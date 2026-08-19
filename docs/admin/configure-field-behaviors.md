# Configure field behaviors

> [!NOTE]
> On this page, map CSV columns to accessible Salesforce fields in a stable order.

Create 1–100 active **Bulk Record Upload Process Field** (`Bulk_Record_Upload_Process_Field__mdt`) records for the process. Give each a unique CSV header, exact field API name, and column order. Use the match, upsert, required, and result options only when the process needs them.

For version 2, configure **Existing Value Action** and **Blank CSV Action** separately. Use Replace + Ignore for ordinary mappings. Append and Prepend also require a separator and duplicate action; they are restricted to text-like fields. Overflow rejects the row instead of truncating business data. Calculated, autonumber, inaccessible, or unsupported fields are rejected before processing.

## Next steps

See the [field behavior reference](../reference/field-behaviors.md) and [supported field types](../reference/supported-field-types.md).
