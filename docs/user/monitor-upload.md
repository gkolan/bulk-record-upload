# Monitor an upload

> [!NOTE]
> On this page, follow upload progress and recognize when processing has reached a final state.

Uploads move forward through `QUEUED`, `VALIDATING`, and `PROCESSING`. Final states are `COMPLETED`, `PARTIAL`, and `FAILED`; transitions never move backward. Refresh history to see safe counts and timestamps for records visible to you.

Version 1 does not cancel a queued job. A retry is a new upload request; it does not automatically replay only prior failures.

## Next steps

[Understand the result](understand-results.md) or use [troubleshooting](../admin/troubleshooting.md).
