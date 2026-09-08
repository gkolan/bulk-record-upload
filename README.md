# Bulk Record Upload for Salesforce

**Upload CSV files in Salesforce using saved field mappings and rules.**

An administrator sets up an **upload process** for a task such as creating Contacts or updating Account details. It defines which object to use, which CSV columns to accept, and how to handle each field. Users download its template, fill it in, and upload from a Lightning page. The same mappings and rules apply each time.

**Choose process → Download template → Preview CSV → Submit → Check row results**

**[Quick start](docs/get-started/quick-start.md)** · **[What makes it useful](#what-makes-this-project-useful)** · **[Choose processes](#choose-which-processes-users-see)** · **[Configure fields](#configure-what-each-field-does)** · **[Example](#a-concrete-example)** · **[Design decisions](#engineering-challenges-and-design-choices)**

Install from source in a Salesforce development org with API 67.0. No one-click package is available yet.

> **Still in development. Not ready for production.** Updates may break existing setups. Try it with sample data in a development org, and check [release status](docs/project-status.md) for unfinished work.

## What makes this project useful

You can give users a process for a recurring task and control how it changes records. For example, an Account update can append new notes to Description while leaving Phone unchanged when the CSV cell is blank. Those rules belong to the process, so users do not have to choose them for every upload.

| Capability                              | What it lets you do                                                                                                                                                     |
| --------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Reusable upload processes**           | Define separate jobs such as “Create Contacts” and “Update Account Details,” each with its own object, operation, fields, and downloadable template.                    |
| **Rules for each field**                | Append a note, keep an existing value, add to a number, or ignore a blank cell. Configure supported behaviors in Salesforce Setup.                                      |
| **Control over process choices**        | Give a page one fixed process, a selected group, or all active processes compatible with its object.                                                                    |
| **Use the page's record as the parent** | Upload Contacts from an Account page and link them to that Account without putting its Salesforce ID in every CSV row. App Pages also support choosing a parent record. |
| **Results for every row**               | Save valid rows even when other rows fail, then use the result file to identify what succeeded and what needs correction.                                               |
| **Salesforce access still applies**     | Configuration respects the user's object, field, and record access. Delete requires separate authorization.                                                             |

Standard and custom objects can have multiple processes, subject to [supported field types](docs/reference/supported-field-types.md) and permissions. The current limit is 5,000 rows per file. For behavior beyond the available settings, developers can use the documented [Apex extension](docs/developer/custom-handler.md).

## A concrete example

This example shows how a Contact upload can use the Account record you have open. Configure:

- **Process:** Contact Insert, which creates Contact records.
- **Columns:** `first_name` maps to `FirstName`, `last_name` maps to `LastName`, and `email` maps to `Email`.
- **Parent:** require the current Account and use it for the Contact's `AccountId` relationship.

The CSV contains:

```csv
first_name,last_name,email
Ada,Lovelace,ada@example.test
Grace,Hopper,grace@example.test
```

With the process, permissions, and required fields configured, this file should create two Contacts under the open Account. The CSV does not need an Account ID. Check both rows in the result file, then open the Contacts to confirm their Account.

If one row fails, the other can still be saved. Correct and retry only the failed row after checking the results. Submitting an Insert file again can create additional records.

To try a supplied example first, the [quick start](docs/get-started/quick-start.md) deploys the optional demo configuration and walks through creating two fictional Accounts from an [included CSV](docs/examples/demo/Account_Insert_Demo.csv).

## Set up an upload process

After [installing the project](docs/get-started/install.md) and [assigning permissions](docs/get-started/permissions.md):

1. **Define the job.** In Setup → **Custom Metadata Types**, create a **Bulk Record Upload Process** record. Choose the Salesforce object and operation.
2. **Define the columns and field rules.** Create **Bulk Record Upload Process Field** records linked to that process. Each mapping identifies a CSV column, its Salesforce field, and how its value is handled.
3. **Make it available on a page.** Activate the completed configuration, add **Bulk Record Upload** in Lightning App Builder, and choose which processes the component shows.

Choose the operation by the result you need:

| Operation  | Use it to…                                                             |
| ---------- | ---------------------------------------------------------------------- |
| **Insert** | Create new records.                                                    |
| **Update** | Change existing records identified by the configured match field.      |
| **Upsert** | Create or update records using a configured external-ID field.         |
| **Delete** | Remove matched records; users also need separate Delete authorization. |

Follow [Configure an upload process](docs/admin/configure-upload-process.md) for the full setup, including matching and parent-record options. After activation, reload the component, select the process, and download its template to check the configuration. Saving a configuration record alone does not validate it for upload use.

## Choose which processes users see

In Lightning App Builder, **Processes to Show** controls the choices on each **Bulk Record Upload** component. Use the same options on a Record Page or an App Page.

| You want the page to…                                            | Choose                  | Then configure                                                      |
| ---------------------------------------------------------------- | ----------------------- | ------------------------------------------------------------------- |
| Run one specific job, with no process picker                     | `SELECTED_PROCESS`      | **Selected Process**, such as the supplied `Account_Insert_Demo`.   |
| Offer a selected group of jobs                                   | `CONFIGURED_PROCESSES`  | **Upload Bundle**, a saved group of processes with a display order. |
| Offer every active, authorized process compatible with an object | `ALL_ACTIVE_FOR_OBJECT` | The record-page object, or **Object API Name** on an App Page.      |

For example, an Account page can offer Insert, Update, and Upsert through the supplied `Account_Save_Operations_Demo` bundle. A component fixed to Account Insert takes users straight to that job. Process configuration never grants access to records or fields.

Give each component a clear **Component Heading** so users know which task it serves. Follow [Configure Lightning pages](docs/admin/configure-lightning-pages.md) for page activation, bundle setup, and App Page parent-record choices.

## Configure what each field does

Each field mapping connects a CSV column to a Salesforce field and sets the rules for saving its value. Create these records in Setup → **Custom Metadata Types** → **Bulk Record Upload Process Field** → **Manage Records**.

For example, the CSV header `first_name` can map to the Contact field `FirstName`. Set the column order and required options, then download the template to check its headers.

Set these two options separately:

- **Existing Value Action** controls how a supplied value changes an existing record.
- **Blank CSV Action** controls what happens when the cell is blank.

| You need to…                                                                     | Field behavior to configure                                  |
| -------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| Update a phone number when supplied, leaving it unchanged when the cell is blank | **Replace** with **Ignore** for blanks.                      |
| Add a new note after an existing description                                     | **Append**, with a text separator and duplicate-text action. |
| Preserve a populated field while allowing an empty one to be filled              | **Keep Existing**.                                           |
| Increase a stored number by the amount in the CSV                                | **Add** on a supported numeric field.                        |
| Add selections without replacing all current selections                          | **Add Values** on a multi-select picklist.                   |
| Use a fallback when a cell is blank                                              | **Use Default**, with a configured **Default Value**.        |

For example, on an Update process, **Append** with a space separator can turn an existing Description of `Called Monday.` and an incoming value of `Follow up Friday.` into `Called Monday. Follow up Friday.` With **Replace**, the incoming text would replace the old description.

Supported settings also cover trimming spaces, changing case, validating values, building a value from other CSV columns, and matching related records by a configured field. Available actions depend on the field type; Insert has no existing value to compare, and Delete does not apply field-merge behaviors.

Start with [Configure field behaviors](docs/admin/configure-field-behaviors.md). The [field behavior reference](docs/reference/field-behaviors.md) gives exact settings and worked examples for each option.

## How an upload works

Once the process and page are configured:

1. **Choose the process, if a picker appears.** Use the job that matches the records you intend to create or change.
2. **Download the template.** Fill it in using the configured headers and save it as a UTF-8 CSV.
3. **Review the preview.** Check the rows and correct reported problems before submitting. Salesforce validation and automation can still reject rows when they are saved.
4. **Confirm and submit once.** The upload runs in the background; follow its status on the page.
5. **Check the results.** Download the result file to see each row's outcome and any error. Successful rows are already saved, even if other rows fail.

See [Run the first upload](docs/get-started/first-upload.md) for the walkthrough and [Understand results](docs/user/understand-results.md) for partial success and recovery.

## Try it yourself

Use a dedicated Developer Edition org or development sandbox with API 67.0 available. You need Salesforce CLI v2 and Node.js 22 or later for setup. Once configured, uploads run through the Salesforce UI.

Follow the [quick start](docs/get-started/quick-start.md) to install the source and demo configuration, assign permissions, and upload the two-row Account CSV. It ends with checking the results and the records you created.

For an existing installation, go straight to [Run the first upload](docs/get-started/first-upload.md). To explore Insert, Update, Upsert, and Delete for Accounts, Contacts, and Opportunities, see the [demonstration kit](docs/examples/demo/README.md).

## Engineering challenges and design choices

The project uses **Apex, Lightning Web Components, Custom Metadata, and Salesforce Files**. These are the main design choices behind the upload workflow:

| Engineering challenge                                     | Design choice and where to learn more                                                                                                                                                                                                                |
| --------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Working within Salesforce transaction limits              | Bound file size, field count, and batch size; split processing into background transactions. See [architecture](docs/developer/architecture.md).                                                                                                     |
| Supporting objects with hundreds of fields                | Build a compact description of the fields needed by the selected process and reuse bounded transaction-local caches. See [cache design](docs/developer/cache-design.md). The large-schema benchmark is synthetic, not a production throughput claim. |
| Safely handling administrator-selected objects and fields | Resolve configuration against Salesforce schema and enforce permissions on the server. Business-record persistence uses user-mode database operations. See [security and access](docs/admin/security-and-access.md).                                 |
| Keeping failures traceable across batches                 | Preserve row identity through mapping, saving, and result generation; distinguish partial success from a failed upload. See [results](docs/user/understand-results.md).                                                                              |
| Extending behavior without growing one large controller   | Separate configuration, authorization, parsing, mapping, persistence, and job services; expose defined extension contracts. See [extension guide](docs/developer/custom-handler.md).                                                                 |

## Scope and current limitations

- **File limits:** 2 MiB, 5,000 data rows, 100 configured columns, and 32,000 characters per cell. See [limits](docs/admin/limits.md) for operating constraints.
- **Supported placement:** Lightning Record Pages and Lightning App Pages. Home Pages, Lightning tabs as component targets, and Experience Cloud pages are outside the supported component surfaces.
- **Setup:** source deployment, permission assignment, and process configuration are required. There is no published one-click package installation yet.
- **Release maturity:** breaking changes are possible. Hands-on accessibility and package lifecycle verification remain open. See [release status](docs/project-status.md).

See [unsupported features](docs/reference/unsupported-features.md) and the [proposed roadmap](docs/roadmap.md) for the boundary between current behavior and planned work.

## Development and verification

From the repository root, run:

```bash
npm ci
npm run check:all
```

These local checks cover formatting, lint, Lightning unit tests, source rules, documentation links, release-file checks, and a synthetic large-schema benchmark. Apex execution and deployment require separate Salesforce org verification.

The [testing guide](docs/developer/testing.md) covers org verification. Check [Project status](docs/project-status.md) for outstanding release checks.

## Documentation and support

See [installation](docs/get-started/install.md), [permissions](docs/get-started/permissions.md), [Lightning page setup](docs/admin/configure-lightning-pages.md), and [troubleshooting](docs/admin/troubleshooting.md). Planned work is listed in the [proposed roadmap](docs/roadmap.md).

Contributions follow [CONTRIBUTING.md](CONTRIBUTING.md); security reports follow [SECURITY.md](SECURITY.md). Package lifecycle requirements are described in [Package and compatibility](docs/reference/package-and-compatibility.md) and [RELEASING.md](RELEASING.md).

Licensed under the [MIT License](LICENSE). See [notices and attribution](NOTICE.md).
