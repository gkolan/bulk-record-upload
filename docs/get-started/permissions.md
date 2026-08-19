# Assign permissions

> [!NOTE]
> On this page, grant only the Bulk Record Upload capabilities each operator needs.

Assign **Bulk Record Upload User** (`Bulk_Record_Upload_User`) for ordinary upload work. Add **Bulk Record Upload Previewer** (`Bulk_Record_Upload_Preview_Access`) when a process requires preview access, **Bulk Record Upload Deletion** (`Bulk_Record_Upload_Delete_Access`) for delete processes, or **Bulk Record Upload Admin** (`Bulk_Record_Upload_Administrator`) for configuration administration.

```powershell
sf org assign permset --name Bulk_Record_Upload_User --target-org <verified-alias>
```

The running user also needs the operation-specific object and field access. Permission sets never override sharing, CRUD, or field-level security.

## Next steps

[Run the first upload](first-upload.md) or review [security and access](../admin/security-and-access.md).
