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
    List<SObject> records = new List<SObject>();
    for (BulkRecordUploadMappedRow row : rows) {
      records.add(row.record);
    }
    String canonical = operation == null ? '' : operation.toUpperCase();
    if (canonical == 'INSERT') {
      return correlateSave(
        rows,
        Database.insert(records, false, AccessLevel.USER_MODE)
      );
    }
    if (canonical == 'UPDATE') {
      return correlateSave(
        rows,
        Database.update(records, false, AccessLevel.USER_MODE)
      );
    }
    if (canonical == 'UPSERT' && upsertField != null) {
      return correlateUpsert(
        rows,
        Database.upsert(records, upsertField, false, AccessLevel.USER_MODE)
      );
    }
    if (canonical == 'DELETE') {
      return correlateDelete(
        rows,
        Database.delete(records, false, AccessLevel.USER_MODE)
      );
    }
    throw new BulkRecordUploadException(
      'The persistence operation is invalid.'
    );
  }

  private static List<BulkRecordUploadRowResult> correlateSave(
    List<BulkRecordUploadMappedRow> rows,
    List<Database.SaveResult> outcomes
  ) {
    List<BulkRecordUploadRowResult> results = new List<BulkRecordUploadRowResult>();
    for (Integer index = 0; index < outcomes.size(); index++) {
      Database.SaveResult outcome = outcomes[index];
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

  private static List<BulkRecordUploadRowResult> correlateUpsert(
    List<BulkRecordUploadMappedRow> rows,
    List<Database.UpsertResult> outcomes
  ) {
    List<BulkRecordUploadRowResult> results = new List<BulkRecordUploadRowResult>();
    for (Integer index = 0; index < outcomes.size(); index++) {
      Database.UpsertResult outcome = outcomes[index];
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
