/** Keeps the later or earlier of a date or date/time pair. */
public class BulkRecordUploadDateCompareStrategy implements BulkRecordUploadFieldMergeStrategy {
  private static final Set<String> DATE_TYPES = new Set<String>{
    'DATE',
    'DATETIME'
  };

  private final Boolean useLater;

  /** @param useLater True for Use Later, false for Use Earlier. */
  public BulkRecordUploadDateCompareStrategy(Boolean useLater) {
    this.useLater = useLater;
  }

  /** {@inheritDoc} */
  public Boolean supportsType(String fieldType) {
    return DATE_TYPES.contains(fieldType);
  }

  /** {@inheritDoc} */
  public Object combine(
    BulkRecordUploadFieldProjection field,
    Object existingValue,
    Object incomingValue,
    Integer maximumLength
  ) {
    if (field.fieldType == 'DATE') {
      Date existingDate = (Date) existingValue;
      Date incomingDate = (Date) incomingValue;
      Boolean useIncoming = useLater
        ? incomingDate > existingDate
        : incomingDate < existingDate;
      return useIncoming ? incomingDate : existingDate;
    }
    Datetime existingDatetime = (Datetime) existingValue;
    Datetime incomingDatetime = (Datetime) incomingValue;
    Boolean useIncomingDatetime = useLater
      ? incomingDatetime > existingDatetime
      : incomingDatetime < existingDatetime;
    return useIncomingDatetime ? incomingDatetime : existingDatetime;
  }
}
