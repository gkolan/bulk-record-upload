/** Validates one upload process while its compact Salesforce field list is built. */
public with sharing class BulkRecordUploadProjectionValidator {
  private static final Set<Schema.DisplayType> SUPPORTED_FIELD_TYPES = new Set<Schema.DisplayType>{
    Schema.DisplayType.STRING,
    Schema.DisplayType.TEXTAREA,
    Schema.DisplayType.EMAIL,
    Schema.DisplayType.PHONE,
    Schema.DisplayType.URL,
    Schema.DisplayType.ID,
    Schema.DisplayType.PICKLIST,
    Schema.DisplayType.MULTIPICKLIST,
    Schema.DisplayType.BOOLEAN,
    Schema.DisplayType.INTEGER,
    Schema.DisplayType.LONG,
    Schema.DisplayType.DOUBLE,
    Schema.DisplayType.CURRENCY,
    Schema.DisplayType.PERCENT,
    Schema.DisplayType.DATE,
    Schema.DisplayType.DATETIME,
    Schema.DisplayType.REFERENCE
  };
  private static final Set<Schema.DisplayType> NUMERIC_DISPLAY_TYPES = new Set<Schema.DisplayType>{
    Schema.DisplayType.INTEGER,
    Schema.DisplayType.LONG,
    Schema.DisplayType.DOUBLE,
    Schema.DisplayType.CURRENCY,
    Schema.DisplayType.PERCENT
  };

  /** Confirms a custom existing-value action can handle its selected field. */
  public static void validateCustomMergeStrategies(
    List<BulkRecordUploadFieldProjection> projectedFields
  ) {
    BulkRecordUploadMergeStrategyRegistry registry = new BulkRecordUploadMergeStrategyRegistry();
    for (BulkRecordUploadFieldProjection field : projectedFields) {
      if (field.existingValueAction == 'CUSTOM') {
        BulkRecordUploadFieldMergeStrategy strategy = registry.resolve(
          field.customMergeStrategyClass
        );
        if (!strategy.supportsType(field.fieldType)) {
          throw new BulkRecordUploadException(
            'The custom merge strategy does not support its configured field type.'
          );
        }
      }
    }
  }

  /** Confirms that number limits are used only with number fields. */
  public static void validateRange(
    BulkRecordUploadFieldConfig config,
    Schema.DescribeFieldResult fieldDescribe
  ) {
    if (
      (config.minValue != null || config.maxValue != null) &&
      !NUMERIC_DISPLAY_TYPES.contains(fieldDescribe.getType())
    ) {
      throw new BulkRecordUploadException(
        'Minimum Value and Maximum Value require a number, currency, or percent field.'
      );
    }
  }

  /** Confirms that an upsert key is a Salesforce External ID. */
  public static void validateUpsertKey(
    BulkRecordUploadFieldConfig config,
    Schema.DescribeFieldResult fieldDescribe
  ) {
    if (config.isUpsertKey && !fieldDescribe.isExternalId()) {
      throw new BulkRecordUploadException(
        'The configured upsert key must be a Salesforce External ID field.'
      );
    }
  }

  /** Confirms that Lookup Match Field is used only for a relationship field. */
  public static void validateLookupMatchField(
    BulkRecordUploadFieldConfig config,
    Schema.DescribeFieldResult fieldDescribe
  ) {
    if (
      String.isNotBlank(config.lookupMatchField) &&
      fieldDescribe.getType() != Schema.DisplayType.REFERENCE
    ) {
      throw new BulkRecordUploadException(
        'Lookup Match Field can be configured only for a relationship field.'
      );
    }
  }

  /** Confirms that the field type can be safely read from a CSV file. */
  public static void validateSupportedType(
    Schema.DescribeFieldResult fieldDescribe
  ) {
    if (!SUPPORTED_FIELD_TYPES.contains(fieldDescribe.getType())) {
      throw new BulkRecordUploadException(
        'The configured target field type is not supported.'
      );
    }
  }

  /** Confirms that the selected existing-value action supports the field type. */
  public static void validateBuiltInMergeStrategy(
    BulkRecordUploadFieldConfig config,
    Schema.DescribeFieldResult fieldDescribe
  ) {
    String action = config.existingValueAction;
    String typeName = String.valueOf(fieldDescribe.getType());
    Boolean supported =
      new Set<String>{ 'REPLACE', 'KEEP_EXISTING', 'CUSTOM' }
        .contains(action) ||
      (new Set<String>{ 'APPEND', 'PREPEND' }.contains(action) &&
      BulkRecordUploadTextJoinStrategy.TEXT_TYPES.contains(typeName)) ||
      (new Set<String>{ 'ADD_VALUES', 'REMOVE_VALUES' }.contains(action) &&
      typeName == 'MULTIPICKLIST') ||
      (new Set<String>{ 'ADD', 'SUBTRACT' }.contains(action) &&
      NUMERIC_DISPLAY_TYPES.contains(fieldDescribe.getType())) ||
      (new Set<String>{ 'USE_LATER', 'USE_EARLIER' }.contains(action) &&
      new Set<String>{ 'DATE', 'DATETIME' }.contains(typeName)) ||
      (new Set<String>{ 'TRUE_IF_EITHER', 'TRUE_IF_BOTH' }.contains(action) &&
      typeName == 'BOOLEAN');
    if (!supported) {
      throw new BulkRecordUploadException(
        'The existing-value action does not support its configured field type.'
      );
    }
  }

  /** Confirms that the chosen page record can safely set the target relationship. */
  public static void validateRecordContext(
    BulkRecordUploadProcessConfig process,
    Schema.DescribeSObjectResult targetDescribe
  ) {
    if (process.recordContextAction == 'NONE') {
      return;
    }
    Schema.SObjectType hostType = Schema.getGlobalDescribe()
      .get(process.hostObjectApiName);
    Schema.SObjectField relationshipToken = targetDescribe.fields.getMap()
      .get(process.recordContextFieldApiName);
    if (hostType == null || relationshipToken == null) {
      throw new BulkRecordUploadException(
        'Configured record context is unavailable.'
      );
    }
    Schema.DescribeFieldResult relationship = relationshipToken.getDescribe();
    Boolean writable = process.operation == 'INSERT'
      ? relationship.isCreateable()
      : process.operation == 'UPSERT'
          ? relationship.isCreateable() && relationship.isUpdateable()
          : relationship.isUpdateable();
    if (
      relationship.getType() != Schema.DisplayType.REFERENCE ||
      !relationship.getReferenceTo().contains(hostType) ||
      !writable
    ) {
      throw new BulkRecordUploadException(
        'Configured parent relationship is not allowed.'
      );
    }
  }

  /** Confirms the current user can use the field for the selected operation. */
  public static void validateFieldAccess(
    BulkRecordUploadFieldConfig config,
    Schema.DescribeFieldResult fieldDescribe,
    String operation
  ) {
    Boolean allowed = operation == 'INSERT'
      ? fieldDescribe.isCreateable()
      : operation == 'DELETE'
          ? fieldDescribe.isAccessible()
          : operation == 'UPSERT'
              ? fieldDescribe.isCreateable() && fieldDescribe.isUpdateable()
              : fieldDescribe.isUpdateable();
    Boolean existingValueReadable =
      !new Set<String>{ 'UPDATE', 'UPSERT' }.contains(operation) ||
      config.existingValueAction == 'REPLACE' ||
      fieldDescribe.isAccessible();
    Boolean matchKeyReadable =
      !config.isMatchKey ||
      (fieldDescribe.isAccessible() && fieldDescribe.isFilterable());
    if (
      !allowed ||
      !existingValueReadable ||
      !matchKeyReadable ||
      fieldDescribe.isCalculated() ||
      fieldDescribe.isAutoNumber()
    ) {
      throw new BulkRecordUploadException(
        'A configured target field is inaccessible or read-only.'
      );
    }
  }

  /** Confirms that each column, field, and sequence appears only once. */
  public static void validateUnique(
    BulkRecordUploadFieldConfig config,
    Set<String> columnKeys,
    Set<Integer> sequences,
    Set<String> targetFieldNames
  ) {
    String targetKey = config.fieldApiName.toLowerCase();
    if (
      columnKeys.contains(config.columnKey) ||
      sequences.contains(config.sequence) ||
      targetFieldNames.contains(targetKey)
    ) {
      throw new BulkRecordUploadException(
        'Process field columns and sequences must be unique.'
      );
    }
    columnKeys.add(config.columnKey);
    sequences.add(config.sequence);
    targetFieldNames.add(targetKey);
  }

  /** Confirms that a template uses only columns supplied by the CSV file. */
  public static void validateSourceTemplates(
    List<BulkRecordUploadFieldProjection> projectedFields,
    Set<String> rawColumnKeys
  ) {
    for (BulkRecordUploadFieldProjection field : projectedFields) {
      if (String.isBlank(field.sourceTemplate)) {
        continue;
      }
      for (
        String token : BulkRecordUploadSourceTemplate.tokens(
          field.sourceTemplate
        )
      ) {
        if (!rawColumnKeys.contains(token)) {
          throw new BulkRecordUploadException(
            'Source Template for "' +
              field.displayLabel +
              '" references an unconfigured or derived column.'
          );
        }
      }
    }
  }
}
