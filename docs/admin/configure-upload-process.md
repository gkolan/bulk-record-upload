# Configure an upload process

> [!NOTE]
> On this page, create one upload process, decide how it gets its parent record on a record page, and put the component where users can reach it.

An upload process is one **Bulk Record Upload Process** (`Bulk_Record_Upload_Process__mdt`) Custom Metadata record. It says which object and operation this upload targets — the columns it accepts are a separate, per-column setup covered in [Configure field behaviors](configure-field-behaviors.md).

## Create one, step by step

In Setup, search **Custom Metadata Types**, open it, find **Bulk Record Upload Process**, click **Manage Records**, then **New**. Fill in:

| Field on the form                                 | What to enter                                                                                                                                                                                            |
| ------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Label / Developer Name                            | A stable name you won't need to rename later, e.g. `Contact_Insert_Weekly`                                                                                                                               |
| Object API Name (`ObjectApiName__c`)              | The object this process loads into, e.g. `Contact`                                                                                                                                                       |
| Upload Operation (`Operation__c`)                 | `Insert`, `Update`, `Upsert`, or `Delete`                                                                                                                                                                |
| Rows per Batch (`RowsPerBatch__c`)                | A number from 25–200. `100` is the default and works for most objects — go lower only if automation on the target object (a trigger, a Flow) makes bigger batches slow.                                  |
| History Retention Days (`RetentionDays__c`)       | A number from 7–365 for how long upload history and result files stick around before cleanup. Default is `90`.                                                                                           |
| Configuration Version (`ConfigurationVersion__c`) | Use `1` for the basic field settings. Use `2` only when you need the separate blank, separator, duplicate, and overflow settings described in [Configure field behaviors](configure-field-behaviors.md). |
| Custom Processor Key (`ProcessorKey__c`)          | Type `STANDARD_DML` for the normal, package-owned save path. This is a plain text field, not a picklist — type the key exactly.                                                                          |
| Is Active                                         | Leave unchecked until you've finished configuring this process's columns, then check it.                                                                                                                 |

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

Use **Require Parent Record** when the upload should run only from a matching record page. Use **Use Parent When Available** when the same process should also work from a Lightning App Page without a parent.

## Let an app-page user pick the parent

Set **Record Context Source** (`RecordContextSource__c`) to **User Choice** when an App Page instance uses the `SELECT_RECORD` record mode. Configure **Context Search Fields**, **Context Display Fields**, and **Context Filter Criteria** (`ContextSearchFields__c`, `ContextDisplayFields__c`, `ContextFilterCriteria__c`) before testing the picker.

On a compatible record page, Salesforce supplies the page record and the page record takes precedence. The Day-1 component is exposed only on Lightning Record Pages and Lightning App Pages.

## Group a few processes

Use an Upload Bundle when a page must offer a controlled group instead of one process or every active process:

1. Create one active **Bulk Record Upload Bundle** (`Bulk_Record_Upload_Bundle__mdt`) record.
2. Create one active **Bulk Record Upload Bundle Process** (`Bulk_Record_Upload_Bundle_Process__mdt`) record per included process.
3. Give each assignment a unique **Display Order**.
4. In App Builder, set **Processes to Show** to `CONFIGURED_PROCESSES` and select the bundle under **Upload Bundle**.

The demo bundle `Account_Save_Operations_Demo` contains Account Insert, Update, and Upsert. `Account_Operations_Demo` contains all four Account operations.

The server re-checks the bundle, process, user permissions, object access, and field access before it returns a process. Configuration never grants access.

## Put the component on a page

Follow [Configure Lightning pages](configure-lightning-pages.md) for selected-process, configured-process, all-active, and App Page record-mode instructions.

## Next steps

[Configure field behaviors](configure-field-behaviors.md), [configure a Lightning page](configure-lightning-pages.md), and check [limits](limits.md).
