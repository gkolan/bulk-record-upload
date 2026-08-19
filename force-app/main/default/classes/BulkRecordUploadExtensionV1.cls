/**
 * The one trusted extension point a subscriber may implement. An
 * implementation may transform rows and observe results; it cannot persist
 * records directly. Persistence stays package-owned and user-mode, per
 * ADR-0007.
 */
public interface BulkRecordUploadExtensionV1 {
  /**
   * Runs before row mapping, in place of the version 1 handler step.
   * @param projection Immutable approved process projection.
   * @param rows Bounded parsed rows for one chunk.
   * @return Transformed rows preserving physical row correlation.
   */
  List<BulkRecordUploadRowV1> beforeMap(
    BulkRecordUploadProjectionV1 projection,
    List<BulkRecordUploadRowV1> rows
  );

  /**
   * Runs after one bounded processor invocation completes.
   * @param uploadId Authorized upload identifier.
   * @param projection Immutable approved process projection.
   * @param outcomes Safe row results; never raw CSV content.
   */
  void afterProcess(
    Id uploadId,
    BulkRecordUploadProjectionV1 projection,
    List<BulkRecordUploadRowResultV1> outcomes
  );
}
