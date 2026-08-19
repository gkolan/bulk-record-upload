/**
 * Loads active version 1 process and field configuration without querying subscriber data.
 */
public with sharing class BulkRecordUploadConfigRepository {
  private final Map<String, Bulk_Record_Upload_Process__mdt> processesByKey;
  private final List<Bulk_Record_Upload_Process_Field__mdt> fieldRecords;
  private final List<Bulk_Record_Upload_Extension__mdt> extensionRecords;

  /** Creates a repository backed by the org's Custom Metadata records. */
  public BulkRecordUploadConfigRepository() {
    this(
      Bulk_Record_Upload_Process__mdt.getAll(),
      Bulk_Record_Upload_Process_Field__mdt.getAll().values(),
      Bulk_Record_Upload_Extension__mdt.getAll().values()
    );
  }

  /**
   * Creates an injectable repository for deterministic tests.
   * @param processesByKey Process records keyed by Developer Name.
   * @param fieldRecords Field configuration records.
   * @param extensionRecords Extension registration records.
   */
  @TestVisible
  private BulkRecordUploadConfigRepository(
    Map<String, Bulk_Record_Upload_Process__mdt> processesByKey,
    List<Bulk_Record_Upload_Process_Field__mdt> fieldRecords,
    List<Bulk_Record_Upload_Extension__mdt> extensionRecords
  ) {
    this.processesByKey = processesByKey == null
      ? new Map<String, Bulk_Record_Upload_Process__mdt>()
      : new Map<String, Bulk_Record_Upload_Process__mdt>(processesByKey);
    this.fieldRecords = fieldRecords == null
      ? new List<Bulk_Record_Upload_Process_Field__mdt>()
      : new List<Bulk_Record_Upload_Process_Field__mdt>(fieldRecords);
    this.extensionRecords = extensionRecords == null
      ? new List<Bulk_Record_Upload_Extension__mdt>()
      : new List<Bulk_Record_Upload_Extension__mdt>(extensionRecords);
  }

  /**
   * Finds one active process and its ordered active field records.
   * @param processKey Exact subscriber Developer Name.
   * @return Immutable process snapshot and ordered field records.
   * @throws BulkRecordUploadException when the process is missing or inactive.
   */
  public Configuration findActive(String processKey) {
    if (String.isBlank(processKey)) {
      throw new BulkRecordUploadException('Process key is required.');
    }
    Bulk_Record_Upload_Process__mdt processRecord = processesByKey.get(
      processKey.trim()
    );
    if (processRecord == null || processRecord.IsActive__c != true) {
      throw new BulkRecordUploadException(
        'The requested upload process is unavailable.'
      );
    }
    List<BulkRecordUploadFieldConfigV1> matchingFields = new List<BulkRecordUploadFieldConfigV1>();
    for (Bulk_Record_Upload_Process_Field__mdt fieldRecord : fieldRecords) {
      if (
        fieldRecord.IsActive__c == true &&
        fieldRecord.ProcessDeveloperName__c == processRecord.DeveloperName
      ) {
        matchingFields.add(new BulkRecordUploadFieldConfigV1(fieldRecord));
      }
    }
    matchingFields.sort();
    List<BulkRecordUploadExtensionConfigV1> matchingExtensions = new List<BulkRecordUploadExtensionConfigV1>();
    for (Bulk_Record_Upload_Extension__mdt extensionRecord : extensionRecords) {
      if (
        extensionRecord.IsActive__c == true &&
        extensionRecord.ProcessDeveloperName__c == processRecord.DeveloperName
      ) {
        matchingExtensions.add(
          new BulkRecordUploadExtensionConfigV1(extensionRecord)
        );
      }
    }
    matchingExtensions.sort();
    return new Configuration(
      new BulkRecordUploadProcessConfigV1(processRecord),
      matchingFields,
      matchingExtensions
    );
  }

  /** Holds one immutable configuration snapshot. */
  public class Configuration {
    public BulkRecordUploadProcessConfigV1 process { get; private set; }
    public List<BulkRecordUploadFieldConfigV1> fields { get; private set; }
    public List<BulkRecordUploadExtensionConfigV1> extensions {
      get;
      private set;
    }

    private Configuration(
      BulkRecordUploadProcessConfigV1 process,
      List<BulkRecordUploadFieldConfigV1> fields,
      List<BulkRecordUploadExtensionConfigV1> extensions
    ) {
      this.process = process;
      this.fields = new List<BulkRecordUploadFieldConfigV1>(fields);
      this.extensions = new List<BulkRecordUploadExtensionConfigV1>(extensions);
    }

    /** @return A defensive copy of ordered field configuration. */
    public List<BulkRecordUploadFieldConfigV1> getFields() {
      return new List<BulkRecordUploadFieldConfigV1>(fields);
    }

    /** @return A defensive copy of ordered extension configuration. */
    public List<BulkRecordUploadExtensionConfigV1> getExtensions() {
      return new List<BulkRecordUploadExtensionConfigV1>(extensions);
    }
  }
}
