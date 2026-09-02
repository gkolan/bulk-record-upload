/** Aura-serializable upload submission contract. */
public class BulkRecordUploadSubmitRequest {
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
  @AuraEnabled
  public String bundleDeveloperName { get; set; }
}
