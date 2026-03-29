# Deploying via Workbench

## The Deploy File

```
deploy/VerificationCodeLoginFlow_Deploy.zip
```

**API Version:** 62.0 | **Size:** ~18 KB | **Components:** 19

---

## What's Inside the ZIP

```
VerificationCodeLoginFlow_Deploy.zip
│
├── package.xml                               ← manifest (API v62.0)
│
├── classes/
│   ├── VerificationCodeService.cls           ← core generate + validate logic
│   ├── VerificationCodeService.cls-meta.xml
│   ├── VerificationCodeGenerator.cls         ← flow wrapper (generate)
│   ├── VerificationCodeGenerator.cls-meta.xml
│   ├── VerificationCodeValidator.cls         ← flow wrapper (validate)
│   ├── VerificationCodeValidator.cls-meta.xml
│   ├── VerificationCodeChecker.cls           ← blocked-state check at login start
│   ├── VerificationCodeChecker.cls-meta.xml
│   ├── VerificationCodeCleanup.cls           ← scheduled daily cleanup
│   ├── VerificationCodeCleanup.cls-meta.xml
│   ├── VerificationCodeServiceTest.cls       ← test class (13 tests)
│   ├── VerificationCodeServiceTest.cls-meta.xml
│   ├── VerificationCodeCheckerTest.cls       ← test class (4 tests)
│   ├── VerificationCodeCheckerTest.cls-meta.xml
│   ├── VerificationCodeCleanupTest.cls       ← test class (2 tests)
│   └── VerificationCodeCleanupTest.cls-meta.xml
│
├── objects/
│   └── Verification_Code__c.object           ← custom object + all 5 fields
│
└── flows/
    └── VerificationCodeLoginFlow.flow         ← login screen flow (Active)
```

---

## Step-by-Step Workbench Deployment

### Step 1 — Log in to Workbench

1. Go to **[https://workbench.developerforce.com](https://workbench.developerforce.com)**
2. Set **Environment** to match your target org type (`Production` / `Sandbox`)
3. Set **API Version** to `62.0`
4. Tick **I agree to the terms of service**
5. Click **Login with Salesforce** and authorise with an admin account

---

### Step 2 — Navigate to Deploy

**Migration → Deploy**

---

### Step 3 — Upload the ZIP

1. Click **Choose File** → select `deploy/VerificationCodeLoginFlow_Deploy.zip`
2. Set options:

| Option | Value |
|---|---|
| **Rollback On Error** | ✅ Checked |
| **Single Package** | ✅ Checked |
| **Allow Missing Files** | ☐ Unchecked |
| **Run Tests** | `RunSpecifiedTests` |
| **Test Classes** | `VerificationCodeServiceTest, VerificationCodeCheckerTest, VerificationCodeCleanupTest` |
| **Purge On Delete** | ☐ Unchecked |

3. Click **Next**

---

### Step 4 — Confirm and Deploy

1. Review the component list — you should see **19 components**
2. Click **Deploy**
3. Wait 1–2 minutes
4. Confirm **Status: Succeeded** and **Number Components Deployed: 19** ✅

> ⚠️ If you see **Number Components Deployed: 0** — the API version in Workbench doesn't match the ZIP. Make sure Workbench is set to **API 62.0** before uploading.

---

### Step 5 — Manual Configuration (Required After Every Deploy)

The flow deploys as **Active** automatically, but the Login Flow assignment must be done manually.

#### 5a — Assign to Standard Login
1. **Setup → Identity → Login Flows → New**
2. Flow: `Verification Code Login Flow`
3. Login Page: `Default Login Page` (or your My Domain)
4. Click **Save**

#### 5b — Assign to SSO (Google SAML)
1. **Setup → Single Sign-On Settings**
2. Click **Edit** on your Google SAML configuration
3. Under **Login Flow**, select `Verification Code Login Flow`
4. Click **Save**

#### 5c — Schedule the Cleanup Job
**Developer Console → Debug → Open Execute Anonymous Window** → paste and run:

```java
System.schedule(
    'VerificationCodeCleanup Daily',
    '0 0 2 * * ?',
    new VerificationCodeCleanup()
);
```

Verify: **Setup → Scheduled Jobs** — `VerificationCodeCleanup Daily` should appear.

---

## Regenerating the ZIP After Future Changes

> ⚠️ Do NOT use PowerShell's `Compress-Archive` — it writes backslash paths into the ZIP which Workbench cannot parse. Use Python instead (Python 3 is required).

```powershell
# 1. Convert SFDX source to Metadata API format
sf project convert source --source-dir force-app/main/default --output-dir deploy/metadata

# 2. Replace with explicit package.xml
Copy-Item manifest/package.xml deploy/metadata/package.xml -Force

# 3. Remove unused components
Remove-Item -Recurse -Force deploy/metadata/lwc -ErrorAction SilentlyContinue
Remove-Item -Force deploy/metadata/classes/VerificationCodeBlocker.cls -ErrorAction SilentlyContinue
Remove-Item -Force deploy/metadata/classes/VerificationCodeBlocker.cls-meta.xml -ErrorAction SilentlyContinue

# 4. Rebuild ZIP using Python (ensures forward-slash paths for Workbench compatibility)
python -c "
import zipfile, os
src = r'deploy\metadata'
dst = r'deploy\VerificationCodeLoginFlow_Deploy.zip'
with zipfile.ZipFile(dst, 'w', zipfile.ZIP_DEFLATED) as zf:
    for root, dirs, files in os.walk(src):
        for f in files:
            fp = os.path.join(root, f)
            arcname = os.path.relpath(fp, src).replace(os.sep, '/')
            zf.write(fp, arcname)
print('ZIP rebuilt successfully')
"
```

---

## Troubleshooting

| Error / Symptom | Fix |
|---|---|
| **0 Components Deployed / 0 Total** | Two possible causes: (1) Workbench API version doesn't match — set it to **62.0**. (2) ZIP was built with PowerShell `Compress-Archive` (backslash paths) — rebuild using the Python script above. |
| `This schedulable class has jobs pending` | Abort the existing `VerificationCodeCleanup` scheduled job then redeploy |
| Flow not visible in Login Flow dropdown | Flow must be **Active**. Go to Setup → Flows → Activate it. |
| `field integrity exception: User__c` | Field already exists with wrong constraints. Delete it in Setup → Object Manager and redeploy. |
| `Required field is missing: sharingModel` | The `Verification_Code__c` object failed to deploy. Check object deployment in Workbench results. |
