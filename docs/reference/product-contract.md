# Product contract

> [!NOTE]
> On this page, learn which Bulk Record Upload operations, limits, lifecycle states, retention rules, and subscriber environments version 1 supports.

Version 1 supports configuration-selected insert, update, upsert, and delete for approved standard and custom objects. Each process exposes no more than 100 configured fields and uses a compact field projection.

## Limits

| Input                       |                                Limit |
| --------------------------- | -----------------------------------: |
| UTF-8 file size             |                      2,000,000 bytes |
| Data rows                   |                                5,000 |
| Columns                     |                                  100 |
| Characters per decoded cell |                               32,000 |
| Characters per header       |                                  255 |
| Active uploads              | One per user/process and ten per org |
| Batch size                  |                  25–200; default 100 |

The server enforces every limit even when browser validation has already run.

## Lifecycle

An upload moves through `QUEUED`, `VALIDATING`, and `PROCESSING`, then reaches `COMPLETED`, `COMPLETED_WITH_ERRORS`, or `FAILED`. A status never moves backward. Version 1 does not cancel a queued job; a retry creates a new linked upload.

## Access and retention

Bulk Record Upload applies sharing plus running-user object and field access to reads and data changes. Configuration cannot authorize an object, field, handler, or group that the trusted project registry does not allow.

By default, input/default files remain for 30 days and logs/results remain for 90 days. An administrator may configure 7–365 days. Archiving changes ordinary history visibility, not retention.

Supported subscriber editions are Enterprise, Unlimited, Performance, and Developer Edition on API version 66.0 or later.

## Related

- [CSV and results contract](csv-and-results-contract.md)
- [Package and compatibility](package-and-compatibility.md)
- [Unsupported features](unsupported-features.md)
