# Run the first upload

> [!NOTE]
> On this page, confirm one configured process with a small CSV and download the correlated result.

1. Open the **Bulk Record Upload** Lightning application or an administrator-created configured-process page.
2. In the upload center, select an active upload process. A configured-process page has already fixed this choice and does not show a selector.
3. Choose a UTF-8 `.csv` file whose normalized headers match the configured column keys.
4. Review the capped preview and validation summary.
5. Submit once and monitor the status through `QUEUED`, `VALIDATING`, `PROCESSING`, and a terminal result.
6. Download the result CSV and match `bru_row_number` to the source row.

Start with two rows and no sensitive values. A partial result keeps successful records and reports a safe code and message for each failed row.

## Next steps

Read [Prepare a CSV](../user/prepare-csv.md) and [Understand results](../user/understand-results.md).
