/** Produces the stable version 1 results CSV from approved result fields only. */
public with sharing class BulkRecordUploadResultWriter {
  public static final String HEADER = 'bru_row_number,bru_status,bru_record_id,bru_error_code,bru_error_message';
  public static final Integer MAX_STAGED_RESULT_CHARACTERS = BulkRecordUploadRuntimeContract.MAX_CHUNK_CHARACTERS;

  /** Builds results without configured source columns. */
  public Blob write(List<BulkRecordUploadRowResultV1> results) {
    return write(results, null, null);
  }

  /** Builds results with approved configured columns in stable projection order. */
  public Blob write(
    List<BulkRecordUploadRowResultV1> results,
    BulkRecordUploadProjectionV1 projection,
    List<BulkRecordUploadRowV1> sourceRows
  ) {
    if (results == null) {
      throw new BulkRecordUploadException('Result rows are required.');
    }
    List<BulkRecordUploadFieldProjectionV1> projectedFields = resultFields(
      projection
    );
    List<String> headers = new List<String>{
      'bru_row_number',
      'bru_status',
      'bru_record_id',
      'bru_error_code',
      'bru_error_message'
    };
    for (BulkRecordUploadFieldProjectionV1 field : projectedFields) {
      headers.add(field.columnKey);
    }
    Map<Integer, Map<String, String>> sourceByRow = indexSource(sourceRows);
    List<String> lines = new List<String>{ String.join(headers, ',') };
    for (BulkRecordUploadRowResultV1 result : results) {
      List<String> cells = new List<String>{
        escape(String.valueOf(result.rowNumber)),
        escape(
          result.isSuccess
            ? BulkRecordUploadRuntimeContract.ROW_SUCCESS
            : BulkRecordUploadRuntimeContract.ROW_FAILED
        ),
        escape(
          result.recordId == null ? null : String.valueOf(result.recordId)
        ),
        escape(result.errorCode),
        escape(result.safeMessage)
      };
      Map<String, String> source = sourceByRow.get(result.rowNumber);
      for (BulkRecordUploadFieldProjectionV1 field : projectedFields) {
        cells.add(escape(source == null ? null : source.get(field.columnKey)));
      }
      lines.add(String.join(cells, ','));
    }
    String csv = String.join(lines, '\r\n') + '\r\n';
    if (csv.length() > MAX_STAGED_RESULT_CHARACTERS) {
      throw new BulkRecordUploadException(
        'The result exceeds the safe chunk size.'
      );
    }
    return Blob.valueOf(csv);
  }

  private static List<BulkRecordUploadFieldProjectionV1> resultFields(
    BulkRecordUploadProjectionV1 projection
  ) {
    List<BulkRecordUploadFieldProjectionV1> fields = new List<BulkRecordUploadFieldProjectionV1>();
    if (projection != null) {
      for (BulkRecordUploadFieldProjectionV1 field : projection.getFields()) {
        if (field.includeInResult) {
          fields.add(field);
        }
      }
    }
    return fields;
  }

  private static Map<Integer, Map<String, String>> indexSource(
    List<BulkRecordUploadRowV1> sourceRows
  ) {
    Map<Integer, Map<String, String>> values = new Map<Integer, Map<String, String>>();
    if (sourceRows != null) {
      for (BulkRecordUploadRowV1 row : sourceRows) {
        values.put(row.rowNumber, row.getValuesByColumn());
      }
    }
    return values;
  }

  private static String escape(String value) {
    String safe = value == null ? '' : value;
    String firstCharacter = String.isBlank(safe) ? '' : safe.left(1);
    Boolean numericNegative =
      firstCharacter == '-' &&
      safe.length() > 1 &&
      '0123456789'.contains(safe.substring(1, 2));
    if (
      !String.isBlank(safe) &&
      ('=+@'.contains(firstCharacter) ||
      (firstCharacter == '-' && !numericNegative) ||
      firstCharacter == '\t' ||
      firstCharacter == '\r')
    ) {
      safe = '\'' + safe;
    }
    return '"' + safe.replace('"', '""') + '"';
  }
}
