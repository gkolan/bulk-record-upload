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
  System.debug('Bulk Record Upload daily maintenance is not scheduled.');
} else {
  System.abortJob(bruMaintenanceSchedules[0].Id);
  System.debug('Bulk Record Upload daily maintenance unscheduled.');
}
