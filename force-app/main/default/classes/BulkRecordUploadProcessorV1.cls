/** Trusted persistence extension for one bounded, already validated and mapped chunk. */
public interface BulkRecordUploadProcessorV1 {
  /** Persists or delegates one bounded chunk while preserving row correlation. */
  List<BulkRecordUploadRowResultV1> process(
    BulkRecordUploadProjectionV1 projection,
    List<BulkRecordUploadMappedRowV1> rows,
    Schema.SObjectField upsertField
  );
}
