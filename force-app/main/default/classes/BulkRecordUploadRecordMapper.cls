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
      BulkRecordUploadMappedRow mappedRow = new BulkRecordUploadMappedRow(
        row.rowNumber,
        record
      );
      Map<String, String> values = row.getValuesByColumn();
      try {
        if (isBlankRow(values)) {
          throw new BulkRecordUploadException(
            'The CSV row is blank and was not processed.'
          );
        }
        mapFields(
          projection,
          values,
          record,
          schemaFields,
          compiledPatterns,
          lookupResolutions
        );
      } catch (BulkRecordUploadException error) {
        mappedRow.markFailed(
          BulkRecordUploadRuntimeContract.REASON_VALIDATION_ERROR,
          error.getMessage()
        );
      }
      mapped.add(mappedRow);
    }
    return mapped;
  }

  private void mapFields(
    BulkRecordUploadProjection projection,
    Map<String, String> values,
    SObject record,
    Map<String, Schema.SObjectField> schemaFields,
    Map<String, Pattern> compiledPatterns,
    Map<String, Map<String, Id>> lookupResolutions
  ) {
    for (BulkRecordUploadFieldProjection field : projection.getFields()) {
      Schema.SObjectField fieldToken = schemaFields.get(field.fieldApiName);
      if (fieldToken == null) {
        throw new BulkRecordUploadException(
          'A configured target field is unavailable.'
        );
      }
      Boolean isDerived = String.isNotBlank(field.sourceTemplate);
      String sourceValue = isDerived
        ? BulkRecordUploadSourceTemplate.compose(field.sourceTemplate, values)
        : values.get(field.columnKey);
      String rawValue = normalizeRawValue(sourceValue, field);
      Boolean isBlankValue = String.isBlank(rawValue);
      if (
        isBlankValue &&
        field.isRequired &&
        field.blankValueAction != 'DEFAULT'
      ) {
        throw new BulkRecordUploadException(
          'A required configured value is blank for ' + field.displayLabel + '.'
        );
      }
      if (isBlankValue && field.blankValueAction == 'IGNORE') {
        continue;
      }
      if (isBlankValue && field.blankValueAction == 'REJECT') {
        throw new BulkRecordUploadException(
          'A required configured value is blank for ' + field.displayLabel + '.'
        );
      }
      Object incoming;
      if (isBlankValue && field.blankValueAction == 'CLEAR') {
        incoming = null;
      } else if (isBlankValue && field.blankValueAction == 'DEFAULT') {
        String normalizedDefault = normalizeRawValue(field.defaultValue, field);
        if (String.isBlank(normalizedDefault)) {
          throw new BulkRecordUploadException(
            'The configured default value is blank for ' +
              field.displayLabel +
              '.'
          );
        }
        validatePattern(normalizedDefault, field, compiledPatterns);
        incoming = field.fieldType == 'REFERENCE'
          ? resolveLookup(normalizedDefault, field, lookupResolutions)
          : coerceFieldValue(
              normalizedDefault,
              field,
              fieldToken.getDescribe()
            );
      } else if (field.fieldType == 'REFERENCE') {
        incoming = resolveLookup(rawValue, field, lookupResolutions);
      } else {
        validatePattern(rawValue, field, compiledPatterns);
        incoming = coerceFieldValue(rawValue, field, fieldToken.getDescribe());
      }
      validatePicklist(incoming, fieldToken.getDescribe(), field);
      if (
        incoming instanceof String &&
        BulkRecordUploadTextJoinStrategy.TEXT_TYPES.contains(field.fieldType)
      ) {
        incoming = BulkRecordUploadTextJoinStrategy.applyOverflow(
          (String) incoming,
          fieldToken.getDescribe().getLength(),
          field
        );
      }
      validateRange(incoming, field);
      record.put(field.fieldApiName, incoming);
    }
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
    Id resolved = resolutions == null
      ? null
      : resolutions.get(
          BulkRecordUploadLookupResolver.canonicalForField(rawValue, field)
        );
    if (resolved == null) {
      throw new BulkRecordUploadException(
        'A configured lookup value did not resolve to exactly one record for ' +
          field.displayLabel +
          '.'
      );
    }
    return resolved;
  }

  private static Boolean isBlankRow(Map<String, String> values) {
    for (String value : values.values()) {
      if (String.isNotBlank(value)) {
        return false;
      }
    }
    return true;
  }

  private Object coerceFieldValue(
    String rawValue,
    BulkRecordUploadFieldProjection field,
    Schema.DescribeFieldResult fieldDescribe
  ) {
    if (
      field.fieldType == 'MULTIPICKLIST' &&
      isActivePicklistValue(rawValue, fieldDescribe)
    ) {
      return rawValue;
    }
    return coercer.coerce(rawValue, field.fieldType);
  }

  private static Boolean isActivePicklistValue(
    String rawValue,
    Schema.DescribeFieldResult fieldDescribe
  ) {
    for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
      if (entry.isActive() && entry.getValue() == rawValue) {
        return true;
      }
    }
    return false;
  }

  private static void validatePicklist(
    Object incoming,
    Schema.DescribeFieldResult fieldDescribe,
    BulkRecordUploadFieldProjection field
  ) {
    if (
      incoming == null ||
      !new Set<String>{ 'PICKLIST', 'MULTIPICKLIST' }
        .contains(field.fieldType) ||
      !fieldDescribe.isRestrictedPicklist()
    ) {
      return;
    }
    Set<String> allowed = new Set<String>();
    for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
      if (entry.isActive()) {
        allowed.add(entry.getValue());
      }
    }
    List<String> tokens = field.fieldType == 'MULTIPICKLIST'
      ? String.valueOf(incoming).split(';')
      : new List<String>{ String.valueOf(incoming) };
    for (String token : tokens) {
      if (!allowed.contains(token)) {
        throw new BulkRecordUploadException(
          'A configured picklist value is invalid for ' +
            field.displayLabel +
            '.'
        );
      }
    }
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
