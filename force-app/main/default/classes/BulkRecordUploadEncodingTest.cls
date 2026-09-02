@IsTest
private class BulkRecordUploadEncodingTest {
  @IsTest
  static void submit_InvalidBase64_IsRejectedSafely() {
    BulkRecordUploadSubmitRequest request = request('Name\nAcme\n');
    request.contentBase64 = '%%%invalid%%%';

    try {
      new BulkRecordUploadRequestService().submit(request);
      Assert.fail('Expected file-encoding exception.');
    } catch (BulkRecordUploadException error) {
      Assert.areEqual(
        'The uploaded file encoding is invalid.',
        error.getMessage()
      );
    }
  }

  @IsTest
  static void submit_InvalidUtf8Bytes_IsRejectedBeforeParsing() {
    BulkRecordUploadSubmitRequest request = request('Name\nAcme\n');
    // Base64 for "Name\r\n", the invalid byte 0xFF, then "Z\r\n".
    request.contentBase64 = 'TmFtZQ0K/1oNCg==';

    Test.startTest();
    try {
      new BulkRecordUploadRequestService().submit(request);
      Assert.fail('A non-UTF-8 byte sequence should be rejected.');
    } catch (BulkRecordUploadException error) {
      Assert.areEqual(
        'The CSV file must use UTF-8 encoding.',
        error.getMessage(),
        'Invalid UTF-8 bytes must return a clear encoding error.'
      );
    }
    Test.stopTest();
  }

  private static BulkRecordUploadSubmitRequest request(String csv) {
    BulkRecordUploadSubmitRequest requestValue = new BulkRecordUploadSubmitRequest();
    requestValue.processKey = 'REQUEST';
    requestValue.fileName = 'request.csv';
    requestValue.contentBase64 = EncodingUtil.base64Encode(Blob.valueOf(csv));
    requestValue.idempotencyKey = EncodingUtil.convertToHex(
      Crypto.generateDigest('SHA-256', Blob.valueOf('encoding-test-key'))
    );
    return requestValue;
  }
}
