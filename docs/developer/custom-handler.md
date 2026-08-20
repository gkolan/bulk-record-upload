# Write and register an extension

> [!NOTE]
> On this page, write an Apex class that plugs into row preparation or field merging, register it, and see exactly what running it looks like — for both of this package's extension points.

There are exactly two places you can run your own Apex: the **row-extension seam** (touch a row before it's mapped, or observe results after saving) and the **custom merge strategy seam** (decide how a new CSV value combines with an existing Salesforce value). Nothing else accepts a class name — not a CSV cell, not a free-text admin field anywhere else. A class only ever runs if it's named in one of these two specific Custom Metadata fields, both reviewed and set by an admin, not an end user.

## Extension point 1: the row-extension seam

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

`beforeMap` runs once per chunk, before row mapping — use it for bounded normalization or validation across a whole chunk of rows at once. It never receives record Ids, because mapping to Salesforce fields hasn't happened yet. `afterProcess` runs once per chunk, after that chunk has already been saved — use it to observe the safe, already-persisted results (never the raw CSV). Neither phase can perform DML, SOQL, callouts, or async work in an unbounded loop, and neither can write to the database directly — saving records stays entirely on the package's own reviewed path (see [ADR-0007](../../specs/decisions/ADR-0007-configuration-over-code-extension.md)). An extension transforms and observes; it never persists.

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

**Step 3 — register it**, by creating one **Bulk Record Upload Extension** (`Bulk_Record_Upload_Extension__mdt`) record:

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

1. Write a class implementing `BulkRecordUploadExtension` (or extending `BulkRecordUploadExtensionAdapter`).
2. Create a `Bulk_Record_Upload_Extension__mdt` record naming it, the same way as Step 3 above.
3. Nothing else can name your class — not CSV content, not any other admin-editable field. Only this record can.

### What happens if a row-extension registration is wrong

The class name is checked twice: once when the process configuration loads (catching a broken registration before any upload runs), and again every time the process actually runs (catching a class that got deleted or broken after registration). Both checks require the name to resolve to a real class, instantiate, and implement `BulkRecordUploadExtension` — any failure raises a clear configuration error naming the class, never a silent skip. A process can register up to `BulkRecordUploadRuntimeContract.MAX_EXTENSIONS_PER_PROCESS` (10) active extensions, running in `SortOrder__c` order.

If your extension throws an exception, the upload fails cleanly with a recorded error — the chunk ends in a `FAILED` status, never stuck partway through.

### Add tests

Cover: the transformation or observation your extension performs, how it handles null or invalid input, and that it stays within governor limits at the maximum chunk size (200 rows). `BulkRecordUploadJobTest` has worked examples of registering two extensions and asserting their run order, and of asserting a throwing extension fails safely — read it alongside your own test for the pattern.

## Extension point 2: custom merge strategies

`BulkRecordUploadFieldMergeStrategy` covers a narrower decision: how a nonblank CSV value combines with an existing Salesforce value on Update or Upsert, for the one case none of the built-in Existing Value Action options fit. See [Field behaviors](../reference/field-behaviors.md#existing-value-action-at-a-glance) for what those built-in options already cover before reaching for this.

```apex
public interface BulkRecordUploadFieldMergeStrategy {
  Boolean supportsType(String fieldType);
  Object combine(
    BulkRecordUploadFieldProjection field,
    Object existingValue,
    Object incomingValue,
    Integer maximumLength
  );
}
```

`supportsType` declares which field types the strategy accepts — `combine` is only ever called after blank handling and that type check both pass.

### A complete merge-strategy example, from class to running upload

This is the actual class shipped with the package, `BulkRecordUploadLongerTextStrategy` — it keeps whichever of the existing or incoming text is longer:

```apex
public class BulkRecordUploadLongerTextStrategy implements BulkRecordUploadFieldMergeStrategy {
  private static final Set<String> TEXT_TYPES = new Set<String>{
    'STRING',
    'TEXTAREA',
    'EMAIL',
    'PHONE',
    'URL',
    'PICKLIST'
  };

  public Boolean supportsType(String fieldType) {
    return TEXT_TYPES.contains(fieldType);
  }

  public Object combine(
    BulkRecordUploadFieldProjection field,
    Object existingValue,
    Object incomingValue,
    Integer maximumLength
  ) {
    String existingText = String.valueOf(existingValue);
    String incomingText = String.valueOf(incomingValue);
    return incomingText.length() > existingText.length()
      ? incomingText
      : existingText;
  }
}
```

To use it (or a class you write the same way), set two fields on a **Bulk Record Upload Process Field** record:

| Field                                                       | Value                                |
| ----------------------------------------------------------- | ------------------------------------ |
| Existing Value Action (`ExistingValueAction__c`)            | `CUSTOM`                             |
| Custom Merge Strategy Class (`CustomMergeStrategyClass__c`) | `BulkRecordUploadLongerTextStrategy` |

**What running it looks like:** on an Account with `Description` already set to `Short note.`, an Update row whose CSV cell for `description` is `A much longer note with more detail than before.` results in `Description` becoming `A much longer note with more detail than before.` — the longer of the two. A row where the incoming text was shorter than the existing text would leave `Description` unchanged instead.

### What happens if a merge-strategy registration is wrong

Validation mirrors the row-extension seam exactly: the class name must resolve to a real class, instantiate, and implement `BulkRecordUploadFieldMergeStrategy`. It's checked eagerly when the process configuration loads — so a typo or a missing class fails immediately, before any row is processed — and again every time the strategy actually merges a row, so a class removed after configuration is still caught before it can run.

## Next steps

Run the [developer test workflow](testing.md) and update the [field behavior reference](../reference/field-behaviors.md) when your extension adds a behavior an admin would configure.
