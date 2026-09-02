// Smoke-check the deterministic Account demo configuration and generated templates.
List<String> processKeys = new List<String>{
  'Account_Insert_Demo',
  'Account_Update_Demo',
  'Account_Upsert_Demo',
  'Account_Delete_Demo'
};

for (String processKey : processKeys) {
  String templateCsv = BulkRecordUploadController.getTemplate(processKey);
  System.assert(String.isNotBlank(templateCsv), processKey + ' must generate a CSV template.');
  System.assert(templateCsv.contains('\n'), processKey + ' template must include a CSV header and sample row.');
}

System.assertEquals(
  4,
  [
    SELECT COUNT()
    FROM Bulk_Record_Upload_Process__mdt
    WHERE ObjectApiName__c = 'Account' AND IsActive__c = TRUE
  ],
  'Account must have four active demo processes.'
);

System.assertEquals(
  3,
  [SELECT COUNT() FROM Account WHERE BulkRecordUploadDemoExternalId__c LIKE 'ACC-DEMO-%'],
  'The Account demo must include one, multiple, and selectable record fixtures.'
);
