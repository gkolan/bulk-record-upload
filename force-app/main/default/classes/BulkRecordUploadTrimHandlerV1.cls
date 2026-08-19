/** Example trusted extension that trims projected string values without performing DML. */
public with sharing class BulkRecordUploadTrimHandlerV1 implements BulkRecordUploadHandlerV1 {
  /** {@inheritDoc} */
  public List<BulkRecordUploadRowV1> handle(
    BulkRecordUploadProjectionV1 projection,
    List<BulkRecordUploadRowV1> rows
  ) {
    if (projection == null || rows == null) {
      throw new BulkRecordUploadException('Handler input is required.');
    }
    List<BulkRecordUploadRowV1> transformed = new List<BulkRecordUploadRowV1>();
    for (BulkRecordUploadRowV1 row : rows) {
      Map<String, String> values = row.getValuesByColumn();
      for (String key : values.keySet()) {
        if (values.get(key) != null) {
          values.put(key, values.get(key).trim());
        }
      }
      transformed.add(new BulkRecordUploadRowV1(row.rowNumber, values));
    }
    return transformed;
  }
}
