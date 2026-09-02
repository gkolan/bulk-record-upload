/** Validates a submission and coordinates log, Files, staging, and one async enqueue. */
public with sharing class BulkRecordUploadRequestService {
  private static final Integer MAX_BASE64_CHARACTERS = 2796204;
  // Blob.toString() silently substitutes this character for byte sequences
  // that are not valid UTF-8 instead of throwing, so its presence is the
  // only reliable signal that the uploaded file was not UTF-8 encoded.
  private static final String UNICODE_REPLACEMENT_CHARACTER = String.fromCharArray(
    new List<Integer>{ 65533 }
  );
  @TestVisible
  private static BulkRecordUploadProjection projectionOverride;

  /** Submits one bounded CSV or returns its 24-hour idempotent upload identity. */
  public BulkRecordUploadSubmission submit(
    BulkRecordUploadSubmitRequest request
  ) {
    requireRequest(request);
    request.processKey = request.processKey.trim();
    if (
      !String.isBlank(request.bundleDeveloperName) &&
      !BulkRecordUploadSelectionService.isProcessInActiveBundle(
        request.processKey,
        request.bundleDeveloperName
      )
    ) {
      throw new BulkRecordUploadException(
        'This upload process is not available.'
      );
    }
    Blob csvBlob;
    try {
      csvBlob = EncodingUtil.base64Decode(request.contentBase64);
    } catch (Exception error) {
      throw new BulkRecordUploadException(
        'The uploaded file encoding is invalid.'
      );
    }
    if (csvBlob.size() > BulkRecordUploadRuntimeContract.MAX_CSV_BYTES) {
      throw new BulkRecordUploadException(
        'The CSV file exceeds the 2 MB limit.'
      );
    }
    String csvText;
    try {
      csvText = csvBlob.toString();
    } catch (Exception error) {
      throw new BulkRecordUploadException(
        'The CSV file must use UTF-8 encoding.'
      );
    }
    if (csvText.contains(UNICODE_REPLACEMENT_CHARACTER)) {
      throw new BulkRecordUploadException(
        'The CSV file must use UTF-8 encoding.'
      );
    }
    BulkRecordUploadProjection projection = projectionOverride == null
      ? new BulkRecordUploadProjectionService()
          .getProjection(request.processKey)
      : projectionOverride;
    BulkRecordUploadParsedCsv parsed = new BulkRecordUploadCsvReader()
      .parse(csvText);
    new BulkRecordUploadRequestValidator().validate(parsed, projection);
    Id contextRecordId = new BulkRecordUploadRecordContextService()
      .validateContext(projection, request.contextRecordId);
    BulkRecordUploadLogService.Creation creation = new BulkRecordUploadLogService()
      .createOrFindWithState(
        projection.processKey,
        request.idempotencyKey,
        parsed.rows.size(),
        projection.retentionDays,
        contextRecordId,
        projection.configHash
      );
    if (!creation.wasCreated) {
      return new BulkRecordUploadSubmission(
        creation.upload.Id,
        creation.upload.Status__c,
        true
      );
    }
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
      String.isBlank(request.fileName) ||
      !request.fileName.trim().toLowerCase().endsWith('.csv') ||
      String.isBlank(request.contentBase64) ||
      request.contentBase64.length() > MAX_BASE64_CHARACTERS ||
      String.isBlank(request.idempotencyKey) ||
      !Pattern.matches('^[a-fA-F0-9]{64}$', request.idempotencyKey)
    ) {
      throw new BulkRecordUploadException('The upload request is invalid.');
    }
  }
}
