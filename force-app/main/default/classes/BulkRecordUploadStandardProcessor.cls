/** Default processor that delegates to partial-success user-mode persistence. */
public with sharing class BulkRecordUploadStandardProcessor implements BulkRecordUploadProcessor {
  /** {@inheritDoc} */
  public List<BulkRecordUploadRowResult> process(
    BulkRecordUploadProjection projection,
    List<BulkRecordUploadMappedRow> rows,
    Schema.SObjectField upsertField
  ) {
    return new BulkRecordUploadPersistenceGateway()
      .persist(projection.operation, rows, upsertField);
  }
}
