/** Proves every retained text separator, duplicate action, blank action, and case action. */
@IsTest
private class BulkRecordUploadFieldOptionTest {
  @IsTest
  static void mergePolicy_AllTextSeparators_ProduceExactValues() {
    Map<String, String> expectedBySeparator = new Map<String, String>{
      'SPACE' => 'Existing Incoming',
      'NEW_LINE' => 'Existing\nIncoming',
      'COMMA_SPACE' => 'Existing, Incoming',
      'SEMICOLON_SPACE' => 'Existing; Incoming',
      'NONE' => 'ExistingIncoming',
      'CUSTOM' => 'Existing | Incoming'
    };
    BulkRecordUploadFieldMergePolicy policy = new BulkRecordUploadFieldMergePolicy();

    for (String separator : expectedBySeparator.keySet()) {
      BulkRecordUploadFieldProjection field = textField(
        'APPEND',
        separator,
        separator == 'CUSTOM' ? ' | ' : null,
        'KEEP',
        'IGNORE',
        'NONE'
      );
      Assert.areEqual(
        expectedBySeparator.get(separator),
        policy.applyPolicy(field, 'Existing', 'Incoming', 100),
        separator + ' should map to one exact separator.'
      );
    }
  }

  @IsTest
  static void mergePolicy_PrependDuplicatesAndBlankActions_AreExplicit() {
    BulkRecordUploadFieldMergePolicy policy = new BulkRecordUploadFieldMergePolicy();
    Assert.areEqual(
      'Incoming Existing',
      apply(policy, 'PREPEND', 'KEEP', 'IGNORE', 'Existing', 'Incoming')
    );
    Assert.areEqual(
      'Existing',
      apply(policy, 'APPEND', 'SKIP', 'IGNORE', 'Existing', 'Existing')
    );
    Assert.areEqual(
      'Existing Existing',
      apply(policy, 'APPEND', 'KEEP', 'IGNORE', 'Existing', 'Existing')
    );
    Assert.areEqual(
      'Existing',
      apply(policy, 'REPLACE', 'SKIP', 'IGNORE', 'Existing', null)
    );
    assertPolicyFailure(
      policy,
      'APPEND',
      'REJECT',
      'IGNORE',
      'already present'
    );
    assertPolicyFailure(policy, 'REPLACE', 'SKIP', 'REJECT', 'blank');
  }

  @IsTest
  static void mapper_AllCaseActions_AreDeterministic() {
    Map<String, String> expectedByAction = new Map<String, String>{
      'NONE' => 'mIXED cASE',
      'UPPER' => 'MIXED CASE',
      'LOWER' => 'mixed case',
      'TITLE' => 'Mixed Case'
    };
    for (String action : expectedByAction.keySet()) {
      Assert.areEqual(
        expectedByAction.get(action),
        BulkRecordUploadRecordMapper.normalizeRawValue(
          'mIXED cASE',
          textField('REPLACE', 'SPACE', null, 'SKIP', 'IGNORE', action)
        ),
        action + ' should have one deterministic normalization path.'
      );
    }
  }

