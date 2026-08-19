/** Resolved administrator selection for one upload component instance. */
public with sharing class BulkRecordUploadSelectionV1 {
  @AuraEnabled
  public String selectionType { get; private set; }
  @AuraEnabled
  public String selectionLabel { get; private set; }
  @AuraEnabled
  public List<BulkRecordUploadProcessOptionV1> processes { get; private set; }

  /** Creates an immutable selection response. */
  public BulkRecordUploadSelectionV1(
    String selectionType,
    String selectionLabel,
    List<BulkRecordUploadProcessOptionV1> processes
  ) {
    this.selectionType = selectionType;
    this.selectionLabel = selectionLabel;
    this.processes = processes == null
      ? new List<BulkRecordUploadProcessOptionV1>()
      : processes;
  }
}
