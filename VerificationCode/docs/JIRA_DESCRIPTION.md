# JIRA Ticket — Salesforce Login Email Verification (MFA via Login Flow)

## Summary
Implement email-based verification code as a second factor for all Salesforce logins, including SSO (Google SAML).

---

## Background
The org uses Google SAML for SSO but has no second-factor verification enforced at the Salesforce layer. Any authenticated user — SSO or standard — can reach the org without confirming their identity via a second channel.

---

## What Was Built

A Salesforce Login Flow that intercepts every login (post-authentication, pre-access) and requires the user to enter a 6-digit code sent to their registered email.

---

## Acceptance Criteria

- [x] A 6-digit code is emailed to the user on every login
- [x] Code expires after 5 minutes
- [x] User has 3 attempts to enter the correct code
- [x] After 3 wrong attempts — user is logged out and blocked for 10 minutes
- [x] Refreshing the page while blocked forces logout and destroys the session
- [x] Works for both SSO (Google SAML) and standard username/password login
- [x] Codes are stored as SHA-256 hashes — never plain text
- [x] 19/19 automated tests passing

---

## Technical Scope

| Component | Type | Purpose |
|---|---|---|
| `Verification_Code__c` | Custom Object | Stores hashed codes, expiry, attempt count |
| `VerificationCodeService` | Apex Class | Core logic — generate, email, validate |
| `VerificationCodeGenerator` | Apex Class | Flow-callable wrapper for code generation |
| `VerificationCodeValidator` | Apex Class | Flow-callable wrapper for code validation |
| `VerificationCodeChecker` | Apex Class | Checks if user is blocked at flow start (refresh guard) |
| `VerificationCodeCleanup` | Apex Class (Scheduled) | Deletes records older than 24 hours, runs at 2 AM daily |
| `VerificationCodeLoginFlow` | Screen Flow (Active) | Login Flow — drives the full verification UX |

---

## How Blocking Works

No dedicated "blocked" field. Block is inferred at runtime by `VerificationCodeChecker`, which queries for a `Verification_Code__c` record with `Attempt_Count >= 3`, `Is_Used = true`, created within the last **10 minutes**. If found → user is blocked → `LoginFlow_FinishLocation = /secur/logout.jsp` → session destroyed on flow completion.

To change the block duration: update `BLOCK_DURATION_MINUTES` constant in `VerificationCodeChecker.cls` and redeploy.

## How Session Destruction Works

`LoginFlow_FinishLocation` is a Salesforce Login Flow output variable. Every blocked path in the flow sets it to `/secur/logout.jsp` before routing to the blocked screen. When the user clicks OK, the flow completes and Salesforce reads this variable — sending the browser to the logout endpoint, which destroys the server-side session.

---

## Deployment Package

**File:** `deploy/VerificationCodeLoginFlow_Deploy.zip`
**API Version:** 62.0
**Contents:** 8 Apex classes + `Verification_Code__c` object (5 fields) + Login Flow

## Post-Deployment Manual Steps

1. **Setup → Flows** — verify flow status is **Active**
2. **Setup → Identity → Login Flows → New** — assign flow to standard login page
3. **Setup → Single Sign-On Settings → Edit** — assign flow to Google SAML config
4. **Developer Console → Execute Anonymous** — schedule the cleanup job:
```java
System.schedule('VerificationCodeCleanup Daily', '0 0 2 * * ?', new VerificationCodeCleanup());
```
