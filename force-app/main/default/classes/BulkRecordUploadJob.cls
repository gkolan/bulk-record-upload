/**
 * Processes one durable staged chunk and enqueues at most one successor.
 * Every exception is converted to a durable FAILED chunk/upload transition in
 * this transaction, so a platform Finalizer would duplicate the same recovery
 * boundary without adding an observable outcome.
 */
@SuppressWarnings('PMD.QueueableWithoutFinalizer')
public with sharing class BulkRecordUploadJob implements Queueable, Database.Batchable<Bulk_Record_Upload_Chunk__c> {
  @TestVisible
  private static BulkRecordUploadProjection projectionOverride;
  private final Id uploadId;
  private final Decimal sequence;

  /** Creates a bounded chunk job. */
  public BulkRecordUploadJob(Id uploadId, Decimal sequence) {
    this.uploadId = uploadId;
    this.sequence = sequence;
  }

  /** Revalidates configuration/access, performs partial DML, and advances orchestration. */
  public void execute(QueueableContext context) {
    processChunk(sequence, true);
  }

  /** Selects ordered ready chunks for edition-independent batch execution. */
  public Iterable<Bulk_Record_Upload_Chunk__c> start(
    Database.BatchableContext context
  ) {
    Integer chunkLimit = BulkRecordUploadRuntimeContract.MAX_CHUNKS;
    return [
      SELECT Id, ProcessingOrder__c
      FROM Bulk_Record_Upload_Chunk__c
      WHERE ParentUpload__c = :uploadId AND Status__c = 'READY'
      WITH SYSTEM_MODE
      ORDER BY ProcessingOrder__c
      LIMIT :chunkLimit
    ];
  }

  /** Processes one durable chunk per Batch Apex transaction. */
  public void execute(
    Database.BatchableContext context,
    List<Bulk_Record_Upload_Chunk__c> scope
  ) {
    if (!scope.isEmpty()) {
      processChunk(scope[0].ProcessingOrder__c, false);
    }
  }

  /** Finalizes only when every chunk completed successfully. */
  public void finish(Database.BatchableContext context) {
    Integer incomplete = [
      SELECT COUNT()
      FROM Bulk_Record_Upload_Chunk__c
      WHERE ParentUpload__c = :uploadId AND Status__c != 'COMPLETED'
      WITH SYSTEM_MODE
    ];
    if (incomplete == 0) {
      new BulkRecordUploadFinalizer().finalizeUpload(uploadId);
    }
  }

  private void processChunk(Decimal processingSequence, Boolean shouldAdvance) {
    Boolean persistenceCompleted = false;
    Bulk_Record_Upload__c upload = [
      SELECT Id, ProcessDeveloperName__c, Status__c, ContextRecordId__c
      FROM Bulk_Record_Upload__c
      WHERE Id = :uploadId
      WITH SYSTEM_MODE
    ];
    Bulk_Record_Upload_Chunk__c chunk = [
      SELECT
        Id,
        Status__c,
        StagedRowData__c,
        IntegrityChecksum__c,
        ProcessingOrder__c
      FROM Bulk_Record_Upload_Chunk__c
      WHERE
        ParentUpload__c = :uploadId
        AND ProcessingOrder__c = :processingSequence
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    if (chunk.Status__c == BulkRecordUploadRuntimeContract.CHUNK_COMPLETED) {
      if (shouldAdvance) {
        advance();
      }
      return;
    }
    try {
      beginLifecycle(upload);
      verifyChecksum(chunk);
      chunk.Status__c = BulkRecordUploadRuntimeContract.CHUNK_PROCESSING;
      update as system chunk;
      BulkRecordUploadProjection projection = projectionOverride == null
        ? new BulkRecordUploadProjectionService()
            .getProjection(upload.ProcessDeveloperName__c)
        : projectionOverride;
      new BulkRecordUploadOperations()
        .resolve(projection.operation)
        .validateProjection(projection);
      List<BulkRecordUploadRow> rows = (List<BulkRecordUploadRow>) JSON.deserialize(
        chunk.StagedRowData__c,
        List<BulkRecordUploadRow>.class
      );
      List<BulkRecordUploadExtension> extensions = new BulkRecordUploadExtensionRegistry()
        .resolve(projection.extensionClassNames);
      for (BulkRecordUploadExtension extension : extensions) {
        rows = extension.beforeMap(projection, rows);
      }
      Map<String, Map<String, Id>> lookupResolutions = new BulkRecordUploadLookupResolver()
        .resolve(projection, rows);
      List<BulkRecordUploadMappedRow> mapped = new BulkRecordUploadRecordMapper()
        .mapRows(projection, rows, lookupResolutions);
      if (
        projection.operation == 'UPDATE' ||
        projection.operation == 'UPSERT' ||
        projection.operation == 'DELETE'
      ) {
        new BulkRecordUploadRecordResolver()
          .assignRecordIds(projection, mapped);
      }
      if (
        projection.operation == 'UPDATE' ||
        projection.operation == 'UPSERT'
      ) {
        new BulkRecordUploadExistingValueMerger()
          .mergeExistingValues(projection, mapped);
      }
      new BulkRecordUploadRecordContextService()
        .applyContext(projection, upload.ContextRecordId__c, mapped);
      Schema.SObjectField upsertField = resolveUpsertField(projection);
      List<BulkRecordUploadRowResult> outcomes = new BulkRecordUploadProcessors()
        .resolve(projection.processorKey)
        .process(projection, mapped, upsertField);
      persistenceCompleted = true;
      for (BulkRecordUploadExtension extension : extensions) {
        extension.afterProcess(uploadId, projection, outcomes);
      }
      chunk.StagedRowData__c = new BulkRecordUploadResultWriter()
        .write(outcomes, projection, rows)
        .toString();
      chunk.SuccessCount__c = countOutcomes(outcomes, true);
      chunk.FailureCount__c = countOutcomes(outcomes, false);
      chunk.Status__c = BulkRecordUploadRuntimeContract.CHUNK_COMPLETED;
      update as system chunk;
      if (shouldAdvance) {
        advance();
      }
    } catch (Exception error) {
      chunk.Status__c = BulkRecordUploadRuntimeContract.CHUNK_FAILED;
      update as system chunk;
      new BulkRecordUploadLogService()
        .fail(
          uploadId,
          persistenceCompleted
            ? BulkRecordUploadRuntimeContract.REASON_PERSISTENCE_COMPLETED_REPORTING_ERROR
            : BulkRecordUploadRuntimeContract.REASON_PROCESSING_ERROR,
          persistenceCompleted
            ? 'Record persistence completed, but result reporting failed. Contact an administrator before retrying.'
            : safeFailureMessage(error)
        );
    }
  }

  private static Integer countOutcomes(
    List<BulkRecordUploadRowResult> outcomes,
    Boolean successes
  ) {
    Integer countValue = 0;
    for (BulkRecordUploadRowResult outcome : outcomes) {
      if (outcome.isSuccess == successes) {
        countValue++;
      }
    }
    return countValue;
  }

  private static String safeFailureMessage(Exception error) {
    return error instanceof BulkRecordUploadException
      ? error.getMessage().left(255)
      : 'Processing failed unexpectedly. Review the process configuration and retry.';
  }

  private void beginLifecycle(Bulk_Record_Upload__c upload) {
    BulkRecordUploadLogService logs = new BulkRecordUploadLogService();
    if (upload.Status__c == BulkRecordUploadRuntimeContract.STATUS_QUEUED) {
      logs.transition(
        uploadId,
        BulkRecordUploadRuntimeContract.STATUS_VALIDATING,
        null,
        null
      );
      logs.transition(
        uploadId,
        BulkRecordUploadRuntimeContract.STATUS_PROCESSING,
        null,
        null
      );
    } else if (
      upload.Status__c == BulkRecordUploadRuntimeContract.STATUS_VALIDATING
    ) {
      logs.transition(
        uploadId,
        BulkRecordUploadRuntimeContract.STATUS_PROCESSING,
        null,
        null
      );
    }
  }

  private static void verifyChecksum(Bulk_Record_Upload_Chunk__c chunk) {
    String checksum = EncodingUtil.convertToHex(
      Crypto.generateDigest('SHA-256', Blob.valueOf(chunk.StagedRowData__c))
    );
    if (checksum != chunk.IntegrityChecksum__c) {
      throw new BulkRecordUploadException(
        'The staged chunk checksum is invalid.'
      );
    }
  }

  private static Schema.SObjectField resolveUpsertField(
    BulkRecordUploadProjection projection
  ) {
    if (projection.operation != 'UPSERT') {
      return null;
    }
    String upsertFieldName;
    for (BulkRecordUploadFieldProjection field : projection.getFields()) {
      if (field.isUpsertKey) {
        upsertFieldName = field.fieldApiName;
        break;
      }
    }
    if (String.isBlank(upsertFieldName)) {
      return null;
    }
    return Schema.getGlobalDescribe()
      .get(projection.objectApiName)
      .getDescribe()
      .fields.getMap()
      .get(upsertFieldName);
  }

  private void advance() {
    List<Bulk_Record_Upload_Chunk__c> nextChunks = [
      SELECT ProcessingOrder__c
      FROM Bulk_Record_Upload_Chunk__c
      WHERE
        ParentUpload__c = :uploadId
        AND ProcessingOrder__c > :sequence
        AND Status__c = 'READY'
      WITH SYSTEM_MODE
      ORDER BY ProcessingOrder__c
      LIMIT 1
    ];
    if (nextChunks.isEmpty()) {
      new BulkRecordUploadFinalizer().finalizeUpload(uploadId);
    } else {
      System.enqueueJob(
        new BulkRecordUploadJob(uploadId, nextChunks[0].ProcessingOrder__c)
      );
    }
  }
}
