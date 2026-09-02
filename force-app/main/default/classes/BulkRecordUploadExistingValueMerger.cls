/** Loads only configured existing values and applies configured merge policies before persistence. */
public with sharing class BulkRecordUploadExistingValueMerger {
  /** Merges existing values for bounded update and upsert rows using one user-mode query. */
  public void mergeExistingValues(
    BulkRecordUploadProjection projection,
    List<BulkRecordUploadMappedRow> rows
  ) {
    Set<Id> recordIds = new Set<Id>();
    for (BulkRecordUploadMappedRow row : rows) {
      if (row.isValid() && row.record.Id != null) {
        recordIds.add(row.record.Id);
      }
    }
    if (recordIds.isEmpty()) {
      return;
    }
    List<String> fieldNames = new List<String>{ 'Id' };
    Set<String> mergeFieldNames = new Set<String>();
    for (BulkRecordUploadFieldProjection field : projection.getFields()) {
      if (field.existingValueAction != 'REPLACE') {
        fieldNames.add(field.fieldApiName);
        mergeFieldNames.add(field.fieldApiName);
      }
    }
    if (mergeFieldNames.isEmpty()) {
      return;
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
      Schema.SObjectField fieldToken = schemaFields.get(field.fieldApiName);
      if (fieldToken == null) {
        throw new BulkRecordUploadException(
          'A configured target field is unavailable.'
        );
      }
      lengthsByField.put(
        field.fieldApiName,
        fieldToken.getDescribe().getLength()
      );
    }
    BulkRecordUploadFieldMergePolicy policy = new BulkRecordUploadFieldMergePolicy();
    for (BulkRecordUploadMappedRow row : rows) {
      if (!row.isValid() || row.record.Id == null) {
        continue;
      }
      if (!existingById.containsKey(row.record.Id)) {
        row.markFailed(
          BulkRecordUploadRuntimeContract.REASON_MATCH_ERROR,
          'The matched record is unavailable for configured merge behavior.'
        );
        continue;
      }
      SObject existingRecord = existingById.get(row.record.Id);
      try {
        for (BulkRecordUploadFieldProjection field : projection.getFields()) {
          if (
            !mergeFieldNames.contains(field.fieldApiName) ||
            !row.record.getPopulatedFieldsAsMap()
              .containsKey(field.fieldApiName)
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
      } catch (BulkRecordUploadException error) {
        row.markFailed(
          BulkRecordUploadRuntimeContract.REASON_VALIDATION_ERROR,
          error.getMessage()
        );
      }
    }
  }
}
