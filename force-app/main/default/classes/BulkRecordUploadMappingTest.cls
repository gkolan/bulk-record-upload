@IsTest
private class BulkRecordUploadMappingTest {
  @IsTest
  static void mapper_ConfiguredFieldsOnly_CoercesAndCorrelates() {
    List<BulkRecordUploadFieldProjectionV1> fields = new List<BulkRecordUploadFieldProjectionV1>{
      field('name', 'Name', 'STRING', 'REPLACE', 1),
      field('employees', 'NumberOfEmployees', 'INTEGER', 'REPLACE', 2)
    };
    BulkRecordUploadProjectionV1 projection = projection(fields);
    BulkRecordUploadRowV1 row = new BulkRecordUploadRowV1(
      7,
      new Map<String, String>{
        'name' => 'Acme',
        'employees' => '42',
        'ignored' => 'secret'
      }
    );

    List<BulkRecordUploadMappedRowV1> mapped = new BulkRecordUploadRecordMapper()
      .mapRows(projection, new List<BulkRecordUploadRowV1>{ row });

    Assert.areEqual(7, mapped[0].rowNumber);
    Assert.areEqual('Acme', mapped[0].record.get('Name'));
    Assert.areEqual(42, mapped[0].record.get('NumberOfEmployees'));
    Assert.isFalse(
      mapped[0].record.getPopulatedFieldsAsMap().containsKey('ignored')
    );
  }

  @IsTest
  static void mergePolicy_AppendSeparatorDuplicateAndOverflow_AreSafe() {
    BulkRecordUploadFieldProjectionV1 appendField = new BulkRecordUploadFieldProjectionV1(
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
    BulkRecordUploadFieldProjectionV1 clearField = new BulkRecordUploadFieldProjectionV1(
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
  static void coercer_SupportedScalarTypes_ReturnTypedValues() {
    BulkRecordUploadValueCoercer coercer = new BulkRecordUploadValueCoercer();
    Assert.areEqual(true, coercer.coerce('yes', 'BOOLEAN'));
    Assert.areEqual(12.5, coercer.coerce('12.5', 'CURRENCY'));
    Assert.areEqual(
      Date.newInstance(2026, 8, 12),
      coercer.coerce('2026-08-12', 'DATE')
    );
  }

  @IsTest
  static void coercer_InvalidValue_RedactsRawInput() {
    try {
      new BulkRecordUploadValueCoercer().coerce('sensitive-value', 'INTEGER');
      Assert.fail('Expected invalid-format exception.');
    } catch (BulkRecordUploadException error) {
      Assert.areEqual(
        'A field value has an invalid format.',
        error.getMessage()
      );
      Assert.isFalse(error.getMessage().contains('sensitive-value'));
    }
  }

  private static BulkRecordUploadProjectionV1 projection(
    List<BulkRecordUploadFieldProjectionV1> fields
  ) {
    return new BulkRecordUploadProjectionV1(
      'ACCOUNT_INSERT',
      'hash',
      'Account',
      'INSERT',
      'STANDARD_V1',
      100,
      30,
      fields
    );
  }

  private static BulkRecordUploadFieldProjectionV1 field(
    String columnKey,
    String apiName,
    String fieldType,
    String existingValueAction,
    Integer sequence
  ) {
    return new BulkRecordUploadFieldProjectionV1(
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
}
