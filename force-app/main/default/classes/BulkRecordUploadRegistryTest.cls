@IsTest
private class BulkRecordUploadRegistryTest {
  @IsTest
  static void extensionRegistry_NoConfiguredExtensions_ResolvesEmptyOrderedList() {
    List<BulkRecordUploadExtension> resolved = new BulkRecordUploadExtensionRegistry()
      .resolve(new List<String>());

    Assert.isTrue(resolved.isEmpty());
  }

  @IsTest
  static void extensionRegistry_ShippedTrimExtension_ProvesExtensionBoundary() {
    List<BulkRecordUploadRow> rows = new List<BulkRecordUploadRow>{
      new BulkRecordUploadRow(
        2,
        new Map<String, String>{ 'name' => '  Acme  ' }
      )
    };
    BulkRecordUploadProjection projection = projection('INSERT', false, false);

    List<BulkRecordUploadExtension> resolved = new BulkRecordUploadExtensionRegistry()
      .resolve(new List<String>{ 'BulkRecordUploadTrimHandler' });
    List<BulkRecordUploadRow> actual = resolved[0].beforeMap(projection, rows);

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
  static void extensionRegistry_InjectionShapedClassName_IsRejected() {
    Boolean rejected = false;
    String message;

    Test.startTest();
    try {
      new BulkRecordUploadExtensionRegistry()
        .resolve(
          new List<String>{
            'BulkRecordUploadTrimHandler); System.abortJob(null); //'
          }
        );
    } catch (BulkRecordUploadException error) {
      rejected = true;
      message = error.getMessage();
    }
    Test.stopTest();

    Assert.isTrue(rejected, 'Injection-shaped class text must fail closed.');
    Assert.isTrue(
      message.contains('not registered'),
      'The rejection should use the bounded registration error.'
    );
  }

  @IsTest
  static void extensionRegistry_TooManyExtensions_IsRejected() {
    List<String> tooMany = new List<String>();
    for (
      Integer i = 0;
      i < BulkRecordUploadRuntimeContract.MAX_EXTENSIONS_PER_PROCESS + 1;
      i++
    ) {
      tooMany.add('BulkRecordUploadTrimHandler');
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
  static void operationStrategy_IncompatibleKeyFlags_AreRejected() {
    Map<String, BulkRecordUploadProjection> invalidByOperation = new Map<String, BulkRecordUploadProjection>{
      'INSERT' => projection('INSERT', true, false),
      'UPDATE' => projection('UPDATE', true, true),
      'UPSERT' => projection('UPSERT', true, true),
      'DELETE' => projection('DELETE', true, true)
    };

    Test.startTest();
    for (String operation : invalidByOperation.keySet()) {
      try {
        new BulkRecordUploadOperations()
          .resolve(operation)
          .validateProjection(invalidByOperation.get(operation));
        Assert.fail(operation + ' should reject an incompatible key flag.');
      } catch (BulkRecordUploadException error) {
        Assert.areEqual(
          'The configured key type is not supported for this operation.',
          error.getMessage(),
          operation + ' should fail with the bounded configuration error.'
        );
      }
    }
    Test.stopTest();
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

  private static BulkRecordUploadProjection projection(
    String operation,
    Boolean matchKey,
    Boolean upsertKey
  ) {
    BulkRecordUploadFieldProjection field = new BulkRecordUploadFieldProjection(
      'name',
      'Name',
      'Name',
      'STRING',
      'REPLACE',
      'IGNORE',
      'SPACE',
      null,
      'SKIP',
      'REJECT',
      null,
      true,
      'NONE',
      new Set<String>(),
      null,
      null,
      null,
      null,
      null,
      null,
      1,
      true,
      matchKey,
      upsertKey,
      true,
      true,
      true
    );
    return new BulkRecordUploadProjection(
      'TEST',
      'hash',
      'Account',
      operation,
      new List<String>(),
      100,
      30,
      new List<BulkRecordUploadFieldProjection>{ field }
    );
  }

  /** Test-only class that does not implement BulkRecordUploadExtension. */
  public class NotAnExtension {
  }
}
