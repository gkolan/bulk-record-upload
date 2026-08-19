/** Versioned validation contract for one configured DML operation. */
public interface BulkRecordUploadOperationStrategyV1 {
  /** Validates that the compact projection can support the operation. */
  void validateProjection(BulkRecordUploadProjectionV1 projection);
}
