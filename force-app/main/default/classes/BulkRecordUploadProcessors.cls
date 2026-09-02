/**
 * Resolves only code-reviewed processor keys; administrator text is never
 * instantiated as a class. Closed set, per ADR-0007: the DML/persistence
 * path stays package-owned so user-mode enforcement cannot be bypassed.
 * Not named `Registry` for that reason -- `BulkRecordUploadExtensionRegistry`
 * is the package's one open extension point.
 */
public with sharing class BulkRecordUploadProcessors {
  public static final String STANDARD_DML = 'STANDARD_DML';
  /** Returns a fresh trusted processor. */
  public BulkRecordUploadProcessor resolve(String processorKey) {
    if (String.isBlank(processorKey) || processorKey == STANDARD_DML) {
      return new BulkRecordUploadStandardProcessor();
    }
    throw new BulkRecordUploadException(
      'The configured custom processor is not registered.'
    );
  }
  /** Reports whether a processor key is registered. */
  public static Boolean isRegistered(String processorKey) {
    return String.isBlank(processorKey) || processorKey == STANDARD_DML;
  }
}
