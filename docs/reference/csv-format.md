# CSV format

> [!NOTE]
> On this page, look up the accepted encoding, dialect, normalization, and size rules for version 1 CSV files.

Files use UTF-8, comma delimiters, double-quoted values, doubled quote escaping, and CRLF or LF line endings. A header is required. Trimmed, case-normalized headers must be unique and match configured column keys; blank, missing required, unknown, or confusable headers are rejected.

The server enforces 2 MiB, 5,000 data rows, 100 configured columns, and 32 KiB per cell. NUL bytes, malformed quoting, mismatched column counts, and unterminated quoted values fail before DML.

The configured batch size controls rows processed per asynchronous transaction; it does not reduce the 5,000-row upload limit. Very wide rows can still reach the independent safe serialized-chunk limit first.

The 2 MiB ceiling is enforced, but maximum-size synchronous parser CPU performance remains an open release benchmark. It must not be interpreted as guaranteed throughput for every combination of quoting, row width, and cell length.

## Related

See [Prepare a CSV](../user/prepare-csv.md) and [Product limits](../admin/limits.md).
