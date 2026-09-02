@IsTest
private with sharing class BulkRecordUploadProcessPicklistTest {
  @IsTest
  static void getValues_NullPageContext_ReturnsSafeRows() {
    BulkRecordUploadProcessPicklist picklist = new BulkRecordUploadProcessPicklist(
      null
    );

    Test.startTest();
    VisualEditor.DynamicPickListRows rows = picklist.getValues();
    Test.stopTest();

    Assert.isNotNull(
      rows,
      'App Builder must always receive a rows collection.'
    );
  }
}
