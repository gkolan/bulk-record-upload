/** Correlates one mapped record to its original physical CSV row. */
public class BulkRecordUploadMappedRow {
  public Integer rowNumber { get; private set; }
  public SObject record { get; private set; }
  public String errorCode { get; private set; }
  public String safeMessage { get; private set; }

  /** Creates a mapped row. */
  public BulkRecordUploadMappedRow(Integer rowNumber, SObject record) {
    if (rowNumber == null || rowNumber < 2 || record == null) {
      throw new BulkRecordUploadException('Mapped row input is invalid.');
    }
    this.rowNumber = rowNumber;
    this.record = record;
  }

  /** Marks this row as a safe pre-DML failure while preserving row correlation. */
  public void markFailed(String code, String message) {
    if (String.isBlank(code)) {
      throw new BulkRecordUploadException(
        'Mapped row failures require a code.'
      );
    }
    errorCode = code.left(
      BulkRecordUploadRuntimeContract.MAX_ERROR_CODE_CHARACTERS
    );
    safeMessage = String.isBlank(message)
      ? 'The row did not pass configured validation.'
      : message.left(
          BulkRecordUploadRuntimeContract.MAX_ERROR_MESSAGE_CHARACTERS
        );
  }

  /** @return True until a row-scoped pre-DML stage marks this row failed. */
  public Boolean isValid() {
    return String.isBlank(errorCode);
  }
}
