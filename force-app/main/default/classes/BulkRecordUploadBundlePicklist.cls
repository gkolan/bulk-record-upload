/** Supplies record-page-compatible upload bundles to Lightning App Builder. */
// VisualEditor.DynamicPickList must be global for Lightning App Builder.
// code-analyzer-suppress-next-line AvoidGlobalModifier
global with sharing class BulkRecordUploadBundlePicklist extends VisualEditor.DynamicPickList {
  private final VisualEditor.DesignTimePageContext context;

  global BulkRecordUploadBundlePicklist(
    VisualEditor.DesignTimePageContext context
  ) {
    this.context = context;
  }

  /**
   * Selects the sole compatible active bundle, while leaving ambiguous choices blank.
   * @return The sole compatible bundle or null.
   */
  global override VisualEditor.DataRow getDefaultValue() {
    List<BundleOption> options = scopedOptions();
    return options.size() == 1 ? options[0].row() : null;
  }

  /**
   * Returns active bundles compatible with the FlexiPage object.
   * @return App Builder rows whose stored value is the bundle Developer Name.
   */
  global override VisualEditor.DynamicPickListRows getValues() {
    VisualEditor.DynamicPickListRows rows = new VisualEditor.DynamicPickListRows();
    for (BundleOption option : scopedOptions()) {
      rows.addRow(option.row());
    }
    return rows;
  }

  private List<BundleOption> scopedOptions() {
    String entityName = context == null ? null : context.entityName;
    Set<String> compatibleNames = compatibleBundleNames(entityName);
    List<BundleOption> options = new List<BundleOption>();
    for (
      Bulk_Record_Upload_Bundle__mdt bundle : Bulk_Record_Upload_Bundle__mdt.getAll()
        .values()
    ) {
      if (
        bundle?.IsActive__c == true &&
        (String.isBlank(entityName) ||
        compatibleNames.contains(bundle.DeveloperName))
      ) {
        options.add(new BundleOption(bundle));
      }
    }
    options.sort();
    return options;
  }

  private Set<String> compatibleBundleNames(String entityName) {
    Set<String> compatibleNames = new Set<String>();
    if (String.isBlank(entityName)) {
      return compatibleNames;
    }
    Map<String, Bulk_Record_Upload_Process__mdt> processes = Bulk_Record_Upload_Process__mdt.getAll();
    for (
      Bulk_Record_Upload_Bundle_Process__mdt assignment : Bulk_Record_Upload_Bundle_Process__mdt.getAll()
        .values()
    ) {
      Bulk_Record_Upload_Process__mdt process = processes.get(
        assignment?.ProcessDeveloperName__c
      );
      if (
        assignment?.IsActive__c == true &&
        process?.IsActive__c == true &&
        appliesToEntity(process, entityName)
      ) {
        compatibleNames.add(assignment.BundleDeveloperName__c);
      }
    }
    return compatibleNames;
  }

  private Boolean appliesToEntity(
    Bulk_Record_Upload_Process__mdt process,
    String entityName
  ) {
    String configuredEntity = String.isBlank(process.HostObjectApiName__c)
      ? process.ObjectApiName__c
      : process.HostObjectApiName__c;
    return entityName.equalsIgnoreCase(configuredEntity);
  }

  private class BundleOption implements Comparable {
    private String label;
    private String value;

    private BundleOption(Bulk_Record_Upload_Bundle__mdt bundle) {
      value = bundle.DeveloperName;
      label = String.isBlank(bundle.MasterLabel)
        ? value
        : bundle.MasterLabel.trim();
    }

    public Integer compareTo(Object comparison) {
      BundleOption other = (BundleOption) comparison;
      Integer labelOrder = label.compareTo(other.label);
      return labelOrder == 0 ? value.compareTo(other.value) : labelOrder;
    }

    private VisualEditor.DataRow row() {
      return new VisualEditor.DataRow(label, value);
    }
  }
}
