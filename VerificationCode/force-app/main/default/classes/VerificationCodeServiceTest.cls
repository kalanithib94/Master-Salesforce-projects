/**
 * Test class for VerificationCodeService, VerificationCodeGenerator,
 * and VerificationCodeValidator.
 *
 * Covers:
 *  - Code generation and email send (happy path)
 *  - Missing / blank input validation
 *  - Old codes are invalidated when a new one is generated
 *  - Successful validation on first attempt
 *  - Invalid code with decrementing attempts remaining
 *  - Lockout after MAX_ATTEMPTS wrong entries (pre-seeded and natural)
 *  - Defensive guard when attempt count is already at MAX
 *  - Expired code handling
 *  - No pending code edge case
 *  - generateRandomCode format/length
 *  - hashCode determinism and collision resistance
 *  - Flow wrapper classes (Generator and Validator)
 */
@IsTest
private class VerificationCodeServiceTest {

    // ─── Test data ────────────────────────────────────────────────────────────

    private static User getTestUser() {
        return [SELECT Id, Email, Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    }

    // ─── VerificationCodeGenerator (wrapper) tests ────────────────────────────

    @IsTest
    static void testGenerator_HappyPath() {
        User u = getTestUser();

        VerificationCodeGenerator.GenerateRequest req = new VerificationCodeGenerator.GenerateRequest();
        req.userId    = u.Id;
        req.userEmail = u.Email;
        req.userName  = u.Name;

        Test.startTest();
        List<VerificationCodeGenerator.GenerateResult> results =
            VerificationCodeGenerator.generateAndSendCode(
                new List<VerificationCodeGenerator.GenerateRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(results[0].isSuccess, 'Generation should succeed');
        System.assert(String.isBlank(results[0].errorMessage));

        List<Verification_Code__c> records = [
            SELECT Id, Is_Used__c, Attempt_Count__c, Expiry_Time__c
            FROM   Verification_Code__c
            WHERE  User__c = :u.Id
        ];
        System.assertEquals(1, records.size(), 'One code record should be created');
        System.assert(!records[0].Is_Used__c);
        System.assertEquals(0, records[0].Attempt_Count__c);
        System.assert(records[0].Expiry_Time__c > DateTime.now());
    }

    @IsTest
    static void testGenerator_BlankInputs() {
        VerificationCodeGenerator.GenerateRequest req = new VerificationCodeGenerator.GenerateRequest();
        req.userId    = '';
        req.userEmail = '';

        Test.startTest();
        List<VerificationCodeGenerator.GenerateResult> results =
            VerificationCodeGenerator.generateAndSendCode(
                new List<VerificationCodeGenerator.GenerateRequest>{ req }
            );
        Test.stopTest();

        System.assert(!results[0].isSuccess);
        System.assert(String.isNotBlank(results[0].errorMessage));
    }

    @IsTest
    static void testGenerator_InvalidatesOldCode() {
        User u = getTestUser();

        insert new Verification_Code__c(
            User__c          = u.Id,
            Code_Hash__c     = 'aabb' + 'cc00'.repeat(15),
            Expiry_Time__c   = DateTime.now().addMinutes(5),
            Attempt_Count__c = 0,
            Is_Used__c       = false
        );

        VerificationCodeGenerator.GenerateRequest req = new VerificationCodeGenerator.GenerateRequest();
        req.userId    = u.Id;
        req.userEmail = u.Email;

        Test.startTest();
        VerificationCodeGenerator.generateAndSendCode(
            new List<VerificationCodeGenerator.GenerateRequest>{ req }
        );
        Test.stopTest();

        List<Verification_Code__c> all = [
            SELECT Is_Used__c FROM Verification_Code__c WHERE User__c = :u.Id ORDER BY CreatedDate ASC
        ];
        System.assertEquals(2, all.size());
        System.assert(all[0].Is_Used__c,  'Old code should be marked used');
        System.assert(!all[1].Is_Used__c, 'New code should be active');
    }

    // ─── VerificationCodeValidator (wrapper) tests ────────────────────────────

    @IsTest
    static void testValidator_Success() {
        User u   = getTestUser();
        String p = '123456';

        insert new Verification_Code__c(
            User__c          = u.Id,
            Code_Hash__c     = VerificationCodeService.hashCode(p),
            Expiry_Time__c   = DateTime.now().addMinutes(5),
            Attempt_Count__c = 0,
            Is_Used__c       = false
        );

        VerificationCodeValidator.ValidateRequest req = new VerificationCodeValidator.ValidateRequest();
        req.userId      = u.Id;
        req.enteredCode = p;

        Test.startTest();
        List<VerificationCodeValidator.ValidateResult> results =
            VerificationCodeValidator.validateCode(
                new List<VerificationCodeValidator.ValidateRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(VerificationCodeService.STATUS_SUCCESS, results[0].status);
        System.assert(String.isBlank(results[0].errorMessage));

        Verification_Code__c vc = [SELECT Is_Used__c FROM Verification_Code__c WHERE User__c = :u.Id LIMIT 1];
        System.assert(vc.Is_Used__c, 'Should be marked used after success');
    }

    @IsTest
    static void testValidator_WrongCode_AttemptsDecrement() {
        User u = getTestUser();

        insert new Verification_Code__c(
            User__c          = u.Id,
            Code_Hash__c     = VerificationCodeService.hashCode('999999'),
            Expiry_Time__c   = DateTime.now().addMinutes(5),
            Attempt_Count__c = 0,
            Is_Used__c       = false
        );

        VerificationCodeValidator.ValidateRequest req = new VerificationCodeValidator.ValidateRequest();
        req.userId      = u.Id;
        req.enteredCode = '000000';

        Test.startTest();
        List<VerificationCodeValidator.ValidateResult> results =
            VerificationCodeValidator.validateCode(
                new List<VerificationCodeValidator.ValidateRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(VerificationCodeService.STATUS_INVALID_CODE, results[0].status);
        System.assertEquals(VerificationCodeService.MAX_ATTEMPTS - 1, results[0].attemptsRemaining);
        System.assert(String.isNotBlank(results[0].errorMessage));
    }

    @IsTest
    static void testValidator_MaxAttempts_NaturalLockout() {
        User u = getTestUser();

        insert new Verification_Code__c(
            User__c          = u.Id,
            Code_Hash__c     = VerificationCodeService.hashCode('777777'),
            Expiry_Time__c   = DateTime.now().addMinutes(5),
            Attempt_Count__c = VerificationCodeService.MAX_ATTEMPTS - 1,
            Is_Used__c       = false
        );

        VerificationCodeValidator.ValidateRequest req = new VerificationCodeValidator.ValidateRequest();
        req.userId      = u.Id;
        req.enteredCode = '000000';

        Test.startTest();
        List<VerificationCodeValidator.ValidateResult> results =
            VerificationCodeValidator.validateCode(
                new List<VerificationCodeValidator.ValidateRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(VerificationCodeService.STATUS_MAX_ATTEMPTS, results[0].status);
        System.assertEquals(0, results[0].attemptsRemaining);

        Verification_Code__c vc = [SELECT Is_Used__c FROM Verification_Code__c WHERE User__c = :u.Id LIMIT 1];
        System.assert(vc.Is_Used__c, 'Must be closed after lockout');
    }

    @IsTest
    static void testValidator_DefensiveGuard_AlreadyMaxed() {
        User u = getTestUser();

        insert new Verification_Code__c(
            User__c          = u.Id,
            Code_Hash__c     = VerificationCodeService.hashCode('111111'),
            Expiry_Time__c   = DateTime.now().addMinutes(5),
            Attempt_Count__c = VerificationCodeService.MAX_ATTEMPTS,
            Is_Used__c       = false
        );

        VerificationCodeValidator.ValidateRequest req = new VerificationCodeValidator.ValidateRequest();
        req.userId      = u.Id;
        req.enteredCode = '111111';

        Test.startTest();
        List<VerificationCodeValidator.ValidateResult> results =
            VerificationCodeValidator.validateCode(
                new List<VerificationCodeValidator.ValidateRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(VerificationCodeService.STATUS_MAX_ATTEMPTS, results[0].status,
            'Defensive guard must block even if code matches but attempts are exhausted');
    }

    @IsTest
    static void testValidator_Expired() {
        User u = getTestUser();

        insert new Verification_Code__c(
            User__c          = u.Id,
            Code_Hash__c     = VerificationCodeService.hashCode('222222'),
            Expiry_Time__c   = DateTime.now().addMinutes(-1),
            Attempt_Count__c = 0,
            Is_Used__c       = false
        );

        VerificationCodeValidator.ValidateRequest req = new VerificationCodeValidator.ValidateRequest();
        req.userId      = u.Id;
        req.enteredCode = '222222';

        Test.startTest();
        List<VerificationCodeValidator.ValidateResult> results =
            VerificationCodeValidator.validateCode(
                new List<VerificationCodeValidator.ValidateRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(VerificationCodeService.STATUS_EXPIRED, results[0].status);
    }

    @IsTest
    static void testValidator_NoPendingCode() {
        User u = getTestUser();

        VerificationCodeValidator.ValidateRequest req = new VerificationCodeValidator.ValidateRequest();
        req.userId      = u.Id;
        req.enteredCode = '123456';

        Test.startTest();
        List<VerificationCodeValidator.ValidateResult> results =
            VerificationCodeValidator.validateCode(
                new List<VerificationCodeValidator.ValidateRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(VerificationCodeService.STATUS_NO_PENDING_CODE, results[0].status);
    }

    @IsTest
    static void testValidator_BlankInputs() {
        VerificationCodeValidator.ValidateRequest req = new VerificationCodeValidator.ValidateRequest();
        req.userId      = '';
        req.enteredCode = '';

        Test.startTest();
        List<VerificationCodeValidator.ValidateResult> results =
            VerificationCodeValidator.validateCode(
                new List<VerificationCodeValidator.ValidateRequest>{ req }
            );
        Test.stopTest();

        System.assertEquals(VerificationCodeService.STATUS_ERROR, results[0].status);
    }

    // ─── Helper method tests ──────────────────────────────────────────────────

    @IsTest
    static void testGenerateRandomCode_FormatAndLength() {
        Test.startTest();
        for (Integer i = 0; i < 20; i++) {
            String code = VerificationCodeService.generateRandomCode();
            System.assertEquals(VerificationCodeService.CODE_LENGTH, code.length(),
                'Code must be exactly CODE_LENGTH digits');
            System.assert(code.isNumeric(), 'Code must be numeric: ' + code);
        }
        Test.stopTest();
    }

    @IsTest
    static void testHashCode_Deterministic() {
        String h1 = VerificationCodeService.hashCode('123456');
        String h2 = VerificationCodeService.hashCode('123456');
        String h3 = VerificationCodeService.hashCode('654321');

        System.assertEquals(h1, h2, 'Same input must yield same hash');
        System.assertNotEquals(h1, h3, 'Different input must yield different hash');
        System.assertEquals(64, h1.length(), 'SHA-256 hex should be 64 chars');
    }

    @IsTest
    static void testBatchRequests_MultipleItems() {
        User u = getTestUser();

        VerificationCodeGenerator.GenerateRequest r1 = new VerificationCodeGenerator.GenerateRequest();
        r1.userId = u.Id; r1.userEmail = u.Email; r1.userName = 'Test User';

        VerificationCodeGenerator.GenerateRequest r2 = new VerificationCodeGenerator.GenerateRequest();
        r2.userId = u.Id; r2.userEmail = u.Email;

        Test.startTest();
        List<VerificationCodeGenerator.GenerateResult> results =
            VerificationCodeGenerator.generateAndSendCode(
                new List<VerificationCodeGenerator.GenerateRequest>{ r1, r2 }
            );
        Test.stopTest();

        System.assertEquals(2, results.size());
        for (VerificationCodeGenerator.GenerateResult r : results) {
            System.assert(r.isSuccess, 'Both requests should succeed');
        }
    }
}
