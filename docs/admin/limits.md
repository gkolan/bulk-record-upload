# Product limits

> [!NOTE]
> On this page, check the hard limits before configuring a process or preparing a CSV.

| Limit              |               Version 1 value |
| ------------------ | ----------------------------: |
| UTF-8 file size    |                         2 MiB |
| Data rows          |                         5,000 |
| Configured columns |                           100 |
| Cell length        |             32,000 characters |
| Batch/chunk rows   |                        25–200 |
| Durable chunks     |                           200 |
| Retention          |                    7–365 days |
| Browser preview    | 10 rows and 20 source columns |

The near-800-field benchmark describes only configured fields and never returns all object fields. See [Step 8 evidence](../evidence/08-large-org-benchmarks/README.md).

Chunks run as one Batch Apex job with a scope of one chunk. This avoids dependence on edition-specific Queueable chain-depth limits while preserving one bounded transaction per chunk.

The 2 MiB value is a structural rejection limit, not a validated synchronous CPU guarantee. Until the maximum-size parser benchmark is complete, administrators should test representative wide files and use smaller files if parsing approaches transaction CPU limits.

## Next steps

[Prepare a CSV](../user/prepare-csv.md).
