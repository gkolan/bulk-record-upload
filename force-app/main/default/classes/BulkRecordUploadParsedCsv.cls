/**
 * Immutable parsed CSV containing normalized headers and bounded rows.
 */
public class BulkRecordUploadParsedCsv {
  public List<String> headers { get; private set; }
  public List<BulkRecordUploadRow> rows { get; private set; }

  /**
   * Creates an immutable parsed CSV.
   * @param headers Normalized unique headers.
   * @param rows Parsed data rows with physical correlation.
   */
  public BulkRecordUploadParsedCsv(
    List<String> headers,
    List<BulkRecordUploadRow> rows
  ) {
    this.headers = new List<String>(headers);
    this.rows = new List<BulkRecordUploadRow>(rows);
  }

  /** @return Defensive copy of normalized headers. */
  public List<String> getHeaders() {
    return new List<String>(headers);
  }

  /** @return Defensive copy of parsed rows. */
  public List<BulkRecordUploadRow> getRows() {
    return new List<BulkRecordUploadRow>(rows);
  }
}
