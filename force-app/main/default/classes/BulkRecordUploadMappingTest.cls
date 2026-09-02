@IsTest
private class BulkRecordUploadMappingTest {
  @IsTest
  static void mapper_ConfiguredFieldsOnly_CoercesAndCorrelates() {
    List<BulkRecordUploadFieldProjection> fields = new List<BulkRecordUploadFieldProjection>{
      field('name', 'Name', 'STRING', 'REPLACE', 1),
      field('employees', 'NumberOfEmployees', 'INTEGER', 'REPLACE', 2)
    };
    BulkRecordUploadProjection projection = projection(fields);
    BulkRecordUploadRow row = new BulkRecordUploadRow(
      7,
      new Map<String, String>{
        'name' => 'Acme',
        'employees' => '42',
        'ignored' => 'secret'
      }
    );

    List<BulkRecordUploadMappedRow> mapped = new BulkRecordUploadRecordMapper()
      .mapRows(projection, new List<BulkRecordUploadRow>{ row });

    Assert.areEqual(7, mapped[0].rowNumber);
    Assert.areEqual('Acme', mapped[0].record.get('Name'));
    Assert.areEqual(42, mapped[0].record.get('NumberOfEmployees'));
    Assert.isFalse(
      mapped[0].record.getPopulatedFieldsAsMap().containsKey('ignored')
    );
  }

