/**
 * Resolves lookup and master-detail columns configured with a Lookup Match
 * Field to record Ids, using one bounded user-mode query per lookup field
 * per chunk. A raw value that matches zero or more than one target record
 * is left unresolved, so BulkRecordUploadRecordMapper fails only the rows
 * that use it.
 */
public with sharing class BulkRecordUploadLookupResolver {
  /**
   * Resolves configuration-time whether a field is a supported, single-
   * target lookup, and validates its Lookup Match Field when configured.
   * @return The lookup's target object API name, or null for a non-lookup
   *   field.
   * @throws BulkRecordUploadException for a polymorphic lookup or a Lookup
   *   Match Field that is not filterable on the target object.
   */
  public static String resolveLookupTargetObject(
    BulkRecordUploadFieldConfig config,
    Schema.DescribeFieldResult fieldDescribe
  ) {
    if (fieldDescribe.getType() != Schema.DisplayType.REFERENCE) {
      return null;
    }
    List<Schema.SObjectType> referenceTo = fieldDescribe.getReferenceTo();
    if (referenceTo.size() != 1) {
      throw new BulkRecordUploadException(
        'Polymorphic lookup fields are not supported.'
      );
    }
    Schema.DescribeSObjectResult targetDescribe = referenceTo[0].getDescribe();
    if (String.isBlank(config.lookupMatchField)) {
      return targetDescribe.getName();
    }
    Schema.SObjectField matchFieldToken = targetDescribe.fields
      .getMap()
      .get(config.lookupMatchField);
    if (
      matchFieldToken == null ||
      !matchFieldToken.getDescribe().isFilterable() ||
      !matchFieldToken.getDescribe().isAccessible()
    ) {
      throw new BulkRecordUploadException(
        'Lookup Match Field is not a readable, filterable field on the lookup target object.'
      );
    }
    return targetDescribe.getName();
  }

  /**
   * Resolves every Lookup Match Field-configured column in one bounded
   * query per column.
   * @return Resolved Id keyed by raw CSV text, keyed by target field API name.
   */
  public Map<String, Map<String, Id>> resolve(
    BulkRecordUploadProjection projection,
    List<BulkRecordUploadRow> rows
  ) {
    Map<String, Map<String, Id>> resolutions = new Map<String, Map<String, Id>>();
    for (BulkRecordUploadFieldProjection field : projection.getFields()) {
      if (
        field.fieldType != 'REFERENCE' || String.isBlank(field.lookupMatchField)
      ) {
        continue;
      }
      resolutions.put(field.fieldApiName, resolveField(field, rows));
    }
    return resolutions;
  }

  /**
   * Resolves each configured raw CSV value (normalized the same way
   * BulkRecordUploadRecordMapper normalizes it before lookup) to a target
   * record Id, matching the query results case-insensitively so the
   * resolution map's keys always agree with what the mapper looks up with.
   */
  private static Map<String, Id> resolveField(
    BulkRecordUploadFieldProjection field,
    List<BulkRecordUploadRow> rows
  ) {
    Map<String, Id> resolved = new Map<String, Id>();
    Map<String, String> rawValuesByCanonicalValue = collectRawValues(
      field,
      rows
    );
    if (rawValuesByCanonicalValue.isEmpty()) {
      return resolved;
    }
    Set<String> rawValues = new Set<String>(rawValuesByCanonicalValue.values());
    List<SObject> matches = Database.queryWithBinds(
      'SELECT Id, ' +
        field.lookupMatchField +
        ' FROM ' +
        field.lookupTargetObject +
        ' WHERE ' +
        field.lookupMatchField +
        ' IN :rawValues',
      new Map<String, Object>{ 'rawValues' => rawValues },
      AccessLevel.USER_MODE
    );
    Map<String, Id> idsByCanonicalMatch = new Map<String, Id>();
    Set<String> ambiguous = new Set<String>();
    for (SObject matchRecord : matches) {
      Object matchValue = matchRecord.get(field.lookupMatchField);
      if (matchValue == null) {
        continue;
      }
      String key = canonicalForField(matchValue, field);
      if (idsByCanonicalMatch.containsKey(key)) {
        ambiguous.add(key);
      } else {
        idsByCanonicalMatch.put(key, matchRecord.Id);
      }
    }
    for (String ambiguousKey : ambiguous) {
      idsByCanonicalMatch.remove(ambiguousKey);
    }
    for (String canonicalRaw : rawValuesByCanonicalValue.keySet()) {
      Id resolvedId = idsByCanonicalMatch.get(canonicalRaw);
      if (resolvedId != null) {
        resolved.put(canonicalRaw, resolvedId);
      }
    }
    return resolved;
  }

  /** @return The configured, mapper-normalized raw value keyed by canonical form. */
  private static Map<String, String> collectRawValues(
    BulkRecordUploadFieldProjection field,
    List<BulkRecordUploadRow> rows
  ) {
    Map<String, String> rawValuesByCanonicalValue = new Map<String, String>();
    for (BulkRecordUploadRow row : rows) {
      Map<String, String> values = row.getValuesByColumn();
      String sourceValue = String.isNotBlank(field.sourceTemplate)
        ? BulkRecordUploadSourceTemplate.compose(field.sourceTemplate, values)
        : values.get(field.columnKey);
      String rawValue = BulkRecordUploadRecordMapper.normalizeRawValue(
        sourceValue,
        field
      );
      if (String.isNotBlank(rawValue)) {
        rawValuesByCanonicalValue.put(
          canonicalForField(rawValue, field),
          rawValue
        );
      }
    }
    if (
      field.blankValueAction == 'DEFAULT' &&
      String.isNotBlank(field.defaultValue)
    ) {
      String normalizedDefault = BulkRecordUploadRecordMapper.normalizeRawValue(
        field.defaultValue,
        field
      );
      if (String.isNotBlank(normalizedDefault)) {
        rawValuesByCanonicalValue.put(
          canonicalForField(normalizedDefault, field),
          normalizedDefault
        );
      }
    }
    return rawValuesByCanonicalValue;
  }

  /** Returns a stable case-insensitive key for text lookup resolution. */
  public static String canonical(String value) {
    return canonicalValue(value, 'STRING');
  }

  /** Returns a stable key using the configured lookup match field's Schema type. */
  public static String canonicalForField(
    Object value,
    BulkRecordUploadFieldProjection field
  ) {
    Schema.SObjectType targetType = Schema.getGlobalDescribe()
      .get(field.lookupTargetObject);
    Schema.SObjectField matchField = targetType == null
      ? null
      : targetType.getDescribe().fields.getMap().get(field.lookupMatchField);
    String fieldType = matchField == null
      ? 'STRING'
      : String.valueOf(matchField.getDescribe().getType());
    return canonicalValue(value, fieldType);
  }

  /** Returns a stable key for a Schema-resolved lookup match value. */
  public static String canonicalValue(Object value, String fieldType) {
    if (value == null) {
      return '';
    }
    String canonical = String.valueOf(value).trim();
    if (
      new Set<String>{ 'INTEGER', 'LONG', 'DOUBLE', 'CURRENCY', 'PERCENT' }
        .contains(fieldType)
    ) {
      if (canonical.contains('.')) {
        while (canonical.endsWith('0')) {
          canonical = canonical.left(canonical.length() - 1);
        }
        if (canonical.endsWith('.')) {
          canonical = canonical.left(canonical.length() - 1);
        }
      }
      return canonical;
    }
    return canonical.toLowerCase();
  }
}
