/**
 * Resolves a subscriber-registered custom merge strategy class name into a
 * validated instance. A class name is never trusted as-is: it must resolve
 * through Type.forName, instantiate, and be assignable to
 * BulkRecordUploadFieldMergeStrategy. Any failure is a configuration error
 * naming the class, never a silent skip. Called at every merge, so a class
 * removed or broken after configuration is caught before it can run.
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
    Object instance;
    try {
      Type strategyType = trimmedName == null
        ? null
        : Type.forName(trimmedName);
      instance = strategyType == null ? null : strategyType.newInstance();
    } catch (Exception error) {
      instance = null;
    }
    if (!(instance instanceof BulkRecordUploadFieldMergeStrategy)) {
      throw new BulkRecordUploadException(
        'The configured custom merge strategy class "' +
          String.valueOf(trimmedName) +
          '" is not registered.'
      );
    }
    return (BulkRecordUploadFieldMergeStrategy) instance;
  }
}
