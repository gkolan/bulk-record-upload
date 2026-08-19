/** Applies one code-owned field behavior without record access or DML. */
public with sharing class BulkRecordUploadFieldBehavior implements BulkRecordUploadFieldBehaviorV1 {
  private final String behavior;

  /** Creates an implementation for a registry-approved behavior key. */
  public BulkRecordUploadFieldBehavior(String behavior) {
    this.behavior = behavior;
  }

  /** {@inheritDoc} */
  public Object apply(Object existingValue, Object incomingValue) {
    if (behavior == 'REPLACE') {
      return incomingValue;
    }
    String existingText = existingValue == null
      ? ''
      : String.valueOf(existingValue);
    String incomingText = incomingValue == null
      ? ''
      : String.valueOf(incomingValue);
    if (behavior == 'APPEND') {
      if (String.isBlank(incomingText)) {
        return existingValue;
      }
      return String.isBlank(existingText)
        ? incomingText
        : existingText + ' ' + incomingText;
    }
    if (behavior == 'PREPEND') {
      if (String.isBlank(incomingText)) {
        return existingValue;
      }
      return String.isBlank(existingText)
        ? incomingText
        : incomingText + ' ' + existingText;
    }
    if (behavior == 'CLEAR_WHEN_BLANK') {
      return String.isBlank(incomingText) ? null : incomingValue;
    }
    throw new BulkRecordUploadException(
      'The configured field behavior is not registered.'
    );
  }
}
