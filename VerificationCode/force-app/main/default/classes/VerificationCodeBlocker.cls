/**
 * Flow action that intentionally throws an exception to BLOCK the Login Flow.
 *
 * In Salesforce Login Flows, a flow that faults (throws an unhandled exception)
 * NEVER grants the user access. This is the only reliable way to block login
 * from within a flow, because:
 *  - Completing the flow = user is logged in
 *  - Faulting the flow   = user is denied access, regardless of runtime
 *
 * This class is called on three blocking paths:
 *  1. No email on file
 *  2. Verification email could not be sent
 *  3. Maximum wrong attempts exceeded
 *
 * The Apex exception message becomes available as {!$Flow.FaultMessage} on
 * the flow's fault screen so the user sees a meaningful reason.
 */
public without sharing class VerificationCodeBlocker {

    public class BlockRequest {
        @InvocableVariable(label='Block Reason Message' required=false)
        public String message;
    }

    @InvocableMethod(
        label       = 'Block Login'
        description = 'Intentionally faults the Login Flow to deny access. Use on all blocking paths (no email, send failed, max attempts). The message is shown on the fault screen via $Flow.FaultMessage.'
        callout     = false
    )
    public static List<String> blockLogin(List<BlockRequest> requests) {
        String reason = (requests != null && !requests.isEmpty() && String.isNotBlank(requests[0].message))
            ? requests[0].message
            : 'Login verification failed. Please return to the login page and try again.';

        // Throwing an unhandled exception faults the Login Flow.
        // A faulted Login Flow NEVER grants the user a Salesforce session.
        throw new LoginBlockedException(reason);
    }

    public class LoginBlockedException extends Exception {}
}
