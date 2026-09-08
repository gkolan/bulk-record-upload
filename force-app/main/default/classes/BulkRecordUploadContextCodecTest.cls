/**
 * Covers record-context literal conversion for SOQL binds and the Lightning
 * record picker, including every supported primitive type and rejection paths.
 */
@IsTest
private class BulkRecordUploadContextCodecTest {
  @IsTest
  static void supports_AcceptsBindableTypesAndRejectsOthers() {
    for (
      String typeName : new List<String>{
        'STRING',
        'textarea',
        'EMAIL',
        'PHONE',
        'URL',
        'PICKLIST',
        'COMBOBOX',
        'DOUBLE',
        'CURRENCY',
        'PERCENT',
        'BOOLEAN',
        'INTEGER',
        'LONG',
        'DATE',
        'DATETIME',
        'TIME',
        'ID',
        'REFERENCE'
      }
    ) {
      Assert.isTrue(
        BulkRecordUploadContextValueCodec.supports(typeName),
        typeName + ' should be bindable.'
      );
    }

    Assert.isFalse(
      BulkRecordUploadContextValueCodec.supports('BASE64'),
      'An unsupported type should not be bindable.'
    );
    Assert.isFalse(
      BulkRecordUploadContextValueCodec.supports(null),
      'A blank type should not be bindable.'
    );
  }

  @IsTest
  static void scalar_ConvertsEverySupportedPrimitive() {
    Assert.areEqual(
      'Retail',
      BulkRecordUploadContextValueCodec.scalar(' Retail ', 'STRING'),
      'Text values should be trimmed.'
    );
    Assert.areEqual(
      true,
      BulkRecordUploadContextValueCodec.scalar('True', 'BOOLEAN'),
      'Boolean parsing should ignore case.'
    );
    Assert.areEqual(
      false,
      BulkRecordUploadContextValueCodec.scalar('false', 'BOOLEAN'),
      'Boolean false should convert.'
    );
    Assert.areEqual(
      42,
      BulkRecordUploadContextValueCodec.scalar('42', 'INTEGER'),
      'Integer values should convert.'
    );
    Assert.areEqual(
      9000000000L,
      BulkRecordUploadContextValueCodec.scalar('9000000000', 'LONG'),
      'Long values should convert.'
    );
    Assert.areEqual(
      12.5,
      BulkRecordUploadContextValueCodec.scalar('12.5', 'CURRENCY'),
      'Decimal values should convert.'
    );
    Assert.areEqual(
      Date.newInstance(2026, 3, 4),
      BulkRecordUploadContextValueCodec.scalar('2026-03-04', 'DATE'),
      'Date values should convert.'
    );
    Assert.areEqual(
      Time.newInstance(13, 45, 30, 0),
      BulkRecordUploadContextValueCodec.scalar('13:45:30', 'TIME'),
      'Time values should convert.'
    );
    Assert.areEqual(
      Time.newInstance(13, 45, 30, 250),
      BulkRecordUploadContextValueCodec.scalar('13:45:30.250Z', 'TIME'),
      'Time values should accept milliseconds and a trailing zone marker.'
    );
    Assert.isInstanceOfType(
      BulkRecordUploadContextValueCodec.scalar(
        '2026-03-04T05:06:07Z',
        'DATETIME'
      ),
      Datetime.class,
      'Date/time values should convert.'
    );
    Assert.areEqual(
      UserInfo.getUserId(),
      BulkRecordUploadContextValueCodec.scalar(
        UserInfo.getUserId(),
        'REFERENCE'
      ),
      'Reference values should convert to an id.'
    );
  }

  @IsTest
  static void scalar_RejectsBlankUnsupportedAndMalformedValues() {
    assertRejected(null, 'STRING', 'a null value');
    assertRejected('  ', 'STRING', 'a blank value');
    assertRejected('anything', 'BASE64', 'an unsupported type');
    assertRejected('maybe', 'BOOLEAN', 'a non-boolean literal');
    assertRejected('not-a-number', 'INTEGER', 'a non-numeric literal');
    assertRejected('not-a-date', 'DATE', 'a malformed date');
    assertRejected('13:45', 'TIME', 'a time without seconds');
    assertRejected('1:2:3:4:5', 'TIME', 'a time with too many parts');
    assertRejected('not-an-id', 'ID', 'a malformed id');
  }

  @IsTest
  static void collection_BuildsHomogeneousSetsPerType() {
    Assert.isInstanceOfType(
      BulkRecordUploadContextValueCodec.collection(
        new List<String>{ 'Retail', 'Banking' },
        'PICKLIST'
      ),
      Set<String>.class,
      'Text collections should bind as a string set.'
    );
    Assert.isInstanceOfType(
      BulkRecordUploadContextValueCodec.collection(
        new List<String>{ 'true', 'false' },
        'BOOLEAN'
      ),
      Set<Boolean>.class,
      'Boolean collections should bind as a boolean set.'
    );
    Assert.isInstanceOfType(
      BulkRecordUploadContextValueCodec.collection(
        new List<String>{ '1', '2' },
        'INTEGER'
      ),
      Set<Integer>.class,
      'Integer collections should bind as an integer set.'
    );
    Assert.isInstanceOfType(
      BulkRecordUploadContextValueCodec.collection(
        new List<String>{ '9000000000' },
        'LONG'
      ),
      Set<Long>.class,
      'Long collections should bind as a long set.'
    );
    Assert.isInstanceOfType(
      BulkRecordUploadContextValueCodec.collection(
        new List<String>{ '1.5' },
        'PERCENT'
      ),
      Set<Decimal>.class,
      'Decimal collections should bind as a decimal set.'
    );
    Assert.isInstanceOfType(
      BulkRecordUploadContextValueCodec.collection(
        new List<String>{ '2026-03-04' },
        'DATE'
      ),
      Set<Date>.class,
      'Date collections should bind as a date set.'
    );
    Assert.isInstanceOfType(
      BulkRecordUploadContextValueCodec.collection(
        new List<String>{ '2026-03-04T05:06:07Z' },
        'DATETIME'
      ),
      Set<Datetime>.class,
      'Date/time collections should bind as a date/time set.'
    );
    Assert.isInstanceOfType(
      BulkRecordUploadContextValueCodec.collection(
        new List<String>{ '13:45:30' },
        'TIME'
      ),
      Set<Time>.class,
      'Time collections should bind as a time set.'
    );
    Assert.isInstanceOfType(
      BulkRecordUploadContextValueCodec.collection(
        new List<String>{ UserInfo.getUserId() },
        'ID'
      ),
      Set<Id>.class,
      'Id collections should bind as an id set.'
    );
  }

