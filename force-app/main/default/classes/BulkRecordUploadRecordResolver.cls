/** Resolves update/delete record Ids in one user-mode query using a trusted projected match field. */
public with sharing class BulkRecordUploadRecordResolver {
  /** Assigns matching record Ids to mapped rows while preserving rows with no match for safe partial failure. */
  public void assignRecordIds(
    BulkRecordUploadProjectionV1 projection,
    List<BulkRecordUploadMappedRowV1> rows
  ) {
    BulkRecordUploadFieldProjectionV1 matchField = findMatchField(projection);
    Set<String> matchValues = new Set<String>();
    for (BulkRecordUploadMappedRowV1 row : rows) {
      Object value = row.record.get(matchField.fieldApiName);
      if (value != null) {
        matchValues.add(String.valueOf(value));
      }
    }
    if (matchValues.isEmpty()) {
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
    Map<String, Id> idsByValue = new Map<String, Id>();
    for (SObject match : matches) {
      idsByValue.put(
        String.valueOf(match.get(matchField.fieldApiName)),
        (Id) match.get('Id')
      );
    }
    for (BulkRecordUploadMappedRowV1 row : rows) {
      String value = String.valueOf(row.record.get(matchField.fieldApiName));
      if (idsByValue.containsKey(value)) {
        row.record.put('Id', idsByValue.get(value));
      }
    }
  }

  private static BulkRecordUploadFieldProjectionV1 findMatchField(
    BulkRecordUploadProjectionV1 projection
  ) {
    for (BulkRecordUploadFieldProjectionV1 field : projection.getFields()) {
      if (field.isMatchKey) {
        return field;
      }
    }
    throw new BulkRecordUploadException(
      'The operation requires a projected match key.'
    );
  }
}
