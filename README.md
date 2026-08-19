# Bulk Record Upload for Salesforce

Bulk Record Upload is an open-source, configuration-driven Lightning application for CSV insert, update, upsert, and delete operations. Administrators choose an approved process; Apex validates a compact field projection, stages at most 5,000 rows, processes partial-success DML asynchronously, and produces a correlated result file.

> **Release status:** implementation candidate under release validation. No public package version has been promoted.

## Supported environment and limits

- Enterprise, Unlimited, Performance, and Developer Edition on Salesforce API 66.0 or later.
- UTF-8 CSV up to 2 MiB, 5,000 data rows, 100 configured columns, and 32 KiB per cell.
- Insert, update, upsert, and delete through registered handlers; delete requires a separate permission.
- Internal Lightning Experience is automated-test complete. Interactive accessibility and Experience Cloud validation remain open for the final release audit.

## Quick start

```powershell
npm ci
npm run check:all
sf project deploy start --manifest manifest/package.xml --target-org <verified-alias> --test-level RunSpecifiedTests --tests BulkRecordUploadConfigProjectionTest --wait 30
```

Assign **Bulk Record Upload User** (`Bulk_Record_Upload_User`) to operators, create active Upload Process and Upload Field Custom Metadata records, then open the **Bulk Record Upload** Lightning application. Use an explicit verified alias for every org command.

## Documentation

- [Install and configure](docs/get-started/install.md)
- [Permissions](docs/get-started/permissions.md)
- [First upload](docs/get-started/first-upload.md)
- [Architecture](docs/developer/architecture.md)
- [Limits](docs/admin/limits.md)
- [Testing](docs/developer/testing.md)
- [Troubleshooting](docs/admin/troubleshooting.md)
- [Unsupported features](docs/reference/unsupported-features.md)

## Development and releases

Node.js 22+ and Salesforce CLI v2 are required. `npm run check:all` runs formatting, lint, Jest, source architecture, documentation, release-boundary, and large-schema checks. Salesforce verification remains package-scoped because a shared org can contain unrelated unmanaged tests.

Contributions follow [CONTRIBUTING.md](CONTRIBUTING.md). Security reports follow [SECURITY.md](SECURITY.md). Upgrade, recovery, and uninstall behavior is defined in [Package and compatibility](docs/reference/package-and-compatibility.md) and rehearsed through [RELEASING.md](RELEASING.md).

Licensed under the [MIT License](LICENSE). See [notices and attribution](NOTICE.md).
