/**
 * No-op base for BulkRecordUploadExtension so an implementer overrides only
 * the phase it needs.
 */
public virtual class BulkRecordUploadExtensionAdapter implements BulkRecordUploadExtension {
  /** Returns rows unchanged by default. */
  public virtual List<BulkRecordUploadRow> beforeMap(
    BulkRecordUploadProjection projection,
    List<BulkRecordUploadRow> rows
  ) {
    return rows;
  }

  /** Does nothing by default. */
  public virtual void afterProcess(
    Id uploadId,
    BulkRecordUploadProjection projection,
    List<BulkRecordUploadRowResult> outcomes
  ) {
    return; // Intentionally empty: the default is a no-op.
  }
}
