/** Trusted persistence extension for one bounded, already validated and mapped chunk. */
public interface BulkRecordUploadProcessor {
  /** Persists or delegates one bounded chunk while preserving row correlation. */
  List<BulkRecordUploadRowResult> process(
    BulkRecordUploadProjection projection,
    List<BulkRecordUploadMappedRow> rows,
    Schema.SObjectField upsertField
  );
}
