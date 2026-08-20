/** Adds or removes selections on a multi-select picklist, using set semantics. */
public class BulkRecordUploadMultiPicklistSetStrategy implements BulkRecordUploadFieldMergeStrategy {
  private final Boolean isAdd;

  /** @param isAdd True for Add Values, false for Remove Values. */
  public BulkRecordUploadMultiPicklistSetStrategy(Boolean isAdd) {
    this.isAdd = isAdd;
  }

  /** {@inheritDoc} */
  public Boolean supportsType(String fieldType) {
    return fieldType == 'MULTIPICKLIST';
  }

  /** {@inheritDoc} */
  public Object combine(
    BulkRecordUploadFieldProjection field,
    Object existingValue,
    Object incomingValue,
    Integer maximumLength
  ) {
    Set<String> existingValues = splitValues(String.valueOf(existingValue));
    Set<String> incomingValues = splitValues(String.valueOf(incomingValue));
    if (isAdd) {
      existingValues.addAll(incomingValues);
    } else {
      existingValues.removeAll(incomingValues);
    }
    List<String> sortedValues = new List<String>(existingValues);
    sortedValues.sort();
    return String.join(sortedValues, ';');
  }

  private static Set<String> splitValues(String value) {
    Set<String> values = new Set<String>();
    if (String.isBlank(value)) {
      return values;
    }
    for (String token : value.split(';')) {
      if (String.isNotBlank(token)) {
        values.add(token.trim());
      }
    }
    return values;
  }
}
