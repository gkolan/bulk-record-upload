@IsTest
private class BulkRecordUploadFieldConfigTest {
  @IsTest
  static void constructor_ExpandedActionsAndTransforms_AreAccepted() {
    Bulk_Record_Upload_Process_Field__mdt recordValue = baseRecord();
    recordValue.ExistingValueAction__c = 'ADD_VALUES';
    recordValue.TextSeparator__c = 'CUSTOM';
    recordValue.CustomSeparator__c = ' | ';
    recordValue.TrimValue__c = true;
    recordValue.CaseAction__c = 'UPPER';
    recordValue.BlankTokens__c = 'N/A, NULL,-';

    BulkRecordUploadFieldConfig config = new BulkRecordUploadFieldConfig(
      recordValue
    );

    Assert.areEqual('ADD_VALUES', config.existingValueAction);
    Assert.areEqual(' | ', config.customSeparator);
    Assert.isTrue(config.trimValue);
    Assert.areEqual('UPPER', config.caseAction);
    Assert.areEqual(new Set<String>{ 'n/a', 'null', '-' }, config.blankTokens);
  }

  @IsTest
  static void constructor_CustomSeparatorWithoutText_ThrowsDomainException() {
    Bulk_Record_Upload_Process_Field__mdt recordValue = baseRecord();
    recordValue.TextSeparator__c = 'CUSTOM';

    try {
      new BulkRecordUploadFieldConfig(recordValue);
      Assert.fail('Expected a missing custom separator exception.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(error.getMessage().contains('Custom Separator'));
    }
  }

  @IsTest
  static void constructor_DefaultBlankActionWithoutValue_ThrowsDomainException() {
    Bulk_Record_Upload_Process_Field__mdt recordValue = baseRecord();
    recordValue.BlankValueAction__c = 'DEFAULT';

    try {
      new BulkRecordUploadFieldConfig(recordValue);
      Assert.fail('Expected a missing default value exception.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(error.getMessage().contains('Default Value'));
    }
  }

  @IsTest
  static void constructor_CustomActionWithoutClass_ThrowsDomainException() {
    Bulk_Record_Upload_Process_Field__mdt recordValue = baseRecord();
    recordValue.ExistingValueAction__c = 'CUSTOM';

    try {
      new BulkRecordUploadFieldConfig(recordValue);
      Assert.fail('Expected a missing custom merge strategy class exception.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(error.getMessage().contains('Custom Merge Strategy Class'));
    }
  }

  @IsTest
  static void constructor_CustomActionWithClass_IsAccepted() {
    Bulk_Record_Upload_Process_Field__mdt recordValue = baseRecord();
    recordValue.ExistingValueAction__c = 'CUSTOM';
    recordValue.CustomMergeStrategyClass__c = 'BulkRecordUploadLongerTextStrategy';

    BulkRecordUploadFieldConfig config = new BulkRecordUploadFieldConfig(
      recordValue
    );

    Assert.areEqual(
      'BulkRecordUploadLongerTextStrategy',
      config.customMergeStrategyClass
    );
  }

  @IsTest
  static void constructor_InvalidValidationPattern_ThrowsDomainException() {
    Bulk_Record_Upload_Process_Field__mdt recordValue = baseRecord();
    recordValue.ValidationPattern__c = '[unterminated';

    try {
      new BulkRecordUploadFieldConfig(recordValue);
      Assert.fail('Expected an invalid-pattern exception.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(error.getMessage().contains('Validation Pattern'));
    }
  }

  @IsTest
  static void constructor_MinValueAboveMaxValue_ThrowsDomainException() {
    Bulk_Record_Upload_Process_Field__mdt recordValue = baseRecord();
    recordValue.MinValue__c = 100;
    recordValue.MaxValue__c = 10;

    try {
      new BulkRecordUploadFieldConfig(recordValue);
      Assert.fail('Expected a min-exceeds-max exception.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(error.getMessage().contains('Minimum Value'));
    }
  }

  @IsTest
  static void constructor_UnsupportedExistingValueAction_ThrowsDomainException() {
    Bulk_Record_Upload_Process_Field__mdt recordValue = baseRecord();
    recordValue.ExistingValueAction__c = 'MULTIPLY';

    try {
      new BulkRecordUploadFieldConfig(recordValue);
      Assert.fail('Expected an unsupported-action exception.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(error.getMessage().contains('not supported'));
    }
  }

  private static Bulk_Record_Upload_Process_Field__mdt baseRecord() {
    return new Bulk_Record_Upload_Process_Field__mdt(
      CsvColumnHeader__c = 'name',
      DisplayLabel__c = 'Name',
      FieldApiName__c = 'Name',
      ExistingValueAction__c = 'REPLACE',
      BlankValueAction__c = 'IGNORE',
      TextSeparator__c = 'SPACE',
      DuplicateTextAction__c = 'SKIP',
      OverflowAction__c = 'REJECT',
      ColumnOrder__c = 1
    );
  }
}