  @IsTest
  static void collection_RejectsEmptyAndUnsupportedInput() {
    try {
      BulkRecordUploadContextValueCodec.collection(null, 'STRING');
      Assert.fail('Expected a null collection to be rejected.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(
        error.getMessage().contains('invalid'),
        'A null collection should report an invalid value.'
      );
    }

    try {
      BulkRecordUploadContextValueCodec.collection(
        new List<String>(),
        'STRING'
      );
      Assert.fail('Expected an empty collection to be rejected.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(
        error.getMessage().contains('invalid'),
        'An empty collection should report an invalid value.'
      );
    }

    try {
      BulkRecordUploadContextValueCodec.collection(
        new List<String>{ 'x' },
        'BASE64'
      );
      Assert.fail('Expected an unsupported collection type to be rejected.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(
        error.getMessage().contains('invalid'),
        'An unsupported collection type should report an invalid value.'
      );
    }
  }

  @IsTest
  static void pickerValue_ShapesScalarsAndCollectionsForRecordPicker() {
    Assert.areEqual(
      'Retail',
      BulkRecordUploadContextValueCodec.pickerValue(
        new List<String>{ 'Retail' },
        'STRING',
        false
      ),
      'A text scalar should pass through as text.'
    );
    Assert.areEqual(
      'true',
      BulkRecordUploadContextValueCodec.pickerValue(
        new List<String>{ 'TRUE' },
        'BOOLEAN',
        false
      ),
      'A boolean scalar should be lowercased for the picker.'
    );

    Object dateValue = BulkRecordUploadContextValueCodec.pickerValue(
      new List<String>{ '2026-03-04' },
      'DATE',
      false
    );
    // Date.valueOf(String) returns a Datetime-backed value, so String.valueOf
    // appends a zero time component. This asserts current behavior; see the
    // DATE picker-value note in the record-context filter documentation.
    Assert.areEqual(
      '2026-03-04 00:00:00',
      ((Map<String, Object>) dateValue).get('value'),
      'A date should be wrapped in the picker value shape.'
    );

    Object datetimeValue = BulkRecordUploadContextValueCodec.pickerValue(
      new List<String>{ '2026-03-04T05:06:07Z' },
      'DATETIME',
      false
    );
    Assert.areEqual(
      '2026-03-04T05:06:07.000Z',
      ((Map<String, Object>) datetimeValue).get('value'),
      'A date/time should be formatted in GMT for the picker.'
    );

    Object timeValue = BulkRecordUploadContextValueCodec.pickerValue(
      new List<String>{ '13:45:30' },
      'TIME',
      false
    );
    Assert.isTrue(
      ((String) ((Map<String, Object>) timeValue).get('value')).endsWith('Z'),
      'A time should carry the picker zone marker.'
    );

    Object collectionValue = BulkRecordUploadContextValueCodec.pickerValue(
      new List<String>{ 'Retail', 'Banking' },
      'PICKLIST',
      true
    );
    Assert.areEqual(
      2,
      ((List<Object>) collectionValue).size(),
      'An IN filter should produce one picker value per literal.'
    );
  }

  @IsTest
  static void filterCondition_BindsAndShapesConfiguredConditions() {
    BulkRecordUploadContextFilterCondition equals = new BulkRecordUploadContextFilterCondition(
      'Industry',
      '=',
      new List<String>{ 'Retail' }
    );
    BulkRecordUploadContextFilterCondition inList = new BulkRecordUploadContextFilterCondition(
      'Industry',
      'IN',
      new List<String>{ 'Retail', 'Banking' },
      'PICKLIST'
    );

    Assert.areEqual(
      'Retail',
      equals.bindValue(),
      'An equality condition should bind a scalar.'
    );
    Assert.areEqual(
      'STRING',
      equals.fieldType,
      'The short constructor should default to a text type.'
    );
    Assert.isInstanceOfType(
      inList.bindValue(),
      Set<String>.class,
      'An IN condition should bind a typed set.'
    );
    Assert.isInstanceOfType(
      inList.pickerValue(),
      List<Object>.class,
      'An IN condition should shape a picker collection.'
    );
  }

  private static void assertRejected(
    String rawValue,
    String fieldType,
    String description
  ) {
    try {
      BulkRecordUploadContextValueCodec.scalar(rawValue, fieldType);
      Assert.fail('Expected ' + description + ' to be rejected.');
    } catch (BulkRecordUploadException error) {
      Assert.isTrue(
        error.getMessage().contains('invalid'),
        'Rejecting ' + description + ' should report an invalid value.'
      );
    }
  }
}
