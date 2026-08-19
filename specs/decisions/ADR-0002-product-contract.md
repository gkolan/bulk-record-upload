# ADR-0002 — Version 1 product contract

> [!NOTE]
> On this page, define the supported Bulk Record Upload behavior and hard limits that implementation and subscriber documentation must share.

- **Status:** Approved on 2026-08-12 for implementation and validation.
- **Owners:** Product, architecture, security, operations, documentation, and test owners.

## Supported scope

Version 1 supports configuration-selected insert, update, upsert, and delete operations on allowlisted standard or custom objects. Each upload process defines a compact ordered field projection, operation, match/upsert key when required, batch size, preview access, and retention policy.

Supported subscriber editions are Enterprise, Unlimited, Performance, and Developer Edition on API version 66.0 or later. Person Accounts, Experience Cloud users, multi-currency, Shield-encrypted fields, compound fields, geolocation, polymorphic references, translated labels, and restricted picklists are supported only where their field-specific acceptance tests pass; otherwise the configuration validator rejects them with a documented reason.

## Input contract 1.0

| Limit                          |                               Version 1 value |
| ------------------------------ | --------------------------------------------: |
| Encoded upload size            |                         2,000,000 UTF-8 bytes |
| Data rows                      |                                         5,000 |
| Columns                        |                                           100 |
| Decoded characters in one cell |                                        32,000 |
| Header length                  |                                255 characters |
| Concurrent nonterminal uploads | One per running user and process; ten per org |
| Configured fields per process  |                                           100 |
| Batch size                     |                           25–200; default 100 |

CSV uses UTF-8 with an optional BOM, comma delimiters, CRLF or LF record endings, double-quoted cells, and doubled quotes inside quoted cells. A header row is required. Blank trailing records are ignored; blank records between data records retain row correlation. Duplicate headers compare case-insensitively after trimming and are rejected.

## Processing contract

- Browser validation is advisory; Apex repeats byte, row, column, cell, header, configuration, and authorization checks.
- CSV headers resolve only through the selected process projection. Administrator text and uploaded text never become unchecked object, field, class, group, or query identifiers.
- Insert, update, upsert, and delete use user-mode access and partial-success DML. Every result remains correlated with the one-based physical CSV data-row number.
- A client-generated idempotency key is unique per user and process for 24 hours. Repeating a successful or active submission returns the original upload identity rather than enqueuing duplicate DML.
- Version 1 does not support cancellation after a job is queued. Retry is explicit and creates a new upload linked to the prior attempt; successful prior rows are not automatically replayed.
- The runtime never describes, queries, serializes, caches, or returns every object field. “All result fields” means the configured process projection only.

## Status contract 1.0

`QUEUED` → `VALIDATING` → `PROCESSING` → one terminal status:

- `COMPLETED`
- `COMPLETED_WITH_ERRORS`
- `FAILED`

Transitions are monotonic. A retry is a new upload. Submission, processing-start, and completion timestamps are separate fields.

## Results CSV contract 1.0

The first columns, in order, are `bru_row_number`, `bru_status`, `bru_record_id`, `bru_error_code`, and `bru_error_message`. Configured result columns follow in stable process order. Status values are `SUCCESS`, `FAILED`, and `SKIPPED`.

Errors use stable codes and redacted administrator-safe messages. Result writing neutralizes cells beginning with formula-trigger characters when a spreadsheet could execute them. Raw CSV contents and sensitive values never enter Apex debug logs, events, or operational messages.

## Retention contract

Core retains upload logs and result files for 90 days and original/default input files for 30 days by default. Administrators may select 7–365 days per process. A scheduled cleanup job removes package-owned file links and files only when the package can prove ownership and no unrelated link remains. Archiving hides a log from ordinary history but does not extend retention.

Before uninstall, administrators export required logs and files. Uninstall and file-retention behavior must be verified and documented; no claim is made that uninstall preserves package-owned records.

## Independent contract versions

- Configuration DTO: `1.0`
- Registered handler interface: `1.0`
- Status model: `1.0`
- Results CSV schema: `1.0`
- Event contract: unsupported; no Core event exists in version 1

Additive optional fields may appear within `1.x` when consumers ignore unknown fields. Removing, renaming, changing meaning, or adding a required field needs a major contract version and migration guidance.

## Unsupported in Core version 1

Slack, webhooks, generic completion events, Flow handlers, arbitrary class-name dispatch, configurable status colors, automatic cancellation, files larger than the stated limit, more than 5,000 rows, and unconfigured object fields are unsupported. Core exposes no inactive field, value, UI control, permission, event, example, or documentation promise for them.

## Related

- [Packaging strategy](ADR-0001-packaging-strategy.md)
- [Public naming and API versions](ADR-0003-public-naming-and-api-version.md)
- [Behavior parity matrix](../artifacts/behavior-parity-matrix.md)
