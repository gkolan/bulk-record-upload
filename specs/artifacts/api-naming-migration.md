# API naming migration

## Approved convention

- Core object APIs use the complete `Bulk_Record_Upload` product name.
- Apex APIs use the complete `BulkRecordUpload` product name.
- Public LWC APIs use the `bulkRecordUpload` product name.
- Fields use contextual PascalCase names without repeating the product name.
- Labels use plain language that communicates purpose in approximately three seconds.
- The pre-release `BRU` API surface is replaced rather than retained as a compatibility alias.

## Core metadata

| Previous API                 | Approved API                            |
| ---------------------------- | --------------------------------------- |
| `BRU_Upload__c`              | `Bulk_Record_Upload__c`                 |
| `BRU_Upload_Chunk__c`        | `Bulk_Record_Upload_Chunk__c`           |
| `BRU_Upload_Process__mdt`    | `Bulk_Record_Upload_Process__mdt`       |
| `BRU_Upload_Field__mdt`      | `Bulk_Record_Upload_Process_Field__mdt` |
| `bulkRecordUpload`           | `bulkRecordUploadMultiProcess`          |
| `bulkRecordUploadConfigured` | `bulkRecordUploadForm`                  |

## Process fields

| Approved API                  | Administrator meaning                                        |
| ----------------------------- | ------------------------------------------------------------ |
| `ObjectApiName__c`            | Salesforce object that this process is allowed to change.    |
| `Operation__c`                | Allowed insert, update, or upsert operation.                 |
| `ProcessingHandler__c`        | Trusted registered processing extension.                     |
| `RowsPerBatch__c`             | Maximum rows handled in one bounded transaction.             |
| `RetentionDays__c`            | Days to retain upload records and files.                     |
| `PreviewPermissionApiName__c` | Optional Custom Permission required to preview this process. |
| `ConfigurationVersion__c`     | Version used to invalidate cached configuration.             |
| `IsActive__c`                 | Whether users can select and run the process.                |

## Process-field fields

| Approved API              | Administrator meaning                               |
| ------------------------- | --------------------------------------------------- |
| `ProcessDeveloperName__c` | Parent process Developer Name.                      |
| `CsvColumnHeader__c`      | Exact incoming CSV header.                          |
| `DisplayLabel__c`         | Plain-language column label shown to users.         |
| `FieldApiName__c`         | Allowlisted Salesforce destination field API name.  |
| `ColumnOrder__c`          | Stable display and processing order.                |
| `ValueHandling__c`        | Approved blank/value behavior for the field.        |
| `IsRequired__c`           | Whether the CSV column and value are required.      |
| `IsMatchField__c`         | Whether the field identifies an existing record.    |
| `IsUpsertExternalId__c`   | Whether the field is the approved upsert key.       |
| `IncludeInResult__c`      | Whether the field may appear in the result file.    |
| `IsActive__c`             | Whether this field configuration is currently used. |

## Runtime fields

Runtime fields follow the same contextual PascalCase convention: `ProcessDeveloperName__c`, `RowCount__c`, `SuccessCount__c`, `FailureCount__c`, `SubmittedAt__c`, `ProcessingStartedAt__c`, `CompletedAt__c`, `InputFileId__c`, `ResultFileId__c`, `RetentionDays__c`, `IsArchived__c`, and `IdempotencyKey__c`. Chunk fields are `ParentUpload__c`, `ProcessingOrder__c`, `FirstCsvRow__c`, `StagedRowData__c`, `IntegrityChecksum__c`, and `Status__c`.

## Security and navigation metadata

Permission sets, Custom Permissions, the application, tabs, list views, and Custom Labels use the full product name. No new API name uses the `BRU` abbreviation.

## Scratch-org migration evidence

Target: reusable scratch org alias `sfdo826` (explicit on every org command).

- Renamed package deployment `0AfG100000L6TbDKAV`: succeeded, 186 components, 0 component errors.
- Apex run `707G1000018UdPo`: 73 of 73 tests passed; tested-package coverage 89%.
- Administrator access: `Bulk_Record_Upload_Administrator` assigned to the scratch administrator so CRUD/FLS and user-mode tests exercise the intended security model.
- Superseded API cleanup `0AfG100000L6dVeKAJ`: succeeded, 16 components, 0 component errors. The four obsolete permission-set assignments were removed before the atomic cleanup.
- Persistent orgs were not modified.
