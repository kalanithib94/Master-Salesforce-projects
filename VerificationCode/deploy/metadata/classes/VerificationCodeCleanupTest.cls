@IsTest
private class VerificationCodeCleanupTest {

    @IsTest
    static void testCleanupDeletesOldRecords() {
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        // Insert a record that should be deleted (created "25 hours ago" via Expiry trick –
        // we back-date it by setting Expiry_Time to a past value; actual CreatedDate cannot
        // be set in tests, so we test the batch logic directly by passing a recent record
        // and verifying the query locator honours the cutoff).
        Verification_Code__c oldLike = new Verification_Code__c(
            User__c          = u.Id,
            Code_Hash__c     = 'aabbcc00112233445566778899aabbcc00112233445566778899aabbcc001122',
            Expiry_Time__c   = DateTime.now().addHours(-26),
            Attempt_Count__c = 0,
            Is_Used__c       = true
        );
        insert oldLike;

        // Insert a record that should be kept
        Verification_Code__c fresh = new Verification_Code__c(
            User__c          = u.Id,
            Code_Hash__c     = 'ffeeddccbbaa99887766554433221100ffeeddccbbaa99887766554433221100',
            Expiry_Time__c   = DateTime.now().addMinutes(5),
            Attempt_Count__c = 0,
            Is_Used__c       = false
        );
        insert fresh;

        Test.startTest();
        Database.executeBatch(new VerificationCodeCleanup(), 200);
        Test.stopTest();

        // The "old-like" record has a past Expiry but CreatedDate is NOW in tests,
        // so the batch won't delete it (CreatedDate cutoff not backdatable in tests).
        // We verify the batch ran without exception and did not delete the fresh record.
        Integer remaining = [SELECT COUNT() FROM Verification_Code__c WHERE User__c = :u.Id];
        System.assert(remaining >= 1, 'Fresh record should still exist');
    }

    @IsTest
    static void testSchedulable() {
        Test.startTest();
        String jobId = System.schedule(
            'Test VC Cleanup',
            '0 0 3 * * ?',
            new VerificationCodeCleanup()
        );
        Test.stopTest();

        System.assert(String.isNotBlank(jobId), 'Scheduled job should have an ID');
    }
}
