/**
 * Validates parsed CSV headers against the compact approved projection before staging.
 */
public class BulkRecordUploadRequestValidator {
  /**
   * Requires received headers to be configured and every required configured column to exist.
   * @param parsedCsv Parsed bounded CSV.
   * @param projection Approved compact projection.
   * @throws BulkRecordUploadException for unknown or missing required columns and empty data.
   */
  public void validate(
    BulkRecordUploadParsedCsvV1 parsedCsv,
    BulkRecordUploadProjectionV1 projection
  ) {
    if (parsedCsv == null || projection == null) {
      throw new BulkRecordUploadException(
        'CSV validation context is required.'
      );
    }
    if (parsedCsv.rows.isEmpty()) {
      throw new BulkRecordUploadException(
        'The CSV must contain at least one data row.'
      );
    }
    Set<String> receivedHeaders = new Set<String>(parsedCsv.getHeaders());
    Set<String> configuredHeaders = new Set<String>();
    Set<String> requiredHeaders = new Set<String>();
    for (
      BulkRecordUploadFieldProjectionV1 fieldProjection : projection.getFields()
    ) {
      configuredHeaders.add(fieldProjection.columnKey);
      if (fieldProjection.isRequired) {
        requiredHeaders.add(fieldProjection.columnKey);
      }
    }
    Set<String> unknownHeaders = receivedHeaders.clone();
    unknownHeaders.removeAll(configuredHeaders);
    if (!unknownHeaders.isEmpty()) {
      throw new BulkRecordUploadException(
        'The CSV contains a column that is not configured.'
      );
    }
    requiredHeaders.removeAll(receivedHeaders);
    if (!requiredHeaders.isEmpty()) {
      throw new BulkRecordUploadException(
        'The CSV is missing a required configured column.'
      );
    }
  }
}
