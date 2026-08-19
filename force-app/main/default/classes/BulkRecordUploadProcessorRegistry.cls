/** Resolves only code-reviewed processor keys; administrator text is never instantiated as a class. */
public with sharing class BulkRecordUploadProcessorRegistry {
  public static final String STANDARD_DML_V1 = 'STANDARD_DML_V1';
  /** Returns a fresh trusted processor. */
  public BulkRecordUploadProcessorV1 resolve(String processorKey) {
    if (String.isBlank(processorKey) || processorKey == STANDARD_DML_V1) {
      return new BulkRecordUploadStandardProcessorV1();
    }
    throw new BulkRecordUploadException(
      'The configured custom processor is not registered.'
    );
  }
  /** Reports whether a processor key is registered. */
  public static Boolean isRegistered(String processorKey) {
    return String.isBlank(processorKey) || processorKey == STANDARD_DML_V1;
  }
}
