/**
 * Immutable process projection containing only configured fields and safe access decisions.
 */
public class BulkRecordUploadProjection {
  public static final Integer CONTRACT_VERSION = 1;

  public String processKey { get; private set; }
  public String configHash { get; private set; }
  public String objectApiName { get; private set; }
  public String operation { get; private set; }
  public List<String> extensionClassNames { get; private set; }
  public Integer batchSize { get; private set; }
  public Integer retentionDays { get; private set; }
  public String processorKey { get; private set; }
  public String recordContextAction { get; private set; }
  public String hostObjectApiName { get; private set; }
  public String recordContextFieldApiName { get; private set; }
  public BulkRecordUploadContextProjection contextProjection {
    get;
    private set;
  }
  public List<BulkRecordUploadFieldProjection> fields { get; private set; }

  /**
   * Creates an immutable process projection.
   * @param processKey Stable subscriber process key.
   * @param configHash Hash of configuration inputs.
   * @param objectApiName Schema-resolved target object API name.
   * @param operation Approved operation code.
   * @param extensionClassNames Ordered, validated registered extension class names.
   * @param batchSize Bounded rows processed per chunk.
   * @param retentionDays Bounded retention copied to the upload record.
   * @param fields Ordered compact field projection.
   */
  public BulkRecordUploadProjection(
    String processKey,
    String configHash,
    String objectApiName,
    String operation,
    List<String> extensionClassNames,
    Integer batchSize,
    Integer retentionDays,
    List<BulkRecordUploadFieldProjection> fields
  ) {
    this(
      processKey,
      configHash,
      objectApiName,
      operation,
      extensionClassNames,
      'STANDARD_DML',
      'NONE',
      null,
      null,
      null,
      batchSize,
      retentionDays,
      fields
    );
  }

  /** Creates a process projection with a registered processor. */
  public BulkRecordUploadProjection(
    String processKey,
    String configHash,
    String objectApiName,
    String operation,
    List<String> extensionClassNames,
    String processorKey,
    Integer batchSize,
    Integer retentionDays,
    List<BulkRecordUploadFieldProjection> fields
  ) {
    this(
      processKey,
      configHash,
      objectApiName,
      operation,
      extensionClassNames,
      processorKey,
      'NONE',
      null,
      null,
      null,
      batchSize,
      retentionDays,
      fields
    );
  }

  /** Creates a projection with secure record-page context settings. */
  public BulkRecordUploadProjection(
    String processKey,
    String configHash,
    String objectApiName,
    String operation,
    List<String> extensionClassNames,
    String processorKey,
    String recordContextAction,
    String hostObjectApiName,
    String recordContextFieldApiName,
    BulkRecordUploadContextProjection contextProjection,
    Integer batchSize,
    Integer retentionDays,
    List<BulkRecordUploadFieldProjection> fields
  ) {
    this.processKey = requireText(processKey, 'processKey');
    this.configHash = requireText(configHash, 'configHash');
    this.objectApiName = requireText(objectApiName, 'objectApiName');
    this.operation = requireText(operation, 'operation');
    if (
      extensionClassNames != null &&
      extensionClassNames.size() >
      BulkRecordUploadRuntimeContract.MAX_EXTENSIONS_PER_PROCESS
    ) {
      throw new BulkRecordUploadException(
        'Too many extensions are registered for this process.'
      );
    }
    this.extensionClassNames = extensionClassNames == null
      ? new List<String>()
      : new List<String>(extensionClassNames);
    this.processorKey = requireText(processorKey, 'processorKey');
    this.recordContextAction = String.isBlank(recordContextAction)
      ? 'NONE'
      : recordContextAction.trim();
    this.hostObjectApiName = String.isBlank(hostObjectApiName)
      ? null
      : hostObjectApiName.trim();
    this.recordContextFieldApiName = String.isBlank(recordContextFieldApiName)
      ? null
      : recordContextFieldApiName.trim();
    this.contextProjection = contextProjection == null
      ? new BulkRecordUploadContextProjection(
          'PAGE',
          null,
          null,
          null,
          null,
          null
        )
      : contextProjection;
    if (batchSize == null || batchSize < 25 || batchSize > 200) {
      throw new BulkRecordUploadException(
        'Batch size must be between 25 and 200.'
      );
    }
    if (retentionDays == null || retentionDays < 7 || retentionDays > 365) {
      throw new BulkRecordUploadException(
        'Retention days must be between 7 and 365.'
      );
    }
    if (fields == null || fields.isEmpty() || fields.size() > 100) {
      throw new BulkRecordUploadException(
        'Projection must contain between 1 and 100 fields.'
      );
    }
    this.batchSize = batchSize;
    this.retentionDays = retentionDays;
    this.fields = new List<BulkRecordUploadFieldProjection>(fields);
  }

  /**
   * Returns a defensive copy of the ordered fields.
   * @return Ordered compact field projections.
   */
  public List<BulkRecordUploadFieldProjection> getFields() {
    return new List<BulkRecordUploadFieldProjection>(fields);
  }

  private static String requireText(String value, String propertyName) {
    if (String.isBlank(value)) {
      throw new BulkRecordUploadException(propertyName + ' is required.');
    }
    return value.trim();
  }
}