  @IsTest
  static void projectionValidator_IgnoredConditionalOptions_FailClosed() {
    assertInvalidOptions(
      config(new Map<String, Object>{ 'CaseAction__c' => 'UPPER' }),
      Account.AnnualRevenue,
      'text-like field'
    );
    assertInvalidOptions(
      config(new Map<String, Object>{ 'ValidationPattern__c' => '[0-9]+' }),
      Account.AnnualRevenue,
      'text-like field'
    );
    assertInvalidOptions(
      config(new Map<String, Object>{ 'OverflowAction__c' => 'TRUNCATE' }),
      Account.AnnualRevenue,
      'text-like field'
    );
    assertInvalidOptions(
      config(new Map<String, Object>{ 'TextSeparator__c' => 'NEW_LINE' }),
      Account.Name,
      'Append or Prepend'
    );
    assertInvalidOptions(
      config(new Map<String, Object>{ 'DuplicateTextAction__c' => 'KEEP' }),
      Account.Name,
      'Append or Prepend'
    );
    assertInvalidOptions(
      config(new Map<String, Object>{ 'CustomSeparator__c' => ' | ' }),
      Account.Name,
      'Append or Prepend'
    );
    assertInvalidOptions(
      config(
        new Map<String, Object>{
          'ExistingValueAction__c' => 'APPEND',
          'TextSeparator__c' => 'SPACE',
          'CustomSeparator__c' => ' | '
        }
      ),
      Account.Name,
      'Custom text separator'
    );
    BulkRecordUploadProjectionValidator.validateBehaviorOptions(
      config(
        new Map<String, Object>{
          'ExistingValueAction__c' => 'APPEND',
          'TextSeparator__c' => 'CUSTOM',
          'CustomSeparator__c' => ' | ',
          'DuplicateTextAction__c' => 'REJECT',
          'CaseAction__c' => 'TITLE',
          'OverflowAction__c' => 'TRUNCATE',
          'ValidationPattern__c' => '.+'
        }
      ),
      Account.Name.getDescribe()
    );
  }

  private static Object apply(
    BulkRecordUploadFieldMergePolicy policy,
    String existingAction,
    String duplicateAction,
    String blankAction,
    Object existingValue,
    Object incomingValue
  ) {
    return policy.applyPolicy(
      textField(
        existingAction,
        'SPACE',
        null,
        duplicateAction,
        blankAction,
        'NONE'
      ),
      existingValue,
      incomingValue,
      100
    );
  }

  private static void assertInvalidOptions(
    BulkRecordUploadFieldConfig fieldConfig,
    Schema.SObjectField fieldToken,
    String expectedMessage
  ) {
    try {
      BulkRecordUploadProjectionValidator.validateBehaviorOptions(
        fieldConfig,
        fieldToken.getDescribe()
      );
      Assert.fail('Expected incompatible conditional options to fail.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(error.getMessage().contains(expectedMessage));
    }
  }

  private static BulkRecordUploadFieldConfig config(
    Map<String, Object> overrides
  ) {
    Bulk_Record_Upload_Process_Field__mdt recordValue = new Bulk_Record_Upload_Process_Field__mdt(
      CsvColumnHeader__c = 'value',
      DisplayLabel__c = 'Value',
      FieldApiName__c = 'Name',
      ExistingValueAction__c = 'REPLACE',
      BlankValueAction__c = 'IGNORE',
      TextSeparator__c = 'SPACE',
      DuplicateTextAction__c = 'SKIP',
      OverflowAction__c = 'REJECT',
      CaseAction__c = 'NONE',
      ColumnOrder__c = 1
    );
    for (String fieldName : overrides.keySet()) {
      recordValue.put(fieldName, overrides.get(fieldName));
    }
    return new BulkRecordUploadFieldConfig(recordValue);
  }

  private static void assertPolicyFailure(
    BulkRecordUploadFieldMergePolicy policy,
    String existingAction,
    String duplicateAction,
    String blankAction,
    String expectedMessage
  ) {
    try {
      apply(
        policy,
        existingAction,
        duplicateAction,
        blankAction,
        'Existing',
        existingAction == 'APPEND' ? 'Existing' : null
      );
      Assert.fail('Expected the configured policy to reject the value.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(error.getMessage().contains(expectedMessage));
    }
  }

  private static BulkRecordUploadFieldProjection textField(
    String existingAction,
    String separator,
    String customSeparator,
    String duplicateAction,
    String blankAction,
    String caseAction
  ) {
    return new BulkRecordUploadFieldProjection(
      'description',
      'Description',
      'Description',
      'TEXTAREA',
      existingAction,
      blankAction,
      separator,
      customSeparator,
      duplicateAction,
      'REJECT',
      null,
      false,
      caseAction,
      new Set<String>(),
      null,
      null,
      null,
      null,
      null,
      null,
      1,
      false,
      false,
      false,
      true,
      true,
      true
    );
  }
}
