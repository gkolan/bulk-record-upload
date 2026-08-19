/** Verifies defensive and invalid-input branches in versioned value contracts. */
@IsTest
private class BulkRecordUploadEdgeCoverageTest {
  @IsTest
  static void valueCoercer_AllSupportedAndRejectedValues_AreDeterministic() {
    BulkRecordUploadValueCoercer coercer = new BulkRecordUploadValueCoercer();
    Test.startTest();
    Assert.isNull(coercer.coerce(null, 'STRING'), 'Null stays null.');
    Assert.areEqual(7L, coercer.coerce('7', 'LONG'), 'Long is supported.');
    Assert.areEqual(
      false,
      coercer.coerce('no', 'BOOLEAN'),
      'False is supported.'
    );
    Assert.areEqual(
      Datetime.newInstanceGmt(2026, 8, 12, 10, 11, 12),
      coercer.coerce('2026-08-12T10:11:12Z', 'DATETIME'),
      'UTC datetime is supported.'
    );
    assertCoercionFailure(coercer, 'maybe', 'BOOLEAN', 'invalid format');
    assertCoercionFailure(coercer, 'x', 'ADDRESS', 'not supported');
    Test.stopTest();
  }

  @IsTest
  static void handlers_NullInputs_AreRejected() {
    Test.startTest();
    assertHandlerFailure(new BulkRecordUploadStandardHandlerV1());
    assertHandlerFailure(new BulkRecordUploadTrimHandlerV1());
    Test.stopTest();
  }

