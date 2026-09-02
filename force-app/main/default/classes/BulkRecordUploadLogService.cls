/** Owns idempotent upload creation and forward-only lifecycle transitions. */
public with sharing class BulkRecordUploadLogService {
  private static final Map<String, Set<String>> TRANSITIONS = BulkRecordUploadRuntimeContract.uploadTransitions();

  /** Returns at most 50 non-archived uploads visible to the running user. */
  public List<BulkRecordUploadHistoryItem> getHistory() {
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
  public List<BulkRecordUploadHistoryItem> getHistory(String processKey) {
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

  /** Returns one current, access-filtered upload status for reliable polling. */
  public BulkRecordUploadHistoryItem getStatus(Id uploadId) {
    new BulkRecordUploadAccessPolicy().requireRunPermission();
    if (uploadId == null) {
      throw new BulkRecordUploadException('The upload identity is invalid.');
    }
    List<Bulk_Record_Upload__c> uploads = [
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
      WHERE Id = :uploadId
      WITH USER_MODE
      LIMIT 1
    ];
    if (uploads.isEmpty()) {
      throw new BulkRecordUploadException('The upload is unavailable.');
    }
    return new BulkRecordUploadHistoryItem(uploads[0]);
  }

  private static List<BulkRecordUploadHistoryItem> toHistoryItems(
    List<Bulk_Record_Upload__c> uploads
  ) {
    List<BulkRecordUploadHistoryItem> items = new List<BulkRecordUploadHistoryItem>();
    for (Bulk_Record_Upload__c upload : uploads) {
      items.add(new BulkRecordUploadHistoryItem(upload));
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
      null,
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
    return createOrFindWithState(
      processKey,
      idempotencyKey,
      rowCount,
      retentionDays,
      contextRecordId,
      null
    );
  }

  /** Creates or finds an upload and pins the configuration accepted at submission. */
  public Creation createOrFindWithState(
    String processKey,
    String idempotencyKey,
    Integer rowCount,
    Integer retentionDays,
    Id contextRecordId,
    String configHash
  ) {
    if (
      String.isBlank(processKey) ||
      String.isBlank(idempotencyKey) ||
      rowCount == null ||
      rowCount < 1
    ) {
      throw new BulkRecordUploadException('Upload log input is invalid.');
    }
    String normalizedProcessKey = processKey.trim();
    String normalizedIdempotencyKey = idempotencyKey.trim();
    Datetime cutoff = System.now().addHours(-24);
    List<Bulk_Record_Upload__c> existing = findIdempotent(
      normalizedProcessKey,
      normalizedIdempotencyKey,
      cutoff
    );
    if (!existing.isEmpty()) {
      requireNotFailed(existing[0]);
      return new Creation(existing[0], false);
    }
    Bulk_Record_Upload__c upload = new Bulk_Record_Upload__c(
      ProcessDeveloperName__c = normalizedProcessKey,
      IdempotencyKey__c = normalizedIdempotencyKey,
      ConfigHash__c = String.isBlank(configHash) ? null : configHash.trim(),
      ActiveUserProcessKey__c = digest(
        UserInfo.getUserId() + ':' + normalizedProcessKey
      ),
      Status__c = BulkRecordUploadRuntimeContract.STATUS_QUEUED,
      SubmittedAt__c = System.now(),
      RowCount__c = rowCount,
      RetentionDays__c = retentionDays,
      ContextRecordId__c = contextRecordId,
      SuccessCount__c = 0,
      FailureCount__c = 0,
      IsArchived__c = false
    );
    Set<String> unavailableSlots = activeOrgSlots();
    for (
      Integer slotNumber = 1;
      slotNumber <= BulkRecordUploadRuntimeContract.MAX_CONCURRENT_UPLOADS;
      slotNumber++
    ) {
      String slot = 'SLOT_' + slotNumber;
      if (unavailableSlots.contains(slot)) {
        continue;
      }
      upload.ActiveOrgSlot__c = slot;
      // The loop is capped at the fixed ten-slot org concurrency limit.
      // code-analyzer-suppress-next-line OperationWithLimitsInLoop
      Database.SaveResult insertion = Database.insert(
        upload,
        false,
        AccessLevel.SYSTEM_MODE
      );
      if (insertion.isSuccess()) {
        return new Creation(upload, true);
      }
      List<Bulk_Record_Upload__c> concurrentIdempotent = findIdempotent(
        normalizedProcessKey,
        normalizedIdempotencyKey,
        cutoff
      );
      if (!concurrentIdempotent.isEmpty()) {
        requireNotFailed(concurrentIdempotent[0]);
        return new Creation(concurrentIdempotent[0], false);
      }
      if (hasActiveUserProcess(normalizedProcessKey)) {
        throw new BulkRecordUploadException(
          'The concurrent upload limit has been reached.'
        );
      }
      if (!isDuplicateOnly(insertion.getErrors())) {
        throw new BulkRecordUploadException(
          'The upload log could not be created.'
        );
      }
      unavailableSlots.add(slot);
      upload.Id = null;
    }
    throw new BulkRecordUploadException(
      'The concurrent upload limit has been reached.'
    );
  }

  /**
   * A terminal FAILED upload committed no durable work, so its idempotency
   * key must not silently absorb a corrected resubmission. Callers must
   * retry with a new idempotency key instead of reusing a failed one.
   */
  private static void requireNotFailed(Bulk_Record_Upload__c upload) {
    if (upload.Status__c == BulkRecordUploadRuntimeContract.STATUS_FAILED) {
      throw new BulkRecordUploadException(
        'This upload previously failed. Submit again to start a new attempt.'
      );
    }
  }

  private static List<Bulk_Record_Upload__c> findIdempotent(
    String processKey,
    String idempotencyKey,
    Datetime cutoff
  ) {
    return [
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
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
  }

  private static Set<String> activeOrgSlots() {
    Set<String> slots = new Set<String>();
    Integer slotLimit = BulkRecordUploadRuntimeContract.MAX_CONCURRENT_UPLOADS;
    for (Bulk_Record_Upload__c upload : [
      SELECT ActiveOrgSlot__c
      FROM Bulk_Record_Upload__c
      WHERE ActiveOrgSlot__c != NULL
      WITH SYSTEM_MODE
      LIMIT :slotLimit
    ]) {
      slots.add(upload.ActiveOrgSlot__c);
    }
    return slots;
  }

  private static Boolean hasActiveUserProcess(String processKey) {
    return [
        SELECT COUNT()
        FROM Bulk_Record_Upload__c
        WHERE
          CreatedById = :UserInfo.getUserId()
          AND ProcessDeveloperName__c = :processKey
          AND ActiveUserProcessKey__c != NULL
        WITH SYSTEM_MODE
      ] > 0;
  }

  private static Boolean isDuplicateOnly(List<Database.Error> errors) {
    return !errors.isEmpty() &&
      errors[0].getStatusCode() == StatusCode.DUPLICATE_VALUE;
  }

  private static String digest(String value) {
    return EncodingUtil.convertToHex(
      Crypto.generateDigest('SHA-256', Blob.valueOf(value))
    );
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
      upload.ActiveUserProcessKey__c = null;
      upload.ActiveOrgSlot__c = null;
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
    upload.ActiveUserProcessKey__c = null;
    upload.ActiveOrgSlot__c = null;
    update as system upload;
  }

  /** Records a bounded non-fatal extension diagnostic without changing status. */
  public void warn(Id uploadId, String errorCode, String safeMessage) {
    if (uploadId == null) {
      return;
    }
    Bulk_Record_Upload__c warning = new Bulk_Record_Upload__c(
      Id = uploadId,
      LastErrorCode__c = String.isBlank(errorCode)
        ? BulkRecordUploadRuntimeContract.REASON_EXTENSION_ERROR
        : errorCode.left(
            BulkRecordUploadRuntimeContract.MAX_ERROR_CODE_CHARACTERS
          ),
      LastErrorMessage__c = String.isBlank(safeMessage)
        ? 'A post-processing extension did not complete.'
        : safeMessage.left(
            BulkRecordUploadRuntimeContract.MAX_ERROR_MESSAGE_CHARACTERS
          )
    );
    Database.update(warning, false, AccessLevel.SYSTEM_MODE);
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
