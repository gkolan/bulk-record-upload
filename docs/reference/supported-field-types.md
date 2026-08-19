# Supported field types

> [!NOTE]
> On this page, check whether a Salesforce field can participate in a version 1 upload process.

The standard handler converts accessible configured scalar values such as text, Boolean, integer, decimal, date, datetime, and supported references. Exact acceptance depends on operation-specific create/update/read access and the field describe result.

Calculated, autonumber, compound parent/child duplicates, deprecated or hidden, inaccessible encrypted, unsupported relationship, geolocation, and polymorphic fields are rejected unless a field-specific acceptance test proves the operation. Match and upsert keys must be readable supported scalar fields with an approved uniqueness contract.

## Related

See [Security and access](../admin/security-and-access.md) and [Configuration fields](configuration-fields.md).
