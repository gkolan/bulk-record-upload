# Security and access

> [!NOTE]
> On this page, understand how permissions, sharing, field access, dynamic identifiers, Files, and logs protect subscriber data.

Controllers use sharing. Business-data queries and DML enforce the running user's access, and delete requires `Bulk_Record_Upload_Delete`. Dynamic object and field names must resolve through Schema; handlers and behaviors must appear in project-owned registries.

The package stores CSV rows only in bounded package-owned staging chunks and does not log CSV content or sensitive field values. Result messages are safe summaries. Files remain governed by Salesforce Files links and sharing.

## Next steps

Review [permissions](../get-started/permissions.md) and [troubleshooting](troubleshooting.md).
