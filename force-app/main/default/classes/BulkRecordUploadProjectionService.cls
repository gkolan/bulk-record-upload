/**
 * Builds a canonical compact projection from active configuration, Schema describe, and current-user access.
 */
public with sharing class BulkRecordUploadProjectionService {
  private final BulkRecordUploadConfigRepository repository;
  private final BulkRecordUploadAccessPolicy accessPolicy;
  private final BulkRecordUploadProjectionCache projectionCache;

  /** Creates a production projection service. */
  public BulkRecordUploadProjectionService() {
    this(
      new BulkRecordUploadConfigRepository(),
      new BulkRecordUploadAccessPolicy(),
      new BulkRecordUploadProjectionCache()
    );
  }

  /**
   * Creates an injectable projection service.
   * @param repository Configuration source.
   * @param accessPolicy Current-user authorization boundary.
   * @param projectionCache Bounded transaction cache.
   */
  @TestVisible
  private BulkRecordUploadProjectionService(
    BulkRecordUploadConfigRepository repository,
    BulkRecordUploadAccessPolicy accessPolicy,
    BulkRecordUploadProjectionCache projectionCache
  ) {
    this.repository = repository;
    this.accessPolicy = accessPolicy;
    this.projectionCache = projectionCache;
  }

  /**
   * Builds or finds the current-user projection for one active process.
   * @param processKey Exact active process Developer Name.
   * @return Immutable compact projection containing at most 100 fields.
   * @throws BulkRecordUploadException for invalid, unsupported, or inaccessible configuration.
   */
  public BulkRecordUploadProjection getProjection(String processKey) {
    accessPolicy.requireRunPermission();
    BulkRecordUploadConfigRepository.Configuration configuration = repository.findActive(
      processKey
    );
    Schema.DescribeSObjectResult objectDescribe = resolveObject(
      configuration.process.objectApiName
    );
    accessPolicy.requireOperationAccess(
      objectDescribe,
      configuration.process.operation
    );
    accessPolicy.requirePreviewPermission(
      configuration.process.previewPermission
    );
    List<String> extensionClassNames = extensionClassNames(configuration);
    new BulkRecordUploadExtensionRegistry().resolve(extensionClassNames);
    BulkRecordUploadContextProjection contextProjection = buildContextProjection(
      configuration.process
    );

    String configHash = createConfigHash(
      configuration,
      extensionClassNames,
      contextProjection
    );
    String cacheKey = createCacheKey(
      configuration.process,
      configHash,
      objectDescribe
    );
    BulkRecordUploadProjection cached = projectionCache.find(cacheKey);
    if (cached != null) {
      return cached;
    }

    BulkRecordUploadProjection projection = buildProjection(
      configuration,
      objectDescribe,
      configHash,
      extensionClassNames,
      contextProjection
    );
    projectionCache.put(cacheKey, projection);
    return projection;
  }

  private static BulkRecordUploadContextProjection buildContextProjection(
    BulkRecordUploadProcessConfig process
  ) {
    if (
      process.recordContextAction == 'NONE' ||
      String.isBlank(process.hostObjectApiName)
    ) {
      return null;
    }
    return new BulkRecordUploadContextSourceService()
      .buildContextProjection(
        process.recordContextSource,
        process.hostObjectApiName,
        process.contextSearchFields,
        process.contextDisplayFields,
        process.contextFilterCriteria
      );
  }

  private BulkRecordUploadProjection buildProjection(
    BulkRecordUploadConfigRepository.Configuration configuration,
    Schema.DescribeSObjectResult objectDescribe,
    String configHash,
    List<String> extensionClassNames,
    BulkRecordUploadContextProjection contextProjection
  ) {
    List<BulkRecordUploadFieldConfig> fieldConfigs = configuration.getFields();
    if (fieldConfigs.isEmpty() || fieldConfigs.size() > 100) {
      throw new BulkRecordUploadException(
        'Process must configure between 1 and 100 active fields.'
      );
    }
    Map<String, Schema.SObjectField> fieldsByName = objectDescribe.fields.getMap();
    List<BulkRecordUploadFieldProjection> projectedFields = new List<BulkRecordUploadFieldProjection>();
    Set<String> columnKeys = new Set<String>();
    Set<String> rawColumnKeys = new Set<String>();
    Set<Integer> sequences = new Set<Integer>();
    for (BulkRecordUploadFieldConfig fieldConfig : fieldConfigs) {
      validateUnique(fieldConfig, columnKeys, sequences);
      if (String.isBlank(fieldConfig.sourceTemplate)) {
        rawColumnKeys.add(fieldConfig.columnKey);
      }
      Schema.SObjectField fieldToken = fieldsByName.get(
        fieldConfig.fieldApiName
      );
      if (fieldToken == null) {
        throw new BulkRecordUploadException(
          'A configured target field is unavailable.'
        );
      }
      Schema.DescribeFieldResult fieldDescribe = fieldToken.getDescribe();
      validateFieldAccess(fieldDescribe, configuration.process.operation);
      validateRange(fieldConfig, fieldDescribe);
      projectedFields.add(createFieldProjection(fieldConfig, fieldDescribe));
    }
    validateSourceTemplates(projectedFields, rawColumnKeys);
    validateCustomMergeStrategies(projectedFields);
    validateRecordContext(configuration.process, objectDescribe);
    return new BulkRecordUploadProjection(
      configuration.process.processKey,
      configHash,
      objectDescribe.getName(),
      configuration.process.operation,
      extensionClassNames,
      configuration.process.processorKey,
      configuration.process.recordContextAction,
      configuration.process.hostObjectApiName,
      configuration.process.recordContextFieldApiName,
      contextProjection,
      configuration.process.batchSize,
      configuration.process.retentionDays,
      projectedFields
    );
  }

  private static List<String> extensionClassNames(
    BulkRecordUploadConfigRepository.Configuration configuration
  ) {
    List<String> classNames = new List<String>();
    for (
      BulkRecordUploadExtensionConfig extensionConfig : configuration.getExtensions()
    ) {
      classNames.add(extensionConfig.className);
    }
    return classNames;
  }

  /**
   * A Custom existing-value action's class is resolved eagerly here, the
   * same way row-extension classes are resolved in getProjection, so a
   * missing or misconfigured class fails at config load instead of mid-
   * chunk during row merging.
   */
  private static void validateCustomMergeStrategies(
    List<BulkRecordUploadFieldProjection> projectedFields
  ) {
    BulkRecordUploadMergeStrategyRegistry registry = new BulkRecordUploadMergeStrategyRegistry();
    for (BulkRecordUploadFieldProjection field : projectedFields) {
      if (field.existingValueAction == 'CUSTOM') {
        registry.resolve(field.customMergeStrategyClass);
      }
    }
  }

  private static final Set<Schema.DisplayType> NUMERIC_DISPLAY_TYPES = new Set<Schema.DisplayType>{
    Schema.DisplayType.INTEGER,
    Schema.DisplayType.LONG,
    Schema.DisplayType.DOUBLE,
    Schema.DisplayType.CURRENCY,
    Schema.DisplayType.PERCENT
  };

  /**
   * A Minimum/Maximum Value config error is detected here, at config load,
   * rather than only at row time in BulkRecordUploadRecordMapper, since the
   * field's Schema type is already resolved here.
   */
  private static void validateRange(
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

  private static void validateRecordContext(
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

  private static BulkRecordUploadFieldProjection createFieldProjection(
    BulkRecordUploadFieldConfig config,
    Schema.DescribeFieldResult fieldDescribe
  ) {
    return new BulkRecordUploadFieldProjection(
      config.columnKey,
      config.displayLabel,
      fieldDescribe.getName(),
      String.valueOf(fieldDescribe.getType()),
      config.existingValueAction,
      config.blankValueAction,
      config.textSeparator,
      config.customSeparator,
      config.duplicateTextAction,
      config.overflowAction,
      config.defaultValue,
      config.trimValue,
      config.caseAction,
      config.blankTokens,
      config.customMergeStrategyClass,
      config.validationPattern,
      config.minValue,
      config.maxValue,
      config.sourceTemplate,
      config.lookupMatchField,
      BulkRecordUploadLookupResolver.resolveLookupTargetObject(
        config,
        fieldDescribe
      ),
      config.sequence,
      config.isRequired,
      config.isMatchKey,
      config.isUpsertKey,
      config.includeInResult,
      fieldDescribe.isCreateable(),
      fieldDescribe.isUpdateable()
    );
  }

  private static Schema.DescribeSObjectResult resolveObject(
    String objectApiName
  ) {
    Schema.SObjectType objectToken = Schema.getGlobalDescribe()
      .get(objectApiName);
    if (objectToken == null) {
      throw new BulkRecordUploadException(
        'Configured target object is unavailable.'
      );
    }
    Schema.DescribeSObjectResult objectDescribe = objectToken.getDescribe();
    if (!objectDescribe.isQueryable() || objectDescribe.isCustomSetting()) {
      throw new BulkRecordUploadException(
        'Configured target object is not supported.'
      );
    }
    return objectDescribe;
  }

  private static void validateFieldAccess(
    Schema.DescribeFieldResult fieldDescribe,
    String operation
  ) {
    Boolean allowed = operation == 'INSERT'
      ? fieldDescribe.isCreateable()
      : operation == 'DELETE'
          ? fieldDescribe.isAccessible()
          : fieldDescribe.isUpdateable();
    if (
      !allowed ||
      fieldDescribe.isCalculated() ||
      fieldDescribe.isAutoNumber()
    ) {
      throw new BulkRecordUploadException(
        'A configured target field is inaccessible or read-only.'
      );
    }
  }

  private static void validateUnique(
    BulkRecordUploadFieldConfig config,
    Set<String> columnKeys,
    Set<Integer> sequences
  ) {
    if (
      columnKeys.contains(config.columnKey) ||
      sequences.contains(config.sequence)
    ) {
      throw new BulkRecordUploadException(
        'Process field columns and sequences must be unique.'
      );
    }
    columnKeys.add(config.columnKey);
    sequences.add(config.sequence);
  }

  /**
   * A Source Template token must reference a raw uploaded column, not
   * another derived column: BulkRecordUploadRecordMapper composes derived
   * columns from the CSV row alone, so a token referencing another derived
   * column would silently resolve to an empty string at upload time.
   */
  private static void validateSourceTemplates(
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

  private static String createConfigHash(
    BulkRecordUploadConfigRepository.Configuration configuration,
    List<String> extensionClassNames,
    BulkRecordUploadContextProjection contextProjection
  ) {
    List<String> parts = new List<String>{
      configuration.process.processKey,
      configuration.process.objectApiName,
      configuration.process.operation,
      String.join(extensionClassNames, ','),
      configuration.process.processorKey,
      configuration.process.recordContextAction,
      configuration.process.hostObjectApiName,
      configuration.process.recordContextFieldApiName,
      contextProjection == null
        ? ''
        : String.join(
            new List<String>{
              contextProjection.recordContextSource,
              contextProjection.primarySearchField,
              String.join(contextProjection.additionalSearchFields, ','),
              contextProjection.primaryDisplayField,
              String.join(contextProjection.additionalDisplayFields, ','),
              contextFilterHashPart(contextProjection.filterConditions)
            },
            '|'
          ),
      String.valueOf(configuration.process.batchSize),
      String.valueOf(configuration.process.retentionDays)
    };
    for (BulkRecordUploadFieldConfig fieldConfig : configuration.getFields()) {
      List<String> sortedBlankTokens = new List<String>(
        fieldConfig.blankTokens
      );
      sortedBlankTokens.sort();
      parts.add(
        String.join(
          new List<String>{
            fieldConfig.columnKey,
            fieldConfig.fieldApiName,
            fieldConfig.existingValueAction,
            fieldConfig.blankValueAction,
            fieldConfig.textSeparator,
            String.isBlank(fieldConfig.customSeparator)
              ? ''
              : fieldConfig.customSeparator,
            fieldConfig.duplicateTextAction,
            fieldConfig.overflowAction,
            String.isBlank(fieldConfig.defaultValue)
              ? ''
              : fieldConfig.defaultValue,
            String.valueOf(fieldConfig.trimValue),
            fieldConfig.caseAction,
            String.join(sortedBlankTokens, ','),
            String.isBlank(fieldConfig.customMergeStrategyClass)
              ? ''
              : fieldConfig.customMergeStrategyClass,
            String.isBlank(fieldConfig.validationPattern)
              ? ''
              : fieldConfig.validationPattern,
            String.valueOf(fieldConfig.minValue),
            String.valueOf(fieldConfig.maxValue),
            String.isBlank(fieldConfig.sourceTemplate)
              ? ''
              : fieldConfig.sourceTemplate,
            String.isBlank(fieldConfig.lookupMatchField)
              ? ''
              : fieldConfig.lookupMatchField,
            String.valueOf(fieldConfig.sequence)
          },
          ':'
        )
      );
    }
    return digest(String.join(parts, '|'));
  }

  private static String createCacheKey(
    BulkRecordUploadProcessConfig process,
    String configHash,
    Schema.DescribeSObjectResult objectDescribe
  ) {
    String accessFingerprint = digest(
      String.join(
        new List<String>{
          String.valueOf(objectDescribe.isCreateable()),
          String.valueOf(objectDescribe.isUpdateable()),
          String.valueOf(objectDescribe.isDeletable()),
          String.valueOf(
            FeatureManagement.checkPermission('Bulk_Record_Upload_Run')
          ),
          String.valueOf(
            FeatureManagement.checkPermission('Bulk_Record_Upload_Delete')
          ),
          UserInfo.getLocale()
        },
        ':'
      )
    );
    return 'bru:projection:1:0.1:' +
      process.processKey +
      ':' +
      configHash +
      ':' +
      accessFingerprint;
  }

  private static String contextFilterHashPart(
    List<BulkRecordUploadContextFilterCondition> conditions
  ) {
    List<String> parts = new List<String>();
    for (BulkRecordUploadContextFilterCondition condition : conditions) {
      parts.add(
        condition.fieldApiName +
          condition.operatorCode +
          String.join(condition.values, ',')
      );
    }
    return String.join(parts, ';');
  }

  private static String digest(String value) {
    return EncodingUtil.convertToHex(
      Crypto.generateDigest('SHA-256', Blob.valueOf(value))
    );
  }
}
