/**
 * Covers the Aura boundary's validation, safe-error, and status paths, plus
 * the non-fatal diagnostic behavior it surfaces to the component.
 */
@IsTest
private with sharing class BulkRecordUploadControllerTest {
  private static final String PROCESS_KEY = 'CONTROLLER';

  @IsTest
  static void getSelection_InvalidModeReturnsSafeAuraMessage() {
    Test.startTest();
    try {
      BulkRecordUploadController.getSelection(
        'NOT_A_MODE',
        null,
        null,
        'Account'
      );
      Assert.fail('Expected an unsupported selection mode to be rejected.');
    } catch (AuraHandledException error) {
      Assert.isNotNull(
        error.getMessage(),
        'The component should receive a safe message.'
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void getTemplate_MismatchedProcessKeyIsRejected() {
    BulkRecordUploadController.projectionOverride = projection();

    Test.startTest();
    try {
      BulkRecordUploadController.getTemplate('A_DIFFERENT_PROCESS');
      Assert.fail('Expected a mismatched process key to be rejected.');
    } catch (AuraHandledException error) {
      Assert.areEqual(
        'The upload process is invalid.',
        error.getMessage(),
        'A mismatched key should report an invalid process.'
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void getTemplate_OmitsDerivedSourceTemplateColumns() {
    BulkRecordUploadController.projectionOverride = projectionWithDerivedField();

    Test.startTest();
    String template = BulkRecordUploadController.getTemplate(PROCESS_KEY);
    Test.stopTest();

    Assert.isTrue(
      template.contains('"name"'),
      'A mapped column should appear in the template.'
    );
    Assert.isFalse(
      template.contains('"derived"'),
      'A derived column should never be requested from the user.'
    );
    Assert.isTrue(
      template.endsWith('\r\n'),
      'The template should end with a CRLF for spreadsheet tools.'
    );
  }

  @IsTest
  static void getProcessPresentation_MismatchedOverrideIsRejected() {
    BulkRecordUploadController.projectionOverride = projection();
    BulkRecordUploadController.presentationOverride = new BulkRecordUploadPresentation(
      'SOME_OTHER_KEY',
      null,
      null,
      null
    );

    Test.startTest();
    try {
      BulkRecordUploadController.getProcessPresentation(PROCESS_KEY);
      Assert.fail('Expected a mismatched presentation to be rejected.');
    } catch (AuraHandledException error) {
      Assert.areEqual(
        'The upload process is invalid.',
        error.getMessage(),
        'A mismatched presentation should report an invalid process.'
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void getProcessPresentation_UnknownProcessIsUnavailable() {
    BulkRecordUploadController.projectionOverride = projection();

    Test.startTest();
    try {
      BulkRecordUploadController.getProcessPresentation(PROCESS_KEY);
      Assert.fail('Expected an unconfigured process to be unavailable.');
    } catch (AuraHandledException error) {
      Assert.areEqual(
        'The upload process is unavailable.',
        error.getMessage(),
        'A process without active configuration should be unavailable.'
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void validateContext_ProcessWithoutContextAcceptsBlankRecord() {
    BulkRecordUploadController.projectionOverride = projection();

    Test.startTest();
    Boolean accepted = BulkRecordUploadController.validateContext(
      PROCESS_KEY,
      null
    );
    Test.stopTest();

    Assert.isTrue(
      accepted,
      'A process without record context should accept a blank parent.'
    );
  }

  @IsTest
  static void validateContext_RequiredParentIsEnforced() {
    BulkRecordUploadController.projectionOverride = parentRequiredProjection();

    Test.startTest();
    try {
      BulkRecordUploadController.validateContext(PROCESS_KEY, null);
      Assert.fail('Expected a required parent to be enforced.');
    } catch (AuraHandledException error) {
      Assert.areEqual(
        'This upload process requires a parent record page.',
        error.getMessage(),
        'A missing required parent should be reported clearly.'
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void validateContext_MismatchedParentTypeIsRejected() {
    BulkRecordUploadController.projectionOverride = parentRequiredProjection();
    Bulk_Record_Upload__c unrelated = BulkRecordUploadTestDataFactory.createUpload(
      PROCESS_KEY
    );

    Test.startTest();
    try {
      BulkRecordUploadController.validateContext(PROCESS_KEY, unrelated.Id);
      Assert.fail('Expected a mismatched parent type to be rejected.');
    } catch (AuraHandledException error) {
      Assert.areEqual(
        'The parent record does not match this upload process.',
        error.getMessage(),
        'A parent of the wrong object should be rejected.'
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void validateContext_MalformedParentIdIsRejected() {
    BulkRecordUploadController.projectionOverride = parentRequiredProjection();

    Test.startTest();
    try {
      BulkRecordUploadController.validateContext(PROCESS_KEY, 'not-an-id');
      Assert.fail('Expected a malformed parent id to be rejected.');
    } catch (AuraHandledException error) {
      Assert.areEqual(
        'The parent record is invalid.',
        error.getMessage(),
        'A malformed parent id should be rejected safely.'
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void validateContext_UnexpectedFailureReturnsGenericMessage() {
    Account parent = BulkRecordUploadTestDataFactory.createAccount(
      'Controller Context Parent'
    );
    BulkRecordUploadController.projectionOverride = projectionWithBadFilter();

    Test.startTest();
    try {
      BulkRecordUploadController.validateContext(PROCESS_KEY, parent.Id);
      Assert.fail('Expected an unresolvable filter field to fail.');
    } catch (AuraHandledException error) {
      Assert.areEqual(
        'The upload request could not be completed. Refresh the page and try again.',
        error.getMessage(),
        'An unexpected failure should never leak internal detail.'
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void getHistory_BlankProcessKeyReturnsRecentVisibleUploads() {
    BulkRecordUploadTestDataFactory.createUpload(PROCESS_KEY);

    Test.startTest();
    List<BulkRecordUploadHistoryItem> history = BulkRecordUploadController.getHistory(
      ''
    );
    Test.stopTest();

    Assert.isNotNull(
      history,
      'A blank process key should still return a history collection.'
    );
  }

  @IsTest
  static void getUploadStatus_ReturnsSafeItemAndRejectsUnknownId() {
    Bulk_Record_Upload__c upload = BulkRecordUploadTestDataFactory.createUpload(
      PROCESS_KEY
    );

    Test.startTest();
    BulkRecordUploadHistoryItem item = BulkRecordUploadController.getUploadStatus(
      upload.Id
    );
    try {
      BulkRecordUploadController.getUploadStatus(null);
      Assert.fail('Expected a missing upload id to be rejected.');
    } catch (AuraHandledException error) {
      Assert.isNotNull(
        error.getMessage(),
        'A missing upload id should produce a safe message.'
      );
    }
    Test.stopTest();

    Assert.areEqual(
      upload.Id,
      item.uploadId,
      'The status item should correlate to the requested upload.'
    );
    Assert.areEqual(
      BulkRecordUploadRuntimeContract.STATUS_QUEUED,
      item.status,
      'A new upload should report the queued status.'
    );
  }

  @IsTest
  static void warn_RecordsBoundedDiagnosticWithoutChangingStatus() {
    Bulk_Record_Upload__c upload = BulkRecordUploadTestDataFactory.createUpload(
      PROCESS_KEY
    );
    BulkRecordUploadLogService logService = new BulkRecordUploadLogService();

    Test.startTest();
    logService.warn(null, 'IGNORED', 'No upload to annotate.');
    logService.warn(upload.Id, null, null);
    Test.stopTest();

    Bulk_Record_Upload__c stored = [
      SELECT Status__c, LastErrorCode__c, LastErrorMessage__c
      FROM Bulk_Record_Upload__c
      WHERE Id = :upload.Id
    ];
    Assert.areEqual(
      BulkRecordUploadRuntimeContract.STATUS_QUEUED,
      stored.Status__c,
      'A warning should never change the upload status.'
    );
    Assert.areEqual(
      BulkRecordUploadRuntimeContract.REASON_EXTENSION_ERROR,
      stored.LastErrorCode__c,
      'A blank warning code should fall back to the extension reason.'
    );
    Assert.areEqual(
      'A post-processing extension did not complete.',
      stored.LastErrorMessage__c,
      'A blank warning message should fall back to a safe default.'
    );
  }

  @IsTest
  static void fail_TerminalUploadIsLeftUnchanged() {
    Bulk_Record_Upload__c upload = BulkRecordUploadTestDataFactory.createUpload(
      PROCESS_KEY
    );
    BulkRecordUploadTestDataFactory.completeUpload(upload, 5);
    BulkRecordUploadLogService logService = new BulkRecordUploadLogService();

    Test.startTest();
    logService.fail(upload.Id, 'LATE', 'Arrived after completion.');
    Test.stopTest();

    Bulk_Record_Upload__c stored = [
      SELECT Status__c, SuccessCount__c, LastErrorCode__c
      FROM Bulk_Record_Upload__c
      WHERE Id = :upload.Id
    ];
    Assert.areEqual(
      BulkRecordUploadRuntimeContract.STATUS_COMPLETED,
      stored.Status__c,
      'A terminal upload should not be reopened by a late failure.'
    );
    Assert.areEqual(
      5,
      stored.SuccessCount__c,
      'A late failure should not rewrite committed counts.'
    );
    Assert.isNull(
      stored.LastErrorCode__c,
      'A late failure should not annotate a completed upload.'
    );
  }

  private static BulkRecordUploadProjection projection() {
    return new BulkRecordUploadProjection(
      PROCESS_KEY,
      'hash',
      'Account',
      'INSERT',
      new List<String>(),
      50,
      30,
      new List<BulkRecordUploadFieldProjection>{ nameField() }
    );
  }

  private static BulkRecordUploadProjection parentRequiredProjection() {
    return new BulkRecordUploadProjection(
      PROCESS_KEY,
      'hash',
      'Contact',
      'INSERT',
      new List<String>(),
      'REQUIRE_PARENT',
      'Account',
      'AccountId',
      null,
      50,
      30,
      new List<BulkRecordUploadFieldProjection>{ nameField() }
    );
  }

  private static BulkRecordUploadProjection projectionWithBadFilter() {
    return new BulkRecordUploadProjection(
      PROCESS_KEY,
      'hash',
      'Contact',
      'INSERT',
      new List<String>(),
      'REQUIRE_PARENT',
      'Account',
      'AccountId',
      new BulkRecordUploadContextProjection(
        'PAGE',
        null,
        null,
        null,
        null,
        new List<BulkRecordUploadContextFilterCondition>{
          new BulkRecordUploadContextFilterCondition(
            'BulkRecordUploadNoSuchField__c',
            '=',
            new List<String>{ 'Retail' }
          )
        }
      ),
      50,
      30,
      new List<BulkRecordUploadFieldProjection>{ nameField() }
    );
  }

  private static BulkRecordUploadProjection projectionWithDerivedField() {
    return new BulkRecordUploadProjection(
      PROCESS_KEY,
      'hash',
      'Account',
      'INSERT',
      new List<String>(),
      50,
      30,
      new List<BulkRecordUploadFieldProjection>{ nameField(), derivedField() }
    );
  }

  private static BulkRecordUploadFieldProjection nameField() {
    return new BulkRecordUploadFieldProjection(
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
  }

  private static BulkRecordUploadFieldProjection derivedField() {
    return new BulkRecordUploadFieldProjection(
      'derived',
      'Derived',
      'Description',
      'TEXTAREA',
      'REPLACE',
      'IGNORE',
      'SPACE',
      null,
      'SKIP',
      'REJECT',
      null,
      false,
      'NONE',
      new Set<String>(),
      null,
      null,
      null,
      'RECORD_CONTEXT_ID',
      null,
      null,
      2,
      false,
      false,
      false,
      true,
      true,
      true
    );
  }
}
