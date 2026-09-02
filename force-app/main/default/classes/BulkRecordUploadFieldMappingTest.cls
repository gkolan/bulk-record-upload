@IsTest
private class BulkRecordUploadFieldMappingTest {
  @IsTest
  static void mapper_CaseActionMultiPicklist_AppliesPerToken() {
    BulkRecordUploadFieldProjection tagsField = new BulkRecordUploadFieldProjection(
      'tags',
      'Tags',
      'Industry',
      'MULTIPICKLIST',
      'REPLACE',
      'IGNORE',
      'SPACE',
      null,
      'SKIP',
      'REJECT',
      null,
      false,
      'TITLE',
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

    String normalized = BulkRecordUploadRecordMapper.normalizeRawValue(
      'red;dark blue',
      tagsField
    );

    Assert.areEqual('Red;Dark Blue', normalized);
  }

  @IsTest
  static void mapper_TrimCaseAndBlankTokens_NormalizeBeforeCoercion() {
    BulkRecordUploadFieldProjection nameField = new BulkRecordUploadFieldProjection(
      'name',
      'Name',
      'Name',
      'STRING',
      'REPLACE',
      'IGNORE',
      'SPACE',
      null,
      'SKIP',
      'REJECT',
      null,
      true,
      'UPPER',
      new Set<String>{ 'n/a' },
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
    BulkRecordUploadFieldProjection statusField = new BulkRecordUploadFieldProjection(
      'status',
      'Status',
      'BillingCity',
      'STRING',
      'REPLACE',
      'CLEAR',
      'SPACE',
      null,
      'SKIP',
      'REJECT',
      null,
      false,
      'NONE',
      new Set<String>{ 'n/a' },
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      2,
      false,
      false,
      false,
      true,
      true,
      true
    );
    BulkRecordUploadProjection mappingProjection = projection(
      new List<BulkRecordUploadFieldProjection>{ nameField, statusField }
    );
    BulkRecordUploadRow row = new BulkRecordUploadRow(
      2,
      new Map<String, String>{ 'name' => '  acme  ', 'status' => ' N/A ' }
    );

    List<BulkRecordUploadMappedRow> mapped = new BulkRecordUploadRecordMapper()
      .mapRows(mappingProjection, new List<BulkRecordUploadRow>{ row });

    Assert.areEqual('ACME', mapped[0].record.get('Name'));
    Assert.isNull(mapped[0].record.get('BillingCity'));
  }

  @IsTest
  static void mapper_BlankValueDefault_SubstitutesConfiguredDefault() {
    BulkRecordUploadFieldProjection defaultField = new BulkRecordUploadFieldProjection(
      'employees',
      'Employees',
      'NumberOfEmployees',
      'INTEGER',
      'REPLACE',
      'DEFAULT',
      'SPACE',
      null,
      'SKIP',
      'REJECT',
      '10',
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
    BulkRecordUploadProjection mappingProjection = projection(
      new List<BulkRecordUploadFieldProjection>{ defaultField }
    );
    BulkRecordUploadRow row = new BulkRecordUploadRow(
      2,
      new Map<String, String>{ 'employees' => '', 'marker' => 'present' }
    );

    List<BulkRecordUploadMappedRow> mapped = new BulkRecordUploadRecordMapper()
      .mapRows(mappingProjection, new List<BulkRecordUploadRow>{ row });

    Assert.areEqual(10, mapped[0].record.get('NumberOfEmployees'));
  }

  @IsTest
  static void mapper_ValidationPattern_RejectsNonMatchingValue() {
    BulkRecordUploadFieldProjection zipField = new BulkRecordUploadFieldProjection(
      'zip',
      'Zip',
      'BillingPostalCode',
      'STRING',
      'REPLACE',
      'IGNORE',
      'SPACE',
      null,
      'SKIP',
      'REJECT',
      null,
      false,
      'NONE',
      new Set<String>(),
      null,
      '[0-9]{5}',
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
    BulkRecordUploadProjection mappingProjection = projection(
      new List<BulkRecordUploadFieldProjection>{ zipField }
    );
    BulkRecordUploadRow row = new BulkRecordUploadRow(
      2,
      new Map<String, String>{ 'zip' => 'not-a-zip' }
    );

    BulkRecordUploadMappedRow mapped = new BulkRecordUploadRecordMapper()
      .mapRows(mappingProjection, new List<BulkRecordUploadRow>{ row })[0];
    Assert.isFalse(mapped.isValid(), 'The invalid row should be rejected.');
    Assert.isTrue(mapped.safeMessage.contains('required pattern'));
  }

  @IsTest
  static void mapper_MinMaxRange_RejectsOutOfRangeValue() {
    BulkRecordUploadFieldProjection employeesField = new BulkRecordUploadFieldProjection(
      'employees',
      'Employees',
      'NumberOfEmployees',
      'INTEGER',
      'REPLACE',
      'IGNORE',
      'SPACE',
      null,
      'SKIP',
      'REJECT',
      null,
      false,
      'NONE',
      new Set<String>(),
      null,
      null,
      1,
      1000,
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
    BulkRecordUploadProjection mappingProjection = projection(
      new List<BulkRecordUploadFieldProjection>{ employeesField }
    );
    BulkRecordUploadRow row = new BulkRecordUploadRow(
      2,
      new Map<String, String>{ 'employees' => '5000' }
    );

    BulkRecordUploadMappedRow mapped = new BulkRecordUploadRecordMapper()
      .mapRows(mappingProjection, new List<BulkRecordUploadRow>{ row })[0];
    Assert.isFalse(
      mapped.isValid(),
      'The out-of-range row should be rejected.'
    );
    Assert.isTrue(mapped.safeMessage.contains('above the maximum'));
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
}
