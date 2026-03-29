/**
 * Core service for the login verification code flow.
 *
 * Contains all business logic. Called by two thin @InvocableMethod wrapper classes
 * (VerificationCodeGenerator and VerificationCodeValidator) because Salesforce only
 * allows one @InvocableMethod annotation per class.
 *
 * Runs WITHOUT SHARING so records can be read/written regardless of the
 * logging-in user's object permissions – the user has not fully entered the
 * org yet when this executes inside a Login Flow.
 */
public without sharing class VerificationCodeService {

    // ─── Constants ────────────────────────────────────────────────────────────

    @TestVisible public static final Integer CODE_LENGTH    = 6;
    @TestVisible public static final Integer EXPIRY_MINUTES = 5;
    @TestVisible public static final Integer MAX_ATTEMPTS   = 3;

    // Status tokens returned to the flow
    public static final String STATUS_SUCCESS         = 'SUCCESS';
    public static final String STATUS_INVALID_CODE    = 'INVALID_CODE';
    public static final String STATUS_MAX_ATTEMPTS    = 'MAX_ATTEMPTS_EXCEEDED';
    public static final String STATUS_EXPIRED         = 'EXPIRED';
    public static final String STATUS_NO_PENDING_CODE = 'NO_PENDING_CODE';
    public static final String STATUS_ERROR           = 'ERROR';

    // ─── generateAndSendCode ──────────────────────────────────────────────────

    /**
     * Generates a 6-digit code, stores its hash, invalidates old codes, and
     * sends the plain code to the user via email.
     */
    public static GenerateResult generateAndSendCode(String userId, String userEmail, String userName) {
        GenerateResult res = new GenerateResult();
        try {
            if (String.isBlank(userId) || String.isBlank(userEmail)) {
                res.isSuccess    = false;
                res.errorMessage = 'User ID and email are required.';
                return res;
            }

            // Invalidate all existing active codes for this user
            List<Verification_Code__c> existing = [
                SELECT Id
                FROM   Verification_Code__c
                WHERE  User__c    = :userId
                AND    Is_Used__c = false
                FOR UPDATE
            ];
            if (!existing.isEmpty()) {
                for (Verification_Code__c vc : existing) {
                    vc.Is_Used__c = true;
                }
                update existing;
            }

            // Generate cryptographically random numeric code
            String plainCode = generateRandomCode();

            // Store only the SHA-256 hash – plain text is never persisted
            String codeHash = hashCode(plainCode);

            insert new Verification_Code__c(
                User__c          = userId,
                Code_Hash__c     = codeHash,
                Expiry_Time__c   = DateTime.now().addMinutes(EXPIRY_MINUTES),
                Attempt_Count__c = 0,
                Is_Used__c       = false
            );

            sendVerificationEmail(userEmail, userName, plainCode);

            res.isSuccess    = true;
            res.errorMessage = null;

        } catch (Exception ex) {
            res.isSuccess    = false;
            res.errorMessage = ex.getMessage();
        }
        return res;
    }

    // ─── validateCode ─────────────────────────────────────────────────────────

    /**
     * Validates the code entered by the user. Tracks wrong attempts and
     * permanently closes the code record after success or max failures.
     */
    public static ValidateResult validateCode(String userId, String enteredCode) {
        ValidateResult res = new ValidateResult();
        try {
            if (String.isBlank(userId) || String.isBlank(enteredCode)) {
                res.status           = STATUS_ERROR;
                res.attemptsRemaining = MAX_ATTEMPTS;
                res.errorMessage     = 'User ID and entered code are required.';
                return res;
            }

            // Two-step: find the latest record id first (ORDER BY not allowed with FOR UPDATE),
            // then re-query with row lock using the specific Id.
            List<Verification_Code__c> latest = [
                SELECT Id
                FROM   Verification_Code__c
                WHERE  User__c    = :userId
                AND    Is_Used__c = false
                ORDER BY CreatedDate DESC
                LIMIT  1
            ];
            if (latest.isEmpty()) {
                res.status           = STATUS_NO_PENDING_CODE;
                res.attemptsRemaining = 0;
                res.errorMessage     = 'No active verification code found. Please request a new code.';
                return res;
            }
            List<Verification_Code__c> records = [
                SELECT Id, Code_Hash__c, Expiry_Time__c, Attempt_Count__c, Is_Used__c
                FROM   Verification_Code__c
                WHERE  Id = :latest[0].Id
                FOR UPDATE
            ];

            Verification_Code__c record = records[0];

            // Expiry check
            if (DateTime.now() > record.Expiry_Time__c) {
                record.Is_Used__c = true;
                update record;
                res.status           = STATUS_EXPIRED;
                res.attemptsRemaining = 0;
                res.errorMessage     = 'Your verification code has expired. A new code will be sent.';
                return res;
            }

            // Defensive guard: already at or beyond max attempts
            if (record.Attempt_Count__c >= MAX_ATTEMPTS) {
                record.Is_Used__c = true;
                update record;
                res.status           = STATUS_MAX_ATTEMPTS;
                res.attemptsRemaining = 0;
                res.errorMessage     = 'Maximum verification attempts reached. Please log in again.';
                return res;
            }

            // Hash comparison
            String enteredHash = hashCode(enteredCode.trim());
            if (enteredHash == record.Code_Hash__c) {
                record.Is_Used__c = true;
                update record;
                res.status           = STATUS_SUCCESS;
                res.attemptsRemaining = MAX_ATTEMPTS;
                res.errorMessage     = null;
            } else {
                record.Attempt_Count__c = (record.Attempt_Count__c == null ? 0 : record.Attempt_Count__c) + 1;
                Integer used      = (Integer) record.Attempt_Count__c;
                Integer remaining = MAX_ATTEMPTS - used;

                if (remaining <= 0) {
                    record.Is_Used__c = true;
                    update record;
                    res.status           = STATUS_MAX_ATTEMPTS;
                    res.attemptsRemaining = 0;
                    res.errorMessage     = 'Maximum verification attempts reached. Please log in again.';
                } else {
                    update record;
                    res.status           = STATUS_INVALID_CODE;
                    res.attemptsRemaining = remaining;
                    res.errorMessage     = 'Incorrect code. You have ' + remaining + ' attempt(s) remaining.';
                }
            }

        } catch (Exception ex) {
            res.status           = STATUS_ERROR;
            res.attemptsRemaining = 0;
            res.errorMessage     = ex.getMessage();
        }
        return res;
    }

    // ─── Result inner classes (shared by both wrapper classes) ───────────────

    public class GenerateResult {
        public Boolean isSuccess;
        public String  errorMessage;
    }

    public class ValidateResult {
        public String  status;
        public Integer attemptsRemaining;
        public String  errorMessage;
    }

    // ─── Private helpers ──────────────────────────────────────────────────────

    /**
     * Returns a zero-padded random numeric string of CODE_LENGTH digits.
     */
    @TestVisible
    public static String generateRandomCode() {
        Integer max  = (Integer) Math.pow(10, CODE_LENGTH);
        Integer raw  = Math.abs(Crypto.getRandomInteger());
        Integer code = Math.mod(raw, max);
        String  fmt  = String.valueOf(code);
        while (fmt.length() < CODE_LENGTH) {
            fmt = '0' + fmt;
        }
        return fmt;
    }

    /**
     * Returns the hex-encoded SHA-256 digest of the given plain-text value.
     */
    @TestVisible
    public static String hashCode(String plainCode) {
        Blob digest = Crypto.generateDigest('SHA-256', Blob.valueOf(plainCode));
        return EncodingUtil.convertToHex(digest);
    }

    /**
     * Sends an HTML + plain-text verification email to the user.
     */
    @TestVisible
    public static void sendVerificationEmail(String toAddress, String recipientName, String code) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{ toAddress });
        mail.setSubject('Your Salesforce Verification Code');
        mail.setSaveAsActivity(false);

        String greeting = String.isNotBlank(recipientName) ? 'Hi ' + recipientName + ',' : 'Hello,';

        mail.setPlainTextBody(
            greeting + '\n\n' +
            'Your Salesforce login verification code is:\n\n' +
            '    ' + code + '\n\n' +
            'This code is valid for ' + EXPIRY_MINUTES + ' minutes. ' +
            'Do not share it with anyone.\n\n' +
            'If you did not request this code, contact your system administrator immediately.\n\n' +
            'Salesforce Security Team'
        );

        mail.setHtmlBody(
            '<html><body style="font-family:Arial,sans-serif;color:#333;">' +
            '<p>' + greeting + '</p>' +
            '<p>Your Salesforce login verification code is:</p>' +
            '<div style="font-size:32px;font-weight:bold;letter-spacing:8px;' +
            'color:#1a1a1a;background:#f4f4f4;padding:16px 24px;' +
            'border-radius:6px;display:inline-block;margin:8px 0;">' +
            code +
            '</div>' +
            '<p>This code is valid for <strong>' + EXPIRY_MINUTES + ' minutes</strong>.</p>' +
            '<p style="color:#888;font-size:12px;">Do not share this code with anyone. ' +
            'If you did not request it, contact your administrator immediately.</p>' +
            '</body></html>'
        );

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
    }
}