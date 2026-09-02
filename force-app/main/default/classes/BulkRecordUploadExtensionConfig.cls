/** Immutable and sortable snapshot of one active extension registration record. */
public class BulkRecordUploadExtensionConfig implements Comparable {
  public String className { get; private set; }
  public Integer sortOrder { get; private set; }

  /**
   * Creates a validated extension registration snapshot.
   * @param recordValue Active subscriber extension registration.
   */
  public BulkRecordUploadExtensionConfig(
    Bulk_Record_Upload_Extension__mdt recordValue
  ) {
    if (recordValue == null) {
      throw new BulkRecordUploadException(
        'Extension configuration is required.'
      );
    }
    className = requireText(recordValue.ClassName__c, 'Extension class name');
    if (recordValue.SortOrder__c == null) {
      throw new BulkRecordUploadException('Extension sort order is required.');
    }
    sortOrder = recordValue.SortOrder__c.intValue();
  }

  /** @return Sort order, then class name for a stable tie-break. */
  public Integer compareTo(Object otherValue) {
    BulkRecordUploadExtensionConfig other = (BulkRecordUploadExtensionConfig) otherValue;
    if (sortOrder != other.sortOrder) {
      return sortOrder < other.sortOrder ? -1 : 1;
    }
    return className.compareTo(other.className);
  }

  private static String requireText(String value, String label) {
    if (String.isBlank(value)) {
      throw new BulkRecordUploadException(label + ' is required.');
    }
    return value.trim();
  }
}
