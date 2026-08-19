/** Performs partial user-mode DML and preserves mapped-row correlation. */
public with sharing class BulkRecordUploadPersistenceGateway {
  /** Persists one bounded collection using its approved operation and optional upsert field. */
  public List<BulkRecordUploadRowResultV1> persist(
    String operation,
    List<BulkRecordUploadMappedRowV1> rows,
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
    for (BulkRecordUploadMappedRowV1 row : rows) {
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

  private static List<BulkRecordUploadRowResultV1> correlateSave(
    List<BulkRecordUploadMappedRowV1> rows,
    List<Database.SaveResult> outcomes
  ) {
    List<BulkRecordUploadRowResultV1> results = new List<BulkRecordUploadRowResultV1>();
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

  private static List<BulkRecordUploadRowResultV1> correlateUpsert(
    List<BulkRecordUploadMappedRowV1> rows,
    List<Database.UpsertResult> outcomes
  ) {
    List<BulkRecordUploadRowResultV1> results = new List<BulkRecordUploadRowResultV1>();
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

  private static List<BulkRecordUploadRowResultV1> correlateDelete(
    List<BulkRecordUploadMappedRowV1> rows,
    List<Database.DeleteResult> outcomes
  ) {
    List<BulkRecordUploadRowResultV1> results = new List<BulkRecordUploadRowResultV1>();
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

  private static BulkRecordUploadRowResultV1 toSafeResult(
    Integer rowNumber,
    Boolean success,
    Id recordId,
    List<Database.Error> errors
  ) {
    if (success) {
      return new BulkRecordUploadRowResultV1(
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
    return new BulkRecordUploadRowResultV1(
      rowNumber,
      false,
      null,
      code,
      'The row could not be saved. Review its configured fields and access.'
    );
  }
}