  @IsTest
  static void mergePolicy_AppendSeparatorDuplicateAndOverflow_AreSafe() {
    BulkRecordUploadFieldProjection appendField = new BulkRecordUploadFieldProjection(
      'description',
      'Description',
      'Description',
      'TEXTAREA',
      'APPEND',
      'IGNORE',
      'NEW_LINE',
      'SKIP',
      'REJECT',
      1,
      false,
      false,
      false,
      true,
      true,
      true
    );
    BulkRecordUploadFieldMergePolicy policy = new BulkRecordUploadFieldMergePolicy();
    Test.startTest();
    Assert.areEqual(
      'Existing\nIncoming',
      policy.applyPolicy(appendField, 'Existing', 'Incoming', 100)
    );
    Assert.areEqual(
      'Existing\nIncoming',
      policy.applyPolicy(appendField, 'Existing\nIncoming', 'Incoming', 100)
    );
    try {
      policy.applyPolicy(appendField, 'Existing', 'Incoming', 5);
      Assert.fail('Overflow should fail instead of truncating.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(
        error.getMessage().contains('field length'),
        'Safe overflow guidance expected.'
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void mergePolicy_BlankActions_AreIndependent() {
    BulkRecordUploadFieldProjection clearField = new BulkRecordUploadFieldProjection(
      'description',
      'Description',
      'Description',
      'TEXTAREA',
      'REPLACE',
      'CLEAR',
      'SPACE',
      'SKIP',
      'REJECT',
      1,
      false,
      false,
      false,
      true,
      true,
      true
    );
    Assert.isNull(
      new BulkRecordUploadFieldMergePolicy()
        .applyPolicy(clearField, 'Existing', null, 100)
    );
  }

  @IsTest
  static void mergePolicy_NumericAddSubtract_AppliesArithmetic() {
    BulkRecordUploadFieldProjection addField = numericField('ADD', 'CURRENCY');
    BulkRecordUploadFieldProjection subtractField = numericField(
      'SUBTRACT',
      'INTEGER'
    );
    BulkRecordUploadFieldMergePolicy policy = new BulkRecordUploadFieldMergePolicy();
    Assert.areEqual(15.0, policy.applyPolicy(addField, 10.0, 5.0, null));
    Assert.areEqual(7, policy.applyPolicy(subtractField, 10, 3, null));
  }

  @IsTest
  static void mergePolicy_DateUseLaterEarlier_PicksCorrectDate() {
    BulkRecordUploadFieldProjection laterField = dateField('USE_LATER');
    BulkRecordUploadFieldProjection earlierField = dateField('USE_EARLIER');
    BulkRecordUploadFieldMergePolicy policy = new BulkRecordUploadFieldMergePolicy();
    Date existingDate = Date.newInstance(2026, 1, 1);
    Date incomingDate = Date.newInstance(2026, 6, 1);
    Assert.areEqual(
      incomingDate,
      policy.applyPolicy(laterField, existingDate, incomingDate, null)
    );
    Assert.areEqual(
      existingDate,
      policy.applyPolicy(earlierField, existingDate, incomingDate, null)
    );
  }

  @IsTest
  static void mergePolicy_BooleanEitherBoth_AppliesLogic() {
    BulkRecordUploadFieldProjection eitherField = booleanField(
      'TRUE_IF_EITHER'
    );
    BulkRecordUploadFieldProjection bothField = booleanField('TRUE_IF_BOTH');
    BulkRecordUploadFieldMergePolicy policy = new BulkRecordUploadFieldMergePolicy();
    Assert.areEqual(true, policy.applyPolicy(eitherField, false, true, null));
    Assert.areEqual(false, policy.applyPolicy(bothField, false, true, null));
  }

  @IsTest
  static void mergePolicy_MultiPicklistAddRemoveValues_AppliesSetSemantics() {
    BulkRecordUploadFieldProjection addValuesField = multiPicklistField(
      'ADD_VALUES'
    );
    BulkRecordUploadFieldProjection removeValuesField = multiPicklistField(
      'REMOVE_VALUES'
    );
    BulkRecordUploadFieldMergePolicy policy = new BulkRecordUploadFieldMergePolicy();
    Assert.areEqual(
      'A;B;C',
      policy.applyPolicy(addValuesField, 'A;B', 'B;C', null)
    );
    Assert.areEqual(
      'A',
      policy.applyPolicy(removeValuesField, 'A;B', 'B', null)
    );
  }

  @IsTest
  static void mergePolicy_CustomSeparator_UsesConfiguredText() {
    BulkRecordUploadFieldProjection customField = new BulkRecordUploadFieldProjection(
      'description',
      'Description',
      'Description',
      'TEXTAREA',
      'APPEND',
      'IGNORE',
      'CUSTOM',
      ' | ',
      'SKIP',
      'REJECT',
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
      1,
      false,
      false,
      false,
      true,
      true,
      true
    );
    Assert.areEqual(
      'Existing | Incoming',
      new BulkRecordUploadFieldMergePolicy()
        .applyPolicy(customField, 'Existing', 'Incoming', 100)
    );
  }

  @IsTest
  static void mergePolicy_UnsupportedActionForType_ThrowsDomainException() {
    BulkRecordUploadFieldProjection invalidField = numericField(
      'ADD',
      'STRING'
    );
    try {
      new BulkRecordUploadFieldMergePolicy()
        .applyPolicy(invalidField, 'Existing', 'Incoming', null);
      Assert.fail('Expected an unsupported-action exception.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(error.getMessage().contains('not supported'));
    }
  }

  @IsTest
  static void mergePolicy_OverflowTruncateAndTruncateAtWord_ShortensText() {
    BulkRecordUploadFieldProjection truncateField = new BulkRecordUploadFieldProjection(
      'description',
      'Description',
      'Description',
      'TEXTAREA',
      'APPEND',
      'IGNORE',
      'SPACE',
      null,
      'SKIP',
      'TRUNCATE',
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
      1,
      false,
      false,
      false,
      true,
      true,
      true
    );
    BulkRecordUploadFieldProjection truncateAtWordField = new BulkRecordUploadFieldProjection(
      'description',
      'Description',
      'Description',
      'TEXTAREA',
      'APPEND',
      'IGNORE',
      'SPACE',
      null,
      'SKIP',
      'TRUNCATE_AT_WORD',
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
      1,
      false,
      false,
      false,
      true,
      true,
      true
    );
    BulkRecordUploadFieldMergePolicy policy = new BulkRecordUploadFieldMergePolicy();
    Assert.areEqual(
      'Existin g Ov',
      policy.applyPolicy(truncateField, 'Existin', 'g Overflow', 12)
    );
    Assert.areEqual(
      'Existin g',
      policy.applyPolicy(truncateAtWordField, 'Existin', 'g Overflow', 12)
    );
  }

  private static BulkRecordUploadProjection projection(
    List<BulkRecordUploadFieldProjection> fields
  ) {
    return new BulkRecordUploadProjection(
      'ACCOUNT_INSERT',
      'hash',
      'Account',
      'INSERT',
      new List<String>(),
      100,
      30,
      fields
    );
  }

  private static BulkRecordUploadFieldProjection field(
    String columnKey,
    String apiName,
    String fieldType,
    String existingValueAction,
    Integer sequence
  ) {
    return new BulkRecordUploadFieldProjection(
      columnKey,
      columnKey,
      apiName,
      fieldType,
      existingValueAction,
      sequence,
      true,
      false,
      false,
      true,
      true,
      true
    );
  }

  private static BulkRecordUploadFieldProjection numericField(
    String existingValueAction,
    String fieldType
  ) {
    return new BulkRecordUploadFieldProjection(
      'amount',
      'Amount',
      'Amount',
      fieldType,
      existingValueAction,
      1,
      false,
      false,
      false,
      true,
      true,
      true
    );
  }

  private static BulkRecordUploadFieldProjection dateField(
    String existingValueAction
  ) {
    return new BulkRecordUploadFieldProjection(
      'closeDate',
      'Close Date',
      'CloseDate',
      'DATE',
      existingValueAction,
      1,
      false,
      false,
      false,
      true,
      true,
      true
    );
  }

  private static BulkRecordUploadFieldProjection booleanField(
    String existingValueAction
  ) {
    return new BulkRecordUploadFieldProjection(
      'active',
      'Active',
      'IsActive',
      'BOOLEAN',
      existingValueAction,
      1,
      false,
      false,
      false,
      true,
      true,
      true
    );
  }

  private static BulkRecordUploadFieldProjection multiPicklistField(
    String existingValueAction
  ) {
    return new BulkRecordUploadFieldProjection(
      'tags',
      'Tags',
      'Tags',
      'MULTIPICKLIST',
      existingValueAction,
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
