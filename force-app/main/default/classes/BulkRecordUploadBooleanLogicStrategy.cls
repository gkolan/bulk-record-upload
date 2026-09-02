/** Combines two checkbox values with OR (True If Either) or AND (True If Both). */
public class BulkRecordUploadBooleanLogicStrategy implements BulkRecordUploadFieldMergeStrategy {
  private final Boolean isEither;

  /** @param isEither True for True If Either, false for True If Both. */
  public BulkRecordUploadBooleanLogicStrategy(Boolean isEither) {
    this.isEither = isEither;
  }

  /** {@inheritDoc} */
  public Boolean supportsType(String fieldType) {
    return fieldType == 'BOOLEAN';
  }

  /** {@inheritDoc} */
  public Object combine(
    BulkRecordUploadFieldProjection field,
    Object existingValue,
    Object incomingValue,
    Integer maximumLength
  ) {
    Boolean existingBoolean = (Boolean) existingValue;
    Boolean incomingBoolean = (Boolean) incomingValue;
    return isEither
      ? existingBoolean || incomingBoolean
      : existingBoolean && incomingBoolean;
  }
}
