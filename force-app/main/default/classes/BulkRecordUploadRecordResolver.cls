/** Resolves update/delete record Ids in one user-mode query using a trusted projected match field. */
public with sharing class BulkRecordUploadRecordResolver {
  /** Assigns matching record Ids to mapped rows while preserving rows with no match for safe partial failure. */
  public void assignRecordIds(
    BulkRecordUploadProjection projection,
    List<BulkRecordUploadMappedRow> rows
  ) {
    BulkRecordUploadFieldProjection matchField = findMatchField(projection);
    if (matchField == null) {
      return;
    }
    Schema.DescribeFieldResult matchDescribe = Schema.getGlobalDescribe()
      .get(projection.objectApiName)
      .getDescribe()
      .fields.getMap()
      .get(matchField.fieldApiName)
      .getDescribe();
    String matchFieldType = String.valueOf(matchDescribe.getType());
    Set<String> matchValues = new Set<String>();
    for (BulkRecordUploadMappedRow row : rows) {
      if (!row.isValid()) {
        continue;
      }
      Object value = row.record.get(matchField.fieldApiName);
      if (value != null) {
        matchValues.add(String.valueOf(value));
      }
    }
    if (matchValues.isEmpty()) {
      for (BulkRecordUploadMappedRow row : rows) {
        if (row.isValid()) {
          row.markFailed(
            BulkRecordUploadRuntimeContract.REASON_MATCH_ERROR,
            'The row is missing its configured match key.'
          );
        }
      }
      return;
    }
    String query =
      'SELECT Id,' +
      matchField.fieldApiName +
      ' FROM ' +
      projection.objectApiName +
      ' WHERE ' +
      matchField.fieldApiName +
      ' IN :matchValues';
    List<SObject> matches = Database.queryWithBinds(
      query,
      new Map<String, Object>{ 'matchValues' => matchValues },
      AccessLevel.USER_MODE
    );
    Map<String, Id> idsByCanonicalValue = new Map<String, Id>();
    Set<String> ambiguous = new Set<String>();
    for (SObject match : matches) {
      String key = BulkRecordUploadLookupResolver.canonicalValue(
        match.get(matchField.fieldApiName),
        matchFieldType
      );
      if (idsByCanonicalValue.containsKey(key)) {
        ambiguous.add(key);
      } else {
        idsByCanonicalValue.put(key, (Id) match.get('Id'));
      }
    }
    for (String ambiguousKey : ambiguous) {
      idsByCanonicalValue.remove(ambiguousKey);
    }
    for (BulkRecordUploadMappedRow row : rows) {
      if (!row.isValid()) {
        continue;
      }
      Object rawValue = row.record.get(matchField.fieldApiName);
      if (rawValue == null) {
        row.markFailed(
          BulkRecordUploadRuntimeContract.REASON_MATCH_ERROR,
          'The row is missing its configured match key.'
        );
        continue;
      }
      String value = BulkRecordUploadLookupResolver.canonicalValue(
        rawValue,
        matchFieldType
      );
      if (ambiguous.contains(value)) {
        row.markFailed(
          BulkRecordUploadRuntimeContract.REASON_MATCH_ERROR,
          'The configured match key resolves to more than one record.'
        );
      } else if (idsByCanonicalValue.containsKey(value)) {
        row.record.put('Id', idsByCanonicalValue.get(value));
      } else if (projection.operation != 'UPSERT') {
        row.markFailed(
          BulkRecordUploadRuntimeContract.REASON_MATCH_ERROR,
          'The configured match key did not resolve to a record.'
        );
      }
    }
  }

  private static BulkRecordUploadFieldProjection findMatchField(
    BulkRecordUploadProjection projection
  ) {
    for (BulkRecordUploadFieldProjection field : projection.getFields()) {
      if (field.isMatchKey) {
        return field;
      }
    }
    return null;
  }
}
