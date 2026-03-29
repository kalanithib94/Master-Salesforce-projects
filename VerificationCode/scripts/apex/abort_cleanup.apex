// Abort the scheduled cleanup job so classes can be redeployed
List<CronTrigger> jobs = [
    SELECT Id, CronJobDetail.Name
    FROM CronTrigger
    WHERE CronJobDetail.Name = 'VerificationCode Cleanup'
];
for (CronTrigger ct : jobs) {
    System.abortJob(ct.Id);
    System.debug('Aborted job: ' + ct.Id);
}
// Also abort any pending async apex jobs
List<AsyncApexJob> asyncJobs = [
    SELECT Id, Status, ApexClass.Name
    FROM AsyncApexJob
    WHERE ApexClass.Name = 'VerificationCodeCleanup'
    AND Status IN ('Queued', 'Processing', 'Preparing')
];
for (AsyncApexJob j : asyncJobs) {
    System.abortJob(j.Id);
    System.debug('Aborted async job: ' + j.Id);
}
System.debug('Done. Jobs aborted: ' + jobs.size() + ' async: ' + asyncJobs.size());
