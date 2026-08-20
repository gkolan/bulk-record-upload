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

  private final BulkRecordUploadMergeStrategyRegistry customStrategyRegistry = new BulkRecordUploadMergeStrategyRegistry();
  private final Map<String, BulkRecordUploadFieldMergeStrategy> customStrategyCache = new Map<String, BulkRecordUploadFieldMergeStrategy>();

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
    if (field.existingValueAction == 'REPLACE' || existingValue == null) {
      return incomingValue;
    }
    if (field.existingValueAction == 'KEEP_EXISTING') {
      return existingValue;
    }
    BulkRecordUploadFieldMergeStrategy strategy = field.existingValueAction ==
      'CUSTOM'
      ? resolveCustomStrategy(field.customMergeStrategyClass)
      : STRATEGIES.get(field.existingValueAction);
    if (strategy == null || !strategy.supportsType(field.fieldType)) {
      throw new BulkRecordUploadException(
        'This existing-value action is not supported for the configured field type.'
      );
    }
    return strategy.combine(field, existingValue, incomingValue, maximumLength);
  }

  /** Resolves a Custom merge strategy class once per instance, not once per row. */
  private BulkRecordUploadFieldMergeStrategy resolveCustomStrategy(
    String className
  ) {
    BulkRecordUploadFieldMergeStrategy cached = customStrategyCache.get(
      className
    );
    if (cached == null) {
      cached = customStrategyRegistry.resolve(className);
      customStrategyCache.put(className, cached);
    }
    return cached;
  }
}
