# ADR-0006 — Runtime architectural principles

- **Status:** Approved on 2026-08-12 for implementation and release validation.
- **Owners:** Product, architecture, security, runtime, metadata, and documentation owners.

## Decision

The project applies seven architectural principles in Bulk Record Upload terms.

| Principle                        | Product consequence                                                                                                                                                                                                                                                             |
| -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Configuration before custom code | Upload Process and Upload Process Field Custom Metadata answer ordinary mapping, operation, merge, permission, and presentation questions. Apex extensions require a code-owned registry and a documented gap that configuration cannot express.                                |
| Fail visible, never silent       | Uploads, chunks, and result rows reach a documented status. Fatal and row failures include stable reason codes and safe, bounded guidance.                                                                                                                                      |
| Security is not optional         | Target business-record SOQL and DML run in user mode. Administrator-controlled identifiers are resolved through Schema and registries. System mode is limited to package-owned upload, chunk, and File orchestration described in ADR-0004; configuration can never request it. |
| Hard limits by design            | CSV bytes, rows, columns, cell characters, chunk rows, chunk bytes, chunk count, history rows, error codes, messages, and staged result size have fixed code-owned ceilings. Configuration may select a value only inside a safe ceiling.                                       |
| One approved value list          | `BulkRecordUploadRuntimeContract` owns runtime ceilings and stable status/reason values. `scripts/check-apex.mjs` compares its status values with restricted picklist metadata used by maintainers.                                                                             |
| Stable integration values        | Automation and integrations consume stored upload status, result status, and reason code. Labels and safe messages are presentation and diagnostic text, not branching contracts.                                                                                               |
| Plain language                   | Setup labels, help text, public documentation, and safe messages use Salesforce terms such as Custom Metadata, Upload Process, field, record, Salesforce File, Permission Set, and Custom Permission.                                                                           |

## Security-mode boundary

The instruction to reject system mode applies at the business-data and configurable-query boundary. The package has no administrator-authored SOQL feature. `BulkRecordUploadRecordResolver` and `BulkRecordUploadExistingValueMerger` query target records in user mode, and persistence uses user-mode partial DML. Package-owned orchestration uses narrowly scoped system-mode access so an authorized asynchronous job can update its private upload and chunk state; it does not grant access to target records.

## Consequences

- Adding a public status, package-defined reason code, or hard ceiling requires a contract, metadata/documentation, test, and audit update.
- A new editable display label does not change an integration value.
- A failure path without a durable status and reason code is release-blocking.
- Maintainer validation and runtime execution cannot maintain independent status lists.

## Related

- [Product contract](ADR-0002-product-contract.md)
- [Security model](ADR-0004-security-model.md)
- [Runtime and cache architecture](ADR-0005-runtime-and-cache-architecture.md)
