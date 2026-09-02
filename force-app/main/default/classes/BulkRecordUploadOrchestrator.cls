/** Starts edition-independent one-chunk-per-transaction processing for a staged upload. */
public with sharing class BulkRecordUploadOrchestrator {
  /** Starts one Batch Apex job with a scope of one durable chunk. */
  public Id start(Id uploadId) {
    List<Bulk_Record_Upload_Chunk__c> chunks = [
      SELECT ProcessingOrder__c
      FROM Bulk_Record_Upload_Chunk__c
      WHERE ParentUpload__c = :uploadId AND Status__c = 'READY'
      WITH SYSTEM_MODE
      ORDER BY ProcessingOrder__c
      LIMIT 1
    ];
    if (chunks.isEmpty()) {
      throw new BulkRecordUploadException('No staged chunk is ready.');
    }
    return Database.executeBatch(new BulkRecordUploadJob(uploadId, null), 1);
  }
}
