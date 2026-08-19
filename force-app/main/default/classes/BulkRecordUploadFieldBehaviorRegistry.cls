/** Resolves field behaviors from the reviewed version 1 allowlist. */
public with sharing class BulkRecordUploadFieldBehaviorRegistry {
  private static final Set<String> KEYS = new Set<String>{
    'REPLACE',
    'APPEND',
    'PREPEND',
    'CLEAR_WHEN_BLANK'
  };

  /** Returns a field behavior for a trusted key. */
  public BulkRecordUploadFieldBehaviorV1 resolve(String behavior) {
    String canonical = behavior == null ? null : behavior.trim().toUpperCase();
    if (!KEYS.contains(canonical)) {
      throw new BulkRecordUploadException(
        'The configured field behavior is not registered.'
      );
    }
    return new BulkRecordUploadFieldBehavior(canonical);
  }
}
