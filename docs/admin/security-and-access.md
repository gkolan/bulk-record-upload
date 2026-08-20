# Security and access

> [!NOTE]
> On this page, understand exactly what Bulk Record Upload lets a user do, and what it never lets them bypass.

## The short version

Bulk Record Upload never gives anyone more access than they already have in Salesforce. If a user can't normally create Account records, they can't create them through an upload either. It runs as the logged-in user, respecting their sharing rules, object permissions, and field-level security on every single row — the same as if they'd edited each record by hand in Salesforce.

## What each permission set actually unlocks

| Permission Set                                                         | Unlocks                                                                                                        |
| ---------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| **Bulk Record Upload User** (`Bulk_Record_Upload_User`)                | Using the tool at all — without this, the component won't run for that user.                                   |
| **Bulk Record Upload Deletion** (`Bulk_Record_Upload_Delete_Access`)   | Running a Delete process. Without it, Delete stays unavailable even to someone who can otherwise use the tool. |
| **Bulk Record Upload Previewer** (`Bulk_Record_Upload_Preview_Access`) | Seeing the row preview on a process configured to require it.                                                  |
| **Bulk Record Upload Admin** (`Bulk_Record_Upload_Administrator`)      | Creating or editing upload processes and field configuration.                                                  |

None of these substitute for ordinary Salesforce access. A user still needs Create or Edit permission (whichever the operation requires) on the target object, and edit access to every field the process maps — the normal way, through their Profile or another Permission Set. See [Assign permissions](../get-started/permissions.md) for how to assign these.

## What happens with your data during an upload

While a file is being processed, Salesforce temporarily holds the CSV data in its own package-managed storage, in bounded pieces — it isn't written into debug logs, so sensitive values in your file (an SSN, a revenue figure, anything else) won't show up somewhere unexpected. If a row fails, the message shown back to you is a short, safe summary (for example, "a required field was missing") — never a full technical stack trace or the row's raw data.

The CSV file you upload is stored as a Salesforce File, which follows Salesforce's normal File sharing rules — the same access model as any other file you'd attach to a record.

## A couple of things this framework deliberately checks strictly

- Every object and field name a process is configured with is checked against Salesforce's own object/field metadata before it's used — a typo or a made-up field name is rejected at configuration time, not allowed to fail unpredictably later.
- A custom Apex class (a row-extension or a custom merge strategy — see [Write and register an extension](../developer/custom-handler.md)) only runs if it's been explicitly registered by an admin in Custom Metadata. A class isn't trusted just because it exists in the org.

## Next steps

Review [permissions](../get-started/permissions.md) and [troubleshooting](troubleshooting.md).
