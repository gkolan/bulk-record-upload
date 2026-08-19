/** Creates bounded durable staging chunks owned by one upload record. */
public with sharing class BulkRecordUploadStagingService {
  public static final Integer MAX_CHUNK_ROWS = BulkRecordUploadRuntimeContract.MAX_CHUNK_ROWS;
  public static final Integer MAX_CHUNK_BYTES = BulkRecordUploadRuntimeContract.MAX_CHUNK_BYTES;
  public static final Integer MAX_CHUNKS = BulkRecordUploadRuntimeContract.MAX_CHUNKS;

  /** Serializes rows into ordered package-owned chunks using one system-mode DML statement. */
  public List<Bulk_Record_Upload_Chunk__c> stage(
    Id uploadId,
    List<BulkRecordUploadRowV1> rows,
    Integer requestedSize
  ) {
    if (uploadId == null || rows == null || rows.isEmpty()) {
      throw new BulkRecordUploadException('Staging input is required.');
    }
    Integer chunkSize = requestedSize == null
      ? MAX_CHUNK_ROWS
      : Math.min(
          MAX_CHUNK_ROWS,
          Math.max(
            BulkRecordUploadRuntimeContract.MIN_CHUNK_ROWS,
            requestedSize
          )
        );
    List<Bulk_Record_Upload_Chunk__c> chunks = new List<Bulk_Record_Upload_Chunk__c>();
    for (
      Integer startIndex = 0; startIndex < rows.size(); startIndex += chunkSize
    ) {
      Integer endIndex = Math.min(startIndex + chunkSize, rows.size());
      appendBounded(chunks, uploadId, slice(rows, startIndex, endIndex));
    }
    if (chunks.size() > MAX_CHUNKS) {
      throw new BulkRecordUploadException(
        'The upload exceeds the 5,000 row or safe staging-size limit.'
      );
    }
    insert as system chunks;
    return chunks;
  }

  private static void appendBounded(
    List<Bulk_Record_Upload_Chunk__c> chunks,
    Id uploadId,
    List<BulkRecordUploadRowV1> rows
  ) {
    String payload = JSON.serialize(rows);
    if (
      Blob.valueOf(payload).size() > MAX_CHUNK_BYTES ||
      payload.length() > BulkRecordUploadRuntimeContract.MAX_CHUNK_CHARACTERS
    ) {
      if (rows.size() == 1) {
        throw new BulkRecordUploadException(
          'A staged row exceeds the safe chunk size.'
        );
      }
      Integer midpoint = rows.size() / 2;
      appendBounded(chunks, uploadId, slice(rows, 0, midpoint));
      appendBounded(chunks, uploadId, slice(rows, midpoint, rows.size()));
      return;
    }
    chunks.add(
      new Bulk_Record_Upload_Chunk__c(
        ParentUpload__c = uploadId,
        ProcessingOrder__c = chunks.size() + 1,
        FirstCsvRow__c = rows[0].rowNumber,
        StagedRowData__c = payload,
        IntegrityChecksum__c = EncodingUtil.convertToHex(
          Crypto.generateDigest('SHA-256', Blob.valueOf(payload))
        ),
        Status__c = BulkRecordUploadRuntimeContract.CHUNK_READY
      )
    );
  }

  private static List<BulkRecordUploadRowV1> slice(
    List<BulkRecordUploadRowV1> rows,
    Integer startIndex,
    Integer endIndex
  ) {
    List<BulkRecordUploadRowV1> result = new List<BulkRecordUploadRowV1>();
    for (Integer index = startIndex; index < endIndex; index++) {
      result.add(rows[index]);
    }
    return result;
  }
}
