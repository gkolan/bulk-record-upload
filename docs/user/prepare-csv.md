# Prepare a CSV

> [!NOTE]
> On this page, build a CSV file that Bulk Record Upload will accept, with a working example to copy.

## The shape of a valid file

One header row, then your data — nothing fancier than any CSV you'd open in Excel or Google Sheets:

```csv
name,industry
Acme Manufacturing,Manufacturing
Northwind,"Retail, Specialty"
```

A value containing a comma, a quote, or a line break needs to be wrapped in quotes (like `"Retail, Specialty"` above) — this is standard CSV behavior, the same as what Excel produces automatically when you save a file with a comma in a cell. A literal quote inside a quoted value is written as two quotes in a row (`""`).

## Column headers must match exactly

Each header in your file must be spelled and spaced exactly like the column your admin configured for this upload process — check with them, or use a downloadable template if one's provided. Extra spaces around a header are trimmed automatically, and headers can't repeat within the same file, but the text itself must match.

## A few limits to keep in mind

| Limit                             | What it means for you                                                                               |
| --------------------------------- | --------------------------------------------------------------------------------------------------- |
| Save as UTF-8                     | The default when saving from Excel or Google Sheets — you don't usually need to do anything special |
| At most 5,000 data rows per file  | A bigger export needs to be split into multiple files                                               |
| File size under 2 MiB             | Roughly tens of thousands of typical rows, depending on how much text is in each cell               |
| Each cell under 32,000 characters | Only relevant for very long text fields like notes or descriptions                                  |

If your file is too big, splitting it into smaller files and uploading each one separately works fine.

## Next steps

[Preview and submit](preview-and-submit.md) or consult the [CSV reference](../reference/csv-format.md) for the exact technical rules.
