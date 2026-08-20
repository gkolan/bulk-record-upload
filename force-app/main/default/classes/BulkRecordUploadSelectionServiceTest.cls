@IsTest
private with sharing class BulkRecordUploadSelectionServiceTest {
  @IsTest
  static void resolve_ActiveProcesses_ReturnsLabelOrderedOptions() {
    configureBundle('ACCOUNT_OPERATIONS');
    BulkRecordUploadSelectionService.processOverride = new Map<String, Bulk_Record_Upload_Process__mdt>{
      'ACCOUNT_INSERT' => process('ACCOUNT_INSERT', 'Account Insert'),
      'ACCOUNT_UPDATE' => process('ACCOUNT_UPDATE', 'Account Update')
    };
    BulkRecordUploadSelectionService.assignmentOverride = new Map<String, Bulk_Record_Upload_Bundle_Process__mdt>{
      'UPDATE' => assignment('ACCOUNT_OPERATIONS', 'ACCOUNT_UPDATE', 2),
      'INSERT' => assignment('ACCOUNT_OPERATIONS', 'ACCOUNT_INSERT', 1)
    };
    Test.startTest();
    BulkRecordUploadSelection result = new BulkRecordUploadSelectionService()
      .resolve('ACCOUNT_OPERATIONS');
    Test.stopTest();
    Assert.areEqual(
      'AVAILABLE',
      result.selectionType,
      'The response should identify server-resolved availability.'
    );
    Assert.areEqual(
      2,
      result.processes.size(),
      'Both configured processes should be offered.'
    );
    Assert.areEqual(
      'ACCOUNT_INSERT',
      result.processes[0].value,
      'Options should be sorted by their user-facing label.'
    );
    Assert.areEqual(
      'Account Insert',
      result.processes[0].label,
      'Users should see the process label.'
    );
  }

  @IsTest
  static void resolve_NoActiveProcess_ReturnsVisibleFailure() {
    configureBundle('EMPTY_BUNDLE');
    BulkRecordUploadSelectionService.processOverride = new Map<String, Bulk_Record_Upload_Process__mdt>();
    BulkRecordUploadSelectionService.assignmentOverride = new Map<String, Bulk_Record_Upload_Bundle_Process__mdt>();
    Test.startTest();
    try {
      new BulkRecordUploadSelectionService().resolve('EMPTY_BUNDLE');
      Assert.fail('Expected an empty process catalog to be rejected.');
    } catch (BulkRecordUploadException error) {
      Assert.areEqual(
        'No active upload process is available.',
        error.getMessage(),
        'An empty process catalog should fail visibly.'
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void resolve_MissingBundle_ReturnsVisibleFailure() {
    BulkRecordUploadSelectionService.bundleOverride = new Map<String, Bulk_Record_Upload_Bundle__mdt>();
    Test.startTest();
    try {
      new BulkRecordUploadSelectionService().resolve('MISSING');
      Assert.fail('Expected a missing bundle to be rejected.');
    } catch (BulkRecordUploadException error) {
      Assert.areEqual(
        'The configured upload bundle is unavailable.',
        error.getMessage(),
        'A missing bundle should fail visibly.'
      );
    }
    Test.stopTest();
  }

  private static void configureBundle(String name) {
    BulkRecordUploadSelectionService.bundleOverride = new Map<String, Bulk_Record_Upload_Bundle__mdt>{
      name => new Bulk_Record_Upload_Bundle__mdt(
        DeveloperName = name,
        MasterLabel = name,
        IsActive__c = true
      )
    };
  }

  private static Bulk_Record_Upload_Bundle_Process__mdt assignment(
    String bundleName,
    String processName,
    Decimal displayOrder
  ) {
    return new Bulk_Record_Upload_Bundle_Process__mdt(
      DeveloperName = bundleName + '_' + processName,
      MasterLabel = processName,
      BundleDeveloperName__c = bundleName,
      ProcessDeveloperName__c = processName,
      DisplayOrder__c = displayOrder,
      IsActive__c = true
    );
  }

  private static Bulk_Record_Upload_Process__mdt process(
    String name,
    String label
  ) {
    return new Bulk_Record_Upload_Process__mdt(
      DeveloperName = name,
      MasterLabel = label,
      IsActive__c = true,
      ConfigurationVersion__c = 2
    );
  }
}
