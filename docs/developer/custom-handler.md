# Write and register an extension

> [!NOTE]
> On this page, extend row preparation and post-processing through the
> package's one registered extension seam, without accepting
> administrator-supplied class names as a free-text plugin surface.

## The one extension point

`BulkRecordUploadExtensionV1` is the only interface a subscriber implements
to extend runtime behavior:

```apex
public interface BulkRecordUploadExtensionV1 {
  List<BulkRecordUploadRowV1> beforeMap(
    BulkRecordUploadProjectionV1 projection,
    List<BulkRecordUploadRowV1> rows
  );
  void afterProcess(
    Id uploadId,
    BulkRecordUploadProjectionV1 projection,
    List<BulkRecordUploadRowResultV1> outcomes
  );
}
```

`beforeMap` runs once per chunk before row mapping — use it for bounded
normalization or validation. It must not perform DML, SOQL, callouts, or
async enqueue in an unbounded loop, and it never receives record IDs to
persist against because mapping has not happened yet. `afterProcess` runs
once per chunk after persistence completes — use it to observe safe row
results and identifiers. Neither phase can touch the database directly: the
DML/persistence path stays package-owned and user-mode by design (see
[ADR-0007](../../specs/decisions/ADR-0007-configuration-over-code-extension.md)),
so an extension transforms and observes data, it never persists it.

Extend `BulkRecordUploadExtensionAdapterV1` instead of implementing the
interface directly if you only need one phase — its no-op default for the
other phase means you override just what you use:

```apex
public class ExampleUppercaseExtension extends BulkRecordUploadExtensionAdapterV1 {
  public override List<BulkRecordUploadRowV1> beforeMap(
    BulkRecordUploadProjectionV1 projection,
    List<BulkRecordUploadRowV1> rows
  ) {
    List<BulkRecordUploadRowV1> transformed = new List<BulkRecordUploadRowV1>();
    for (BulkRecordUploadRowV1 row : rows) {
      Map<String, String> values = row.getValuesByColumn();
      for (String key : values.keySet()) {
        if (values.get(key) != null) {
          values.put(key, values.get(key).toUpperCase());
        }
      }
      transformed.add(new BulkRecordUploadRowV1(row.rowNumber, values));
    }
    return transformed;
  }
}
```

## Worked example: registering the shipped trim extension

`BulkRecordUploadTrimHandlerV1` ships with the package and trims every
projected string value before mapping. Register it for one process with a
`Bulk_Record_Upload_Extension__mdt` record:

| Field                     | Value                                                                        |
| ------------------------- | ---------------------------------------------------------------------------- |
| `ProcessDeveloperName__c` | The exact Developer Name of the process this extension runs for.             |
| `ClassName__c`            | `BulkRecordUploadTrimHandlerV1` — the exact global Apex class name.          |
| `SortOrder__c`            | `10` — controls run order when a process has more than one active extension. |
| `IsActive__c`             | `true`                                                                       |

`examples/main/default/customMetadata/Bulk_Record_Upload_Extension.Contact_Insert_Trim.md-meta.xml`
in this repository is exactly this record, registered against the
`Contact_Insert_Demo` example process — copy it as a starting point.

## Registering your own extension

1. Write a class implementing `BulkRecordUploadExtensionV1` (or extending
   `BulkRecordUploadExtensionAdapterV1`).
2. Create a `Bulk_Record_Upload_Extension__mdt` record with `ClassName__c`
   set to your class's exact name, `ProcessDeveloperName__c` set to the
   process it should run for, a unique `SortOrder__c` if more than one
   extension is active for that process, and `IsActive__c = true`.
3. Nothing else names your class. The class name is never accepted from CSV
   content or any other administrator-editable free-text field — only from
   this reviewed Custom Metadata record.

## What happens if registration is wrong

The class name is validated twice: once when the process configuration is
loaded (so a broken registration is caught before an upload runs), and again
every time the process actually runs (so a class deleted or broken after
configuration is caught before it can execute). Both checks use the same
rule: the name must resolve through `Type.forName`, instantiate, and be
assignable to `BulkRecordUploadExtensionV1`. Any failure raises a
configuration error naming the class — never a silent skip, and never a
class instantiated without that check. A process may register up to
`BulkRecordUploadRuntimeContract.MAX_EXTENSIONS_PER_PROCESS` active
extensions; run order follows `SortOrder__c`.

If your extension throws, the upload fails cleanly with a recorded error;
the chunk is left in a terminal `FAILED` status, never wedged mid-processing.

## Add tests

Add focused tests for your extension covering: the transformation or
observation it performs, null/invalid input handling, and bulk safety at the
maximum chunk size. `BulkRecordUploadJobTest` has worked examples of
registering two extensions and asserting their run order, and of asserting a
throwing extension fails safely.

## Next steps

Run the [developer test workflow](testing.md) and update the
[field behavior reference](../reference/field-behaviors.md) when the
extension adds a behavior.
