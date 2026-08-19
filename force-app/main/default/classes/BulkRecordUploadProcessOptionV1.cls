/** Safe process choice returned to the upload selector. */
public with sharing class BulkRecordUploadProcessOptionV1 {
  @AuraEnabled
  public String label { get; private set; }
  @AuraEnabled
  public String value { get; private set; }

  /** Creates one process choice. */
  public BulkRecordUploadProcessOptionV1(String label, String value) {
    this.label = String.isBlank(label) ? value : label.trim();
    this.value = value?.trim();
  }
}
