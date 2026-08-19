@IsTest
private class BulkRecordUploadStagingTest {
  @IsTest
  static void stage_MoreThanOneChunk_PreservesOrderChecksumAndBounds() {
    Bulk_Record_Upload__c upload = BulkRecordUploadTestDataFactory.createUpload(
      'STAGING'
    );
    List<BulkRecordUploadRowV1> rows = new List<BulkRecordUploadRowV1>();
    for (Integer index = 0; index < 51; index++) {
      rows.add(
        new BulkRecordUploadRowV1(
          index + 2,
          new Map<String, String>{ 'name' => 'Row ' + index }
        )
      );
    }

    Test.startTest();
    List<Bulk_Record_Upload_Chunk__c> chunks = new BulkRecordUploadStagingService()
      .stage(upload.Id, rows, 25);
    Integer dmlStatements = Limits.getDmlStatements();
    Test.stopTest();

    Assert.areEqual(3, chunks.size());
    Assert.areEqual(2, chunks[0].FirstCsvRow__c);
    Assert.areEqual(52, chunks[2].FirstCsvRow__c);
    Assert.areEqual(1, dmlStatements);
    for (Bulk_Record_Upload_Chunk__c chunk : chunks) {
      Assert.isTrue(
        Blob.valueOf(chunk.StagedRowData__c).size() <=
        BulkRecordUploadStagingService.MAX_CHUNK_BYTES
      );
      Assert.areEqual(64, chunk.IntegrityChecksum__c.length());
      Assert.areEqual('READY', chunk.Status__c);
    }
  }

  @IsTest
  static void stage_MissingInput_IsRejectedWithoutDml() {
    try {
      new BulkRecordUploadStagingService()
        .stage(null, new List<BulkRecordUploadRowV1>(), 100);
      Assert.fail('Expected staging input exception.');
    } catch (BulkRecordUploadException error) {
      Assert.areEqual('Staging input is required.', error.getMessage());
      Assert.areEqual(0, Limits.getDmlStatements());
    }
  }
}
