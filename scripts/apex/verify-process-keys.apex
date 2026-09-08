// Verifies the exact Aura method used by the multi-process demo component.
Map<String, Integer> expectedCountsByHostObject = new Map<String, Integer>{
  'Account' => 5,
  'Contact' => 3,
  'Opportunity' => 4
};
List<String> processKeys = new List<String>();
for (String objectApiName : expectedCountsByHostObject.keySet()) {
  BulkRecordUploadSelection selection = BulkRecordUploadController.getSelection(
    'ALL_ACTIVE_FOR_OBJECT',
    null,
    null,
    objectApiName
  );
  System.assertEquals(
    expectedCountsByHostObject.get(objectApiName),
    selection.processes.size(),
    objectApiName + ' should expose the expected active demo processes.'
  );
  for (BulkRecordUploadProcessOption processOption : selection.processes) {
    processKeys.add(processOption.value);
  }
}
System.assertEquals(
  12,
  processKeys.size(),
  'The demo selector should expose all twelve active processes.'
);
System.assert(
  processKeys.contains('Account_Insert_Demo'),
  'Account insert should be visible.'
);
System.assert(
  processKeys.contains('Contact_Insert_Demo'),
  'Contact insert should be visible.'
);
System.assert(
  processKeys.contains('Opportunity_Insert_Demo'),
  'Opportunity insert should be visible.'
);
