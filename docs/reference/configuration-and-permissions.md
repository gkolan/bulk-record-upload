# Configuration, metadata, and permissions

> [!NOTE]
> On this page, understand the version 1 metadata model, sharing boundary, and permission assignments for Bulk Record Upload.

## Configuration model

`Bulk_Record_Upload_Process__mdt` defines an approved upload process. Its target object, operation, handler key, batch size, retention period, optional preview permission, active state, and contract version are configuration inputs—not authorization grants.

`Bulk_Record_Upload_Process_Field__mdt` defines the compact field projection for a process. Each active row names one CSV column and one target field plus ordering, blank-value behavior, match/upsert roles, required behavior, and result inclusion. Runtime validation must resolve every object, field, permission, and handler through Schema describe or a project-owned registry before processing begins.

Version 1 ships no Custom Metadata records. Subscribers create records for their own approved objects and fields after installation. Example and test records remain outside the Core manifest.

## Stored records and Files

`Bulk_Record_Upload__c` is a private execution record. Salesforce sharing determines who can see it. It stores lifecycle state, bounded counts, contract identifiers, retention state, and Salesforce File document IDs; it does not store CSV content.

`Bulk_Record_Upload_Chunk__c` is a controlled-by-parent system record used for bounded, ordered staging. Application code—not end users—creates and removes chunks. Chunk payloads must never be logged.

The input and result CSVs use Salesforce Files. Runtime code must create record links and re-check record and File access at each synchronous and asynchronous boundary. A stored File ID never bypasses sharing.

Core creates no public File distribution and no Public Group. Files are linked to
the private upload record through `ContentDocumentLink`. Subscribers may share
upload records through their own Public Groups and sharing rules; the package
never hardcodes a group or broadens access to target records.

## Permission sets

| Permission set                   | Purpose                                                                                               | Deliberately excluded                                               |
| -------------------------------- | ----------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| Bulk Record Upload User          | Run approved processes and access the app, upload tab, configuration types, and shared upload records | Target-object CRUD/FLS, delete operation, preview, broad org access |
| Bulk Record Upload Previewer     | Grants run and preview capabilities                                                                   | Target-object access                                                |
| Bulk Record Upload Deletion      | Grants run and approved delete-process capabilities                                                   | Target-object delete/FLS                                            |
| Bulk Record Upload Administrator | Inspect configuration, uploads, and staging records for support and retention                         | Modify All Data, View All Data, target-object access                |

Every operator also needs the appropriate target-object CRUD, field-level security, record sharing, and Salesforce Files access through subscriber-owned permissions. The package never grants those rights implicitly.

## Stable status values

Upload status values are `QUEUED`, `VALIDATING`, `PROCESSING`, `COMPLETED`, `COMPLETED_WITH_ERRORS`, and `FAILED`. Chunk status values are `READY`, `PROCESSING`, `COMPLETED`, and `FAILED`. These stored values are public automation contracts; labels may be translated without changing them.

## Retention and audit

Upload history tracking is enabled for status and counts that drive operational review. Retention is configured from 7 through 365 days, defaults to 90, and must be copied to the upload record when work is accepted. Cleanup removes chunks and eligible Files without requiring Modify All Data and records only safe identifiers and aggregate outcomes.

## Subscriber-supplied reference failures

An inactive process, unknown object or field, disallowed operation, unregistered handler, missing preview permission, duplicate column/sequence, or inaccessible target projection must fail configuration validation before any target DML. User-facing guidance names the configuration entry and safe API identifier, never CSV values. Portability tests install the package without subscriber records and exercise valid and invalid records created only in test setup.

## Related

- [Product contract](product-contract.md)
- [CSV and results contract](csv-and-results-contract.md)
- [Step 5 evidence](../evidence/05-metadata-and-permissions/README.md)
