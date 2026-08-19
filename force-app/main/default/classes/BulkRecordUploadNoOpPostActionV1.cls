/** Default post-processing action that deliberately performs no work. */
public with sharing class BulkRecordUploadNoOpPostActionV1 implements BulkRecordUploadPostActionV1 {
  /** {@inheritDoc} */
  public void afterProcess(
    Id uploadId,
    BulkRecordUploadProjectionV1 projection,
    List<BulkRecordUploadRowResultV1> results
  ) {
    if (uploadId == null || projection == null || results == null) {
      throw new BulkRecordUploadException('Post-processing input is required.');
    }
  }
}
