@IsTest
private with sharing class BulkRecordUploadRequestServiceTest {
  @IsTest
  static void submit_ValidRequest_StagesEnqueuesAndDeduplicates() {
    BulkRecordUploadProjection projection = projection();
    BulkRecordUploadRequestService.projectionOverride = projection;
    BulkRecordUploadJob.projectionOverride = projection;
    BulkRecordUploadSubmitRequest request = request(
      'Name\r\nRequest Account\r\n'
    );

    Test.startTest();
    BulkRecordUploadSubmission first = new BulkRecordUploadRequestService()
      .submit(request);
    BulkRecordUploadSubmission duplicate = new BulkRecordUploadRequestService()
      .submit(request);
    Test.stopTest();

    Assert.areEqual(first.uploadId, duplicate.uploadId);
    Assert.isFalse(first.isDuplicate);
    Assert.isTrue(duplicate.isDuplicate);
    Assert.areEqual(
      2,
      [
        SELECT COUNT()
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :first.uploadId
      ]
    );
  }

  @IsTest
  static void submit_ProcessNotInSpecifiedBundle_IsRejectedBeforeDml() {
    BulkRecordUploadProjection configuredProjection = projection();
    BulkRecordUploadRequestService.projectionOverride = configuredProjection;
    BulkRecordUploadSelectionService.bundleOverride = new Map<String, Bulk_Record_Upload_Bundle__mdt>{
      'OTHER_BUNDLE' => new Bulk_Record_Upload_Bundle__mdt(
        DeveloperName = 'OTHER_BUNDLE',
        MasterLabel = 'OTHER_BUNDLE',
        IsActive__c = true
      )
    };
    BulkRecordUploadSelectionService.assignmentOverride = new Map<String, Bulk_Record_Upload_Bundle_Process__mdt>{
      'OTHER' => new Bulk_Record_Upload_Bundle_Process__mdt(
        DeveloperName = 'OTHER_BUNDLE_OTHER_PROCESS',
        BundleDeveloperName__c = 'OTHER_BUNDLE',
        ProcessDeveloperName__c = 'OTHER_PROCESS',
        DisplayOrder__c = 1,
        IsActive__c = true
      )
    };
    BulkRecordUploadSubmitRequest request = request(
      'Name\r\nRequest Account\r\n'
    );
    request.bundleDeveloperName = 'OTHER_BUNDLE';

    Test.startTest();
    try {
      new BulkRecordUploadRequestService().submit(request);
      Assert.fail(
        'Expected a processKey outside the specified bundle to be rejected.'
      );
    } catch (BulkRecordUploadException error) {
      Assert.areEqual(
        'This upload process is not available.',
        error.getMessage(),
        'A direct submit for a process outside the bundle must fail the same way the picker would.'
      );
      Assert.areEqual(
        0,
        Limits.getDmlStatements(),
        'The bundle check must run before any DML.'
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void submit_InvalidIdempotencyKey_IsRejectedBeforeDml() {
    BulkRecordUploadSubmitRequest request = request('Name\nAcme\n');
    request.idempotencyKey = 'not-a-key';
    try {
      new BulkRecordUploadRequestService().submit(request);
      Assert.fail('Expected invalid request exception.');
    } catch (BulkRecordUploadException error) {
      Assert.areEqual('The upload request is invalid.', error.getMessage());
      Assert.areEqual(0, Limits.getDmlStatements());
    }
  }

  @IsTest
  static void controller_InvalidRequest_ReturnsSafeAuraError() {
    try {
      BulkRecordUploadController.submit(null);
      Assert.fail('Expected Aura error.');
    } catch (AuraHandledException error) {
      Assert.areEqual('The upload request is invalid.', error.getMessage());
    }
  }

  @IsTest
  static void controller_FixedProcess_ReturnsScopedHistory() {
    User userRecord = BulkRecordUploadTestDataFactory.createUser('fixedkey');
    BulkRecordUploadTestDataFactory.assignPermissionSets(
      userRecord.Id,
      new Set<String>{ 'Bulk_Record_Upload_User' }
    );
    System.runAs(userRecord) {
      BulkRecordUploadProjection configuredProjection = projection();
      BulkRecordUploadController.projectionOverride = configuredProjection;
      Bulk_Record_Upload__c matching = BulkRecordUploadTestDataFactory.createUpload(
        configuredProjection.processKey
      );
      BulkRecordUploadTestDataFactory.createUpload('OTHER_PROCESS');

      Test.startTest();
      List<BulkRecordUploadHistoryItem> history = BulkRecordUploadController.getHistory(
        configuredProjection.processKey
      );
      Test.stopTest();

      Assert.areEqual(1, history.size());
      Assert.areEqual(matching.Id, history[0].uploadId);
    }
  }

  @IsTest
  static void controller_FixedProcessMismatch_ReturnsSafeAuraError() {
    BulkRecordUploadController.projectionOverride = projection();

    Test.startTest();
    try {
      BulkRecordUploadController.getHistory('OTHER_PROCESS');
      Assert.fail('Expected a mismatched fixed process to be rejected.');
    } catch (AuraHandledException error) {
      Assert.areEqual('The upload process is invalid.', error.getMessage());
    }
    Test.stopTest();
  }

  @IsTest
  static void controller_Template_ReturnsProjectedColumnsOnly() {
    BulkRecordUploadController.projectionOverride = projection();

    Test.startTest();
    String templateCsv = BulkRecordUploadController.getTemplate('REQUEST');
    Test.stopTest();

    Assert.areEqual('"name"\r\n', templateCsv);
  }

  @IsTest
  static void controller_Presentation_ReturnsAuthorizedMetadataProjection() {
    BulkRecordUploadController.projectionOverride = projection();
    BulkRecordUploadController.presentationOverride = new BulkRecordUploadPresentation(
      'REQUEST',
      'Upload account records.',
      '<p>Before uploading:</p><ul><li>Use the template.</li></ul>',
      'standard:account'
    );

    Test.startTest();
    BulkRecordUploadPresentation presentation = BulkRecordUploadController.getProcessPresentation(
      'REQUEST'
    );
    Test.stopTest();

    Assert.areEqual(
      'REQUEST',
      presentation.processKey,
      'The presentation must remain scoped to the authorized process.'
    );
    Assert.areEqual(
      'Upload account records.',
      presentation.subtitle,
      'The configured subtitle should be returned without other metadata.'
    );
    Assert.isTrue(
      presentation.instructions.contains('<li>Use the template.</li>'),
      'The compact response should preserve configured list markup.'
    );
    Assert.areEqual(
      'standard:account',
      presentation.iconName,
      'A valid configured SLDS icon should be returned.'
    );
  }

  @IsTest
  static void recordContext_RequiredParent_IsValidatedAndApplied() {
    Account parent = BulkRecordUploadTestDataFactory.createAccount(
      'Context Parent'
    );
    BulkRecordUploadProjection projection = contextProjection();
    BulkRecordUploadRecordContextService service = new BulkRecordUploadRecordContextService();
    List<BulkRecordUploadMappedRow> rows = new List<BulkRecordUploadMappedRow>{
      new BulkRecordUploadMappedRow(2, new Contact(LastName = 'Child'))
    };

    Test.startTest();
    Id validated = service.validateContext(projection, parent.Id);
    service.applyContext(projection, validated, rows);
    Test.stopTest();

    Assert.areEqual(parent.Id, rows[0].record.get('AccountId'));
  }

  @IsTest
  static void recordContext_PageParent_OverridesCsvParent() {
    Account pageAccount = BulkRecordUploadTestDataFactory.createAccount(
      'Page Account'
    );
    Account csvSuppliedAccount = BulkRecordUploadTestDataFactory.createAccount(
      'Csv Supplied Account'
    );
    BulkRecordUploadProjection projection = contextProjection();
    List<BulkRecordUploadMappedRow> rows = new List<BulkRecordUploadMappedRow>{
      new BulkRecordUploadMappedRow(2, new Contact(LastName = 'Blank Parent')),
      new BulkRecordUploadMappedRow(
        3,
        new Contact(
          LastName = 'Supplied Parent',
          AccountId = csvSuppliedAccount.Id
        )
      )
    };

    Test.startTest();
    new BulkRecordUploadRecordContextService()
      .applyContext(projection, pageAccount.Id, rows);
    Test.stopTest();

    Assert.areEqual(
      pageAccount.Id,
      rows[0].record.get('AccountId'),
      'A row with no mapped parent should use the page parent.'
    );
    Assert.areEqual(
      pageAccount.Id,
      rows[1].record.get('AccountId'),
      'The trusted page parent must replace a CSV-supplied parent.'
    );
  }

  @IsTest
  static void recordContext_RequiredParentWithoutRecord_IsRejected() {
    Test.startTest();
    try {
      new BulkRecordUploadRecordContextService()
        .validateContext(contextProjection(), null);
      Assert.fail('Expected the missing parent to be rejected.');
    } catch (BulkRecordUploadException error) {
      Assert.areEqual(
        'This upload process requires a parent record page.',
        error.getMessage()
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void recordContext_FilteredOutParent_IsRejectedEvenWhenVisible() {
    Account eligible = BulkRecordUploadTestDataFactory.createAccountWithIndustry(
      'Eligible Parent',
      'Technology'
    );
    Account ineligible = BulkRecordUploadTestDataFactory.createAccountWithIndustry(
      'Ineligible Parent',
      'Retail'
    );
    BulkRecordUploadProjection projection = filteredContextProjection(
      'Industry',
      '=',
      new List<String>{ 'Technology' }
    );
    BulkRecordUploadRecordContextService service = new BulkRecordUploadRecordContextService();

    Test.startTest();
    Id validated = service.validateContext(projection, eligible.Id);
    Exception caughtError;
    try {
      service.validateContext(projection, ineligible.Id);
      Assert.fail('Expected the filtered-out parent to be rejected.');
    } catch (BulkRecordUploadException error) {
      caughtError = error;
    }
    Test.stopTest();

    Assert.areEqual(eligible.Id, validated);
    Assert.areEqual(
      'The parent record is unavailable.',
      caughtError.getMessage()
    );
  }

  @IsTest
  static void recordContext_IdInFilter_RejectsVisibleNonMemberBypassingTheComponent() {
    Account member = BulkRecordUploadTestDataFactory.createAccount(
      'Allowed Parent'
    );
    Account nonMember = BulkRecordUploadTestDataFactory.createAccount(
      'Other Parent'
    );
    BulkRecordUploadProjection projection = filteredContextProjection(
      'Id',
      'IN',
      new List<String>{ member.Id }
    );
    BulkRecordUploadRecordContextService service = new BulkRecordUploadRecordContextService();

    Test.startTest();
    try {
      service.validateContext(projection, nonMember.Id);
      Assert.fail(
        'A client-supplied ID outside the filter must be rejected server-side, proving a caller cannot bypass the LWC picker.'
      );
    } catch (BulkRecordUploadException error) {
      Assert.areEqual('The parent record is unavailable.', error.getMessage());
    }
    Test.stopTest();
  }

  private static BulkRecordUploadProjection filteredContextProjection(
    String fieldApiName,
    String operatorCode,
    List<String> values
  ) {
    BulkRecordUploadFieldProjection field = new BulkRecordUploadFieldProjection(
      'last name',
      'Last Name',
      'LastName',
      'STRING',
      'REPLACE',
      1,
      true,
      false,
      false,
      true,
      true,
      true
    );
    BulkRecordUploadContextProjection contextProj = new BulkRecordUploadContextProjection(
      'USER_CHOICE',
      'Name',
      new List<String>(),
      'Name',
      new List<String>(),
      new List<BulkRecordUploadContextFilterCondition>{
        new BulkRecordUploadContextFilterCondition(
          fieldApiName,
          operatorCode,
          values
        )
      }
    );
    return new BulkRecordUploadProjection(
      'CONTACT_FOR_ACCOUNT',
      'hash',
      'Contact',
      'INSERT',
      new List<String>(),
      'STANDARD_DML',
      'REQUIRE_PARENT',
      'Account',
      'AccountId',
      contextProj,
      100,
      30,
      new List<BulkRecordUploadFieldProjection>{ field }
    );
  }

  private static BulkRecordUploadSubmitRequest request(String csv) {
    BulkRecordUploadSubmitRequest request = new BulkRecordUploadSubmitRequest();
    request.processKey = 'REQUEST';
    request.fileName = 'request.csv';
    request.contentBase64 = EncodingUtil.base64Encode(Blob.valueOf(csv));
    request.idempotencyKey = EncodingUtil.convertToHex(
      Crypto.generateDigest('SHA-256', Blob.valueOf('request-key'))
    );
    return request;
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
      false,
      false,
      true,
      true,
      true
    );
    return new BulkRecordUploadProjection(
      'REQUEST',
      'hash',
      'Account',
      'INSERT',
      new List<String>(),
      100,
      30,
      new List<BulkRecordUploadFieldProjection>{ field }
    );
  }

  private static BulkRecordUploadProjection contextProjection() {
    BulkRecordUploadFieldProjection field = new BulkRecordUploadFieldProjection(
      'last name',
      'Last Name',
      'LastName',
      'STRING',
      'REPLACE',
      1,
      true,
      false,
      false,
      true,
      true,
      true
    );
    return new BulkRecordUploadProjection(
      'CONTACT_FOR_ACCOUNT',
      'hash',
      'Contact',
      'INSERT',
      new List<String>(),
      'STANDARD_DML',
      'REQUIRE_PARENT',
      'Account',
      'AccountId',
      null,
      100,
      30,
      new List<BulkRecordUploadFieldProjection>{ field }
    );
  }
}
