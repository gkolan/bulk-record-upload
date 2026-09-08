@IsTest
private with sharing class BulkRecordUploadResultTest {
  @IsTest
  static void writer_SuccessAndFailure_UsesStableSafeSchema() {
    List<BulkRecordUploadRowResult> results = new List<BulkRecordUploadRowResult>{
      new BulkRecordUploadRowResult(2, true, null, null, null),
      new BulkRecordUploadRowResult(3, false, null, 'INVALID_VALUE', '=formula')
    };
    String csv = new BulkRecordUploadResultWriter().write(results).toString();
    Assert.isTrue(csv.startsWith(BulkRecordUploadResultWriter.HEADER + '\r\n'));
    Assert.isTrue(csv.contains('formula'));
    Assert.isFalse(csv.contains('"=formula"'));
    Assert.isFalse(csv.contains('source value'));
  }

  @IsTest
  static void writer_NegativeNumber_DoesNotChangeRoundTripValue() {
    List<BulkRecordUploadRowResult> results = new List<BulkRecordUploadRowResult>{
      new BulkRecordUploadRowResult(2, false, null, 'INVALID_VALUE', '-5')
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
  static void writer_AllSpreadsheetFormulaPrefixes_AreGuarded() {
    List<String> dangerousValues = new List<String>{
      '=cmd',
      '+cmd',
      '-cmd',
      '@cmd',
      '\tcmd',
      '\rcmd',
      '\ncmd'
    };
    List<BulkRecordUploadRowResult> results = new List<BulkRecordUploadRowResult>();
    List<BulkRecordUploadRow> sourceRows = new List<BulkRecordUploadRow>();
    Integer rowNumber = 2;
    for (String dangerousValue : dangerousValues) {
      results.add(
        new BulkRecordUploadRowResult(rowNumber++, true, null, null, null)
      );
      sourceRows.add(
        new BulkRecordUploadRow(
          rowNumber - 1,
          new Map<String, String>{ 'name' => dangerousValue }
        )
      );
    }

    Test.startTest();
    String csv = new BulkRecordUploadResultWriter()
      .write(results, resultProjection(), sourceRows)
      .toString();
    Test.stopTest();

    for (String dangerousValue : dangerousValues) {
      Assert.isTrue(
        csv.contains('"\'' + dangerousValue + '"'),
        'Formula-shaped prefix ' +
          EncodingUtil.convertToHex(Blob.valueOf(dangerousValue.left(1))) +
          ' must receive an apostrophe guard.'
      );
    }
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

  private static BulkRecordUploadProjection resultProjection() {
    BulkRecordUploadFieldProjection field = new BulkRecordUploadFieldProjection(
      'name',
      'Name',
      'Name',
      'STRING',
      'REPLACE',
      1,
      true,
      false,
      false,
      true,
      true,
      true
    );
    return new BulkRecordUploadProjection(
      'RESULT_FORMULA',
      'hash',
      'Account',
      'INSERT',
      new List<String>(),
      100,
      30,
      new List<BulkRecordUploadFieldProjection>{ field }
    );
  }
}
