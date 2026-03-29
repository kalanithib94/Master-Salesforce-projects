/**
 * Flow-callable action that validates the code entered by the user.
 *
 * Salesforce allows only one @InvocableMethod per class, so this class is a
 * thin wrapper that delegates all logic to VerificationCodeService.
 *
 * Referenced in the Flow as action: VerificationCodeValidator
 */
public without sharing class VerificationCodeValidator {

    public class ValidateRequest {
        @InvocableVariable(label='User Id' required=true)
        public String userId;

        @InvocableVariable(label='Entered Code' required=true)
        public String enteredCode;
    }

    public class ValidateResult {
        @InvocableVariable(label='Status')
        public String status;

        @InvocableVariable(label='Attempts Remaining')
        public Integer attemptsRemaining;

        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }

    @InvocableMethod(
        label       = 'Validate Verification Code'
        description = 'Validates the code entered by the user. Tracks wrong attempts and blocks after 3 failures, returning SUCCESS, INVALID_CODE, MAX_ATTEMPTS_EXCEEDED, EXPIRED, or ERROR.'
        callout     = false
    )
    public static List<ValidateResult> validateCode(List<ValidateRequest> requests) {
        List<ValidateResult> results = new List<ValidateResult>();
        for (ValidateRequest req : requests) {
            VerificationCodeService.ValidateResult svcResult =
                VerificationCodeService.validateCode(req.userId, req.enteredCode);

            ValidateResult out = new ValidateResult();
            out.status           = svcResult.status;
            out.attemptsRemaining = svcResult.attemptsRemaining;
            out.errorMessage     = svcResult.errorMessage;
            results.add(out);
        }
        return results;
    }
}
