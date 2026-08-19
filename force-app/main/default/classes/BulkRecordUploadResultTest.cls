@IsTest
private with sharing class BulkRecordUploadResultTest {
  @IsTest
  static void writer_SuccessAndFailure_UsesVersionedSafeSchema() {
    List<BulkRecordUploadRowResultV1> results = new List<BulkRecordUploadRowResultV1>{
      new BulkRecordUploadRowResultV1(2, true, null, null, null),
      new BulkRecordUploadRowResultV1(
        3,
        false,
        null,
        'INVALID_VALUE',
        '=formula'
      )
    };
    String csv = new BulkRecordUploadResultWriter().write(results).toString();
    Assert.isTrue(csv.startsWith(BulkRecordUploadResultWriter.HEADER + '\r\n'));
    Assert.isTrue(csv.contains('formula'));
    Assert.isFalse(csv.contains('"=formula"'));
    Assert.isFalse(csv.contains('source value'));
  }

  @IsTest
  static void writer_NegativeNumber_DoesNotChangeRoundTripValue() {
    List<BulkRecordUploadRowResultV1> results = new List<BulkRecordUploadRowResultV1>{
      new BulkRecordUploadRowResultV1(2, false, null, 'INVALID_VALUE', '-5')
    };

    Test.startTest();
    String csv = new BulkRecordUploadResultWriter().write(results).toString();
    Test.stopTest();

    Assert.isTrue(
      csv.contains('"-5"'),
      'A negative numeric value should not receive a formula prefix.'
    );
    Assert.isFalse(
      csv.contains('"\'-5"'),
      'The result should preserve negative numeric text.'
    );
  }

  @IsTest
  static void fileService_CreatesLinkedResultAndUpdatesUpload() {
    Bulk_Record_Upload__c upload = BulkRecordUploadTestDataFactory.createUpload(
      'RESULT_FILE'
    );
    Test.startTest();
    Id documentId = new BulkRecordUploadFileService()
      .createResultFile(upload.Id, Blob.valueOf('safe'));
    Test.stopTest();
    Bulk_Record_Upload__c stored = [
      SELECT ResultFileId__c
      FROM Bulk_Record_Upload__c
      WHERE Id = :upload.Id
    ];
    Assert.areEqual(String.valueOf(documentId), stored.ResultFileId__c);
    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :upload.Id
      ]
    );
  }
}
