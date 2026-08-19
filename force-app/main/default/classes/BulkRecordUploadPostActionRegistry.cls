/** Resolves only reviewed post-processing actions. */
public with sharing class BulkRecordUploadPostActionRegistry {
  public static final String NONE_V1 = 'NONE_V1';
  /** Returns a trusted action; blank means no-op. */
  public BulkRecordUploadPostActionV1 resolve(String actionKey) {
    if (String.isBlank(actionKey) || actionKey == NONE_V1) {
      return new BulkRecordUploadNoOpPostActionV1();
    }
    throw new BulkRecordUploadException(
      'The configured post-processing action is not registered.'
    );
  }
  /** Reports whether an action is registered. */
  public static Boolean isRegistered(String actionKey) {
    return String.isBlank(actionKey) || actionKey == NONE_V1;
  }
}
