# Configuration fields

> [!NOTE]
> On this page, look up the Custom Metadata fields that define versioned upload processes and columns.

**Upload Process** (`Bulk_Record_Upload_Process__mdt`) owns target object, operation, processing mode, processor key, batch size, retention, preview permission, active state, and contract version. **Upload Field** (`Bulk_Record_Upload_Process_Field__mdt`) owns the process key, CSV column, Salesforce field, sequence, existing-value action, blank-value action, text separator, duplicate policy, overflow policy, required/match/upsert flags, result inclusion, and active state.

Use Developer Names as stable identities. The runtime requires 1–100 active fields, unique normalized column keys and sequences, batch size 25–200, retention 7–365 days, and contract version `1` or `2`. Contract version identifies the process configuration schema and is independent of field-behavior configuration, which has exactly one mechanism: Existing Value Action and Blank CSV Action.

Never enter an Apex class name in `ProcessorKey__c`; it accepts only a reviewed key present in its code-owned closed set. The packaged default is `STANDARD_DML_V1`.

**Upload Extension** (`Bulk_Record_Upload_Extension__mdt`) is the package's one open extension point. It registers `ProcessDeveloperName__c`, `ClassName__c` (the exact Apex class name, validated at configuration load and at every run), `SortOrder__c`, and `IsActive__c`. See [Write and register an extension](../developer/custom-handler.md).

Record-page parenting uses `RecordContextAction__c`, `HostObjectApiName__c`, and `RecordContextFieldApiName__c`. The supported actions are `NONE`, `DEFAULT_PARENT`, and `REQUIRE_PARENT`. Context is validated server-side and cannot be overridden by a CSV column.

## Related

See [Configure an upload process](../admin/configure-upload-process.md) and [Field behaviors](field-behaviors.md).
