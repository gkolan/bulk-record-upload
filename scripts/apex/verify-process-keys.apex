// Verifies the exact cacheable Aura method used by the multi-process demo component.
List<String> processKeys = BulkRecordUploadController.getProcessKeys();
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
