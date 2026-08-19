# Prepare a CSV

> [!NOTE]
> On this page, create a bounded UTF-8 CSV whose headers and values match the selected upload process.

Use one header row followed by at most 5,000 data rows. Headers are trimmed and normalized and must be unique; each must match a configured column key. Quote values containing commas, quotes, or line breaks, and escape a quote as `""`.

```csv
name,industry
Acme Manufacturing,Manufacturing
Northwind,"Retail, Specialty"
```

Keep the file below 2 MiB and each cell below 32 KiB. Formula-like result values are neutralized when the package writes result files.

## Next steps

[Preview and submit](preview-and-submit.md) or consult the [CSV reference](../reference/csv-format.md).
