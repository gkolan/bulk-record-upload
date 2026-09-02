/** Focused regression coverage for defects fixed during release validation. */
@IsTest
private with sharing class BulkRecordUploadBugRegressionTest {
  @IsTest
  static void valueCoercer_IsoOffsetWithMilliseconds_NormalizesToUtc() {
    Test.startTest();
    Datetime actual = (Datetime) new BulkRecordUploadValueCoercer()
      .coerce('2026-08-12T10:11:12.345+02:30', 'DATETIME');
    Test.stopTest();

    Long expected =
      Datetime.newInstanceGmt(2026, 8, 12, 7, 41, 12).getTime() + 345;
    Assert.areEqual(
      expected,
      actual.getTime(),
      'An ISO offset and milliseconds should normalize to the same UTC instant.'
    );
  }

  @IsTest
  static void valueCoercer_ExcessFractionPrecision_IsRejectedSafely() {
    Test.startTest();
    try {
      new BulkRecordUploadValueCoercer()
        .coerce('2026-08-12T10:11:12.1234Z', 'DATETIME');
      Assert.fail('More than three fractional-second digits should fail.');
    } catch (BulkRecordUploadException error) {
      Assert.areEqual(
        'A field value has an invalid format.',
        error.getMessage(),
        'Invalid precision should return the bounded coercion message.'
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void valueCoercer_PipeMultiPicklist_NormalizesToSalesforceFormat() {
    Test.startTest();
    Object actual = new BulkRecordUploadValueCoercer()
      .coerce(' Alpha | Beta |Gamma ', 'MULTIPICKLIST');
    Test.stopTest();

    Assert.areEqual(
      'Alpha;Beta;Gamma',
      actual,
      'Pipe-delimited values should be trimmed and joined with semicolons.'
    );
  }

  @IsTest
  static void resultWriter_NonnumericNegative_IsFormulaGuarded() {
    List<BulkRecordUploadRowResult> results = new List<BulkRecordUploadRowResult>{
      new BulkRecordUploadRowResult(2, false, null, 'INVALID_VALUE', '-1+cmd')
    };

    Test.startTest();
    String csv = new BulkRecordUploadResultWriter().write(results).toString();
    Test.stopTest();

    Assert.isTrue(
      csv.contains('"\'-1+cmd"'),
      'A negative expression should receive an apostrophe formula guard.'
    );
  }

  @IsTest
  static void recordMapper_DefaultPatternAndBlankRows_AreRowScoped() {
    BulkRecordUploadProjection projection = mappingProjection(
      mappingField('DEFAULT', 'Default Name', true, '[A-Z][A-Za-z ]+')
    );
    List<BulkRecordUploadRow> rows = new List<BulkRecordUploadRow>{
      row(2, 'Acme', null),
      row(3, '', 'present'),
      row(4, '123 invalid', null),
      row(5, '', null)
    };

    Test.startTest();
    List<BulkRecordUploadMappedRow> mapped = new BulkRecordUploadRecordMapper()
      .mapRows(projection, rows);
    Test.stopTest();

    Assert.areEqual(4, mapped.size(), 'Every physical row should be retained.');
    Assert.areEqual('Acme', mapped[0].record.get('Name'), 'Valid input maps.');
    Assert.areEqual(
      'Default Name',
      mapped[1].record.get('Name'),
      'A nonblank row with a blank configured value should use the default.'
    );
    Assert.isFalse(
      mapped[2].isValid(),
      'Pattern failure should be row scoped.'
    );
    Assert.areEqual(
      4,
      mapped[2].rowNumber,
      'Pattern row correlation remains stable.'
    );
    Assert.isFalse(
      mapped[3].isValid(),
      'An interior blank row should fail safely.'
    );
    Assert.areEqual(
      5,
      mapped[3].rowNumber,
      'Blank row correlation remains stable.'
    );
  }

  @IsTest
  static void recordMapper_RequiredBlank_DoesNotRejectSiblingRows() {
    BulkRecordUploadProjection projection = mappingProjection(
      mappingField('REJECT', null, true, null)
    );
    List<BulkRecordUploadRow> rows = new List<BulkRecordUploadRow>{
      row(2, 'First', null),
      row(3, '', 'present'),
      row(4, 'Third', null)
    };

    Test.startTest();
    List<BulkRecordUploadMappedRow> mapped = new BulkRecordUploadRecordMapper()
      .mapRows(projection, rows);
    Test.stopTest();

    Assert.isTrue(
      mapped[0].isValid(),
      'The first valid row should remain valid.'
    );
    Assert.isFalse(
      mapped[1].isValid(),
      'Only the required-blank row should fail.'
    );
    Assert.areEqual(
      BulkRecordUploadRuntimeContract.REASON_VALIDATION_ERROR,
      mapped[1].errorCode,
      'Required blank should use the stable validation reason code.'
    );
    Assert.isTrue(mapped[2].isValid(), 'A later valid row should still map.');
  }

  @IsTest
  static void contextFilter_ValueContainingColons_IsPreserved() {
    Test.startTest();
    BulkRecordUploadContextProjection projection = new BulkRecordUploadContextSourceService()
      .buildContextProjection(
        'USER_CHOICE',
        'Account',
        'Name',
        'Name',
        'Website:=:https://example.test:8443/a:b'
      );
    Test.stopTest();

    Assert.areEqual(
      'https://example.test:8443/a:b',
      projection.filterConditions[0].values[0],
      'Only the first two delimiters should separate a context filter.'
    );
  }

  @IsTest
  static void recordResolver_CaseVariantAmbiguity_FailsOnlyAffectedRow() {
    Account uniqueAccount = BulkRecordUploadTestDataFactory.createAccount(
      'Unique Resolver Account'
    );
    BulkRecordUploadTestDataFactory.createAccount('Duplicate Resolver Account');
    BulkRecordUploadTestDataFactory.createAccount('duplicate resolver account');
    List<BulkRecordUploadMappedRow> rows = new List<BulkRecordUploadMappedRow>{
      new BulkRecordUploadMappedRow(
        2,
        new Account(Name = 'uNIQUE rESOLVER aCCOUNT')
      ),
      new BulkRecordUploadMappedRow(
        3,
        new Account(Name = 'DUPLICATE RESOLVER ACCOUNT')
      )
    };

    Test.startTest();
    new BulkRecordUploadRecordResolver()
      .assignRecordIds(resolverProjection(), rows);
    Test.stopTest();

    Assert.areEqual(
      uniqueAccount.Id,
      rows[0].record.Id,
      'Case should canonicalize.'
    );
    Assert.isTrue(rows[0].isValid(), 'The unique row should remain valid.');
    Assert.isFalse(
      rows[1].isValid(),
      'The ambiguous case variant should fail.'
    );
    Assert.areEqual(
      BulkRecordUploadRuntimeContract.REASON_MATCH_ERROR,
      rows[1].errorCode,
      'Ambiguity should use the stable match error code.'
    );
  }

  @IsTest
  static void lookupCanonical_NumericScale_IsNormalized() {
    Test.startTest();
    String actual = BulkRecordUploadLookupResolver.canonicalValue(
      Decimal.valueOf('10.000'),
      'DOUBLE'
    );
    Test.stopTest();

    Assert.areEqual(
      '10',
      actual,
      'Equivalent numeric scales should share a key.'
    );
  }

  @IsTest
  static void persistence_MixedInvalidAndValidRows_PreservesInputOrder() {
    BulkRecordUploadMappedRow firstInvalid = new BulkRecordUploadMappedRow(
      8,
      new Account()
    );
    firstInvalid.markFailed('VALIDATION_ERROR', 'First invalid row.');
    BulkRecordUploadMappedRow secondInvalid = new BulkRecordUploadMappedRow(
      10,
      new Account()
    );
    secondInvalid.markFailed('MATCH_ERROR', 'Second invalid row.');
    List<BulkRecordUploadMappedRow> rows = new List<BulkRecordUploadMappedRow>{
      firstInvalid,
      new BulkRecordUploadMappedRow(9, new Account(Name = 'Ordered One')),
      secondInvalid,
      new BulkRecordUploadMappedRow(11, new Account(Name = 'Ordered Two'))
    };

    Test.startTest();
    List<BulkRecordUploadRowResult> results = new BulkRecordUploadPersistenceGateway()
      .persist('INSERT', rows, null);
    Test.stopTest();

    Assert.areEqual(
      4,
      results.size(),
      'Every input row should have one result.'
    );
    Assert.areEqual(8, results[0].rowNumber, 'First invalid row stays first.');
    Assert.areEqual(9, results[1].rowNumber, 'First valid row stays second.');
    Assert.areEqual(
      10,
      results[2].rowNumber,
      'Second invalid row stays third.'
    );
    Assert.areEqual(11, results[3].rowNumber, 'Second valid row stays fourth.');
    Assert.isFalse(
      results[0].isSuccess,
      'Pre-DML failure should remain failed.'
    );
    Assert.isTrue(results[1].isSuccess, 'First valid row should be inserted.');
    Assert.isFalse(
      results[2].isSuccess,
      'Second pre-DML failure remains failed.'
    );
    Assert.isTrue(results[3].isSuccess, 'Second valid row should be inserted.');
  }

  @IsTest
  static void projectionHash_BehaviorFlags_ChangeFingerprint() {
    String baseline = fingerprint(
      fieldMetadata('Name', false, false, false, false)
    );

    Test.startTest();
    String labelHash = fingerprint(
      fieldMetadata('Account Name', false, false, false, false)
    );
    String requiredHash = fingerprint(
      fieldMetadata('Name', true, false, false, false)
    );
    String resultHash = fingerprint(
      fieldMetadata('Name', false, false, false, true)
    );
    Test.stopTest();

    Assert.areNotEqual(
      baseline,
      labelHash,
      'Display label should affect the hash.'
    );
    Assert.areNotEqual(
      baseline,
      requiredHash,
      'Required flag should affect the hash.'
    );
    Assert.areNotEqual(
      baseline,
      resultHash,
      'Result flag should affect the hash.'
    );
  }

  private static BulkRecordUploadRow row(
    Integer rowNumber,
    String name,
    String marker
  ) {
    Map<String, String> values = new Map<String, String>{ 'name' => name };
    if (marker != null) {
      values.put('marker', marker);
    }
    return new BulkRecordUploadRow(rowNumber, values);
  }

  private static BulkRecordUploadFieldProjection mappingField(
    String blankAction,
    String defaultValue,
    Boolean required,
    String validationPattern
  ) {
    return new BulkRecordUploadFieldProjection(
      'name',
      'Name',
      'Name',
      'STRING',
      'REPLACE',
      blankAction,
      'SPACE',
      null,
      'SKIP',
      'REJECT',
      defaultValue,
      true,
      'NONE',
      new Set<String>(),
      null,
      validationPattern,
      null,
      null,
      null,
      null,
      null,
      1,
      required,
      false,
      false,
      true,
      true,
      true
    );
  }

  private static BulkRecordUploadProjection mappingProjection(
    BulkRecordUploadFieldProjection field
  ) {
    return new BulkRecordUploadProjection(
      'BUG_MAPPING',
      'hash',
      'Account',
      'INSERT',
      new List<String>(),
      100,
      30,
      new List<BulkRecordUploadFieldProjection>{ field }
    );
  }

  private static BulkRecordUploadProjection resolverProjection() {
    BulkRecordUploadFieldProjection field = new BulkRecordUploadFieldProjection(
      'name',
      'Name',
      'Name',
      'STRING',
      'REPLACE',
      1,
      true,
      true,
      false,
      true,
      true,
      true
    );
    return new BulkRecordUploadProjection(
      'BUG_RESOLVER',
      'hash',
      'Account',
      'UPDATE',
      new List<String>(),
      100,
      30,
      new List<BulkRecordUploadFieldProjection>{ field }
    );
  }

  private static Bulk_Record_Upload_Process_Field__mdt fieldMetadata(
    String displayLabel,
    Boolean required,
    Boolean matchKey,
    Boolean upsertKey,
    Boolean includeInResult
  ) {
    return new Bulk_Record_Upload_Process_Field__mdt(
      DeveloperName = 'HASH_NAME',
      ProcessDeveloperName__c = 'HASH_PROCESS',
      CsvColumnHeader__c = 'name',
      DisplayLabel__c = displayLabel,
      FieldApiName__c = 'Name',
      ExistingValueAction__c = 'REPLACE',
      ColumnOrder__c = 1,
      IsRequired__c = required,
      IsMatchField__c = matchKey,
      IsUpsertExternalId__c = upsertKey,
      IncludeInResult__c = includeInResult,
      IsActive__c = true
    );
  }

  private static String fingerprint(
    Bulk_Record_Upload_Process_Field__mdt fieldRecord
  ) {
    Bulk_Record_Upload_Process__mdt process = new Bulk_Record_Upload_Process__mdt(
      DeveloperName = 'HASH_PROCESS',
      ObjectApiName__c = 'Account',
      Operation__c = 'INSERT',
      RowsPerBatch__c = 100,
      RetentionDays__c = 30,
      ConfigurationVersion__c = 2,
      IsActive__c = true
    );
    BulkRecordUploadConfigRepository.Configuration configuration = new BulkRecordUploadConfigRepository(
        new Map<String, Bulk_Record_Upload_Process__mdt>{
          process.DeveloperName => process
        },
        new List<Bulk_Record_Upload_Process_Field__mdt>{ fieldRecord },
        new List<Bulk_Record_Upload_Extension__mdt>()
      )
      .findActive(process.DeveloperName);
    return BulkRecordUploadProjectionFingerprint.configHash(
      configuration,
      new List<String>(),
      null
    );
  }
}
