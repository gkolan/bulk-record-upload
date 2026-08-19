/** One validated field/operator/value eligibility condition for record context. */
public class BulkRecordUploadContextFilterConditionV1 {
  public String fieldApiName { get; private set; }
  public String operatorCode { get; private set; }
  public List<String> values { get; private set; }

  /** Creates an immutable, already-validated filter condition. */
  public BulkRecordUploadContextFilterConditionV1(
    String fieldApiName,
    String operatorCode,
    List<String> values
  ) {
    this.fieldApiName = fieldApiName;
    this.operatorCode = operatorCode;
    this.values = new List<String>(values);
  }
}
