# Statuses and results

> [!NOTE]
> On this page, look up every lifecycle status and every reason code an upload can produce, and what each one means.
> **Reference:** the exact stored values automation should branch on. See [CSV and results contract](csv-and-results-contract.md) for the full results-file column schema, and [Monitor an upload](../user/monitor-upload.md) for the same statuses explained for an end user.

## Lifecycle status

| Status                  | Meaning                                |
| ----------------------- | -------------------------------------- |
| `QUEUED`                | Waiting to be picked up.               |
| `VALIDATING`            | The file's structure is being checked. |
| `PROCESSING`            | Rows are actively being saved.         |
| `COMPLETED`             | Every row succeeded.                   |
| `COMPLETED_WITH_ERRORS` | Some rows succeeded, some failed.      |
| `FAILED`                | Nothing was saved.                     |

A status only ever moves forward through this list, never backward. `COMPLETED`, `COMPLETED_WITH_ERRORS`, and `FAILED` are the three possible endings.

## Row status

Each row in the results file gets its own `bru_status`: `SUCCESS`, `FAILED`, or `SKIPPED`. See [CSV and results contract](csv-and-results-contract.md) for where this column sits in the full results schema.

## Reason codes

When a row's `bru_status` is `FAILED`, `bru_error_code` is one of these package-defined codes, or a Salesforce DML status code passed straight through:

| Reason code                             | Meaning                                                                                                                                                                                 |
| --------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `PROCESSING_ERROR`                      | Processing stopped before a complete result could be produced for this row.                                                                                                             |
| `PERSISTENCE_COMPLETED_REPORTING_ERROR` | The record was actually saved, but something went wrong producing the result row for it — an administrator should review this upload directly rather than treat it as a normal failure. |
| `DML_ERROR`                             | Salesforce rejected the row and didn't return a more specific code — `bru_error_message` has the detail.                                                                                |

Any other code you see is a standard Salesforce DML status code (for example, one naming a specific validation rule) — these are stable, documented Salesforce platform values, not something this package invents.

**Build automation against `bru_status` and `bru_error_code` only** — they're the stable, versioned contract. `bru_error_message` can change wording between releases; it's for a person to read, not for a script to pattern-match.

Additive columns can appear in a future results-schema version without breaking existing automation; removing or renaming a column requires a new schema version.

## Related

See [CSV and results contract](csv-and-results-contract.md) and [Understand results](../user/understand-results.md).
