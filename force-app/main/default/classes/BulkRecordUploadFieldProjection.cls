/**
 * Immutable projection of one configured CSV column and target field.
 */
// This compact read-only record carries one approved field between services.
// code-analyzer-suppress-next-line ExcessivePublicCount
public class BulkRecordUploadFieldProjection {
  public String columnKey { get; private set; }
  public String displayLabel { get; private set; }
  public String fieldApiName { get; private set; }
  public String fieldType { get; private set; }
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
  public String lookupTargetObject { get; private set; }
  public Integer sequence { get; private set; }
  public Boolean isRequired { get; private set; }
  public Boolean isMatchKey { get; private set; }
  public Boolean isUpsertKey { get; private set; }
  public Boolean includeInResult { get; private set; }
  public Boolean canCreate { get; private set; }
  public Boolean canUpdate { get; private set; }

  /**
   * Creates an immutable field projection.
   * @param columnKey Stable normalized CSV column key.
   * @param displayLabel Safe user-facing column label.
   * @param fieldApiName Resolved target field API name.
   * @param fieldType Resolved Salesforce display type.
   * @param existingValueAction Registered existing-value merge action key.
   * @param sequence One-based configured order.
   * @param isRequired Whether an input value is required.
   * @param isMatchKey Whether this field identifies an existing record.
   * @param isUpsertKey Whether this field is the upsert key.
   * @param includeInResult Whether the safe value can appear in results.
   * @param canCreate Whether user-mode create access was granted.
   * @param canUpdate Whether user-mode update access was granted.
   */
  public BulkRecordUploadFieldProjection(
    String columnKey,
    String displayLabel,
    String fieldApiName,
    String fieldType,
    String existingValueAction,
    Integer sequence,
    Boolean isRequired,
    Boolean isMatchKey,
    Boolean isUpsertKey,
    Boolean includeInResult,
    Boolean canCreate,
    Boolean canUpdate
  ) {
    this(
      columnKey,
      displayLabel,
      fieldApiName,
      fieldType,
      existingValueAction,
      'IGNORE',
      'SPACE',
      'SKIP',
      'REJECT',
      sequence,
      isRequired,
      isMatchKey,
      isUpsertKey,
      includeInResult,
      canCreate,
      canUpdate
    );
  }

  /** Creates a field projection with explicit merge decisions. */
  public BulkRecordUploadFieldProjection(
    String columnKey,
    String displayLabel,
    String fieldApiName,
    String fieldType,
    String existingValueAction,
    String blankValueAction,
    String textSeparator,
    String duplicateTextAction,
    String overflowAction,
    Integer sequence,
    Boolean isRequired,
    Boolean isMatchKey,
    Boolean isUpsertKey,
    Boolean includeInResult,
    Boolean canCreate,
    Boolean canUpdate
  ) {
    this(
      columnKey,
      displayLabel,
      fieldApiName,
      fieldType,
      existingValueAction,
      blankValueAction,
      textSeparator,
      null,
      duplicateTextAction,
      overflowAction,
      null,
      false,
      'NONE',
      new Set<String>(),
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      sequence,
      isRequired,
      isMatchKey,
      isUpsertKey,
      includeInResult,
      canCreate,
      canUpdate
    );
  }

  /**
   * Creates a field projection with explicit merge, separator, default,
   * value-transform, row-validation, and lookup-resolution decisions.
   */
  public BulkRecordUploadFieldProjection(
    String columnKey,
    String displayLabel,
    String fieldApiName,
    String fieldType,
    String existingValueAction,
    String blankValueAction,
    String textSeparator,
    String customSeparator,
    String duplicateTextAction,
    String overflowAction,
    String defaultValue,
    Boolean trimValue,
    String caseAction,
    Set<String> blankTokens,
    String customMergeStrategyClass,
    String validationPattern,
    Decimal minValue,
    Decimal maxValue,
    String sourceTemplate,
    String lookupMatchField,
    String lookupTargetObject,
    Integer sequence,
    Boolean isRequired,
    Boolean isMatchKey,
    Boolean isUpsertKey,
    Boolean includeInResult,
    Boolean canCreate,
    Boolean canUpdate
  ) {
    this.columnKey = requireText(columnKey, 'columnKey');
    this.displayLabel = requireText(displayLabel, 'displayLabel');
    this.fieldApiName = requireText(fieldApiName, 'fieldApiName');
    this.fieldType = requireText(fieldType, 'fieldType');
    this.existingValueAction = requireText(
      existingValueAction,
      'existingValueAction'
    );
    this.blankValueAction = requireText(blankValueAction, 'blankValueAction');
    this.textSeparator = requireText(textSeparator, 'textSeparator');
    this.customSeparator = customSeparator;
    this.duplicateTextAction = requireText(
      duplicateTextAction,
      'duplicateTextAction'
    );
    this.overflowAction = requireText(overflowAction, 'overflowAction');
    this.defaultValue = defaultValue;
    this.trimValue = trimValue == true;
    this.caseAction = String.isBlank(caseAction) ? 'NONE' : caseAction;
    this.blankTokens = blankTokens == null ? new Set<String>() : blankTokens;
    this.customMergeStrategyClass = customMergeStrategyClass;
    this.validationPattern = validationPattern;
    this.minValue = minValue;
    this.maxValue = maxValue;
    this.sourceTemplate = sourceTemplate;
    this.lookupMatchField = lookupMatchField;
    this.lookupTargetObject = lookupTargetObject;
    if (sequence == null || sequence < 1) {
      throw new BulkRecordUploadException('Field sequence must be positive.');
    }
    this.sequence = sequence;
    this.isRequired = isRequired == true;
    this.isMatchKey = isMatchKey == true;
    this.isUpsertKey = isUpsertKey == true;
    this.includeInResult = includeInResult == true;
    this.canCreate = canCreate == true;
    this.canUpdate = canUpdate == true;
  }

  private static String requireText(String value, String propertyName) {
    if (String.isBlank(value)) {
      throw new BulkRecordUploadException(propertyName + ' is required.');
    }
    return value.trim();
  }
}
