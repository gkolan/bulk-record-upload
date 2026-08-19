# ADR-0003 — Public naming and API-version policy

> [!NOTE]
> On this page, define collision-resistant no-namespace names and the Salesforce release matrix before metadata names become upgrade commitments.

- **Status:** Approved on 2026-08-12 for implementation and validation.
- **Owners:** Architecture, metadata, release, documentation, and security owners.

## Public naming

The unlocked package has no namespace. Use these project-owned forms:

| Surface                                                       | Required form                                                              | Example pattern                  |
| ------------------------------------------------------------- | -------------------------------------------------------------------------- | -------------------------------- |
| Apex classes and interfaces                                   | `BulkRecordUpload` prefix                                                  | `BulkRecordUploadHandlerV1`      |
| LWC folders                                                   | `bru` prefix followed by a task                                            | `bruUploadWorkspace`             |
| Custom objects and Custom Metadata Types                      | `BulkRecordUpload_` label/API prefix                                       | `Bulk_Record_Upload__c`          |
| Custom fields on project objects                              | Descriptive API name; object already supplies `BulkRecordUpload_` boundary | `Status__c`                      |
| Custom fields on external objects                             | `BulkRecordUpload_` prefix                                                 | `BulkRecordUpload_Import_Key__c` |
| Permission sets and Custom Permissions                        | `BulkRecordUpload_` prefix                                                 | `Bulk_Record_Upload_User`        |
| labels, tabs, applications, events, and other global metadata | `BulkRecordUpload_` prefix                                                 | `Bulk_Record_Upload`             |
| Stable result columns and machine values                      | lowercase `bru_` prefix or uppercase snake case                            | `bru_row_number`, `COMPLETED`    |

Generic names such as `GlobalPlatformEvent`, `UploadController`, `Handler`, or `Admin` are prohibited. Before adding a public name, search project metadata, dependency manifests, current Salesforce standard names, and the authorized test org. Record any unavoidable commitment in this ADR.

## API versions and releases

- Development source API version: `67.0`.
- Minimum subscriber platform/API version: `66.0`.
- Package creation version: the checked-in source version, currently `67.0`.
- Scratch-org definition: current generally available release matching source version 67.0; preview orgs are not release evidence.
- Source API advances only when a required platform capability or supported-release policy is approved and both minimum-version compatibility and current-version package tests pass.
- Preview releases may be used for research in an isolated scratch org but cannot replace the reusable project scratch org or satisfy a release gate.

Every release validates fresh install on the current supported release, upgrade from the previous promoted package version, and a no-namespace source deployment. Features whose metadata cannot deploy to the minimum version either need a compatibility boundary or a documented minimum-version increase before merge.

## Collision and compatibility consequences

No-namespace global metadata names are subscriber-org commitments. Renaming Apex, LWC, objects, fields, permissions, or stored machine values requires the compatibility process and usually a major version. Labels may change when API identity and meaning remain stable and documentation records the new label.

## Related

- [Packaging strategy](ADR-0001-packaging-strategy.md)
- [Version 1 product contract](ADR-0002-product-contract.md)
