/**
 * Verifies bounded CSV parsing, physical row correlation, and structural projection validation.
 */
@IsTest
private class BulkRecordUploadCsvReaderTest {
  @IsTest
  static void parse_NulCharacter_IsRejected() {
    try {
      new BulkRecordUploadCsvReader()
        .parse('Name\nAcme' + String.fromCharArray(new List<Integer>{ 0 }));
      Assert.fail('Expected NUL rejection.');
    } catch (BulkRecordUploadException error) {
      Assert.areEqual(
        'The CSV file contains a prohibited NUL character.',
        error.getMessage()
      );
    }
  }

  @IsTest
  static void parse_QuotedCommaAndNewline_PreservesValuesAndPhysicalRows() {
    String csvText =
      'last_name,email,notes\r\n' +
      'Smith,smith@example.test,"hello, world"\r\n' +
      'Jones,jones@example.test,"line one\nline two"\r\n' +
      'Lee,lee@example.test,done';

    Test.startTest();
    BulkRecordUploadParsedCsvV1 parsed = new BulkRecordUploadCsvReader()
      .parse(csvText);
    Test.stopTest();

    Assert.areEqual(
      3,
      parsed.rows.size(),
      'Reader should return three data records.'
    );
    Assert.areEqual(
      'hello, world',
      parsed.rows[0].valuesByColumn.get('notes'),
      'Quoted comma should remain data.'
    );
    Assert.areEqual(
      'line one\nline two',
      parsed.rows[1].valuesByColumn.get('notes'),
      'Quoted newline should remain data.'
    );
    Assert.areEqual(
      5,
      parsed.rows[2].rowNumber,
      'Physical row should account for the embedded newline.'
    );
  }

  @IsTest
  static void parse_EscapedQuote_ReturnsLiteralQuote() {
    Test.startTest();
    BulkRecordUploadParsedCsvV1 parsed = new BulkRecordUploadCsvReader()
      .parse('last_name,notes\nSmith,"said ""hello"""');
    Test.stopTest();

    Assert.areEqual(
      'said "hello"',
      parsed.rows[0].valuesByColumn.get('notes'),
      'Double quote should unescape once.'
    );
  }

  @IsTest
  static void parse_Utf8Bom_NormalizesFirstHeader() {
    String bom = String.fromCharArray(new List<Integer>{ 65279 });

    Test.startTest();
    BulkRecordUploadParsedCsvV1 parsed = new BulkRecordUploadCsvReader()
      .parse(bom + 'Name\nAcme');
    Test.stopTest();

    Assert.areEqual(
      'name',
      parsed.headers[0],
      'BOM should not become part of the first header.'
    );
    Assert.areEqual(
      'Acme',
      parsed.rows[0].valuesByColumn.get('name'),
      'The first column should remain correlated.'
    );
  }

  @IsTest
  static void parse_FiveThousandRows_ReachesDocumentedRowCeiling() {
    List<String> lines = new List<String>{ 'name' };
    for (
      Integer indexValue = 0;
      indexValue < BulkRecordUploadRuntimeContract.MAX_CSV_ROWS;
      indexValue++
    ) {
      lines.add('row' + indexValue);
    }

    Test.startTest();
    BulkRecordUploadParsedCsvV1 parsed = new BulkRecordUploadCsvReader()
      .parse(String.join(lines, '\n'));
    Test.stopTest();

    Assert.areEqual(
      BulkRecordUploadRuntimeContract.MAX_CSV_ROWS,
      parsed.rows.size(),
      'The documented row ceiling should parse successfully.'
    );
    Assert.areEqual(
      5001,
      parsed.rows[4999].rowNumber,
      'Physical row correlation should survive the ceiling case.'
    );
  }

  @IsTest
  static void parse_UnterminatedQuote_ThrowsSafeException() {
    assertParseFailure(
      'last_name,notes\nSmith,"unfinished',
      'The CSV contains an unterminated quoted value.'
    );
  }

