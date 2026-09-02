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
      .resolve('CONFIGURED_PROCESSES', null, 'ACCOUNT_OPERATIONS', 'Account');
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
      new BulkRecordUploadSelectionService()
        .resolve('CONFIGURED_PROCESSES', null, 'EMPTY_BUNDLE', 'Account');
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
      new BulkRecordUploadSelectionService()
        .resolve('CONFIGURED_PROCESSES', null, 'MISSING', 'Account');
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

  @IsTest
  static void isProcessInActiveBundle_MembershipAndBoundaries_AreEnforced() {
    configureBundle('ACCOUNT_OPERATIONS');
    BulkRecordUploadSelectionService.assignmentOverride = new Map<String, Bulk_Record_Upload_Bundle_Process__mdt>{
      'INSERT' => assignment('ACCOUNT_OPERATIONS', 'ACCOUNT_INSERT', 1)
    };

    Test.startTest();
    Boolean member = BulkRecordUploadSelectionService.isProcessInActiveBundle(
      'ACCOUNT_INSERT',
      'ACCOUNT_OPERATIONS'
    );
    Boolean nonMember = BulkRecordUploadSelectionService.isProcessInActiveBundle(
      'ACCOUNT_DELETE',
      'ACCOUNT_OPERATIONS'
    );
    Boolean unknownBundle = BulkRecordUploadSelectionService.isProcessInActiveBundle(
      'ACCOUNT_INSERT',
      'UNKNOWN_BUNDLE'
    );
    Test.stopTest();

    Assert.isTrue(
      member,
      'A process assigned to the active bundle should be recognized.'
    );
    Assert.isFalse(
      nonMember,
      'A process outside the bundle must not be reported as a member.'
    );
    Assert.isFalse(
      unknownBundle,
      'An unknown bundle must never report membership.'
    );
  }

  @IsTest
  static void resolve_SelectedProcess_ReturnsOnlyConfiguredProcess() {
    BulkRecordUploadSelectionService.processOverride = new Map<String, Bulk_Record_Upload_Process__mdt>{
      'ACCOUNT_INSERT' => process('ACCOUNT_INSERT', 'Account Insert'),
      'CONTACT_INSERT' => contactProcess('CONTACT_INSERT', 'Contact Insert')
    };

    Test.startTest();
    BulkRecordUploadSelection result = new BulkRecordUploadSelectionService()
      .resolve('SELECTED_PROCESS', 'ACCOUNT_INSERT', null, 'Account');
    Test.stopTest();

    Assert.areEqual(
      1,
      result.processes.size(),
      'One fixed process should be returned.'
    );
    Assert.areEqual(
      'ACCOUNT_INSERT',
      result.processes[0].value,
      'The selected process should be preserved.'
    );
  }

  @IsTest
  static void resolve_AllActiveForObject_FiltersOtherObjects() {
    BulkRecordUploadSelectionService.processOverride = new Map<String, Bulk_Record_Upload_Process__mdt>{
      'ACCOUNT_INSERT' => process('ACCOUNT_INSERT', 'Account Insert'),
      'CONTACT_INSERT' => contactProcess('CONTACT_INSERT', 'Contact Insert')
    };

    Test.startTest();
    BulkRecordUploadSelection result = new BulkRecordUploadSelectionService()
      .resolve('ALL_ACTIVE_FOR_OBJECT', null, null, 'Account');
    Test.stopTest();

    Assert.areEqual(
      1,
      result.processes.size(),
      'Only processes compatible with Account should be returned.'
    );
    Assert.areEqual(
      'ACCOUNT_INSERT',
      result.processes[0].value,
      'Account should match.'
    );
  }

  @IsTest
  static void resolve_MissingMode_IsRejected() {
    Test.startTest();
    try {
      new BulkRecordUploadSelectionService()
        .resolve(null, null, null, 'Account');
      Assert.fail('A Day-1 component must provide an explicit selection mode.');
    } catch (BulkRecordUploadException error) {
      Assert.areEqual(
        'The process selection mode is invalid.',
        error.getMessage(),
        'Missing modes must not fall back to bundle behavior.'
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
      ConfigurationVersion__c = 2,
      ObjectApiName__c = 'Account'
    );
  }

  private static Bulk_Record_Upload_Process__mdt contactProcess(
    String name,
    String label
  ) {
    Bulk_Record_Upload_Process__mdt value = process(name, label);
    value.ObjectApiName__c = 'Contact';
    return value;
  }
}
