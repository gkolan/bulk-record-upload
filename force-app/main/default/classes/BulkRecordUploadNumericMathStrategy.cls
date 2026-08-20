/** Adds or subtracts a number, currency, or percent value, preserving the field's numeric type. */
public class BulkRecordUploadNumericMathStrategy implements BulkRecordUploadFieldMergeStrategy {
  private static final Set<String> NUMERIC_TYPES = new Set<String>{
    'INTEGER',
    'LONG',
    'DOUBLE',
    'CURRENCY',
    'PERCENT'
  };

  private final Boolean isAdd;

  /** @param isAdd True for Add, false for Subtract. */
  public BulkRecordUploadNumericMathStrategy(Boolean isAdd) {
    this.isAdd = isAdd;
  }

  /** {@inheritDoc} */
  public Boolean supportsType(String fieldType) {
    return NUMERIC_TYPES.contains(fieldType);
  }

  /** {@inheritDoc} */
  public Object combine(
    BulkRecordUploadFieldProjection field,
    Object existingValue,
    Object incomingValue,
    Integer maximumLength
  ) {
    Decimal existingDecimal = Decimal.valueOf(String.valueOf(existingValue));
    Decimal incomingDecimal = Decimal.valueOf(String.valueOf(incomingValue));
    Decimal result = isAdd
      ? existingDecimal + incomingDecimal
      : existingDecimal - incomingDecimal;
    if (field.fieldType == 'INTEGER') {
      return result.intValue();
    }
    if (field.fieldType == 'LONG') {
      return result.longValue();
    }
    return result;
  }
}
