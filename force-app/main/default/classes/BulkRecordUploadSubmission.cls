/** Safe upload submission response. */
public class BulkRecordUploadSubmission {
  @AuraEnabled
  public Id uploadId { get; private set; }
  @AuraEnabled
  public String status { get; private set; }
  @AuraEnabled
  public Boolean isDuplicate { get; private set; }

  /** Creates a submission outcome. */
  public BulkRecordUploadSubmission(
    Id uploadId,
    String status,
    Boolean isDuplicate
  ) {
    this.uploadId = uploadId;
    this.status = status;
    this.isDuplicate = isDuplicate;
  }
}
