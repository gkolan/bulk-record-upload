/** Resolved administrator selection for one upload component instance. */
public with sharing class BulkRecordUploadSelection {
  @AuraEnabled
  public String selectionType { get; private set; }
  @AuraEnabled
  public String selectionLabel { get; private set; }
  @AuraEnabled
  public List<BulkRecordUploadProcessOption> processes { get; private set; }

  /** Creates an immutable selection response. */
  public BulkRecordUploadSelection(
    String selectionType,
    String selectionLabel,
    List<BulkRecordUploadProcessOption> processes
  ) {
    this.selectionType = selectionType;
    this.selectionLabel = selectionLabel;
    this.processes = processes == null
      ? new List<BulkRecordUploadProcessOption>()
      : processes;
  }
}
