# Statuses and results

> [!NOTE]
> On this page, look up upload lifecycle values and the independently versioned result CSV contract.

Lifecycle version 1 moves through `QUEUED`, `VALIDATING`, and `PROCESSING` to `COMPLETED`, `COMPLETED_WITH_ERRORS`, or `FAILED`. Stored transitions are monotonic.

Result schema version 1 begins with `bru_row_number`, `bru_status`, `bru_record_id`, `bru_error_code`, and `bru_error_message`. `bru_status` is `SUCCESS`, `FAILED`, or `SKIPPED`; configured safe fields follow in projection order. Additive fields may appear within a version, while removal or renaming requires a new schema version.

Integrations branch on these stored status values and `bru_error_code`, never on editable labels or `bru_error_message`.

## Package-defined reason codes

| Reason code                             | Meaning                                                                                                                          |
| --------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `PROCESSING_ERROR`                      | Processing stopped before the package could produce a complete result.                                                           |
| `PERSISTENCE_COMPLETED_REPORTING_ERROR` | Target-record changes committed, but result reporting did not complete. An administrator must review the upload before retrying. |
| `DML_ERROR`                             | Salesforce returned no more specific row-level DML status code.                                                                  |

Salesforce DML status codes can also appear as row reason codes. They are stable platform API values. Messages remain safe, bounded diagnostic wording and are not integration contracts.

## Related

See [Understand results](../user/understand-results.md) and [CSV and results contract](csv-and-results-contract.md).
