/** Joins ordered safe result fragments, creates the final File, and removes staging. */
public with sharing class BulkRecordUploadFinalizer {
  /** Finalizes an upload after every staged chunk reaches COMPLETED. */
  public void finalizeUpload(Id uploadId) {
    List<Bulk_Record_Upload_Chunk__c> chunks = [
      SELECT
        Id,
        ProcessingOrder__c,
        Status__c,
        StagedRowData__c,
        SuccessCount__c,
        FailureCount__c
      FROM Bulk_Record_Upload_Chunk__c
      WHERE ParentUpload__c = :uploadId
      WITH SYSTEM_MODE
      ORDER BY ProcessingOrder__c
    ];
    Integer successes = 0;
    Integer failures = 0;
    List<String> fragments = new List<String>();
    for (Bulk_Record_Upload_Chunk__c chunk : chunks) {
      if (chunk.Status__c != 'COMPLETED') {
        throw new BulkRecordUploadException(
          'Upload chunks are not ready for finalization.'
        );
      }
      String payload = chunk.StagedRowData__c == null
        ? ''
        : chunk.StagedRowData__c;
      successes += Integer.valueOf(chunk.SuccessCount__c ?? 0);
      failures += Integer.valueOf(chunk.FailureCount__c ?? 0);
      Integer firstBreak = payload.indexOf('\r\n');
      if (fragments.isEmpty()) {
        fragments.add(
          firstBreak < 0
            ? BulkRecordUploadResultWriter.HEADER
            : payload.substring(0, firstBreak)
        );
      }
      String body = firstBreak < 0
        ? ''
        : payload.substring(firstBreak + 2).trim();
      if (!String.isBlank(body)) {
        fragments.add(body);
      }
    }
    new BulkRecordUploadFileService()
      .createResultFile(
        uploadId,
        Blob.valueOf(String.join(fragments, '\r\n') + '\r\n')
      );
    String terminal = failures == 0 ? 'COMPLETED' : 'COMPLETED_WITH_ERRORS';
    new BulkRecordUploadLogService()
      .transition(uploadId, terminal, successes, failures);
    delete as system chunks;
  }
}
