# Install Bulk Record Upload from source

> [!NOTE]
> On this page, download the project, authenticate to your development org, validate the source, and deploy it.

The current installation path is a source deployment. No promoted package version or one-click installation link is available. To include a working sample configuration and CSV, follow the [quick start](quick-start.md).

## Before you start

- Use a dedicated Developer Edition org or development sandbox where you have permission to deploy Apex and metadata and assign permission sets. Start with synthetic data.
- The current [project configuration](../../sfdx-project.json) and [manifest](../../manifest/package.xml) use **API 67.0**. Your org must support that version.
- Install [Salesforce CLI v2](https://developer.salesforce.com/tools/salesforcecli) and Node.js 22 or later. Confirm `sf --version`, `node --version`, and `npm --version` work in your terminal.

These instructions let people evaluating their own copy use a development org they control. Shared maintainer-org work follows the target policy in [CONTRIBUTING.md](../../CONTRIBUTING.md).

## 1. Download the project

On this repository's GitHub page, select **Code → Download ZIP**, extract it, and open a terminal in the extracted folder containing `sfdx-project.json`. Alternatively, copy the clone URL from **Code** and clone it with Git.

Run from that folder:

```bash
npm ci
npm run check:all
```

Continue when both commands finish successfully. The second command validates local source and documentation; it does not deploy or run Apex in Salesforce.

## 2. Sign in and verify the org

For Developer Edition:

```bash
sf org login web --alias bru-demo --instance-url https://login.salesforce.com
```

For a sandbox, use this command instead:

```bash
sf org login web --alias bru-demo --instance-url https://test.salesforce.com
```

Complete sign-in in the browser. `bru-demo` is a local alias for the org you select. If that alias is already used for a different org, choose another alias and use it in every command below. For SSO, use your org's My Domain login URL; see the official [web login reference](https://github.com/salesforcecli/plugin-auth#sf-org-login-web).

Before each org-affecting command, verify the alias:

```bash
sf org display --target-org bru-demo
```

Confirm the instance URL and username belong to the intended development org. Stop if they do not match. Keep CLI authentication output private.

## 3. Validate and deploy

Validate first without saving metadata:

```bash
sf project deploy start --dry-run --manifest manifest/package.xml --target-org bru-demo --test-level RunLocalTests --wait 30
```

In a dedicated evaluation org, `RunLocalTests` exercises the project's tests along with any other local tests already installed. Shared-org release verification uses the project's [testing guidance](../developer/testing.md). The official [deployment reference](https://github.com/salesforcecli/plugin-deploy-retrieve#sf-project-deploy-start) explains the test levels.

After validation succeeds, verify the alias again and deploy:

```bash
sf org display --target-org bru-demo
sf project deploy start --manifest manifest/package.xml --target-org bru-demo --test-level RunLocalTests --wait 30
```

Continue only when the deployment reports **Succeeded** with no component or test failures. If the command returns a job ID while the deployment is still running, check its status with `sf project deploy report --job-id YOUR_JOB_ID --target-org bru-demo`, replacing `YOUR_JOB_ID` with that returned ID.

## 4. Make it usable

Deployment installs the application and components. Your users still need permissions, active process and field configuration, and a Lightning page:

1. [Assign permissions](permissions.md).
2. [Configure an upload process](../admin/configure-upload-process.md) and its [fields](../admin/configure-field-behaviors.md), or load the examples through the [quick start](quick-start.md#2-load-the-sample-configuration).
3. [Configure a Lightning page](../admin/configure-lightning-pages.md).
4. [Run the first upload](first-upload.md).

## Troubleshooting

| Problem                             | Next action                                                                                                                    |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `sf` or `npm` is not recognized     | Install the prerequisite and open a new terminal.                                                                              |
| API version is unsupported          | Use an org supporting API 67.0; changing only the manifest version does not establish compatibility.                           |
| Deployment access is denied         | Ask the org administrator to perform the deployment with an authorized deployment account.                                     |
| An Apex test or component fails     | Read the named failure in the deploy report and resolve it before proceeding. Other local tests can also fail in a shared org. |
| The app is missing after deployment | Assign the application permission set and refresh Salesforce.                                                                  |
| The component has no processes      | Configure active process and field records, or deploy the optional demo configuration.                                         |
