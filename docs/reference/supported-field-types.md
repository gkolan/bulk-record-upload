# Supported field types

> [!NOTE]
> On this page, check whether a specific Salesforce field can be used in an upload process before you try to configure it.

## Supported

Text, Text Area, Email, Phone, URL, Picklist, Multi-Select Picklist, Checkbox, Number (whole or decimal), Currency, Percent, Date, Date/Time, and single-target Lookup or Master-Detail relationships. See [Field behaviors](field-behaviors.md#every-supported-field-type-with-a-sample-csv-value) for a real object, a real field, and a sample CSV value for every one of these.

Whether a specific field actually works also depends on the running user's own Create/Edit/Read access to it, and on the operation — a field readable but not editable, for example, can be included in results but not written to.

## Not supported

| Category                                        | Example                                                       | Why                                                                                                                                                                             |
| ----------------------------------------------- | ------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Formula and roll-up summary fields              | Account `Employees` when it's a roll-up, or any formula field | The value is calculated by Salesforce, not something a CSV can set.                                                                                                             |
| Auto Number fields                              | A custom `Order_Number__c` set to Auto Number                 | Salesforce assigns the value itself; nothing can be uploaded into it.                                                                                                           |
| Polymorphic lookups                             | Task `WhoId` (can point to a Lead or a Contact)               | There's no single target object to validate a match against — see [Lookup Match Field](field-behaviors.md#lookup-match-field) for the single-target lookups that are supported. |
| Geolocation (compound) fields                   | A custom Geolocation field                                    | The compound value doesn't map to one CSV cell.                                                                                                                                 |
| Encrypted fields the running user can't decrypt | Any Shield Platform Encryption field without decrypt access   | Salesforce itself won't return a value to read or compare against.                                                                                                              |
| Deprecated or hidden fields                     | A field marked deprecated in a managed package                | Not exposed for configuration.                                                                                                                                                  |

A **Match Field** or **Upsert External Id** column (see [Field behaviors](field-behaviors.md)) has one more requirement beyond the list above: it must be a field Salesforce itself treats as suitable for matching or as an external Id — an ordinary Text field without the External Id attribute, for example, can't be used as an Upsert key.

## Related

See [Security and access](../admin/security-and-access.md) and [Configuration fields](configuration-fields.md).
