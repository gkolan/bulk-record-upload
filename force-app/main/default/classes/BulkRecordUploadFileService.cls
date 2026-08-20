/** Owns package-created input/result Files and their upload-record links. */
public with sharing class BulkRecordUploadFileService {
  /** Creates the original input File and records its document Id. */
  public Id createInputFile(Id uploadId, Blob body, String fileName) {
    requireFileInput(uploadId, body, 'Input file data is required.');
    String safeName = String.isBlank(fileName)
      ? 'bulk-record-upload.csv'
      : fileName.replaceAll('[^a-zA-Z0-9._-]', '_').left(120);
    Id documentId = createFile(
      uploadId,
      body,
      'Bulk Record Upload Input',
      safeName
    );
    update as system new Bulk_Record_Upload__c(
      Id = uploadId,
      InputFileId__c = documentId
    );
    return documentId;
  }

  /** Creates one result File and records its document Id. */
  public Id createResultFile(Id uploadId, Blob body) {
    requireFileInput(uploadId, body, 'Result file input is required.');
    Id documentId = createFile(
      uploadId,
      body,
      'Bulk Record Upload Results',
      'bulk-record-upload-results.csv'
    );
    update as system new Bulk_Record_Upload__c(
      Id = uploadId,
      ResultFileId__c = documentId
    );
    return documentId;
  }

  private static Id createFile(
    Id uploadId,
    Blob body,
    String title,
    String path
  ) {
    ContentVersion version = new ContentVersion(
      Title = title,
      PathOnClient = path,
      VersionData = body,
      FirstPublishLocationId = uploadId
    );
    insert as system version;
    return [
      SELECT ContentDocumentId
      FROM ContentVersion
      WHERE Id = :version.Id
      WITH SYSTEM_MODE
    ]
    .ContentDocumentId;
  }

  private static void requireFileInput(Id uploadId, Blob body, String message) {
    if (uploadId == null || body == null || body.size() == 0) {
      throw new BulkRecordUploadException(message);
    }
  }
}
