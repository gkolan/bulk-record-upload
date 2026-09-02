/** Performs partial user-mode DML and preserves mapped-row correlation. */
public with sharing class BulkRecordUploadPersistenceGateway {
  /** Persists one bounded collection using its approved operation and optional upsert field. */
  public List<BulkRecordUploadRowResult> persist(
    String operation,
    List<BulkRecordUploadMappedRow> rows,
    Schema.SObjectField upsertField
  ) {
    if (
      rows == null ||
      rows.isEmpty() ||
      rows.size() > BulkRecordUploadRuntimeContract.MAX_CHUNK_ROWS
    ) {
      throw new BulkRecordUploadException(
        'Persistence requires between 1 and 200 rows.'
      );
    }
    List<BulkRecordUploadMappedRow> validRows = new List<BulkRecordUploadMappedRow>();
    Map<Integer, BulkRecordUploadRowResult> resultsByRow = new Map<Integer, BulkRecordUploadRowResult>();
    for (BulkRecordUploadMappedRow row : rows) {
      if (row.isValid()) {
        validRows.add(row);
      } else {
        resultsByRow.put(
          row.rowNumber,
          new BulkRecordUploadRowResult(
            row.rowNumber,
            false,
            null,
            row.errorCode,
            row.safeMessage
          )
        );
      }
    }
    if (validRows.isEmpty()) {
      return orderedResults(rows, resultsByRow);
    }
    List<SObject> records = new List<SObject>();
    for (BulkRecordUploadMappedRow row : validRows) {
      records.add(row.record);
    }
    String canonical = operation == null ? '' : operation.toUpperCase();
    if (canonical == 'INSERT') {
      List<Database.SaveResult> insertOutcomes = Database.insert(
        records,
        false,
        AccessLevel.USER_MODE
      );
      addResults(
        resultsByRow,
        correlateSave(
          validRows,
          insertOutcomes,
          visibleRecordIds(records, successfulIds(insertOutcomes))
        )
      );
      return orderedResults(rows, resultsByRow);
    }
    if (canonical == 'UPDATE') {
      addResults(
        resultsByRow,
        correlateSave(
          validRows,
          Database.update(records, false, AccessLevel.USER_MODE),
          null
        )
      );
      return orderedResults(rows, resultsByRow);
    }
    if (canonical == 'UPSERT' && upsertField != null) {
      List<Database.UpsertResult> upsertOutcomes = Database.upsert(
        records,
        upsertField,
        false,
        AccessLevel.USER_MODE
      );
      addResults(
        resultsByRow,
        correlateUpsert(
          validRows,
          upsertOutcomes,
          visibleRecordIds(records, successfulIds(upsertOutcomes))
        )
      );
      return orderedResults(rows, resultsByRow);
    }
    if (canonical == 'DELETE') {
      addResults(
        resultsByRow,
        correlateDelete(
          validRows,
          Database.delete(records, false, AccessLevel.USER_MODE)
        )
      );
      return orderedResults(rows, resultsByRow);
    }
    throw new BulkRecordUploadException(
      'The persistence operation is invalid.'
    );
  }

  private static void addResults(
    Map<Integer, BulkRecordUploadRowResult> resultsByRow,
    List<BulkRecordUploadRowResult> results
  ) {
    for (BulkRecordUploadRowResult result : results) {
      resultsByRow.put(result.rowNumber, result);
    }
  }

  private static List<BulkRecordUploadRowResult> orderedResults(
    List<BulkRecordUploadMappedRow> rows,
    Map<Integer, BulkRecordUploadRowResult> resultsByRow
  ) {
    List<BulkRecordUploadRowResult> results = new List<BulkRecordUploadRowResult>();
    for (BulkRecordUploadMappedRow row : rows) {
      results.add(resultsByRow.get(row.rowNumber));
    }
    return results;
  }

  private static List<BulkRecordUploadRowResult> correlateSave(
    List<BulkRecordUploadMappedRow> rows,
    List<Database.SaveResult> outcomes,
    Set<Id> visibleRecordIds
  ) {
    List<BulkRecordUploadRowResult> results = new List<BulkRecordUploadRowResult>();
    for (Integer index = 0; index < outcomes.size(); index++) {
      Database.SaveResult outcome = outcomes[index];
      results.add(
        toSafeResult(
          rows[index].rowNumber,
          outcome.isSuccess(),
          visibleRecordIds == null || visibleRecordIds.contains(outcome.getId())
            ? outcome.getId()
            : null,
          outcome.getErrors()
        )
      );
    }
    return results;
  }

  private static List<BulkRecordUploadRowResult> correlateUpsert(
    List<BulkRecordUploadMappedRow> rows,
    List<Database.UpsertResult> outcomes,
    Set<Id> visibleRecordIds
  ) {
    List<BulkRecordUploadRowResult> results = new List<BulkRecordUploadRowResult>();
    for (Integer index = 0; index < outcomes.size(); index++) {
      Database.UpsertResult outcome = outcomes[index];
      results.add(
        toSafeResult(
          rows[index].rowNumber,
          outcome.isSuccess(),
          visibleRecordIds.contains(outcome.getId()) ? outcome.getId() : null,
          outcome.getErrors()
        )
      );
    }
    return results;
  }

  private static Set<Id> successfulIds(List<Database.SaveResult> outcomes) {
    Set<Id> ids = new Set<Id>();
    for (Database.SaveResult outcome : outcomes) {
      if (outcome.isSuccess()) {
        ids.add(outcome.getId());
      }
    }
    return ids;
  }

  private static Set<Id> successfulIds(List<Database.UpsertResult> outcomes) {
    Set<Id> ids = new Set<Id>();
    for (Database.UpsertResult outcome : outcomes) {
      if (outcome.isSuccess()) {
        ids.add(outcome.getId());
      }
    }
    return ids;
  }

  private static Set<Id> visibleRecordIds(
    List<SObject> records,
    Set<Id> recordIds
  ) {
    Set<Id> visible = new Set<Id>();
    if (
      recordIds.isEmpty() ||
      !records[0].getSObjectType().getDescribe().isAccessible()
    ) {
      return visible;
    }
    String objectApiName = records[0].getSObjectType().getDescribe().getName();
    for (
      SObject record : Database.queryWithBinds(
        'SELECT Id FROM ' + objectApiName + ' WHERE Id IN :recordIds',
        new Map<String, Object>{ 'recordIds' => recordIds },
        AccessLevel.USER_MODE
      )
    ) {
      visible.add(record.Id);
    }
    return visible;
  }

  private static List<BulkRecordUploadRowResult> correlateDelete(
    List<BulkRecordUploadMappedRow> rows,
    List<Database.DeleteResult> outcomes
  ) {
    List<BulkRecordUploadRowResult> results = new List<BulkRecordUploadRowResult>();
    for (Integer index = 0; index < outcomes.size(); index++) {
      Database.DeleteResult outcome = outcomes[index];
      results.add(
        toSafeResult(
          rows[index].rowNumber,
          outcome.isSuccess(),
          outcome.getId(),
          outcome.getErrors()
        )
      );
    }
    return results;
  }

  private static BulkRecordUploadRowResult toSafeResult(
    Integer rowNumber,
    Boolean success,
    Id recordId,
    List<Database.Error> errors
  ) {
    if (success) {
      return new BulkRecordUploadRowResult(
        rowNumber,
        true,
        recordId,
        null,
        null
      );
    }
    String code = errors.isEmpty()
      ? BulkRecordUploadRuntimeContract.REASON_DML_ERROR
      : String.valueOf(errors[0].getStatusCode());
    return new BulkRecordUploadRowResult(
      rowNumber,
      false,
      null,
      code,
      'The row could not be saved. Review its configured fields and access.'
    );
  }
}
