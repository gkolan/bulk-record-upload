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
    Savepoint persistenceBoundary;
    Bulk_Record_Upload__c upload = [
      SELECT
        Id,
        ProcessDeveloperName__c,
        Status__c,
        ContextRecordId__c,
        ConfigHash__c
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
      FOR UPDATE
    ];
    if (chunk.Status__c == BulkRecordUploadRuntimeContract.CHUNK_COMPLETED) {
      if (shouldAdvance) {
        advance();
      }
      return;
    }
    if (chunk.Status__c != BulkRecordUploadRuntimeContract.CHUNK_READY) {
      // Another worker claimed or terminated this row while this transaction
      // waited for the lock. Only READY is a valid processing claim.
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
      verifyConfiguration(upload, projection);
      new BulkRecordUploadOperations()
        .resolve(projection.operation)
        .validateProjection(projection);
      List<BulkRecordUploadRow> rows = (List<BulkRecordUploadRow>) JSON.deserialize(
        chunk.StagedRowData__c,
        List<BulkRecordUploadRow>.class
      );
      List<BulkRecordUploadExtension> extensions = new BulkRecordUploadExtensionRegistry()
        .resolve(projection.extensionClassNames);
      List<Integer> expectedRowNumbers = rowNumbers(rows);
      for (BulkRecordUploadExtension extension : extensions) {
        rows = extension.beforeMap(projection, rows);
        validateExtensionRows(rows, expectedRowNumbers);
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
      persistenceBoundary = Database.setSavepoint();
      List<BulkRecordUploadRowResult> outcomes = new BulkRecordUploadProcessors()
        .resolve(projection.processorKey)
        .process(projection, mapped, upsertField);
      String resultPayload = new BulkRecordUploadResultWriter()
        .write(outcomes, projection, rows)
        .toString();
      chunk.StagedRowData__c = resultPayload;
      chunk.IntegrityChecksum__c = checksum(resultPayload);
      chunk.SuccessCount__c = countOutcomes(outcomes, true);
      chunk.FailureCount__c = countOutcomes(outcomes, false);
      chunk.Status__c = BulkRecordUploadRuntimeContract.CHUNK_COMPLETED;
      update as system chunk;
      chunk.StagedRowData__c = [
        SELECT StagedRowData__c
        FROM Bulk_Record_Upload_Chunk__c
        WHERE Id = :chunk.Id
        WITH SYSTEM_MODE
      ]
      .StagedRowData__c;
      chunk.IntegrityChecksum__c = checksum(chunk.StagedRowData__c);
      update as system chunk;
      runAfterProcess(extensions, projection, outcomes);
      if (shouldAdvance) {
        advance();
      }
    } catch (Exception error) {
      if (persistenceBoundary != null) {
        Database.rollback(persistenceBoundary);
      }
      update as system new Bulk_Record_Upload_Chunk__c(
        Id = chunk.Id,
        Status__c = BulkRecordUploadRuntimeContract.CHUNK_FAILED
      );
      BulkRecordUploadLogService logs = new BulkRecordUploadLogService();
      logs.fail(uploadId, reasonCode(error), safeFailureMessage(error));
      try {
        new BulkRecordUploadFinalizer().finalizePartialResults(uploadId);
        // Partial result promotion is best-effort after the durable Failed state.
        // code-analyzer-suppress-next-line EmptyCatchBlock
      } catch (Exception partialResultError) {
        // The fatal upload state and its staged chunks remain durable. A later
        // retention/support pass can retry partial result promotion safely.
      }
    }
  }

  /** Runs post-processing extensions independently after durable row results. */
  private void runAfterProcess(
    List<BulkRecordUploadExtension> extensions,
    BulkRecordUploadProjection projection,
    List<BulkRecordUploadRowResult> outcomes
  ) {
    for (BulkRecordUploadExtension extension : extensions) {
      try {
        extension.afterProcess(uploadId, projection, outcomes);
      } catch (Exception error) {
        new BulkRecordUploadLogService()
          .warn(
            uploadId,
            BulkRecordUploadRuntimeContract.REASON_EXTENSION_ERROR,
            'A post-processing extension did not complete.'
          );
      }
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

  private static List<Integer> rowNumbers(List<BulkRecordUploadRow> rows) {
    List<Integer> numbers = new List<Integer>();
    for (BulkRecordUploadRow row : rows) {
      if (row == null) {
        throw new BulkRecordUploadException(
          'The staged row collection is invalid.'
        );
      }
      numbers.add(row.rowNumber);
    }
    return numbers;
  }

  private static void validateExtensionRows(
    List<BulkRecordUploadRow> rows,
    List<Integer> expectedRowNumbers
  ) {
    if (
      rows == null ||
      rows.size() != expectedRowNumbers.size() ||
      rows.size() > BulkRecordUploadRuntimeContract.MAX_CHUNK_ROWS
    ) {
      throw new BulkRecordUploadException(
        'A row extension did not preserve the bounded row collection.'
      );
    }
    for (Integer index = 0; index < rows.size(); index++) {
      if (
        rows[index] == null ||
        rows[index].rowNumber != expectedRowNumbers[index]
      ) {
        throw new BulkRecordUploadException(
          'A row extension did not preserve physical row correlation.'
        );
      }
    }
  }

  private static String safeFailureMessage(Exception error) {
    return error instanceof BulkRecordUploadException
      ? error.getMessage().left(255)
      : 'Processing failed unexpectedly. Review the process configuration and retry.';
  }

  private static String reasonCode(Exception error) {
    return error instanceof ConfigurationChangedException
      ? BulkRecordUploadRuntimeContract.REASON_CONFIGURATION_CHANGED
      : BulkRecordUploadRuntimeContract.REASON_PROCESSING_ERROR;
  }

  private static void verifyConfiguration(
    Bulk_Record_Upload__c upload,
    BulkRecordUploadProjection projection
  ) {
    if (
      String.isBlank(upload.ConfigHash__c) ||
      upload.ConfigHash__c != projection.configHash ||
      upload.ProcessDeveloperName__c != projection.processKey
    ) {
      throw new ConfigurationChangedException(
        'The upload process configuration changed after submission. Submit a new upload.'
      );
    }
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
    if (checksum(chunk.StagedRowData__c) != chunk.IntegrityChecksum__c) {
      throw new BulkRecordUploadException(
        'The staged chunk checksum is invalid.'
      );
    }
  }

  private static String checksum(String payload) {
    return EncodingUtil.convertToHex(
      Crypto.generateDigest(
        'SHA-256',
        Blob.valueOf(payload == null ? '' : payload)
      )
    );
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
    Schema.SObjectField fieldToken = Schema.getGlobalDescribe()
      .get(projection.objectApiName)
      .getDescribe()
      .fields.getMap()
      .get(upsertFieldName);
    if (fieldToken == null || !fieldToken.getDescribe().isExternalId()) {
      throw new BulkRecordUploadException(
        'The configured upsert key is not an External ID.'
      );
    }
    return fieldToken;
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

  private class ConfigurationChangedException extends Exception {
  }
}
