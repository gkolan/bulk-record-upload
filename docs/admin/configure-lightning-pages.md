# Configure Lightning pages

> [!NOTE]
> On this page, place Bulk Record Upload on a Lightning Record Page or Lightning App Page and configure every supported process and record mode.

Bulk Record Upload exposes one App Builder component named **Bulk Record Upload**. If App Builder shows two entries with that label, an older `bulkRecordUploadMultiProcess` bundle is still installed and must be removed before the Day-1 configuration is considered complete.

## Before you start

Complete these tasks first:

1. [Install the source or package](../get-started/install.md).
2. [Assign the needed permission sets](../get-started/permissions.md).
3. [Create active processes and fields](configure-upload-process.md).
4. For configured groups, create an active **Bulk Record Upload Bundle** and active **Bulk Record Upload Bundle Process** records.

Keep the Developer Names of the processes and bundles available while you work in Lightning App Builder.

## Choose a process mode

Every component instance has a **Processes to Show** property.

| App Builder value       | Use it when                                                    | Required property                         | What users see                                              |
| ----------------------- | -------------------------------------------------------------- | ----------------------------------------- | ----------------------------------------------------------- |
| `SELECTED_PROCESS`      | The page performs one specific job                             | **Selected Process**                      | That active process only; no process picker                 |
| `CONFIGURED_PROCESSES`  | The page offers a controlled group                             | **Upload Bundle**                         | Active, authorized processes assigned to that bundle        |
| `ALL_ACTIVE_FOR_OBJECT` | The page should follow all active configuration for the object | Record-page object or **Object API Name** | Every active, authorized process compatible with the object |

Set **Component Heading** to a short label that explains the instance, such as **1. Selected Process**. The heading is visible to users and is especially important when a page contains more than one instance.

## Configure a record page

On a Lightning Record Page, Salesforce supplies the current Record ID and object automatically.

1. In Setup, open **Lightning App Builder**.
2. Open or create the record page for the host object, such as Account.
3. Drag **Bulk Record Upload** onto the page once for each process mode you want to demonstrate or support.
4. Configure each instance using the table above.
5. Save the page, click **Activation**, and assign it to the intended application, profiles, record types, and form factors.
6. Open a real record and confirm each heading and process list.

The optional Account demo page in `examples/pages/main/default` contains these three instances on the same Details tab. [Deploy its configuration first, then deploy and activate the page](../get-started/quick-start.md). Core installation includes the upload-history page and does not assign an Account demo page.

| Heading                                 | Processes to Show       | Additional value                                        |
| --------------------------------------- | ----------------------- | ------------------------------------------------------- |
| **1. Selected Process**                 | `SELECTED_PROCESS`      | `Account_Insert_Demo`                                   |
| **2. Configured Processes**             | `CONFIGURED_PROCESSES`  | `Account_Save_Operations_Demo` (Insert, Update, Upsert) |
| **3. All Active Processes for Account** | `ALL_ACTIVE_FOR_OBJECT` | No process or bundle value                              |

## Configure an app page

A Lightning App Page has no current record. Configure both the process mode and **Records** mode.

| Records value      | Use it when                                                           | Required property or configuration                               |
| ------------------ | --------------------------------------------------------------------- | ---------------------------------------------------------------- |
| `ONE_RECORD`       | Every upload uses one configured parent record                        | **Record Id** and **Object API Name**                            |
| `MULTIPLE_RECORDS` | CSV rows are independent and no parent record is supplied by the page | **Object API Name** when the process mode needs object filtering |
| `SELECT_RECORD`    | The person uploading chooses a parent first                           | **Object API Name** plus record-picker settings on the process   |

To demonstrate every combination clearly, add nine component instances: three process modes for each of the three record modes. Give each instance a heading that names both choices, for example **Selected Process — One Record** or **All Active Processes — Select a Record**.

For `SELECT_RECORD`, configure the process's **Record Context Source**, search fields, display fields, and optional filter before testing the picker. For `ONE_RECORD`, use a valid 15- or 18-character Record ID from the configured object; the server still verifies object type, visibility, and process compatibility.

## Verify the page

Test with a user who has the same Permission Sets, object permissions, field access, and record access as the people who will use the page.

1. Confirm every expected component heading is visible.
2. Confirm a selected-process instance hides the process picker.
3. Confirm a configured-process instance lists only its bundle assignments.
4. Confirm an all-active instance lists every compatible active process.
5. Download the Template from each process and check its headers.
6. On an app page, verify one record, multiple records, and record selection separately.
7. Upload a small synthetic CSV and confirm the result file matches the submitted rows.

## Troubleshooting

| Symptom                                                  | Check                                                                                                            |
| -------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| Two **Bulk Record Upload** entries appear in App Builder | Remove the retired `bulkRecordUploadMultiProcess` Lightning component bundle and refresh App Builder             |
| **No active upload process is available**                | Confirm the process is active, matches the host object, has active field records, and is authorized for the user |
| **Complete this field** appears in App Builder           | Set the property required by the selected process or record mode                                                 |
| A bundle shows fewer processes than expected             | Confirm the bundle, process, and Bundle Process records are active and that Display Order values are unique      |
| A record picker does not appear                          | Use `SELECT_RECORD` and confirm the process uses user-choice record context with valid search/display fields     |
| A page works for an administrator but not another user   | Compare Permission Sets, object permissions, field access, record sharing, and Delete/Preview permissions        |

## Related

- [Configure an upload process](configure-upload-process.md)
- [Configuration fields](../reference/configuration-fields.md)
- [Security and access](security-and-access.md)
- [Three-object demonstration kit](../examples/demo/README.md)
