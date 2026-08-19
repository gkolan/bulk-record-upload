/**
 * No-op base for BulkRecordUploadExtensionV1 so an implementer overrides only
 * the phase it needs.
 */
public virtual class BulkRecordUploadExtensionAdapterV1 implements BulkRecordUploadExtensionV1 {
  /** Returns rows unchanged by default. */
  public virtual List<BulkRecordUploadRowV1> beforeMap(
    BulkRecordUploadProjectionV1 projection,
    List<BulkRecordUploadRowV1> rows
  ) {
    return rows;
  }

  /** Does nothing by default. */
  public virtual void afterProcess(
    Id uploadId,
    BulkRecordUploadProjectionV1 projection,
    List<BulkRecordUploadRowResultV1> outcomes
  ) {
    return; // Intentionally empty: the default is a no-op.
  }
}
