/**
 * Covers the configuration guards applied while a compact field projection is
 * built: supported types, ranges, upsert keys, lookups, merge actions,
 * uniqueness, record context, field access, and source templates.
 */
@IsTest
private class BulkRecordUploadProjectionValidatorTest {
  @IsTest
  static void validateSupportedType_AcceptsCsvSafeTypesAndRejectsOthers() {
    BulkRecordUploadProjectionValidator.validateSupportedType(
      describe('Account', 'Name')
    );
    BulkRecordUploadProjectionValidator.validateSupportedType(
      describe('Account', 'AnnualRevenue')
    );

    try {
      BulkRecordUploadProjectionValidator.validateSupportedType(
        describe('Attachment', 'Body')
      );
      Assert.fail('Expected an unsupported field type to be rejected.');
    } catch (BulkRecordUploadException error) {
      Assert.areEqual(
        'The configured target field type is not supported.',
        error.getMessage(),
        'An unsupported type should be reported clearly.'
      );
    }
  }

  @IsTest
  static void validateRange_RequiresNumericTargetField() {
    BulkRecordUploadFieldConfig numericConfig = config(
      new Map<String, Object>{
        'FieldApiName__c' => 'AnnualRevenue',
        'MinValue__c' => 1,
        'MaxValue__c' => 100
      }
    );
    BulkRecordUploadProjectionValidator.validateRange(
      numericConfig,
      describe('Account', 'AnnualRevenue')
    );

    try {
      BulkRecordUploadProjectionValidator.validateRange(
        numericConfig,
        describe('Account', 'Name')
      );
      Assert.fail('Expected numeric limits on a text field to be rejected.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(
        error.getMessage().contains('Minimum Value'),
        'A range on a text field should name the offending setting.'
      );
    }
  }

  @IsTest
  static void validateUpsertKey_RequiresExternalIdField() {
    BulkRecordUploadFieldConfig plainField = config(
      new Map<String, Object>{ 'IsUpsertExternalId__c' => false }
    );
    BulkRecordUploadProjectionValidator.validateUpsertKey(
      plainField,
      describe('Account', 'Name')
    );

    try {
      BulkRecordUploadProjectionValidator.validateUpsertKey(
        config(new Map<String, Object>{ 'IsUpsertExternalId__c' => true }),
        describe('Account', 'Name')
      );
      Assert.fail('Expected a non-External ID upsert key to be rejected.');
    } catch (BulkRecordUploadException error) {
      Assert.areEqual(
        'The configured upsert key must be a Salesforce External ID field.',
        error.getMessage(),
        'An upsert key must be an External ID.'
      );
    }
  }

  @IsTest
  static void validateLookupMatchField_RequiresRelationshipField() {
    BulkRecordUploadProjectionValidator.validateLookupMatchField(
      config(
        new Map<String, Object>{
          'FieldApiName__c' => 'AccountId',
          'LookupMatchField__c' => 'Name'
        }
      ),
      describe('Contact', 'AccountId')
    );

    try {
      BulkRecordUploadProjectionValidator.validateLookupMatchField(
        config(new Map<String, Object>{ 'LookupMatchField__c' => 'Name' }),
        describe('Account', 'Name')
      );
      Assert.fail('Expected a lookup match on a text field to be rejected.');
    } catch (BulkRecordUploadException error) {
      Assert.areEqual(
        'Lookup Match Field can be configured only for a relationship field.',
        error.getMessage(),
        'Lookup matching requires a relationship field.'
      );
    }
  }

