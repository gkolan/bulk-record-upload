# CSV format

> [!NOTE]
> On this page, look up the exact encoding and formatting rules a CSV file must follow — for the row and column limits, see [Product limits](../admin/limits.md) instead.

- **Encoding:** UTF-8, with or without a byte-order mark.
- **Delimiter:** comma.
- **Quoting:** wrap a value in double quotes when it contains a comma, a quote character, or a line break; write a literal quote as two quotes in a row (`""`).
- **Line endings:** either CRLF or LF are accepted.
- **Header row:** required, must be the first row, and every header must be unique after trimming whitespace and ignoring case — `Name` and `name ` are treated as the same header and rejected if both appear.
- **Header match:** every header must match a column configured for the process you're uploading to; an uploaded column the process doesn't recognize is rejected, the same way a required configured column that's missing from the file is rejected.

See [Product limits](../admin/limits.md) for the exact size, row, and column caps, and [Prepare a CSV](../user/prepare-csv.md) for a worked example file.

## What causes an immediate rejection

A `NUL` byte anywhere in the file, a quoted value that's never closed, or a row with a different number of columns than the header row — all of these fail before any record is touched, the same way an oversized file does.

## A note on very wide rows

The row-count and file-size limits in [Product limits](../admin/limits.md) are the main ones to plan around, but a single unusually wide row — many columns, each holding a lot of text — can hit an internal processing limit before either of those does. If a file with very long text values (like large description fields) is rejected in a way the row/size limits don't explain, try splitting it into rows with less text per cell, or fewer columns per file.

## Related

See [Prepare a CSV](../user/prepare-csv.md), [Product limits](../admin/limits.md), and the [CSV and results contract](csv-and-results-contract.md) for the exact column schema a results file returns.
