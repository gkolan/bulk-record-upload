# Configuration fields

> [!NOTE]
> On this page, look up the exact Custom Metadata field, its type, and its default for every setting the framework reads — for a walkthrough of actually creating these records, see [Configure an upload process](../admin/configure-upload-process.md) and [Configure field behaviors](../admin/configure-field-behaviors.md) instead.
> **Reference:** the field-by-field data dictionary. Use Developer Names as the stable identity for every record type below — nothing here is looked up by label.

## Bulk Record Upload Process (`Bulk_Record_Upload_Process__mdt`)

One record per upload process. See [Configure an upload process](../admin/configure-upload-process.md) for a full walkthrough with examples.

| Field                  | API name                  | Type                                              | Default  |
| ---------------------- | ------------------------- | ------------------------------------------------- | -------- |
| Object API Name        | `ObjectApiName__c`        | Text                                              | —        |
| Upload Operation       | `Operation__c`            | Picklist (`INSERT`, `UPDATE`, `UPSERT`, `DELETE`) | `INSERT` |
| Rows per Batch         | `RowsPerBatch__c`         | Number, 25–200                                    | `100`    |
| History Retention Days | `RetentionDays__c`        | Number, 7–365                                     | `90`     |
| Configuration Version  | `ConfigurationVersion__c` | Number, `1` or `2`                                | `1`      |
| Custom Processor Key   | `ProcessorKey__c`         | Text — a reviewed key, never an Apex class name   | —        |
| Is Active              | `IsActive__c`             | Checkbox                                          | `false`  |

Never put an Apex class name in **Custom Processor Key** — it only ever accepts a small, reviewed set of keys. The packaged default and normal choice is `STANDARD_DML`.

### Record-page parenting

| Field                              | API name                       | Type                                                  | Default |
| ---------------------------------- | ------------------------------ | ----------------------------------------------------- | ------- |
| Record Context Action              | `RecordContextAction__c`       | Picklist (`NONE`, `DEFAULT_PARENT`, `REQUIRE_PARENT`) | `NONE`  |
| Record Page Object API Name        | `HostObjectApiName__c`         | Text                                                  | —       |
| Parent Relationship Field API Name | `RecordContextFieldApiName__c` | Text                                                  | —       |
| Record Context Source              | `RecordContextSource__c`       | Picklist (`PAGE`, `USER_CHOICE`)                      | `PAGE`  |

`RecordContextAction__c` and `RecordContextSource__c` are independent axes: the first decides _whether_ a parent is required at all, the second decides _where_ it's allowed to come from (only the host record page, or also a user-facing picker). See [Configure an upload process](../admin/configure-upload-process.md#use-the-current-record-as-the-parent) for what each combination looks like in practice.

**Picker fields**, used only when `RecordContextSource__c` is `USER_CHOICE`:

| Field                   | API name                   | Controls                                 | Blank default                        |
| ----------------------- | -------------------------- | ---------------------------------------- | ------------------------------------ |
| Context Search Fields   | `ContextSearchFields__c`   | What the user's typing matches           | The host object's Name field         |
| Context Display Fields  | `ContextDisplayFields__c`  | What the user sees in results            | The host object's Name field         |
| Context Filter Criteria | `ContextFilterCriteria__c` | Which parent records are eligible at all | No filter — every record is eligible |

Both `ContextSearchFields__c` and `ContextDisplayFields__c` take a comma-separated list of field API names, where the first is the primary field and the rest are additional fields (capped at 3 additional fields). Every field named is checked against the host object's Schema when the process configuration loads — a field that isn't searchable (for search fields) or readable (for display fields) is rejected by name at that point, not later when the picker renders.

`ContextFilterCriteria__c` holds one condition per line, `FieldApiName:Operator:Value`, where `Operator` is `=`, `!=`, or `IN` (comma-separated values for `IN`); every line combines with AND, up to 10 lines. **Example:** to only let a rep attach an upload to an open Opportunity, two lines:

```text
StageName:!=:Closed Won
Type:IN:New Business,Renewal
```

This filter is applied twice — in the picker, so an ineligible record is never shown, and again on the server when the upload is submitted, so a caller that skips the picker entirely is still rejected. Only the server check is load-bearing; the picker is a convenience.

## Bulk Record Upload Bundle (`Bulk_Record_Upload_Bundle__mdt`)

The thing an admin picks by Developer Name in App Builder when placing the **Bulk Record Upload** component. See [Configure an upload process](../admin/configure-upload-process.md#put-the-component-where-users-can-reach-it) for the full walkthrough.

| Field  | API name      | Type     | Default |
| ------ | ------------- | -------- | ------- |
| Active | `IsActive__c` | Checkbox | `false` |

That's the whole record — a bundle is just a named, activatable container. What it actually offers comes from the assignment records below.

## Bulk Record Upload Bundle Process (`Bulk_Record_Upload_Bundle_Process__mdt`)

One record per process assigned to a bundle. A bundle with more than one active assignment shows the user a picker; a bundle with exactly one skips straight to it.

| Field            | API name                  | Type                                          | Default |
| ---------------- | ------------------------- | --------------------------------------------- | ------- |
| Bundle API Name  | `BundleDeveloperName__c`  | Text — the Developer Name of a Bundle record  | —       |
| Process API Name | `ProcessDeveloperName__c` | Text — the Developer Name of a Process record | —       |
| Display Order    | `DisplayOrder__c`         | Number                                        | —       |
| Active           | `IsActive__c`             | Checkbox                                      | `false` |

## Bulk Record Upload Process Field (`Bulk_Record_Upload_Process_Field__mdt`)

One record per CSV column. This is the largest configuration surface — every setting is documented with a worked example on [Field behaviors](field-behaviors.md), which is the page to actually use when configuring a column. In brief, one record owns: which CSV column maps to which Salesforce field, its sequence, its existing-value and blank-value behavior, separator and overflow rules, trim/case/blank-token cleanup, validation pattern and value range, Source Template (calculated columns), Lookup Match Field, and its required/match/upsert/result-inclusion flags.

A process needs 1–100 active field records, with unique column keys and sequences.

## Bulk Record Upload Extension (`Bulk_Record_Upload_Extension__mdt`)

Registers one Apex class to run for one process. See [Write and register an extension](../developer/custom-handler.md) for the full contract and a worked example.

| Field            | API name                  | Type                                                                             |
| ---------------- | ------------------------- | -------------------------------------------------------------------------------- |
| Process API Name | `ProcessDeveloperName__c` | Text                                                                             |
| Class Name       | `ClassName__c`            | Text — the exact Apex class name, checked at configuration load and at every run |
| Sort Order       | `SortOrder__c`            | Number                                                                           |
| Is Active        | `IsActive__c`             | Checkbox                                                                         |

## Related

See [Configure an upload process](../admin/configure-upload-process.md), [Configure field behaviors](../admin/configure-field-behaviors.md), and [Field behaviors](field-behaviors.md).
