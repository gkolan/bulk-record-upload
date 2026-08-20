# Product contract

> [!NOTE]
> On this page, look up the exact operations, limits, lifecycle states, and supported environments version 1 guarantees — the canonical numbers other pages link to rather than repeat.
> **Reference:** the formal contract. See [Product limits](../admin/limits.md) for the same limits explained for an administrator, with what happens at each one.

Version 1 supports Insert, Update, Upsert, and Delete for any standard or custom object an admin configures a process for. Each process can configure up to 100 columns — the running upload only ever reads or writes those configured columns, never every field on the object.

## Limits

| Input                            | Limit                                     |
| -------------------------------- | ----------------------------------------- |
| File size (UTF-8)                | 2,000,000 bytes (2 MiB)                   |
| Data rows                        | 5,000                                     |
| Configured columns per process   | 100                                       |
| Characters per decoded cell      | 32,000                                    |
| Characters per column header     | 255                                       |
| Uploads actively running at once | 1 per user per process; 10 across the org |
| Rows per batch (chunk size)      | 25–200; default 100                       |

The server enforces every one of these limits itself, even though the browser already checks most of them before submission — a request that somehow bypasses the browser check is still rejected server-side.

## Lifecycle

An upload moves through `QUEUED`, `VALIDATING`, and `PROCESSING`, then reaches exactly one of `COMPLETED`, `COMPLETED_WITH_ERRORS`, or `FAILED`. A status never moves backward. Version 1 doesn't support cancelling a queued upload; uploading the same file again creates a new, independent upload rather than resuming or retrying the original.

## Access and retention

Every read and every data change an upload performs applies the running user's own sharing, object, and field access — configuration can never grant access to an object, field, extension class, or merge strategy that isn't already allowed through Salesforce's own permission model.

Retention is one setting per process (**History Retention Days**, 7–365 days, default 90) that applies to that process's upload history and its input and result Files together — there's no separate retention period for files versus history.

Supported subscriber editions are Enterprise, Unlimited, Performance, and Developer Edition, on Salesforce API version 66.0 or later.

## Related

- [Product limits](../admin/limits.md) (the same facts, admin-facing)
- [CSV and results contract](csv-and-results-contract.md)
- [Package and compatibility](package-and-compatibility.md)
- [Unsupported features](unsupported-features.md)
