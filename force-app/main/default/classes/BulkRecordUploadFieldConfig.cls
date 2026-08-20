/**
 * Immutable and sortable snapshot of one active field configuration record.
 */
public class BulkRecordUploadFieldConfig implements Comparable {
  public String columnKey { get; private set; }
  public String displayLabel { get; private set; }
  public String fieldApiName { get; private set; }
  public String existingValueAction { get; private set; }
  public String blankValueAction { get; private set; }
  public String textSeparator { get; private set; }
  public String customSeparator { get; private set; }
  public String duplicateTextAction { get; private set; }
  public String overflowAction { get; private set; }
  public String defaultValue { get; private set; }
  public Boolean trimValue { get; private set; }
  public String caseAction { get; private set; }
  public Set<String> blankTokens { get; private set; }
  public String customMergeStrategyClass { get; private set; }
  public String validationPattern { get; private set; }
  public Decimal minValue { get; private set; }
  public Decimal maxValue { get; private set; }
  public String sourceTemplate { get; private set; }
  public String lookupMatchField { get; private set; }
  public Integer sequence { get; private set; }
  public Boolean isRequired { get; private set; }
  public Boolean isMatchKey { get; private set; }
  public Boolean isUpsertKey { get; private set; }
  public Boolean includeInResult { get; private set; }

  private static final Set<String> EXISTING_VALUE_ACTIONS = new Set<String>{
    'REPLACE',
    'KEEP_EXISTING',
    'APPEND',
    'PREPEND',
    'ADD_VALUES',
    'REMOVE_VALUES',
    'ADD',
    'SUBTRACT',
    'USE_LATER',
    'USE_EARLIER',
    'TRUE_IF_EITHER',
    'TRUE_IF_BOTH',
    'CUSTOM'
  };
  private static final Set<String> BLANK_VALUE_ACTIONS = new Set<String>{
    'IGNORE',
    'CLEAR',
    'REJECT',
    'DEFAULT'
  };
  private static final Set<String> TEXT_SEPARATORS = new Set<String>{
    'SPACE',
    'NEW_LINE',
    'COMMA_SPACE',
    'SEMICOLON_SPACE',
    'NONE',
    'CUSTOM'
  };
  private static final Set<String> CASE_ACTIONS = new Set<String>{
    'NONE',
    'UPPER',
    'LOWER',
    'TITLE'
  };
  private static final Set<String> OVERFLOW_ACTIONS = new Set<String>{
    'REJECT',
    'TRUNCATE',
    'TRUNCATE_AT_WORD'
  };

  /**
   * Creates a validated field snapshot.
   * @param recordValue Active subscriber field configuration.
   */
  public BulkRecordUploadFieldConfig(
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
    existingValueAction = defaultCode(
      recordValue.ExistingValueAction__c,
      'REPLACE'
    );
    blankValueAction = defaultCode(recordValue.BlankValueAction__c, 'IGNORE');
    textSeparator = defaultCode(recordValue.TextSeparator__c, 'SPACE');
    customSeparator = recordValue.CustomSeparator__c;
    duplicateTextAction = defaultCode(
      recordValue.DuplicateTextAction__c,
      'SKIP'
    );
    overflowAction = defaultCode(recordValue.OverflowAction__c, 'REJECT');
    defaultValue = recordValue.DefaultValue__c;
    trimValue = recordValue.TrimValue__c == true;
    caseAction = defaultCode(recordValue.CaseAction__c, 'NONE');
    blankTokens = parseBlankTokens(recordValue.BlankTokens__c);
    customMergeStrategyClass = recordValue.CustomMergeStrategyClass__c;
    validationPattern = recordValue.ValidationPattern__c;
    minValue = recordValue.MinValue__c;
    maxValue = recordValue.MaxValue__c;
    sourceTemplate = recordValue.SourceTemplate__c;
    lookupMatchField = recordValue.LookupMatchField__c;
    sequence = recordValue.ColumnOrder__c == null
      ? null
      : recordValue.ColumnOrder__c.intValue();
    if (sequence == null || sequence < 1 || sequence > 100) {
      throw new BulkRecordUploadException(
        'Field sequence must be between 1 and 100.'
      );
    }
    if (
      !EXISTING_VALUE_ACTIONS.contains(existingValueAction) ||
      !BLANK_VALUE_ACTIONS.contains(blankValueAction) ||
      !TEXT_SEPARATORS.contains(textSeparator) ||
      !new Set<String>{ 'SKIP', 'KEEP', 'REJECT' }
        .contains(duplicateTextAction) ||
      !OVERFLOW_ACTIONS.contains(overflowAction) ||
      !CASE_ACTIONS.contains(caseAction)
    ) {
      throw new BulkRecordUploadException(
        'Field merge configuration is not supported.'
      );
    }
    if (textSeparator == 'CUSTOM' && String.isBlank(customSeparator)) {
      throw new BulkRecordUploadException(
        'Custom Separator is required when Text Separator is Custom.'
      );
    }
    if (blankValueAction == 'DEFAULT' && String.isBlank(defaultValue)) {
      throw new BulkRecordUploadException(
        'Default Value is required when Blank CSV Action is Use Default.'
      );
    }
    if (
      existingValueAction == 'CUSTOM' &&
      String.isBlank(customMergeStrategyClass)
    ) {
      throw new BulkRecordUploadException(
        'Custom Merge Strategy Class is required when Existing Value Action is Custom.'
      );
    }
    if (String.isNotBlank(validationPattern)) {
      try {
        Pattern.compile(validationPattern);
      } catch (Exception error) {
        throw new BulkRecordUploadException(
          'Validation Pattern is not a valid regular expression.'
        );
      }
    }
    if (minValue != null && maxValue != null && minValue > maxValue) {
      throw new BulkRecordUploadException(
        'Minimum Value cannot exceed Maximum Value.'
      );
    }
    isRequired = recordValue.IsRequired__c == true;
    isMatchKey = recordValue.IsMatchField__c == true;
    isUpsertKey = recordValue.IsUpsertExternalId__c == true;
    includeInResult = recordValue.IncludeInResult__c == true;
  }

  /** @return Sort order by sequence and then field API name. */
  public Integer compareTo(Object otherValue) {
    BulkRecordUploadFieldConfig other = (BulkRecordUploadFieldConfig) otherValue;
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

  private static Set<String> parseBlankTokens(String value) {
    Set<String> tokens = new Set<String>();
    if (String.isBlank(value)) {
      return tokens;
    }
    for (String token : value.split(',')) {
      if (String.isNotBlank(token)) {
        tokens.add(token.trim().toLowerCase());
      }
    }
    return tokens;
  }
}
