/** Converts bounded CSV text into supported Salesforce scalar values. */
public with sharing class BulkRecordUploadValueCoercer {
  /** Coerces one value using a Schema-resolved display type name. */
  public Object coerce(String rawValue, String fieldType) {
    if (rawValue == null) {
      return null;
    }
    String typeName = fieldType == null ? '' : fieldType.toUpperCase();
    try {
      if (typeName == 'MULTIPICKLIST') {
        return normalizeMultiPicklist(rawValue);
      }
      if (isText(typeName)) {
        return rawValue;
      }
      if (typeName == 'BOOLEAN') {
        return coerceBoolean(rawValue);
      }
      if (typeName == 'INTEGER') {
        return Integer.valueOf(normalizeNumber(rawValue, typeName));
      }
      if (typeName == 'LONG') {
        return Long.valueOf(normalizeNumber(rawValue, typeName));
      }
      if (isDecimal(typeName)) {
        return Decimal.valueOf(normalizeNumber(rawValue, typeName));
      }
      if (typeName == 'DATE') {
        return Date.valueOf(rawValue.trim());
      }
      if (typeName == 'DATETIME') {
        return parseDatetime(rawValue);
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

  private static String normalizeMultiPicklist(String rawValue) {
    String delimiter = rawValue.contains(';')
      ? ';'
      : rawValue.contains('|') ? '\\|' : ',';
    List<String> normalized = new List<String>();
    for (String token : rawValue.split(delimiter)) {
      if (String.isNotBlank(token)) {
        normalized.add(token.trim());
      }
    }
    return String.join(normalized, ';');
  }

  private static String normalizeNumber(String rawValue, String typeName) {
    String value = rawValue.trim();
    Boolean isNegative = value.startsWith('(') && value.endsWith(')');
    if (isNegative) {
      value = value.substring(1, value.length() - 1).trim();
    }
    if (value.startsWith('$')) {
      if (typeName != 'CURRENCY') {
        throw new BulkRecordUploadException(
          'A field value has an invalid format.'
        );
      }
      value = value.substring(1).trim();
    }
    if (value.endsWith('%')) {
      if (typeName != 'PERCENT') {
        throw new BulkRecordUploadException(
          'A field value has an invalid format.'
        );
      }
      value = value.left(value.length() - 1).trim();
    }
    if (
      value.contains(',') &&
      !Pattern.matches('^-?[0-9]{1,3}(,[0-9]{3})*(\\.[0-9]+)?$', value)
    ) {
      throw new BulkRecordUploadException(
        'A field value has an ambiguous numeric format.'
      );
    }
    value = value.replace(',', '');
    return isNegative ? '-' + value : value;
  }

  private static Datetime parseDatetime(String rawValue) {
    Matcher matcher = Pattern.compile(
        '^([0-9]{4}-[0-9]{2}-[0-9]{2})[T ]([0-9]{2}:[0-9]{2}:[0-9]{2})(?:\\.([0-9]{1,3}))?(Z|[+-][0-9]{2}:[0-9]{2})?$'
      )
      .matcher(rawValue.trim());
    if (!matcher.matches()) {
      throw new BulkRecordUploadException(
        'A field value has an invalid datetime format.'
      );
    }
    String fractionalSeconds = matcher.group(3);
    Datetime parsed = String.isBlank(fractionalSeconds)
      ? Datetime.valueOfGmt(matcher.group(1) + ' ' + matcher.group(2))
      : (Datetime) JSON.deserialize(
          '"' +
            matcher.group(1) +
            'T' +
            matcher.group(2) +
            '.' +
            fractionalSeconds.rightPad(3, '0') +
            'Z"',
          Datetime.class
        );
    String offset = matcher.group(4);
    if (String.isBlank(offset) || offset == 'Z') {
      return parsed;
    }
    Integer offsetMinutes =
      Integer.valueOf(offset.substring(1, 3)) * 60 +
      Integer.valueOf(offset.substring(4, 6));
    Integer direction = offset.startsWith('+') ? 1 : -1;
    return parsed.addMinutes(-direction * offsetMinutes);
  }
}
