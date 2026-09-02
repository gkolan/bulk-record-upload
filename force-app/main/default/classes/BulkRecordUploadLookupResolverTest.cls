@IsTest
private class BulkRecordUploadLookupResolverTest {
  @IsTest
  static void resolve_UniqueAndAmbiguousAndMissingMatches_ResolvesOnlyUnique() {
    Account uniqueMatch = BulkRecordUploadTestDataFactory.createAccount(
      'Unique Co'
    );
    BulkRecordUploadTestDataFactory.createAccount('Duplicate Co');
    BulkRecordUploadTestDataFactory.createAccount('Duplicate Co');

    BulkRecordUploadFieldProjection parentField = new BulkRecordUploadFieldProjection(
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
      'Name',
      'Account',
      1,
      false,
      false,
      false,
      true,
      true,
      true
    );
    BulkRecordUploadProjection projectionValue = new BulkRecordUploadProjection(
      'ACCOUNT_INSERT',
      'hash',
      'Account',
      'INSERT',
      new List<String>(),
      100,
      30,
      new List<BulkRecordUploadFieldProjection>{ parentField }
    );
    List<BulkRecordUploadRow> rows = new List<BulkRecordUploadRow>{
      new BulkRecordUploadRow(
        2,
        new Map<String, String>{ 'parent' => 'Unique Co' }
      ),
      new BulkRecordUploadRow(
        3,
        new Map<String, String>{ 'parent' => 'Duplicate Co' }
      ),
      new BulkRecordUploadRow(
        4,
        new Map<String, String>{ 'parent' => 'No Match Co' }
      )
    };

    Test.startTest();
    Map<String, Map<String, Id>> resolutions = new BulkRecordUploadLookupResolver()
      .resolve(projectionValue, rows);
    Test.stopTest();

    Map<String, Id> parentResolutions = resolutions.get('ParentId');
    Assert.areEqual(
      uniqueMatch.Id,
      parentResolutions.get('unique co'),
      'A single matching record should resolve.'
    );
    Assert.isFalse(
      parentResolutions.containsKey('duplicate co'),
      'An ambiguous match should not resolve.'
    );
    Assert.isFalse(
      parentResolutions.containsKey('no match co'),
      'A missing match should not resolve.'
    );
  }

  @IsTest
  static void resolveLookupTargetObject_PolymorphicField_ThrowsDomainException() {
    Schema.DescribeFieldResult whoIdDescribe = Task.WhoId.getDescribe();
    Bulk_Record_Upload_Process_Field__mdt recordValue = baseRecord();

    try {
      BulkRecordUploadLookupResolver.resolveLookupTargetObject(
        new BulkRecordUploadFieldConfig(recordValue),
        whoIdDescribe
      );
      Assert.fail('Expected a polymorphic-lookup exception.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(error.getMessage().contains('Polymorphic'));
    }
  }

  @IsTest
  static void resolveLookupTargetObject_NonFilterableMatchField_ThrowsDomainException() {
    Schema.DescribeFieldResult parentIdDescribe = Account.ParentId.getDescribe();
    Bulk_Record_Upload_Process_Field__mdt recordValue = baseRecord();
    recordValue.LookupMatchField__c = 'NotARealField__c';

    try {
      BulkRecordUploadLookupResolver.resolveLookupTargetObject(
        new BulkRecordUploadFieldConfig(recordValue),
        parentIdDescribe
      );
      Assert.fail('Expected a non-filterable match field exception.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(error.getMessage().contains('filterable'));
    }
  }

  @IsTest
  static void resolveLookupTargetObject_ValidSingleTargetLookup_ReturnsTargetObject() {
    Schema.DescribeFieldResult parentIdDescribe = Account.ParentId.getDescribe();
    Bulk_Record_Upload_Process_Field__mdt recordValue = baseRecord();
    recordValue.LookupMatchField__c = 'Name';

    String targetObject = BulkRecordUploadLookupResolver.resolveLookupTargetObject(
      new BulkRecordUploadFieldConfig(recordValue),
      parentIdDescribe
    );

    Assert.areEqual('Account', targetObject);
  }

  private static Bulk_Record_Upload_Process_Field__mdt baseRecord() {
    return new Bulk_Record_Upload_Process_Field__mdt(
      CsvColumnHeader__c = 'parent',
      DisplayLabel__c = 'Parent',
      FieldApiName__c = 'ParentId',
      ExistingValueAction__c = 'REPLACE',
      BlankValueAction__c = 'IGNORE',
      TextSeparator__c = 'SPACE',
      DuplicateTextAction__c = 'SKIP',
      OverflowAction__c = 'REJECT',
      ColumnOrder__c = 1
    );
  }
}
