/** Validation contract for one configured DML operation. */
public interface BulkRecordUploadOperationStrategy {
  /** Validates that the compact projection can support the operation. */
  void validateProjection(BulkRecordUploadProjection projection);
}
