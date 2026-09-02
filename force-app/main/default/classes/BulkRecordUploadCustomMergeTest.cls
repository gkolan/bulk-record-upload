@IsTest
private class BulkRecordUploadCustomMergeTest {
  @IsTest
  static void customStrategy_DispatchesToRegisteredClass() {
    BulkRecordUploadFieldProjection field = customField(
      'BulkRecordUploadLongerTextStrategy'
    );

    Assert.areEqual(
      'Existing Longer',
      new BulkRecordUploadFieldMergePolicy()
        .applyPolicy(field, 'Short', 'Existing Longer', null)
    );
  }

  @IsTest
  static void unregisteredStrategy_ThrowsSafeException() {
    BulkRecordUploadFieldProjection field = customField('NotARealClass');

    try {
      new BulkRecordUploadFieldMergePolicy()
        .applyPolicy(field, 'Existing', 'Incoming', null);
      Assert.fail('Expected an unregistered custom strategy exception.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(error.getMessage().contains('is not registered'));
    }
  }

  @IsTest
  static void registry_RejectsClassWithoutRequiredInterface() {
    BulkRecordUploadMergeStrategyRegistry registry = new BulkRecordUploadMergeStrategyRegistry();
    Assert.isInstanceOfType(
      registry.resolve('BulkRecordUploadLongerTextStrategy'),
      BulkRecordUploadFieldMergeStrategy.class
    );

    try {
      registry.resolve('BulkRecordUploadFieldConfig');
      Assert.fail('Expected a non-implementing class to be rejected.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(error.getMessage().contains('is not registered'));
    }
  }

  private static BulkRecordUploadFieldProjection customField(String className) {
    return new BulkRecordUploadFieldProjection(
      'description',
      'Description',
      'Description',
      'TEXTAREA',
      'CUSTOM',
      'IGNORE',
      'SPACE',
      null,
      'SKIP',
      'REJECT',
      null,
      false,
      'NONE',
      new Set<String>(),
      className,
      null,
      null,
      null,
      null,
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
