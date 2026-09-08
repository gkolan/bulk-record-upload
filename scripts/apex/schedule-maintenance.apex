String bruMaintenanceJobName = 'Bulk Record Upload Daily Maintenance';
List<CronTrigger> bruMaintenanceSchedules = [
  SELECT Id
  FROM CronTrigger
  WHERE
    CronJobDetail.Name = :bruMaintenanceJobName
    AND State IN ('WAITING', 'ACQUIRED', 'PAUSED', 'BLOCKED', 'PAUSED_BLOCKED')
  LIMIT 1
];
if (bruMaintenanceSchedules.isEmpty()) {
  System.schedule(
    bruMaintenanceJobName,
    '0 0 2 * * ?',
    new BulkRecordUploadRetentionJob()
  );
  System.debug('Bulk Record Upload daily maintenance scheduled.');
} else {
  System.debug('Bulk Record Upload daily maintenance is already scheduled.');
}
