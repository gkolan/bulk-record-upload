/**
 * Resolves the four supported operation strategies from an explicit
 * allowlist. Closed set, per ADR-0007: insert/update/upsert/delete are
 * package-owned code constants a subscriber selects by configuration, not an
 * extension point. Not named `Registry` for that reason.
 */
public with sharing class BulkRecordUploadOperations {
  private static final Set<String> OPERATIONS = new Set<String>{
    'INSERT',
    'UPDATE',
    'UPSERT',
    'DELETE'
  };

  /** Returns a strategy for an approved operation code. */
  public BulkRecordUploadOperationStrategy resolve(String operation) {
    String canonical = operation == null
      ? null
      : operation.trim().toUpperCase();
    if (!OPERATIONS.contains(canonical)) {
      throw new BulkRecordUploadException(
        'The configured operation is not supported.'
      );
    }
    return new BulkRecordUploadOperationValidator(canonical);
  }
}
