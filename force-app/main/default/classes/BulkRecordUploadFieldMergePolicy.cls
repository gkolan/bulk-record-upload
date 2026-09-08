/** Dispatches configured blank and existing-value decisions to a registered merge strategy. */
public with sharing class BulkRecordUploadFieldMergePolicy {
  private static final Map<String, BulkRecordUploadFieldMergeStrategy> STRATEGIES = new Map<String, BulkRecordUploadFieldMergeStrategy>{
    'APPEND' => new BulkRecordUploadTextJoinStrategy(true),
    'PREPEND' => new BulkRecordUploadTextJoinStrategy(false),
    'ADD_VALUES' => new BulkRecordUploadMultiPicklistSetStrategy(true),
    'REMOVE_VALUES' => new BulkRecordUploadMultiPicklistSetStrategy(false),
    'ADD' => new BulkRecordUploadNumericMathStrategy(true),
    'SUBTRACT' => new BulkRecordUploadNumericMathStrategy(false),
    'USE_LATER' => new BulkRecordUploadDateCompareStrategy(true),
    'USE_EARLIER' => new BulkRecordUploadDateCompareStrategy(false),
    'TRUE_IF_EITHER' => new BulkRecordUploadBooleanLogicStrategy(true),
    'TRUE_IF_BOTH' => new BulkRecordUploadBooleanLogicStrategy(false)
  };

  /**
   * Returns the safely merged value for one Schema-resolved field.
   * A blank incoming value with blankValueAction DEFAULT never reaches this
   * method blank: BulkRecordUploadRecordMapper resolves the default value
   * before mapping, so incomingValue already carries a coerced value here.
   */
  public Object applyPolicy(
    BulkRecordUploadFieldProjection field,
    Object existingValue,
    Object incomingValue,
    Integer maximumLength
  ) {
    if (
      incomingValue == null ||
      (incomingValue instanceof String &&
      String.isBlank((String) incomingValue))
    ) {
      if (field.blankValueAction == 'IGNORE') {
        return existingValue;
      }
      if (field.blankValueAction == 'CLEAR') {
        return null;
      }
      throw new BulkRecordUploadException(
        'A required configured value is blank.'
      );
    }
    if (
      field.existingValueAction == 'REPLACE' ||
      existingValue == null ||
      (existingValue instanceof String &&
      String.isBlank((String) existingValue))
    ) {
      return incomingValue;
    }
    if (field.existingValueAction == 'KEEP_EXISTING') {
      return existingValue;
    }
    BulkRecordUploadFieldMergeStrategy strategy = STRATEGIES.get(
      field.existingValueAction
    );
    if (strategy == null || !strategy.supportsType(field.fieldType)) {
      throw new BulkRecordUploadException(
        'This existing-value action is not supported for the configured field type.'
      );
    }
    Object combined = strategy.combine(
      field,
      existingValue,
      incomingValue,
      maximumLength
    );
    validateRange(field, combined);
    return combined;
  }

  private static void validateRange(
    BulkRecordUploadFieldProjection field,
    Object value
  ) {
    if (value == null || (field.minValue == null && field.maxValue == null)) {
      return;
    }
    Decimal numericValue = Decimal.valueOf(String.valueOf(value));
    if (field.minValue != null && numericValue < field.minValue) {
      throw new BulkRecordUploadException(
        'A configured merged value is below the minimum for ' +
          field.displayLabel +
          '.'
      );
    }
    if (field.maxValue != null && numericValue > field.maxValue) {
      throw new BulkRecordUploadException(
        'A configured merged value is above the maximum for ' +
          field.displayLabel +
          '.'
      );
    }
  }
}
