/** Supplies compatible active upload processes to Lightning App Builder. */
// VisualEditor.DynamicPickList must be global for Lightning App Builder.
// code-analyzer-suppress-next-line AvoidGlobalModifier
global with sharing class BulkRecordUploadProcessPicklist extends VisualEditor.DynamicPickList {
  private final VisualEditor.DesignTimePageContext context;

  global BulkRecordUploadProcessPicklist(
    VisualEditor.DesignTimePageContext context
  ) {
    this.context = context;
  }

  /** Returns the sole compatible process when exactly one is available. */
  global override VisualEditor.DataRow getDefaultValue() {
    List<ProcessOption> options = scopedOptions();
    return options.size() == 1 ? options[0].row() : null;
  }

  /** Returns active processes compatible with the page object. */
  global override VisualEditor.DynamicPickListRows getValues() {
    VisualEditor.DynamicPickListRows rows = new VisualEditor.DynamicPickListRows();
    for (ProcessOption option : scopedOptions()) {
      rows.addRow(option.row());
    }
    return rows;
  }

  private List<ProcessOption> scopedOptions() {
    String entityName = context == null ? null : context.entityName;
    List<ProcessOption> options = new List<ProcessOption>();
    for (
      Bulk_Record_Upload_Process__mdt process : Bulk_Record_Upload_Process__mdt.getAll()
        .values()
    ) {
      if (
        process?.IsActive__c == true && appliesToEntity(process, entityName)
      ) {
        options.add(new ProcessOption(process));
      }
    }
    options.sort();
    return options;
  }

  private static Boolean appliesToEntity(
    Bulk_Record_Upload_Process__mdt process,
    String entityName
  ) {
    if (String.isBlank(entityName)) {
      return true;
    }
    String configuredEntity = String.isBlank(process.HostObjectApiName__c)
      ? process.ObjectApiName__c
      : process.HostObjectApiName__c;
    return entityName.equalsIgnoreCase(configuredEntity);
  }

  private class ProcessOption implements Comparable {
    private String label;
    private String value;

    private ProcessOption(Bulk_Record_Upload_Process__mdt process) {
      value = process.DeveloperName;
      label = String.isBlank(process.MasterLabel)
        ? value
        : process.MasterLabel.trim();
    }

    public Integer compareTo(Object comparison) {
      ProcessOption other = (ProcessOption) comparison;
      Integer labelOrder = label.compareTo(other.label);
      return labelOrder == 0 ? value.compareTo(other.value) : labelOrder;
    }

    private VisualEditor.DataRow row() {
      return new VisualEditor.DataRow(label, value);
    }
  }
}
