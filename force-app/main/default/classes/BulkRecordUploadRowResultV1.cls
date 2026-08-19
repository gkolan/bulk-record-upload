/**
 * Safe version 1 outcome correlated to one physical CSV row.
 */
public class BulkRecordUploadRowResultV1 {
  public Integer rowNumber { get; private set; }
  public Boolean isSuccess { get; private set; }
  public Id recordId { get; private set; }
  public String errorCode { get; private set; }
  public String safeMessage { get; private set; }

  /**
   * Creates a row outcome without exposing input values or internal exception details.
   * @param rowNumber Physical CSV row number.
   * @param isSuccess Whether target persistence succeeded.
   * @param recordId Resulting or matched record identifier when authorized.
   * @param errorCode Stable safe error code for a failed row.
   * @param safeMessage Safe guidance suitable for a result CSV.
   */
  public BulkRecordUploadRowResultV1(
    Integer rowNumber,
    Boolean isSuccess,
    Id recordId,
    String errorCode,
    String safeMessage
  ) {
    if (rowNumber == null || rowNumber < 2) {
      throw new BulkRecordUploadException(
        'Result row number must be at least 2.'
      );
    }
    if (isSuccess != true && String.isBlank(errorCode)) {
      throw new BulkRecordUploadException(
        'Failed results require an error code.'
      );
    }
    this.rowNumber = rowNumber;
    this.isSuccess = isSuccess == true;
    this.recordId = recordId;
    this.errorCode = String.isBlank(errorCode) ? null : errorCode.trim();
    this.safeMessage = String.isBlank(safeMessage) ? null : safeMessage.trim();
  }
}
