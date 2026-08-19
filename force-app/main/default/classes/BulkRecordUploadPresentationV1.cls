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

  /** Creates a bounded presentation DTO from process Custom Metadata values. */
  public BulkRecordUploadPresentationV1(
    String processKey,
    String subtitle,
    String instructions,
    String iconName
  ) {
    if (String.isBlank(processKey)) {
      throw new BulkRecordUploadException('Process key is required.');
    }
    this.processKey = processKey.trim();
    this.subtitle = trimToNull(subtitle);
    this.instructions = trimToNull(instructions);
    this.iconName = normalizeIcon(iconName);
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
