@IsTest
private class BulkRecordUploadLookupMappingTest {
  @IsTest
  static void mapper_SourceTemplate_ComposesFromOtherColumns() {
    BulkRecordUploadFieldProjection firstNameField = field(
      'first_name',
      'FirstName',
      'STRING',
      'REPLACE',
      1
    );
    BulkRecordUploadFieldProjection lastNameField = field(
      'last_name',
      'LastName',
      'STRING',
      'REPLACE',
      2
    );
    BulkRecordUploadFieldProjection fullNameField = new BulkRecordUploadFieldProjection(
      'full_name',
      'Full Name',
      'Description',
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
      null,
      null,
      null,
      '{first_name} {last_name}',
      null,
      null,
      3,
      false,
      false,
      false,
      true,
      true,
      true
    );
    BulkRecordUploadProjection mappingProjection = projection(
      new List<BulkRecordUploadFieldProjection>{
        firstNameField,
        lastNameField,
        fullNameField
      }
    );
    BulkRecordUploadRow row = new BulkRecordUploadRow(
      2,
      new Map<String, String>{
        'first_name' => 'Ada',
        'last_name' => 'Lovelace'
      }
    );

    List<BulkRecordUploadMappedRow> mapped = new BulkRecordUploadRecordMapper()
      .mapRows(mappingProjection, new List<BulkRecordUploadRow>{ row });

    Assert.areEqual('Ada Lovelace', mapped[0].record.get('Description'));
  }

  @IsTest
  static void sourceTemplate_TokensAndCompose_ParseAndSubstitute() {
    Assert.areEqual(
      new Set<String>{ 'first_name', 'last_name' },
      BulkRecordUploadSourceTemplate.tokens('{first_name} {last_name}')
    );
    Assert.areEqual(
      'Ada Lovelace',
      BulkRecordUploadSourceTemplate.compose(
        '{first_name} {last_name}',
        new Map<String, String>{
          'first_name' => 'Ada',
          'last_name' => 'Lovelace'
        }
      )
    );
    Assert.areEqual(
      'Ada ',
      BulkRecordUploadSourceTemplate.compose(
        '{first_name} {missing}',
        new Map<String, String>{ 'first_name' => 'Ada' }
      )
    );
  }

  @IsTest
  static void mapper_LookupDirectId_UsesValidIdOrThrows() {
    Account target = BulkRecordUploadTestDataFactory.createAccount(
      'Lookup Target'
    );
    BulkRecordUploadFieldProjection parentField = lookupField(null, null);
    BulkRecordUploadProjection mappingProjection = projection(
      new List<BulkRecordUploadFieldProjection>{ parentField }
    );
    BulkRecordUploadRow validRow = new BulkRecordUploadRow(
      2,
      new Map<String, String>{ 'parent' => target.Id }
    );

    List<BulkRecordUploadMappedRow> mapped = new BulkRecordUploadRecordMapper()
      .mapRows(mappingProjection, new List<BulkRecordUploadRow>{ validRow });

    Assert.areEqual(target.Id, mapped[0].record.get('ParentId'));

    BulkRecordUploadRow invalidRow = new BulkRecordUploadRow(
      2,
      new Map<String, String>{ 'parent' => 'not-an-id' }
    );
    try {
      new BulkRecordUploadRecordMapper()
        .mapRows(
          mappingProjection,
          new List<BulkRecordUploadRow>{ invalidRow }
        );
      Assert.fail('Expected an invalid-Id exception.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(error.getMessage().contains('valid Salesforce Id'));
    }
  }

  @IsTest
  static void mapper_LookupResolvedViaMatchField_UsesResolvedIdOrThrows() {
    Account target = BulkRecordUploadTestDataFactory.createAccount('Acme Corp');
    BulkRecordUploadFieldProjection parentField = lookupField(
      'Name',
      'Account'
    );
    BulkRecordUploadProjection mappingProjection = projection(
      new List<BulkRecordUploadFieldProjection>{ parentField }
    );
    Map<String, Map<String, Id>> resolutions = new Map<String, Map<String, Id>>{
      'ParentId' => new Map<String, Id>{ 'Acme Corp' => target.Id }
    };
    BulkRecordUploadRow resolvedRow = new BulkRecordUploadRow(
      2,
      new Map<String, String>{ 'parent' => 'Acme Corp' }
    );

    List<BulkRecordUploadMappedRow> mapped = new BulkRecordUploadRecordMapper()
      .mapRows(
        mappingProjection,
        new List<BulkRecordUploadRow>{ resolvedRow },
        resolutions
      );

    Assert.areEqual(target.Id, mapped[0].record.get('ParentId'));

    BulkRecordUploadRow unresolvedRow = new BulkRecordUploadRow(
      2,
      new Map<String, String>{ 'parent' => 'Unknown Co' }
    );
    try {
      new BulkRecordUploadRecordMapper()
        .mapRows(
          mappingProjection,
          new List<BulkRecordUploadRow>{ unresolvedRow },
          resolutions
        );
      Assert.fail('Expected an unresolved-lookup exception.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(error.getMessage().contains('did not resolve'));
    }
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

  private static BulkRecordUploadFieldProjection lookupField(
    String lookupMatchField,
    String lookupTargetObject
  ) {
    return new BulkRecordUploadFieldProjection(
      'parent',
      'Parent',
      'ParentId',
      'REFERENCE',
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
      null,
      null,
      null,
      lookupMatchField,
      lookupTargetObject,
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
