/**
 * Immutable version 1 parsed CSV containing normalized headers and bounded rows.
 */
public class BulkRecordUploadParsedCsvV1 {
  public List<String> headers { get; private set; }
  public List<BulkRecordUploadRowV1> rows { get; private set; }

  /**
   * Creates an immutable parsed CSV.
   * @param headers Normalized unique headers.
   * @param rows Parsed data rows with physical correlation.
   */
  public BulkRecordUploadParsedCsvV1(
    List<String> headers,
    List<BulkRecordUploadRowV1> rows
  ) {
    this.headers = new List<String>(headers);
    this.rows = new List<BulkRecordUploadRowV1>(rows);
  }

  /** @return Defensive copy of normalized headers. */
  public List<String> getHeaders() {
    return new List<String>(headers);
  }

  /** @return Defensive copy of parsed rows. */
  public List<BulkRecordUploadRowV1> getRows() {
    return new List<BulkRecordUploadRowV1>(rows);
  }
}
