@IsTest
private class BulkRecordUploadPersistenceTest {
  @IsTest
  static void persist_InsertPartialSuccess_PreservesRowCorrelationAndRedactsValues() {
    List<BulkRecordUploadMappedRowV1> rows = new List<BulkRecordUploadMappedRowV1>{
      new BulkRecordUploadMappedRowV1(
        9,
        new Account(Name = 'Successful Account')
      ),
      new BulkRecordUploadMappedRowV1(15, new Account())
    };

    Test.startTest();
    List<BulkRecordUploadRowResultV1> results = new BulkRecordUploadPersistenceGateway()
      .persist('INSERT', rows, null);
    Integer dmlStatements = Limits.getDmlStatements();
    Test.stopTest();

    Assert.areEqual(2, results.size());
    Assert.areEqual(9, results[0].rowNumber);
    Assert.isTrue(results[0].isSuccess);
    Assert.isNotNull(results[0].recordId);
    Assert.areEqual(15, results[1].rowNumber);
    Assert.isFalse(results[1].isSuccess);
    Assert.isNotNull(results[1].errorCode);
    Assert.isFalse(results[1].safeMessage.contains('Successful Account'));
    Assert.areEqual(1, dmlStatements);
  }

  @IsTest
  static void persist_OverChunkLimit_IsRejectedBeforeDml() {
    List<BulkRecordUploadMappedRowV1> rows = new List<BulkRecordUploadMappedRowV1>();
    for (Integer index = 0; index < 201; index++) {
      rows.add(
        new BulkRecordUploadMappedRowV1(
          index + 2,
          new Account(Name = 'Bounded')
        )
      );
    }
    try {
      new BulkRecordUploadPersistenceGateway().persist('INSERT', rows, null);
      Assert.fail('Expected bounded-persistence exception.');
    } catch (BulkRecordUploadException error) {
      Assert.areEqual(
        'Persistence requires between 1 and 200 rows.',
        error.getMessage()
      );
      Assert.areEqual(0, Limits.getDmlStatements());
    }
  }

  @IsTest
  static void persist_UpdateUpsertDelete_SupportsApprovedOperations() {
    BulkRecordUploadPersistenceGateway gateway = new BulkRecordUploadPersistenceGateway();
    List<BulkRecordUploadRowResultV1> inserted = gateway.persist(
      'INSERT',
      new List<BulkRecordUploadMappedRowV1>{
        new BulkRecordUploadMappedRowV1(2, new Account(Name = 'Lifecycle'))
      },
      null
    );
    Id accountId = inserted[0].recordId;

    List<BulkRecordUploadRowResultV1> updated = gateway.persist(
      'UPDATE',
      new List<BulkRecordUploadMappedRowV1>{
        new BulkRecordUploadMappedRowV1(
          3,
          new Account(Id = accountId, Name = 'Updated')
        )
      },
      null
    );
    List<BulkRecordUploadRowResultV1> upserted = gateway.persist(
      'UPSERT',
      new List<BulkRecordUploadMappedRowV1>{
        new BulkRecordUploadMappedRowV1(
          4,
          new Account(Id = accountId, Name = 'Upserted')
        )
      },
      Account.Id
    );
    List<BulkRecordUploadRowResultV1> deleted = gateway.persist(
      'DELETE',
      new List<BulkRecordUploadMappedRowV1>{
        new BulkRecordUploadMappedRowV1(5, new Account(Id = accountId))
      },
      null
    );

    Assert.isTrue(updated[0].isSuccess);
    Assert.isTrue(upserted[0].isSuccess);
    Assert.isTrue(deleted[0].isSuccess);
    Assert.areEqual(5, deleted[0].rowNumber);
  }

  @IsTest
  static void persist_UnapprovedOperation_IsRejected() {
    try {
      new BulkRecordUploadPersistenceGateway()
        .persist(
          'MERGE',
          new List<BulkRecordUploadMappedRowV1>{
            new BulkRecordUploadMappedRowV1(2, new Account(Name = 'No DML'))
          },
          null
        );
      Assert.fail('Expected operation exception.');
    } catch (BulkRecordUploadException error) {
      Assert.areEqual(
        'The persistence operation is invalid.',
        error.getMessage()
      );
    }
  }
}
