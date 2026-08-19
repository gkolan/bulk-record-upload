@IsTest
private with sharing class BulkRecordUploadJobTest {
  @IsTest
  static void execute_OneInsertChunk_FinalizesFileLogAndCleanup() {
    Bulk_Record_Upload__c upload = BulkRecordUploadTestDataFactory.createUpload(
      'JOB_SUCCESS'
    );
    List<Bulk_Record_Upload_Chunk__c> chunks = new BulkRecordUploadStagingService()
      .stage(
        upload.Id,
        new List<BulkRecordUploadRowV1>{
          new BulkRecordUploadRowV1(
            2,
            new Map<String, String>{ 'name' => 'Async Account' }
          )
        },
        100
      );
    BulkRecordUploadJob.projectionOverride = projection();

    Test.startTest();
    new BulkRecordUploadJob(upload.Id, chunks[0].ProcessingOrder__c)
      .execute(null);
    Test.stopTest();

    Bulk_Record_Upload__c stored = [
      SELECT Status__c, SuccessCount__c, FailureCount__c, ResultFileId__c
      FROM Bulk_Record_Upload__c
      WHERE Id = :upload.Id
    ];
    Assert.areEqual('COMPLETED', stored.Status__c);
    Assert.areEqual(1, stored.SuccessCount__c);
    Assert.areEqual(0, stored.FailureCount__c);
    Assert.isNotNull(stored.ResultFileId__c);
    Assert.areEqual(
      0,
      [
        SELECT COUNT()
        FROM Bulk_Record_Upload_Chunk__c
        WHERE ParentUpload__c = :upload.Id
      ]
    );
    Assert.areEqual(
      1,
      [SELECT COUNT() FROM Account WHERE Name = 'Async Account']
    );
  }

  @IsTest
  static void orchestrator_NoReadyChunk_IsRejectedWithoutEnqueue() {
    Bulk_Record_Upload__c upload = BulkRecordUploadTestDataFactory.createUpload(
      'NO_CHUNK'
    );
    try {
      new BulkRecordUploadOrchestrator().start(upload.Id);
      Assert.fail('Expected ready-chunk exception.');
    } catch (BulkRecordUploadException error) {
      Assert.areEqual('No staged chunk is ready.', error.getMessage());
      Assert.areEqual(0, Limits.getQueueableJobs());
    }
  }

  @IsTest
  static void orchestrator_ReadyChunk_StartsBatchAndFailsSafelyWithoutConfig() {
    Bulk_Record_Upload__c upload = BulkRecordUploadTestDataFactory.createUpload(
      'JOB_SAFE_FAILURE'
    );
    new BulkRecordUploadStagingService()
      .stage(
        upload.Id,
        new List<BulkRecordUploadRowV1>{
          new BulkRecordUploadRowV1(
            2,
            new Map<String, String>{ 'name' => 'Never logged' }
          )
        },
        100
      );
    BulkRecordUploadJob.projectionOverride = null;
    Test.startTest();
    Id jobId = new BulkRecordUploadOrchestrator().start(upload.Id);
    Test.stopTest();
    Assert.isNotNull(jobId);
    Bulk_Record_Upload__c stored = [
      SELECT Status__c
      FROM Bulk_Record_Upload__c
      WHERE Id = :upload.Id
    ];
    Assert.areEqual('FAILED', stored.Status__c);
  }

  @IsTest
  static void execute_FirstOfTwoChunks_EnqueuesOneSuccessor() {
    Bulk_Record_Upload__c upload = BulkRecordUploadTestDataFactory.createUpload(
      'JOB_CHAIN'
    );
    List<BulkRecordUploadRowV1> rows = new List<BulkRecordUploadRowV1>();
    for (Integer index = 0; index < 26; index++) {
      rows.add(
        new BulkRecordUploadRowV1(
          index + 2,
          new Map<String, String>{ 'name' => 'Chain ' + index }
        )
      );
    }
    List<Bulk_Record_Upload_Chunk__c> chunks = new BulkRecordUploadStagingService()
      .stage(upload.Id, rows, 25);
    BulkRecordUploadJob.projectionOverride = projection();
    Test.startTest();
    new BulkRecordUploadJob(upload.Id, chunks[0].ProcessingOrder__c)
      .execute(null);
    Integer queued = Limits.getQueueableJobs();
    Test.stopTest();
    Assert.areEqual(1, queued);
  }

  private static BulkRecordUploadProjectionV1 projection() {
    BulkRecordUploadFieldProjectionV1 field = new BulkRecordUploadFieldProjectionV1(
      'name',
      'Name',
      'Name',
      'STRING',
      'REPLACE',
      1,
      true,
      false,
      false,
      true,
      true,
      true
    );
    return new BulkRecordUploadProjectionV1(
      'JOB_SUCCESS',
      'hash',
      'Account',
      'INSERT',
      'STANDARD_V1',
      100,
      30,
      new List<BulkRecordUploadFieldProjectionV1>{ field }
    );
  }
}
