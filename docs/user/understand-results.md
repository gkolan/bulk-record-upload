# Understand upload results

> [!NOTE]
> On this page, correlate every result row to the source and act on success or failure without losing partial progress.

The result begins with `bru_row_number`, `bru_status`, `bru_record_id`, `bru_error_code`, and `bru_error_message`. Configured safe result fields follow in process order. `bru_row_number` uses the physical CSV row, so the first data row is row 2.

`SUCCESS` means Salesforce accepted that operation. `FAILURE` includes a stable safe code and message; inspect object access, field access, validation rules, duplicate rules, and automation before preparing a new request.

## Related

See [Statuses and results](../reference/statuses-and-results.md).
