# Assign permissions

> [!NOTE]
> On this page, give each person only the Bulk Record Upload access they actually need, in Setup — no CLI required.

Bulk Record Upload supplies four permission sets for application access. A person can hold more than one. Salesforce profiles and other permission sets still determine access to the business objects and fields being uploaded.

| Permission Set                          | API name                            | Assign it when someone needs to                                                                                           |
| --------------------------------------- | ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| **Bulk Record Upload — User**           | `Bulk_Record_Upload_User`           | Upload a CSV at all. Assign this to everyone who will use the tool.                                                       |
| **Bulk Record Upload — Preview Access** | `Bulk_Record_Upload_Preview_Access` | Review rows before submitting, on a process configured to require preview.                                                |
| **Bulk Record Upload — Delete Access**  | `Bulk_Record_Upload_Delete_Access`  | Run a Delete process.                                                                                                     |
| **Bulk Record Upload — Administrator**  | `Bulk_Record_Upload_Administrator`  | Create or edit upload processes and field configuration — this is for the person setting things up, not day-to-day users. |

Most people only need **Bulk Record Upload — User**. Add the others only for the specific capability they cover.

## Assign one, step by step

**In Setup (the way most admins will do this):**

1. In Setup, go to **Users** > **Permission Sets**.
2. Click the Permission Set you want to assign — for example, **Bulk Record Upload — User**.
3. Click **Manage Assignments**, then **Add Assignment**.
4. Check the box next to the person's name, then click **Assign** > **Done**.

**From the command line, if you're scripting this for several users:**

```bash
sf org assign permset --name Bulk_Record_Upload_User --target-org <your-org-alias>
```

## Grant access to the target data

A Permission Set only unlocks the Bulk Record Upload app and its actions — it doesn't hand someone access to your data. The person also needs their own object and field access through their Profile or another Permission Set, the normal Salesforce way: Create/Edit access to the object the process writes to (like Account), and edit access to every field the process maps. Bulk Record Upload never bypasses sharing rules, object permissions, or field-level security — if someone can't normally edit a field by hand, they can't edit it through an upload either.

## If something goes wrong

| What you see                                                                                        | What to check                                                                                                                                                   |
| --------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| The user has **Bulk Record Upload — User** assigned but the upload still fails with an access error | Check their object permissions (Create/Edit on the target object) and field-level security on every mapped field — the Permission Set above doesn't grant these |
| A Delete process is unavailable to someone who can otherwise use the tool                           | They're missing **Bulk Record Upload — Delete Access** (`Bulk_Record_Upload_Delete_Access`)                                                                     |
| Someone can't see the preview step on a process that should show one                                | They're missing **Bulk Record Upload — Preview Access** (`Bulk_Record_Upload_Preview_Access`)                                                                   |

## Next steps

[Run the first upload](first-upload.md) or review [security and access](../admin/security-and-access.md).
