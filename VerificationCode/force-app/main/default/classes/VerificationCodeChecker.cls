/**
 * Flow action called at the very start of the Login Flow.
 *
 * Checks whether the authenticating user has recently exhausted their
 * verification attempts (Attempt_Count >= MAX_ATTEMPTS on a record created
 * within the last 30 minutes). If so, the flow routes directly to the
 * blocked screen without generating a new code, preventing a refresh from
 * giving the user a fresh set of attempts.
 *
 * Runs WITHOUT SHARING so the query works regardless of OWD (Private).
 */
public without sharing class VerificationCodeChecker {

    // How long a block lasts after max attempts are exhausted (minutes)
    @TestVisible public static final Integer BLOCK_DURATION_MINUTES = 10;

    public class CheckRequest {
        @InvocableVariable(label='User Id' required=true)
        public String userId;
    }

    public class CheckResult {
        @InvocableVariable(label='Is Blocked')
        public Boolean isBlocked;
    }

    @InvocableMethod(
        label       = 'Check If User Is Verification Blocked'
        description = 'Returns isBlocked=true if the user has a recent Verification_Code__c record with Attempt_Count >= MAX_ATTEMPTS. Used at flow start so a page refresh does not reset the block.'
        callout     = false
    )
    public static List<CheckResult> checkIfBlocked(List<CheckRequest> requests) {
        List<CheckResult> results = new List<CheckResult>();
        for (CheckRequest req : requests) {
            CheckResult res = new CheckResult();
            res.isBlocked = false;

            if (String.isNotBlank(req.userId)) {
                DateTime cutoff = DateTime.now().addMinutes(-BLOCK_DURATION_MINUTES);
                List<Verification_Code__c> blocked = [
                    SELECT Id
                    FROM   Verification_Code__c
                    WHERE  User__c           = :req.userId
                    AND    Attempt_Count__c  >= :VerificationCodeService.MAX_ATTEMPTS
                    AND    Is_Used__c        = true
                    AND    CreatedDate       >= :cutoff
                    LIMIT  1
                ];
                res.isBlocked = !blocked.isEmpty();
            }
            results.add(res);
        }
        return results;
    }
}
