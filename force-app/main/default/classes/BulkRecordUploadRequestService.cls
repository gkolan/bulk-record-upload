/** Validates a submission and coordinates log, Files, staging, and one async enqueue. */
public with sharing class BulkRecordUploadRequestService {
  @TestVisible
  private static BulkRecordUploadProjection projectionOverride;

  /** Submits one bounded CSV or returns its 24-hour idempotent upload identity. */
  public BulkRecordUploadSubmission submit(
    BulkRecordUploadSubmitRequest request
  ) {
    requireRequest(request);
    Blob csvBlob;
    try {
      csvBlob = EncodingUtil.base64Decode(request.contentBase64);
    } catch (Exception error) {
      throw new BulkRecordUploadException(
        'The uploaded file encoding is invalid.'
      );
    }
    BulkRecordUploadProjection projection = projectionOverride == null
      ? new BulkRecordUploadProjectionService()
          .getProjection(request.processKey)
      : projectionOverride;
    BulkRecordUploadParsedCsv parsed = new BulkRecordUploadCsvReader()
      .parse(csvBlob.toString());
    new BulkRecordUploadRequestValidator().validate(parsed, projection);
    Id contextRecordId = new BulkRecordUploadRecordContextService()
      .validateContext(projection, request.contextRecordId);
    BulkRecordUploadLogService.Creation creation = new BulkRecordUploadLogService()
      .createOrFindWithState(
        projection.processKey,
        request.idempotencyKey,
        parsed.rows.size(),
        projection.retentionDays,
        contextRecordId
      );
    if (!creation.wasCreated) {
      return new BulkRecordUploadSubmission(
        creation.upload.Id,
        creation.upload.Status__c,
        true
      );
    }
    enforceConcurrency(creation.upload, projection.processKey);
    new BulkRecordUploadFileService()
      .createInputFile(creation.upload.Id, csvBlob, request.fileName);
    new BulkRecordUploadStagingService()
      .stage(creation.upload.Id, parsed.rows, projection.batchSize);
    new BulkRecordUploadOrchestrator().start(creation.upload.Id);
    return new BulkRecordUploadSubmission(creation.upload.Id, 'QUEUED', false);
  }

  private static void requireRequest(BulkRecordUploadSubmitRequest request) {
    if (
      request == null ||
      String.isBlank(request.processKey) ||
      String.isBlank(request.contentBase64) ||
      String.isBlank(request.idempotencyKey) ||
      !Pattern.matches('^[a-fA-F0-9]{64}$', request.idempotencyKey)
    ) {
      throw new BulkRecordUploadException('The upload request is invalid.');
    }
  }

  private static void enforceConcurrency(
    Bulk_Record_Upload__c created,
    String processKey
  ) {
    Set<String> active = new Set<String>{
      'QUEUED',
      'VALIDATING',
      'PROCESSING'
    };
    Integer userProcessCount = [
      SELECT COUNT()
      FROM Bulk_Record_Upload__c
      WHERE
        CreatedById = :UserInfo.getUserId()
        AND ProcessDeveloperName__c = :processKey
        AND Status__c IN :active
      WITH SYSTEM_MODE
    ];
    Integer orgCount = [
      SELECT COUNT()
      FROM Bulk_Record_Upload__c
      WHERE Status__c IN :active
      WITH SYSTEM_MODE
    ];
    if (userProcessCount > 1 || orgCount > 10) {
      delete as system created;
      throw new BulkRecordUploadException(
        'The concurrent upload limit has been reached.'
      );
    }
  }
}
