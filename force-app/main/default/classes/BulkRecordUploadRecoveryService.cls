/** Recovers abandoned nonterminal uploads so concurrency claims cannot strand. */
public with sharing class BulkRecordUploadRecoveryService {
  /** Fails stale active uploads and promotes any already-completed chunk results. */
  public Integer recover() {
    Datetime cutoff = System.now()
      .addHours(-BulkRecordUploadRuntimeContract.MAX_ACTIVE_UPLOAD_HOURS);
    Integer recoveryLimit = BulkRecordUploadRuntimeContract.MAX_CONCURRENT_UPLOADS;
    List<Bulk_Record_Upload__c> abandoned = [
      SELECT Id
      FROM Bulk_Record_Upload__c
      WHERE
        ActiveOrgSlot__c != NULL
        AND Status__c IN ('QUEUED', 'VALIDATING', 'PROCESSING')
        AND ((ProcessingStartedAt__c = NULL
        AND SubmittedAt__c <= :cutoff)
        OR ProcessingStartedAt__c <= :cutoff)
      WITH SYSTEM_MODE
      ORDER BY SubmittedAt__c
      LIMIT :recoveryLimit
    ];
    Integer recovered = 0;
    for (Bulk_Record_Upload__c upload : abandoned) {
      try {
        new BulkRecordUploadLogService()
          .fail(
            upload.Id,
            BulkRecordUploadRuntimeContract.REASON_ABANDONED_UPLOAD,
            'Processing did not finish within the supported active window.'
          );
        recovered++;
        try {
          new BulkRecordUploadFinalizer().finalizePartialResults(upload.Id);
          // Result promotion is best-effort after the durable Failed state.
          // code-analyzer-suppress-next-line EmptyCatchBlock
        } catch (Exception partialResultError) {
          // Completed chunks remain available for a later support or cleanup pass.
        }
        // A later scheduled run safely retries a lock or temporary save failure.
        // code-analyzer-suppress-next-line EmptyCatchBlock
      } catch (Exception recoveryError) {
        // A lock or transient DML failure is retried by the next scheduled run.
      }
    }
    return recovered;
  }
}
