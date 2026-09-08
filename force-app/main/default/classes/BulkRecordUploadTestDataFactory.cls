/**
 * Sole public factory for reusable Bulk Record Upload Apex test records and permission assignments.
 */
@IsTest
public with sharing class BulkRecordUploadTestDataFactory {
  /** Creates one reusable Account parent for record-context tests. */
  public static Account createAccount(String name) {
    Account recordValue = new Account(Name = name);
    insert recordValue;
    return recordValue;
  }

  /**
   * Creates one reusable Account parent with a filterable standard field
   * set, for record-context eligibility filter tests.
   */
  public static Account createAccountWithIndustry(
    String name,
    String industry
  ) {
    Account recordValue = new Account(Name = name, Industry = industry);
    insert recordValue;
    return recordValue;
  }

  /**
   * Creates one active internal test user with the current test profile.
   * @param key Unique readable suffix for the test method.
   * @return Inserted user.
   */
  public static User createUser(String key) {
    String randomSuffix = String.valueOf(Crypto.getRandomLong())
      .replace('-', '');
    String uniqueValue =
      key +
      '.' +
      UserInfo.getOrganizationId() +
      '.' +
      randomSuffix +
      '@example.test';
    User userRecord = new User(
      Alias = ('bru' + key).left(8),
      Email = uniqueValue,
      EmailEncodingKey = 'UTF-8',
      LastName = 'Bulk Upload ' + key,
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = leastPrivilegeProfileId(),
      TimeZoneSidKey = 'America/Chicago',
      Username = uniqueValue
    );
    insert userRecord;
    return userRecord;
  }

  private static Id leastPrivilegeProfileId() {
    List<Profile> profiles = [
      SELECT Id
      FROM Profile
      WHERE
        UserType = 'Standard'
        AND UserLicense.Name = 'Salesforce'
        AND PermissionsModifyAllData = FALSE
        AND PermissionsViewAllData = FALSE
      WITH SYSTEM_MODE
      ORDER BY Name
      LIMIT 1
    ];
    Assert.isFalse(
      profiles.isEmpty(),
      'A standard least-privilege profile is required for security tests.'
    );
    return profiles[0].Id;
  }

  /**
   * Assigns project permission sets to a test user.
   * @param userId Test user identifier.
   * @param permissionSetNames Exact project Permission Set API names.
   */
  public static void assignPermissionSets(
    Id userId,
    Set<String> permissionSetNames
  ) {
    List<PermissionSet> permissionSets = [
      SELECT Id, Name
      FROM PermissionSet
      WHERE Name IN :permissionSetNames
      WITH SYSTEM_MODE
    ];
    List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
    for (PermissionSet permissionSet : permissionSets) {
      assignments.add(
        new PermissionSetAssignment(
          AssigneeId = userId,
          PermissionSetId = permissionSet.Id
        )
      );
    }
    insert as system assignments;
    Assert.areEqual(
      permissionSetNames.size(),
      assignments.size(),
      'Every requested project permission set should exist.'
    );
  }

  /** Revokes one project permission set from a reusable test user. */
  public static void revokePermissionSet(Id userId, String permissionSetName) {
    List<PermissionSetAssignment> assignments = [
      SELECT Id
      FROM PermissionSetAssignment
      WHERE AssigneeId = :userId AND PermissionSet.Name = :permissionSetName
      WITH SYSTEM_MODE
    ];
    delete as system assignments;
  }

  /**
   * Creates one reusable upload parent for staging, lifecycle, and Files tests.
   * @param key Stable test-specific process key.
   * @return Inserted upload parent.
   */
  public static Bulk_Record_Upload__c createUpload(String key) {
    Bulk_Record_Upload__c upload = new Bulk_Record_Upload__c(
      ProcessDeveloperName__c = key,
      IdempotencyKey__c = EncodingUtil.convertToHex(
        Crypto.generateDigest(
          'SHA-256',
          Blob.valueOf(key + String.valueOf(Crypto.getRandomLong()))
        )
      ),
      ConfigHash__c = 'hash',
      Status__c = 'QUEUED',
      SubmittedAt__c = System.now(),
      RetentionDays__c = 30,
      RowCount__c = 1,
      SuccessCount__c = 0,
      FailureCount__c = 0,
      IsArchived__c = false
    );
    insert as system upload;
    return upload;
  }

  /** Updates a reusable upload's deterministic row count. */
  public static void setUploadRowCount(
    Bulk_Record_Upload__c upload,
    Integer rowCount
  ) {
    upload.RowCount__c = rowCount;
    update as system upload;
  }

  /** Ages one active upload beyond the supported processing window. */
  public static void ageActiveUploadForRecovery(Bulk_Record_Upload__c upload) {
    upload.SubmittedAt__c = System.now()
      .addHours(-BulkRecordUploadRuntimeContract.MAX_ACTIVE_UPLOAD_HOURS - 1);
    update as system upload;
  }

  /** Marks an upload failed with a deterministic idempotency key. */
  public static void failUploadWithIdempotencyKey(
    Bulk_Record_Upload__c upload,
    String idempotencyKey
  ) {
    upload.IdempotencyKey__c = idempotencyKey;
    upload.Status__c = BulkRecordUploadRuntimeContract.STATUS_FAILED;
    update as system upload;
  }

  /** Marks one reusable chunk complete with deterministic outcome counts. */
  public static void completeChunk(
    Bulk_Record_Upload_Chunk__c chunk,
    Integer successes,
    Integer failures
  ) {
    chunk.Status__c = 'COMPLETED';
    chunk.SuccessCount__c = successes;
    chunk.FailureCount__c = failures;
    update as system chunk;
  }

  /**
   * Creates one terminal upload whose retention has elapsed.
   * @param key Stable test-specific process key.
   * @return Inserted expired upload parent.
   */
  public static Bulk_Record_Upload__c createExpiredUpload(String key) {
    Bulk_Record_Upload__c upload = new Bulk_Record_Upload__c(
      ProcessDeveloperName__c = key,
      IdempotencyKey__c = EncodingUtil.convertToHex(
        Crypto.generateDigest('SHA-256', Blob.valueOf(key))
      ),
      Status__c = 'COMPLETED',
      SubmittedAt__c = System.now().addDays(-40),
      ProcessingStartedAt__c = System.now().addDays(-40),
      CompletedAt__c = System.now().addDays(-31),
      RetentionDays__c = 30,
      RowCount__c = 1,
      SuccessCount__c = 1,
      FailureCount__c = 0,
      IsArchived__c = false
    );
    insert as system upload;
    return upload;
  }

  /**
   * Creates one reusable Account carrying an existing value for merge tests.
   * @param name Account name.
   * @param description Existing description the merge policy will combine.
   * @return Inserted Account with a populated existing value.
   */
  public static Account createAccountWithDescription(
    String name,
    String description
  ) {
    Account recordValue = new Account(Name = name, Description = description);
    insert recordValue;
    return recordValue;
  }

  /**
   * Removes one reusable Account so a matched record becomes unavailable.
   * @param recordValue Account to remove.
   * @return Identifier of the removed Account.
   */
  public static Id removeAccount(Account recordValue) {
    Id removedId = recordValue.Id;
    delete recordValue;
    return removedId;
  }

  /**
   * Moves one reusable upload to a terminal status with committed counts.
   * @param upload Upload parent to complete.
   * @param successes Committed successful row count.
   */
  public static void completeUpload(
    Bulk_Record_Upload__c upload,
    Integer successes
  ) {
    upload.Status__c = BulkRecordUploadRuntimeContract.STATUS_COMPLETED;
    upload.SuccessCount__c = successes;
    upload.CompletedAt__c = System.now();
    update as system upload;
  }

  /**
   * Creates ordered reusable input rows without database work.
   * @param count Exact number of rows to construct.
   * @return Ordered rows beginning at CSV row number two.
   */
  public static List<BulkRecordUploadRow> createRows(Integer count) {
    List<BulkRecordUploadRow> rows = new List<BulkRecordUploadRow>();
    for (Integer index = 0; index < count; index++) {
      rows.add(
        new BulkRecordUploadRow(
          index + 2,
          new Map<String, String>{ 'name' => 'Row ' + index }
        )
      );
    }
    return rows;
  }
}
