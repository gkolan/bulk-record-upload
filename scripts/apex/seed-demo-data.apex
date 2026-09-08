// Deterministic, synthetic records for all Account, Contact, and Opportunity demos.
List<Account> oldAccounts = [
  SELECT Id
  FROM Account
  WHERE Name LIKE 'Bulk Upload Demo %' OR Name LIKE 'Bulk Upload CSV %'
];
if (!oldAccounts.isEmpty()) {
  delete oldAccounts;
}

Set<String> demoContactLastNames = new Set<String>{
  'CSV Contact One',
  'CSV Contact Two'
};
Set<String> demoContactKeys = new Set<String>{
  'CON-DEMO-001',
  'CON-DEMO-002',
  'CON-DEMO-DELETE',
  'CON-DEMO-NEW'
};
List<Contact> oldContacts = [
  SELECT Id
  FROM Contact
  WHERE
    LastName IN :demoContactLastNames
    OR BulkRecordUploadDemoExternalId__c IN :demoContactKeys
];
if (!oldContacts.isEmpty()) {
  delete oldContacts;
}

Set<String> demoOpportunityNames = new Set<String>{
  'Bulk Upload CSV Opportunity One',
  'Bulk Upload CSV Opportunity Two'
};
Set<String> demoOpportunityKeys = new Set<String>{
  'OPP-DEMO-001',
  'OPP-DEMO-002',
  'OPP-DEMO-DELETE',
  'OPP-DEMO-NEW'
};
List<Opportunity> oldOpportunities = [
  SELECT Id
  FROM Opportunity
  WHERE
    Name IN :demoOpportunityNames
    OR BulkRecordUploadDemoExternalId__c IN :demoOpportunityKeys
];
if (!oldOpportunities.isEmpty()) {
  delete oldOpportunities;
}

List<Account> accounts = new List<Account>{
  new Account(
    Name = 'Bulk Upload Demo Alpha',
    Description = 'Update and upsert fixture.',
    BulkRecordUploadDemoExternalId__c = 'ACC-DEMO-001'
  ),
  new Account(
    Name = 'Bulk Upload Demo Beta',
    Description = 'Update fixture.',
    BulkRecordUploadDemoExternalId__c = 'ACC-DEMO-002'
  ),
  new Account(
    Name = 'Bulk Upload Demo Delete',
    Description = 'Delete fixture.',
    BulkRecordUploadDemoExternalId__c = 'ACC-DEMO-DELETE'
  )
};
insert accounts;

List<Contact> contacts = new List<Contact>{
  new Contact(
    FirstName = 'Demo',
    LastName = 'Contact One',
    Email = 'contact1@example.test',
    AccountId = accounts[0].Id,
    BulkRecordUploadDemoExternalId__c = 'CON-DEMO-001'
  ),
  new Contact(
    FirstName = 'Demo',
    LastName = 'Contact Two',
    Email = 'contact2@example.test',
    AccountId = accounts[0].Id,
    BulkRecordUploadDemoExternalId__c = 'CON-DEMO-002'
  ),
  new Contact(
    FirstName = 'Demo',
    LastName = 'Contact Delete',
    Email = 'contact.delete@example.test',
    AccountId = accounts[0].Id,
    BulkRecordUploadDemoExternalId__c = 'CON-DEMO-DELETE'
  )
};
insert contacts;

List<Opportunity> opportunities = new List<Opportunity>{
  new Opportunity(
    Name = 'Bulk Upload Demo Opportunity One',
    AccountId = accounts[0].Id,
    StageName = 'Prospecting',
    CloseDate = Date.today().addDays(60),
    BulkRecordUploadDemoExternalId__c = 'OPP-DEMO-001'
  ),
  new Opportunity(
    Name = 'Bulk Upload Demo Opportunity Two',
    AccountId = accounts[0].Id,
    StageName = 'Prospecting',
    CloseDate = Date.today().addDays(90),
    BulkRecordUploadDemoExternalId__c = 'OPP-DEMO-002'
  ),
  new Opportunity(
    Name = 'Bulk Upload Demo Opportunity Delete',
    AccountId = accounts[0].Id,
    StageName = 'Prospecting',
    CloseDate = Date.today().addDays(30),
    BulkRecordUploadDemoExternalId__c = 'OPP-DEMO-DELETE'
  )
};
insert opportunities;

System.assertEquals(
  3,
  [
    SELECT COUNT()
    FROM Account
    WHERE BulkRecordUploadDemoExternalId__c LIKE 'ACC-DEMO-%'
  ]
);
System.assertEquals(
  3,
  [
    SELECT COUNT()
    FROM Contact
    WHERE BulkRecordUploadDemoExternalId__c LIKE 'CON-DEMO-%'
  ]
);
System.assertEquals(
  3,
  [
    SELECT COUNT()
    FROM Opportunity
    WHERE BulkRecordUploadDemoExternalId__c LIKE 'OPP-DEMO-%'
  ]
);
