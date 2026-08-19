@IsTest
private with sharing class BulkRecordUploadLogTest {
  @IsTest
  static void createOrFind_SameUserAndKey_IsIdempotent() {
    BulkRecordUploadLogService service = new BulkRecordUploadLogService();
    String key = EncodingUtil.convertToHex(
      Crypto.generateDigest('SHA-256', Blob.valueOf('idempotent'))
    );
    Bulk_Record_Upload__c first = service.createOrFind('PROCESS', key, 12, 30);
    Bulk_Record_Upload__c second = service.createOrFind('PROCESS', key, 12, 30);
    Assert.areEqual(first.Id, second.Id);
    Assert.areEqual(
      1,
      [SELECT COUNT() FROM Bulk_Record_Upload__c WHERE IdempotencyKey__c = :key]
    );
  }

  @IsTest
  static void transition_ForwardLifecycle_RecordsTimestampsAndCounts() {
    Bulk_Record_Upload__c upload = BulkRecordUploadTestDataFactory.createUpload(
      'LIFECYCLE'
    );
    BulkRecordUploadLogService service = new BulkRecordUploadLogService();
    service.transition(upload.Id, 'VALIDATING', null, null);
    service.transition(upload.Id, 'PROCESSING', null, null);
    service.transition(upload.Id, 'COMPLETED_WITH_ERRORS', 8, 2);
    Bulk_Record_Upload__c stored = [
      SELECT
        Status__c,
        ProcessingStartedAt__c,
        CompletedAt__c,
        SuccessCount__c,
        FailureCount__c
      FROM Bulk_Record_Upload__c
      WHERE Id = :upload.Id
    ];
    Assert.areEqual('COMPLETED_WITH_ERRORS', stored.Status__c);
    Assert.isNotNull(stored.ProcessingStartedAt__c);
    Assert.isNotNull(stored.CompletedAt__c);
    Assert.areEqual(8, stored.SuccessCount__c);
    Assert.areEqual(2, stored.FailureCount__c);
  }

  @IsTest
  static void transition_Backward_IsRejected() {
    Bulk_Record_Upload__c upload = BulkRecordUploadTestDataFactory.createUpload(
      'INVALID_TRANSITION'
    );
    try {
      new BulkRecordUploadLogService().transition(upload.Id, 'COMPLETED', 1, 0);
      Assert.fail('Expected transition exception.');
    } catch (BulkRecordUploadException error) {
      Assert.areEqual(
        'The requested upload status transition is invalid.',
        error.getMessage()
      );
    }
  }

  @IsTest
  static void fail_PartialCommittedChunks_RollsUpDurableCounts() {
    Bulk_Record_Upload__c upload = BulkRecordUploadTestDataFactory.createUpload(
      'PARTIAL_FAILURE'
    );
    BulkRecordUploadTestDataFactory.setUploadRowCount(upload, 10);
    List<Bulk_Record_Upload_Chunk__c> chunks = new BulkRecordUploadStagingService()
      .stage(upload.Id, BulkRecordUploadTestDataFactory.createRows(10), 25);
    BulkRecordUploadTestDataFactory.completeChunk(chunks[0], 7, 1);

    Test.startTest();
    new BulkRecordUploadLogService()
      .fail(upload.Id, 'PROCESSING_ERROR', 'Safe diagnostic.');
    Test.stopTest();

    Bulk_Record_Upload__c stored = [
      SELECT
        Status__c,
        SuccessCount__c,
        FailureCount__c,
        LastErrorCode__c,
        LastErrorMessage__c
      FROM Bulk_Record_Upload__c
      WHERE Id = :upload.Id
    ];
    Assert.areEqual('FAILED', stored.Status__c);
    Assert.areEqual(7, stored.SuccessCount__c);
    Assert.areEqual(3, stored.FailureCount__c);
    Assert.areEqual('PROCESSING_ERROR', stored.LastErrorCode__c);
    Assert.areEqual('Safe diagnostic.', stored.LastErrorMessage__c);
  }

  @IsTest
  static void getHistory_AuthorizedUser_ReturnsVisibleSafeDto() {
    User userRecord = BulkRecordUploadTestDataFactory.createUser('history');
    BulkRecordUploadTestDataFactory.assignPermissionSets(
      userRecord.Id,
      new Set<String>{ 'Bulk_Record_Upload_User' }
    );
    System.runAs(userRecord) {
      Bulk_Record_Upload__c upload = BulkRecordUploadTestDataFactory.createUpload(
        'HISTORY'
      );
      List<BulkRecordUploadHistoryItemV1> items = BulkRecordUploadController.getHistory();
      Assert.areEqual(1, items.size());
      Assert.areEqual(upload.Id, items[0].uploadId);
      Assert.areEqual('HISTORY', items[0].processKey);
    }
  }

  @IsTest
  static void getHistory_ProcessKey_ReturnsOnlyMatchingUploads() {
    User userRecord = BulkRecordUploadTestDataFactory.createUser(
      'historyprocess'
    );
    BulkRecordUploadTestDataFactory.assignPermissionSets(
      userRecord.Id,
      new Set<String>{ 'Bulk_Record_Upload_User' }
    );
    System.runAs(userRecord) {
      Bulk_Record_Upload__c matching = BulkRecordUploadTestDataFactory.createUpload(
        'MATCHING_PROCESS'
      );
      BulkRecordUploadTestDataFactory.createUpload('OTHER_PROCESS');

      Test.startTest();
      List<BulkRecordUploadHistoryItemV1> items = new BulkRecordUploadLogService()
        .getHistory('MATCHING_PROCESS');
      Test.stopTest();

      Assert.areEqual(1, items.size(), 'Only matching history is returned.');
      Assert.areEqual(
        matching.Id,
        items[0].uploadId,
        'The fixed process owns the returned history.'
      );
    }
  }

  @IsTest
  static void getHistory_BlankProcessKey_IsRejected() {
    User userRecord = BulkRecordUploadTestDataFactory.createUser(
      'historyblank'
    );
    BulkRecordUploadTestDataFactory.assignPermissionSets(
      userRecord.Id,
      new Set<String>{ 'Bulk_Record_Upload_User' }
    );
    System.runAs(userRecord) {
      Test.startTest();
      try {
        new BulkRecordUploadLogService().getHistory(' ');
        Assert.fail('Expected a blank process key to be rejected.');
      } catch (BulkRecordUploadException error) {
        Assert.areEqual(
          'The upload process is invalid.',
          error.getMessage(),
          'The error must remain safe and specific.'
        );
      }
      Test.stopTest();
    }
  }
}
