/**
 * Shipped example custom merge strategy that keeps whichever of the
 * existing or incoming text value is longer, ignoring separator, duplicate,
 * and overflow configuration. Register by class name as Existing Value
 * Action Custom; see docs/developer/custom-handler.md for the worked
 * example.
 */
public class BulkRecordUploadLongerTextStrategy implements BulkRecordUploadFieldMergeStrategy {
  private static final Set<String> TEXT_TYPES = new Set<String>{
    'STRING',
    'TEXTAREA',
    'EMAIL',
    'PHONE',
    'URL',
    'PICKLIST'
  };

  /** {@inheritDoc} */
  public Boolean supportsType(String fieldType) {
    return TEXT_TYPES.contains(fieldType);
  }

  /** {@inheritDoc} */
  public Object combine(
    BulkRecordUploadFieldProjection field,
    Object existingValue,
    Object incomingValue,
    Integer maximumLength
  ) {
    String existingText = String.valueOf(existingValue);
    String incomingText = String.valueOf(incomingValue);
    return incomingText.length() > existingText.length()
      ? incomingText
      : existingText;
  }
}
