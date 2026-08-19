/** Aura-serializable version 1 upload submission contract. */
public class BulkRecordUploadSubmitRequestV1 {
  @AuraEnabled
  public String processKey { get; set; }
  @AuraEnabled
  public String fileName { get; set; }
  @AuraEnabled
  public String contentBase64 { get; set; }
  @AuraEnabled
  public String idempotencyKey { get; set; }
  @AuraEnabled
  public String contextRecordId { get; set; }
}
