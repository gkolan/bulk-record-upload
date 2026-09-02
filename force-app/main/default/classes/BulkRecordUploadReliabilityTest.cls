@IsTest
private with sharing class BulkRecordUploadReliabilityTest {
  @IsTest
  static void createUpload_TwoActiveProcesses_ReservesDistinctClaims() {
    Test.startTest();
    Bulk_Record_Upload__c first = createClaimedUpload(
      'RELIABILITY_CLAIM_A',
      'hash-a'
    );
    Bulk_Record_Upload__c second = createClaimedUpload(
      'RELIABILITY_CLAIM_B',
      'hash-b'
    );
    Test.stopTest();
    Set<Id> uploadIds = new Set<Id>{ first.Id, second.Id };
    Map<Id, Bulk_Record_Upload__c> storedById = new Map<Id, Bulk_Record_Upload__c>(
      [
        SELECT ActiveOrgSlot__c, ActiveUserProcessKey__c
        FROM Bulk_Record_Upload__c
        WHERE Id IN :uploadIds
      ]
    );
    Assert.areEqual(
      2,
      storedById.size(),
      'Both active uploads should be durably created.'
    );
    Assert.isNotNull(
      storedById.get(first.Id).ActiveOrgSlot__c,
      'The first upload should reserve an organization slot.'
    );
    Assert.areNotEqual(
      storedById.get(first.Id).ActiveOrgSlot__c,
      storedById.get(second.Id).ActiveOrgSlot__c,
      'Concurrent uploads should reserve distinct organization slots.'
    );
    Assert.areEqual(
      64,
      storedById.get(first.Id).ActiveUserProcessKey__c.length(),
      'The user-process claim should be a SHA-256 digest.'
    );
    Assert.areNotEqual(
      storedById.get(first.Id).ActiveUserProcessKey__c,
      storedById.get(second.Id).ActiveUserProcessKey__c,
      'Different processes should reserve different user-process claims.'
    );
  }
  @IsTest
  static void transition_CompletedUpload_ReleasesActiveClaims() {
    Bulk_Record_Upload__c upload = createClaimedUpload(
      'RELIABILITY_TERMINAL',
      'terminal-hash'
    );
    BulkRecordUploadLogService logs = new BulkRecordUploadLogService();
    Test.startTest();
    logs.transition(upload.Id, 'VALIDATING', null, null);
    logs.transition(upload.Id, 'PROCESSING', null, null);
    logs.transition(upload.Id, 'COMPLETED', 1, 0);
    Test.stopTest();
    Bulk_Record_Upload__c stored = uploadWithClaims(upload.Id);
    Assert.areEqual(
      'COMPLETED',
      stored.Status__c,
      'The upload should reach its requested terminal status.'
    );
    assertClaimsReleased(stored);
  }
  @IsTest
  static void fail_NonterminalUpload_ReleasesActiveClaims() {
    Bulk_Record_Upload__c upload = createClaimedUpload(
      'RELIABILITY_FAIL',
      'failure-hash'
    );
    Test.startTest();
    new BulkRecordUploadLogService()
      .fail(upload.Id, 'PROCESSING_ERROR', 'Safe regression diagnostic.');
    Test.stopTest();
    Bulk_Record_Upload__c stored = uploadWithClaims(upload.Id);
    Assert.areEqual(
      'FAILED',
      stored.Status__c,
      'A fatal upload should reach FAILED.'
    );
    assertClaimsReleased(stored);
  }
  @IsTest
  static void execute_ConfigHashMismatch_FailsBeforeTargetDml() {
    String processKey = 'RELIABILITY_CONFIG_DRIFT';
    Bulk_Record_Upload__c upload = createPinnedUpload(
      processKey,
      'submitted-hash'
    );
    List<Bulk_Record_Upload_Chunk__c> chunks = stageOneRow(upload.Id);
    BulkRecordUploadJob.projectionOverride = projection(
      processKey,
      'changed-hash'
    );
    Test.startTest();
    new BulkRecordUploadJob(upload.Id, chunks[0].ProcessingOrder__c)
      .execute(null);
    Test.stopTest();
    Bulk_Record_Upload__c stored = [
      SELECT Status__c, LastErrorCode__c
      FROM Bulk_Record_Upload__c
      WHERE Id = :upload.Id
    ];
    Assert.areEqual(
      'FAILED',
      stored.Status__c,
      'Configuration drift should fail the upload.'
    );
    Assert.areEqual(
      'CONFIGURATION_CHANGED',
      stored.LastErrorCode__c,
      'Configuration drift should use its stable reason code.'
    );
    Assert.areEqual(
      0,
      [SELECT COUNT() FROM Account WHERE Name = 'Row 0'],
      'No target DML should run after a configuration hash mismatch.'
    );
  }
  @IsTest
  static void execute_FailedChunk_DoesNotReprocessTargetDml() {
    assertTerminalChunkIsNotProcessed('FAILED');
  }
  @IsTest
  static void execute_ProcessingChunk_DoesNotReprocessTargetDml() {
    assertTerminalChunkIsNotProcessed('PROCESSING');
  }
  @IsTest
  static void execute_CompletedChunk_UpdatesResultChecksum() {
    String processKey = 'RELIABILITY_CHECKSUM';
    String configHash = 'checksum-hash';
    Bulk_Record_Upload__c upload = createPinnedUpload(processKey, configHash);
    List<Bulk_Record_Upload_Chunk__c> chunks = stageOneRow(upload.Id);
    String inputChecksum = chunks[0].IntegrityChecksum__c;
    BulkRecordUploadJob.projectionOverride = projection(processKey, configHash);
    Test.startTest();
    new BulkRecordUploadJob(upload.Id, null)
      .execute(
        (Database.BatchableContext) null,
        new List<Bulk_Record_Upload_Chunk__c>{ chunks[0] }
      );
    Test.stopTest();
    Bulk_Record_Upload_Chunk__c stored = [
      SELECT Status__c, StagedRowData__c, IntegrityChecksum__c
      FROM Bulk_Record_Upload_Chunk__c
      WHERE Id = :chunks[0].Id
    ];
    Assert.areEqual(
      'COMPLETED',
      stored.Status__c,
      'The successful batch scope should leave a completed result chunk.'
    );
    Assert.areNotEqual(
      inputChecksum,
      stored.IntegrityChecksum__c,
      'Replacing staged input with results should replace its checksum.'
    );
    Assert.areEqual(
      checksum(stored.StagedRowData__c),
      stored.IntegrityChecksum__c,
      'The completed checksum should cover the durable result payload.'
    );
  }
  @IsTest
  static void finalizePartialResults_CompletedAndFailedChunks_PromotesOnlyCompleted() {
    Bulk_Record_Upload__c upload = BulkRecordUploadTestDataFactory.createUpload(
      'RELIABILITY_PARTIAL'
    );
    List<Bulk_Record_Upload_Chunk__c> chunks = new BulkRecordUploadStagingService()
      .stage(upload.Id, BulkRecordUploadTestDataFactory.createRows(26), 25);
    String resultPayload = new BulkRecordUploadResultWriter()
      .write(
        new List<BulkRecordUploadRowResult>{
          new BulkRecordUploadRowResult(2, true, null, null, null)
        }
      )
      .toString();
    BulkRecordUploadTestDataFactory.completeChunk(chunks[0], 1, 0);
    updateRecord(
      new Bulk_Record_Upload_Chunk__c(
        Id = chunks[0].Id,
        StagedRowData__c = resultPayload,
        IntegrityChecksum__c = checksum(resultPayload)
      )
    );
    updateRecord(
      new Bulk_Record_Upload_Chunk__c(Id = chunks[1].Id, Status__c = 'FAILED')
    );
    Test.startTest();
    Boolean promoted = new BulkRecordUploadFinalizer()
      .finalizePartialResults(upload.Id);
    Test.stopTest();
    Bulk_Record_Upload__c storedUpload = [
      SELECT ResultFileId__c
      FROM Bulk_Record_Upload__c
      WHERE Id = :upload.Id
    ];
    Assert.isTrue(promoted, 'A completed fragment should be promoted.');
    Assert.isNotNull(
      storedUpload.ResultFileId__c,
      'Partial promotion should create a downloadable result File.'
    );
    List<Bulk_Record_Upload_Chunk__c> remaining = [
      SELECT Id, Status__c
      FROM Bulk_Record_Upload_Chunk__c
      WHERE ParentUpload__c = :upload.Id
    ];
    Assert.areEqual(
      1,
      remaining.size(),
      'Only the unpromoted fatal chunk should remain.'
    );
    Assert.areEqual(
      chunks[1].Id,
      remaining[0].Id,
      'Partial finalization must delete only the promoted chunk.'
    );
    ContentVersion resultVersion = [
      SELECT VersionData
      FROM ContentVersion
      WHERE ContentDocumentId = :storedUpload.ResultFileId__c
      WITH SYSTEM_MODE
      ORDER BY VersionNumber DESC
      LIMIT 1
    ];
    Assert.isTrue(
      resultVersion.VersionData.toString().contains('"2","SUCCESS"'),
      'The promoted File should contain the completed chunk result row.'
    );
  }
  @IsTest
  static void recover_StaleClaim_FailsUploadAndReleasesClaims() {
    Bulk_Record_Upload__c upload = createClaimedUpload(
      'RELIABILITY_RECOVERY',
      'recovery-hash'
    );
    updateRecord(
      new Bulk_Record_Upload__c(
        Id = upload.Id,
        SubmittedAt__c = System.now()
          .addHours(
            -BulkRecordUploadRuntimeContract.MAX_ACTIVE_UPLOAD_HOURS - 1
          )
      )
    );
    Test.startTest();
    Integer recovered = new BulkRecordUploadRecoveryService().recover();
    Test.stopTest();
    Bulk_Record_Upload__c stored = [
      SELECT
        Status__c,
        LastErrorCode__c,
        ActiveOrgSlot__c,
        ActiveUserProcessKey__c
      FROM Bulk_Record_Upload__c
      WHERE Id = :upload.Id
    ];
    Assert.areEqual(1, recovered, 'The one stale claim should be recovered.');
    Assert.areEqual(
      'FAILED',
      stored.Status__c,
      'Recovery should fail abandoned work.'
    );
    Assert.areEqual(
      'ABANDONED_UPLOAD',
      stored.LastErrorCode__c,
      'Recovery should record the stable abandoned-upload reason.'
    );
    assertClaimsReleased(stored);
  }
  @IsTest
  static void cleanup_PastAndFutureFormulaCutoffs_DeletesOnlyExpiredUpload() {
    Bulk_Record_Upload__c expired = BulkRecordUploadTestDataFactory.createExpiredUpload(
      'RELIABILITY_EXPIRED'
    );
    Bulk_Record_Upload__c retained = BulkRecordUploadTestDataFactory.createUpload(
      'RELIABILITY_RETAINED'
    );
    Datetime retainedCompletion = System.now().addDays(-29);
    updateRecord(
      new Bulk_Record_Upload__c(
        Id = retained.Id,
        Status__c = 'COMPLETED',
        CompletedAt__c = retainedCompletion,
        RetentionDays__c = 30
      )
    );
    Set<Id> uploadIds = new Set<Id>{ expired.Id, retained.Id };
    Map<Id, Bulk_Record_Upload__c> beforeCleanup = new Map<Id, Bulk_Record_Upload__c>(
      [
        SELECT CompletedAt__c, RetentionDays__c, ExpiresAt__c
        FROM Bulk_Record_Upload__c
        WHERE Id IN :uploadIds
      ]
    );
    Assert.areEqual(
      retainedCompletion.addDays(30),
      beforeCleanup.get(retained.Id).ExpiresAt__c,
      'Expires At should equal completion plus the configured retention days.'
    );
    Test.startTest();
    Integer removed = new BulkRecordUploadRetentionJob().cleanup();
    Test.stopTest();
    Assert.areEqual(
      1,
      removed,
      'Only the elapsed formula cutoff should be removed.'
    );
    Assert.areEqual(
      0,
      [SELECT COUNT() FROM Bulk_Record_Upload__c WHERE Id = :expired.Id],
      'The expired upload should be deleted.'
    );
    Assert.areEqual(
      1,
      [SELECT COUNT() FROM Bulk_Record_Upload__c WHERE Id = :retained.Id],
      'The future expiration should remain.'
    );
  }
  private static Bulk_Record_Upload__c createClaimedUpload(
    String processKey,
    String configHash
  ) {
    return new BulkRecordUploadLogService()
      .createOrFindWithState(
        processKey,
        checksum(processKey),
        1,
        30,
        null,
        configHash
      )
      .upload;
  }
  private static Bulk_Record_Upload__c createPinnedUpload(
    String processKey,
    String configHash
  ) {
    Bulk_Record_Upload__c upload = BulkRecordUploadTestDataFactory.createUpload(
      processKey
    );
    updateRecord(
      new Bulk_Record_Upload__c(Id = upload.Id, ConfigHash__c = configHash)
    );
    return upload;
  }
  private static List<Bulk_Record_Upload_Chunk__c> stageOneRow(Id uploadId) {
    return new BulkRecordUploadStagingService()
      .stage(uploadId, BulkRecordUploadTestDataFactory.createRows(1), 25);
  }

  private static void assertTerminalChunkIsNotProcessed(String chunkStatus) {
    String processKey = 'RELIABILITY_' + chunkStatus;
    Bulk_Record_Upload__c upload = createPinnedUpload(processKey, 'claim-hash');
    List<Bulk_Record_Upload_Chunk__c> chunks = stageOneRow(upload.Id);
    updateRecord(
      new Bulk_Record_Upload_Chunk__c(
        Id = chunks[0].Id,
        Status__c = chunkStatus
      )
    );
    BulkRecordUploadJob.projectionOverride = projection(
      processKey,
      'claim-hash'
    );
    Test.startTest();
    new BulkRecordUploadJob(upload.Id, chunks[0].ProcessingOrder__c)
      .execute(null);
    Test.stopTest();
    Bulk_Record_Upload_Chunk__c storedChunk = [
      SELECT Status__c
      FROM Bulk_Record_Upload_Chunk__c
      WHERE Id = :chunks[0].Id
    ];
    Assert.areEqual(
      chunkStatus,
      storedChunk.Status__c,
      'A non-READY chunk should retain its terminal or claimed status.'
    );
    Assert.areEqual(
      0,
      [SELECT COUNT() FROM Account WHERE Name = 'Row 0'],
      'A non-READY chunk must not execute target DML.'
    );
  }

  private static BulkRecordUploadProjection projection(
    String processKey,
    String configHash
  ) {
    BulkRecordUploadFieldProjection field = new BulkRecordUploadFieldProjection(
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
    return new BulkRecordUploadProjection(
      processKey,
      configHash,
      'Account',
      'INSERT',
      new List<String>(),
      100,
      30,
      new List<BulkRecordUploadFieldProjection>{ field }
    );
  }

  private static Bulk_Record_Upload__c uploadWithClaims(Id uploadId) {
    return [
      SELECT Status__c, ActiveOrgSlot__c, ActiveUserProcessKey__c
      FROM Bulk_Record_Upload__c
      WHERE Id = :uploadId
    ];
  }

  private static void assertClaimsReleased(Bulk_Record_Upload__c upload) {
    Assert.isNull(
      upload.ActiveOrgSlot__c,
      'A terminal upload should release its organization slot.'
    );
    Assert.isNull(
      upload.ActiveUserProcessKey__c,
      'A terminal upload should release its user-process claim.'
    );
  }

  private static void updateRecord(SObject recordValue) {
    Database.update(recordValue, false, AccessLevel.SYSTEM_MODE);
  }

  private static String checksum(String value) {
    return EncodingUtil.convertToHex(
      Crypto.generateDigest('SHA-256', Blob.valueOf(value == null ? '' : value))
    );
  }
}