  @IsTest
  static void validateBuiltInMergeStrategy_MatchesActionToFieldType() {
    BulkRecordUploadProjectionValidator.validateBuiltInMergeStrategy(
      config(new Map<String, Object>{ 'ExistingValueAction__c' => 'REPLACE' }),
      describe('Account', 'Name')
    );
    BulkRecordUploadProjectionValidator.validateBuiltInMergeStrategy(
      config(new Map<String, Object>{ 'ExistingValueAction__c' => 'APPEND' }),
      describe('Account', 'Name')
    );
    BulkRecordUploadProjectionValidator.validateBuiltInMergeStrategy(
      config(
        new Map<String, Object>{
          'FieldApiName__c' => 'AnnualRevenue',
          'ExistingValueAction__c' => 'ADD'
        }
      ),
      describe('Account', 'AnnualRevenue')
    );

    try {
      BulkRecordUploadProjectionValidator.validateBuiltInMergeStrategy(
        config(new Map<String, Object>{ 'ExistingValueAction__c' => 'ADD' }),
        describe('Account', 'Name')
      );
      Assert.fail('Expected a numeric action on a text field to be rejected.');
    } catch (BulkRecordUploadException error) {
      Assert.areEqual(
        'The existing-value action does not support its configured field type.',
        error.getMessage(),
        'A mismatched action should be reported clearly.'
      );
    }
  }

  @IsTest
  static void validateUnique_RejectsRepeatedColumnSequenceOrField() {
    Set<String> columnKeys = new Set<String>();
    Set<Integer> sequences = new Set<Integer>();
    Set<String> targetFields = new Set<String>();

    BulkRecordUploadProjectionValidator.validateUnique(
      config(new Map<String, Object>()),
      columnKeys,
      sequences,
      targetFields
    );
    Assert.isTrue(
      columnKeys.contains('name'),
      'A validated column should be recorded for later comparison.'
    );

    try {
      BulkRecordUploadProjectionValidator.validateUnique(
        config(
          new Map<String, Object>{
            'FieldApiName__c' => 'Description',
            'ColumnOrder__c' => 2
          }
        ),
        columnKeys,
        sequences,
        targetFields
      );
      Assert.fail('Expected a repeated column key to be rejected.');
    } catch (BulkRecordUploadException error) {
      Assert.areEqual(
        'Process field columns and sequences must be unique.',
        error.getMessage(),
        'Repeated configuration should be reported clearly.'
      );
    }

    try {
      BulkRecordUploadProjectionValidator.validateUnique(
        config(
          new Map<String, Object>{
            'CsvColumnHeader__c' => 'description',
            'FieldApiName__c' => 'Description',
            'ColumnOrder__c' => 1
          }
        ),
        columnKeys,
        sequences,
        targetFields
      );
      Assert.fail('Expected a repeated sequence to be rejected.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(
        error.getMessage().contains('unique'),
        'A repeated sequence should be reported as a uniqueness problem.'
      );
    }
  }

  @IsTest
  static void validateFieldAccess_RejectsDerivedAndReadOnlyFields() {
    BulkRecordUploadProjectionValidator.validateFieldAccess(
      config(new Map<String, Object>()),
      describe('Account', 'Name'),
      'INSERT'
    );
    BulkRecordUploadProjectionValidator.validateFieldAccess(
      config(new Map<String, Object>()),
      describe('Account', 'Name'),
      'UPDATE'
    );

    try {
      BulkRecordUploadProjectionValidator.validateFieldAccess(
        config(new Map<String, Object>{ 'FieldApiName__c' => 'CreatedDate' }),
        describe('Account', 'CreatedDate'),
        'INSERT'
      );
      Assert.fail('Expected a system audit field to be rejected.');
    } catch (BulkRecordUploadException error) {
      Assert.areEqual(
        'A configured target field is inaccessible or read-only.',
        error.getMessage(),
        'A read-only field should be reported clearly.'
      );
    }
  }

  @IsTest
  static void validateRecordContext_ChecksRelationshipAndWriteAccess() {
    BulkRecordUploadProjectionValidator.validateRecordContext(
      processConfig('NONE', null, null, 'INSERT'),
      Account.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED)
    );
    BulkRecordUploadProjectionValidator.validateRecordContext(
      processConfig('REQUIRE_PARENT', 'Account', 'AccountId', 'INSERT'),
      Contact.SObjectType.getDescribe(SObjectDescribeOptions.FULL)
    );

