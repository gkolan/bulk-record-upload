/** Proves private upload and File visibility with separate least-privilege users. */
@IsTest
private with sharing class BulkRecordUploadPrivacyTest {
  @IsTest
  static void historyStatusAndFile_SecondUserCannotDiscoverOwnersUpload() {
    User owner = BulkRecordUploadTestDataFactory.createUser('owner');
    User secondUser = BulkRecordUploadTestDataFactory.createUser('second');
    BulkRecordUploadTestDataFactory.assignPermissionSets(
      owner.Id,
      new Set<String>{ 'Bulk_Record_Upload_User' }
    );
    BulkRecordUploadTestDataFactory.assignPermissionSets(
      secondUser.Id,
      new Set<String>{ 'Bulk_Record_Upload_User' }
    );
    Bulk_Record_Upload__c upload;
    Id resultDocumentId;

    System.runAs(owner) {
      upload = new BulkRecordUploadLogService()
        .createOrFind('PRIVATE_PROCESS', digest('owner-request'), 1, 30);
      resultDocumentId = new BulkRecordUploadFileService()
        .createResultFile(upload.Id, Blob.valueOf('safe result'));
      Assert.areEqual(
        1,
        new BulkRecordUploadLogService().getHistory().size(),
        'The owner should see the upload.'
      );
      Assert.areEqual(
        upload.Id,
        new BulkRecordUploadLogService().getStatus(upload.Id).uploadId,
        'The owner should see current status.'
      );
      Assert.areEqual(
        1,
        [
          SELECT COUNT()
          FROM ContentDocument
          WHERE Id = :resultDocumentId
          WITH USER_MODE
        ],
        'The owner should see the linked result File.'
      );
    }

    System.runAs(secondUser) {
      Test.startTest();
      Assert.areEqual(
        0,
        new BulkRecordUploadLogService().getHistory().size(),
        'A second user must not discover private upload history.'
      );
      try {
        new BulkRecordUploadLogService().getStatus(upload.Id);
        Assert.fail('A second user must not read another owner status.');
      } catch (BulkRecordUploadException error) {
        Assert.areEqual('The upload is unavailable.', error.getMessage());
      }
      Assert.areEqual(
        0,
        [
          SELECT COUNT()
          FROM ContentDocument
          WHERE Id = :resultDocumentId
          WITH USER_MODE
        ],
        'A second user must not discover the private linked File.'
      );
      Test.stopTest();
    }
  }

  private static String digest(String value) {
    return EncodingUtil.convertToHex(
      Crypto.generateDigest('SHA-256', Blob.valueOf(value))
    );
  }
}
