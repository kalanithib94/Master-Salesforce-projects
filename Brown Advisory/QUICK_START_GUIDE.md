# Brown Advisory Outlook Integration - Quick Start Guide

## 🎯 What's Been Done

✅ **All code has been deployed to TSO org (tso@gptyfy.com)**
- Apex classes created and deployed
- Named Credential configured
- External Credential configured
- Test scripts created

---

## 🚀 What You Need To Do Now

### 1️⃣ Send Test Emails (5 minutes)
- Login to https://outlook.office.com with `jeevan@gptfy.dev`
- Send 3-5 test emails (use template in README section 1.2)
- Note the email addresses you use

### 2️⃣ Get Access Token (2 minutes)
- Go to https://developer.microsoft.com/en-us/graph/graph-explorer
- Sign in with `jeevan@gptfy.dev`
- Profile → Access token → **Copy the token**

### 3️⃣ Configure Named Credential (3 minutes)
- Salesforce Setup → "Named Credentials"
- Edit "OutlookGraphAPI"
- Add custom header: `Bearer YOUR_TOKEN_HERE`
- Save

### 4️⃣ Test Connectivity (2 minutes)
Run this command:
```powershell
cd "c:\CC\Project_SFDC\Brown Advisory"
sf apex run --file scripts/apex/ping.apex --target-org tso@gptyfy.com
```
Expected: "Status: OK_200"

### 5️⃣ Create AI Data Source (3 minutes)
- Salesforce → AI Data Sources → New
- Name: "Email / MS Exchange - Outlook"
- Connector Class: "OutlookDataSourceConnector"
- Named Credential: "OutlookGraphAPI"
- Save

### 6️⃣ Update Brown Advisory Prompt (5 minutes)
- Clone Financial House Prompt
- Add email data source
- Add email fields to template (see README lines 390-446)

### 7️⃣ Test End-to-End (5 minutes)
- Create test Contact with email from step 1
- Open Contact → Account360 component
- Verify email intelligence appears

---

## 📞 Commands Reference

### Test Connectivity
```powershell
sf apex run --file scripts/apex/ping.apex --target-org tso@gptyfy.com
```

### Run Unit Tests
```powershell
sf apex run test --tests OutlookDataSourceConnectorTest --result-format human --target-org tso@gptyfy.com
```

### Test Integration
```powershell
# Edit scripts/apex/test-integration.apex first (update email address)
sf apex run --file scripts/apex/test-integration.apex --target-org tso@gptyfy.com
```

---

## 🔧 Troubleshooting

### Token Expired Error
1. Get new token from Graph Explorer
2. Update Named Credential
3. Retry

### No Emails Returned
- Check email address matches test emails
- Check emails are within 30 days
- Verify token has Mail.Read permission

### Deployment Issues
Already deployed! If you need to redeploy:
```powershell
sf project deploy start --target-org tso@gptyfy.com
```

---

## 📁 File Structure

```
c:\CC\Project_SFDC\Brown Advisory\
├── Readme.md                              ← Original detailed guide
├── DEPLOYMENT_STATUS.md                   ← What's done & what's next
├── QUICK_START_GUIDE.md (this file)       ← Quick reference
├── sfdx-project.json
├── force-app/main/default/
│   ├── classes/
│   │   ├── OutlookDataSourceConnector.cls          ✅ Deployed
│   │   ├── OutlookDataSourceConnectorTest.cls      ✅ Deployed
│   │   └── OutlookGraphPing.cls                    ✅ Deployed
│   ├── externalCredentials/
│   │   └── OutlookGraphAPI.externalCredential      ✅ Deployed
│   └── namedCredentials/
│       └── OutlookGraphAPI.namedCredential         ✅ Deployed
└── scripts/apex/
    ├── ping.apex                          ← Test connectivity
    └── test-integration.apex              ← Test full integration
```

---

## ⏱️ Total Time Required: ~25 minutes

Good luck! 🎉

