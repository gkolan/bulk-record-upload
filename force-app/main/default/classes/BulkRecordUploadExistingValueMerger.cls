/** Loads only configured existing values and applies configured merge policies before persistence. */
public with sharing class BulkRecordUploadExistingValueMerger {
  /** Merges existing values for bounded update and upsert rows using one user-mode query. */
  public void mergeExistingValues(
    BulkRecordUploadProjection projection,
    List<BulkRecordUploadMappedRow> rows
  ) {
    Set<Id> recordIds = new Set<Id>();
    for (BulkRecordUploadMappedRow row : rows) {
      if (row.record.Id != null) {
        recordIds.add(row.record.Id);
      }
    }
    if (recordIds.isEmpty()) {
      return;
    }
    List<String> fieldNames = new List<String>{ 'Id' };
    for (BulkRecordUploadFieldProjection field : projection.getFields()) {
      fieldNames.add(field.fieldApiName);
    }
    List<SObject> existingRecords = Database.queryWithBinds(
      'SELECT ' +
        String.join(fieldNames, ',') +
        ' FROM ' +
        projection.objectApiName +
        ' WHERE Id IN :recordIds',
      new Map<String, Object>{ 'recordIds' => recordIds },
      AccessLevel.USER_MODE
    );
    Map<Id, SObject> existingById = new Map<Id, SObject>(existingRecords);
    Map<String, Schema.SObjectField> schemaFields = Schema.getGlobalDescribe()
      .get(projection.objectApiName)
      .getDescribe()
      .fields.getMap();
    Map<String, Integer> lengthsByField = new Map<String, Integer>();
    for (BulkRecordUploadFieldProjection field : projection.getFields()) {
      lengthsByField.put(
        field.fieldApiName,
        schemaFields.get(field.fieldApiName).getDescribe().getLength()
      );
    }
    BulkRecordUploadFieldMergePolicy policy = new BulkRecordUploadFieldMergePolicy();
    for (BulkRecordUploadMappedRow row : rows) {
      if (!existingById.containsKey(row.record.Id)) {
        continue;
      }
      SObject existingRecord = existingById.get(row.record.Id);
      for (BulkRecordUploadFieldProjection field : projection.getFields()) {
        if (
          !row.record.getPopulatedFieldsAsMap().containsKey(field.fieldApiName)
        ) {
          continue;
        }
        row.record.put(
          field.fieldApiName,
          policy.applyPolicy(
            field,
            existingRecord.get(field.fieldApiName),
            row.record.get(field.fieldApiName),
            lengthsByField.get(field.fieldApiName)
          )
        );
      }
    }
  }
}
