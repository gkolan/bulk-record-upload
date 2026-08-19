/** Verifies maximum-input staging and bounded projection-cache behavior. */
@IsTest
private with sharing class BulkRecordUploadScaleTest {
  @IsTest
  static void staging_MaximumRows_UsesBoundedOrderedChunks() {
    Bulk_Record_Upload__c upload = BulkRecordUploadTestDataFactory.createUpload(
      'MAXIMUM_ROWS'
    );
    List<BulkRecordUploadRowV1> rows = BulkRecordUploadTestDataFactory.createRows(
      BulkRecordUploadRuntimeContract.MAX_CSV_ROWS
    );

    Test.startTest();
    List<Bulk_Record_Upload_Chunk__c> chunks = new BulkRecordUploadStagingService()
      .stage(upload.Id, rows, 200);
    Integer dmlStatements = Limits.getDmlStatements();
    Integer dmlRows = Limits.getDmlRows();
    Integer queries = Limits.getQueries();
    Test.stopTest();

    Assert.areEqual(25, chunks.size(), 'Maximum input should use 25 chunks.');
    Assert.areEqual(2, chunks[0].FirstCsvRow__c, 'First row must correlate.');
    Assert.areEqual(
      4802,
      chunks[24].FirstCsvRow__c,
      'Final chunk must preserve source order.'
    );
    Assert.areEqual(1, dmlStatements, 'Staging should use one DML statement.');
    Assert.areEqual(
      25,
      dmlRows,
      'Only package-owned chunks should be inserted.'
    );
    Assert.areEqual(0, queries, 'Staging should not query subscriber data.');
  }

  @IsTest
  static void projection_MaximumFields_IsCompactAndDefensive() {
    BulkRecordUploadProjectionV1 projection = projection(100, 'maximum');

    Test.startTest();
    Integer serializedBytes = Blob.valueOf(JSON.serialize(projection)).size();
    List<BulkRecordUploadFieldProjectionV1> fields = projection.getFields();
    fields.clear();
    Test.stopTest();

    Assert.isTrue(
      serializedBytes < BulkRecordUploadRuntimeContract.MAX_CHUNK_CHARACTERS,
      'Projection must stay below 128 KiB.'
    );
    Assert.areEqual(
      100,
      projection.getFields().size(),
      'Copy mutation must not leak.'
    );
  }

  @IsTest
  static void cache_EvictionVersionAndFingerprint_IsolateResults() {
    BulkRecordUploadProjectionCache.clear();
    BulkRecordUploadProjectionCache cacheValue = new BulkRecordUploadProjectionCache();
    BulkRecordUploadProjectionV1 expected = projection(5, 'expected');

    Test.startTest();
    cacheValue.put('bru:projection:1:0.1:process:v1:fingerprint-a', expected);
    for (Integer index = 0; index < 50; index++) {
      cacheValue.put('bru:filler:' + index, projection(1, 'filler' + index));
    }
    BulkRecordUploadProjectionV1 evicted = cacheValue.find(
      'bru:projection:1:0.1:process:v1:fingerprint-a'
    );
    BulkRecordUploadProjectionV1 wrongVersion = cacheValue.find(
      'bru:projection:2:0.1:process:v1:fingerprint-a'
    );
    BulkRecordUploadProjectionV1 wrongFingerprint = cacheValue.find(
      'bru:projection:1:0.1:process:v1:fingerprint-b'
    );
    Test.stopTest();

    Assert.isNull(evicted, 'Oldest entry should be evicted at the bound.');
    Assert.isNull(wrongVersion, 'Contract versions must not share entries.');
    Assert.isNull(
      wrongFingerprint,
      'Permission fingerprints must not share entries.'
    );
  }

  @IsTest
  static void cache_WarmAndCold_ReturnEquivalentProjection() {
    BulkRecordUploadProjectionCache.clear();
    BulkRecordUploadProjectionCache cacheValue = new BulkRecordUploadProjectionCache();
    BulkRecordUploadProjectionV1 cold = projection(50, 'equivalent');

    Test.startTest();
    cacheValue.put('bru:equivalent', cold);
    BulkRecordUploadProjectionV1 warm = cacheValue.find('bru:equivalent');
    Test.stopTest();

    Assert.areEqual(
      JSON.serialize(cold),
      JSON.serialize(warm),
      'Cache hit must preserve the complete projection contract.'
    );
  }

  @IsTest
  static void projection_TwoHundredFields_IsRejected() {
    Test.startTest();
    try {
      projection(200, 'too-many');
      Assert.fail('Expected the configured-field maximum to be enforced.');
    } catch (BulkRecordUploadException error) {
      Assert.areEqual(
        'Projection must contain between 1 and 100 fields.',
        error.getMessage(),
        'Oversized projection should fail at the immutable boundary.'
      );
    }
    Test.stopTest();
  }

  private static BulkRecordUploadProjectionV1 projection(
    Integer count,
    String key
  ) {
    List<BulkRecordUploadFieldProjectionV1> fields = new List<BulkRecordUploadFieldProjectionV1>();
    for (Integer index = 0; index < count; index++) {
      fields.add(
        new BulkRecordUploadFieldProjectionV1(
          'column_' + index,
          'Column ' + index,
          'Field_' + index + '__c',
          'STRING',
          'REPLACE',
          index + 1,
          false,
          false,
          false,
          true,
          true,
          true
        )
      );
    }
    return new BulkRecordUploadProjectionV1(
      key,
      'hash-' + key,
      'Synthetic__c',
      'INSERT',
      new List<String>(),
      200,
      30,
      fields
    );
  }
}
