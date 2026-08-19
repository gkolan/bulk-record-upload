@IsTest
private with sharing class BulkRecordUploadRequestServiceTest {
  @IsTest
  static void submit_ValidRequest_StagesEnqueuesAndDeduplicates() {
    BulkRecordUploadProjectionV1 projection = projection();
    BulkRecordUploadRequestService.projectionOverride = projection;
    BulkRecordUploadJob.projectionOverride = projection;
    BulkRecordUploadSubmitRequestV1 request = request(
      'Name\r\nRequest Account\r\n'
    );

    Test.startTest();
    BulkRecordUploadSubmissionV1 first = new BulkRecordUploadRequestService()
      .submit(request);
    BulkRecordUploadSubmissionV1 duplicate = new BulkRecordUploadRequestService()
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
  static void submit_InvalidIdempotencyKey_IsRejectedBeforeDml() {
    BulkRecordUploadSubmitRequestV1 request = request('Name\nAcme\n');
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
      BulkRecordUploadProjectionV1 configuredProjection = projection();
      BulkRecordUploadController.projectionOverride = configuredProjection;
      Bulk_Record_Upload__c matching = BulkRecordUploadTestDataFactory.createUpload(
        configuredProjection.processKey
      );
      BulkRecordUploadTestDataFactory.createUpload('OTHER_PROCESS');

      Test.startTest();
      List<BulkRecordUploadHistoryItemV1> history = BulkRecordUploadController.getHistory(
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
    BulkRecordUploadController.presentationOverride = new BulkRecordUploadPresentationV1(
      'REQUEST',
      'Upload account records.',
      '<p>Before uploading:</p><ul><li>Use the template.</li></ul>',
      'standard:account'
    );

    Test.startTest();
    BulkRecordUploadPresentationV1 presentation = BulkRecordUploadController.getProcessPresentation(
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
  static void submit_InvalidBase64_IsRejectedSafely() {
    BulkRecordUploadSubmitRequestV1 request = request('Name\nAcme\n');
    request.contentBase64 = '%%%invalid%%%';
    try {
      new BulkRecordUploadRequestService().submit(request);
      Assert.fail('Expected file-encoding exception.');
    } catch (BulkRecordUploadException error) {
      Assert.areEqual(
        'The uploaded file encoding is invalid.',
        error.getMessage()
      );
    }
  }

  @IsTest
  static void recordContext_RequiredParent_IsValidatedAndApplied() {
    Account parent = BulkRecordUploadTestDataFactory.createAccount(
      'Context Parent'
    );
    BulkRecordUploadProjectionV1 projection = contextProjection();
    BulkRecordUploadRecordContextService service = new BulkRecordUploadRecordContextService();
    List<BulkRecordUploadMappedRowV1> rows = new List<BulkRecordUploadMappedRowV1>{
      new BulkRecordUploadMappedRowV1(2, new Contact(LastName = 'Child'))
    };

    Test.startTest();
    Id validated = service.validateContext(projection, parent.Id);
    service.applyContext(projection, validated, rows);
    Test.stopTest();

    Assert.areEqual(parent.Id, rows[0].record.get('AccountId'));
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

  private static BulkRecordUploadSubmitRequestV1 request(String csv) {
    BulkRecordUploadSubmitRequestV1 request = new BulkRecordUploadSubmitRequestV1();
    request.processKey = 'REQUEST';
    request.fileName = 'request.csv';
    request.contentBase64 = EncodingUtil.base64Encode(Blob.valueOf(csv));
    request.idempotencyKey = EncodingUtil.convertToHex(
      Crypto.generateDigest('SHA-256', Blob.valueOf('request-key'))
    );
    return request;
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
      false,
      false,
      true,
      true,
      true
    );
    return new BulkRecordUploadProjectionV1(
      'REQUEST',
      'hash',
      'Account',
      'INSERT',
      'STANDARD_V1',
      100,
      30,
      new List<BulkRecordUploadFieldProjectionV1>{ field }
    );
  }

  private static BulkRecordUploadProjectionV1 contextProjection() {
    BulkRecordUploadFieldProjectionV1 field = new BulkRecordUploadFieldProjectionV1(
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
    return new BulkRecordUploadProjectionV1(
      'CONTACT_FOR_ACCOUNT',
      'hash',
      'Contact',
      'INSERT',
      'STANDARD_V1',
      'STANDARD_DML_V1',
      null,
      'REQUIRE_PARENT',
      'Account',
      'AccountId',
      100,
      30,
      new List<BulkRecordUploadFieldProjectionV1>{ field }
    );
  }
}
