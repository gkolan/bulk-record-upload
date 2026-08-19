/** Trusted post-processing extension that receives safe results but never raw CSV content. */
public interface BulkRecordUploadPostActionV1 {
  /** Runs after one bounded processor invocation completes. */
  void afterProcess(
    Id uploadId,
    BulkRecordUploadProjectionV1 projection,
    List<BulkRecordUploadRowResultV1> results
  );
}