    try {
      BulkRecordUploadProjectionValidator.validateRecordContext(
        processConfig(
          'REQUIRE_PARENT',
          'BulkRecordUploadNoSuchObject',
          'AccountId',
          'INSERT'
        ),
        Contact.SObjectType.getDescribe(SObjectDescribeOptions.FULL)
      );
      Assert.fail('Expected an unknown host object to be rejected.');
    } catch (BulkRecordUploadException error) {
      Assert.areEqual(
        'Configured record context is unavailable.',
        error.getMessage(),
        'An unresolvable host object should be reported clearly.'
      );
    }

    try {
      BulkRecordUploadProjectionValidator.validateRecordContext(
        processConfig('REQUIRE_PARENT', 'Account', 'LastName', 'INSERT'),
        Contact.SObjectType.getDescribe(SObjectDescribeOptions.FULL)
      );
      Assert.fail('Expected a non-relationship context field to be rejected.');
    } catch (BulkRecordUploadException error) {
      Assert.areEqual(
        'Configured parent relationship is not allowed.',
        error.getMessage(),
        'A parent relationship must point at the host object.'
      );
    }
  }

  @IsTest
  static void validateSourceTemplates_RequiresSuppliedColumns() {
    List<BulkRecordUploadFieldProjection> fields = new List<BulkRecordUploadFieldProjection>{
      projectedField('name', 'STRING', 'REPLACE', null),
      projectedField('summary', 'TEXTAREA', 'REPLACE', '{name}')
    };

    BulkRecordUploadProjectionValidator.validateSourceTemplates(
      fields,
      new Set<String>{ 'name' }
    );

    try {
      BulkRecordUploadProjectionValidator.validateSourceTemplates(
        fields,
        new Set<String>{ 'other' }
      );
      Assert.fail('Expected a template on an unsupplied column to fail.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(
        error.getMessage().contains('Source Template'),
        'An unresolved template token should name the setting.'
      );
    }
  }

  private static Schema.DescribeFieldResult describe(
    String objectApiName,
    String fieldApiName
  ) {
    return Schema.getGlobalDescribe()
      .get(objectApiName)
      .getDescribe()
      .fields.getMap()
      .get(fieldApiName)
      .getDescribe();
  }

  private static BulkRecordUploadFieldConfig config(
    Map<String, Object> overrides
  ) {
    Map<String, Object> values = new Map<String, Object>{
      'CsvColumnHeader__c' => 'name',
      'DisplayLabel__c' => 'Name',
      'FieldApiName__c' => 'Name',
      'ExistingValueAction__c' => 'REPLACE',
      'BlankValueAction__c' => 'IGNORE',
      'TextSeparator__c' => 'SPACE',
      'DuplicateTextAction__c' => 'SKIP',
      'OverflowAction__c' => 'REJECT',
      'ColumnOrder__c' => 1
    };
    values.putAll(overrides);
    return new BulkRecordUploadFieldConfig(
      (Bulk_Record_Upload_Process_Field__mdt) JSON.deserialize(
        JSON.serialize(values),
        Bulk_Record_Upload_Process_Field__mdt.class
      )
    );
  }

  private static BulkRecordUploadProcessConfig processConfig(
    String recordContextAction,
    String hostObjectApiName,
    String recordContextFieldApiName,
    String operation
  ) {
    return new BulkRecordUploadProcessConfig(
      new Bulk_Record_Upload_Process__mdt(
        DeveloperName = 'ValidatorProcess',
        ObjectApiName__c = 'Contact',
        Operation__c = operation,
        IsActive__c = true,
        RowsPerBatch__c = 50,
        RetentionDays__c = 30,
        RecordContextAction__c = recordContextAction,
        HostObjectApiName__c = hostObjectApiName,
        RecordContextFieldApiName__c = recordContextFieldApiName
      )
    );
  }

  private static BulkRecordUploadFieldProjection projectedField(
    String columnKey,
    String fieldType,
    String existingValueAction,
    String sourceTemplate
  ) {
    return new BulkRecordUploadFieldProjection(
      columnKey,
      columnKey,
      'Name',
      fieldType,
      existingValueAction,
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
      sourceTemplate,
      null,
      null,
      1,
      false,
      false,
      false,
      true,
      true,
      true
    );
  }
}
