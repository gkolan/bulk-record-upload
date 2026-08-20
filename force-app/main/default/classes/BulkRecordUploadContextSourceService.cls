/**
 * Parses and validates record-context picker configuration against the host
 * object's Schema describe, and re-applies the eligibility filter server-side
 * so a caller that bypasses the LWC picker is still rejected.
 */
public with sharing class BulkRecordUploadContextSourceService {
  private static final Set<String> FILTER_OPERATORS = new Set<String>{
    '=',
    '!=',
    'IN'
  };

  /**
   * Builds a validated context projection for one host object.
   * @param recordContextSource PAGE or USER_CHOICE; blank defaults to PAGE.
   * @param hostObjectApiName Schema-resolved host object API name.
   * @param rawSearchFields Comma-separated field list; blank defaults to the name field.
   * @param rawDisplayFields Comma-separated field list; blank defaults to the name field.
   * @param rawFilterCriteria One FieldApiName:Operator:Value condition per line.
   * @throws BulkRecordUploadException naming the field, operator, or count that failed.
   */
  public BulkRecordUploadContextProjection buildContextProjection(
    String recordContextSource,
    String hostObjectApiName,
    String rawSearchFields,
    String rawDisplayFields,
    String rawFilterCriteria
  ) {
    Schema.DescribeSObjectResult hostDescribe = resolveHost(hostObjectApiName);
    Map<String, Schema.SObjectField> fieldsByName = hostDescribe.fields.getMap();
    String nameField = defaultNameField(hostDescribe);

    List<String> searchFields = parseFieldList(rawSearchFields, nameField);
    validateFieldList(searchFields, fieldsByName, true);

    List<String> displayFields = parseFieldList(rawDisplayFields, nameField);
    validateFieldList(displayFields, fieldsByName, false);

    List<BulkRecordUploadContextFilterCondition> conditions = parseFilterCriteria(
      rawFilterCriteria,
      fieldsByName
    );

    return new BulkRecordUploadContextProjection(
      recordContextSource,
      searchFields[0],
      additionalFields(searchFields),
      displayFields[0],
      additionalFields(displayFields),
      conditions
    );
  }

  private static List<String> additionalFields(List<String> fields) {
    List<String> additional = new List<String>();
    for (Integer index = 1; index < fields.size(); index++) {
      additional.add(fields[index]);
    }
    return additional;
  }

  /**
   * Returns whether a candidate parent record is visible to the running user
   * and satisfies every configured filter condition.
   */
  public Boolean isEligible(
    String hostObjectApiName,
    Id candidateId,
    List<BulkRecordUploadContextFilterCondition> conditions
  ) {
    List<String> whereClauses = new List<String>{ 'Id = :candidateId' };
    Map<String, Object> binds = new Map<String, Object>{
      'candidateId' => candidateId
    };
    Integer bindIndex = 0;
    for (BulkRecordUploadContextFilterCondition condition : conditions) {
      String bindName = 'v' + bindIndex;
      bindIndex++;
      if (condition.operatorCode == 'IN') {
        whereClauses.add(condition.fieldApiName + ' IN :' + bindName);
        binds.put(bindName, condition.values);
      } else {
        whereClauses.add(
          condition.fieldApiName +
            ' ' +
            condition.operatorCode +
            ' :' +
            bindName
        );
        binds.put(bindName, condition.values[0]);
      }
    }
    List<SObject> matches = Database.queryWithBinds(
      'SELECT Id FROM ' +
        hostObjectApiName +
        ' WHERE ' +
        String.join(whereClauses, ' AND '),
      binds,
      AccessLevel.USER_MODE
    );
    return !matches.isEmpty();
  }

  private static Schema.DescribeSObjectResult resolveHost(
    String hostObjectApiName
  ) {
    Schema.SObjectType hostType = String.isBlank(hostObjectApiName)
      ? null
      : Schema.getGlobalDescribe().get(hostObjectApiName.trim());
    if (hostType == null) {
      throw new BulkRecordUploadException(
        'Configured record context host object is unavailable.'
      );
    }
    return hostType.getDescribe();
  }

  private static String defaultNameField(
    Schema.DescribeSObjectResult hostDescribe
  ) {
    for (Schema.SObjectField field : hostDescribe.fields.getMap().values()) {
      if (field.getDescribe().isNameField()) {
        return field.getDescribe().getName();
      }
    }
    return 'Name';
  }

  private static List<String> parseFieldList(
    String rawValue,
    String defaultField
  ) {
    if (String.isBlank(rawValue)) {
      return new List<String>{ defaultField };
    }
    List<String> fields = new List<String>();
    for (String part : rawValue.split(',')) {
      if (String.isNotBlank(part)) {
        fields.add(part.trim());
      }
    }
    if (fields.isEmpty()) {
      return new List<String>{ defaultField };
    }
    return fields;
  }

  private static void validateFieldList(
    List<String> fields,
    Map<String, Schema.SObjectField> fieldsByName,
    Boolean requireFilterable
  ) {
    if (
      fields.size() - 1 >
      BulkRecordUploadRuntimeContract.MAX_ADDITIONAL_CONTEXT_FIELDS
    ) {
      throw new BulkRecordUploadException(
        'Too many additional record context fields are configured.'
      );
    }
    for (String fieldApiName : fields) {
      Schema.SObjectField fieldToken = fieldsByName.get(fieldApiName);
      if (fieldToken == null) {
        throw new BulkRecordUploadException(
          'Configured record context field "' +
            fieldApiName +
            '" is unavailable.'
        );
      }
      Schema.DescribeFieldResult fieldDescribe = fieldToken.getDescribe();
      if (!fieldDescribe.isAccessible()) {
        throw new BulkRecordUploadException(
          'Configured record context field "' +
            fieldApiName +
            '" is not readable.'
        );
      }
      if (requireFilterable && !fieldDescribe.isFilterable()) {
        throw new BulkRecordUploadException(
          'Configured record context search field "' +
            fieldApiName +
            '" is not searchable.'
        );
      }
    }
  }

  private static List<BulkRecordUploadContextFilterCondition> parseFilterCriteria(
    String rawFilterCriteria,
    Map<String, Schema.SObjectField> fieldsByName
  ) {
    List<BulkRecordUploadContextFilterCondition> conditions = new List<BulkRecordUploadContextFilterCondition>();
    if (String.isBlank(rawFilterCriteria)) {
      return conditions;
    }
    for (String line : rawFilterCriteria.split('\n')) {
      String trimmedLine = line.trim();
      if (String.isBlank(trimmedLine)) {
        continue;
      }
      List<String> parts = trimmedLine.split(':');
      if (parts.size() != 3) {
        throw new BulkRecordUploadException(
          'Configured record context filter condition is not valid.'
        );
      }
      String fieldApiName = parts[0].trim();
      String operatorCode = parts[1].trim().toUpperCase() == 'IN'
        ? 'IN'
        : parts[1].trim();
      Schema.SObjectField fieldToken = fieldsByName.get(fieldApiName);
      if (fieldToken == null) {
        throw new BulkRecordUploadException(
          'Configured record context filter field "' +
            fieldApiName +
            '" is unavailable.'
        );
      }
      Schema.DescribeFieldResult fieldDescribe = fieldToken.getDescribe();
      if (!fieldDescribe.isFilterable() || !fieldDescribe.isAccessible()) {
        throw new BulkRecordUploadException(
          'Configured record context filter field "' +
            fieldApiName +
            '" is not filterable.'
        );
      }
      if (!FILTER_OPERATORS.contains(operatorCode)) {
        throw new BulkRecordUploadException(
          'Configured record context filter operator "' +
            operatorCode +
            '" is not supported.'
        );
      }
      List<String> values = new List<String>();
      for (String value : parts[2].split(',')) {
        if (String.isNotBlank(value)) {
          values.add(value.trim());
        }
      }
      if (values.isEmpty()) {
        throw new BulkRecordUploadException(
          'Configured record context filter condition is missing a value.'
        );
      }
      conditions.add(
        new BulkRecordUploadContextFilterCondition(
          fieldApiName,
          operatorCode,
          values
        )
      );
    }
    if (
      conditions.size() >
      BulkRecordUploadRuntimeContract.MAX_CONTEXT_FILTER_CONDITIONS
    ) {
      throw new BulkRecordUploadException(
        'Too many record context filter conditions are configured.'
      );
    }
    return conditions;
  }
}
