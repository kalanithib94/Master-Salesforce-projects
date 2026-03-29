// Schedule the nightly cleanup job (runs at 2:00 AM daily)
// Only schedule if not already scheduled
List<CronTrigger> existing = [
    SELECT Id, CronJobDetail.Name
    FROM CronTrigger
    WHERE CronJobDetail.Name = 'VerificationCode Cleanup'
    LIMIT 1
];

if (existing.isEmpty()) {
    String jobId = System.schedule(
        'VerificationCode Cleanup',
        '0 0 2 * * ?',
        new VerificationCodeCleanup()
    );
    System.debug('Cleanup job scheduled. Job Id: ' + jobId);
} else {
    System.debug('Cleanup job already scheduled: ' + existing[0].Id);
}
