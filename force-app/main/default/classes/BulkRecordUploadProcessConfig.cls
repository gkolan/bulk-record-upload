/**
 * Immutable snapshot of one active upload-process configuration record.
 */
public class BulkRecordUploadProcessConfig {
  public String processKey { get; private set; }
  public String objectApiName { get; private set; }
  public String operation { get; private set; }
  public String previewPermission { get; private set; }
  public Integer batchSize { get; private set; }
  public Integer retentionDays { get; private set; }
  public Integer contractVersion { get; private set; }
  public String processingMode { get; private set; }
  public String processorKey { get; private set; }
  public String recordContextAction { get; private set; }
  public String hostObjectApiName { get; private set; }
  public String recordContextFieldApiName { get; private set; }
  public String recordContextSource { get; private set; }
  public String contextSearchFields { get; private set; }
  public String contextDisplayFields { get; private set; }
  public String contextFilterCriteria { get; private set; }

  /**
   * Creates a validated process snapshot from Custom Metadata.
   * @param recordValue Active subscriber process configuration.
   * @throws BulkRecordUploadException when the record violates the configuration contract.
   */
  public BulkRecordUploadProcessConfig(
    Bulk_Record_Upload_Process__mdt recordValue
  ) {
    if (recordValue == null || String.isBlank(recordValue.DeveloperName)) {
      throw new BulkRecordUploadException(
        'Process configuration requires a Developer Name.'
      );
    }
    processKey = recordValue.DeveloperName.trim();
    objectApiName = requireText(recordValue.ObjectApiName__c, 'Target object');
    operation = requireText(recordValue.Operation__c, 'Operation')
      .toUpperCase();
    previewPermission = String.isBlank(recordValue.PreviewPermissionApiName__c)
      ? null
      : recordValue.PreviewPermissionApiName__c.trim();
    batchSize = decimalToInteger(recordValue.RowsPerBatch__c, 100);
    retentionDays = decimalToInteger(recordValue.RetentionDays__c, 90);
    contractVersion = decimalToInteger(recordValue.ConfigurationVersion__c, 1);
    processingMode = String.isBlank(recordValue.ProcessingMode__c)
      ? 'STANDARD_DML'
      : recordValue.ProcessingMode__c.trim().toUpperCase();
    processorKey = String.isBlank(recordValue.ProcessorKey__c)
      ? 'STANDARD_DML'
      : recordValue.ProcessorKey__c.trim().toUpperCase();
    recordContextAction = String.isBlank(recordValue.RecordContextAction__c)
      ? 'NONE'
      : recordValue.RecordContextAction__c.trim().toUpperCase();
    hostObjectApiName = trimToNull(recordValue.HostObjectApiName__c);
    recordContextFieldApiName = trimToNull(
      recordValue.RecordContextFieldApiName__c
    );
    recordContextSource = String.isBlank(recordValue.RecordContextSource__c)
      ? 'PAGE'
      : recordValue.RecordContextSource__c.trim().toUpperCase();
    contextSearchFields = trimToNull(recordValue.ContextSearchFields__c);
    contextDisplayFields = trimToNull(recordValue.ContextDisplayFields__c);
    contextFilterCriteria = trimToNull(recordValue.ContextFilterCriteria__c);
    validateBounds();
  }

  private void validateBounds() {
    if (
      !new Set<String>{ 'INSERT', 'UPDATE', 'UPSERT', 'DELETE' }
        .contains(operation)
    ) {
      throw new BulkRecordUploadException(
        'Process operation is not supported.'
      );
    }
    if (
      !new Set<String>{ 'NONE', 'DEFAULT_PARENT', 'REQUIRE_PARENT' }
        .contains(recordContextAction) ||
      (recordContextAction != 'NONE' &&
      (String.isBlank(hostObjectApiName) ||
      String.isBlank(recordContextFieldApiName))) ||
      (recordContextAction != 'NONE' &&
      operation == 'DELETE')
    ) {
      throw new BulkRecordUploadException(
        'Process record context configuration is not supported.'
      );
    }
    if (
      !new Set<String>{ 'PAGE', 'USER_CHOICE' }.contains(recordContextSource)
    ) {
      throw new BulkRecordUploadException(
        'Process record context source is not supported.'
      );
    }
    if (batchSize < 25 || batchSize > 200) {
      throw new BulkRecordUploadException(
        'Process batch size must be between 25 and 200.'
      );
    }
    if (retentionDays < 7 || retentionDays > 365) {
      throw new BulkRecordUploadException(
        'Process retention must be between 7 and 365 days.'
      );
    }
    if (!new Set<Integer>{ 1, 2 }.contains(contractVersion)) {
      throw new BulkRecordUploadException(
        'Process contract version is not supported.'
      );
    }
    if (
      !new Set<String>{ 'STANDARD_DML', 'CUSTOM_APEX' }
        .contains(processingMode) ||
      !BulkRecordUploadProcessors.isRegistered(processorKey)
    ) {
      throw new BulkRecordUploadException(
        'Process processor configuration is not supported.'
      );
    }
  }

  private static String requireText(String value, String label) {
    if (String.isBlank(value)) {
      throw new BulkRecordUploadException(label + ' is required.');
    }
    return value.trim();
  }

  private static Integer decimalToInteger(Decimal value, Integer defaultValue) {
    return value == null ? defaultValue : value.intValue();
  }

  private static String trimToNull(String value) {
    return String.isBlank(value) ? null : value.trim();
  }
}
