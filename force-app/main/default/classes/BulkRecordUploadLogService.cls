/** Owns idempotent upload creation and forward-only lifecycle transitions. */
public with sharing class BulkRecordUploadLogService {
  private static final Map<String, Set<String>> TRANSITIONS = BulkRecordUploadRuntimeContract.uploadTransitions();

  /** Returns at most 50 non-archived uploads visible to the running user. */
  public List<BulkRecordUploadHistoryItemV1> getHistory() {
    new BulkRecordUploadAccessPolicy().requireRunPermission();
    Integer historyLimit = BulkRecordUploadRuntimeContract.MAX_HISTORY_ROWS;
    return toHistoryItems(
      [
        SELECT
          Id,
          ProcessDeveloperName__c,
          Status__c,
          RowCount__c,
          SubmittedAt__c,
          ResultFileId__c,
          LastErrorCode__c,
          LastErrorMessage__c
        FROM Bulk_Record_Upload__c
        WHERE IsArchived__c = FALSE
        WITH USER_MODE
        ORDER BY SubmittedAt__c DESC
        LIMIT :historyLimit
      ]
    );
  }

  /** Returns at most 50 visible non-archived uploads for one validated process. */
  public List<BulkRecordUploadHistoryItemV1> getHistory(String processKey) {
    new BulkRecordUploadAccessPolicy().requireRunPermission();
    if (String.isBlank(processKey)) {
      throw new BulkRecordUploadException('The upload process is invalid.');
    }
    Integer historyLimit = BulkRecordUploadRuntimeContract.MAX_HISTORY_ROWS;
    return toHistoryItems(
      [
        SELECT
          Id,
          ProcessDeveloperName__c,
          Status__c,
          RowCount__c,
          SubmittedAt__c,
          ResultFileId__c,
          LastErrorCode__c,
          LastErrorMessage__c
        FROM Bulk_Record_Upload__c
        WHERE IsArchived__c = FALSE AND ProcessDeveloperName__c = :processKey
        WITH USER_MODE
        ORDER BY SubmittedAt__c DESC
        LIMIT :historyLimit
      ]
    );
  }

  private static List<BulkRecordUploadHistoryItemV1> toHistoryItems(
    List<Bulk_Record_Upload__c> uploads
  ) {
    List<BulkRecordUploadHistoryItemV1> items = new List<BulkRecordUploadHistoryItemV1>();
    for (Bulk_Record_Upload__c upload : uploads) {
      items.add(new BulkRecordUploadHistoryItemV1(upload));
    }
    return items;
  }

  /** Creates an upload once for the current user and idempotency key. */
  public Bulk_Record_Upload__c createOrFind(
    String processKey,
    String idempotencyKey,
    Integer rowCount,
    Integer retentionDays
  ) {
    return createOrFindWithState(
        processKey,
        idempotencyKey,
        rowCount,
        retentionDays
      )
      .upload;
  }

  /** Creates or finds an upload and reports whether this transaction created it. */
  public Creation createOrFindWithState(
    String processKey,
    String idempotencyKey,
    Integer rowCount,
    Integer retentionDays
  ) {
    return createOrFindWithState(
      processKey,
      idempotencyKey,
      rowCount,
      retentionDays,
      null
    );
  }

  /** Creates or finds an upload and stores an optional verified record context. */
  public Creation createOrFindWithState(
    String processKey,
    String idempotencyKey,
    Integer rowCount,
    Integer retentionDays,
    Id contextRecordId
  ) {
    if (
      String.isBlank(processKey) ||
      String.isBlank(idempotencyKey) ||
      rowCount == null ||
      rowCount < 1
    ) {
      throw new BulkRecordUploadException('Upload log input is invalid.');
    }
    Datetime cutoff = System.now().addHours(-24);
    List<Bulk_Record_Upload__c> existing = [
      SELECT
        Id,
        Status__c,
        ProcessDeveloperName__c,
        RowCount__c,
        RetentionDays__c
      FROM Bulk_Record_Upload__c
      WHERE
        IdempotencyKey__c = :idempotencyKey
        AND ProcessDeveloperName__c = :processKey
        AND CreatedById = :UserInfo.getUserId()
        AND CreatedDate >= :cutoff
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    if (!existing.isEmpty()) {
      return new Creation(existing[0], false);
    }
    Bulk_Record_Upload__c upload = new Bulk_Record_Upload__c(
      ProcessDeveloperName__c = processKey.trim(),
      IdempotencyKey__c = idempotencyKey.trim(),
      Status__c = BulkRecordUploadRuntimeContract.STATUS_QUEUED,
      SubmittedAt__c = System.now(),
      RowCount__c = rowCount,
      RetentionDays__c = retentionDays,
      ContextRecordId__c = contextRecordId,
      SuccessCount__c = 0,
      FailureCount__c = 0,
      IsArchived__c = false
    );
    insert as system upload;
    return new Creation(upload, true);
  }

  /** Advances one upload to an allowed status and records bounded terminal counts. */
  public void transition(
    Id uploadId,
    String nextStatus,
    Integer successes,
    Integer failures
  ) {
    Bulk_Record_Upload__c upload = [
      SELECT Id, Status__c, ProcessingStartedAt__c
      FROM Bulk_Record_Upload__c
      WHERE Id = :uploadId
      WITH SYSTEM_MODE
      FOR UPDATE
    ];
    String canonical = nextStatus == null ? '' : nextStatus.toUpperCase();
    if (
      !TRANSITIONS.containsKey(upload.Status__c) ||
      !TRANSITIONS.get(upload.Status__c).contains(canonical)
    ) {
      throw new BulkRecordUploadException(
        'The requested upload status transition is invalid.'
      );
    }
    upload.Status__c = canonical;
    if (
      canonical == BulkRecordUploadRuntimeContract.STATUS_PROCESSING &&
      upload.ProcessingStartedAt__c == null
    ) {
      upload.ProcessingStartedAt__c = System.now();
    }
    if (isTerminal(canonical)) {
      upload.CompletedAt__c = System.now();
      upload.SuccessCount__c = Math.max(0, successes == null ? 0 : successes);
      upload.FailureCount__c = Math.max(0, failures == null ? 0 : failures);
    }
    update as system upload;
  }

  /** Records an idempotent, safe fatal diagnostic without exposing CSV data. */
  public void fail(Id uploadId, String errorCode, String safeMessage) {
    Bulk_Record_Upload__c upload = [
      SELECT Id, Status__c, RowCount__c
      FROM Bulk_Record_Upload__c
      WHERE Id = :uploadId
      WITH SYSTEM_MODE
      FOR UPDATE
    ];
    if (isTerminal(upload.Status__c)) {
      return;
    }
    upload.Status__c = BulkRecordUploadRuntimeContract.STATUS_FAILED;
    upload.CompletedAt__c = System.now();
    String completedChunkStatus = BulkRecordUploadRuntimeContract.CHUNK_COMPLETED;
    AggregateResult completed = [
      SELECT SUM(SuccessCount__c) successes, SUM(FailureCount__c) failures
      FROM Bulk_Record_Upload_Chunk__c
      WHERE ParentUpload__c = :uploadId AND Status__c = :completedChunkStatus
      WITH SYSTEM_MODE
    ];
    Integer committedSuccesses = decimalToInteger(completed.get('successes'));
    Integer completedFailures = decimalToInteger(completed.get('failures'));
    upload.SuccessCount__c = committedSuccesses;
    upload.FailureCount__c = Math.max(
      completedFailures + 1,
      (upload.RowCount__c ?? 0).intValue() - committedSuccesses
    );
    upload.LastErrorCode__c = String.isBlank(errorCode)
      ? BulkRecordUploadRuntimeContract.REASON_PROCESSING_ERROR
      : errorCode.left(
          BulkRecordUploadRuntimeContract.MAX_ERROR_CODE_CHARACTERS
        );
    upload.LastErrorMessage__c = String.isBlank(safeMessage)
      ? 'Processing failed. Review the process configuration and retry.'
      : safeMessage.left(
          BulkRecordUploadRuntimeContract.MAX_ERROR_MESSAGE_CHARACTERS
        );
    update as system upload;
  }

  private static Integer decimalToInteger(Object value) {
    return value == null ? 0 : ((Decimal) value).intValue();
  }

  private static Boolean isTerminal(String status) {
    return BulkRecordUploadRuntimeContract.isTerminalUploadStatus(status);
  }

  /** Immutable idempotent creation outcome. */
  public class Creation {
    public Bulk_Record_Upload__c upload { get; private set; }
    public Boolean wasCreated { get; private set; }

    private Creation(Bulk_Record_Upload__c upload, Boolean wasCreated) {
      this.upload = upload;
      this.wasCreated = wasCreated;
    }
  }
}