  @IsTest
  static void operationStrategy_InvalidProjectionAndUpsertKey_AreRejected() {
    Test.startTest();
    try {
      new BulkRecordUploadOperationStrategy('INSERT').validateProjection(null);
      Assert.fail('Null projection should fail.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(
        error.getMessage().contains('invalid'),
        'Safe error expected.'
      );
    }
    try {
      new BulkRecordUploadOperationStrategy('UPSERT')
        .validateProjection(projection('UPSERT', field(false, false, 1)));
      Assert.fail('Upsert without a key should fail.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(
        error.getMessage().contains('upsert key'),
        'Key error expected.'
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void contracts_InvalidInputs_AreRejectedAndCopiesAreDefensive() {
    Test.startTest();
    assertProjectionFailure(6, 'Retention days');
    assertProjectionTextFailure();
    assertFieldProjectionFailure();
    assertMappedRowFailure();
    assertResultRowFailure();
    assertRowValuesFailure();
    BulkRecordUploadParsedCsvV1 parsed = new BulkRecordUploadParsedCsvV1(
      new List<String>{ 'name' },
      BulkRecordUploadTestDataFactory.createRows(1)
    );
    List<BulkRecordUploadRowV1> rows = parsed.getRows();
    rows.clear();
    Assert.areEqual(
      1,
      parsed.rows.size(),
      'Parsed rows are defensively copied.'
    );
    Test.stopTest();
  }

  @IsTest
  static void processConfig_DefaultsAndBounds_AreValidated() {
    Test.startTest();
    BulkRecordUploadProcessConfigV1 defaults = new BulkRecordUploadProcessConfigV1(
      process('  DEMO  ', null, null, null, null)
    );
    Assert.areEqual(100, defaults.batchSize, 'Default batch is stable.');
    Assert.areEqual(90, defaults.retentionDays, 'Default retention is stable.');
    Assert.isNull(
      defaults.previewPermission,
      'Blank preview permission is null.'
    );
    assertProcessFailure(null, 'Developer Name');
    assertProcessFailure(process('X', 24, 90, 1, null), 'batch size');
    assertProcessFailure(process('X', 100, 6, 1, null), 'retention');
    assertProcessFailure(process('X', 100, 90, 3, null), 'version');
    Bulk_Record_Upload_Process__mdt missing = process('X', 100, 90, 1, null);
    missing.ObjectApiName__c = ' ';
    assertProcessFailure(missing, 'Target object');
    Test.stopTest();
  }

  @IsTest
  static void fieldConfig_NullBoundsBehaviorAndSort_AreValidated() {
    Test.startTest();
    assertFieldConfigFailure(null, 'required');
    assertFieldConfigFailure(fieldRecord(null, 'REPLACE', 1), 'Column key');
    assertFieldConfigFailure(fieldRecord('name', 'REPLACE', null), 'sequence');
    assertFieldConfigFailure(
      fieldRecord('name', 'EXECUTE', 1),
      'not supported'
    );
    BulkRecordUploadFieldConfigV1 beta = new BulkRecordUploadFieldConfigV1(
      fieldRecord('beta', 'REPLACE', 1)
    );
    BulkRecordUploadFieldConfigV1 alpha = new BulkRecordUploadFieldConfigV1(
      fieldRecord('alpha', 'REPLACE', 1)
    );
    Assert.isTrue(
      alpha.compareTo(beta) < 0,
      'Same-order fields sort by API name.'
    );
    Test.stopTest();
  }

  @IsTest
  static void operationRegistry_TrimsAndResolvesKnownKey() {
    Test.startTest();
    Assert.isNotNull(
      new BulkRecordUploadOperationRegistry().resolve(' insert ')
    );
    Test.stopTest();
  }

  private static void assertCoercionFailure(
    BulkRecordUploadValueCoercer coercer,
    String value,
    String typeName,
    String fragment
  ) {
    try {
      coercer.coerce(value, typeName);
      Assert.fail('Coercion should fail.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(
        error.getMessage().contains(fragment),
        'Expected safe coercion error.'
      );
    }
  }

  private static void assertHandlerFailure(BulkRecordUploadHandlerV1 handler) {
    try {
      handler.handle(null, null);
      Assert.fail('Invalid handler input should fail.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(
        error.getMessage().contains('required'),
        'Required-input error expected.'
      );
    }
  }

  private static void assertProjectionFailure(
    Integer retention,
    String fragment
  ) {
    try {
      new BulkRecordUploadProjectionV1(
        'P',
        'H',
        'Account',
        'INSERT',
        'STANDARD_V1',
        100,
        retention,
        new List<BulkRecordUploadFieldProjectionV1>{ field(false, false, 1) }
      );
      Assert.fail('Projection should fail.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(
        error.getMessage().contains(fragment),
        'Projection error expected.'
      );
    }
  }

  private static void assertProjectionTextFailure() {
    try {
      new BulkRecordUploadProjectionV1(
        ' ',
        'H',
        'Account',
        'INSERT',
        'STANDARD_V1',
        100,
        30,
        new List<BulkRecordUploadFieldProjectionV1>{ field(false, false, 1) }
      );
      Assert.fail('Blank key should fail.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(
        error.getMessage().contains('processKey'),
        'Property error expected.'
      );
    }
  }

  private static void assertFieldProjectionFailure() {
    try {
      new BulkRecordUploadFieldProjectionV1(
        'name',
        'Name',
        'Name',
        'STRING',
        'REPLACE',
        0,
        false,
        false,
        false,
        true,
        true,
        true
      );
      Assert.fail('Sequence should fail.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(
        error.getMessage().contains('positive'),
        'Sequence error expected.'
      );
    }
  }

  private static void assertMappedRowFailure() {
    try {
      new BulkRecordUploadMappedRowV1(1, null);
      Assert.fail('Mapped row should fail.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(
        error.getMessage().contains('invalid'),
        'Mapped-row error expected.'
      );
    }
  }

  private static void assertResultRowFailure() {
    try {
      new BulkRecordUploadRowResultV1(1, true, null, null, null);
      Assert.fail('Result row should fail.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(
        error.getMessage().contains('at least 2'),
        'Row error expected.'
      );
    }
  }

  private static void assertRowValuesFailure() {
    try {
      new BulkRecordUploadRowV1(2, null);
      Assert.fail('Null values should fail.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(
        error.getMessage().contains('required'),
        'Values error expected.'
      );
    }
  }

  private static void assertProcessFailure(
    Bulk_Record_Upload_Process__mdt value,
    String fragment
  ) {
    try {
      new BulkRecordUploadProcessConfigV1(value);
      Assert.fail('Process config should fail.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(
        error.getMessage().contains(fragment),
        'Process error expected.'
      );
    }
  }

  private static void assertFieldConfigFailure(
    Bulk_Record_Upload_Process_Field__mdt value,
    String fragment
  ) {
    try {
      new BulkRecordUploadFieldConfigV1(value);
      Assert.fail('Field config should fail.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(
        error.getMessage().contains(fragment),
        'Field error expected.'
      );
    }
  }

  private static Bulk_Record_Upload_Process__mdt process(
    String name,
    Decimal batch,
    Decimal retention,
    Decimal version,
    String permissionName
  ) {
    return new Bulk_Record_Upload_Process__mdt(
      DeveloperName = name,
      ObjectApiName__c = 'Account',
      Operation__c = 'INSERT',
      ProcessingHandler__c = 'STANDARD_V1',
      RowsPerBatch__c = batch,
      RetentionDays__c = retention,
      ConfigurationVersion__c = version,
      PreviewPermissionApiName__c = permissionName
    );
  }

  private static Bulk_Record_Upload_Process_Field__mdt fieldRecord(
    String column,
    String existingValueAction,
    Decimal orderValue
  ) {
    return new Bulk_Record_Upload_Process_Field__mdt(
      CsvColumnHeader__c = column,
      DisplayLabel__c = 'Name',
      FieldApiName__c = column == 'beta'
        ? 'Beta__c'
        : column == 'alpha' ? 'Alpha__c' : 'Name',
      ExistingValueAction__c = existingValueAction,
      ColumnOrder__c = orderValue
    );
  }

  private static BulkRecordUploadProjectionV1 projection(
    String operation,
    BulkRecordUploadFieldProjectionV1 projectedField
  ) {
    return new BulkRecordUploadProjectionV1(
      'P',
      'H',
      'Account',
      operation,
      'STANDARD_V1',
      100,
      30,
      new List<BulkRecordUploadFieldProjectionV1>{ projectedField }
    );
  }

  private static BulkRecordUploadFieldProjectionV1 field(
    Boolean matchKey,
    Boolean upsertKey,
    Integer sequence
  ) {
    return new BulkRecordUploadFieldProjectionV1(
      'name',
      'Name',
      'Name',
      'STRING',
      'REPLACE',
      sequence,
      true,
      matchKey,
      upsertKey,
      true,
      true,
      true
    );
  }
}
