# ADR-0004 — Security and data-boundary model

> [!NOTE]
> On this page, define the authorization, sharing, identifier, Files, output, and asynchronous controls every Bulk Record Upload runtime path must enforce.

- **Status:** Approved on 2026-08-12 for implementation.
- **Owners:** Security, architecture, runtime, metadata, and test owners.

## Authorization model

All record-accessing classes use `with sharing` unless this ADR adds a narrowly justified exception. Version 1 approves no `without sharing` business-data service. Controllers, selectors, services, Batch Apex, Queueables, schedulers, trigger handlers, cleanup jobs, and handler adapters repeat authorization appropriate to their transaction.

Use user-mode SOQL and user-mode partial DML for business data. Schema/configuration reads still validate that the running user has the relevant Custom Permission and that every selected object, field, operation, and handler registry key is approved. Revoked access during async execution fails affected rows or the job safely; initiating access is not cached as authority.

## Permission matrix

| Capability          | Required object access                            | Required field access                            | Additional permission                                            | Output boundary                                             |
| ------------------- | ------------------------------------------------- | ------------------------------------------------ | ---------------------------------------------------------------- | ----------------------------------------------------------- |
| Read process        | Read approved configuration projection            | Read only display-safe configuration             | `Bulk_Record_Upload_Run`                                         | Missing and unauthorized use the same not-available outcome |
| Preview             | Read target object and configured readable fields | Read match/default/result fields                 | `Bulk_Record_Upload_Preview`                                     | No inaccessible values or record-existence inference        |
| Insert              | Create target object                              | Create access for every supplied/defaulted field | `Bulk_Record_Upload_Run`                                         | ID only when readable and authorized                        |
| Update/upsert       | Read plus Update; Create also for upsert          | Read key; update/create for changed fields       | `Bulk_Record_Upload_Run`                                         | Partial results are redacted per row                        |
| Delete              | Read plus Delete                                  | Read validated match key only                    | `Bulk_Record_Upload_Delete`                                      | No inaccessible record detail                               |
| History/results     | Read upload log and linked Files                  | Read approved operational fields                 | `Bulk_Record_Upload_Run` or `Bulk_Record_Upload_Administer`      | Sharing and Files access both apply                         |
| Configure processes | Metadata administration outside runtime           | Schema validation of configured fields           | `Bulk_Record_Upload_Administer`                                  | Validation reports identifiers, never record data           |
| Cleanup             | Package-owned log/file scope only                 | Minimal retention fields                         | `Bulk_Record_Upload_Administer` schedules; job revalidates scope | Never delete a File with an unrelated link                  |

## Trusted identifiers

Object, field, operation, behavior, permission, group/share target, and handler keys resolve through code-owned registries plus Schema describe. Store canonical qualified API names after validation. Bind every data value. Dynamic SOQL may concatenate only canonical field/object identifiers emitted by the projection builder; it never concatenates CSV or administrator-supplied values.

Handlers use `BulkRecordUploadHandlerV1` registry keys compiled into a project-owned registry. `Type.forName` on configuration text is prohibited. Adding a handler requires code review, registry membership, interface tests, and documented permission/data behavior.

## Field eligibility

Reject inaccessible fields and field types that the operation cannot safely coerce. Calculated, autonumber, compound parent/child duplicates, deprecated/hidden, polymorphic, encrypted-without-access, and unsupported relationship fields fail configuration validation. Match keys must be readable, supported scalar fields and must have an approved uniqueness contract. Defaults receive the same create/update/FLS and type checks as CSV values.

## Files and CSV output

Accept only `.csv` names and UTF-8 CSV content within ADR-0002 limits. Reject NUL bytes, malformed encoding, excess rows/columns/cells, duplicate/confusable headers, and unsupported controls. Client checks never replace server checks.

Store original/default/result content as Salesforce Files linked to an authorized upload log. File identifiers are references, not authorization. Result cells beginning with `=`, `+`, `-`, `@`, tab, or carriage return receive a leading apostrophe in spreadsheet-oriented output. Error codes are stable; messages omit CSV values, SOQL, stack traces, class names, and raw DML details.

## Data classification and observability

CSV/default/result content and business field values are confidential subscriber data. File names, process identifiers, row counts, status, timing, and stable reason codes are operational data. Logs may contain the latter but never contents, credentials, usernames, emails, record values, raw exceptions, or unredacted IDs beyond the authorized upload identity.

Version 1 publishes no event or external notification. Cache entries contain immutable schema/configuration projections only, never record data. Authorization-sensitive projections include an access fingerprint and cannot be shared across users whose effective access differs.

## Sharing matrix

| Class family                                                                      | Sharing                                  | Reason                                                                                          |
| --------------------------------------------------------------------------------- | ---------------------------------------- | ----------------------------------------------------------------------------------------------- |
| Aura-enabled controllers, request/history services, selectors, Files/log services | `with sharing`                           | Enforce current-user record visibility at synchronous boundaries                                |
| Batch/Queueable handlers and persistence gateway                                  | `with sharing` plus user-mode operations | Async execution is a new trust boundary; sharing and CRUD/FLS are rechecked                     |
| Configuration/schema projection and registry                                      | `with sharing`                           | Consistent default; does not authorize business records                                         |
| Retention scheduler/cleanup                                                       | `with sharing`                           | Version 1 approves no elevated deletion; inability to see a candidate is a safe skip and metric |
| Test data factory                                                                 | No business runtime access; test-only    | Centralized synthetic fixture construction                                                      |

## Adversarial acceptance suite

Executable tests must cover every case in Step 3, including restricted users, malicious identifiers and SOQL fragments, revoked async access, guest/external users, malformed/oversized CSV, formula triggers, Unicode confusables, Files cross-user access, error redaction, concurrency, config deletion, and share/cleanup failure. Each test asserts both the returned outcome and absence of data inference.

## Related

- [Version 1 product contract](ADR-0002-product-contract.md)
- [Step 3 specification](../03-security-and-data-boundaries.md)
- [Configuration over code extension](ADR-0007-configuration-over-code-extension.md)
