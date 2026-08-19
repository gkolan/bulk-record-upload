# Configure an upload process

> [!NOTE]
> On this page, create an active Custom Metadata process that selects one approved object, operation, batch size, and retention period.

Create a **Bulk Record Upload Process** (`Bulk_Record_Upload_Process__mdt`) record with a stable Developer Name. Set `ObjectApiName__c`, one supported `Operation__c`, `RowsPerBatch__c` from 25–200, `RetentionDays__c` from 7–365, `ConfigurationVersion__c` to `2`, and `IsActive__c` only after its fields validate.

For the normal path, select **Standard DML** and use processor key `STANDARD_DML_V1`; this closed persistence path is package-owned and always user-mode (see [ADR-0007](../../specs/decisions/ADR-0007-configuration-over-code-extension.md)). To run reviewed Apex before mapping or after processing, register it as an extension — see [Write and register an extension](../developer/custom-handler.md) — rather than through a processor key.

Object and processor text is resolved through Schema and trusted registries. An unknown value returns a safe configuration fault.

## Use the current record as the parent

For a record-page upload, set **Record Context Action** to **Require Parent Record** or **Use Parent When Available**. Enter the record-page object in **Record Page Object API Name** and the target relationship field in **Parent Relationship Field API Name**. For example, a Contact insert process placed on an Account record page uses `Account` and `AccountId`.

The component passes the current record ID automatically. Apex verifies its object type, the user's access to the parent, and the relationship field before accepting the upload. During processing, the verified parent overwrites any value supplied for that relationship in the CSV. Use **Require Parent Record** for a process that must run only on a compatible record page; use **Use Parent When Available** when the same process may also run from an app or home page.

## Let the user choose the parent off a record page

Set **Record Context Source** to **User Choice** so the same process also works from an app page, home page, tab, or Experience Cloud page. When no host record page provides a parent, the component shows a record picker instead; the host page still wins whenever it does provide one, so nothing about the record-page placement changes. Configure the picker with `ContextSearchFields__c`, `ContextDisplayFields__c`, and `ContextFilterCriteria__c` — see [Configuration fields](../reference/configuration-fields.md) for the shared field-list convention and the filter grammar. Leaving Record Context Source at its default, **Page**, keeps the current record-page-only behavior exactly as it was.

## Choose how users enter the process

The package provides two components; neither replaces the other.

- **Bulk Record Upload — Multiple Processes** lists every active process available to the user and lets the user choose one.
- **Bulk Record Upload** accepts no App Builder process or instruction override. Apex returns active Upload Process choices; one choice is selected automatically and multiple choices display the runtime selector.

On initialization, the server resolves active configuration and enforces run permission, preview permission, object CRUD, field access, operation permission, trusted extension registration, and bounded field projection. A single available process scopes history automatically.

To offer three distinct jobs, create three process records and place three component instances, each with its own fixed API name. Deactivating or invalidating a process causes its component to fail safely rather than fall back to a different process.

## Next steps

[Configure field behaviors](configure-field-behaviors.md) and verify [limits](limits.md).
