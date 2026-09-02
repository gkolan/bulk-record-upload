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

    String configHash = BulkRecordUploadProjectionFingerprint.configHash(
      configuration,
      extensionClassNames,
      contextProjection
    );
    String cacheKey = BulkRecordUploadProjectionFingerprint.cacheKey(
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
    Set<String> targetFieldNames = new Set<String>();
    for (BulkRecordUploadFieldConfig fieldConfig : fieldConfigs) {
      BulkRecordUploadProjectionValidator.validateUnique(
        fieldConfig,
        columnKeys,
        sequences,
        targetFieldNames
      );
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
      BulkRecordUploadProjectionValidator.validateSupportedType(fieldDescribe);
      BulkRecordUploadProjectionValidator.validateFieldAccess(
        fieldConfig,
        fieldDescribe,
        configuration.process.operation
      );
      BulkRecordUploadProjectionValidator.validateRange(
        fieldConfig,
        fieldDescribe
      );
      BulkRecordUploadProjectionValidator.validateUpsertKey(
        fieldConfig,
        fieldDescribe
      );
      BulkRecordUploadProjectionValidator.validateLookupMatchField(
        fieldConfig,
        fieldDescribe
      );
      BulkRecordUploadProjectionValidator.validateBuiltInMergeStrategy(
        fieldConfig,
        fieldDescribe
      );
      projectedFields.add(createFieldProjection(fieldConfig, fieldDescribe));
    }
    BulkRecordUploadProjectionValidator.validateSourceTemplates(
      projectedFields,
      rawColumnKeys
    );
    BulkRecordUploadProjectionValidator.validateCustomMergeStrategies(
      projectedFields
    );
    BulkRecordUploadProjectionValidator.validateRecordContext(
      configuration.process,
      objectDescribe
    );
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
    Set<String> canonicalNames = new Set<String>();
    for (
      BulkRecordUploadExtensionConfig extensionConfig : configuration.getExtensions()
    ) {
      if (!canonicalNames.add(extensionConfig.className.toLowerCase())) {
        throw new BulkRecordUploadException(
          'An extension class is registered more than once for this process.'
        );
      }
      classNames.add(extensionConfig.className);
    }
    return classNames;
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
}
