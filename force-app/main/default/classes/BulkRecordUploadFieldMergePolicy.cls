/** Applies version 2 blank, existing-value, separator, duplicate, and overflow decisions. */
public with sharing class BulkRecordUploadFieldMergePolicy {
  /** Returns the safely merged value for one Schema-resolved field. */
  public Object applyPolicy(
    BulkRecordUploadFieldProjectionV1 field,
    Object existingValue,
    Object incomingValue,
    Integer maximumLength
  ) {
    if (
      incomingValue == null ||
      (incomingValue instanceof String &&
      String.isBlank((String) incomingValue))
    ) {
      if (field.blankValueAction == 'IGNORE') {
        return existingValue;
      }
      if (field.blankValueAction == 'CLEAR') {
        return null;
      }
      throw new BulkRecordUploadException(
        'A required configured value is blank.'
      );
    }
    if (field.existingValueAction == 'REPLACE' || existingValue == null) {
      return incomingValue;
    }
    if (field.existingValueAction == 'KEEP_EXISTING') {
      return existingValue;
    }
    if (!isTextType(field.fieldType)) {
      throw new BulkRecordUploadException(
        'Append and Prepend require a text-like field.'
      );
    }
    String existingText = String.valueOf(existingValue);
    String incomingText = String.valueOf(incomingValue);
    String separator = separator(field.textSeparator);
    if (isDuplicate(existingText, incomingText, separator)) {
      if (field.duplicateTextAction == 'SKIP') {
        return existingValue;
      }
      if (field.duplicateTextAction == 'REJECT') {
        throw new BulkRecordUploadException(
          'The incoming text is already present.'
        );
      }
    }
    String merged = field.existingValueAction == 'APPEND'
      ? existingText + separator + incomingText
      : incomingText + separator + existingText;
    if (
      maximumLength != null &&
      maximumLength > 0 &&
      merged.length() > maximumLength
    ) {
      throw new BulkRecordUploadException(
        'The merged text exceeds the Salesforce field length.'
      );
    }
    return merged;
  }

  private static Boolean isTextType(String fieldType) {
    return new Set<String>{
        'STRING',
        'TEXTAREA',
        'EMAIL',
        'PHONE',
        'URL',
        'PICKLIST',
        'MULTIPICKLIST'
      }
      .contains(fieldType);
  }

  private static String separator(String key) {
    if (key == 'NEW_LINE') {
      return '\n';
    }
    if (key == 'COMMA_SPACE') {
      return ', ';
    }
    if (key == 'SEMICOLON_SPACE') {
      return '; ';
    }
    if (key == 'NONE') {
      return '';
    }
    return ' ';
  }

  private static Boolean isDuplicate(
    String existingText,
    String incomingText,
    String separatorValue
  ) {
    return existingText == incomingText ||
      existingText.startsWith(incomingText + separatorValue) ||
      existingText.endsWith(separatorValue + incomingText);
  }
}
