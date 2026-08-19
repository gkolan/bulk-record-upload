/** Versioned contract for applying one trusted field merge behavior. */
public interface BulkRecordUploadFieldBehaviorV1 {
  /** Returns the value that should be assigned after applying the behavior. */
  Object apply(Object existingValue, Object incomingValue);
}
