# Configure an upload process

> [!NOTE]
> On this page, create one upload process, decide how it gets its parent record on a record page, and put the component where users can reach it.

An upload process is one **Bulk Record Upload Process** (`Bulk_Record_Upload_Process__mdt`) Custom Metadata record. It says which object and operation this upload targets — the columns it accepts are a separate, per-column setup covered in [Configure field behaviors](configure-field-behaviors.md).

## Create one, step by step

In Setup, search **Custom Metadata Types**, open it, find **Bulk Record Upload Process**, click **Manage Records**, then **New**. Fill in:

| Field on the form                                 | What to enter                                                                                                                                                               |
| ------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Label / Developer Name                            | A stable name you won't need to rename later, e.g. `Contact_Insert_Weekly`                                                                                                  |
| Object API Name (`ObjectApiName__c`)              | The object this process loads into, e.g. `Contact`                                                                                                                          |
| Upload Operation (`Operation__c`)                 | `Insert`, `Update`, `Upsert`, or `Delete`                                                                                                                                   |
| Rows per Batch (`RowsPerBatch__c`)                | A number from 25–200. `100` is the default and works for most objects — go lower only if automation on the target object (a trigger, a Flow) makes bigger batches slow.     |
| History Retention Days (`RetentionDays__c`)       | A number from 7–365 for how long upload history and result files stick around before cleanup. Default is `90`.                                                              |
| Configuration Version (`ConfigurationVersion__c`) | `1`, unless you've been told a specific column feature needs `2` — check the field's own inline help text in Setup, since this can change as the framework adds capability. |
| Custom Processor Key (`ProcessorKey__c`)          | Type `STANDARD_DML` for the normal, package-owned save path. This is a plain text field, not a picklist — type the key exactly.                                             |
| Is Active                                         | Leave unchecked until you've finished configuring this process's columns, then check it.                                                                                    |

**"Custom Processor Key" only ever needs `STANDARD_DML`** unless you're doing something unusual. If you need to run your own Apex before mapping or after saving — logging, notifications, extra validation — don't put a class name here (it's rejected either way). Instead, register that Apex as an extension; see [Write and register an extension](../developer/custom-handler.md).

If you type an object, operation, or processor key Salesforce or the package doesn't recognize, the process won't activate — you'll see a clear error instead of it silently doing nothing.

## Use the current record as the parent

Placed on a record page, the component can automatically use that record as the parent of every row it uploads — useful for "upload these Contacts under this Account" style processes.

| Field                                                               | What it controls                                                                               |
| ------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| Record Context Action (`RecordContextAction__c`)                    | `Do Not Use Record Context` (default), `Use Parent When Available`, or `Require Parent Record` |
| Record Page Object API Name (`HostObjectApiName__c`)                | The object of the record page this process is placed on                                        |
| Parent Relationship Field API Name (`RecordContextFieldApiName__c`) | The lookup field on the target object that points back to that record page's object            |

**Example:** a Contact Insert process placed on an Account record page, where every uploaded Contact should belong to that Account — set **Record Page Object API Name** to `Account` and **Parent Relationship Field API Name** to `AccountId`.

Salesforce checks the object type, the current user's access to that parent record, and the relationship field before accepting any upload — a user can't spoof a different parent by editing the CSV. Whatever the CSV says for that relationship field is overwritten with the actual page's record during processing.

Use **Require Parent Record** for a process that only makes sense on a compatible record page (it fails safely anywhere else). Use **Use Parent When Available** when the same process should also work from an app page, home page, or tab, without a parent.

## Let the user pick the parent instead

Set **Record Context Source** (`RecordContextSource__c`) to **User Choice** and the same process also works from an app page, home page, tab, or Experience Cloud page: when there's no host record page to supply a parent automatically, the component shows a record picker instead. On an actual compatible record page, the page still wins and no picker appears — nothing about the record-page behavior above changes. Leaving **Record Context Source** at its default, **Page**, keeps record-page-only behavior.

Configure the picker with **Context Search Fields**, **Context Display Fields**, and **Context Filter Criteria** (`ContextSearchFields__c`, `ContextDisplayFields__c`, `ContextFilterCriteria__c`) — see [Configuration fields](../reference/configuration-fields.md) for exactly what to type into each.

## Put the component where users can reach it

There is one component, **Bulk Record Upload**, placed on a Lightning App Page, Home Page, Record Page, tab, or Experience Cloud page through App Builder. It doesn't get configured with one fixed process directly — instead, it points at an **Upload Bundle**, and the bundle decides which process (or processes) show up.

An Upload Bundle is a small piece of configuration, not code:

1. Create one **Bulk Record Upload Bundle** (`Bulk_Record_Upload_Bundle__mdt`) record — just a Developer Name and **Is Active** checked. This is the thing you'll pick by name in App Builder.
2. Create one **Bulk Record Upload Bundle Process** (`Bulk_Record_Upload_Bundle_Process__mdt`) record per process you want that bundle to offer — each one links a **Bundle Developer Name** to a **Process Developer Name**, with a **Display Order** number and **Is Active** checked.
3. Drag the **Bulk Record Upload** component onto your page in App Builder, and set its **Upload Bundle** property to the bundle's Developer Name.

**Example**, taken from this package's own demo kit: the bundle `Account_Operations_Demo` has four Bundle Process records assigning it `Account_Insert_Demo`, `Account_Update_Demo`, `Account_Upsert_Demo`, and `Account_Delete_Demo`, in that display order. A page with the component set to that bundle shows the user all four as choices. A bundle with only one active process assigned skips the choice screen entirely and goes straight to that one process — so the same component and the same bundle mechanism cover both "pick from a few options" and "there's only one thing to do here."

To offer two unrelated jobs on different pages, create two bundles (each with their own Bundle Process assignments) and place the component twice, once per page, pointed at the matching bundle.

Before showing anything, the server re-checks that the current user actually has run permission, the right object and field access, and (for Delete) delete access — and that the bundle and every process it references are still active. Deactivating a process, or removing its Bundle Process assignment, makes the component fail safely instead of silently falling back to something else.

## Next steps

[Configure field behaviors](configure-field-behaviors.md) and check [limits](limits.md).
