# Run the first upload

> [!NOTE]
> On this page, upload a small test CSV through one configured process, watch it finish, and download the result.

## Before you start

- Someone has [installed Bulk Record Upload](install.md) in this org.
- You have the **Bulk Record Upload User** permission set — see [Assign permissions](permissions.md).
- An admin has created at least one active upload process (for example, "insert new Contacts") and told you which one to use, or placed a page for it.
- You have Create or Edit access (whichever the process needs) on the target object and every field it maps.

## Try it, step by step

1. **Open Bulk Record Upload.** Click the App Launcher (the grid icon, top-left corner of Salesforce), search for **Bulk Record Upload**, and open it. If your admin instead gave you a direct link or placed the component on a record page, use that instead.

2. **Pick the process, if asked.** If more than one upload process is available to you, you'll see a list to choose from first — pick the one your admin told you to use. If only one process is available, or your admin built a page fixed to one process, this step doesn't appear at all — you'll go straight to choosing a file.

3. **Choose your CSV file.** Save it as a `.csv` file (Excel's and Google Sheets' default "Save As" / "Download" option produces this correctly). The column headers in row 1 must match exactly what your admin configured — if you're not sure what they are, ask, or use a downloadable template if your admin provided one.

4. **Review the preview.** Bulk Record Upload shows you the first several rows of your file before anything is saved, plus a summary of how many rows look ready and how many have a problem — so you can catch a typo'd header or an obviously bad value before committing the whole file.

5. **Click Submit.** This is the only time you click it — clicking Submit again on the same file won't create duplicate records, but there's no need to test that. The upload now runs in the background; you can leave the page.

6. **Watch it finish.** You'll see a status that moves through a few stages: **Queued** (waiting its turn), **Validating** (checking the file), **Processing** (saving records), and then one of three final states — see what each one means in [Monitor an upload](../user/monitor-upload.md).

7. **Download the result.** Once it's done, download the result file. Each row lines up with a row from your original CSV (matched by row number) and shows whether that row succeeded, the Id of the record it created or changed, and — if it failed — a plain-language reason why. See [Understand results](../user/understand-results.md) for exactly what's in this file.

## What you'll see when it works

A status of **Completed**, and a result file where every row shows success with a record Id. For your very first try, use a small file — two or three rows, no real customer data — so it's easy to check every row by hand.

## If something goes wrong

| What you see                                    | What it means                                           | What to do                                                                                                                                          |
| ----------------------------------------------- | ------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| An error before you can even choose a process   | You likely don't have the right permission set assigned | See [Assign permissions](permissions.md)                                                                                                            |
| The file is rejected before the preview appears | The column headers don't match what's configured        | Check for typos, extra spaces, or a header the admin didn't configure — see [Prepare a CSV](../user/prepare-csv.md)                                 |
| The status ends at **Completed with errors**    | Some rows succeeded and some didn't                     | Download the result file — the successful rows are already saved, and the failed rows each show a reason. Fix just those rows and upload them again |
| The status ends at **Failed**                   | Nothing was saved                                       | Check the result file's error messages, or see [Understand results](../user/understand-results.md)                                                  |

## Next steps

Read [Prepare a CSV](../user/prepare-csv.md) and [Understand results](../user/understand-results.md).
