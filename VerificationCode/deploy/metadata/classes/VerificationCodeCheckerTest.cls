@IsTest
private class VerificationCodeCheckerTest {

    private static User getTestUser() {
        return [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    }

    @IsTest
    static void testNotBlocked_NoRecords() {
        User u = getTestUser();

        VerificationCodeChecker.CheckRequest req = new VerificationCodeChecker.CheckRequest();
        req.userId = u.Id;

        Test.startTest();
        List<VerificationCodeChecker.CheckResult> results =
            VerificationCodeChecker.checkIfBlocked(new List<VerificationCodeChecker.CheckRequest>{ req });
        Test.stopTest();

        System.assert(!results[0].isBlocked, 'No records = not blocked');
    }

    @IsTest
    static void testNotBlocked_ActiveCode() {
        User u = getTestUser();
        // Active code with fewer than MAX_ATTEMPTS
        insert new Verification_Code__c(
            User__c          = u.Id,
            Code_Hash__c     = VerificationCodeService.hashCode('123456'),
            Expiry_Time__c   = DateTime.now().addMinutes(5),
            Attempt_Count__c = 1,
            Is_Used__c       = false
        );

        VerificationCodeChecker.CheckRequest req = new VerificationCodeChecker.CheckRequest();
        req.userId = u.Id;

        Test.startTest();
        List<VerificationCodeChecker.CheckResult> results =
            VerificationCodeChecker.checkIfBlocked(new List<VerificationCodeChecker.CheckRequest>{ req });
        Test.stopTest();

        System.assert(!results[0].isBlocked, 'Under max attempts = not blocked');
    }

    @IsTest
    static void testBlocked_MaxAttemptsReached() {
        User u = getTestUser();
        insert new Verification_Code__c(
            User__c          = u.Id,
            Code_Hash__c     = VerificationCodeService.hashCode('999999'),
            Expiry_Time__c   = DateTime.now().addMinutes(-1),
            Attempt_Count__c = VerificationCodeService.MAX_ATTEMPTS,
            Is_Used__c       = true
        );

        VerificationCodeChecker.CheckRequest req = new VerificationCodeChecker.CheckRequest();
        req.userId = u.Id;

        Test.startTest();
        List<VerificationCodeChecker.CheckResult> results =
            VerificationCodeChecker.checkIfBlocked(new List<VerificationCodeChecker.CheckRequest>{ req });
        Test.stopTest();

        System.assert(results[0].isBlocked, 'Max attempts + Is_Used = blocked');
    }

    @IsTest
    static void testNotBlocked_BlankUserId() {
        VerificationCodeChecker.CheckRequest req = new VerificationCodeChecker.CheckRequest();
        req.userId = '';

        Test.startTest();
        List<VerificationCodeChecker.CheckResult> results =
            VerificationCodeChecker.checkIfBlocked(new List<VerificationCodeChecker.CheckRequest>{ req });
        Test.stopTest();

        System.assert(!results[0].isBlocked, 'Blank userId = not blocked');
    }
}
