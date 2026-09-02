// Verifies that every optional demo process resolves through the production security and schema projection.
Map<String, Integer> expectedFieldCounts = new Map<String, Integer>{
  'Account_Insert_Demo' => 6, 'Account_Update_Demo' => 4,
  'Account_Upsert_Demo' => 4, 'Account_Delete_Demo' => 1,
  'Contact_Insert_Demo' => 6, 'Contact_Update_Demo' => 5,
  'Contact_Upsert_Demo' => 5, 'Contact_Delete_Demo' => 1,
  'Opportunity_Insert_Demo' => 7, 'Opportunity_Update_Demo' => 6,
  'Opportunity_Upsert_Demo' => 6, 'Opportunity_Delete_Demo' => 1
};
BulkRecordUploadProjectionService service = new BulkRecordUploadProjectionService();
List<String> processKeys = new List<String>(expectedFieldCounts.keySet());
processKeys.sort();
for (String processKey : processKeys) {
  BulkRecordUploadProjection projection;
  try {
    projection = service.getProjection(processKey);
  } catch (Exception error) {
    throw new BulkRecordUploadException(processKey + ': ' + error.getMessage());
  }
  System.assertEquals(expectedFieldCounts.get(processKey), projection.getFields().size(), processKey + ' field count');
  System.assertEquals(processKey.substringBefore('_'), projection.objectApiName, processKey + ' object');
}
System.assertEquals(12, expectedFieldCounts.size(), 'Exactly twelve demo processes should resolve.');
