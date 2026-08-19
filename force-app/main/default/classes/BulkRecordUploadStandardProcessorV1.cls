/** Default processor that delegates to partial-success user-mode persistence. */
public with sharing class BulkRecordUploadStandardProcessorV1 implements BulkRecordUploadProcessorV1 {
  /** {@inheritDoc} */
  public List<BulkRecordUploadRowResultV1> process(
    BulkRecordUploadProjectionV1 projection,
    List<BulkRecordUploadMappedRowV1> rows,
    Schema.SObjectField upsertField
  ) {
    return new BulkRecordUploadPersistenceGateway()
      .persist(projection.operation, rows, upsertField);
  }
}
