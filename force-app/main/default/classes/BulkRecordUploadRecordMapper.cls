/** Maps projected CSV rows to records using only Schema-approved object and field identifiers. */
public with sharing class BulkRecordUploadRecordMapper {
  private static final Set<String> NUMERIC_TYPES = new Set<String>{
    'INTEGER',
    'LONG',
    'DOUBLE',
    'CURRENCY',
    'PERCENT'
  };

  private final BulkRecordUploadValueCoercer coercer = new BulkRecordUploadValueCoercer();

  /** Maps one bounded row collection without querying or persisting records. */
  public List<BulkRecordUploadMappedRow> mapRows(
    BulkRecordUploadProjection projection,
    List<BulkRecordUploadRow> rows
  ) {
    return mapRows(projection, rows, new Map<String, Map<String, Id>>());
  }

  /**
   * Maps one bounded row collection, resolving lookup and master-detail
   * columns from a caller-supplied, already-queried resolution map. Never
   * queries or persists records itself.
   */
  public List<BulkRecordUploadMappedRow> mapRows(
    BulkRecordUploadProjection projection,
    List<BulkRecordUploadRow> rows,
    Map<String, Map<String, Id>> lookupResolutions
  ) {
    Schema.SObjectType objectType = Schema.getGlobalDescribe()
      .get(projection.objectApiName);
    if (objectType == null) {
      throw new BulkRecordUploadException(
        'The projected object is unavailable.'
      );
    }
    Map<String, Schema.SObjectField> schemaFields = objectType.getDescribe()
      .fields.getMap();
    Map<String, Pattern> compiledPatterns = new Map<String, Pattern>();
    List<BulkRecordUploadMappedRow> mapped = new List<BulkRecordUploadMappedRow>();
    for (BulkRecordUploadRow row : rows) {
      SObject record = objectType.newSObject();
      Map<String, String> values = row.getValuesByColumn();
      for (BulkRecordUploadFieldProjection field : projection.getFields()) {
        Boolean isDerived = String.isNotBlank(field.sourceTemplate);
        if (
          !schemaFields.containsKey(field.fieldApiName) ||
          (!isDerived && !values.containsKey(field.columnKey))
        ) {
          continue;
        }
        String sourceValue = isDerived
          ? BulkRecordUploadSourceTemplate.compose(field.sourceTemplate, values)
          : values.get(field.columnKey);
        String rawValue = normalizeRawValue(sourceValue, field);
        Boolean isBlankValue = String.isBlank(rawValue);
        if (isBlankValue && field.blankValueAction == 'IGNORE') {
          continue;
        }
        if (isBlankValue && field.blankValueAction == 'REJECT') {
          throw new BulkRecordUploadException(
            'A required configured value is blank.'
          );
        }
        Object incoming;
        if (isBlankValue && field.blankValueAction == 'CLEAR') {
          incoming = null;
        } else if (isBlankValue && field.blankValueAction == 'DEFAULT') {
          incoming = field.fieldType == 'REFERENCE'
            ? resolveLookup(field.defaultValue, field, lookupResolutions)
            : coercer.coerce(field.defaultValue, field.fieldType);
        } else if (field.fieldType == 'REFERENCE') {
          incoming = resolveLookup(rawValue, field, lookupResolutions);
        } else {
          validatePattern(rawValue, field, compiledPatterns);
          incoming = coercer.coerce(rawValue, field.fieldType);
          if (
            BulkRecordUploadTextJoinStrategy.TEXT_TYPES.contains(
              field.fieldType
            )
          ) {
            incoming = BulkRecordUploadTextJoinStrategy.applyOverflow(
              (String) incoming,
              fieldLength(schemaFields, field.fieldApiName),
              field
            );
          }
        }
        validateRange(incoming, field);
        record.put(field.fieldApiName, incoming);
      }
      mapped.add(new BulkRecordUploadMappedRow(row.rowNumber, record));
    }
    return mapped;
  }

  /** Applies the configured trim, case, and blank-token rules to a raw CSV value. */
  public static String normalizeRawValue(
    String rawValue,
    BulkRecordUploadFieldProjection field
  ) {
    String value = rawValue;
    if (field.trimValue && value != null) {
      value = value.trim();
    }
    if (value != null && field.caseAction != 'NONE') {
      value = field.fieldType == 'MULTIPICKLIST'
        ? applyCaseToEachToken(value, field.caseAction)
        : applyCase(value, field.caseAction);
    }
    if (
      value != null &&
      !field.blankTokens.isEmpty() &&
      field.blankTokens.contains(value.trim().toLowerCase())
    ) {
      value = '';
    }
    return value;
  }

  private static Id resolveLookup(
    String rawValue,
    BulkRecordUploadFieldProjection field,
    Map<String, Map<String, Id>> lookupResolutions
  ) {
    if (String.isBlank(field.lookupMatchField)) {
      try {
        return Id.valueOf(rawValue);
      } catch (Exception error) {
        throw new BulkRecordUploadException(
          'A configured lookup value is not a valid Salesforce Id for ' +
            field.displayLabel +
            '.'
        );
      }
    }
    Map<String, Id> resolutions = lookupResolutions.get(field.fieldApiName);
    Id resolved = resolutions == null ? null : resolutions.get(rawValue);
    if (resolved == null) {
      throw new BulkRecordUploadException(
        'A configured lookup value did not resolve to exactly one record for ' +
          field.displayLabel +
          '.'
      );
    }
    return resolved;
  }

  private static Integer fieldLength(
    Map<String, Schema.SObjectField> schemaFields,
    String fieldApiName
  ) {
    Schema.SObjectField fieldToken = schemaFields.get(fieldApiName);
    return fieldToken == null ? null : fieldToken.getDescribe().getLength();
  }

  private static void validatePattern(
    String rawValue,
    BulkRecordUploadFieldProjection field,
    Map<String, Pattern> compiledPatterns
  ) {
    if (String.isBlank(field.validationPattern)) {
      return;
    }
    Pattern compiled = compiledPatterns.get(field.validationPattern);
    if (compiled == null) {
      compiled = Pattern.compile(field.validationPattern);
      compiledPatterns.put(field.validationPattern, compiled);
    }
    if (!compiled.matcher(rawValue).matches()) {
      throw new BulkRecordUploadException(
        'A configured value does not match the required pattern for ' +
          field.displayLabel +
          '.'
      );
    }
  }

  private static void validateRange(
    Object incoming,
    BulkRecordUploadFieldProjection field
  ) {
    if (
      incoming == null || (field.minValue == null && field.maxValue == null)
    ) {
      return;
    }
    if (!NUMERIC_TYPES.contains(field.fieldType)) {
      throw new BulkRecordUploadException(
        'Minimum Value and Maximum Value require a number, currency, or percent field.'
      );
    }
    Decimal numericValue = Decimal.valueOf(String.valueOf(incoming));
    if (field.minValue != null && numericValue < field.minValue) {
      throw new BulkRecordUploadException(
        'A configured value is below the minimum for ' +
          field.displayLabel +
          '.'
      );
    }
    if (field.maxValue != null && numericValue > field.maxValue) {
      throw new BulkRecordUploadException(
        'A configured value is above the maximum for ' +
          field.displayLabel +
          '.'
      );
    }
  }

  private static String applyCaseToEachToken(String value, String caseAction) {
    List<String> tokens = new List<String>();
    for (String token : value.split(';')) {
      tokens.add(applyCase(token, caseAction));
    }
    return String.join(tokens, ';');
  }

  private static String applyCase(String value, String caseAction) {
    if (caseAction == 'UPPER') {
      return value.toUpperCase();
    }
    if (caseAction == 'LOWER') {
      return value.toLowerCase();
    }
    if (caseAction == 'TITLE') {
      return toTitleCase(value);
    }
    return value;
  }

  private static String toTitleCase(String value) {
    List<String> capitalized = new List<String>();
    for (String word : value.split(' ')) {
      capitalized.add(
        String.isBlank(word)
          ? word
          : word.substring(0, 1).toUpperCase() + word.substring(1).toLowerCase()
      );
    }
    return String.join(capitalized, ' ');
  }
}
