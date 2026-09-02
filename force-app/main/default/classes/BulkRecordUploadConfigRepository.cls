/**
 * Loads active process and field configuration without querying subscriber data.
 */
public with sharing class BulkRecordUploadConfigRepository {
  private final Map<String, Bulk_Record_Upload_Process__mdt> processesByKey;
  private final List<Bulk_Record_Upload_Process_Field__mdt> fieldRecords;
  private final List<Bulk_Record_Upload_Extension__mdt> extensionRecords;
  private final Boolean queryOrgMetadata;

  /** Creates a repository backed by the org's Custom Metadata records. */
  public BulkRecordUploadConfigRepository() {
    this(
      new Map<String, Bulk_Record_Upload_Process__mdt>(),
      new List<Bulk_Record_Upload_Process_Field__mdt>(),
      new List<Bulk_Record_Upload_Extension__mdt>(),
      true
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
    this(processesByKey, fieldRecords, extensionRecords, false);
  }

  private BulkRecordUploadConfigRepository(
    Map<String, Bulk_Record_Upload_Process__mdt> processesByKey,
    List<Bulk_Record_Upload_Process_Field__mdt> fieldRecords,
    List<Bulk_Record_Upload_Extension__mdt> extensionRecords,
    Boolean queryOrgMetadata
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
    this.queryOrgMetadata = queryOrgMetadata == true;
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
    String normalizedKey = processKey.trim();
    Bulk_Record_Upload_Process__mdt processRecord = queryOrgMetadata
      ? queryProcess(normalizedKey)
      : processesByKey.get(normalizedKey);
    if (processRecord == null || processRecord.IsActive__c != true) {
      throw new BulkRecordUploadException(
        'The requested upload process is unavailable.'
      );
    }
    List<BulkRecordUploadFieldConfig> matchingFields = new List<BulkRecordUploadFieldConfig>();
    List<Bulk_Record_Upload_Process_Field__mdt> fieldsToInspect = queryOrgMetadata
      ? queryFields(normalizedKey)
      : fieldRecords;
    for (Bulk_Record_Upload_Process_Field__mdt fieldRecord : fieldsToInspect) {
      if (
        fieldRecord.IsActive__c == true &&
        fieldRecord.ProcessDeveloperName__c == processRecord.DeveloperName
      ) {
        matchingFields.add(new BulkRecordUploadFieldConfig(fieldRecord));
      }
    }
    matchingFields.sort();
    List<BulkRecordUploadExtensionConfig> matchingExtensions = new List<BulkRecordUploadExtensionConfig>();
    List<Bulk_Record_Upload_Extension__mdt> extensionsToInspect = queryOrgMetadata
      ? queryExtensions(normalizedKey)
      : extensionRecords;
    for (
      Bulk_Record_Upload_Extension__mdt extensionRecord : extensionsToInspect
    ) {
      if (
        extensionRecord.IsActive__c == true &&
        extensionRecord.ProcessDeveloperName__c == processRecord.DeveloperName
      ) {
        matchingExtensions.add(
          new BulkRecordUploadExtensionConfig(extensionRecord)
        );
      }
    }
    matchingExtensions.sort();
    return new Configuration(
      new BulkRecordUploadProcessConfig(processRecord),
      matchingFields,
      matchingExtensions
    );
  }

  private static Bulk_Record_Upload_Process__mdt queryProcess(String key) {
    // Custom Metadata is package setup and has no object CRUD permission.
    // code-analyzer-suppress-next-line ApexCRUDViolation
    List<Bulk_Record_Upload_Process__mdt> records = [
      SELECT
        DeveloperName,
        IsActive__c,
        ObjectApiName__c,
        Operation__c,
        PreviewPermissionApiName__c,
        RowsPerBatch__c,
        RetentionDays__c,
        ConfigurationVersion__c,
        ProcessingMode__c,
        ProcessorKey__c,
        RecordContextAction__c,
        HostObjectApiName__c,
        RecordContextFieldApiName__c,
        RecordContextSource__c,
        ContextSearchFields__c,
        ContextDisplayFields__c,
        ContextFilterCriteria__c
      FROM Bulk_Record_Upload_Process__mdt
      WHERE DeveloperName = :key
      LIMIT 1
    ];
    return records.isEmpty() ? null : records[0];
  }

  private static List<Bulk_Record_Upload_Process_Field__mdt> queryFields(
    String key
  ) {
    Integer fieldLimit = BulkRecordUploadRuntimeContract.MAX_CSV_COLUMNS + 1;
    // Custom Metadata is package setup and has no object CRUD permission.
    // code-analyzer-suppress-next-line ApexCRUDViolation
    return [
      SELECT
        DeveloperName,
        IsActive__c,
        ProcessDeveloperName__c,
        CsvColumnHeader__c,
        DisplayLabel__c,
        FieldApiName__c,
        ExistingValueAction__c,
        BlankValueAction__c,
        TextSeparator__c,
        CustomSeparator__c,
        DuplicateTextAction__c,
        OverflowAction__c,
        DefaultValue__c,
        TrimValue__c,
        CaseAction__c,
        BlankTokens__c,
        CustomMergeStrategyClass__c,
        ValidationPattern__c,
        MinValue__c,
        MaxValue__c,
        SourceTemplate__c,
        LookupMatchField__c,
        ColumnOrder__c,
        IsRequired__c,
        IsMatchField__c,
        IsUpsertExternalId__c,
        IncludeInResult__c
      FROM Bulk_Record_Upload_Process_Field__mdt
      WHERE ProcessDeveloperName__c = :key AND IsActive__c = TRUE
      ORDER BY ColumnOrder__c, DeveloperName
      LIMIT :fieldLimit
    ];
  }

  private static List<Bulk_Record_Upload_Extension__mdt> queryExtensions(
    String key
  ) {
    Integer extensionLimit =
      BulkRecordUploadRuntimeContract.MAX_EXTENSIONS_PER_PROCESS + 1;
    // Custom Metadata is package setup and has no object CRUD permission.
    // code-analyzer-suppress-next-line ApexCRUDViolation
    return [
      SELECT
        DeveloperName,
        IsActive__c,
        ProcessDeveloperName__c,
        ClassName__c,
        SortOrder__c
      FROM Bulk_Record_Upload_Extension__mdt
      WHERE ProcessDeveloperName__c = :key AND IsActive__c = TRUE
      ORDER BY SortOrder__c, DeveloperName
      LIMIT :extensionLimit
    ];
  }

  /** Holds one immutable configuration snapshot. */
  public class Configuration {
    public BulkRecordUploadProcessConfig process { get; private set; }
    public List<BulkRecordUploadFieldConfig> fields { get; private set; }
    public List<BulkRecordUploadExtensionConfig> extensions {
      get;
      private set;
    }

    private Configuration(
      BulkRecordUploadProcessConfig process,
      List<BulkRecordUploadFieldConfig> fields,
      List<BulkRecordUploadExtensionConfig> extensions
    ) {
      this.process = process;
      this.fields = new List<BulkRecordUploadFieldConfig>(fields);
      this.extensions = new List<BulkRecordUploadExtensionConfig>(extensions);
    }

    /** @return A defensive copy of ordered field configuration. */
    public List<BulkRecordUploadFieldConfig> getFields() {
      return new List<BulkRecordUploadFieldConfig>(fields);
    }

    /** @return A defensive copy of ordered extension configuration. */
    public List<BulkRecordUploadExtensionConfig> getExtensions() {
      return new List<BulkRecordUploadExtensionConfig>(extensions);
    }
  }
}