  @IsTest
  static void parse_DuplicateNormalizedHeader_ThrowsSafeException() {
    assertParseFailure(
      'Email, email \na@example.test,b@example.test',
      'CSV headers must be unique.'
    );
  }

  @IsTest
  static void parse_MismatchedColumnCount_ThrowsSafeException() {
    assertParseFailure(
      'last_name,email\nSmith',
      'A CSV row has a different column count than the header.'
    );
  }

  @IsTest
  static void validate_RequiredConfiguredHeaders_AcceptsValidRows() {
    BulkRecordUploadParsedCsvV1 parsed = new BulkRecordUploadCsvReader()
      .parse('last_name,email\nSmith,smith@example.test');

    Test.startTest();
    new BulkRecordUploadRequestValidator().validate(parsed, createProjection());
    Test.stopTest();

    Assert.areEqual(
      1,
      parsed.rows.size(),
      'Validation should not mutate parsed rows.'
    );
  }

  @IsTest
  static void validate_UnknownHeader_ThrowsSafeException() {
    BulkRecordUploadParsedCsvV1 parsed = new BulkRecordUploadCsvReader()
      .parse('last_name,unknown\nSmith,value');
    assertValidationFailure(
      parsed,
      'The CSV contains a column that is not configured.'
    );
  }

  @IsTest
  static void validate_MissingRequiredHeader_ThrowsSafeException() {
    BulkRecordUploadParsedCsvV1 parsed = new BulkRecordUploadCsvReader()
      .parse('email\nsmith@example.test');
    assertValidationFailure(
      parsed,
      'The CSV is missing a required configured column.'
    );
  }

  @IsTest
  static void validate_HeaderOnly_ThrowsSafeException() {
    BulkRecordUploadParsedCsvV1 parsed = new BulkRecordUploadCsvReader()
      .parse('last_name,email');
    assertValidationFailure(
      parsed,
      'The CSV must contain at least one data row.'
    );
  }

  private static void assertParseFailure(
    String csvText,
    String expectedMessage
  ) {
    Test.startTest();
    try {
      new BulkRecordUploadCsvReader().parse(csvText);
      Assert.fail('Expected malformed CSV to fail.');
    } catch (BulkRecordUploadException exceptionValue) {
      Assert.areEqual(
        expectedMessage,
        exceptionValue.getMessage(),
        'Parser should return safe structural guidance.'
      );
    }
    Test.stopTest();
  }

  private static void assertValidationFailure(
    BulkRecordUploadParsedCsvV1 parsed,
    String expectedMessage
  ) {
    Test.startTest();
    try {
      new BulkRecordUploadRequestValidator()
        .validate(parsed, createProjection());
      Assert.fail('Expected invalid headers to fail.');
    } catch (BulkRecordUploadException exceptionValue) {
      Assert.areEqual(
        expectedMessage,
        exceptionValue.getMessage(),
        'Validator should return safe header guidance.'
      );
    }
    Test.stopTest();
  }

  private static BulkRecordUploadProjectionV1 createProjection() {
    return new BulkRecordUploadProjectionV1(
      'CONTACT_INSERT',
      'hash',
      'Contact',
      'INSERT',
      'STANDARD_V1',
      100,
      90,
      new List<BulkRecordUploadFieldProjectionV1>{
        createField('last_name', 'LastName', 1, true),
        createField('email', 'Email', 2, false)
      }
    );
  }

  private static BulkRecordUploadFieldProjectionV1 createField(
    String columnKey,
    String fieldApiName,
    Integer sequence,
    Boolean isRequired
  ) {
    return new BulkRecordUploadFieldProjectionV1(
      columnKey,
      columnKey,
      fieldApiName,
      'STRING',
      'REPLACE',
      sequence,
      isRequired,
      false,
      false,
      true,
      true,
      true
    );
  }
}
