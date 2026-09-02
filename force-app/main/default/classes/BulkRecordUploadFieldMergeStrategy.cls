/** One registered existing-value merge action for a family of field types. */
public interface BulkRecordUploadFieldMergeStrategy {
  /** Whether this strategy applies to the given Schema display type. */
  Boolean supportsType(String fieldType);

  /** Returns the merged value. Only called after blank and type checks pass. */
  Object combine(
    BulkRecordUploadFieldProjection field,
    Object existingValue,
    Object incomingValue,
    Integer maximumLength
  );
}
