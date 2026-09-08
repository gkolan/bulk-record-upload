/**
 * Covers the Lightning App Builder picklists and the safe presentation DTO
 * returned to the upload component.
 */
@IsTest
private class BulkRecordUploadAppBuilderTest {
  @IsTest
  static void bundlePicklist_NullPageContextReturnsEveryActiveBundle() {
    BulkRecordUploadBundlePicklist picklist = new BulkRecordUploadBundlePicklist(
      null
    );

    Test.startTest();
    VisualEditor.DynamicPickListRows rows = picklist.getValues();
    Test.stopTest();

    Assert.isNotNull(
      rows,
      'App Builder must always receive a rows collection.'
    );
    Assert.areEqual(
      activeBundleCount(),
      rows.size(),
      'A blank page context should offer every active bundle.'
    );
  }

  @IsTest
  static void bundlePicklist_ScopesRowsToThePageObject() {
    VisualEditor.DesignTimePageContext context = new VisualEditor.DesignTimePageContext();
    context.entityName = 'Account';

    Test.startTest();
    VisualEditor.DynamicPickListRows rows = new BulkRecordUploadBundlePicklist(
        context
      )
      .getValues();
    Test.stopTest();

    Assert.isNotNull(rows, 'A scoped context should still return rows.');
    Assert.areEqual(
      compatibleBundleCount('Account'),
      rows.size(),
      'Only bundles reachable from an active Account process should appear.'
    );
  }

  @IsTest
  static void bundlePicklist_LeavesAmbiguousDefaultBlank() {
    VisualEditor.DesignTimePageContext context = new VisualEditor.DesignTimePageContext();
    context.entityName = 'BulkRecordUploadNoSuchObject';

    Test.startTest();
    BulkRecordUploadBundlePicklist picklist = new BulkRecordUploadBundlePicklist(
      context
    );
    VisualEditor.DataRow defaultRow = picklist.getDefaultValue();
    Integer rowCount = picklist.getValues().size();
    Test.stopTest();

    Assert.areEqual(
      0,
      rowCount,
      'An unrelated page object should offer no bundles.'
    );
    Assert.isNull(
      defaultRow,
      'App Builder should not preselect a value when none is compatible.'
    );
  }

  @IsTest
  static void processPicklist_ScopesRowsAndDefaultToThePageObject() {
    VisualEditor.DesignTimePageContext context = new VisualEditor.DesignTimePageContext();
    context.entityName = 'BulkRecordUploadNoSuchObject';

    Test.startTest();
    BulkRecordUploadProcessPicklist picklist = new BulkRecordUploadProcessPicklist(
      context
    );
    Integer rowCount = picklist.getValues().size();
    VisualEditor.DataRow defaultRow = picklist.getDefaultValue();
    Test.stopTest();

    Assert.areEqual(
      0,
      rowCount,
      'An unrelated page object should offer no processes.'
    );
    Assert.isNull(
      defaultRow,
      'App Builder should not preselect an incompatible process.'
    );
  }

  @IsTest
  static void presentation_NormalizesLabelsAndIcon() {
    BulkRecordUploadPresentation presentation = new BulkRecordUploadPresentation(
      '  Account_Insert  ',
      '  Create accounts  ',
      '  Use the template.  ',
      'standard:account'
    );

    Assert.areEqual(
      'Account_Insert',
      presentation.processKey,
      'The process key should be trimmed.'
    );
    Assert.areEqual(
      'Create accounts',
      presentation.subtitle,
      'The subtitle should be trimmed.'
    );
    Assert.areEqual(
      'Use the template.',
      presentation.instructions,
      'Instructions should be trimmed.'
    );
    Assert.areEqual(
      'standard:account',
      presentation.iconName,
      'A valid icon name should be kept.'
    );
    Assert.areEqual(
      'NONE',
      presentation.recordContextAction,
      'A presentation without a projection should not request record context.'
    );
    Assert.areEqual(
      'PAGE',
      presentation.recordContextSource,
      'A presentation without a projection should default to the page source.'
    );
    Assert.isTrue(
      presentation.additionalSearchFields.isEmpty(),
      'Search fields should default to an empty list.'
    );
    Assert.isNull(
      presentation.filterCriteriaJson,
      'No configured conditions should produce no filter criteria.'
    );
  }

  @IsTest
  static void presentation_RejectsMissingProcessKeyAndUnsafeIcon() {
    try {
      new BulkRecordUploadPresentation('  ', null, null, null);
      Assert.fail('Expected a blank process key to be rejected.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(
        error.getMessage().contains('required'),
        'A blank process key should be reported as required.'
      );
    }

    Assert.areEqual(
      'utility:upload',
      new BulkRecordUploadPresentation(
          'Account_Insert',
          null,
          null,
          'javascript:alert(1)'
        )
        .iconName,
      'An unsafe icon name should fall back to the default icon.'
    );
    Assert.areEqual(
      'utility:upload',
      new BulkRecordUploadPresentation('Account_Insert', null, null, null)
        .iconName,
      'A missing icon name should fall back to the default icon.'
    );
  }

