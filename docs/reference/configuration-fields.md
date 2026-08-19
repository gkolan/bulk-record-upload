# Configuration fields

> [!NOTE]
> On this page, look up the Custom Metadata fields that define versioned upload processes and columns.

**Upload Process** (`Bulk_Record_Upload_Process__mdt`) owns target object, operation, registered row handler, processing mode, processor key, post-processing action, batch size, retention, preview permission, active state, and contract version. **Upload Field** (`Bulk_Record_Upload_Process_Field__mdt`) owns the process key, CSV column, Salesforce field, sequence, existing-value action, blank-value action, text separator, duplicate policy, overflow policy, required/match/upsert flags, result inclusion, and active state.

Use Developer Names as stable identities. The runtime requires 1–100 active fields, unique normalized column keys and sequences, batch size 25–200, retention 7–365 days, and contract version `1` or `2`. Use version `2` for new configurations. Version `1` remains supported for existing metadata and translates the legacy behavior into safe defaults.

Never enter an Apex class name. `ProcessingHandler__c`, `ProcessorKey__c`, and `PostProcessingAction__c` accept only reviewed keys present in their code-owned registries. The packaged defaults are `STANDARD_V1`, `STANDARD_DML_V1`, and `NONE_V1`.

Record-page parenting uses `RecordContextAction__c`, `HostObjectApiName__c`, and `RecordContextFieldApiName__c`. The supported actions are `NONE`, `DEFAULT_PARENT`, and `REQUIRE_PARENT`. Context is validated server-side and cannot be overridden by a CSV column.

## Related

See [Configure an upload process](../admin/configure-upload-process.md) and [Field behaviors](field-behaviors.md).
