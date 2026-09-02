# Plain-language glossary

> [!NOTE]
> On this page, find plain-language definitions for Salesforce and software terms used throughout
> the Bulk Record Upload documentation.

The guides use Salesforce labels when describing Setup and exact API names when a value must be
entered, deployed, queried, or troubleshot. Use this glossary when a specification, evidence record,
or developer guide needs a technical term that would otherwise interrupt the task.

## Salesforce terms

| Term                          | Meaning in this project                                                                                                                                                      |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Apex                          | Salesforce's server-side programming language. Bulk Record Upload uses Apex to validate files, save records, and run background work.                                        |
| API name                      | The exact identifier Salesforce metadata and code use, such as `Bulk_Record_Upload__c`. A Setup label can contain spaces and can differ from its API name.                   |
| CRUD and FLS                  | Create, Read, Update, and Delete access for an object, plus Field-Level Security for individual fields. The package checks both before it reads or changes business records. |
| Custom Metadata Type          | Deployable Salesforce setup records. These records define upload processes and field behavior without changing Apex.                                                         |
| DML                           | The Apex operation that inserts, updates, upserts, or deletes Salesforce records.                                                                                            |
| External ID                   | A field marked in Salesforce as an identifier from another system. Upsert uses it to decide whether to create a record or update an existing one.                            |
| Lightning Web Component (LWC) | A Salesforce user-interface component. `bulkRecordUpload` is the component placed on Lightning pages.                                                                        |
| metadata                      | Salesforce configuration stored as files, including objects, fields, permission sets, Lightning pages, and Custom Metadata Types.                                            |
| org                           | One Salesforce environment. A scratch org is temporary; the approved persistent org is long-lived.                                                                           |
| Salesforce Files              | Salesforce records used to store the uploaded CSV and the result CSV. Access follows the upload record's sharing.                                                            |
| schema                        | The objects, fields, types, and relationships available in an org.                                                                                                           |
| scratch org                   | A temporary Salesforce environment created from `config/project-scratch-def.json` for development and release checks.                                                        |
| SOQL                          | Salesforce Object Query Language, which Apex uses to read Salesforce records.                                                                                                |
| user mode                     | An Apex data-access mode that enforces the current user's object, field, and record access.                                                                                  |

## Processing and architecture terms

| Term                              | Meaning in this project                                                                                                                                                                                        |
| --------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| asynchronous or background work   | Work Salesforce runs after the submit request finishes, so a large upload does not keep the browser request open.                                                                                              |
| Batch Apex                        | Salesforce background processing that runs work in controlled groups. Bulk Record Upload processes one stored file chunk per batch execution.                                                                  |
| bounded                           | Limited by an explicit maximum. Bounds keep file size, field count, cache entries, and stored messages within tested limits.                                                                                   |
| cache                             | A temporary saved copy of validated setup information. The package can reuse it during a transaction instead of repeating the same schema work.                                                                |
| configuration fingerprint or hash | A value calculated from upload settings. If relevant setup changes after preview, the value changes and submission stops before records are saved.                                                             |
| data transfer object (DTO)        | A small object used to move a defined set of safe values between code layers or to the browser.                                                                                                                |
| idempotency                       | Protection that makes a repeated submit request return the original upload instead of starting the same work twice.                                                                                            |
| orchestration                     | Code that controls the order of background steps, such as staging, processing chunks, finalizing results, and cleanup.                                                                                         |
| projection                        | The compact, validated subset of object fields and process settings needed for one upload. The package does not load every field from a large object.                                                          |
| registry                          | A package-owned list of approved extension identifiers and their Apex implementations. Administrator-entered text cannot select an arbitrary class.                                                            |
| rollback or recovery              | The documented action that returns setup to a known state or safely resumes after a failure. Committed Salesforce record changes require a separate corrective upload or other approved data-recovery process. |
| runtime                           | The package behavior while someone previews, submits, processes, or reviews an upload.                                                                                                                         |
| transaction                       | One Salesforce unit of work. If an unhandled error ends the transaction, Salesforce reverses its uncommitted record changes.                                                                                   |

## Delivery and decision terms

| Term                                      | Meaning in this project                                                                                                                                  |
| ----------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Architecture Decision Record (ADR)        | A record of an important design choice, its reason, and its consequences. Accepted public decisions belong in the architecture or contract guide.        |
| continuous integration (CI)               | Automated checks that run for repository changes, including formatting, tests, source rules, documentation checks, and release-boundary checks.          |
| exit gate                                 | The evidence that must exist before a program step can be marked complete. An unchecked gate is not a passing result.                                    |
| manifest                                  | `manifest/package.xml`, the explicit list of Salesforce metadata included in deployment validation.                                                      |
| rollback                                  | A safe way to return code, metadata, or configuration to a previously known state. Data rollback is separate and depends on what records were committed. |
| Software Bill of Materials (SBOM)         | A generated list of software dependencies and their recorded license identifiers used during release review.                                             |
| Salesforce Lightning Design System (SLDS) | Salesforce's components, styles, and accessibility patterns for Lightning interfaces.                                                                    |

## Related

- [Documentation index](../README.md)
- [Architecture](../developer/architecture.md)
- [Configuration and permissions](configuration-and-permissions.md)
