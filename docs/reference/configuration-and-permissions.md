# Configuration, storage, and permissions

> [!NOTE]
> On this page, see the formal authorization and storage model — what's configuration versus what's an actual access grant, and exactly what each Permission Set unlocks.
> **Reference:** technical detail for anyone auditing access or storage behavior. See [Configure an upload process](../admin/configure-upload-process.md) and [Configuration fields](configuration-fields.md) for what each configuration field is, and [Security and access](../admin/security-and-access.md) for the same permission model explained for an admin.

## Configuration is not authorization

A **Bulk Record Upload Process** record's target object, operation, processor key, batch size, retention period, and active state are configuration inputs — none of them grant access on their own. Every object, field, Apex extension class, or merge strategy class a process names is still re-checked against Schema and the package's own reviewed registries at run time; naming something in configuration that isn't actually allowed produces a configuration error, not a bypass.

Version 1 ships with no Custom Metadata records of its own — a subscriber creates every process, field, bundle, and extension record for their own approved objects and fields after installing. The shipped example and test records live outside the core package manifest.

## Stored records and Files

| Object                        | What it is                                                                                                                                                                                                                      |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Bulk_Record_Upload__c`       | One record per upload. Ordinary Salesforce sharing controls who can see it. Stores lifecycle status, row counts, and links to the input/result Files — never the CSV content itself.                                            |
| `Bulk_Record_Upload_Chunk__c` | Internal, package-managed staging records used to process a file in bounded pieces. Only the package's own Apex creates or removes these — an end user never interacts with them directly, and their contents are never logged. |

The input file and the results file are both stored as ordinary Salesforce Files, linked to the private upload record through a `ContentDocumentLink`. Access to them follows normal Salesforce File sharing — nothing here creates a public link, a Public Group, or any other broadened access. If a subscriber org wants to share upload records more broadly, that's done with the org's own sharing rules, not anything this package configures automatically.

## What each Permission Set unlocks

| Permission Set               | API name                            | Grants                                                                                | Deliberately does not grant                                 |
| ---------------------------- | ----------------------------------- | ------------------------------------------------------------------------------------- | ----------------------------------------------------------- |
| Bulk Record Upload User      | `Bulk_Record_Upload_User`           | Run approved processes; access the app, the upload history, and Custom Metadata Types | Object/field access on the target object, Delete, preview   |
| Bulk Record Upload Previewer | `Bulk_Record_Upload_Preview_Access` | Everything User grants, plus the row-preview step                                     | Object/field access on the target object                    |
| Bulk Record Upload Deletion  | `Bulk_Record_Upload_Delete_Access`  | Everything User grants, plus running approved Delete processes                        | Delete access on the target object itself                   |
| Bulk Record Upload Admin     | `Bulk_Record_Upload_Administrator`  | Inspect configuration, uploads, and staging records, for support and troubleshooting  | Modify All Data, View All Data, or any target-object access |

Each Permission Set is built from an underlying Custom Permission of the same shape (`Bulk_Record_Upload_Run`, `Bulk_Record_Upload_Preview`, `Bulk_Record_Upload_Delete`, `Bulk_Record_Upload_Administer`) — code checks the Custom Permission, and the shipped Permission Set is just a convenient way to grant it.

Each person still needs the normal Salesforce permissions for the object and fields, access to the records, and access to Salesforce Files through a Profile or Permission Set. Bulk Record Upload does not grant that access. See [Assign permissions](../get-started/permissions.md).

## Retention

Retention is one setting per process, 7–365 days (default 90), applied together to that process's upload history and its input and result Files — cleanup removes expired chunks and Files without needing Modify All Data, and only ever records safe identifiers and counts, never CSV content.

## What fails configuration validation before any record is touched

An inactive process, an object or field Salesforce doesn't recognize, a disallowed operation, an unregistered extension or merge strategy class, a missing required preview permission, a duplicate column key or sequence, or a field the current user can't actually access — every one of these is caught at configuration-load time, before any target-object DML runs. The error a user sees names the configuration entry and a safe identifier, never a CSV value.

## Related

- [Configuration fields](configuration-fields.md)
- [Security and access](../admin/security-and-access.md)
- [Product contract](product-contract.md)
- [Testing and verification](../developer/testing.md)
