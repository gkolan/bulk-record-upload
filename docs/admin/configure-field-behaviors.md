# Configure field behaviors

> [!NOTE]
> On this page, map CSV columns to accessible Salesforce fields in a stable order.

Create 1–100 active **Bulk Record Upload Process Field** (`Bulk_Record_Upload_Process_Field__mdt`) records for the process. Give each a unique CSV header, exact field API name, and column order. Use the match, upsert, required, and result options only when the process needs them.

Configure **Existing Value Action** and **Blank CSV Action** separately. Use Replace + Ignore for ordinary mappings. Append and Prepend also require a separator and duplicate action, and are restricted to text-like fields, including multi-select picklist; a multi-select picklist can instead use Add Values/Remove Values for set semantics. Numbers use Add/Subtract, dates use Use Later/Use Earlier, and checkboxes use True If Either/True If Both. Blank CSV Action can also substitute a configured Default Value. Trim Value, Case Action, and Blank Tokens normalize a cell before any of the above runs. Overflow rejects the row instead of truncating business data. Calculated, autonumber, inaccessible, or unsupported fields are rejected before processing.

## Next steps

See the [field behavior reference](../reference/field-behaviors.md) and [supported field types](../reference/supported-field-types.md).
