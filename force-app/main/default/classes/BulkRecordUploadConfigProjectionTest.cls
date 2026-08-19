/**
 * Verifies active configuration loading, access decisions, compact projection, and cache recovery.
 */
@IsTest
private class BulkRecordUploadConfigProjectionTest {
  @IsTest
  static void repository_ActiveProcess_ReturnsOrderedFields() {
    BulkRecordUploadConfigRepository repository = createRepository(
      'STANDARD_V1',
      new List<Bulk_Record_Upload_Process_Field__mdt>{
        createField('last_name', 'LastName', 2),
        createField('email', 'Email', 1)
      }
    );

    Test.startTest();
    BulkRecordUploadConfigRepository.Configuration result = repository.findActive(
      'CONTACT_INSERT'
    );
    Test.stopTest();

    Assert.areEqual(
      2,
      result.getFields().size(),
      'Repository should return both active fields.'
    );
    Assert.areEqual(
      'email',
      result.getFields()[0].columnKey,
      'Fields should be sorted by sequence.'
    );
    Assert.areEqual(
      'last_name',
      result.getFields()[1].columnKey,
      'Second sequence should follow first.'
    );
  }

  @IsTest
  static void repository_MissingProcess_ThrowsSafeException() {
    BulkRecordUploadConfigRepository repository = createRepository(
      'STANDARD_V1',
      new List<Bulk_Record_Upload_Process_Field__mdt>()
    );

    Test.startTest();
    try {
      repository.findActive('UNKNOWN');
      Assert.fail('Expected an unknown process to fail.');
    } catch (BulkRecordUploadException exceptionValue) {
      Assert.areEqual(
        'The requested upload process is unavailable.',
        exceptionValue.getMessage(),
        'Failure should not reveal subscriber configuration.'
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void projection_ValidContactConfig_ReturnsOnlyConfiguredFields() {
    User operatorUser = BulkRecordUploadTestDataFactory.createUser(
      'projection'
    );
    BulkRecordUploadTestDataFactory.assignPermissionSets(
      operatorUser.Id,
      new Set<String>{ 'Bulk_Record_Upload_User' }
    );
    BulkRecordUploadProjectionService service = createService(
      'STANDARD_V1',
      new List<Bulk_Record_Upload_Process_Field__mdt>{
        createField('last_name', 'LastName', 1),
        createField('email', 'Email', 2)
      }
    );

    System.runAs(operatorUser) {
      Test.startTest();
      BulkRecordUploadProjectionV1 projection = service.getProjection(
        'CONTACT_INSERT'
      );
      Test.stopTest();

      Assert.areEqual(
        'Contact',
        projection.objectApiName,
        'Projection should resolve the exact object API name.'
      );
      Assert.areEqual(
        2,
        projection.getFields().size(),
        'Projection should contain only configured fields.'
      );
      Assert.areEqual(
        'LastName',
        projection.getFields()[0].fieldApiName,
        'Projection should preserve configured order.'
      );
    }
  }

  @IsTest
  static void projection_UnregisteredHandler_ThrowsSafeException() {
    User operatorUser = BulkRecordUploadTestDataFactory.createUser('handler');
    BulkRecordUploadTestDataFactory.assignPermissionSets(
      operatorUser.Id,
      new Set<String>{ 'Bulk_Record_Upload_User' }
    );
    BulkRecordUploadProjectionService service = createService(
      'ARBITRARY_CLASS',
      new List<Bulk_Record_Upload_Process_Field__mdt>{
        createField('last_name', 'LastName', 1)
      }
    );

    System.runAs(operatorUser) {
      Test.startTest();
      try {
        service.getProjection('CONTACT_INSERT');
        Assert.fail('Expected an unregistered handler to fail.');
      } catch (BulkRecordUploadException exceptionValue) {
        Assert.areEqual(
          'Configured handler is not registered.',
          exceptionValue.getMessage(),
          'Failure should enforce the trusted registry boundary.'
        );
      }
      Test.stopTest();
    }
  }

  @IsTest
  static void projection_UnknownField_ThrowsSafeException() {
    User operatorUser = BulkRecordUploadTestDataFactory.createUser('field');
    BulkRecordUploadTestDataFactory.assignPermissionSets(
      operatorUser.Id,
      new Set<String>{ 'Bulk_Record_Upload_User' }
    );
    BulkRecordUploadProjectionService service = createService(
      'STANDARD_V1',
      new List<Bulk_Record_Upload_Process_Field__mdt>{
        createField('unknown', 'NotAField__c', 1)
      }
    );

    System.runAs(operatorUser) {
      Test.startTest();
      try {
        service.getProjection('CONTACT_INSERT');
        Assert.fail('Expected an unknown field to fail.');
      } catch (BulkRecordUploadException exceptionValue) {
        Assert.areEqual(
          'A configured target field is unavailable.',
          exceptionValue.getMessage(),
          'Failure should not echo untrusted field text.'
        );
      }
      Test.stopTest();
    }
  }

  @IsTest
  static void cache_CorruptEntry_RemovesAndReturnsMiss() {
    BulkRecordUploadProjectionCache.clear();
    BulkRecordUploadProjectionCache.putCorrupt('bru:test');
    BulkRecordUploadProjectionCache cacheValue = new BulkRecordUploadProjectionCache();

    Test.startTest();
    BulkRecordUploadProjectionV1 projection = cacheValue.find('bru:test');
    Test.stopTest();

    Assert.isNull(projection, 'Corrupt cache values should behave as misses.');
    Assert.isNull(
      cacheValue.find('bru:test'),
      'Corrupt value should be removed after recovery.'
    );
  }

  @IsTest
  static void accessPolicy_UnknownPreviewPermission_RejectsAdminText() {
    BulkRecordUploadAccessPolicy policy = new BulkRecordUploadAccessPolicy();

    Test.startTest();
    try {
      policy.requirePreviewPermission('Subscriber_Arbitrary_Permission');
      Assert.fail('Expected an unowned Custom Permission name to fail.');
    } catch (BulkRecordUploadException exceptionValue) {
      Assert.areEqual(
        'Preview permission configuration is not supported.',
        exceptionValue.getMessage(),
        'Only project-owned preview capability should be allowed.'
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void accessPolicy_MissingTargetDescribe_RejectsInvalidBoundary() {
    BulkRecordUploadAccessPolicy policy = new BulkRecordUploadAccessPolicy();

    Test.startTest();
    try {
      policy.requireOperationAccess(null, 'INSERT');
      Assert.fail('Expected a missing target describe to fail.');
    } catch (BulkRecordUploadException exceptionValue) {
      Assert.areEqual(
        'Target access configuration is invalid.',
        exceptionValue.getMessage(),
        'Invalid access boundary should fail before dereferencing Schema.'
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void accessPolicy_UserWithoutPermission_CannotRun() {
    User unprivilegedUser = BulkRecordUploadTestDataFactory.createUser(
      'denied'
    );
    BulkRecordUploadAccessPolicy policy = new BulkRecordUploadAccessPolicy();

    System.runAs(unprivilegedUser) {
      Test.startTest();
      try {
        policy.requireRunPermission();
        Assert.fail('Expected an unprivileged user to be denied.');
      } catch (BulkRecordUploadException exceptionValue) {
        Assert.areEqual(
          'You are not authorized to run uploads.',
          exceptionValue.getMessage(),
          'Denial should be safe and actionable.'
        );
      }
      Test.stopTest();
    }
  }

  @IsTest
  static void accessPolicy_BaseOperator_CanInsertButCannotDelete() {
    User operatorUser = BulkRecordUploadTestDataFactory.createUser('operator');
    BulkRecordUploadTestDataFactory.assignPermissionSets(
      operatorUser.Id,
      new Set<String>{ 'Bulk_Record_Upload_User' }
    );
    BulkRecordUploadAccessPolicy policy = new BulkRecordUploadAccessPolicy();

    System.runAs(operatorUser) {
      Test.startTest();
      policy.requireRunPermission();
      policy.requireOperationAccess(
        Contact.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED),
        'INSERT'
      );
      policy.requirePreviewPermission(null);
      try {
        policy.requireOperationAccess(
          Contact.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED),
          'DELETE'
        );
        Assert.fail('Expected delete to require its separate capability.');
      } catch (BulkRecordUploadException exceptionValue) {
        Assert.areEqual(
          'You are not authorized to run delete processes.',
          exceptionValue.getMessage(),
          'Delete denial should name the missing capability without target data.'
        );
      }
      Test.stopTest();
    }
  }

  @IsTest
  static void processConfig_UnsupportedOperation_ThrowsSafeException() {
    Bulk_Record_Upload_Process__mdt process = new Bulk_Record_Upload_Process__mdt(
      DeveloperName = 'INVALID_PROCESS',
      ObjectApiName__c = 'Contact',
      Operation__c = 'MERGE',
      ProcessingHandler__c = 'STANDARD_V1',
      RowsPerBatch__c = 100,
      RetentionDays__c = 90,
      IsActive__c = true,
      ConfigurationVersion__c = 1
    );

    Test.startTest();
    try {
      new BulkRecordUploadProcessConfigV1(process);
      Assert.fail('Expected an unsupported operation to fail.');
    } catch (BulkRecordUploadException exceptionValue) {
      Assert.areEqual(
        'Process operation is not supported.',
        exceptionValue.getMessage(),
        'Configuration error should not echo arbitrary operation text.'
      );
    }
    Test.stopTest();
  }

  private static BulkRecordUploadProjectionService createService(
    String handlerKey,
    List<Bulk_Record_Upload_Process_Field__mdt> fields
  ) {
    return new BulkRecordUploadProjectionService(
      createRepository(handlerKey, fields),
      new BulkRecordUploadAccessPolicy(),
      new BulkRecordUploadProjectionCache()
    );
  }

  private static BulkRecordUploadConfigRepository createRepository(
    String handlerKey,
    List<Bulk_Record_Upload_Process_Field__mdt> fields
  ) {
    Bulk_Record_Upload_Process__mdt process = new Bulk_Record_Upload_Process__mdt(
      DeveloperName = 'CONTACT_INSERT',
      ObjectApiName__c = 'Contact',
      Operation__c = 'INSERT',
      ProcessingHandler__c = handlerKey,
      RowsPerBatch__c = 100,
      RetentionDays__c = 90,
      IsActive__c = true,
      ConfigurationVersion__c = 1
    );
    return new BulkRecordUploadConfigRepository(
      new Map<String, Bulk_Record_Upload_Process__mdt>{
        process.DeveloperName => process
      },
      fields
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
      ValueHandling__c = 'REPLACE',
      IsRequired__c = fieldApiName == 'LastName',
      IncludeInResult__c = true,
      IsActive__c = true
    );
  }
}