  @IsTest
  static void presentation_CarriesRecordContextPickerSettings() {
    BulkRecordUploadContextProjection contextProjection = new BulkRecordUploadContextProjection(
      'PICKER',
      'Name',
      new List<String>{ 'AccountNumber' },
      'Name',
      new List<String>{ 'Industry' },
      new List<BulkRecordUploadContextFilterCondition>{
        new BulkRecordUploadContextFilterCondition(
          'Industry',
          '=',
          new List<String>{ 'Retail' }
        ),
        new BulkRecordUploadContextFilterCondition(
          'Rating',
          '!=',
          new List<String>{ 'Cold' }
        ),
        new BulkRecordUploadContextFilterCondition(
          'Type',
          'IN',
          new List<String>{ 'Customer', 'Partner' }
        )
      }
    );

    BulkRecordUploadPresentation presentation = new BulkRecordUploadPresentation(
      'Contact_Insert',
      null,
      null,
      null,
      projectionWithContext(contextProjection)
    );

    Assert.areEqual(
      'PICKER',
      presentation.recordContextSource,
      'The configured record-context source should be carried through.'
    );
    Assert.areEqual(
      'Account',
      presentation.hostObjectApiName,
      'The host object should be carried through.'
    );
    Assert.areEqual(
      'Name',
      presentation.primarySearchField,
      'The primary search field should be carried through.'
    );
    Assert.areEqual(
      new List<String>{ 'Industry' },
      presentation.additionalDisplayFields,
      'Additional display fields should be carried through.'
    );

    Map<String, Object> criteria = (Map<String, Object>) JSON.deserializeUntyped(
      presentation.filterCriteriaJson
    );
    Assert.areEqual(
      'and',
      criteria.get('filterLogic'),
      'Configured conditions should combine with AND.'
    );
    List<Object> conditions = (List<Object>) criteria.get('criteria');
    Assert.areEqual(
      3,
      conditions.size(),
      'Every configured condition should reach the picker filter.'
    );
    Assert.areEqual(
      'eq',
      ((Map<String, Object>) conditions[0]).get('operator'),
      'An equality condition should map to eq.'
    );
    Assert.areEqual(
      'ne',
      ((Map<String, Object>) conditions[1]).get('operator'),
      'A not-equal condition should map to ne.'
    );
    Assert.areEqual(
      'in',
      ((Map<String, Object>) conditions[2]).get('operator'),
      'An IN condition should map to in.'
    );
  }

  private static BulkRecordUploadProjection projectionWithContext(
    BulkRecordUploadContextProjection contextProjection
  ) {
    return new BulkRecordUploadProjection(
      'Contact_Insert',
      'hash',
      'Contact',
      'INSERT',
      new List<String>(),
      'REQUIRE_PARENT',
      'Account',
      'AccountId',
      contextProjection,
      50,
      30,
      new List<BulkRecordUploadFieldProjection>{
        new BulkRecordUploadFieldProjection(
          'lastname',
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
        )
      }
    );
  }

  private static Integer activeBundleCount() {
    Integer count = 0;
    for (
      Bulk_Record_Upload_Bundle__mdt bundle : Bulk_Record_Upload_Bundle__mdt.getAll()
        .values()
    ) {
      if (bundle.IsActive__c == true) {
        count++;
      }
    }
    return count;
  }

  private static Integer compatibleBundleCount(String entityName) {
    Map<String, Bulk_Record_Upload_Process__mdt> processes = Bulk_Record_Upload_Process__mdt.getAll();
    Set<String> compatible = new Set<String>();
    for (
      Bulk_Record_Upload_Bundle_Process__mdt assignment : Bulk_Record_Upload_Bundle_Process__mdt.getAll()
        .values()
    ) {
      Bulk_Record_Upload_Process__mdt process = processes.get(
        assignment.ProcessDeveloperName__c
      );
      if (assignment.IsActive__c != true || process?.IsActive__c != true) {
        continue;
      }
      String configuredEntity = String.isBlank(process.HostObjectApiName__c)
        ? process.ObjectApiName__c
        : process.HostObjectApiName__c;
      if (entityName.equalsIgnoreCase(configuredEntity)) {
        compatible.add(assignment.BundleDeveloperName__c);
      }
    }
    Integer count = 0;
    for (
      Bulk_Record_Upload_Bundle__mdt bundle : Bulk_Record_Upload_Bundle__mdt.getAll()
        .values()
    ) {
      if (
        bundle.IsActive__c == true && compatible.contains(bundle.DeveloperName)
      ) {
        count++;
      }
    }
    return count;
  }
}
