/** Validates and converts record-context filter literals for SOQL and LWC. */
public class BulkRecordUploadContextValueCodec {
  private static final Set<String> TEXT_TYPES = new Set<String>{
    'STRING',
    'TEXTAREA',
    'EMAIL',
    'PHONE',
    'URL',
    'PICKLIST',
    'COMBOBOX'
  };
  private static final Set<String> DECIMAL_TYPES = new Set<String>{
    'DOUBLE',
    'CURRENCY',
    'PERCENT'
  };

  /** Returns whether equality and IN binds are supported for this type. */
  public static Boolean supports(String fieldType) {
    String typeName = normalizeType(fieldType);
    return TEXT_TYPES.contains(typeName) ||
      DECIMAL_TYPES.contains(typeName) ||
      new Set<String>{
          'BOOLEAN',
          'INTEGER',
          'LONG',
          'DATE',
          'DATETIME',
          'TIME',
          'ID',
          'REFERENCE'
        }
        .contains(typeName);
  }

  /** Converts one validated literal to the exact primitive SOQL bind type. */
  public static Object scalar(String rawValue, String fieldType) {
    String typeName = normalizeType(fieldType);
    String value = rawValue == null ? null : rawValue.trim();
    if (String.isBlank(value) || !supports(typeName)) {
      throw invalidValue();
    }
    try {
      if (TEXT_TYPES.contains(typeName)) {
        return value;
      }
      if (typeName == 'BOOLEAN') {
        String canonical = value.toLowerCase();
        if (canonical == 'true') {
          return true;
        }
        if (canonical == 'false') {
          return false;
        }
        throw invalidValue();
      }
      if (typeName == 'INTEGER') {
        return Integer.valueOf(value);
      }
      if (typeName == 'LONG') {
        return Long.valueOf(value);
      }
      if (DECIMAL_TYPES.contains(typeName)) {
        return Decimal.valueOf(value);
      }
      if (typeName == 'DATE') {
        return Date.valueOf(value);
      }
      if (typeName == 'DATETIME') {
        return new BulkRecordUploadValueCoercer().coerce(value, typeName);
      }
      if (typeName == 'TIME') {
        return parseTime(value);
      }
      if (typeName == 'ID' || typeName == 'REFERENCE') {
        return Id.valueOf(value);
      }
    } catch (Exception error) {
      throw invalidValue();
    }
    throw invalidValue();
  }

  private static Time parseTime(String rawValue) {
    String value = rawValue.endsWith('Z')
      ? rawValue.left(rawValue.length() - 1)
      : rawValue;
    List<String> parts = value.split('[:.]');
    if (parts.size() < 3 || parts.size() > 4) {
      throw invalidValue();
    }
    return Time.newInstance(
      Integer.valueOf(parts[0]),
      Integer.valueOf(parts[1]),
      Integer.valueOf(parts[2]),
      parts.size() == 4 ? Integer.valueOf(parts[3]) : 0
    );
  }

  /** Builds a homogeneously typed collection suitable for an IN bind. */
  public static Object collection(List<String> rawValues, String fieldType) {
    String typeName = normalizeType(fieldType);
    if (rawValues == null || rawValues.isEmpty()) {
      throw invalidValue();
    }
    if (TEXT_TYPES.contains(typeName)) {
      Set<String> values = new Set<String>();
      for (String rawValue : rawValues) {
        values.add((String) scalar(rawValue, typeName));
      }
      return values;
    }
    if (typeName == 'BOOLEAN') {
      Set<Boolean> values = new Set<Boolean>();
      for (String rawValue : rawValues) {
        values.add((Boolean) scalar(rawValue, typeName));
      }
      return values;
    }
    if (typeName == 'INTEGER') {
      Set<Integer> values = new Set<Integer>();
      for (String rawValue : rawValues) {
        values.add((Integer) scalar(rawValue, typeName));
      }
      return values;
    }
    if (typeName == 'LONG') {
      Set<Long> values = new Set<Long>();
      for (String rawValue : rawValues) {
        values.add((Long) scalar(rawValue, typeName));
      }
      return values;
    }
    if (DECIMAL_TYPES.contains(typeName)) {
      Set<Decimal> values = new Set<Decimal>();
      for (String rawValue : rawValues) {
        values.add((Decimal) scalar(rawValue, typeName));
      }
      return values;
    }
    if (typeName == 'DATE') {
      Set<Date> values = new Set<Date>();
      for (String rawValue : rawValues) {
        values.add((Date) scalar(rawValue, typeName));
      }
      return values;
    }
    if (typeName == 'DATETIME') {
      Set<Datetime> values = new Set<Datetime>();
      for (String rawValue : rawValues) {
        values.add((Datetime) scalar(rawValue, typeName));
      }
      return values;
    }
    if (typeName == 'TIME') {
      Set<Time> values = new Set<Time>();
      for (String rawValue : rawValues) {
        values.add((Time) scalar(rawValue, typeName));
      }
      return values;
    }
    if (typeName == 'ID' || typeName == 'REFERENCE') {
      Set<Id> values = new Set<Id>();
      for (String rawValue : rawValues) {
        values.add((Id) scalar(rawValue, typeName));
      }
      return values;
    }
    throw invalidValue();
  }

  /** Builds a lightning-record-picker-compatible scalar or IN value. */
  public static Object pickerValue(
    List<String> rawValues,
    String fieldType,
    Boolean collectionValue
  ) {
    List<Object> values = new List<Object>();
    for (String rawValue : rawValues) {
      Object converted = scalar(rawValue, fieldType);
      values.add(pickerScalar(converted, fieldType));
    }
    return collectionValue ? (Object) values : values[0];
  }

  private static Object pickerScalar(Object value, String fieldType) {
    String typeName = normalizeType(fieldType);
    if (typeName == 'DATE') {
      return new Map<String, Object>{ 'value' => String.valueOf(value) };
    }
    if (typeName == 'DATETIME') {
      return new Map<String, Object>{
        'value' => ((Datetime) value)
          .formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'')
      };
    }
    if (typeName == 'TIME') {
      return new Map<String, Object>{ 'value' => String.valueOf(value) + 'Z' };
    }
    return String.valueOf(value).toLowerCase() == 'true' ||
      String.valueOf(value).toLowerCase() == 'false'
      ? String.valueOf(value).toLowerCase()
      : String.valueOf(value);
  }

  private static String normalizeType(String fieldType) {
    return String.isBlank(fieldType) ? '' : fieldType.trim().toUpperCase();
  }

  private static BulkRecordUploadException invalidValue() {
    return new BulkRecordUploadException(
      'A configured record context filter value is invalid.'
    );
  }
}
