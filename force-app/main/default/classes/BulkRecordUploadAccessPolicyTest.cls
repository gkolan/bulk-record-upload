@IsTest
private class BulkRecordUploadAccessPolicyTest {
  @IsTest
  static void unknownPreviewPermission_RejectsAdminText() {
    BulkRecordUploadAccessPolicy policy = new BulkRecordUploadAccessPolicy();

    Test.startTest();
    try {
      policy.requirePreviewPermission('Subscriber_Arbitrary_Permission');
      Assert.fail('Expected an unowned Custom Permission name to fail.');
    } catch (BulkRecordUploadException exceptionValue) {
      Assert.areEqual(
        'Preview permission configuration is not supported.',
        exceptionValue.getMessage(),
        'Only the package preview permission should be allowed.'
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void missingTargetDescribe_RejectsInvalidBoundary() {
    BulkRecordUploadAccessPolicy policy = new BulkRecordUploadAccessPolicy();

    Test.startTest();
    try {
      policy.requireOperationAccess(null, 'INSERT');
      Assert.fail('Expected a missing target description to fail.');
    } catch (BulkRecordUploadException exceptionValue) {
      Assert.areEqual(
        'Target access configuration is invalid.',
        exceptionValue.getMessage(),
        'Invalid access setup should fail safely.'
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void userWithoutPermission_CannotRun() {
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
          'The user should receive a safe, useful message.'
        );
      }
      Test.stopTest();
    }
  }

  @IsTest
  static void baseOperator_CanInsertButCannotDelete() {
    User operatorUser = BulkRecordUploadTestDataFactory.createUser('operator');
    BulkRecordUploadTestDataFactory.assignPermissionSets(
      operatorUser.Id,
      new Set<String>{
        'Bulk_Record_Upload_User',
        'Bulk_Record_Upload_Demo_Target_Access'
      }
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
        Assert.fail('Expected delete to require its separate permission.');
      } catch (BulkRecordUploadException exceptionValue) {
        Assert.areEqual(
          'You are not authorized to run delete processes.',
          exceptionValue.getMessage(),
          'Delete should require the separate delete permission.'
        );
      }
      Test.stopTest();
    }
  }

  @IsTest
  static void baseOperator_PassesUpdateAndUpsertAccessChecks() {
    User operatorUser = BulkRecordUploadTestDataFactory.createUser('upsert');
    BulkRecordUploadTestDataFactory.assignPermissionSets(
      operatorUser.Id,
      new Set<String>{
        'Bulk_Record_Upload_User',
        'Bulk_Record_Upload_Demo_Target_Access'
      }
    );
    BulkRecordUploadAccessPolicy policy = new BulkRecordUploadAccessPolicy();
    System.runAs(operatorUser) {
      Schema.DescribeSObjectResult contactDescribe = Contact.SObjectType.getDescribe(
        SObjectDescribeOptions.DEFERRED
      );
      Test.startTest();
      policy.requireOperationAccess(contactDescribe, 'UPDATE');
      policy.requireOperationAccess(contactDescribe, 'UPSERT');
      policy.requireOperationAccess(contactDescribe, 'insert');
      Test.stopTest();
    }

  }

  @IsTest
  static void deleteOperator_PassesWithSeparateDeletePermission() {
    User deleteUser = BulkRecordUploadTestDataFactory.createUser('remover');
    BulkRecordUploadTestDataFactory.assignPermissionSets(
      deleteUser.Id,
      new Set<String>{
        'Bulk_Record_Upload_User',
        'Bulk_Record_Upload_Demo_Target_Access',
        'Bulk_Record_Upload_Delete_Access'
      }
    );
    BulkRecordUploadAccessPolicy policy = new BulkRecordUploadAccessPolicy();

    System.runAs(deleteUser) {
      Test.startTest();
      policy.requireRunPermission();
      policy.requireOperationAccess(
        Contact.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED),
        'DELETE'
      );
      Test.stopTest();
    }

    Assert.isTrue(
      true,
      'A delete-authorized user should pass both access checks.'
    );
  }

  @IsTest
  static void previewOperator_PassesWithPreviewPermission() {
    User previewUser = BulkRecordUploadTestDataFactory.createUser('preview');
    BulkRecordUploadTestDataFactory.assignPermissionSets(
      previewUser.Id,
      new Set<String>{
        'Bulk_Record_Upload_User',
        'Bulk_Record_Upload_Preview_Access'
      }
    );
    BulkRecordUploadAccessPolicy policy = new BulkRecordUploadAccessPolicy();

    System.runAs(previewUser) {
      Test.startTest();
      policy.requirePreviewPermission('Bulk_Record_Upload_Preview');
      Test.stopTest();
    }

    Assert.isTrue(
      true,
      'A preview-authorized user should pass the preview check.'
    );
  }

  @IsTest
  static void operatorWithoutPreviewPermission_IsDenied() {
    User operatorUser = BulkRecordUploadTestDataFactory.createUser('nopreview');
    BulkRecordUploadTestDataFactory.assignPermissionSets(
      operatorUser.Id,
      new Set<String>{ 'Bulk_Record_Upload_User' }
    );
    BulkRecordUploadAccessPolicy policy = new BulkRecordUploadAccessPolicy();

    System.runAs(operatorUser) {
      Test.startTest();
      try {
        policy.requirePreviewPermission('Bulk_Record_Upload_Preview');
        Assert.fail('Expected preview to require its own permission.');
      } catch (BulkRecordUploadException exceptionValue) {
        Assert.areEqual(
          'You are not authorized to preview this process.',
          exceptionValue.getMessage(),
          'Preview denial should stay safe and specific.'
        );
      }
      Test.stopTest();
    }
  }

  @IsTest
  static void blankOperation_RejectsInvalidBoundary() {
    BulkRecordUploadAccessPolicy policy = new BulkRecordUploadAccessPolicy();

    Test.startTest();
    try {
      policy.requireOperationAccess(
        Contact.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED),
        '  '
      );
      Assert.fail('Expected a blank operation to fail.');
    } catch (BulkRecordUploadException exceptionValue) {
      Assert.areEqual(
        'Target access configuration is invalid.',
        exceptionValue.getMessage(),
        'A blank operation should fail safely.'
      );
    }
    Test.stopTest();
  }
}
