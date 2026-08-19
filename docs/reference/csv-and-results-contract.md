# CSV and results contract

> [!NOTE]
> On this page, prepare a compatible CSV file and understand the stable columns returned for each processed row.

## Input CSV 1.0

Use UTF-8 with an optional byte-order mark, a comma delimiter, and CRLF or LF record endings. The first record is the required header. Wrap a cell in double quotes when it contains a comma, quote, or record ending; represent a literal quote with two quotes.

Headers are trimmed and compared without case. Duplicate headers are rejected. A header resolves only to a field configured for the selected process. Blank trailing records are ignored; blank records between data records keep their physical row number.

```csv
Name,External Key,Description
"Example, Inc.",EX-100,"Uses ""quoted"" text"
```

## Results CSV 1.0

Every results file begins with these columns in order:

| Column              | Meaning                                                   |
| ------------------- | --------------------------------------------------------- |
| `bru_row_number`    | One-based physical data-row number from the input file    |
| `bru_status`        | `SUCCESS`, `FAILED`, or `SKIPPED`                         |
| `bru_record_id`     | Salesforce record ID when the running user may receive it |
| `bru_error_code`    | Stable documented reason code when processing fails       |
| `bru_error_message` | Redacted administrator-safe explanation                   |

Configured result fields follow in stable process order. “All result fields” means every configured process field, never every field on the Salesforce object.

```csv
bru_row_number,bru_status,bru_record_id,bru_error_code,bru_error_message,Name,External Key
2,SUCCESS,001000000000001,,,"Example, Inc.",EX-100
```

Result writing neutralizes spreadsheet formula triggers while retaining useful display text. CSV contents and field values do not enter operational logs.

## Related

- [Product contract](product-contract.md)
- [First-upload contract example](../examples/first-upload-contract.md)
