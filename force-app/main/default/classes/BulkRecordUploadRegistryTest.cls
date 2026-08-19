@IsTest
private class BulkRecordUploadRegistryTest {
  @IsTest
  static void handlerRegistry_StandardHandler_PreservesRows() {
    BulkRecordUploadProjectionV1 projection = projection(
      'INSERT',
      false,
      false
    );
    List<BulkRecordUploadRowV1> rows = new List<BulkRecordUploadRowV1>{
      new BulkRecordUploadRowV1(2, new Map<String, String>{ 'name' => 'Acme' })
    };

    List<BulkRecordUploadRowV1> actual = new BulkRecordUploadHandlerRegistry()
      .resolve('STANDARD_V1')
      .handle(projection, rows);

    Assert.areEqual('Acme', actual[0].getValuesByColumn().get('name'));
    Assert.isTrue(BulkRecordUploadHandlerRegistry.isRegistered('STANDARD_V1'));
  }

  @IsTest
  static void handlerRegistry_CustomTrimHandler_ProvesExtensionBoundary() {
    BulkRecordUploadProjectionV1 projection = projection(
      'INSERT',
      false,
      false
    );
    List<BulkRecordUploadRowV1> rows = new List<BulkRecordUploadRowV1>{
      new BulkRecordUploadRowV1(
        2,
        new Map<String, String>{ 'name' => '  Acme  ' }
      )
    };

    List<BulkRecordUploadRowV1> actual = new BulkRecordUploadHandlerRegistry()
      .resolve('TRIM_TEXT_V1')
      .handle(projection, rows);

    Assert.areEqual('Acme', actual[0].getValuesByColumn().get('name'));
    Assert.areEqual('  Acme  ', rows[0].getValuesByColumn().get('name'));
  }

  @IsTest
  static void handlerRegistry_AdministratorClassName_IsRejected() {
    try {
      new BulkRecordUploadHandlerRegistry().resolve('System.String');
      Assert.fail('Expected an unregistered-handler exception.');
    } catch (BulkRecordUploadException error) {
      Assert.areEqual(
        'The configured handler is not registered.',
        error.getMessage()
      );
    }
  }

  @IsTest
  static void operationRegistry_AllSupportedOperations_Resolve() {
    BulkRecordUploadOperationRegistry registry = new BulkRecordUploadOperationRegistry();
    registry.resolve('insert')
      .validateProjection(projection('INSERT', false, false));
    registry.resolve('UPDATE')
      .validateProjection(projection('UPDATE', true, false));
    registry.resolve('UPSERT')
      .validateProjection(projection('UPSERT', false, true));
    registry.resolve('DELETE')
      .validateProjection(projection('DELETE', true, false));
  }

  @IsTest
  static void operationStrategy_MissingRequiredKey_IsRejected() {
    try {
      new BulkRecordUploadOperationRegistry()
        .resolve('UPDATE')
        .validateProjection(projection('UPDATE', false, false));
      Assert.fail('Expected a match-key exception.');
    } catch (BulkRecordUploadException error) {
      Assert.areEqual(
        'This operation requires exactly one match key.',
        error.getMessage()
      );
    }
  }

  @IsTest
  static void operationRegistry_UnknownOperation_IsRejected() {
    try {
      new BulkRecordUploadOperationRegistry().resolve('MERGE');
      Assert.fail('Expected an unsupported-operation exception.');
    } catch (BulkRecordUploadException error) {
      Assert.areEqual(
        'The configured operation is not supported.',
        error.getMessage()
      );
    }
  }

  @IsTest
  static void processorAndPostActionRegistries_ResolveOnlyTrustedKeys() {
    Assert.isNotNull(
      new BulkRecordUploadProcessorRegistry().resolve('STANDARD_DML_V1')
    );
    Assert.isTrue(
      BulkRecordUploadProcessorRegistry.isRegistered('STANDARD_DML_V1')
    );
    Assert.isNotNull(
      new BulkRecordUploadPostActionRegistry().resolve('NONE_V1')
    );
    Assert.isTrue(BulkRecordUploadPostActionRegistry.isRegistered('NONE_V1'));

    try {
      new BulkRecordUploadProcessorRegistry().resolve('System.String');
      Assert.fail('Expected an unregistered-processor exception.');
    } catch (BulkRecordUploadException error) {
      Assert.areEqual(
        'The configured custom processor is not registered.',
        error.getMessage()
      );
    }
    try {
      new BulkRecordUploadPostActionRegistry().resolve('System.String');
      Assert.fail('Expected an unregistered-action exception.');
    } catch (BulkRecordUploadException error) {
      Assert.areEqual(
        'The configured post-processing action is not registered.',
        error.getMessage()
      );
    }
  }

  private static BulkRecordUploadProjectionV1 projection(
    String operation,
    Boolean matchKey,
    Boolean upsertKey
  ) {
    BulkRecordUploadFieldProjectionV1 field = new BulkRecordUploadFieldProjectionV1(
      'name',
      'Name',
      'Name',
      'STRING',
      'REPLACE',
      1,
      true,
      matchKey,
      upsertKey,
      true,
      true,
      true
    );
    return new BulkRecordUploadProjectionV1(
      'TEST',
      'hash',
      'Account',
      operation,
      'STANDARD_V1',
      100,
      30,
      new List<BulkRecordUploadFieldProjectionV1>{ field }
    );
  }
}
