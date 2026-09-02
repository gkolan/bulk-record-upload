@IsTest
private with sharing class BulkRecordUploadResolverTest {
  @IsTest
  static void assignRecordIds_MultipleRows_UsesOneQueryAndPreservesCorrelation() {
    BulkRecordUploadPersistenceGateway gateway = new BulkRecordUploadPersistenceGateway();
    List<BulkRecordUploadRowResult> inserted = gateway.persist(
      'INSERT',
      new List<BulkRecordUploadMappedRow>{
        new BulkRecordUploadMappedRow(2, new Account(Name = 'Resolve One')),
        new BulkRecordUploadMappedRow(3, new Account(Name = 'Resolve Two'))
      },
      null
    );
    List<BulkRecordUploadMappedRow> rows = new List<BulkRecordUploadMappedRow>{
      new BulkRecordUploadMappedRow(8, new Account(Name = 'Resolve One')),
      new BulkRecordUploadMappedRow(9, new Account(Name = 'Resolve Two'))
    };
    Integer beforeQueries = Limits.getQueries();
    new BulkRecordUploadRecordResolver().assignRecordIds(projection(), rows);
    Assert.areEqual(1, Limits.getQueries() - beforeQueries);
    Assert.areEqual(inserted[0].recordId, rows[0].record.Id);
    Assert.areEqual(inserted[1].recordId, rows[1].record.Id);
  }

  private static BulkRecordUploadProjection projection() {
    BulkRecordUploadFieldProjection field = new BulkRecordUploadFieldProjection(
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
    return new BulkRecordUploadProjection(
      'UPDATE_ACCOUNT',
      'hash',
      'Account',
      'UPDATE',
      new List<String>(),
      100,
      30,
      new List<BulkRecordUploadFieldProjection>{ field }
    );
  }
}
