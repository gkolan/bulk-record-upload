/** Resolves only code-reviewed versioned handler keys. */
public with sharing class BulkRecordUploadHandlerRegistry {
  public static final String STANDARD_V1 = 'STANDARD_V1';
  public static final String TRIM_TEXT_V1 = 'TRIM_TEXT_V1';

  /** Returns a fresh trusted handler for the supplied registry key. */
  public BulkRecordUploadHandlerV1 resolve(String handlerKey) {
    if (handlerKey == STANDARD_V1) {
      return new BulkRecordUploadStandardHandlerV1();
    }
    if (handlerKey == TRIM_TEXT_V1) {
      return new BulkRecordUploadTrimHandlerV1();
    }
    throw new BulkRecordUploadException(
      'The configured handler is not registered.'
    );
  }

  /** Reports whether a key is part of the reviewed registry. */
  public static Boolean isRegistered(String handlerKey) {
    return handlerKey == STANDARD_V1 || handlerKey == TRIM_TEXT_V1;
  }
}
