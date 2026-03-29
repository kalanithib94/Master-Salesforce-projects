/**
 * Schedulable batch job that deletes Verification_Code__c records older than
 * 24 hours.  Run once via Anonymous Apex after deploying:
 *
 *   System.schedule('VerificationCode Cleanup', '0 0 2 * * ?', new VerificationCodeCleanup());
 *
 * This keeps the custom object table lean and avoids storage accumulation.
 * It runs WITHOUT SHARING to guarantee deletion regardless of OWD (Private).
 */
public without sharing class VerificationCodeCleanup implements Schedulable, Database.Batchable<SObject> {

    @TestVisible private static final Integer RETENTION_HOURS = 24;

    // ─── Schedulable ──────────────────────────────────────────────────────────

    public void execute(SchedulableContext ctx) {
        Database.executeBatch(new VerificationCodeCleanup(), 200);
    }

    // ─── Batchable ────────────────────────────────────────────────────────────

    public Database.QueryLocator start(Database.BatchableContext ctx) {
        DateTime cutoff = DateTime.now().addHours(-RETENTION_HOURS);
        return Database.getQueryLocator([
            SELECT Id
            FROM   Verification_Code__c
            WHERE  CreatedDate < :cutoff
        ]);
    }

    public void execute(Database.BatchableContext ctx, List<Verification_Code__c> scope) {
        delete scope;
    }

    public void finish(Database.BatchableContext ctx) {
        // No post-processing needed
    }
}
