/** One validated field/operator/value eligibility condition for record context. */
public class BulkRecordUploadContextFilterCondition {
  public String fieldApiName { get; private set; }
  public String operatorCode { get; private set; }
  public List<String> values { get; private set; }
  public String fieldType { get; private set; }

  /** Creates an immutable, already-validated filter condition. */
  public BulkRecordUploadContextFilterCondition(
    String fieldApiName,
    String operatorCode,
    List<String> values
  ) {
    this(fieldApiName, operatorCode, values, 'STRING');
  }

  /** Creates a condition with its Schema-resolved primitive type. */
  public BulkRecordUploadContextFilterCondition(
    String fieldApiName,
    String operatorCode,
    List<String> values,
    String fieldType
  ) {
    this.fieldApiName = fieldApiName;
    this.operatorCode = operatorCode;
    this.values = new List<String>(values);
    this.fieldType = fieldType;
  }

  /** Returns the exact scalar or collection type required by SOQL. */
  public Object bindValue() {
    return operatorCode == 'IN'
      ? BulkRecordUploadContextValueCodec.collection(values, fieldType)
      : BulkRecordUploadContextValueCodec.scalar(values[0], fieldType);
  }

  /** Returns the GraphQL filter value shape expected by record picker. */
  public Object pickerValue() {
    return BulkRecordUploadContextValueCodec.pickerValue(
      values,
      fieldType,
      operatorCode == 'IN'
    );
  }
}
