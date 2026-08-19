/**
 * One parsed version 1 CSV row with stable physical correlation.
 */
public class BulkRecordUploadRowV1 {
  public Integer rowNumber { get; private set; }
  public Map<String, String> valuesByColumn { get; private set; }

  /**
   * Creates a parsed row value.
   * @param rowNumber Physical one-based CSV row number, including the header row.
   * @param valuesByColumn Values keyed by normalized configured column key.
   */
  public BulkRecordUploadRowV1(
    Integer rowNumber,
    Map<String, String> valuesByColumn
  ) {
    if (rowNumber == null || rowNumber < 2) {
      throw new BulkRecordUploadException(
        'Data row number must be at least 2.'
      );
    }
    if (valuesByColumn == null) {
      throw new BulkRecordUploadException('Row values are required.');
    }
    this.rowNumber = rowNumber;
    this.valuesByColumn = new Map<String, String>(valuesByColumn);
  }

  /**
   * Returns a defensive copy of the parsed values.
   * @return Values keyed by normalized column key.
   */
  public Map<String, String> getValuesByColumn() {
    return new Map<String, String>(valuesByColumn);
  }
}
