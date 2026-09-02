# Bulk Record Upload for Salesforce

**Upload CSV files inside Salesforce, with reusable rules and clear results for every row.**

An administrator defines an upload process: which records to create or change, which columns to accept, and how to save them. Users follow its template to upload Accounts, Contacts, or other configured records. Field mapping stays consistent across uploads, and Salesforce permissions still apply.

**Choose process → Download template → Preview CSV → Submit → Check row results**

**[Quick start](docs/get-started/quick-start.md)** · **[See an example](#a-concrete-example)** · **[How it works](#how-an-upload-works)** · **[Design decisions](#engineering-challenges-and-design-choices)**

Try it in a Salesforce development org with API 67.0. Install from source; no one-click package is available yet.

> **Active development — not production-ready.** Updates may break existing setups, and bugs or incomplete behavior are possible. Use sample data in a development org. See [release status](docs/project-status.md) for open verification work.

## Why this project exists

A recurring upload involves more than reading a CSV file. Someone must decide which Salesforce object it changes, which columns are allowed, how existing records are matched, and what happens when a row fails. Those decisions need to remain consistent across uploads.

This project puts those decisions into a reusable **upload process**: Salesforce configuration that defines one job, such as creating Contacts or updating selected Account fields. Users choose that process and work from its template. They do not need to choose an object, remap columns, or write code for each upload.

The same application can support multiple processes for different standard or custom objects, subject to supported fields and the user's Salesforce permissions. Its focus is bounded, recurring uploads inside Lightning; the current limit is 5,000 rows per file.

## A concrete example

Suppose an Account needs a new list of Contacts from a spreadsheet. An administrator configures a Contact Insert process with approved columns and places it on the Account record page. The process can require the current Account as the parent, so the person uploading does not need to look up or paste its Salesforce ID into each row.

The user downloads the template, adds the Contacts, reviews the file, and submits it. The application processes the rows in the background and produces a result file that identifies successful rows and explains failures. When an individual row cannot be saved, partial-success processing lets other valid rows succeed. The user can correct failed rows without uploading successful ones again.

This is one supported configuration. The [quick start](docs/get-started/quick-start.md) uses a smaller example: creating two fictional Accounts from an included CSV.

## What problems it addresses

| Upload challenge                                        | How the project addresses it                                                                                                                        |
| ------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| Repeating the same mapping and setup decisions          | A configured process defines the object, operation, CSV columns, and field behavior. Its template reflects those choices.                           |
| Making uploads available where the work happens         | A Lightning component runs on Record Pages and App Pages, with one process or a controlled choice of processes.                                     |
| Preventing an upload from becoming a permissions bypass | Apex validates configuration and applies the user's object, field, and record access to business data. Delete also requires separate authorization. |
| Understanding a partially successful file               | Results preserve the original row numbers and report each row's outcome.                                                                            |
| Adapting to different data rules                        | Configuration controls matching, blank values, and supported field behaviors; validated Apex extensions support additional processing.              |

## How an upload works

1. **Configure:** an administrator defines the process, columns, permissions, and Lightning page placement.
2. **Prepare:** a user selects the process, downloads its template, and fills in a UTF-8 CSV.
3. **Review:** the component previews the file and reports validation problems before submission.
4. **Process:** Apex validates the request and handles rows in bounded background work, applying the configured operation.
5. **Check results:** the user follows the upload status and downloads the row results.

Available operations are **Insert** (create), **Update** (change matched records), **Upsert** (create or update using a configured external-ID field), and **Delete** (remove matched records with separate permission).

## Try it yourself

Use a dedicated Developer Edition org or development sandbox with API 67.0 available. You need Salesforce CLI v2 and Node.js 22 or later for setup. Once configured, uploads run through the Salesforce UI.

The [quick-start guide](docs/get-started/quick-start.md) walks through:

1. Downloading this repository and signing in to your development org.
2. Validating and deploying the source and supplied demo configuration.
3. Assigning permissions and opening the demo Account page.
4. Uploading the included two-row CSV and checking the created records.

For an existing installation, go straight to [Run the first upload](docs/get-started/first-upload.md). For your own objects and fields, follow [Configure an upload process](docs/admin/configure-upload-process.md).

## Engineering challenges and design choices

The implementation uses **Apex, Lightning Web Components, Custom Metadata, and Salesforce Files**. The main engineering work is coordinating configuration, security, background processing, and useful failure reporting.

| Engineering challenge                                     | Design choice and where to learn more                                                                                                                                                                                                                |
| --------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Working within Salesforce transaction limits              | Bound file size, field count, and batch size; split processing into background transactions. See [architecture](docs/developer/architecture.md).                                                                                                     |
| Supporting objects with hundreds of fields                | Build a compact description of the fields needed by the selected process and reuse bounded transaction-local caches. See [cache design](docs/developer/cache-design.md). The large-schema benchmark is synthetic, not a production throughput claim. |
| Safely handling administrator-selected objects and fields | Resolve configuration against Salesforce schema and enforce permissions on the server. Business-record persistence uses user-mode database operations. See [security and access](docs/admin/security-and-access.md).                                 |
| Keeping failures traceable across batches                 | Preserve row identity through mapping, saving, and result generation; distinguish partial success from a failed upload. See [results](docs/user/understand-results.md).                                                                              |
| Extending behavior without growing one large controller   | Separate configuration, authorization, parsing, mapping, persistence, and job services; expose defined extension contracts. See [extension guide](docs/developer/custom-handler.md).                                                                 |

These choices aim to keep the code easy to maintain, bounded as workloads grow, straightforward to extend, and understandable to someone new to the project.

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

The [testing guide](docs/developer/testing.md) explains those additional checks. Release limitations are listed in [Project status](docs/project-status.md). Verification belongs to the exact candidate being reviewed; local work logs are not included in the public repository.

## Documentation and support

See [installation](docs/get-started/install.md), [permissions](docs/get-started/permissions.md), [Lightning page setup](docs/admin/configure-lightning-pages.md), and [troubleshooting](docs/admin/troubleshooting.md). Planned work is listed in the [proposed roadmap](docs/roadmap.md).

Contributions follow [CONTRIBUTING.md](CONTRIBUTING.md); security reports follow [SECURITY.md](SECURITY.md). Package lifecycle requirements are described in [Package and compatibility](docs/reference/package-and-compatibility.md) and [RELEASING.md](RELEASING.md).

Licensed under the [MIT License](LICENSE). See [notices and attribution](NOTICE.md).
