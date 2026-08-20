/**
 * Verifies record-context picker settings participate in the projection
 * config hash, so a configuration-only change busts the cache.
 */
@IsTest
private class BulkRecordUploadContextHashTest {
  @IsTest
  static void projection_ContextSettingChange_ChangesConfigHashAndBustsCache() {
    User operatorUser = BulkRecordUploadTestDataFactory.createUser('ctxhash');
    BulkRecordUploadTestDataFactory.assignPermissionSets(
      operatorUser.Id,
      new Set<String>{ 'Bulk_Record_Upload_User' }
    );
    List<Bulk_Record_Upload_Process_Field__mdt> fields = new List<Bulk_Record_Upload_Process_Field__mdt>{
      createField('last_name', 'LastName', 1)
    };
    BulkRecordUploadProjectionService originalService = createContextService(
      fields,
      'Name'
    );
    BulkRecordUploadProjectionService changedService = createContextService(
      fields,
      'Name,AccountNumber'
    );

    System.runAs(operatorUser) {
      Test.startTest();
      BulkRecordUploadProjection original = originalService.getProjection(
        'CONTACT_INSERT'
      );
      BulkRecordUploadProjection changed = changedService.getProjection(
        'CONTACT_INSERT'
      );
      Test.stopTest();

      Assert.areNotEqual(
        original.configHash,
        changed.configHash,
        'Changing a context search field must change the config hash so the cache is not reused.'
      );
      Assert.areEqual(
        new List<String>(),
        original.contextProjection.additionalSearchFields
      );
      Assert.areEqual(
        new List<String>{ 'AccountNumber' },
        changed.contextProjection.additionalSearchFields
      );
    }
  }

  private static BulkRecordUploadProjectionService createContextService(
    List<Bulk_Record_Upload_Process_Field__mdt> fields,
    String contextSearchFields
  ) {
    Bulk_Record_Upload_Process__mdt process = new Bulk_Record_Upload_Process__mdt(
      DeveloperName = 'CONTACT_INSERT',
      ObjectApiName__c = 'Contact',
      Operation__c = 'INSERT',
      RowsPerBatch__c = 100,
      RetentionDays__c = 90,
      IsActive__c = true,
      ConfigurationVersion__c = 1,
      RecordContextAction__c = 'DEFAULT_PARENT',
      HostObjectApiName__c = 'Account',
      RecordContextFieldApiName__c = 'AccountId',
      RecordContextSource__c = 'USER_CHOICE',
      ContextSearchFields__c = contextSearchFields
    );
    BulkRecordUploadConfigRepository repository = new BulkRecordUploadConfigRepository(
      new Map<String, Bulk_Record_Upload_Process__mdt>{
        process.DeveloperName => process
      },
      fields,
      new List<Bulk_Record_Upload_Extension__mdt>()
    );
    return new BulkRecordUploadProjectionService(
      repository,
      new BulkRecordUploadAccessPolicy(),
      new BulkRecordUploadProjectionCache()
    );
  }

  private static Bulk_Record_Upload_Process_Field__mdt createField(
    String columnKey,
    String fieldApiName,
    Integer sequence
  ) {
    return new Bulk_Record_Upload_Process_Field__mdt(
      DeveloperName = 'FIELD_' + sequence,
      ProcessDeveloperName__c = 'CONTACT_INSERT',
      FieldApiName__c = fieldApiName,
      CsvColumnHeader__c = columnKey,
      DisplayLabel__c = columnKey,
      ColumnOrder__c = sequence,
      ExistingValueAction__c = 'REPLACE',
      IsRequired__c = fieldApiName == 'LastName',
      IncludeInResult__c = true,
      IsActive__c = true
    );
  }
}
