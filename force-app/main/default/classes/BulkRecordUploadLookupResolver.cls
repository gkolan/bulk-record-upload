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
      matchFieldToken == null || !matchFieldToken.getDescribe().isFilterable()
    ) {
      throw new BulkRecordUploadException(
        'Lookup Match Field is not a filterable field on the lookup target object.'
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
    Map<String, String> rawValuesByLowerCase = collectRawValues(field, rows);
    if (rawValuesByLowerCase.isEmpty()) {
      return resolved;
    }
    Set<String> rawValues = new Set<String>(rawValuesByLowerCase.values());
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
    Map<String, Id> idsByLowerCaseMatch = new Map<String, Id>();
    Set<String> ambiguous = new Set<String>();
    for (SObject matchRecord : matches) {
      Object matchValue = matchRecord.get(field.lookupMatchField);
      if (matchValue == null) {
        continue;
      }
      String key = String.valueOf(matchValue).toLowerCase();
      if (idsByLowerCaseMatch.containsKey(key)) {
        ambiguous.add(key);
      } else {
        idsByLowerCaseMatch.put(key, matchRecord.Id);
      }
    }
    for (String ambiguousKey : ambiguous) {
      idsByLowerCaseMatch.remove(ambiguousKey);
    }
    for (String lowerCaseRaw : rawValuesByLowerCase.keySet()) {
      Id resolvedId = idsByLowerCaseMatch.get(lowerCaseRaw);
      if (resolvedId != null) {
        resolved.put(rawValuesByLowerCase.get(lowerCaseRaw), resolvedId);
      }
    }
    return resolved;
  }

  /** @return The configured, mapper-normalized raw value keyed by its lowercase form. */
  private static Map<String, String> collectRawValues(
    BulkRecordUploadFieldProjection field,
    List<BulkRecordUploadRow> rows
  ) {
    Map<String, String> rawValuesByLowerCase = new Map<String, String>();
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
        rawValuesByLowerCase.put(rawValue.toLowerCase(), rawValue);
      }
    }
    return rawValuesByLowerCase;
  }
}
