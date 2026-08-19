/**
 * Trusted version 1 extension contract for projected rows. Implementations may transform rows but cannot persist records directly.
 */
public interface BulkRecordUploadHandlerV1 {
  /**
   * Applies registered row transformation or validation behavior.
   * @param projection Immutable approved process projection.
   * @param rows Bounded parsed rows for one chunk.
   * @return Transformed rows preserving physical row correlation.
   */
  List<BulkRecordUploadRowV1> handle(
    BulkRecordUploadProjectionV1 projection,
    List<BulkRecordUploadRowV1> rows
  );
}
