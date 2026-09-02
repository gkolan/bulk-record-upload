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
}
