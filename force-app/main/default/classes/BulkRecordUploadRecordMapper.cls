/** Maps projected CSV rows to records using only Schema-approved object and field identifiers. */
public with sharing class BulkRecordUploadRecordMapper {
  private final BulkRecordUploadValueCoercer coercer = new BulkRecordUploadValueCoercer();

  /** Maps one bounded row collection without querying or persisting records. */
  public List<BulkRecordUploadMappedRowV1> mapRows(
    BulkRecordUploadProjectionV1 projection,
    List<BulkRecordUploadRowV1> rows
  ) {
    Schema.SObjectType objectType = Schema.getGlobalDescribe()
      .get(projection.objectApiName);
    if (objectType == null) {
      throw new BulkRecordUploadException(
        'The projected object is unavailable.'
      );
    }
    Map<String, Schema.SObjectField> schemaFields = objectType.getDescribe()
      .fields.getMap();
    List<BulkRecordUploadMappedRowV1> mapped = new List<BulkRecordUploadMappedRowV1>();
    for (BulkRecordUploadRowV1 row : rows) {
      SObject record = objectType.newSObject();
      Map<String, String> values = row.getValuesByColumn();
      for (BulkRecordUploadFieldProjectionV1 field : projection.getFields()) {
        if (
          !schemaFields.containsKey(field.fieldApiName) ||
          !values.containsKey(field.columnKey)
        ) {
          continue;
        }
        String rawValue = values.get(field.columnKey);
        if (String.isBlank(rawValue) && field.blankValueAction == 'IGNORE') {
          continue;
        }
        if (String.isBlank(rawValue) && field.blankValueAction == 'REJECT') {
          throw new BulkRecordUploadException(
            'A required configured value is blank.'
          );
        }
        Object incoming = String.isBlank(rawValue) &&
          field.blankValueAction == 'CLEAR'
          ? null
          : coercer.coerce(rawValue, field.fieldType);
        record.put(field.fieldApiName, incoming);
      }
      mapped.add(new BulkRecordUploadMappedRowV1(row.rowNumber, record));
    }
    return mapped;
  }
}
