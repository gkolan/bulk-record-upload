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
  public BulkRecordUploadProjectionV1 getProjection(String processKey) {
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

    String configHash = createConfigHash(configuration, extensionClassNames);
    String cacheKey = createCacheKey(
      configuration.process,
      configHash,
      objectDescribe
    );
    BulkRecordUploadProjectionV1 cached = projectionCache.find(cacheKey);
    if (cached != null) {
      return cached;
    }

    BulkRecordUploadProjectionV1 projection = buildProjection(
      configuration,
      objectDescribe,
      configHash,
      extensionClassNames
    );
    projectionCache.put(cacheKey, projection);
    return projection;
  }

  private BulkRecordUploadProjectionV1 buildProjection(
    BulkRecordUploadConfigRepository.Configuration configuration,
    Schema.DescribeSObjectResult objectDescribe,
    String configHash,
    List<String> extensionClassNames
  ) {
    List<BulkRecordUploadFieldConfigV1> fieldConfigs = configuration.getFields();
    if (fieldConfigs.isEmpty() || fieldConfigs.size() > 100) {
      throw new BulkRecordUploadException(
        'Process must configure between 1 and 100 active fields.'
      );
    }
    Map<String, Schema.SObjectField> fieldsByName = objectDescribe.fields.getMap();
    List<BulkRecordUploadFieldProjectionV1> projectedFields = new List<BulkRecordUploadFieldProjectionV1>();
    Set<String> columnKeys = new Set<String>();
    Set<Integer> sequences = new Set<Integer>();
    for (BulkRecordUploadFieldConfigV1 fieldConfig : fieldConfigs) {
      validateUnique(fieldConfig, columnKeys, sequences);
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
      projectedFields.add(createFieldProjection(fieldConfig, fieldDescribe));
    }
    validateRecordContext(configuration.process, objectDescribe);
    return new BulkRecordUploadProjectionV1(
      configuration.process.processKey,
      configHash,
      objectDescribe.getName(),
      configuration.process.operation,
      extensionClassNames,
      configuration.process.processorKey,
      configuration.process.recordContextAction,
      configuration.process.hostObjectApiName,
      configuration.process.recordContextFieldApiName,
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
      BulkRecordUploadExtensionConfigV1 extensionConfig : configuration.getExtensions()
    ) {
      classNames.add(extensionConfig.className);
    }
    return classNames;
  }

  private static void validateRecordContext(
    BulkRecordUploadProcessConfigV1 process,
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

  private static BulkRecordUploadFieldProjectionV1 createFieldProjection(
    BulkRecordUploadFieldConfigV1 config,
    Schema.DescribeFieldResult fieldDescribe
  ) {
    return new BulkRecordUploadFieldProjectionV1(
      config.columnKey,
      config.displayLabel,
      fieldDescribe.getName(),
      String.valueOf(fieldDescribe.getType()),
      config.existingValueAction,
      config.blankValueAction,
      config.textSeparator,
      config.duplicateTextAction,
      config.overflowAction,
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
    BulkRecordUploadFieldConfigV1 config,
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

  private static String createConfigHash(
    BulkRecordUploadConfigRepository.Configuration configuration,
    List<String> extensionClassNames
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
      String.valueOf(configuration.process.batchSize),
      String.valueOf(configuration.process.retentionDays)
    };
    for (
      BulkRecordUploadFieldConfigV1 fieldConfig : configuration.getFields()
    ) {
      parts.add(
        String.join(
          new List<String>{
            fieldConfig.columnKey,
            fieldConfig.fieldApiName,
            fieldConfig.existingValueAction,
            fieldConfig.blankValueAction,
            fieldConfig.textSeparator,
            fieldConfig.duplicateTextAction,
            fieldConfig.overflowAction,
            String.valueOf(fieldConfig.sequence)
          },
          ':'
        )
      );
    }
    return digest(String.join(parts, '|'));
  }

  private static String createCacheKey(
    BulkRecordUploadProcessConfigV1 process,
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

  private static String digest(String value) {
    return EncodingUtil.convertToHex(
      Crypto.generateDigest('SHA-256', Blob.valueOf(value))
    );
  }
}
