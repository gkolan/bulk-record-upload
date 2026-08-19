# Install Bulk Record Upload

> [!NOTE]
> On this page, deploy the current source safely and verify that the Bulk Record Upload application is available.

## Before you start

Use Salesforce API 66.0 or later in a supported edition and Salesforce CLI v2. Verify the target alias and instance URL immediately before deployment.

```powershell
npm ci
sf org display --target-org <verified-alias> --json
sf project deploy start --manifest manifest/package.xml --target-org <verified-alias> --test-level RunSpecifiedTests --tests BulkRecordUploadConfigProjectionTest --wait 30
```

Confirm the deployment report has no component or test failures. Public releases install as immutable unlocked package versions; source deployment is the contributor path.

## Next steps

[Assign permissions](permissions.md), then [configure an upload process](../admin/configure-upload-process.md).
