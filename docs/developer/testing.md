# Test and verify changes

> [!NOTE]
> On this page, run the exact commands that check a change before it's considered done, on Windows, macOS, or Linux.

## Local checks (fast, no org needed)

```bash
npm ci
npm run check:all
npm audit --omit=dev
npm run sbom
```

`npm run check:all` runs linting, formatting, unit tests, source/doc structure checks, and the release-boundary check in sequence — it's the single command to run before opening a pull request. If it fails, the failing step's own output says which one broke and why.

## Salesforce checks (need a target org)

1. **Confirm your target org**, the same way as in [Install](../get-started/install.md):

   ```bash
   sf org display --target-org <your-org-alias> --json
   ```

2. **Dry-run the deploy** — checks that your change would deploy cleanly, without actually deploying it:

   ```bash
   sf project deploy start --source-dir force-app --target-org <your-org-alias> --dry-run
   ```

3. **Deploy for real, running just the tests related to your change first** (faster feedback than the full suite):

   ```bash
   sf project deploy start --source-dir force-app --target-org <your-org-alias> --test-level RunSpecifiedTests --tests BulkRecordUploadJobTest --wait 30
   ```

   Replace `BulkRecordUploadJobTest` with whichever test class(es) actually cover what you changed.

4. **Run every package test class with coverage**, once your focused tests pass:

   ```bash
   sf project deploy start --source-dir force-app --target-org <your-org-alias> --test-level RunLocalTests --wait 30
   ```

   `RunLocalTests` runs every test class deployed to the org, not only this package's — in an org with other unmanaged code installed, that can include tests this package doesn't own. The package's own test classes are the ones listed in `manifest/package.xml` ending in `Test` — that list is the authoritative one to check coverage against, not a fixed number written down here (it changes as classes are added or split).

5. **Run Code Analyzer last**, after tests pass. Follow the [release process](../../RELEASING.md)
   and coordinate shared-org verification according to [CONTRIBUTING.md](../../CONTRIBUTING.md).
   The checked-in [analyzer configuration](../../code-analyzer.yml) defines the repository's rule overrides.

## The shared scratch org

This project reuses one 30-day scratch org, created from `config/project-scratch-def.json` (which requests Salesforce sample data), rather than spinning up a new one per change. Deploy the full manifest, list views, and the project's deterministic seed assets to it. Only replace it if it's expired, corrupted, incompatible with a required feature, or otherwise unrecoverable — and write down why before you do, since a scratch org replacement affects whatever the rest of the team has running against it too.

## Try the demo kit

Start with the [two-Account quick start](../get-started/quick-start.md), which needs no seed script.
For Update, Upsert, and Delete fixtures, follow the [three-object demonstration kit](../examples/demo/README.md): deploy the optional example metadata before running its seed script in an isolated development org. The seed deletes Accounts whose names begin with `Bulk Upload Demo ` or `Bulk Upload CSV ` and recreates Account, Contact, and Opportunity fixtures. Review those names and related records before resetting demo data.

## Related

See [CONTRIBUTING.md](../../CONTRIBUTING.md) and [RELEASING.md](../../RELEASING.md).
