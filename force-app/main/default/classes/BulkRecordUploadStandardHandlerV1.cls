/** Default handler that preserves approved projected rows unchanged. */
public with sharing class BulkRecordUploadStandardHandlerV1 implements BulkRecordUploadHandlerV1 {
  /** {@inheritDoc} */
  public List<BulkRecordUploadRowV1> handle(
    BulkRecordUploadProjectionV1 projection,
    List<BulkRecordUploadRowV1> rows
  ) {
    if (projection == null || rows == null) {
      throw new BulkRecordUploadException('Handler input is required.');
    }
    return new List<BulkRecordUploadRowV1>(rows);
  }
}
