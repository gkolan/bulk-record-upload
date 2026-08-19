@IsTest
private with sharing class BulkRecordUploadJobTest {
  @TestVisible
  private static List<String> extensionCallLog = new List<String>();

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
      new List<String>(),
      100,
      30,
      new List<BulkRecordUploadFieldProjectionV1>{ field }
    );
  }

  private static BulkRecordUploadProjectionV1 projectionWithExtensions(
    String processKey,
    List<String> extensionClassNames
  ) {
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
      processKey,
      'hash',
      'Account',
      'INSERT',
      extensionClassNames,
      100,
      30,
      new List<BulkRecordUploadFieldProjectionV1>{ field }
    );
  }

  @IsTest
  static void execute_TwoRegisteredExtensions_RunBothPhasesInSortOrder() {
    extensionCallLog.clear();
    Bulk_Record_Upload__c upload = BulkRecordUploadTestDataFactory.createUpload(
      'JOB_EXTENSION_ORDER'
    );
    new BulkRecordUploadStagingService()
      .stage(
        upload.Id,
        new List<BulkRecordUploadRowV1>{
          new BulkRecordUploadRowV1(
            2,
            new Map<String, String>{ 'name' => 'Ordered Account' }
          )
        },
        100
      );
    BulkRecordUploadJob.projectionOverride = projectionWithExtensions(
      'JOB_EXTENSION_ORDER',
      new List<String>{
        'BulkRecordUploadJobTest.OrderExtensionA',
        'BulkRecordUploadJobTest.OrderExtensionB'
      }
    );

    Test.startTest();
    new BulkRecordUploadOrchestrator().start(upload.Id);
    Test.stopTest();

    Assert.areEqual(
      new List<String>{
        'A-beforeMap',
        'B-beforeMap',
        'A-afterProcess',
        'B-afterProcess'
      },
      extensionCallLog,
      'Both extensions must run at both phases, in configured sort order.'
    );
  }

  @IsTest
  static void execute_ThrowingExtension_FailsUploadWithoutWedgingChunk() {
    Bulk_Record_Upload__c upload = BulkRecordUploadTestDataFactory.createUpload(
      'JOB_EXTENSION_THROWS'
    );
    List<Bulk_Record_Upload_Chunk__c> chunks = new BulkRecordUploadStagingService()
      .stage(
        upload.Id,
        new List<BulkRecordUploadRowV1>{
          new BulkRecordUploadRowV1(
            2,
            new Map<String, String>{ 'name' => 'Never persisted' }
          )
        },
        100
      );
    BulkRecordUploadJob.projectionOverride = projectionWithExtensions(
      'JOB_EXTENSION_THROWS',
      new List<String>{ 'BulkRecordUploadJobTest.ThrowingExtension' }
    );

    Test.startTest();
    new BulkRecordUploadJob(upload.Id, chunks[0].ProcessingOrder__c)
      .execute(null);
    Test.stopTest();

    Bulk_Record_Upload__c storedUpload = [
      SELECT Status__c, LastErrorCode__c
      FROM Bulk_Record_Upload__c
      WHERE Id = :upload.Id
    ];
    Assert.areEqual('FAILED', storedUpload.Status__c);
    Assert.areEqual('PROCESSING_ERROR', storedUpload.LastErrorCode__c);
    Bulk_Record_Upload_Chunk__c storedChunk = [
      SELECT Status__c
      FROM Bulk_Record_Upload_Chunk__c
      WHERE Id = :chunks[0].Id
    ];
    Assert.areEqual(
      'FAILED',
      storedChunk.Status__c,
      'A throwing extension must leave the chunk in a terminal, not wedged, status.'
    );
    Assert.areEqual(
      0,
      [SELECT COUNT() FROM Account WHERE Name = 'Never persisted'],
      'No record should be persisted when an extension fails before mapping.'
    );
  }

  /** Test-only extension proving configured sort order at both lifecycle phases. */
  public class OrderExtensionA implements BulkRecordUploadExtensionV1 {
    public List<BulkRecordUploadRowV1> beforeMap(
      BulkRecordUploadProjectionV1 projection,
      List<BulkRecordUploadRowV1> rows
    ) {
      extensionCallLog.add('A-beforeMap');
      return rows;
    }
    public void afterProcess(
      Id uploadId,
      BulkRecordUploadProjectionV1 projection,
      List<BulkRecordUploadRowResultV1> outcomes
    ) {
      extensionCallLog.add('A-afterProcess');
    }
  }

  /** Test-only extension proving configured sort order at both lifecycle phases. */
  public class OrderExtensionB implements BulkRecordUploadExtensionV1 {
    public List<BulkRecordUploadRowV1> beforeMap(
      BulkRecordUploadProjectionV1 projection,
      List<BulkRecordUploadRowV1> rows
    ) {
      extensionCallLog.add('B-beforeMap');
      return rows;
    }
    public void afterProcess(
      Id uploadId,
      BulkRecordUploadProjectionV1 projection,
      List<BulkRecordUploadRowResultV1> outcomes
    ) {
      extensionCallLog.add('B-afterProcess');
    }
  }

  /** Test-only extension proving a throwing extension fails the upload safely. */
  public class ThrowingExtension implements BulkRecordUploadExtensionV1 {
    public List<BulkRecordUploadRowV1> beforeMap(
      BulkRecordUploadProjectionV1 projection,
      List<BulkRecordUploadRowV1> rows
    ) {
      throw new BulkRecordUploadException('Extension deliberately failed.');
    }
    public void afterProcess(
      Id uploadId,
      BulkRecordUploadProjectionV1 projection,
      List<BulkRecordUploadRowResultV1> outcomes
    ) {
      return; // Intentionally empty: beforeMap always throws first.
    }
  }
}
