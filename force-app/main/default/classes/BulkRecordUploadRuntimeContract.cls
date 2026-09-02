/**
 * Defines the code-owned limits and stable integration values shared by the
 * Bulk Record Upload runtime and maintainer validation.
 */
public class BulkRecordUploadRuntimeContract {
  public static final Integer MAX_CSV_BYTES = 2 * 1024 * 1024;
  public static final Integer MAX_CSV_ROWS = 5000;
  public static final Integer MAX_CSV_COLUMNS = 100;
  public static final Integer MAX_CSV_CELL_CHARACTERS = 32000;
  public static final Integer MAX_CHUNK_ROWS = 200;
  public static final Integer MIN_CHUNK_ROWS = 25;
  public static final Integer MAX_CHUNK_BYTES = 524288;
  public static final Integer MAX_CHUNK_CHARACTERS = 131072;
  public static final Integer MAX_CHUNKS = 200;
  public static final Integer MAX_EXTENSIONS_PER_PROCESS = 10;
  // lightning-record-picker accepts at most one additional matching field
  // and one additional display field.
  public static final Integer MAX_ADDITIONAL_CONTEXT_FIELDS = 1;
  public static final Integer MAX_CONTEXT_FILTER_CONDITIONS = 10;
  public static final Integer MAX_HISTORY_ROWS = 50;
  public static final Integer MAX_PROCESS_OPTIONS = 25;
  public static final Integer MAX_CONCURRENT_UPLOADS = 10;
  public static final Integer MAX_ACTIVE_UPLOAD_HOURS = 24;
  public static final Integer MAX_ERROR_CODE_CHARACTERS = 80;
  public static final Integer MAX_ERROR_MESSAGE_CHARACTERS = 255;

  public static final String STATUS_QUEUED = 'QUEUED';
  public static final String STATUS_VALIDATING = 'VALIDATING';
  public static final String STATUS_PROCESSING = 'PROCESSING';
  public static final String STATUS_COMPLETED = 'COMPLETED';
  public static final String STATUS_COMPLETED_WITH_ERRORS = 'COMPLETED_WITH_ERRORS';
  public static final String STATUS_FAILED = 'FAILED';

  public static final String CHUNK_READY = 'READY';
  public static final String CHUNK_PROCESSING = 'PROCESSING';
  public static final String CHUNK_COMPLETED = 'COMPLETED';
  public static final String CHUNK_FAILED = 'FAILED';

  public static final String ROW_SUCCESS = 'SUCCESS';
  public static final String ROW_FAILED = 'FAILED';
  public static final String ROW_SKIPPED = 'SKIPPED';

  public static final String REASON_PROCESSING_ERROR = 'PROCESSING_ERROR';
  public static final String REASON_PERSISTENCE_COMPLETED_REPORTING_ERROR = 'PERSISTENCE_COMPLETED_REPORTING_ERROR';
  public static final String REASON_DML_ERROR = 'DML_ERROR';
  public static final String REASON_VALIDATION_ERROR = 'VALIDATION_ERROR';
  public static final String REASON_MATCH_ERROR = 'MATCH_ERROR';
  public static final String REASON_CONFIGURATION_CHANGED = 'CONFIGURATION_CHANGED';
  public static final String REASON_EXTENSION_ERROR = 'EXTENSION_ERROR';
  public static final String REASON_ABANDONED_UPLOAD = 'ABANDONED_UPLOAD';

  /** @return A defensive copy of supported upload lifecycle values. */
  public static Set<String> uploadStatuses() {
    return new Set<String>{
      STATUS_QUEUED,
      STATUS_VALIDATING,
      STATUS_PROCESSING,
      STATUS_COMPLETED,
      STATUS_COMPLETED_WITH_ERRORS,
      STATUS_FAILED
    };
  }

  /** @return A defensive copy of supported row-result status values. */
  public static Set<String> rowStatuses() {
    return new Set<String>{ ROW_SUCCESS, ROW_FAILED, ROW_SKIPPED };
  }

  /** @return A defensive copy of package-defined fatal reason codes. */
  public static Set<String> packageReasonCodes() {
    return new Set<String>{
      REASON_PROCESSING_ERROR,
      REASON_PERSISTENCE_COMPLETED_REPORTING_ERROR,
      REASON_DML_ERROR,
      REASON_VALIDATION_ERROR,
      REASON_MATCH_ERROR,
      REASON_CONFIGURATION_CHANGED,
      REASON_EXTENSION_ERROR,
      REASON_ABANDONED_UPLOAD
    };
  }

  /** @return Allowed forward lifecycle transitions keyed by current status. */
  public static Map<String, Set<String>> uploadTransitions() {
    return new Map<String, Set<String>>{
      STATUS_QUEUED => new Set<String>{ STATUS_VALIDATING, STATUS_FAILED },
      STATUS_VALIDATING => new Set<String>{ STATUS_PROCESSING, STATUS_FAILED },
      STATUS_PROCESSING => new Set<String>{
        STATUS_COMPLETED,
        STATUS_COMPLETED_WITH_ERRORS,
        STATUS_FAILED
      }
    };
  }

  /** @return True when the supplied upload status is terminal. */
  public static Boolean isTerminalUploadStatus(String status) {
    return status == STATUS_COMPLETED ||
      status == STATUS_COMPLETED_WITH_ERRORS ||
      status == STATUS_FAILED;
  }
}
