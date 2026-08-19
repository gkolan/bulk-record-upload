@IsTest
private with sharing class BulkRecordUploadResolverTest {
  @IsTest
  static void assignRecordIds_MultipleRows_UsesOneQueryAndPreservesCorrelation() {
    BulkRecordUploadPersistenceGateway gateway = new BulkRecordUploadPersistenceGateway();
    List<BulkRecordUploadRowResultV1> inserted = gateway.persist(
      'INSERT',
      new List<BulkRecordUploadMappedRowV1>{
        new BulkRecordUploadMappedRowV1(2, new Account(Name = 'Resolve One')),
        new BulkRecordUploadMappedRowV1(3, new Account(Name = 'Resolve Two'))
      },
      null
    );
    List<BulkRecordUploadMappedRowV1> rows = new List<BulkRecordUploadMappedRowV1>{
      new BulkRecordUploadMappedRowV1(8, new Account(Name = 'Resolve One')),
      new BulkRecordUploadMappedRowV1(9, new Account(Name = 'Resolve Two'))
    };
    Integer beforeQueries = Limits.getQueries();
    new BulkRecordUploadRecordResolver().assignRecordIds(projection(), rows);
    Assert.areEqual(1, Limits.getQueries() - beforeQueries);
    Assert.areEqual(inserted[0].recordId, rows[0].record.Id);
    Assert.areEqual(inserted[1].recordId, rows[1].record.Id);
  }

  private static BulkRecordUploadProjectionV1 projection() {
    BulkRecordUploadFieldProjectionV1 field = new BulkRecordUploadFieldProjectionV1(
      'name',
      'Name',
      'Name',
      'STRING',
      'REPLACE',
      1,
      true,
      true,
      false,
      true,
      true,
      true
    );
    return new BulkRecordUploadProjectionV1(
      'UPDATE_ACCOUNT',
      'hash',
      'Account',
      'UPDATE',
      'STANDARD_V1',
      100,
      30,
      new List<BulkRecordUploadFieldProjectionV1>{ field }
    );
  }
}
