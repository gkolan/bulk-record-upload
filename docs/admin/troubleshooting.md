# Troubleshooting

> [!NOTE]
> On this page, work through what a person actually sees, in order, to find and fix the cause — without ever needing to paste CSV data or record values anywhere.

## The process isn't available / the component shows nothing

**Likely cause:** the process, or the bundle it's assigned to, isn't active or isn't set up right.

1. In Setup, open **Custom Metadata Types** > **Bulk Record Upload Process**, find the process, and confirm **Is Active** is checked.
2. Open **Bulk Record Upload Bundle**, confirm the bundle the component points to is active.
3. Open **Bulk Record Upload Bundle Process**, confirm there's an active record linking that bundle to that process, with the right Developer Names spelled exactly right (a typo here is the most common cause).

**Recovery:** fix whichever record is inactive or misspelled, save, and reload the page — no deploy needed, Custom Metadata changes take effect immediately.

## "You don't have access to run this process" / not authorized

**Likely cause:** a missing permission, somewhere between the Bulk Record Upload layer and the underlying Salesforce object.

Check, in this order:

1. Does the user have the **Bulk Record Upload User** permission set assigned? See [Assign permissions](../get-started/permissions.md).
2. Does the user have Create or Edit access (whichever the process needs) on the target object?
3. Can the user edit every field the process maps? Check **Setup** > **Object Manager** > _(the object)_ > **Fields & Relationships** > _(the field)_ > **Field-Level Security**.
4. Can the user actually see the specific records involved (sharing rules), for an Update, Upsert, or Delete process?
5. Running Delete specifically? They also need **Bulk Record Upload Deletion** (`Bulk_Record_Upload_Delete_Access`).
6. Trying to preview rows and it's blocked? Some processes require an additional Custom Permission beyond the standard preview access — check the process's **Additional Preview Permission** field for one, and confirm the user has it if so.

**Recovery:** assign whatever's missing from the list above, in Setup.

## The file is rejected before the preview even shows up

**Likely cause:** the CSV's headers don't match what's configured, or the file itself is malformed.

1. Confirm the file is saved as `.csv` and UTF-8 (Excel's and Google Sheets' default export does this).
2. Compare the header row, character for character, against the configured columns — see [Configure field behaviors](configure-field-behaviors.md) for what each column expects. A common cause is a header with different capitalization or an extra space than what's configured.
3. Confirm no header is repeated twice in the same file.

**Recovery:** fix the header row and re-upload.

## Some or all rows fail

**Likely cause:** the failure reason is already in the result file — that's the fastest way to find it, faster than guessing here.

1. Download the result file for that upload (see [Understand results](../user/understand-results.md)) and read `bru_error_message` for the failed rows.
2. If the message names a specific field or value problem, fix that in the source CSV.
3. If the message doesn't explain enough, check the object for a **validation rule**, a **duplicate rule**, or **automation** (a Flow or trigger) that could be rejecting the record — these run the same way for an upload as they would for a manual save.

**Recovery:** fix just the failed rows in your source file and upload them again — rows that already succeeded don't need to be re-uploaded.

## The result file isn't available anymore

**Likely cause:** the upload hasn't finished yet, or its retention period has passed.

1. Confirm the upload actually reached a final status — **Completed**, **Completed with errors**, or **Failed** — not still **Queued**, **Validating**, or **Processing**.
2. Check the process's **History Retention Days** setting — older uploads and their result files are cleaned up automatically once that many days have passed.
3. Confirm the user has access to the Salesforce File the result is stored in — normal Salesforce File sharing applies.

**Recovery:** if retention has passed, the file is gone and the upload needs to be run again to get a fresh result.

## Reporting a problem

If none of the above explains it, use the [support policy](../../SUPPORT.md) to file a reproducible defect. Don't paste CSV contents, credentials, org Ids, or any sensitive record values into a public issue — describe the symptom and the steps above that you already tried instead.
