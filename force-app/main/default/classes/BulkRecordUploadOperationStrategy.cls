/** Validates operation-specific projection requirements without accessing records. */
public with sharing class BulkRecordUploadOperationStrategy implements BulkRecordUploadOperationStrategyV1 {
  private final String operation;

  /** Creates a strategy for one registry-owned operation code. */
  public BulkRecordUploadOperationStrategy(String operation) {
    this.operation = operation;
  }

  /** {@inheritDoc} */
  public void validateProjection(BulkRecordUploadProjectionV1 projection) {
    if (projection == null || projection.operation != operation) {
      throw new BulkRecordUploadException(
        'The operation projection is invalid.'
      );
    }
    Integer matchKeys = 0;
    Integer upsertKeys = 0;
    for (BulkRecordUploadFieldProjectionV1 field : projection.getFields()) {
      matchKeys += field.isMatchKey ? 1 : 0;
      upsertKeys += field.isUpsertKey ? 1 : 0;
    }
    if ((operation == 'UPDATE' || operation == 'DELETE') && matchKeys != 1) {
      throw new BulkRecordUploadException(
        'This operation requires exactly one match key.'
      );
    }
    if (operation == 'UPSERT' && upsertKeys != 1) {
      throw new BulkRecordUploadException(
        'Upsert requires exactly one upsert key.'
      );
    }
  }
}
