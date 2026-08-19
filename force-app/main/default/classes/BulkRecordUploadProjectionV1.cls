/**
 * Immutable version 1 process projection containing only configured fields and safe access decisions.
 */
public class BulkRecordUploadProjectionV1 {
  public static final Integer CONTRACT_VERSION = 1;

  public String processKey { get; private set; }
  public String configHash { get; private set; }
  public String objectApiName { get; private set; }
  public String operation { get; private set; }
  public String handlerKey { get; private set; }
  public Integer batchSize { get; private set; }
  public Integer retentionDays { get; private set; }
  public String processorKey { get; private set; }
  public String postProcessingAction { get; private set; }
  public String recordContextAction { get; private set; }
  public String hostObjectApiName { get; private set; }
  public String recordContextFieldApiName { get; private set; }
  public List<BulkRecordUploadFieldProjectionV1> fields { get; private set; }

  /**
   * Creates an immutable process projection.
   * @param processKey Stable subscriber process key.
   * @param configHash Hash of configuration inputs.
   * @param objectApiName Schema-resolved target object API name.
   * @param operation Approved operation code.
   * @param handlerKey Trusted registered handler key.
   * @param batchSize Bounded rows processed per chunk.
   * @param retentionDays Bounded retention copied to the upload record.
   * @param fields Ordered compact field projection.
   */
  public BulkRecordUploadProjectionV1(
    String processKey,
    String configHash,
    String objectApiName,
    String operation,
    String handlerKey,
    Integer batchSize,
    Integer retentionDays,
    List<BulkRecordUploadFieldProjectionV1> fields
  ) {
    this(
      processKey,
      configHash,
      objectApiName,
      operation,
      handlerKey,
      'STANDARD_DML_V1',
      null,
      'NONE',
      null,
      null,
      batchSize,
      retentionDays,
      fields
    );
  }

  /** Creates a version 2 process projection with registered processing extensions. */
  public BulkRecordUploadProjectionV1(
    String processKey,
    String configHash,
    String objectApiName,
    String operation,
    String handlerKey,
    String processorKey,
    String postProcessingAction,
    Integer batchSize,
    Integer retentionDays,
    List<BulkRecordUploadFieldProjectionV1> fields
  ) {
    this(
      processKey,
      configHash,
      objectApiName,
      operation,
      handlerKey,
      processorKey,
      postProcessingAction,
      'NONE',
      null,
      null,
      batchSize,
      retentionDays,
      fields
    );
  }

  /** Creates a version 2 projection with secure record-page context settings. */
  public BulkRecordUploadProjectionV1(
    String processKey,
    String configHash,
    String objectApiName,
    String operation,
    String handlerKey,
    String processorKey,
    String postProcessingAction,
    String recordContextAction,
    String hostObjectApiName,
    String recordContextFieldApiName,
    Integer batchSize,
    Integer retentionDays,
    List<BulkRecordUploadFieldProjectionV1> fields
  ) {
    this.processKey = requireText(processKey, 'processKey');
    this.configHash = requireText(configHash, 'configHash');
    this.objectApiName = requireText(objectApiName, 'objectApiName');
    this.operation = requireText(operation, 'operation');
    this.handlerKey = requireText(handlerKey, 'handlerKey');
    this.processorKey = requireText(processorKey, 'processorKey');
    this.postProcessingAction = String.isBlank(postProcessingAction)
      ? null
      : postProcessingAction.trim();
    this.recordContextAction = String.isBlank(recordContextAction)
      ? 'NONE'
      : recordContextAction.trim();
    this.hostObjectApiName = String.isBlank(hostObjectApiName)
      ? null
      : hostObjectApiName.trim();
    this.recordContextFieldApiName = String.isBlank(recordContextFieldApiName)
      ? null
      : recordContextFieldApiName.trim();
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
    this.fields = new List<BulkRecordUploadFieldProjectionV1>(fields);
  }

  /**
   * Returns a defensive copy of the ordered fields.
   * @return Ordered compact field projections.
   */
  public List<BulkRecordUploadFieldProjectionV1> getFields() {
    return new List<BulkRecordUploadFieldProjectionV1>(fields);
  }

  private static String requireText(String value, String propertyName) {
    if (String.isBlank(value)) {
      throw new BulkRecordUploadException(propertyName + ' is required.');
    }
    return value.trim();
  }
}
