/** Validates and applies administrator-approved Lightning record context. */
public with sharing class BulkRecordUploadRecordContextService {
  /** Returns a visible, type-correct context ID or null when context is disabled. */
  public Id validateContext(
    BulkRecordUploadProjection projection,
    String contextRecordId
  ) {
    if (projection.recordContextAction == 'NONE') {
      return null;
    }
    if (String.isBlank(contextRecordId)) {
      if (projection.recordContextAction == 'REQUIRE_PARENT') {
        throw new BulkRecordUploadException(
          'This upload process requires a parent record page.'
        );
      }
      return null;
    }
    Id contextId;
    try {
      contextId = (Id) contextRecordId;
    } catch (Exception error) {
      throw new BulkRecordUploadException('The parent record is invalid.');
    }
    Schema.SObjectType hostType = Schema.getGlobalDescribe()
      .get(projection.hostObjectApiName);
    if (hostType == null || contextId.getSObjectType() != hostType) {
      throw new BulkRecordUploadException(
        'The parent record does not match this upload process.'
      );
    }
    Boolean eligible = new BulkRecordUploadContextSourceService()
      .isEligible(
        projection.hostObjectApiName,
        contextId,
        projection.contextProjection.filterConditions
      );
    if (!eligible) {
      throw new BulkRecordUploadException('The parent record is unavailable.');
    }
    return contextId;
  }

  /** Applies the server-verified parent after CSV mapping and merge behavior. */
  public void applyContext(
    BulkRecordUploadProjection projection,
    Id contextRecordId,
    List<BulkRecordUploadMappedRow> rows
  ) {
    if (contextRecordId == null || projection.recordContextAction == 'NONE') {
      return;
    }
    for (BulkRecordUploadMappedRow row : rows) {
      row.record.put(projection.recordContextFieldApiName, contextRecordId);
    }
  }
}
