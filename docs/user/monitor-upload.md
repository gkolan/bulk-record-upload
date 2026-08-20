# Monitor an upload

> [!NOTE]
> On this page, follow an upload's progress and recognize when it's actually finished.

## What you'll see

After you submit a file, its status moves forward through a few stages, shown on screen as a label:

| Status                    | What it means                                                                    |
| ------------------------- | -------------------------------------------------------------------------------- |
| **Queued**                | Your file is waiting its turn — nothing has happened yet.                        |
| **Validating**            | Bulk Record Upload is checking the file's structure before touching any records. |
| **Processing**            | Records are actively being created, updated, or deleted.                         |
| **Completed**             | Every row succeeded.                                                             |
| **Completed with errors** | Some rows succeeded, some failed — the successful ones are already saved.        |
| **Failed**                | Nothing was saved.                                                               |

An upload only ever moves forward through this list — it never jumps back to an earlier stage. **Completed**, **Completed with errors**, and **Failed** are the three possible endings; once you see one of those, the upload is done.

To check on one, open **Bulk Record Upload** and look at the upload history — refresh it to see the latest status, row counts, and timestamp for each upload you can see.

## A few things worth knowing

- **You can't cancel an upload once it's queued.** Let it finish, then deal with any failed rows afterward.
- **Uploading the same file again is a brand-new upload, not a retry.** It processes every row in the file again — it doesn't automatically skip the rows that already succeeded last time. If only some rows failed, either fix and re-upload just those rows, or expect the successful rows to be processed again (which is safe for most operations, but check with your admin if you're unsure).

## Next steps

[Understand the result](understand-results.md) or see [troubleshooting](../admin/troubleshooting.md) if something looks wrong.
