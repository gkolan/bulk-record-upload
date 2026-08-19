/** Resolves the four version 1 operation strategies from an explicit allowlist. */
public with sharing class BulkRecordUploadOperationRegistry {
  private static final Set<String> OPERATIONS = new Set<String>{
    'INSERT',
    'UPDATE',
    'UPSERT',
    'DELETE'
  };

  /** Returns a strategy for an approved operation code. */
  public BulkRecordUploadOperationStrategyV1 resolve(String operation) {
    String canonical = operation == null
      ? null
      : operation.trim().toUpperCase();
    if (!OPERATIONS.contains(canonical)) {
      throw new BulkRecordUploadException(
        'The configured operation is not supported.'
      );
    }
    return new BulkRecordUploadOperationStrategy(canonical);
  }
}
