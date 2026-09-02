# Understand upload results

> [!NOTE]
> On this page, read the result file an upload produces and know what to do with a failed row.

## Where to find it

Once your upload reaches a final status (**Completed**, **Completed with errors**, or **Failed** — see [Monitor an upload](monitor-upload.md)), download the result file from the upload's detail page. It's a CSV, the same kind of file you uploaded, with one row for every row in your original file.

## What's in it

| Column              | What it tells you                                                                                       |
| ------------------- | ------------------------------------------------------------------------------------------------------- |
| `bru_row_number`    | Which row of your original CSV this result matches. Row 2 is your first data row (row 1 is the header). |
| `bru_status`        | `SUCCESS`, `FAILED`, or `SKIPPED` for this row.                                                         |
| `bru_record_id`     | The Salesforce Id of the record that was created or changed. Blank if the row failed.                   |
| `bru_error_code`    | A short, stable code for a failed row — useful if you're reporting the problem to someone.              |
| `bru_error_message` | A plain-language explanation of what went wrong.                                                        |

Any other columns your admin configured to appear in the result (for example, a value used to double-check which record was matched) come after these five, in the order the process was configured.

**A worked example.** Say row 3 of your CSV was missing a required Last Name. Its result row would look like this:

```csv
bru_row_number,bru_status,bru_record_id,bru_error_code,bru_error_message
3,FAILED,,DML_ERROR,"REQUIRED_FIELD_MISSING: Last Name"
```

## What to do with a failure

Read `bru_error_message` for that row — it usually tells you exactly what to fix (a missing required field, a value that doesn't match an existing record, and so on). Correct just those rows in your source file and upload them again; you don't need to re-upload rows that already succeeded. If the message doesn't make sense to you, share the row and the message with your Salesforce administrator — they can check things like validation rules or duplicate rules that aren't visible from the upload screen.

## One safety note

If a value in your result file would otherwise look like a spreadsheet formula (starting with `=`, `+`, `-`, or `@`), Bulk Record Upload adds a small safety prefix so Excel or Google Sheets displays it as plain text instead of running it as a formula when you open the file.

## Related

See [Statuses and results](../reference/statuses-and-results.md) for the complete technical reference, including every reason code.
