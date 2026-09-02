# Run the first upload

> [!NOTE]
> On this page, upload a small test CSV through one configured process, watch it finish, and download the result.

Trying the project for the first time? The [quick start](quick-start.md) includes installation, configuration, and a ready-to-upload sample file.

## Before you start

- Someone has [installed Bulk Record Upload](install.md) in this org.
- You have the **Bulk Record Upload User** permission set — see [Assign permissions](permissions.md).
- An admin has created at least one active upload process and [configured a Lightning page](../admin/configure-lightning-pages.md).
- You have Create or Edit access (whichever the process needs) on the target object and every field it maps.

## Try it, step by step

1. **Open the configured Lightning page.** Use the record page or app page your administrator configured. For the supplied demo, open **Bulk Record Upload** from the App Launcher, choose **Accounts**, open an Account, and use **1. Selected Process** on **Details**.

2. **Pick the process, if asked.** If more than one upload process is available to you, you'll see a list to choose from first — pick the one your admin told you to use. If only one process is available, or your admin built a page fixed to one process, this step doesn't appear at all — you'll go straight to choosing a file.

3. **Download the template, then choose your CSV file.** Select the process, click **Template**, and use those exact headers. Save the completed file as UTF-8 `.csv`.

4. **Review the preview.** Bulk Record Upload shows the first several rows before anything is saved,
   plus a count of rows that look ready and rows with a problem. Correct a misspelled header or a
   value that does not match the configured field type before submitting the file.

5. **Confirm and submit once.** Complete the confirmation shown by the component. The upload runs in the background. A new Insert upload of the same CSV can create additional records, so inspect the previous result before submitting a file again.

6. **Watch it finish.** You'll see a status that moves through a few stages: **Queued** (waiting its turn), **Validating** (checking the file), **Processing** (saving records), and then one of three final states — see what each one means in [Monitor an upload](../user/monitor-upload.md).

7. **Download the result.** Once it's done, download the result file. Each row lines up with a row from your original CSV (matched by row number) and shows whether that row succeeded, the Id of the record it created or changed, and — if it failed — a plain-language reason why. See [Understand results](../user/understand-results.md) for exactly what's in this file.

## What you'll see when it works

A status of **Completed**, and a result file where every row shows success with a record Id. For your very first try, use a small file — two or three rows, no real customer data — so it's easy to check every row by hand.

## If something goes wrong

| What you see                                    | What it means                                                      | What to do                                                                                                                                                 |
| ----------------------------------------------- | ------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| An error before you can even choose a process   | You likely don't have the right permission set assigned            | See [Assign permissions](permissions.md)                                                                                                                   |
| The file is rejected before the preview appears | The column headers don't match what's configured                   | Check for typos, extra spaces, or a header the admin didn't configure — see [Prepare a CSV](../user/prepare-csv.md)                                        |
| The status ends at **Completed with errors**    | Some rows succeeded and some didn't                                | Download the result file — the successful rows are already saved, and the failed rows each show a reason. Fix just those rows and upload them again        |
| The status ends at **Failed**                   | The upload stopped because of a file, setup, or processing problem | Download the result if one is available. Rows completed before the stop can already be saved. Then see [Understand results](../user/understand-results.md) |

## Next steps

Read [Prepare a CSV](../user/prepare-csv.md) and [Understand results](../user/understand-results.md).
