/** Applies bounded retention and deletes only package-owned Files with no unrelated links. */
// The durable query supplies retry state; a Queueable Finalizer adds no recovery data.
// code-analyzer-suppress-next-line QueueableWithoutFinalizer
public with sharing class BulkRecordUploadRetentionJob implements Schedulable, Queueable {
  private static final Integer MAX_UPLOADS = 200;

  /** Scheduled entry point for bounded cleanup. */
  public void execute(SchedulableContext context) {
    cleanupAndContinue();
  }

  /** Queueable continuation for a backlog larger than one safe transaction. */
  public void execute(QueueableContext context) {
    cleanupAndContinue();
  }

  /** Removes expired terminal uploads and their provably package-owned Files. */
  public Integer cleanup() {
    List<Bulk_Record_Upload__c> candidates = [
      SELECT Id, InputFileId__c, ResultFileId__c
      FROM Bulk_Record_Upload__c
      WHERE
        Status__c IN ('COMPLETED', 'COMPLETED_WITH_ERRORS', 'FAILED')
        AND ExpiresAt__c <= :System.now()
      WITH SYSTEM_MODE
      ORDER BY CompletedAt__c
      LIMIT :MAX_UPLOADS
    ];
    Map<Id, Id> uploadByDocument = new Map<Id, Id>();
    for (Bulk_Record_Upload__c upload : candidates) {
      addDocument(uploadByDocument, upload.InputFileId__c, upload.Id);
      addDocument(uploadByDocument, upload.ResultFileId__c, upload.Id);
    }
    deleteOwnedDocuments(uploadByDocument);
    if (!candidates.isEmpty()) {
      delete as system candidates;
    }
    return candidates.size();
  }

  private void cleanupAndContinue() {
    new BulkRecordUploadRecoveryService().recover();
    if (cleanup() == MAX_UPLOADS) {
      System.enqueueJob(new BulkRecordUploadRetentionJob());
    }
  }

  private static void addDocument(
    Map<Id, Id> uploadByDocument,
    String value,
    Id uploadId
  ) {
    if (String.isBlank(value)) {
      return;
    }
    if (Pattern.matches('^[a-zA-Z0-9]{15}([a-zA-Z0-9]{3})?$', value)) {
      uploadByDocument.put((Id) value, uploadId);
    }
  }

  private static void deleteOwnedDocuments(Map<Id, Id> uploadByDocument) {
    if (uploadByDocument.isEmpty()) {
      return;
    }
    Set<Id> documentIds = uploadByDocument.keySet();
    Map<Id, List<Id>> linksByDocument = new Map<Id, List<Id>>();
    for (ContentDocumentLink link : [
      SELECT ContentDocumentId, LinkedEntityId
      FROM ContentDocumentLink
      WHERE ContentDocumentId IN :documentIds
      WITH SYSTEM_MODE
    ]) {
      if (!linksByDocument.containsKey(link.ContentDocumentId)) {
        linksByDocument.put(link.ContentDocumentId, new List<Id>());
      }
      linksByDocument.get(link.ContentDocumentId).add(link.LinkedEntityId);
    }
    List<ContentDocument> owned = new List<ContentDocument>();
    for (ContentDocument document : [
      SELECT Id, Title
      FROM ContentDocument
      WHERE Id IN :documentIds
      WITH SYSTEM_MODE
    ]) {
      List<Id> links = linksByDocument.get(document.Id);
      if (
        links != null &&
        links.size() == 1 &&
        links[0] == uploadByDocument.get(document.Id) &&
        document.Title.startsWith('Bulk Record Upload ')
      ) {
        owned.add(document);
      }
    }
    if (!owned.isEmpty()) {
      delete as system owned;
    }
  }
}
