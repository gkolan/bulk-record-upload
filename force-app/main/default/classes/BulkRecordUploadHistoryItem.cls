/** Safe upload-history item for the current user's visible records. */
public class BulkRecordUploadHistoryItem {
  @AuraEnabled
  public Id uploadId { get; private set; }
  @AuraEnabled
  public String processKey { get; private set; }
  @AuraEnabled
  public String status { get; private set; }
  @AuraEnabled
  public Integer rowCount { get; private set; }
  @AuraEnabled
  public Datetime submittedAt { get; private set; }
  @AuraEnabled
  public String resultFileId { get; private set; }
  @AuraEnabled
  public String errorCode { get; private set; }
  @AuraEnabled
  public String errorMessage { get; private set; }

  /** Creates one redacted history DTO. */
  public BulkRecordUploadHistoryItem(Bulk_Record_Upload__c upload) {
    uploadId = upload.Id;
    processKey = upload.ProcessDeveloperName__c;
    status = upload.Status__c;
    rowCount = upload.RowCount__c == null ? 0 : upload.RowCount__c.intValue();
    submittedAt = upload.SubmittedAt__c;
    resultFileId = upload.ResultFileId__c;
    errorCode = upload.LastErrorCode__c;
    errorMessage = upload.LastErrorMessage__c;
  }
}
