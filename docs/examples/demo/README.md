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
