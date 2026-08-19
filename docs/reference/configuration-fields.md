# Configuration fields

> [!NOTE]
> On this page, look up the Custom Metadata fields that define versioned upload processes and columns.

**Upload Process** (`Bulk_Record_Upload_Process__mdt`) owns target object, operation, processing mode, processor key, batch size, retention, preview permission, active state, and contract version. **Upload Field** (`Bulk_Record_Upload_Process_Field__mdt`) owns the process key, CSV column, Salesforce field, sequence, existing-value action, blank-value action, text separator, duplicate policy, overflow policy, required/match/upsert flags, result inclusion, and active state.

Use Developer Names as stable identities. The runtime requires 1–100 active fields, unique normalized column keys and sequences, batch size 25–200, retention 7–365 days, and contract version `1` or `2`. Contract version identifies the process configuration schema and is independent of field-behavior configuration, which has exactly one mechanism: Existing Value Action and Blank CSV Action.

Never enter an Apex class name in `ProcessorKey__c`; it accepts only a reviewed key present in its code-owned closed set. The packaged default is `STANDARD_DML_V1`.

**Upload Extension** (`Bulk_Record_Upload_Extension__mdt`) is the package's one open extension point. It registers `ProcessDeveloperName__c`, `ClassName__c` (the exact Apex class name, validated at configuration load and at every run), `SortOrder__c`, and `IsActive__c`. See [Write and register an extension](../developer/custom-handler.md).

Record-page parenting uses `RecordContextAction__c`, `HostObjectApiName__c`, and `RecordContextFieldApiName__c`. The supported actions are `NONE`, `DEFAULT_PARENT`, and `REQUIRE_PARENT`. Context is validated server-side and cannot be overridden by a CSV column.

### Where the parent comes from

`RecordContextSource__c` is an axis orthogonal to `RecordContextAction__c`: it decides _where_ a parent may come from, not whether one is required. It is `PAGE` (default — the parent comes only from the host record page) or `USER_CHOICE` (a record picker is also shown when no page context is present). The host record page always wins: on a valid host record page, `USER_CHOICE` renders no picker and behaves exactly like `PAGE`.

Three fields configure the picker, sharing one convention: **a comma-separated list of field API names where the first entry is the primary field and the rest are additional fields.** Both may be blank; a blank list defaults to the host object's name field, so setting only `HostObjectApiName__c` gives a working picker.

| Field                     | Controls                       | Blank default                |
| ------------------------- | ------------------------------ | ---------------------------- |
| `ContextSearchFields__c`  | What the user's typing matches | The host object's name field |
| `ContextDisplayFields__c` | What the user sees in results  | The host object's name field |

Search fields must be searchable and display fields must be readable; both are checked through Schema describe against the host object when the process configuration loads, and a field that fails either check is rejected with a message naming it — never allowed to fail later at picker render. Additional fields (everything after the first) are capped at `BulkRecordUploadRuntimeContract.MAX_ADDITIONAL_CONTEXT_FIELDS`.

`ContextFilterCriteria__c` narrows which parent records are eligible. It holds one condition per line, `FieldApiName:Operator:Value`, where `Operator` is `=`, `!=`, or `IN` (comma-separated values for `IN`); all lines combine with AND. Every field is validated the same way as search/display fields. The filter is applied twice: in the picker, so ineligible records are never offered, and again in Apex inside `validateContext`, so a caller that bypasses the component entirely is still rejected — the picker is convenience, the server check is the guarantee, and only the second one is load-bearing.

Each of these four settings satisfies the predictability rule in [ADR-0007](../../specs/decisions/ADR-0007-configuration-over-code-extension.md): an administrator can read `RecordContextSource__c` alone and know whether a picker can ever appear; `ContextSearchFields__c`/`ContextDisplayFields__c` alone determine the picker's behavior with no dependency on another field's value; and `ContextFilterCriteria__c` alone determines eligibility, applied identically in both places it runs.

## Related

See [Configure an upload process](../admin/configure-upload-process.md) and [Field behaviors](field-behaviors.md).
