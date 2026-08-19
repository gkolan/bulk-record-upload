/** Thin Aura boundary for version 1 upload selection and submission. */
public with sharing class BulkRecordUploadController {
  @TestVisible
  private static BulkRecordUploadProjectionV1 projectionOverride;
  @TestVisible
  private static BulkRecordUploadPresentationV1 presentationOverride;

  /** Resolves the active process choices available to the running user. */
  @AuraEnabled(cacheable=true)
  public static BulkRecordUploadSelectionV1 getSelection(
    String bundleDeveloperName
  ) {
    try {
      return new BulkRecordUploadSelectionService()
        .resolve(bundleDeveloperName);
    } catch (BulkRecordUploadException error) {
      throw aura(error.getMessage());
    }
  }

  /** Returns active authorized process keys. */
  @AuraEnabled(cacheable=true)
  public static List<String> getProcessKeys() {
    try {
      return new BulkRecordUploadRequestService().listProcessKeys();
    } catch (BulkRecordUploadException error) {
      throw aura(error.getMessage());
    }
  }

  /** Returns one active, authorized process key for a fixed component instance. */
  @AuraEnabled(cacheable=true)
  public static String getProcessKey(String processKey) {
    try {
      return resolveProcessKey(processKey);
    } catch (BulkRecordUploadException error) {
      throw aura(error.getMessage());
    }
  }

  /** Returns presentation settings for one active, authorized process. */
  @AuraEnabled(cacheable=true)
  public static BulkRecordUploadPresentationV1 getProcessPresentation(
    String processKey
  ) {
    try {
      String validatedKey = resolveProcessKey(processKey);
      if (presentationOverride != null) {
        if (presentationOverride.processKey != validatedKey) {
          throw new BulkRecordUploadException('The upload process is invalid.');
        }
        return presentationOverride;
      }
      Bulk_Record_Upload_Process__mdt process = Bulk_Record_Upload_Process__mdt.getInstance(
        validatedKey
      );
      if (process == null) {
        throw new BulkRecordUploadException(
          'The upload process is unavailable.'
        );
      }
      return new BulkRecordUploadPresentationV1(
        validatedKey,
        process.Subtitle__c,
        process.Instructions__c,
        process.IconName__c
      );
    } catch (BulkRecordUploadException error) {
      throw aura(error.getMessage());
    }
  }

  /** Returns the safe CSV template header for one authorized process. */
  @AuraEnabled(cacheable=true)
  public static String getTemplate(String processKey) {
    try {
      BulkRecordUploadProjectionV1 projection = projectionOverride == null
        ? new BulkRecordUploadProjectionService().getProjection(processKey)
        : projectionOverride;
      if (projection.processKey != processKey?.trim()) {
        throw new BulkRecordUploadException('The upload process is invalid.');
      }
      List<String> headers = new List<String>();
      for (BulkRecordUploadFieldProjectionV1 field : projection.getFields()) {
        headers.add('"' + field.columnKey.replace('"', '""') + '"');
      }
      return String.join(headers, ',') + '\r\n';
    } catch (BulkRecordUploadException error) {
      throw aura(error.getMessage());
    }
  }

  /** Returns access-filtered recent upload history. */
  @AuraEnabled
  public static List<BulkRecordUploadHistoryItemV1> getHistory() {
    try {
      return new BulkRecordUploadLogService().getHistory();
    } catch (BulkRecordUploadException error) {
      throw aura(error.getMessage());
    }
  }

  /** Returns access-filtered history for one validated process. */
  @AuraEnabled
  public static List<BulkRecordUploadHistoryItemV1> getHistoryForProcess(
    String processKey
  ) {
    try {
      String validatedKey = resolveProcessKey(processKey);
      return new BulkRecordUploadLogService().getHistory(validatedKey);
    } catch (BulkRecordUploadException error) {
      throw aura(error.getMessage());
    }
  }

  private static String resolveProcessKey(String processKey) {
    BulkRecordUploadProjectionV1 projection = projectionOverride == null
      ? new BulkRecordUploadProjectionService().getProjection(processKey)
      : projectionOverride;
    if (
      projectionOverride != null &&
      projection.processKey != processKey?.trim()
    ) {
      throw new BulkRecordUploadException('The upload process is invalid.');
    }
    return projection.processKey;
  }

  /** Submits one version 1 request and returns only safe operational fields. */
  @AuraEnabled
  public static BulkRecordUploadSubmissionV1 submit(
    BulkRecordUploadSubmitRequestV1 request
  ) {
    try {
      return new BulkRecordUploadRequestService().submit(request);
    } catch (BulkRecordUploadException error) {
      throw aura(error.getMessage());
    }
  }

  private static AuraHandledException aura(String message) {
    AuraHandledException error = new AuraHandledException(message);
    error.setMessage(message);
    return error;
  }
}
