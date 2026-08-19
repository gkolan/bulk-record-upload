/**
 * Immutable, compact projection of one process's record-context picker
 * configuration. Held as a single property on BulkRecordUploadProjectionV1
 * instead of threading four more constructor arguments through the
 * project's most-touched configuration type.
 */
public class BulkRecordUploadContextProjectionV1 {
  public String recordContextSource { get; private set; }
  public String primarySearchField { get; private set; }
  public List<String> additionalSearchFields { get; private set; }
  public String primaryDisplayField { get; private set; }
  public List<String> additionalDisplayFields { get; private set; }
  public List<BulkRecordUploadContextFilterConditionV1> filterConditions {
    get;
    private set;
  }

  /** Creates an immutable context projection from already-validated inputs. */
  public BulkRecordUploadContextProjectionV1(
    String recordContextSource,
    String primarySearchField,
    List<String> additionalSearchFields,
    String primaryDisplayField,
    List<String> additionalDisplayFields,
    List<BulkRecordUploadContextFilterConditionV1> filterConditions
  ) {
    this.recordContextSource = String.isBlank(recordContextSource)
      ? 'PAGE'
      : recordContextSource.trim();
    this.primarySearchField = primarySearchField;
    this.additionalSearchFields = additionalSearchFields == null
      ? new List<String>()
      : new List<String>(additionalSearchFields);
    this.primaryDisplayField = primaryDisplayField;
    this.additionalDisplayFields = additionalDisplayFields == null
      ? new List<String>()
      : new List<String>(additionalDisplayFields);
    this.filterConditions = filterConditions == null
      ? new List<BulkRecordUploadContextFilterConditionV1>()
      : new List<BulkRecordUploadContextFilterConditionV1>(filterConditions);
  }
}
