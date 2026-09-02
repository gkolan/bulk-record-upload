@IsTest
private with sharing class BulkRecordUploadRetentionTest {
  @IsTest
  static void cleanup_ExpiredUpload_PreservesFilesWithOtherLinks() {
    Bulk_Record_Upload__c upload = BulkRecordUploadTestDataFactory.createExpiredUpload(
      'RETENTION'
    );
    BulkRecordUploadFileService files = new BulkRecordUploadFileService();
    Id inputId = files.createInputFile(
      upload.Id,
      Blob.valueOf('input'),
      'input.csv'
    );
    Id resultId = files.createResultFile(upload.Id, Blob.valueOf('result'));

    Test.startTest();
    Integer removed = new BulkRecordUploadRetentionJob().cleanup();
    Test.stopTest();

    Assert.areEqual(1, removed);
    Assert.areEqual(
      0,
      [SELECT COUNT() FROM Bulk_Record_Upload__c WHERE Id = :upload.Id]
    );
    Set<Id> documentIds = new Set<Id>{ inputId, resultId };
    Assert.areEqual(
      2,
      [SELECT COUNT() FROM ContentDocument WHERE Id IN :documentIds]
    );
    Assert.areEqual(
      0,
      [
        SELECT COUNT()
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :upload.Id
      ]
    );
  }

  @IsTest
  static void execute_NoExpiredUploads_CompletesBoundedScan() {
    Test.startTest();
    new BulkRecordUploadRetentionJob().execute((SchedulableContext) null);
    Test.stopTest();
    Assert.isTrue(Limits.getQueries() <= 3);
  }
}
