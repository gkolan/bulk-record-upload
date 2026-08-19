/** Converts bounded CSV text into supported Salesforce scalar values. */
public with sharing class BulkRecordUploadValueCoercer {
  /** Coerces one value using a Schema-resolved display type name. */
  public Object coerce(String rawValue, String fieldType) {
    if (rawValue == null) {
      return null;
    }
    String typeName = fieldType == null ? '' : fieldType.toUpperCase();
    try {
      if (isText(typeName)) {
        return rawValue;
      }
      if (typeName == 'BOOLEAN') {
        return coerceBoolean(rawValue);
      }
      if (typeName == 'INTEGER') {
        return Integer.valueOf(rawValue);
      }
      if (typeName == 'LONG') {
        return Long.valueOf(rawValue);
      }
      if (isDecimal(typeName)) {
        return Decimal.valueOf(rawValue);
      }
      if (typeName == 'DATE') {
        return Date.valueOf(rawValue);
      }
      if (typeName == 'DATETIME') {
        return Datetime.valueOfGmt(rawValue.replace('T', ' ').replace('Z', ''));
      }
    } catch (Exception error) {
      throw new BulkRecordUploadException(
        'A field value has an invalid format.'
      );
    }
    throw new BulkRecordUploadException(
      'The configured field type is not supported.'
    );
  }

  private static Boolean isText(String typeName) {
    return new Set<String>{
        'STRING',
        'TEXTAREA',
        'EMAIL',
        'PHONE',
        'URL',
        'ID',
        'PICKLIST',
        'MULTIPICKLIST'
      }
      .contains(typeName);
  }

  private static Boolean isDecimal(String typeName) {
    return new Set<String>{ 'DOUBLE', 'CURRENCY', 'PERCENT' }
      .contains(typeName);
  }

  private static Boolean coerceBoolean(String rawValue) {
    String canonical = rawValue.trim().toLowerCase();
    if (canonical == 'true' || canonical == '1' || canonical == 'yes') {
      return true;
    }
    if (canonical == 'false' || canonical == '0' || canonical == 'no') {
      return false;
    }
    throw new BulkRecordUploadException('A field value has an invalid format.');
  }
}
