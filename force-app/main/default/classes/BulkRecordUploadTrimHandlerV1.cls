/**
 * Shipped example extension that trims projected string values before
 * mapping, without performing DML. Registered by class name in
 * Bulk_Record_Upload_Extension__mdt; see docs/developer/custom-handler.md
 * for the worked example.
 */
public with sharing class BulkRecordUploadTrimHandlerV1 extends BulkRecordUploadExtensionAdapterV1 {
  /** {@inheritDoc} */
  public override List<BulkRecordUploadRowV1> beforeMap(
    BulkRecordUploadProjectionV1 projection,
    List<BulkRecordUploadRowV1> rows
  ) {
    if (projection == null || rows == null) {
      throw new BulkRecordUploadException('Extension input is required.');
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
