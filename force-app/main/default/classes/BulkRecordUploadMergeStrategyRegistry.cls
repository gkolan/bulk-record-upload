/**
 * Resolves a subscriber-registered custom merge strategy class name into a
 * validated package-owned instance. Administrator text is matched only
 * against this explicit allowlist and is never used for dynamic instantiation.
 */
public with sharing class BulkRecordUploadMergeStrategyRegistry {
  /**
   * Resolves one validated custom merge strategy instance.
   * @param className Exact Apex class name implementing the strategy interface.
   * @throws BulkRecordUploadException naming the class when it does not
   *   resolve, does not instantiate, or does not implement the interface.
   */
  public BulkRecordUploadFieldMergeStrategy resolve(String className) {
    String trimmedName = String.isBlank(className) ? null : className.trim();
    if (trimmedName == 'BulkRecordUploadLongerTextStrategy') {
      return new BulkRecordUploadLongerTextStrategy();
    }
    throw new BulkRecordUploadException(
      'The configured custom merge strategy class "' +
        String.valueOf(trimmedName) +
        '" is not registered.'
    );
  }
}
