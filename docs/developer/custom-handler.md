# Write and register an extension

> [!NOTE]
> On this page, write an Apex class that plugs into row preparation, register it, and see exactly what running it looks like.

There is exactly one place to run subscriber Apex: the **row-extension seam** can touch a row before
it is mapped or observe safe results after saving. Nothing else accepts a class name—not a CSV cell,
process metadata, field metadata, or persistence setting. A class runs only when a reviewed,
source-controlled `Bulk_Record_Upload_Extension__mdt` registration names it.

## The row-extension seam

`BulkRecordUploadExtension` is the interface:

```apex
public interface BulkRecordUploadExtension {
  List<BulkRecordUploadRow> beforeMap(
    BulkRecordUploadProjection projection,
    List<BulkRecordUploadRow> rows
  );
  void afterProcess(
    Id uploadId,
    BulkRecordUploadProjection projection,
    List<BulkRecordUploadRowResult> outcomes
  );
}
```

`beforeMap` runs once per chunk, before row mapping — use it for bounded normalization or validation across a whole chunk of rows at once. It never receives record Ids, because mapping to Salesforce fields hasn't happened yet. `afterProcess` runs once per chunk, after that chunk has already been saved — use it to observe the safe, already-persisted results (never the raw CSV).

An extension is subscriber Apex, and Salesforce does not sandbox it from SOQL, DML, callouts, or
asynchronous work that its execution context permits. Treat its class and registration like any
other production Apex deployment: review it for sharing, CRUD/FLS, user-mode access, secrets,
bulkification, transaction behavior, and governor limits. The package never delegates its mapped
target-row save to the extension; `BulkRecordUploadPersistenceGateway` remains the only package
path that persists those rows.

If you only need one phase, extend `BulkRecordUploadExtensionAdapter` instead of implementing the interface directly — it gives you a no-op default for the phase you don't use.

### A complete row-extension example, from class to running upload

**Step 1 — write the class.** This example uppercases every text value in a row before it's mapped:

```apex
public class ExampleUppercaseExtension extends BulkRecordUploadExtensionAdapter {
  public override List<BulkRecordUploadRow> beforeMap(
    BulkRecordUploadProjection projection,
    List<BulkRecordUploadRow> rows
  ) {
    List<BulkRecordUploadRow> transformed = new List<BulkRecordUploadRow>();
    for (BulkRecordUploadRow row : rows) {
      Map<String, String> values = row.getValuesByColumn();
      for (String key : values.keySet()) {
        if (values.get(key) != null) {
          values.put(key, values.get(key).toUpperCase());
        }
      }
      transformed.add(new BulkRecordUploadRow(row.rowNumber, values));
    }
    return transformed;
  }
}
```

**Step 2 — deploy it**, the same way you'd deploy any Apex class in this repository.

**Step 3 — register it**, by adding one source-controlled **Bulk Record Upload Extension** (`Bulk_Record_Upload_Extension__mdt`) record and deploying it through your reviewed release path:

| Field                                              | Value                                                                                     |
| -------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| Process Developer Name (`ProcessDeveloperName__c`) | The exact Developer Name of the process this should run for, e.g. `Contact_Insert_Weekly` |
| Class Name (`ClassName__c`)                        | `ExampleUppercaseExtension` — the exact Apex class name                                   |
| Sort Order (`SortOrder__c`)                        | `10` — only matters if this process has more than one active extension                    |
| Is Active (`IsActive__c`)                          | `true`                                                                                    |

**Step 4 — see it run.** Upload a CSV where the `name` column has the value `acme corp`. Once the row is mapped, `Name` on the created record is `ACME CORP` — the class ran before mapping and changed the value every later stage saw.

### A real one already in this repository

`BulkRecordUploadTrimHandler` ships with the package and trims every projected string value before mapping. It's registered against the demo `Contact_Insert_Demo` process in `examples/main/default/customMetadata/Bulk_Record_Upload_Extension.Contact_Insert_Trim.md-meta.xml` — open that file to see a real, already-working registration record, and copy it as a starting point for your own.

### Registering your own, in short

1. Write and review a class implementing `BulkRecordUploadExtension` (or extending `BulkRecordUploadExtensionAdapter`).
2. Add a `Bulk_Record_Upload_Extension__mdt` record to version-controlled source and deploy it through the same review path.
3. Nothing else can name your class — not CSV content, process/field configuration, or another runtime input. Only an active registration record can.

### What happens if a row-extension registration is wrong

The class name is checked twice: once when the process configuration loads (catching a broken registration before any upload runs), and again every time the process actually runs (catching a class that got deleted or broken after registration). Both checks require the name to resolve to a real class, instantiate, and implement `BulkRecordUploadExtension` — any failure raises a clear configuration error naming the class, never a silent skip. A process can register up to `BulkRecordUploadRuntimeContract.MAX_EXTENSIONS_PER_PROCESS` (10) active extensions, running in `SortOrder__c` order.

If your extension throws an exception, the upload fails cleanly with a recorded error — the chunk ends in a `FAILED` status, never stuck partway through.

### Add tests

Cover: the transformation or observation your extension performs, how it handles null or invalid input, and that it stays within governor limits at the maximum chunk size (200 rows). `BulkRecordUploadJobTest` has worked examples of registering two extensions and asserting their run order, and of asserting a throwing extension fails safely — read it alongside your own test for the pattern.

## Next steps

Run the [developer test workflow](testing.md). Keep persistence and field-merge behavior inside the
package-owned paths; `BulkRecordUploadExtension` is the only subscriber Apex extension seam.
