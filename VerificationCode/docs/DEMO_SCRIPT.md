# Demo Script — Salesforce Login Email Verification

**Audience:** Stakeholders / Reviewers
**Duration:** ~10 minutes
**Prerequisites:** Solution deployed, Login Flow assigned to Standard Login and SSO

---

## Setup Before the Demo

- [ ] Clear all existing verification records:
  ```java
  delete [SELECT Id FROM Verification_Code__c];
  ```
- [ ] Have the test user's email inbox open and visible
- [ ] Log the test user out of Salesforce
- [ ] Open `https://login.salesforce.com` (or your My Domain URL)

---

## Scenario 1 — Happy Path (Correct Code)

**Shows:** Code is emailed, entered correctly, login succeeds.

**Steps:**
1. Enter the test user's credentials and click **Log In**
2. The **Verification Code** screen appears (flow running) ← _point this out_
3. Switch to the email inbox — a new email arrives with the subject **"Your Salesforce Verification Code"**
4. Note the 6-digit code in the email
5. Enter the code in the input field on screen
6. Click **Next**
7. User is now inside the org ✅

**Talking point:** *"The code expires in 5 minutes. It is stored as a SHA-256 hash — plain text is never saved in the database."*

---

## Scenario 2 — Wrong Code → Error Message → Attempts Counter

**Shows:** Wrong codes show inline error; attempts are tracked.

**Steps:**
1. Log the user out again
2. Log back in — verification screen appears; a new code is emailed
3. Type `999999` (wrong code) → click **Next**
4. **Error message appears**: *"Invalid code. 2 attempts remaining."* ← _point this out_
5. Type `000000` (wrong code again) → click **Next**
6. **Error message**: *"Invalid code. 1 attempt remaining."*

**Talking point:** *"Errors show inline — no page reload. The user sees exactly how many attempts they have left."*

---

## Scenario 3 — Three Wrong Codes → Block & Forced Logout

**Shows:** After 3 wrong codes, the user is blocked and the session is destroyed.

**Steps (continuing from Scenario 2):**
1. Type `111111` (wrong code, 3rd attempt) → click **Next**
2. **Blocked screen appears**: *"You have entered 3 incorrect verification codes. For your security, you are being logged out. Please log in again after 10 minutes."*
3. Click **OK**
4. Browser redirects to `https://login.salesforce.com` — session destroyed ✅

**Talking point:** *"The Finish button triggers `LoginFlow_FinishLocation = /secur/logout.jsp`. No matter what path the user takes on this screen — they cannot reach the org. The session is destroyed at the platform level, not the browser level."*

---

## Scenario 4 — Refresh While Blocked (Session Guard)

**Shows:** Refreshing the browser during or after a block does not bypass the system.

**Steps:**
1. Log the user back in within 10 minutes of the block ← _this is the key moment_
2. Instead of completing Scenario 3's block screen, demonstrate: go back to login, log in again
3. The **Force Logout screen** appears immediately: *"You have exceeded the maximum number of verification attempts. Click OK to be logged out."*
4. No code was emailed — the check happened before code generation ← _point this out_
5. Click **OK** → redirected to `login.salesforce.com`

**Talking point:** *"`VerificationCodeChecker` runs at the very start of every flow execution — before generating or sending a code. Even if the user opens a new browser tab, they cannot bypass the block."*

---

## Scenario 5 — Expired Code

**Shows:** Codes older than 5 minutes are rejected and a new one is auto-sent.

**Steps:**
1. Log the user in and let the verification screen sit idle for more than 5 minutes
   _(or temporarily shorten `CODE_EXPIRY_MINUTES` in `VerificationCodeService` for the demo)_
2. Enter any code from the old email
3. Flow detects the expired code and **automatically sends a new email**
4. The screen refreshes, prompting the user to check their inbox for a new code

**Talking point:** *"Codes are valid for exactly 5 minutes. Attempting to use an old code after expiry triggers a fresh send — no action required from the user beyond entering the new code."*

---

## Scenario 6 — SSO (Google SAML) Path

**Shows:** The flow applies to SSO users, not just standard logins.

**Steps:**
1. Navigate to the My Domain URL (or SSO entry point)
2. Click **Log In with Google**
3. Complete Google authentication
4. The **Verification Code** screen appears ← _same UI as standard login_
5. Enter the code from email → access granted ✅

**Talking point:** *"The Login Flow is assigned at both the Login Page level and the SSO configuration level. All users — regardless of identity provider — must pass email verification."*

---

## Scenario 7 — Block Expires (10-Minute Window)

**Shows:** The block is temporary — after 10 minutes the user can log in normally.

**Steps:**
1. Attempt to log in while blocked → force logout screen appears
2. Wait 10 minutes (or show the timestamp on the blocked `Verification_Code__c` record)
3. Log in again → verification screen appears normally
4. Enter the correct code → access granted ✅

**Talking point:** *"There is no permanent ban. The block window is 10 minutes — a configurable constant in one Apex class. An admin can also manually unblock a user immediately via a simple anonymous Apex query."*

---

## Summary Talking Points

| Feature | Detail |
|---|---|
| Works for all users | SSO + standard login |
| Code validity | 5 minutes |
| Max attempts | 3 |
| Block duration | 10 minutes |
| Code storage | SHA-256 hash only |
| Session handling | Server-side logout via `LoginFlow_FinishLocation` |
| Test coverage | 19/19 tests passing |
| Deployment method | ZIP via Workbench (Metadata API v62.0) |
