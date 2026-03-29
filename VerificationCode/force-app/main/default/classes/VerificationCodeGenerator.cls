/**
 * Flow-callable action that generates and emails a verification code.
 *
 * Salesforce allows only one @InvocableMethod per class, so this class is a
 * thin wrapper that delegates all logic to VerificationCodeService.
 *
 * Referenced in the Flow as action: VerificationCodeGenerator
 */
public without sharing class VerificationCodeGenerator {

    public class GenerateRequest {
        @InvocableVariable(label='User Id' required=true)
        public String userId;

        @InvocableVariable(label='User Email' required=true)
        public String userEmail;

        @InvocableVariable(label='User Full Name' required=false)
        public String userName;
    }

    public class GenerateResult {
        @InvocableVariable(label='Success')
        public Boolean isSuccess;

        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }

    @InvocableMethod(
        label       = 'Generate and Send Verification Code'
        description = 'Generates a 6-digit code, stores its hash in Verification_Code__c, and emails the plain code to the user. Any previous active codes for the user are invalidated.'
        callout     = false
    )
    public static List<GenerateResult> generateAndSendCode(List<GenerateRequest> requests) {
        List<GenerateResult> results = new List<GenerateResult>();
        for (GenerateRequest req : requests) {
            VerificationCodeService.GenerateResult svcResult =
                VerificationCodeService.generateAndSendCode(req.userId, req.userEmail, req.userName);

            GenerateResult out = new GenerateResult();
            out.isSuccess    = svcResult.isSuccess;
            out.errorMessage = svcResult.errorMessage;
            results.add(out);
        }
        return results;
    }
}
