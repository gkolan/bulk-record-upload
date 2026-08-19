/** Correlates one mapped record to its original physical CSV row. */
public class BulkRecordUploadMappedRowV1 {
  public Integer rowNumber { get; private set; }
  public SObject record { get; private set; }

  /** Creates a mapped row. */
  public BulkRecordUploadMappedRowV1(Integer rowNumber, SObject record) {
    if (rowNumber == null || rowNumber < 2 || record == null) {
      throw new BulkRecordUploadException('Mapped row input is invalid.');
    }
    this.rowNumber = rowNumber;
    this.record = record;
  }
}
