/** Thin Aura boundary for upload selection and submission. */
public with sharing class BulkRecordUploadController {
  @TestVisible
  private static BulkRecordUploadProjection projectionOverride;
  @TestVisible
  private static BulkRecordUploadPresentation presentationOverride;

  /** Resolves the active process choices available to the running user. */
  @AuraEnabled(cacheable=true)
  public static BulkRecordUploadSelection getSelection(
    String bundleDeveloperName
  ) {
    try {
      return new BulkRecordUploadSelectionService()
        .resolve(bundleDeveloperName);
    } catch (BulkRecordUploadException error) {
      throw aura(error.getMessage());
    }
  }

  /** Returns presentation settings for one active, authorized process. */
  @AuraEnabled(cacheable=true)
  public static BulkRecordUploadPresentation getProcessPresentation(
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
      BulkRecordUploadProjection projection = projectionOverride == null
        ? new BulkRecordUploadProjectionService().getProjection(validatedKey)
        : projectionOverride;
      return new BulkRecordUploadPresentation(
        validatedKey,
        process.Subtitle__c,
        process.Instructions__c,
        process.IconName__c,
        projection
      );
    } catch (BulkRecordUploadException error) {
      throw aura(error.getMessage());
    }
  }

  /** Returns the safe CSV template header for one authorized process. */
  @AuraEnabled(cacheable=true)
  public static String getTemplate(String processKey) {
    try {
      BulkRecordUploadProjection projection = projectionOverride == null
        ? new BulkRecordUploadProjectionService().getProjection(processKey)
        : projectionOverride;
      if (projection.processKey != processKey?.trim()) {
        throw new BulkRecordUploadException('The upload process is invalid.');
      }
      List<String> headers = new List<String>();
      for (BulkRecordUploadFieldProjection field : projection.getFields()) {
        if (String.isNotBlank(field.sourceTemplate)) {
          continue;
        }
        headers.add('"' + field.columnKey.replace('"', '""') + '"');
      }
      return String.join(headers, ',') + '\r\n';
    } catch (BulkRecordUploadException error) {
      throw aura(error.getMessage());
    }
  }

  /**
   * Returns access-filtered upload history. A blank processKey returns
   * recent history across every process the running user may see; a
   * populated processKey is validated and scopes history to that process.
   */
  @AuraEnabled
  public static List<BulkRecordUploadHistoryItem> getHistory(
    String processKey
  ) {
    try {
      if (String.isBlank(processKey)) {
        return new BulkRecordUploadLogService().getHistory();
      }
      String validatedKey = resolveProcessKey(processKey);
      return new BulkRecordUploadLogService().getHistory(validatedKey);
    } catch (BulkRecordUploadException error) {
      throw aura(error.getMessage());
    }
  }

  private static String resolveProcessKey(String processKey) {
    BulkRecordUploadProjection projection = projectionOverride == null
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

  /** Submits one upload request and returns only safe operational fields. */
  @AuraEnabled
  public static BulkRecordUploadSubmission submit(
    BulkRecordUploadSubmitRequest request
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
