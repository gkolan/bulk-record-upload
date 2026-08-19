/** Safe, compact presentation settings for one authorized upload process. */
public class BulkRecordUploadPresentationV1 {
  @AuraEnabled
  public String processKey { get; private set; }
  @AuraEnabled
  public String subtitle { get; private set; }
  @AuraEnabled
  public String instructions { get; private set; }
  @AuraEnabled
  public String iconName { get; private set; }
  @AuraEnabled
  public String recordContextAction { get; private set; }
  @AuraEnabled
  public String recordContextSource { get; private set; }
  @AuraEnabled
  public String hostObjectApiName { get; private set; }
  @AuraEnabled
  public String primarySearchField { get; private set; }
  @AuraEnabled
  public List<String> additionalSearchFields { get; private set; }
  @AuraEnabled
  public String primaryDisplayField { get; private set; }
  @AuraEnabled
  public List<String> additionalDisplayFields { get; private set; }
  @AuraEnabled
  public String filterCriteriaJson { get; private set; }

  /** Creates a bounded presentation DTO from process Custom Metadata values. */
  public BulkRecordUploadPresentationV1(
    String processKey,
    String subtitle,
    String instructions,
    String iconName
  ) {
    this(processKey, subtitle, instructions, iconName, null);
  }

  /** Creates a bounded presentation DTO including record-context picker settings. */
  public BulkRecordUploadPresentationV1(
    String processKey,
    String subtitle,
    String instructions,
    String iconName,
    BulkRecordUploadProjectionV1 projection
  ) {
    if (String.isBlank(processKey)) {
      throw new BulkRecordUploadException('Process key is required.');
    }
    this.processKey = processKey.trim();
    this.subtitle = trimToNull(subtitle);
    this.instructions = trimToNull(instructions);
    this.iconName = normalizeIcon(iconName);
    this.recordContextAction = projection == null
      ? 'NONE'
      : projection.recordContextAction;
    this.hostObjectApiName = projection == null
      ? null
      : projection.hostObjectApiName;
    BulkRecordUploadContextProjectionV1 contextProjection = projection == null
      ? null
      : projection.contextProjection;
    this.recordContextSource = contextProjection == null
      ? 'PAGE'
      : contextProjection.recordContextSource;
    this.primarySearchField = contextProjection == null
      ? null
      : contextProjection.primarySearchField;
    this.additionalSearchFields = contextProjection == null
      ? new List<String>()
      : contextProjection.additionalSearchFields;
    this.primaryDisplayField = contextProjection == null
      ? null
      : contextProjection.primaryDisplayField;
    this.additionalDisplayFields = contextProjection == null
      ? new List<String>()
      : contextProjection.additionalDisplayFields;
    this.filterCriteriaJson = contextProjection == null
      ? null
      : toFilterJson(contextProjection.filterConditions);
  }

  private static String toFilterJson(
    List<BulkRecordUploadContextFilterConditionV1> conditions
  ) {
    if (conditions == null || conditions.isEmpty()) {
      return null;
    }
    List<Map<String, Object>> criteria = new List<Map<String, Object>>();
    for (BulkRecordUploadContextFilterConditionV1 condition : conditions) {
      String operator = condition.operatorCode == '='
        ? 'eq'
        : condition.operatorCode == '!=' ? 'ne' : 'in';
      Object value = condition.operatorCode == 'IN'
        ? (Object) condition.values
        : (Object) condition.values[0];
      criteria.add(
        new Map<String, Object>{
          'fieldPath' => condition.fieldApiName,
          'operator' => operator,
          'value' => value
        }
      );
    }
    return JSON.serialize(
      new Map<String, Object>{ 'criteria' => criteria, 'filterLogic' => 'and' }
    );
  }

  private static String trimToNull(String value) {
    return String.isBlank(value) ? null : value.trim();
  }

  private static String normalizeIcon(String value) {
    String normalized = trimToNull(value);
    return normalized != null &&
      Pattern.matches(
        '^(utility|standard|custom|doctype|action):[a-z0-9_]+$',
        normalized
      )
      ? normalized
      : 'utility:upload';
  }
}
