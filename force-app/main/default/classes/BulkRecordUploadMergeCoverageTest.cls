/**
 * Covers configured existing-value merging against real records, the date
 * comparison strategy, and the extension registration contracts.
 */
@IsTest
private with sharing class BulkRecordUploadMergeCoverageTest {
  private static final String PROCESS_KEY = 'MergeCoverage';

  @IsTest
  static void mergeExistingValues_AppliesConfiguredPolicyPerRow() {
    Account existing = BulkRecordUploadTestDataFactory.createAccountWithDescription(
      'Merge Coverage Base',
      'Existing'
    );

    BulkRecordUploadProjection projection = descriptionProjection('APPEND');
    BulkRecordUploadMappedRow row = new BulkRecordUploadMappedRow(
      2,
      new Account(Id = existing.Id, Description = 'Incoming')
    );

    Test.startTest();
    new BulkRecordUploadExistingValueMerger()
      .mergeExistingValues(
        projection,
        new List<BulkRecordUploadMappedRow>{ row }
      );
    Test.stopTest();

    Assert.isTrue(row.isValid(), 'A merged row should stay valid.');
    Assert.areEqual(
      'Existing Incoming',
      (String) row.record.get('Description'),
      'Append should join the existing value and the incoming value.'
    );
  }

  @IsTest
  static void mergeExistingValues_FailsRowWhenMatchedRecordIsUnavailable() {
    Id missingId = BulkRecordUploadTestDataFactory.removeAccount(
      BulkRecordUploadTestDataFactory.createAccount('Merge Coverage Removed')
    );

    BulkRecordUploadProjection projection = descriptionProjection('APPEND');
    BulkRecordUploadMappedRow row = new BulkRecordUploadMappedRow(
      2,
      new Account(Id = missingId, Description = 'Incoming')
    );

    Test.startTest();
    new BulkRecordUploadExistingValueMerger()
      .mergeExistingValues(
        projection,
        new List<BulkRecordUploadMappedRow>{ row }
      );
    Test.stopTest();

    Assert.isFalse(
      row.isValid(),
      'A row whose matched record disappeared should fail.'
    );
    Assert.areEqual(
      BulkRecordUploadRuntimeContract.REASON_MATCH_ERROR,
      row.errorCode,
      'An unavailable match should report the match error reason.'
    );
  }

  @IsTest
  static void mergeExistingValues_PreservesRowCorrelationOnPolicyFailure() {
    Account existing = BulkRecordUploadTestDataFactory.createAccountWithDescription(
      'Merge Coverage Unsupported',
      'Existing'
    );

    // ADD is a numeric action; a text field cannot support it.
    BulkRecordUploadProjection projection = descriptionProjection('ADD');
    BulkRecordUploadMappedRow row = new BulkRecordUploadMappedRow(
      7,
      new Account(Id = existing.Id, Description = 'Incoming')
    );

    Test.startTest();
    new BulkRecordUploadExistingValueMerger()
      .mergeExistingValues(
        projection,
        new List<BulkRecordUploadMappedRow>{ row }
      );
    Test.stopTest();

    Assert.isFalse(row.isValid(), 'An unsupported policy should fail the row.');
    Assert.areEqual(
      7,
      row.rowNumber,
      'The original CSV row number should survive a policy failure.'
    );
    Assert.areEqual(
      BulkRecordUploadRuntimeContract.REASON_VALIDATION_ERROR,
      row.errorCode,
      'An unsupported policy should report the validation reason.'
    );
  }

  @IsTest
  static void mergeExistingValues_SkipsWorkWithoutMergeFieldsOrIds() {
    BulkRecordUploadProjection replaceOnly = descriptionProjection('REPLACE');
    Account existing = BulkRecordUploadTestDataFactory.createAccount(
      'Merge Coverage Replace'
    );
    BulkRecordUploadMappedRow replaceRow = new BulkRecordUploadMappedRow(
      2,
      new Account(Id = existing.Id, Description = 'Incoming')
    );
    BulkRecordUploadMappedRow withoutId = new BulkRecordUploadMappedRow(
      3,
      new Account(Description = 'Incoming')
    );

    Test.startTest();
    Integer queriesBefore = Limits.getQueries();
    new BulkRecordUploadExistingValueMerger()
      .mergeExistingValues(
        descriptionProjection('APPEND'),
        new List<BulkRecordUploadMappedRow>{ withoutId }
      );
    Integer queriesAfterNoIds = Limits.getQueries();
    new BulkRecordUploadExistingValueMerger()
      .mergeExistingValues(
        replaceOnly,
        new List<BulkRecordUploadMappedRow>{ replaceRow }
      );
    Test.stopTest();

    Assert.areEqual(
      queriesBefore,
      queriesAfterNoIds,
      'Rows without matched ids should not query existing values.'
    );
    Assert.areEqual(
      'Incoming',
      (String) replaceRow.record.get('Description'),
      'A replace-only projection should leave the incoming value alone.'
    );
  }

  @IsTest
  static void dateCompareStrategy_KeepsLaterAndEarlierValues() {
    BulkRecordUploadFieldProjection dateField = typedField('DATE', 'USE_LATER');
    BulkRecordUploadFieldProjection datetimeField = typedField(
      'DATETIME',
      'USE_EARLIER'
    );
    Date earlierDate = Date.newInstance(2026, 1, 1);
    Date laterDate = Date.newInstance(2026, 6, 1);
    Datetime earlierMoment = Datetime.newInstanceGmt(2026, 1, 1, 0, 0, 0);
    Datetime laterMoment = Datetime.newInstanceGmt(2026, 6, 1, 0, 0, 0);

    BulkRecordUploadDateCompareStrategy useLater = new BulkRecordUploadDateCompareStrategy(
      true
    );
    BulkRecordUploadDateCompareStrategy useEarlier = new BulkRecordUploadDateCompareStrategy(
      false
    );

    Assert.isTrue(
      useLater.supportsType('DATE'),
      'Date comparison should support DATE.'
    );
    Assert.isFalse(
      useLater.supportsType('STRING'),
      'Date comparison should reject unrelated types.'
    );
    Assert.areEqual(
      laterDate,
      useLater.combine(dateField, earlierDate, laterDate, null),
      'Use Later should keep the later date.'
    );
    Assert.areEqual(
      laterDate,
      useLater.combine(dateField, laterDate, earlierDate, null),
      'Use Later should keep the existing date when it is later.'
    );
    Assert.areEqual(
      earlierMoment,
      useEarlier.combine(datetimeField, laterMoment, earlierMoment, null),
      'Use Earlier should keep the earlier date/time.'
    );
    Assert.areEqual(
      earlierMoment,
      useEarlier.combine(datetimeField, earlierMoment, laterMoment, null),
      'Use Earlier should keep the existing date/time when it is earlier.'
    );
  }

  @IsTest
  static void extensionAdapter_DefaultsToNoOpPhases() {
    BulkRecordUploadExtensionAdapter adapter = new BulkRecordUploadExtensionAdapter();
    BulkRecordUploadProjection projection = descriptionProjection('REPLACE');
    List<BulkRecordUploadRow> rows = new List<BulkRecordUploadRow>();

    Assert.areEqual(
      rows,
      adapter.beforeMap(projection, rows),
      'The default adapter should return rows unchanged.'
    );

    adapter.afterProcess(
      null,
      projection,
      new List<BulkRecordUploadRowResult>()
    );
    Assert.isInstanceOfType(
      adapter,
      BulkRecordUploadExtension.class,
      'The adapter should satisfy the extension contract.'
    );
  }

  @IsTest
  static void extensionConfig_RejectsIncompleteRegistrations() {
    try {
      new BulkRecordUploadExtensionConfig(null);
      Assert.fail('Expected a missing registration to be rejected.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(
        error.getMessage().contains('required'),
        'A missing registration should explain that it is required.'
      );
    }

    try {
      new BulkRecordUploadExtensionConfig(
        new Bulk_Record_Upload_Extension__mdt(
          ClassName__c = '  ',
          SortOrder__c = 1
        )
      );
      Assert.fail('Expected a blank class name to be rejected.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(
        error.getMessage().contains('class name'),
        'A blank class name should be named in the message.'
      );
    }

    try {
      new BulkRecordUploadExtensionConfig(
        new Bulk_Record_Upload_Extension__mdt(
          ClassName__c = 'SomeExtension',
          SortOrder__c = null
        )
      );
      Assert.fail('Expected a missing sort order to be rejected.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(
        error.getMessage().contains('sort order'),
        'A missing sort order should be named in the message.'
      );
    }
  }

  @IsTest
  static void extensionConfig_SortsBySortOrderThenClassName() {
    BulkRecordUploadExtensionConfig first = config('Alpha', 1);
    BulkRecordUploadExtensionConfig second = config('Beta', 2);
    BulkRecordUploadExtensionConfig tieBreak = config('Alpha2', 1);

    Assert.areEqual(
      -1,
      first.compareTo(second),
      'A lower sort order should sort first.'
    );
    Assert.areEqual(
      1,
      second.compareTo(first),
      'A higher sort order should sort last.'
    );
    Assert.isTrue(
      first.compareTo(tieBreak) < 0,
      'A tie should fall back to the class name.'
    );

    List<BulkRecordUploadExtensionConfig> ordered = new List<BulkRecordUploadExtensionConfig>{
      second,
      tieBreak,
      first
    };
    ordered.sort();
    Assert.areEqual(
      'Alpha',
      ordered[0].className,
      'Sorting should place the lowest sort order and class name first.'
    );
    Assert.areEqual(
      'Beta',
      ordered[2].className,
      'Sorting should place the highest sort order last.'
    );
  }

  private static BulkRecordUploadExtensionConfig config(
    String className,
    Integer sortOrder
  ) {
    return new BulkRecordUploadExtensionConfig(
      new Bulk_Record_Upload_Extension__mdt(
        ClassName__c = className,
        SortOrder__c = sortOrder
      )
    );
  }

  private static BulkRecordUploadProjection descriptionProjection(
    String existingValueAction
  ) {
    return new BulkRecordUploadProjection(
      PROCESS_KEY,
      'hash',
      'Account',
      'UPDATE',
      new List<String>(),
      50,
      30,
      new List<BulkRecordUploadFieldProjection>{
        field('Description', 'TEXTAREA', existingValueAction)
      }
    );
  }

  private static BulkRecordUploadFieldProjection typedField(
    String fieldType,
    String existingValueAction
  ) {
    return field('Description', fieldType, existingValueAction);
  }

  private static BulkRecordUploadFieldProjection field(
    String fieldApiName,
    String fieldType,
    String existingValueAction
  ) {
    return new BulkRecordUploadFieldProjection(
      fieldApiName.toLowerCase(),
      fieldApiName,
      fieldApiName,
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
}
