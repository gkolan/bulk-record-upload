/** Resolves active upload processes for the component selector. */
public with sharing class BulkRecordUploadSelectionService {
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
  public BulkRecordUploadSelection resolve(String bundleDeveloperName) {
    new BulkRecordUploadAccessPolicy().requireRunPermission();
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
    Set<String> includedProcessNames = new Set<String>();
    for (AssignmentOption orderedAssignment : orderedAssignments) {
      Bulk_Record_Upload_Process__mdt process = processes()
        .get(orderedAssignment.processName);
      if (
        isActive(process) && includedProcessNames.add(process.DeveloperName)
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

  private static Boolean isActive(Bulk_Record_Upload_Process__mdt process) {
    return process != null &&
      process.IsActive__c == true &&
      (process.ConfigurationVersion__c == 1 ||
      process.ConfigurationVersion__c == 2);
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
}
