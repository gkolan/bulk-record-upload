# Preview and submit

> [!NOTE]
> On this page, validate a selected CSV, understand the capped preview, and submit one upload safely.

The browser validates file name, size, encoding, structure, row count, headers, and required columns before submission; Apex repeats trusted validation. The preview shows at most 10 rows and 20 source columns even when the process supports 100 configured columns.

Review the selected process, operation, row count, validation summary, and file name. Submission creates a unique request key, stores the input File, stages rows, and queues processing. Repeating the same request key returns the existing upload instead of adding another job.

When the administrator configures **Bulk Record Upload** with one resolved process, no process selector appears. The server validates that process before loading the page, scopes displayed history to it, and rejects a missing, inactive, inaccessible, or invalid configuration. The CSV and submission steps are otherwise identical to a multi-process bundle.

## Next steps

[Monitor the upload](monitor-upload.md).
