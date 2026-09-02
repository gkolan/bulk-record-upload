# Three-object demonstration kit

> [!NOTE]
> On this page, deploy and run the optional Account, Contact, and Opportunity demonstration processes with deterministic data and CSV files.

This optional kit configures four active processes for each of three standard
objects. It is deliberately outside the Core manifest because subscriber
configuration must remain subscriber-owned.

| Object      | Processes                      | Demonstrated supported field types                 |
| ----------- | ------------------------------ | -------------------------------------------------- |
| Account     | Insert, Update, Upsert, Delete | Text, text area, phone, URL, integer, currency     |
| Contact     | Insert, Update, Upsert, Delete | Text, email, phone, date, Boolean                  |
| Opportunity | Insert, Update, Upsert, Delete | Text, picklist, date, currency, percent, text area |

Together these configurations cover every value family supported by the version
1 coercer: text-like values (`STRING`, `TEXTAREA`, `EMAIL`, `PHONE`, `URL`, and
`PICKLIST`), `BOOLEAN`, `INTEGER`, `CURRENCY`, `PERCENT`, and `DATE`. `LONG`,
`DOUBLE`, and `DATETIME` use the same coercion families and are covered by Apex
tests because the selected standard objects do not provide portable writable
demo fields of those exact types. Unsupported Salesforce field types are not
advertised as supported.

`Account_Update_Demo` demonstrates Append with a New Line separator on
Description and duplicate skipping. `Opportunity_Update_Demo` demonstrates
Prepend with a Semicolon + Space separator on Next Step. Other fields use the
recommended Replace + Ignore defaults.

Each object receives an optional unique external-ID field named
`BulkRecordUploadDemoExternalId__c`. Update and Delete use it as the match field;
Upsert uses it as the external-ID key. Run `scripts/apex/seed-demo-data.apex`
after deploying `examples/main/default`. Assign both the normal Bulk Record Upload
role and `Bulk_Record_Upload_Demo_Target_Access` to the demo user, then use the 12
CSV files in this folder.

The seed and CSV values are fictional and deterministic. Re-running the seed
removes only records carrying the documented demo names and keys.

## Load the demo into a development org

Use an explicit alias and confirm its `instanceUrl` before each command that changes the org.

```bash
sf org display --target-org <org-alias> --json
sf project deploy start --dry-run --source-dir examples/main/default --target-org <org-alias> --test-level NoTestRun --wait 30
sf project deploy start --source-dir examples/main/default --target-org <org-alias> --test-level NoTestRun --wait 30
sf apex run --file scripts/apex/seed-demo-data.apex --target-org <org-alias>
```

Assign **Bulk Record Upload User**, the optional Preview/Delete/Admin Permission Sets needed for the scenario, and **Bulk Record Upload Demo Target Access** (`Bulk_Record_Upload_Demo_Target_Access`). The target-access Permission Set grants the demo external-ID fields; normal object and field permissions still apply.

## Account page scenarios

The supplied **Account Bulk Record Upload Demo** page is activated for Account inside the **Bulk Record Upload** application. It contains three labeled component instances:

1. **Selected Process** uses `Account_Insert_Demo`.
2. **Configured Processes** uses `Account_Save_Operations_Demo` for Insert, Update, and Upsert.
3. **All Active Processes for Account** discovers Insert, Update, Upsert, and Delete.

The seed creates **Bulk Upload Demo Alpha**, **Bulk Upload Demo Beta**, and **Bulk Upload Demo Delete**. These records support one-record, multiple-record, selection, update, upsert, and delete checks. Download the Template from every process before using the matching CSV in this folder.

For App Page combinations, follow [Configure Lightning pages](../../admin/configure-lightning-pages.md). Configure and label all nine process-mode/record-mode combinations when the page is intended as a complete demonstration.

## Verify and reset

Run the reusable smoke script after deployment:

```bash
sf apex run --file scripts/apex/verify-account-demo.apex --target-org <org-alias>
```

It verifies four active Account processes, three Account records, and a generated server-side template for every Account operation. To reset the demo after testing Insert, Update, Upsert, or Delete, rerun `scripts/apex/seed-demo-data.apex`.

## Related

- [Configure Lightning pages](../../admin/configure-lightning-pages.md)
- [Configure an upload process](../../admin/configure-upload-process.md)
- [Assign permissions](../../get-started/permissions.md)
