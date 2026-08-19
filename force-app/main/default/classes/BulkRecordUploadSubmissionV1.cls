/** Safe version 1 upload submission response. */
public class BulkRecordUploadSubmissionV1 {
  @AuraEnabled
  public Id uploadId { get; private set; }
  @AuraEnabled
  public String status { get; private set; }
  @AuraEnabled
  public Boolean isDuplicate { get; private set; }

  /** Creates a submission outcome. */
  public BulkRecordUploadSubmissionV1(
    Id uploadId,
    String status,
    Boolean isDuplicate
  ) {
    this.uploadId = uploadId;
    this.status = status;
    this.isDuplicate = isDuplicate;
  }
}
