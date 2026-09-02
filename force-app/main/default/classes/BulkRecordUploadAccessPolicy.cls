/**
 * Centralizes Custom Permission, object CRUD, and configured-field FLS decisions.
 */
public with sharing class BulkRecordUploadAccessPolicy {
  /**
   * Requires the base run capability.
   * @throws BulkRecordUploadException when the current user lacks Bulk_Record_Upload_Run.
   */
  public void requireRunPermission() {
    if (!FeatureManagement.checkPermission('Bulk_Record_Upload_Run')) {
      throw new BulkRecordUploadException(
        'You are not authorized to run uploads.'
      );
    }
  }

  /**
   * Validates operation-level CRUD and special capability boundaries.
   * @param objectDescribe Resolved target object describe.
   * @param operation Stable approved operation code.
   * @throws BulkRecordUploadException when access is insufficient.
   */
  public void requireOperationAccess(
    Schema.DescribeSObjectResult objectDescribe,
    String operation
  ) {
    if (objectDescribe == null || String.isBlank(operation)) {
      throw new BulkRecordUploadException(
        'Target access configuration is invalid.'
      );
    }
    String normalizedOperation = operation.toUpperCase();
    Boolean allowed = normalizedOperation == 'INSERT'
      ? objectDescribe.isCreateable()
      : normalizedOperation == 'DELETE'
          ? objectDescribe.isAccessible() && objectDescribe.isDeletable()
          : normalizedOperation == 'UPSERT'
              ? objectDescribe.isAccessible() &&
                objectDescribe.isCreateable() &&
                objectDescribe.isUpdateable()
              : objectDescribe.isAccessible() && objectDescribe.isUpdateable();
    if (!allowed) {
      throw new BulkRecordUploadException(
        'Target object access is insufficient for this process.'
      );
    }
    if (
      normalizedOperation == 'DELETE' &&
      !FeatureManagement.checkPermission('Bulk_Record_Upload_Delete')
    ) {
      throw new BulkRecordUploadException(
        'You are not authorized to run delete processes.'
      );
    }
  }

  /**
   * Validates an optional project-owned preview Custom Permission reference.
   * @param permissionName Exact Custom Permission API name or blank.
   * @throws BulkRecordUploadException for unowned or ungranted names.
   */
  public void requirePreviewPermission(String permissionName) {
    if (String.isBlank(permissionName)) {
      return;
    }
    if (permissionName != 'Bulk_Record_Upload_Preview') {
      throw new BulkRecordUploadException(
        'Preview permission configuration is not supported.'
      );
    }
    if (!FeatureManagement.checkPermission(permissionName)) {
      throw new BulkRecordUploadException(
        'You are not authorized to preview this process.'
      );
    }
  }
}
