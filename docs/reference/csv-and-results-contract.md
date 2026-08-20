# CSV and results contract

> [!NOTE]
> On this page, see a real example of a valid input file and a real example of the results file it produces.
> **Reference:** the versioned schema contract. See [CSV format](csv-format.md) for the encoding/dialect rules and [Statuses and results](statuses-and-results.md) for what each status and reason code means.

## Input CSV 1.0

```csv
Name,External Key,Description
"Example, Inc.",EX-100,"Uses ""quoted"" text"
```

A header resolves only to a column actually configured for the process being uploaded to — an unrecognized header is rejected the same way a missing required one is. See [CSV format](csv-format.md) for the full encoding and quoting rules this example follows.

## Results CSV 1.0

Every results file begins with these five columns, in this order, no matter what the process is configured with:

| Column              | Meaning                                                                                                                   |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| `bru_row_number`    | The matching row number from the input file (row 2 is the first data row).                                                |
| `bru_status`        | `SUCCESS`, `FAILED`, or `SKIPPED`.                                                                                        |
| `bru_record_id`     | The Salesforce Id of the record created or changed — blank if the row failed.                                             |
| `bru_error_code`    | A short, stable code for a failed row. See [Statuses and results](statuses-and-results.md) for what each one means.       |
| `bru_error_message` | A plain-language explanation, safe to show to the person who ran the upload — never a raw stack trace or internal detail. |

Whichever columns the process is configured to include in results follow after these five, in the order they're configured — never every field on the target object, only the ones the process explicitly includes.

```csv
bru_row_number,bru_status,bru_record_id,bru_error_code,bru_error_message,Name,External Key
2,SUCCESS,001000000000001,,,"Example, Inc.",EX-100
```

If a value in the results file would otherwise be read as a spreadsheet formula (starting with `=`, `+`, `-`, or `@`), a safety prefix is added so Excel or Google Sheets displays it as plain text instead of running it as a formula. Nothing in the CSV — input or results — is written into operational logs.

## Related

- [Product contract](product-contract.md)
- [Statuses and results](statuses-and-results.md)
- [First-upload contract example](../examples/first-upload-contract.md)
