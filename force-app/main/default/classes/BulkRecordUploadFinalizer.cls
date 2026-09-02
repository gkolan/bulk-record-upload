/** Joins ordered safe result fragments, creates the final File, and removes staging. */
public with sharing class BulkRecordUploadFinalizer {
  /** Finalizes an upload after every staged chunk reaches COMPLETED. */
  public void finalizeUpload(Id uploadId) {
    List<Bulk_Record_Upload_Chunk__c> chunks = [
      SELECT
        Id,
        ProcessingOrder__c,
        Status__c,
        StagedRowData__c,
        SuccessCount__c,
        FailureCount__c
      FROM Bulk_Record_Upload_Chunk__c
      WHERE ParentUpload__c = :uploadId
      WITH SYSTEM_MODE
      ORDER BY ProcessingOrder__c
    ];
    ResultAssembly assembly = assemble(chunks, true);
    new BulkRecordUploadFileService().createResultFile(uploadId, assembly.body);
    String terminal = assembly.failures == 0
      ? 'COMPLETED'
      : 'COMPLETED_WITH_ERRORS';
    new BulkRecordUploadLogService()
      .transition(uploadId, terminal, assembly.successes, assembly.failures);
    delete as system chunks;
  }

  /** Promotes completed chunk results after a later chunk fails fatally. */
  public Boolean finalizePartialResults(Id uploadId) {
    List<Bulk_Record_Upload_Chunk__c> chunks = [
      SELECT
        Id,
        ProcessingOrder__c,
        Status__c,
        StagedRowData__c,
        SuccessCount__c,
        FailureCount__c
      FROM Bulk_Record_Upload_Chunk__c
      WHERE ParentUpload__c = :uploadId AND Status__c = 'COMPLETED'
      WITH SYSTEM_MODE
      ORDER BY ProcessingOrder__c
    ];
    if (chunks.isEmpty()) {
      return false;
    }
    ResultAssembly assembly = assemble(chunks, false);
    new BulkRecordUploadFileService().createResultFile(uploadId, assembly.body);
    delete as system chunks;
    return true;
  }

  private static ResultAssembly assemble(
    List<Bulk_Record_Upload_Chunk__c> chunks,
    Boolean requireEveryChunk
  ) {
    Integer successes = 0;
    Integer failures = 0;
    List<String> fragments = new List<String>();
    for (Bulk_Record_Upload_Chunk__c chunk : chunks) {
      if (requireEveryChunk && chunk.Status__c != 'COMPLETED') {
        throw new BulkRecordUploadException(
          'Upload chunks are not ready for finalization.'
        );
      }
      String payload = chunk.StagedRowData__c == null
        ? ''
        : chunk.StagedRowData__c;
      successes += Integer.valueOf(chunk.SuccessCount__c ?? 0);
      failures += Integer.valueOf(chunk.FailureCount__c ?? 0);
      Integer firstBreak = payload.indexOf('\r\n');
      if (fragments.isEmpty()) {
        fragments.add(
          firstBreak < 0
            ? BulkRecordUploadResultWriter.HEADER
            : payload.substring(0, firstBreak)
        );
      }
      String body = firstBreak < 0 ? '' : payload.substring(firstBreak + 2);
      if (body.endsWith('\r\n')) {
        body = body.left(body.length() - 2);
      }
      if (!String.isBlank(body)) {
        fragments.add(body);
      }
      chunk.StagedRowData__c = null;
    }
    String csv = String.join(fragments, '\r\n') + '\r\n';
    fragments.clear();
    return new ResultAssembly(Blob.valueOf(csv), successes, failures);
  }

  private class ResultAssembly {
    private Blob body;
    private Integer successes;
    private Integer failures;

    private ResultAssembly(Blob body, Integer successes, Integer failures) {
      this.body = body;
      this.successes = successes;
      this.failures = failures;
    }
  }
}
