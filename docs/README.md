# Bulk Record Upload documentation

> [!NOTE]
> On this page, choose the shortest documentation path for installing, administering, using, or extending Bulk Record Upload.

Bulk Record Upload lets someone create, update, upsert, or delete many Salesforce records at once by uploading a CSV file through a Lightning component — no Data Loader, no command line, no code required to use it. An admin configures which object and fields a CSV can touch; a user then picks a file and uploads it, the same way they'd attach a file anywhere else in Salesforce.

Not sure where to start?

- **"I was told to go upload a CSV"** — start with [Run the first upload](get-started/first-upload.md).
- **"I need to set this up for my team"** — start with [Install](get-started/install.md).
- **"I'm evaluating whether this fits my org"** — read [Configuration fields](reference/configuration-fields.md) and [Limits](admin/limits.md).

## Get started

1. [Install](get-started/install.md)
2. [Assign permissions](get-started/permissions.md)
3. [Run the first upload](get-started/first-upload.md)

## Administrators

- [Configure an upload process](admin/configure-upload-process.md)
- [Configure field behaviors](admin/configure-field-behaviors.md)
- [Security and access](admin/security-and-access.md)
- [Limits](admin/limits.md)
- [Troubleshooting](admin/troubleshooting.md)

## Users

- [Prepare a CSV](user/prepare-csv.md)
- [Preview and submit](user/preview-and-submit.md)
- [Monitor an upload](user/monitor-upload.md)
- [Understand results](user/understand-results.md)

## Developers and reference

- [Architecture](developer/architecture.md), [cache design](developer/cache-design.md), [custom handlers](developer/custom-handler.md), and [testing](developer/testing.md)
- [Configuration fields](reference/configuration-fields.md), [field behaviors](reference/field-behaviors.md), [CSV format](reference/csv-format.md), [statuses and results](reference/statuses-and-results.md), and [supported field types](reference/supported-field-types.md)
- [Package compatibility](reference/package-and-compatibility.md) and [unsupported features](reference/unsupported-features.md)

Implementation evidence under `docs/evidence/` supports the gated specifications and is not an end-user guide.

## Related

Read the [project README](../README.md) or [contribution guide](../CONTRIBUTING.md).
