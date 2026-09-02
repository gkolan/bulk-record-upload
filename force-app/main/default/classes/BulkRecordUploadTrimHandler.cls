/**
 * Shipped example extension that trims projected string values before
 * mapping, without performing DML. Registered by class name in
 * Bulk_Record_Upload_Extension__mdt; see docs/developer/custom-handler.md
 * for the worked example.
 */
public with sharing class BulkRecordUploadTrimHandler extends BulkRecordUploadExtensionAdapter {
  /** {@inheritDoc} */
  public override List<BulkRecordUploadRow> beforeMap(
    BulkRecordUploadProjection projection,
    List<BulkRecordUploadRow> rows
  ) {
    if (projection == null || rows == null) {
      throw new BulkRecordUploadException('Extension input is required.');
    }
    Set<String> trimmedColumns = new Set<String>();
    for (BulkRecordUploadFieldProjection field : projection.getFields()) {
      if (field.trimValue && String.isBlank(field.sourceTemplate)) {
        trimmedColumns.add(field.columnKey);
      }
    }
    List<BulkRecordUploadRow> transformed = new List<BulkRecordUploadRow>();
    for (BulkRecordUploadRow row : rows) {
      Map<String, String> values = row.getValuesByColumn();
      for (String key : trimmedColumns) {
        if (values.get(key) != null) {
          values.put(key, values.get(key).trim());
        }
      }
      transformed.add(new BulkRecordUploadRow(row.rowNumber, values));
    }
    return transformed;
  }
}
