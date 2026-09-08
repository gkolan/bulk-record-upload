/** Adversarial authorization, identifier, and recovery-boundary coverage. */
@IsTest
private with sharing class BulkRecordUploadSecurityRecoveryTest {
  @IsTest
  static void runPermission_RevokedAfterSelection_IsRejectedAtNextBoundary() {
    User operator = BulkRecordUploadTestDataFactory.createUser('revoked');
    BulkRecordUploadTestDataFactory.assignPermissionSets(
      operator.Id,
      new Set<String>{ 'Bulk_Record_Upload_User' }
    );

    System.runAs(operator) {
      new BulkRecordUploadAccessPolicy().requireRunPermission();
    }

    BulkRecordUploadTestDataFactory.revokePermissionSet(
      operator.Id,
      'Bulk_Record_Upload_User'
    );

    System.runAs(operator) {
      Test.startTest();
      try {
        new BulkRecordUploadAccessPolicy().requireRunPermission();
        Assert.fail('A revoked capability must fail at the next boundary.');
      } catch (BulkRecordUploadException error) {
        Assert.areEqual(
          'You are not authorized to run uploads.',
          error.getMessage(),
          'Revocation should return the stable authorization message.'
        );
      }
      try {
        new BulkRecordUploadLogService().getHistory();
        Assert.fail('Revocation must also stop later status access.');
      } catch (BulkRecordUploadException error) {
        Assert.areEqual(
          'You are not authorized to run uploads.',
          error.getMessage(),
          'The status boundary should recheck the revoked capability.'
        );
      }
      Test.stopTest();
    }
  }

  @IsTest
  static void projection_IdentifierInjection_IsRejectedBeforeDynamicAccess() {
    User operator = BulkRecordUploadTestDataFactory.createUser('inject');
    BulkRecordUploadTestDataFactory.assignPermissionSets(
      operator.Id,
      new Set<String>{ 'Bulk_Record_Upload_User' }
    );
    Bulk_Record_Upload_Process__mdt processRecord = new Bulk_Record_Upload_Process__mdt(
      DeveloperName = 'INJECTION',
      MasterLabel = 'Injection',
      IsActive__c = true,
      ObjectApiName__c = 'Account WHERE Name != null',
      Operation__c = 'INSERT',
      RowsPerBatch__c = 100,
      RetentionDays__c = 30
    );
    BulkRecordUploadConfigRepository repository = new BulkRecordUploadConfigRepository(
      new Map<String, Bulk_Record_Upload_Process__mdt>{
        'INJECTION' => processRecord
      },
      new List<Bulk_Record_Upload_Process_Field__mdt>(),
      new List<Bulk_Record_Upload_Extension__mdt>()
    );

    System.runAs(operator) {
      Test.startTest();
      try {
        new BulkRecordUploadProjectionService(
            repository,
            new BulkRecordUploadAccessPolicy(),
            new BulkRecordUploadProjectionCache()
          )
          .getProjection('INJECTION');
        Assert.fail('An injected object identifier must be rejected.');
      } catch (BulkRecordUploadException error) {
        Assert.areEqual(
          'Configured target object is unavailable.',
          error.getMessage(),
          'Identifier rejection must not echo attacker-controlled text.'
        );
      }
      Test.stopTest();
    }
  }

  @IsTest
  static void recover_AbandonedUpload_IsBoundedAndIdempotent() {
    Bulk_Record_Upload__c upload = new BulkRecordUploadLogService()
      .createOrFindWithState(
        'RECOVERY_IDEMPOTENT',
        digest('recovery-request'),
        1,
        30,
        null,
        'recovery-hash'
      )
      .upload;
    BulkRecordUploadTestDataFactory.ageActiveUploadForRecovery(upload);

    Test.startTest();
    Integer firstPass = new BulkRecordUploadRecoveryService().recover();
    Integer secondPass = new BulkRecordUploadRecoveryService().recover();
    Test.stopTest();

    Bulk_Record_Upload__c stored = [
      SELECT Status__c, LastErrorCode__c, ActiveOrgSlot__c
      FROM Bulk_Record_Upload__c
      WHERE Id = :upload.Id
      WITH SYSTEM_MODE
    ];
    Assert.areEqual(1, firstPass, 'One stale upload should be recovered.');
    Assert.areEqual(
      0,
      secondPass,
      'A terminal upload must not be recovered twice.'
    );
    Assert.areEqual('FAILED', stored.Status__c);
    Assert.areEqual('ABANDONED_UPLOAD', stored.LastErrorCode__c);
    Assert.isNull(stored.ActiveOrgSlot__c, 'Recovery must release its claim.');
  }

  private static String digest(String value) {
    return EncodingUtil.convertToHex(
      Crypto.generateDigest('SHA-256', Blob.valueOf(value))
    );
  }
}
