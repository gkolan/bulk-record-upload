/**
 * Verifies value-object invariants and defensive collection copies.
 */
@IsTest
private class BulkRecordUploadContractsTest {
  @IsTest
  static void projection_ValidInput_PreservesBoundedContract() {
    BulkRecordUploadFieldProjection field = createField(1);

    Test.startTest();
    BulkRecordUploadProjection projection = new BulkRecordUploadProjection(
      'CONTACT_INSERT',
      'hash-1',
      'Contact',
      'INSERT',
      new List<String>(),
      100,
      90,
      new List<BulkRecordUploadFieldProjection>{ field }
    );
    Test.stopTest();

    Assert.areEqual(
      1,
      projection.getFields().size(),
      'Projection should contain one configured field.'
    );
    Assert.areEqual(
      100,
      projection.batchSize,
      'Projection should preserve the approved batch size.'
    );
    Assert.areEqual(
      90,
      projection.retentionDays,
      'Projection should preserve retention days.'
    );
  }

  @IsTest
  static void projection_BatchBelowMinimum_ThrowsDomainException() {
    Test.startTest();
    try {
      new BulkRecordUploadProjection(
        'CONTACT_INSERT',
        'hash-1',
        'Contact',
        'INSERT',
        new List<String>(),
        24,
        90,
        new List<BulkRecordUploadFieldProjection>{ createField(1) }
      );
      Assert.fail('Expected an invalid batch size to fail.');
    } catch (BulkRecordUploadException exceptionValue) {
      Assert.isTrue(
        exceptionValue.getMessage().contains('between 25 and 200'),
        'Failure should explain the safe batch-size boundary.'
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void projection_MoreThanOneHundredFields_ThrowsDomainException() {
    List<BulkRecordUploadFieldProjection> fields = new List<BulkRecordUploadFieldProjection>();
    for (Integer sequence = 1; sequence <= 101; sequence++) {
      fields.add(createField(sequence));
    }

    Test.startTest();
    try {
      new BulkRecordUploadProjection(
        'CONTACT_INSERT',
        'hash-1',
        'Contact',
        'INSERT',
        new List<String>(),
        100,
        90,
        fields
      );
      Assert.fail('Expected an oversized projection to fail.');
    } catch (BulkRecordUploadException exceptionValue) {
      Assert.isTrue(
        exceptionValue.getMessage().contains('between 1 and 100'),
        'Failure should explain the compact projection boundary.'
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void row_ValidInput_ReturnsDefensiveValueCopy() {
    Map<String, String> originalValues = new Map<String, String>{
      'email' => 'person@example.test'
    };

    Test.startTest();
    BulkRecordUploadRow row = new BulkRecordUploadRow(2, originalValues);
    originalValues.put('email', 'changed@example.test');
    Map<String, String> returnedValues = row.getValuesByColumn();
    returnedValues.put('email', 'also-changed@example.test');
    Test.stopTest();

    Assert.areEqual(
      'person@example.test',
      row.getValuesByColumn().get('email'),
      'Callers must not mutate stored parsed values.'
    );
  }

  @IsTest
  static void row_HeaderRowNumber_ThrowsDomainException() {
    Test.startTest();
    try {
      new BulkRecordUploadRow(1, new Map<String, String>());
      Assert.fail('Expected the header row number to fail.');
    } catch (BulkRecordUploadException exceptionValue) {
      Assert.isTrue(
        exceptionValue.getMessage().contains('at least 2'),
        'Failure should preserve the physical-row contract.'
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void rowResult_FailureWithoutCode_ThrowsDomainException() {
    Test.startTest();
    try {
      new BulkRecordUploadRowResult(2, false, null, null, 'Safe guidance');
      Assert.fail('Expected a failed result without a code to fail.');
    } catch (BulkRecordUploadException exceptionValue) {
      Assert.isTrue(
        exceptionValue.getMessage().contains('error code'),
        'Failure should require a stable safe error code.'
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void rowResult_Success_PreservesSafeOutcome() {
    Test.startTest();
    BulkRecordUploadRowResult result = new BulkRecordUploadRowResult(
      2,
      true,
      UserInfo.getUserId(),
      null,
      null
    );
    Test.stopTest();

    Assert.isTrue(
      result.isSuccess,
      'Result should preserve successful status.'
    );
    Assert.areEqual(
      2,
      result.rowNumber,
      'Result should preserve physical row correlation.'
    );
    Assert.areEqual(
      UserInfo.getUserId(),
      result.recordId,
      'Result should preserve an authorized record Id.'
    );
    Assert.isNull(
      result.errorCode,
      'Successful results should not have an error code.'
    );
  }

  @IsTest
  static void rowResult_ValidFailure_TrimsSafeDetails() {
    Test.startTest();
    BulkRecordUploadRowResult result = new BulkRecordUploadRowResult(
      3,
      false,
      null,
      ' INVALID_VALUE ',
      ' Correct the configured value. '
    );
    Test.stopTest();

    Assert.isFalse(result.isSuccess, 'Result should preserve failed status.');
    Assert.areEqual(
      'INVALID_VALUE',
      result.errorCode,
      'Stable error code should be trimmed.'
    );
    Assert.areEqual(
      'Correct the configured value.',
      result.safeMessage,
      'Safe guidance should be trimmed without input values.'
    );
  }

  @IsTest
  static void runtimeContract_StableValuesAndLimits_AreDefensive() {
    Set<String> statuses = BulkRecordUploadRuntimeContract.uploadStatuses();
    statuses.clear();

    Test.startTest();
    Set<String> freshStatuses = BulkRecordUploadRuntimeContract.uploadStatuses();
    Map<String, Set<String>> transitions = BulkRecordUploadRuntimeContract.uploadTransitions();
    Test.stopTest();

    Assert.areEqual(
      6,
      freshStatuses.size(),
      'The stable upload status contract should expose six values.'
    );
    Assert.isTrue(
      freshStatuses.contains(
        BulkRecordUploadRuntimeContract.STATUS_COMPLETED_WITH_ERRORS
      ),
      'The partial-success terminal status should remain stable.'
    );
    Assert.isTrue(
      transitions
        .get(BulkRecordUploadRuntimeContract.STATUS_PROCESSING)
        .contains(BulkRecordUploadRuntimeContract.STATUS_FAILED),
      'Processing should permit a visible fatal outcome.'
    );
    Assert.areEqual(
      5000,
      BulkRecordUploadRuntimeContract.MAX_CSV_ROWS,
      'The published CSV row ceiling should be code-owned.'
    );
    Assert.areEqual(
      200,
      BulkRecordUploadRuntimeContract.MAX_CHUNK_ROWS,
      'The persistence transaction ceiling should be code-owned.'
    );
  }

  private static BulkRecordUploadFieldProjection createField(Integer sequence) {
    return new BulkRecordUploadFieldProjection(
      'email_' + sequence,
      'Email ' + sequence,
      'Email',
      'EMAIL',
      'REPLACE',
      sequence,
      true,
      false,
      false,
      true,
      true,
      true
    );
  }
}
