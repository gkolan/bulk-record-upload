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

## Expected contract for every example

Every field is included in the result. Required Insert fields and every match/external-ID field use
Reject Blank; other fields use Ignore Blank. Unless a row below says otherwise, fields use Replace,
Reject Overflow, no case conversion, and no text-join behavior. A successful run returns one result
row per CSV data row in source order.

| Process and CSV           | Exact headers                                                                    | Configured behavior                                                                                                                        | Expected business records and result                                              | Repeat-run effect                                                                                                          |
| ------------------------- | -------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `Account_Insert_Demo`     | Account Name; Description; Phone; Website; Employees; Annual Revenue             | Account Name is required; the other configured fields are optional.                                                                        | Two new Accounts; two Success rows.                                               | A new submission creates two more Accounts. Request-delivery idempotency does not make separate Insert submissions unique. |
| `Account_Update_Demo`     | External Key; Description; Phone; Employees                                      | External Key matches a unique demo field. Description uses Append, New Line, and Skip Duplicate; other values Replace.                     | The two seeded keyed Accounts change; two Success rows.                           | The same Description is not appended twice; replacement values remain the same.                                            |
| `Account_Upsert_Demo`     | External Key; Description; Phone; Employees                                      | External Key is the unique upsert key; values Replace.                                                                                     | `ACC-DEMO-001` changes and `ACC-DEMO-NEW` is created; two Success rows.           | The same keys update those two records without inserting another record.                                                   |
| `Account_Delete_Demo`     | External Key                                                                     | External Key is the match field; Delete permission is required.                                                                            | The seeded `ACC-DEMO-DELETE` Account is deleted; one Success row.                 | A later separate submission finds no matching record and returns a bounded failed row.                                     |
| `Contact_Insert_Demo`     | Last Name; First Name; Email; Phone; Birthdate; Email Opt Out                    | Last Name is required. On the supplied Account record page, validated page context sets `AccountId`; on an App Page no parent is required. | Two new Contacts; two Success rows; both receive the page Account when run there. | A new submission creates two more Contacts.                                                                                |
| `Contact_Update_Demo`     | External Key; First Name; Email; Birthdate; Email Opt Out                        | External Key matches a unique demo field; values Replace.                                                                                  | The two seeded keyed Contacts change; two Success rows.                           | The same values replace themselves without inserting records.                                                              |
| `Contact_Upsert_Demo`     | External Key; First Name; Email; Birthdate; Email Opt Out                        | External Key is the unique upsert key; values Replace.                                                                                     | `CON-DEMO-001` changes and `CON-DEMO-NEW` is created; two Success rows.           | The same keys update those two records without inserting another record.                                                   |
| `Contact_Delete_Demo`     | External Key                                                                     | External Key is the match field; Delete permission is required.                                                                            | The seeded `CON-DEMO-DELETE` Contact is deleted; one Success row.                 | A later separate submission finds no matching record and returns a bounded failed row.                                     |
| `Opportunity_Insert_Demo` | Opportunity Name; Stage; Close Date; Amount; Probability; Next Step; Description | Name, Stage, and Close Date are required; other configured fields are optional.                                                            | Two new Opportunities; two Success rows.                                          | A new submission creates two more Opportunities.                                                                           |
| `Opportunity_Update_Demo` | External Key; Stage; Close Date; Amount; Probability; Next Step                  | External Key matches a unique demo field. Next Step uses Prepend, Semicolon + Space, and Skip Duplicate; other values Replace.             | The two seeded keyed Opportunities change; two Success rows.                      | The same Next Step is not prepended twice; replacement values remain the same.                                             |
| `Opportunity_Upsert_Demo` | External Key; Stage; Close Date; Amount; Probability; Next Step                  | External Key is the unique upsert key; values Replace.                                                                                     | `OPP-DEMO-001` changes and `OPP-DEMO-NEW` is created; two Success rows.           | The same keys update those two records without inserting another record.                                                   |
| `Opportunity_Delete_Demo` | External Key                                                                     | External Key is the match field; Delete permission is required.                                                                            | The seeded `OPP-DEMO-DELETE` Opportunity is deleted; one Success row.             | A later separate submission finds no matching record and returns a bounded failed row.                                     |

For any failed or partial run, download the result, reconcile by `bru_row_number`, correct only the
failed source rows, and submit a correction file containing only those rows. Do not replay successful
Insert rows. Configuration-change failures require restoring or deliberately updating the process,
then starting a new upload; stale work is never resumed under a different projection.

For cleanup after any row above, capture created IDs first and rerun
`scripts/apex/seed-demo-data.apex`. It restores the deterministic seeded records and removes only the
documented demo-name and demo-key families. Run `scripts/apex/verify-account-demo.apex` afterward for
the Account fixtures. Remove uploaded Files and history only by captured IDs or let the configured
retention job remove eligible package-owned records.

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

After the example configuration succeeds, deploy the optional page from `examples/pages/main/default` and assign it to Account inside the **Bulk Record Upload** application. Follow [Deploy and open the demo page](../../get-started/quick-start.md#4-deploy-and-open-the-demo-page) for the commands and App Builder activation. This separate deployment is required because the page validates its process and bundle choices against configuration already installed in the org. It contains three labeled component instances:

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
