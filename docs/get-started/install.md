# Install Bulk Record Upload

> [!NOTE]
> On this page, deploy Bulk Record Upload into a Salesforce org and confirm it worked, on Windows, macOS, or Linux.

## Before you start

You need:

- A Salesforce sandbox or Developer Edition org you can deploy to (API version 66.0 or later).
- [Salesforce CLI v2](https://developer.salesforce.com/tools/salesforcecli) installed (`sf --version` should print something).
- [Node.js](https://nodejs.org) installed, so `npm` works.
- This repository checked out locally.

## Install it, step by step

1. **Install the repository's tooling.** From the repository's root folder:

   ```bash
   npm ci
   ```

2. **Confirm you're pointed at the right org.** This is the single most important step — a deploy goes to whatever org is targeted, and mixing that up can overwrite someone else's work.

   ```bash
   sf org display --target-org <your-org-alias> --json
   ```

   In the output, check that `instanceUrl` is the sandbox or Developer Edition org you actually mean to use. If you're not sure what your org's alias is, run `sf org list` to see every org you're authenticated to.

3. **Deploy the source.**

   ```bash
   sf project deploy start --manifest manifest/package.xml --target-org <your-org-alias> --test-level RunSpecifiedTests --tests BulkRecordUploadConfigProjectionTest --wait 30
   ```

## What you'll see when it works

The terminal prints a deploy report ending in `Status: Succeeded`, with the test result showing `Pass Rate: 100%`. Back in Salesforce, click the App Launcher (the grid icon in the top-left corner), search for **Bulk Record Upload**, and open it — seeing the app in that list confirms the install worked.

## If something goes wrong

| What you see                                                                  | What it means                                                                                                                  | What to do                                                                                                                                                                     |
| ----------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `INSUFFICIENT_ACCESS` during deploy                                           | Your Salesforce user doesn't have permission to deploy metadata                                                                | Ask whoever administers the org to deploy it, or grant your user the **Modify All Data** or **Author Apex** permission                                                         |
| A test failure naming `BulkRecordUploadConfigProjectionTest` or another class | Something in the org conflicts with the package (an existing object, a Custom Metadata Type name collision, or a stale deploy) | Re-run with `--test-level RunLocalTests` to see whether other tests also fail — if only this one does, check the deploy report's error message for the specific cause it names |
| The app doesn't appear in the App Launcher after a successful deploy          | Your user may not be assigned a permission set yet                                                                             | This is expected — installing the package doesn't grant access by itself. Continue to [Assign permissions](permissions.md)                                                     |

## Next steps

[Assign permissions](permissions.md), then [configure an upload process](../admin/configure-upload-process.md).

Public releases install as an unlocked package version instead of source — once a package version is available, installing it is a single **Install Package** click from the install link, with no CLI required. This page covers the source-deployment path used during development and contribution.
