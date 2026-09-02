/** Appends or prepends text-like values with the configured separator, duplicate, and overflow rules. */
public class BulkRecordUploadTextJoinStrategy implements BulkRecordUploadFieldMergeStrategy {
  /** Field types treated as text for Append/Prepend and for overflow truncation. */
  public static final Set<String> TEXT_TYPES = new Set<String>{
    'STRING',
    'TEXTAREA',
    'EMAIL',
    'PHONE',
    'URL',
    'PICKLIST',
    'MULTIPICKLIST'
  };

  private final Boolean isAppend;

  /** @param isAppend True for Append, false for Prepend. */
  public BulkRecordUploadTextJoinStrategy(Boolean isAppend) {
    this.isAppend = isAppend;
  }

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
    String separatorValue = separator(field);
    if (isDuplicate(existingText, incomingText, separatorValue)) {
      if (field.duplicateTextAction == 'SKIP') {
        return existingValue;
      }
      if (field.duplicateTextAction == 'REJECT') {
        throw new BulkRecordUploadException(
          'The incoming text is already present.'
        );
      }
    }
    String merged = isAppend
      ? existingText + separatorValue + incomingText
      : incomingText + separatorValue + existingText;
    return applyOverflow(merged, maximumLength, field);
  }

  /**
   * Applies the configured overflow rule to any text-like value, not only a
   * merged Append/Prepend result. BulkRecordUploadRecordMapper calls this
   * directly for Replace and Insert, since applyPolicy's Replace branch
   * returns the incoming value before any strategy runs.
   */
  public static String applyOverflow(
    String value,
    Integer maximumLength,
    BulkRecordUploadFieldProjection field
  ) {
    if (
      value == null ||
      maximumLength == null ||
      maximumLength <= 0 ||
      value.length() <= maximumLength
    ) {
      return value;
    }
    if (field.overflowAction == 'TRUNCATE') {
      return value.substring(0, maximumLength);
    }
    if (field.overflowAction == 'TRUNCATE_AT_WORD') {
      return truncateAtWord(value, maximumLength);
    }
    throw new BulkRecordUploadException(
      'The configured value exceeds the Salesforce field length for ' +
        field.displayLabel +
        '.'
    );
  }

  private static String truncateAtWord(String value, Integer maximumLength) {
    String truncated = value.substring(0, maximumLength);
    Integer lastSpace = truncated.lastIndexOf(' ');
    return lastSpace <= 0 ? truncated : truncated.substring(0, lastSpace);
  }

  private static String separator(BulkRecordUploadFieldProjection field) {
    if (field.textSeparator == 'CUSTOM') {
      return String.isBlank(field.customSeparator) ? '' : field.customSeparator;
    }
    if (field.textSeparator == 'NEW_LINE') {
      return '\n';
    }
    if (field.textSeparator == 'COMMA_SPACE') {
      return ', ';
    }
    if (field.textSeparator == 'SEMICOLON_SPACE') {
      return '; ';
    }
    if (field.textSeparator == 'NONE') {
      return '';
    }
    return ' ';
  }

  private static Boolean isDuplicate(
    String existingText,
    String incomingText,
    String separatorValue
  ) {
    if (existingText == incomingText) {
      return true;
    }
    if (String.isEmpty(separatorValue)) {
      return false;
    }
    Integer separatorLength = separatorValue.length();
    Integer searchStart = 0;
    Integer separatorIndex = existingText.indexOf(separatorValue, searchStart);
    while (separatorIndex != -1) {
      if (existingText.substring(searchStart, separatorIndex) == incomingText) {
        return true;
      }
      searchStart = separatorIndex + separatorLength;
      separatorIndex = existingText.indexOf(separatorValue, searchStart);
    }
    return existingText.substring(searchStart) == incomingText;
  }
}
