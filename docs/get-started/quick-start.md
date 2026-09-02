# Quick start: upload two sample Accounts

> [!NOTE]
> On this page, install the source, load the supplied demo configuration, and upload two fictional Accounts through Salesforce Lightning.

Use a dedicated Developer Edition org or development sandbox with API 67.0, Salesforce CLI v2, and Node.js 22 or later. You need permission to deploy metadata, assign permission sets, and create Accounts. No promoted package installation link is available yet.

## 1. Install the application

Follow [Install from source](install.md) through **Validate and deploy**. That guide covers downloading this repository, signing in, and checking the deployment result.

The commands below use the same `bru-demo` alias. Before each org-affecting command, run `sf org display --target-org bru-demo` and confirm it still points to your intended development org.

## 2. Load the sample configuration

From the repository root, validate the optional examples:

```bash
sf org display --target-org bru-demo
sf project deploy start --dry-run --source-dir examples/main/default --target-org bru-demo --test-level NoTestRun --wait 30
```

After validation succeeds, deploy them:

```bash
sf org display --target-org bru-demo
sf project deploy start --source-dir examples/main/default --target-org bru-demo --test-level NoTestRun --wait 30
```

These examples contain configuration, demo fields, and a permission set; they add no Apex classes. They install Insert, Update, Upsert, and Delete processes for Account, Contact, and Opportunity. This walkthrough uses **Account Insert Demo** only. Delete processes still require the separate Delete Access permission.

Continue when the example deployment reports **Succeeded**. No seed script is needed for this first Insert demonstration.

## 3. Give yourself demo access

In Salesforce, open **Setup → Permission Sets**. For each set below, select **Manage Assignments → Add Assignment**, choose your user, and complete the assignment:

| Permission set label                    | API name                                |
| --------------------------------------- | --------------------------------------- |
| Bulk Record Upload — User               | `Bulk_Record_Upload_User`               |
| Bulk Record Upload — Preview Access     | `Bulk_Record_Upload_Preview_Access`     |
| Bulk Record Upload — Demo Target Access | `Bulk_Record_Upload_Demo_Target_Access` |

The demo target set grants object access for all three example objects and selected demo fields. Your profile or another permission set must also allow the mapped Account fields: Name, Description, Phone, Website, Number of Employees, and Annual Revenue. Use [permissions](permissions.md) to configure access for regular users.

## 4. Open the demo page

1. In the **App Launcher**, open **Bulk Record Upload**.
2. Select **Accounts** in the app navigation.
3. Create an Account named **Upload Demo Workspace**, then open that record.
4. On **Details**, find **1. Selected Process**, which uses `Account_Insert_Demo`.

The source includes an Account record page assigned inside this application. The other two upload components demonstrate process selection; use the first component for this walkthrough. The sample Insert creates separate Accounts; the open Account is only where the component is displayed.

If the component is missing, open **Setup → Lightning App Builder → Account Bulk Record Upload Demo**, then check its activation for Account in the **Bulk Record Upload** application. See [page configuration](../admin/configure-lightning-pages.md) for the assignment steps.

## 5. Upload the sample CSV

1. Click **Template** in **1. Selected Process** and compare its headers with [Account_Insert_Demo.csv](../examples/demo/Account_Insert_Demo.csv).
2. Choose that CSV from your downloaded repository at `docs/examples/demo/Account_Insert_Demo.csv`. It contains two fictional rows, **Bulk Upload CSV Account One** and **Bulk Upload CSV Account Two**.
3. Review the displayed rows and complete the confirmation shown by the component, then submit once.
4. Wait for the upload to finish. Use **View Status** to inspect the upload and download its result file.

Submitting a new Insert upload again can create additional records. For a repeat demonstration, inspect or remove the two previously created sample Accounts first.

## 6. Check the result

You should see **Completed**, two successful rows, and no failed rows. The result CSV should include a Salesforce record ID for each created Account. In **Accounts**, find the two sample names and confirm their values.

| What you see          | What to check                                                                                                   |
| --------------------- | --------------------------------------------------------------------------------------------------------------- |
| No active process     | Confirm the example deployment succeeded, the process and fields are active, and your permissions are assigned. |
| CSV header error      | Use the supplied Account Insert file, or copy its rows into the freshly downloaded template.                    |
| Field access error    | Check Account Create/Read access and field permissions for every mapped field.                                  |
| Completed with errors | Download the result and correct only the failed rows; successful rows are already saved.                        |
| Failed                | Inspect the error and any available results before retrying; earlier rows can already be saved.                 |

This is a documented evaluation path based on the supplied source and demo assets. A fresh hands-on walkthrough of this guide remains part of the open release review.

## Next steps

Use the [short user guide](first-upload.md) for everyday uploads, [configure your own process](../admin/configure-upload-process.md), or explore Update, Upsert, and Delete with the [three-object demonstration kit](../examples/demo/README.md).
