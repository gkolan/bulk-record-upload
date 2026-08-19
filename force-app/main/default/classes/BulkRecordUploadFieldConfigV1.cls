/**
 * Immutable and sortable version 1 snapshot of one active field configuration record.
 */
public class BulkRecordUploadFieldConfigV1 implements Comparable {
  public String columnKey { get; private set; }
  public String displayLabel { get; private set; }
  public String fieldApiName { get; private set; }
  public String behavior { get; private set; }
  public String existingValueAction { get; private set; }
  public String blankValueAction { get; private set; }
  public String textSeparator { get; private set; }
  public String duplicateTextAction { get; private set; }
  public String overflowAction { get; private set; }
  public Integer sequence { get; private set; }
  public Boolean isRequired { get; private set; }
  public Boolean isMatchKey { get; private set; }
  public Boolean isUpsertKey { get; private set; }
  public Boolean includeInResult { get; private set; }

  /**
   * Creates a validated field snapshot.
   * @param recordValue Active subscriber field configuration.
   */
  public BulkRecordUploadFieldConfigV1(
    Bulk_Record_Upload_Process_Field__mdt recordValue
  ) {
    if (recordValue == null) {
      throw new BulkRecordUploadException('Field configuration is required.');
    }
    columnKey = normalizeColumn(
      requireText(recordValue.CsvColumnHeader__c, 'Column key')
    );
    displayLabel = requireText(recordValue.DisplayLabel__c, 'Display label');
    fieldApiName = requireText(recordValue.FieldApiName__c, 'Field API name');
    behavior = String.isBlank(recordValue.ValueHandling__c)
      ? 'REPLACE'
      : recordValue.ValueHandling__c.trim().toUpperCase();
    existingValueAction = defaultCode(
      recordValue.ExistingValueAction__c,
      behavior == 'CLEAR_WHEN_BLANK' ? 'REPLACE' : behavior
    );
    blankValueAction = defaultCode(
      recordValue.BlankValueAction__c,
      behavior == 'CLEAR_WHEN_BLANK' ? 'CLEAR' : 'IGNORE'
    );
    textSeparator = defaultCode(recordValue.TextSeparator__c, 'SPACE');
    duplicateTextAction = defaultCode(
      recordValue.DuplicateTextAction__c,
      'SKIP'
    );
    overflowAction = defaultCode(recordValue.OverflowAction__c, 'REJECT');
    sequence = recordValue.ColumnOrder__c == null
      ? null
      : recordValue.ColumnOrder__c.intValue();
    if (sequence == null || sequence < 1 || sequence > 100) {
      throw new BulkRecordUploadException(
        'Field sequence must be between 1 and 100.'
      );
    }
    if (
      !new Set<String>{ 'REPLACE', 'KEEP_EXISTING', 'APPEND', 'PREPEND' }
        .contains(existingValueAction)
    ) {
      throw new BulkRecordUploadException('Field behavior is not supported.');
    }
    if (
      !new Set<String>{ 'IGNORE', 'CLEAR', 'REJECT' }
        .contains(blankValueAction) ||
      !new Set<String>{
          'SPACE',
          'NEW_LINE',
          'COMMA_SPACE',
          'SEMICOLON_SPACE',
          'NONE'
        }
        .contains(textSeparator) ||
      !new Set<String>{ 'SKIP', 'KEEP', 'REJECT' }
        .contains(duplicateTextAction) ||
      overflowAction != 'REJECT'
    ) {
      throw new BulkRecordUploadException(
        'Field merge configuration is not supported.'
      );
    }
    isRequired = recordValue.IsRequired__c == true;
    isMatchKey = recordValue.IsMatchField__c == true;
    isUpsertKey = recordValue.IsUpsertExternalId__c == true;
    includeInResult = recordValue.IncludeInResult__c == true;
  }

  /** @return Sort order by sequence and then field API name. */
  public Integer compareTo(Object otherValue) {
    BulkRecordUploadFieldConfigV1 other = (BulkRecordUploadFieldConfigV1) otherValue;
    if (sequence != other.sequence) {
      return sequence < other.sequence ? -1 : 1;
    }
    return fieldApiName.compareTo(other.fieldApiName);
  }

  private static String normalizeColumn(String value) {
    return value.trim().toLowerCase();
  }

  private static String defaultCode(String value, String defaultValue) {
    return String.isBlank(value) ? defaultValue : value.trim().toUpperCase();
  }

  private static String requireText(String value, String label) {
    if (String.isBlank(value)) {
      throw new BulkRecordUploadException(label + ' is required.');
    }
    return value.trim();
  }
}
