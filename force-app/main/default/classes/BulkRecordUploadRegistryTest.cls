@IsTest
private class BulkRecordUploadRegistryTest {
  @IsTest
  static void extensionRegistry_NoConfiguredExtensions_ResolvesEmptyOrderedList() {
    List<BulkRecordUploadExtensionV1> resolved = new BulkRecordUploadExtensionRegistry()
      .resolve(new List<String>());

    Assert.isTrue(resolved.isEmpty());
  }

  @IsTest
  static void extensionRegistry_ShippedTrimExtension_ProvesExtensionBoundary() {
    List<BulkRecordUploadRowV1> rows = new List<BulkRecordUploadRowV1>{
      new BulkRecordUploadRowV1(
        2,
        new Map<String, String>{ 'name' => '  Acme  ' }
      )
    };
    BulkRecordUploadProjectionV1 projection = projection(
      'INSERT',
      false,
      false
    );

    List<BulkRecordUploadExtensionV1> resolved = new BulkRecordUploadExtensionRegistry()
      .resolve(new List<String>{ 'BulkRecordUploadTrimHandlerV1' });
    List<BulkRecordUploadRowV1> actual = resolved[0]
      .beforeMap(projection, rows);

    Assert.areEqual('Acme', actual[0].getValuesByColumn().get('name'));
    Assert.areEqual('  Acme  ', rows[0].getValuesByColumn().get('name'));
  }

  @IsTest
  static void extensionRegistry_UnresolvableClassName_IsRejected() {
    try {
      new BulkRecordUploadExtensionRegistry()
        .resolve(new List<String>{ 'System.String' });
      Assert.fail('Expected an unregistered-extension exception.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(
        error.getMessage().contains('is not registered'),
        'Safe error naming the class expected.'
      );
    }
  }

  @IsTest
  static void extensionRegistry_NonImplementingClassName_IsRejected() {
    try {
      new BulkRecordUploadExtensionRegistry()
        .resolve(
          new List<String>{ 'BulkRecordUploadRegistryTest.NotAnExtension' }
        );
      Assert.fail('Expected an unregistered-extension exception.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(
        error.getMessage().contains('is not registered'),
        'Safe error naming the class expected.'
      );
    }
  }

  @IsTest
  static void extensionRegistry_TooManyExtensions_IsRejected() {
    List<String> tooMany = new List<String>();
    for (
      Integer i = 0;
      i < BulkRecordUploadRuntimeContract.MAX_EXTENSIONS_PER_PROCESS + 1;
      i++
    ) {
      tooMany.add('BulkRecordUploadTrimHandlerV1');
    }
    try {
      new BulkRecordUploadExtensionRegistry().resolve(tooMany);
      Assert.fail('Expected a too-many-extensions exception.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(
        error.getMessage().contains('Too many extensions'),
        'Bounded-count error expected.'
      );
    }
  }

  @IsTest
  static void operations_AllSupportedOperations_Resolve() {
    BulkRecordUploadOperations registry = new BulkRecordUploadOperations();
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
      new BulkRecordUploadOperations()
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
  static void operations_UnknownOperation_IsRejected() {
    try {
      new BulkRecordUploadOperations().resolve('MERGE');
      Assert.fail('Expected an unsupported-operation exception.');
    } catch (BulkRecordUploadException error) {
      Assert.areEqual(
        'The configured operation is not supported.',
        error.getMessage()
      );
    }
  }

  @IsTest
  static void processors_ResolveOnlyTrustedKeys() {
    Assert.isNotNull(
      new BulkRecordUploadProcessors().resolve('STANDARD_DML_V1')
    );
    Assert.isTrue(BulkRecordUploadProcessors.isRegistered('STANDARD_DML_V1'));

    try {
      new BulkRecordUploadProcessors().resolve('System.String');
      Assert.fail('Expected an unregistered-processor exception.');
    } catch (BulkRecordUploadException error) {
      Assert.areEqual(
        'The configured custom processor is not registered.',
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
      new List<String>(),
      100,
      30,
      new List<BulkRecordUploadFieldProjectionV1>{ field }
    );
  }

  /** Test-only class that does not implement BulkRecordUploadExtensionV1. */
  public class NotAnExtension {
  }
}
