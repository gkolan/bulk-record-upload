/** Resolves active upload processes for the component selector. */
public with sharing class BulkRecordUploadSelectionService {
  private static final String MODE_SELECTED = 'SELECTED_PROCESS';
  private static final String MODE_BUNDLE = 'CONFIGURED_PROCESSES';
  private static final String MODE_ALL = 'ALL_ACTIVE_FOR_OBJECT';
  @TestVisible
  private static Map<String, Bulk_Record_Upload_Process__mdt> processOverride;
  @TestVisible
  private static Map<String, Bulk_Record_Upload_Bundle__mdt> bundleOverride;
  @TestVisible
  private static Map<String, Bulk_Record_Upload_Bundle_Process__mdt> assignmentOverride;
  @TestVisible
  /**
   * Returns the active processes assigned to one administrator-selected bundle.
   * @param bundleDeveloperName Developer Name of the configured bundle.
   * @return Bundle-scoped process choices in configured display order.
   */
  /**
   * Resolves one allowlisted App Builder process-scope mode.
   * @param selectionMode Selected process, configured processes, or all active for object.
   * @param selectedProcessDeveloperName Fixed process Developer Name.
   * @param bundleDeveloperName Configured bundle Developer Name.
   * @param objectApiName Lightning page object API name when available.
   * @return Authorized process choices bounded by the runtime contract.
   */
  public BulkRecordUploadSelection resolve(
    String selectionMode,
    String selectedProcessDeveloperName,
    String bundleDeveloperName,
    String objectApiName
  ) {
    new BulkRecordUploadAccessPolicy().requireRunPermission();
    String mode = selectionMode?.trim().toUpperCase();
    if (mode == MODE_SELECTED) {
      return selectedProcess(selectedProcessDeveloperName, objectApiName);
    }
    if (mode == MODE_ALL) {
      return allActiveProcesses(objectApiName);
    }
    if (mode != MODE_BUNDLE) {
      throw new BulkRecordUploadException(
        'The process selection mode is invalid.'
      );
    }
    return configuredProcesses(bundleDeveloperName);
  }

  private BulkRecordUploadSelection configuredProcesses(
    String bundleDeveloperName
  ) {
    String bundleName = bundleDeveloperName?.trim();
    Bulk_Record_Upload_Bundle__mdt bundle = bundles().get(bundleName);
    if (String.isBlank(bundleName) || bundle?.IsActive__c != true) {
      throw new BulkRecordUploadException(
        'The configured upload bundle is unavailable.'
      );
    }
    List<BulkRecordUploadProcessOption> options = new List<BulkRecordUploadProcessOption>();
    List<AssignmentOption> orderedAssignments = new List<AssignmentOption>();
    for (
      Bulk_Record_Upload_Bundle_Process__mdt assignment : assignments().values()
    ) {
      if (
        assignment?.IsActive__c == true &&
        assignment.BundleDeveloperName__c == bundleName &&
        !String.isBlank(assignment.ProcessDeveloperName__c)
      ) {
        orderedAssignments.add(new AssignmentOption(assignment));
      }
    }
    orderedAssignments.sort();
    if (
      orderedAssignments.size() >
      BulkRecordUploadRuntimeContract.MAX_PROCESS_OPTIONS
    ) {
      throw new BulkRecordUploadException(
        'Too many upload processes are assigned to this bundle.'
      );
    }
    Set<String> includedProcessNames = new Set<String>();
    for (AssignmentOption orderedAssignment : orderedAssignments) {
      Bulk_Record_Upload_Process__mdt process = processes()
        .get(orderedAssignment.processName);
      if (
        isActive(process) &&
        isAuthorized(process.DeveloperName) &&
        includedProcessNames.add(process.DeveloperName)
      ) {
        options.add(option(process));
      }
    }
    if (options.isEmpty()) {
      throw new BulkRecordUploadException(
        'No active upload process is available.'
      );
    }
    return new BulkRecordUploadSelection('AVAILABLE', null, options);
  }

  private BulkRecordUploadSelection selectedProcess(
    String selectedProcessDeveloperName,
    String objectApiName
  ) {
    String processName = selectedProcessDeveloperName?.trim();
    Bulk_Record_Upload_Process__mdt process = processes().get(processName);
    if (!isSelectable(process, objectApiName)) {
      throw new BulkRecordUploadException(
        'The configured upload process is unavailable.'
      );
    }
    return new BulkRecordUploadSelection(
      'AVAILABLE',
      null,
      new List<BulkRecordUploadProcessOption>{ option(process) }
    );
  }

  private BulkRecordUploadSelection allActiveProcesses(String objectApiName) {
    List<ProcessChoice> choices = new List<ProcessChoice>();
    for (Bulk_Record_Upload_Process__mdt process : processes().values()) {
      if (isSelectable(process, objectApiName)) {
        choices.add(new ProcessChoice(process));
      }
    }
    choices.sort();
    if (choices.isEmpty()) {
      throw new BulkRecordUploadException(
        'No active upload process is available.'
      );
    }
    if (choices.size() > BulkRecordUploadRuntimeContract.MAX_PROCESS_OPTIONS) {
      throw new BulkRecordUploadException(
        'Too many active upload processes are available for this object.'
      );
    }
    List<BulkRecordUploadProcessOption> options = new List<BulkRecordUploadProcessOption>();
    for (ProcessChoice choice : choices) {
      options.add(choice.option());
    }
    return new BulkRecordUploadSelection('AVAILABLE', null, options);
  }

  private static Boolean isSelectable(
    Bulk_Record_Upload_Process__mdt process,
    String objectApiName
  ) {
    if (!isActive(process) || !isAuthorized(process.DeveloperName)) {
      return false;
    }
    if (String.isBlank(objectApiName)) {
      return true;
    }
    String configuredObject = String.isBlank(process.HostObjectApiName__c)
      ? process.ObjectApiName__c
      : process.HostObjectApiName__c;
    return objectApiName.equalsIgnoreCase(configuredObject);
  }

  /**
   * Returns whether processKey is an active member of an active bundle, so
   * server-side submission can be scoped the same as the picker presents it.
   */
  public static Boolean isProcessInActiveBundle(
    String processKey,
    String bundleDeveloperName
  ) {
    String bundleName = bundleDeveloperName?.trim();
    Bulk_Record_Upload_Bundle__mdt bundle = bundles().get(bundleName);
    if (String.isBlank(bundleName) || bundle?.IsActive__c != true) {
      return false;
    }
    for (
      Bulk_Record_Upload_Bundle_Process__mdt assignment : assignments().values()
    ) {
      if (
        assignment?.IsActive__c == true &&
        assignment.BundleDeveloperName__c == bundleName &&
        assignment.ProcessDeveloperName__c?.trim() == processKey
      ) {
        return true;
      }
    }
    return false;
  }

  private static Boolean isActive(Bulk_Record_Upload_Process__mdt process) {
    return process != null &&
      process.IsActive__c == true &&
      (process.ConfigurationVersion__c == 1 ||
      process.ConfigurationVersion__c == 2);
  }

  private static Boolean isAuthorized(String processKey) {
    if (processOverride != null) {
      return true;
    }
    try {
      new BulkRecordUploadProjectionService().getProjection(processKey);
      return true;
    } catch (BulkRecordUploadException error) {
      return false;
    }
  }

  private static BulkRecordUploadProcessOption option(
    Bulk_Record_Upload_Process__mdt process
  ) {
    return new BulkRecordUploadProcessOption(
      displayLabel(process.MasterLabel, process.DeveloperName),
      process.DeveloperName
    );
  }

  private static String displayLabel(String label, String fallback) {
    return String.isBlank(label) ? fallback : label.trim();
  }

  private static Map<String, Bulk_Record_Upload_Process__mdt> processes() {
    return processOverride == null
      ? Bulk_Record_Upload_Process__mdt.getAll()
      : processOverride;
  }

  private static Map<String, Bulk_Record_Upload_Bundle__mdt> bundles() {
    return bundleOverride == null
      ? Bulk_Record_Upload_Bundle__mdt.getAll()
      : bundleOverride;
  }

  private static Map<String, Bulk_Record_Upload_Bundle_Process__mdt> assignments() {
    return assignmentOverride == null
      ? Bulk_Record_Upload_Bundle_Process__mdt.getAll()
      : assignmentOverride;
  }

  private class AssignmentOption implements Comparable {
    private Decimal displayOrder;
    private String processName;

    private AssignmentOption(
      Bulk_Record_Upload_Bundle_Process__mdt assignment
    ) {
      displayOrder = assignment.DisplayOrder__c;
      processName = assignment.ProcessDeveloperName__c?.trim();
    }

    public Integer compareTo(Object comparison) {
      AssignmentOption other = (AssignmentOption) comparison;
      Decimal leftOrder = displayOrder == null
        ? Decimal.valueOf('999999')
        : displayOrder;
      Decimal rightOrder = other.displayOrder == null
        ? Decimal.valueOf('999999')
        : other.displayOrder;
      Integer orderComparison = leftOrder == rightOrder
        ? 0
        : (leftOrder < rightOrder ? -1 : 1);
      return orderComparison == 0
        ? processName.compareTo(other.processName)
        : orderComparison;
    }
  }

  private class ProcessChoice implements Comparable {
    private String label;
    private String value;

    private ProcessChoice(Bulk_Record_Upload_Process__mdt process) {
      value = process.DeveloperName;
      label = displayLabel(process.MasterLabel, value);
    }

    public Integer compareTo(Object comparison) {
      ProcessChoice other = (ProcessChoice) comparison;
      Integer labelOrder = label.compareTo(other.label);
      return labelOrder == 0 ? value.compareTo(other.value) : labelOrder;
    }

    private BulkRecordUploadProcessOption option() {
      return new BulkRecordUploadProcessOption(label, value);
    }
  }
}
