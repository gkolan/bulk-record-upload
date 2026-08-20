# Product limits

> [!NOTE]
> On this page, check the hard limits before configuring a process or preparing a CSV, and what actually happens when a file hits one.

| Limit                   | Value                                             | What happens if you go over it                                                                                                                                                                                                      |
| ----------------------- | ------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| File size               | 2 MiB                                             | The file is rejected outright, before any row is read.                                                                                                                                                                              |
| Data rows               | 5,000                                             | The file is rejected — split it into smaller files and upload each one.                                                                                                                                                             |
| Configured columns      | 100                                               | The process itself can't be activated with more than 100 columns configured.                                                                                                                                                        |
| Cell length             | 32,000 characters                                 | That cell's row fails validation. Only relevant for very long text like notes.                                                                                                                                                      |
| Header length           | 255 characters                                    | A column header longer than this is rejected — not a realistic limit for ordinary column names.                                                                                                                                     |
| Batch/chunk rows        | 25–200                                            | Not a file limit — this is a per-process setting (**Rows per Batch**, see [Configure an upload process](configure-upload-process.md)) controlling how many rows are saved together in one step behind the scenes.                   |
| Durable chunks          | 200                                               | The most pieces one file can be split into for processing. At the smallest allowed batch size (25 rows), this caps a single upload well above the 5,000-row limit above — in practice you'll hit the row limit first, not this one. |
| History kept            | 7–365 days                                        | Set per process. Older upload history and result files are cleaned up automatically; this doesn't affect the records the upload already created or changed.                                                                         |
| Browser preview         | 10 rows, 20 columns                               | The preview screen only ever shows this much, even for a bigger file — the full file still processes completely once submitted.                                                                                                     |
| Uploads running at once | 1 per person per process, 10 across the whole org | Starting another upload of the same process while one is still running is rejected — wait for it to finish first. This doesn't limit how many uploads you run over a day, only how many are active at the same moment.              |

## Why a file might be slow even under the size limit

A file well under 2 MiB can still take a while to process if it's very wide — many columns, each with a lot of text in every cell. If a large upload is taking noticeably longer than similar smaller ones, try splitting it into a few smaller files rather than one very wide one.

## Next steps

[Prepare a CSV](../user/prepare-csv.md).
