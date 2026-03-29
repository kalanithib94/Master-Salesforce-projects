# Remaining Steps Guide - Brown Advisory Outlook Integration

## 📊 Current Status

### ✅ COMPLETED
1. ✅ Project Setup & Code Creation
2. ✅ Metadata Files Fixed
3. ✅ Deployment to TSO Org
4. ✅ Test Scripts Created

### 🔄 IN PROGRESS
- Step 2: Send Test Emails (templates created)
- Step 5: Get Graph API Token (instructions ready)

### ⏸️ PENDING
- Step 6: Configure Named Credential
- Step 7: Test Integration
- Step 8: Configure AI Data Source
- Step 9: Clone Brown Advisory Prompt
- Step 10: Verify End-to-End

---

## 🚀 Quick Action Plan

### **RIGHT NOW** (15 minutes)

#### 1. Send Test Emails (5 min)
- Log in to https://outlook.office.com with `jeevan@gptfy.dev`
- Use `EMAIL_TEMPLATES_TO_SEND.md`
- Send all 5 emails to Mark and Cathy Addaman

#### 2. Get Graph API Token (3 min)
- Follow `STEP5_GET_GRAPH_API_TOKEN.md`
- Sign in to Graph Explorer
- Consent to Mail.Read
- Copy access token

#### 3. Configure Named Credential (2 min)
- Follow `STEP6_CONFIGURE_NAMED_CREDENTIAL.md`
- Add Bearer token to Salesforce Named Credential
- Save configuration

---

### **THEN TEST** (10 minutes)

#### Step 7: Test the Integration

**7.1 Run Unit Tests**
```powershell
cd "c:\CC\Project_SFDC\Brown Advisory"
sf apex run test --tests OutlookDataSourceConnectorTest --result-format human --code-coverage --target-org tso@gptyfy.com
```
Expected: Pass: 4/4

**7.2 Test Named Credential Connectivity**
```powershell
sf apex run --file scripts/apex/ping.apex --target-org tso@gptyfy.com
```
Expected: Status: OK_200

**7.3 Test with Real Email**
1. Edit `scripts/apex/test-integration.apex`
2. Change email to: `mark.addaman@techcorp.com`
3. Run:
```powershell
sf apex run --file scripts/apex/test-integration.apex --target-org tso@gptyfy.com
```
Expected: Email Count: 3+ (number of emails you sent)

---

### **CONFIGURE SALESFORCE** (15 minutes)

#### Step 8: Create AI Data Source Record

**Instructions:**
1. Login to Salesforce: https://tsogptfy.my.salesforce.com
2. App Launcher → Search: **"AI Data Sources"**
3. Click **"New"**
4. Fill in:

| Field | Value |
|-------|-------|
| Data Source Name | Email / MS Exchange - Outlook |
| Connector Class | OutlookDataSourceConnector |
| Named Credential | OutlookGraphAPI |
| Active | ✓ |
| Source | External |
| Description | Retrieves email history from Microsoft Outlook/Exchange for relationship intelligence |

5. Click **"Save"**
6. **COPY THE RECORD ID** from the URL

---

#### Step 9: Clone & Configure Brown Advisory Prompt

**Instructions:**

**9.1 Find Existing Prompt**
1. App Launcher → Search: **"Prompts"** or **"AI Prompts"**
2. Find the **"Financial House Prompt"** (used for TVAMP)
3. Click to open it

**9.2 Clone the Prompt**
1. Click **"Clone"** button
2. Rename to: **"Brown Advisory Account360 Prompt"**
3. Update Description:
   ```
   Account360 Pre-Call Briefing combining Salesforce data and Outlook email intelligence for Brown Advisory
   ```

**9.3 Add Email Data Source**
1. In the cloned prompt, find **"Data Sources"** section
2. Click **"Add Data Source"**
3. Select: **"Email / MS Exchange - Outlook"** (the one you created in Step 8)
4. Click **"Save"**

**9.4 Update Prompt Template**

Find the existing prompt template and add these sections after the Account/Contact information:

```
## Recent Email Activity
{OutlookEmails.summary}

### Email Highlights (Last 30 Days)
{OutlookEmails.highlights}

### Topics Discussed via Email
{OutlookEmails.topics}
```

**Full template structure should be:**
```
You are a financial advisor assistant preparing a pre-call briefing for Brown Advisory.

## Client Information
- Name: {Contact.Name}
- Email: {Contact.Email}
- Phone: {Contact.Phone}
- Title: {Contact.Title}

## Account Details
- Account Name: {Account.Name}
- AUM: {Account.AUM__c}
- Account Type: {Account.Type}
- Industry: {Account.Industry}

## Recent Email Activity
{OutlookEmails.summary}

### Email Highlights (Last 30 Days)
{OutlookEmails.highlights}

### Topics Discussed via Email
{OutlookEmails.topics}

## Recent Opportunities
{Opportunities}

## Recent Activities
{Activities}

---

Based on the above information, provide a concise pre-call briefing that includes:
1. Client relationship summary
2. Recent email interactions and topics discussed
3. Key discussion points for the upcoming call
4. Recommended talking points based on email history
5. Any action items or follow-ups from previous emails
```

5. Click **"Save"**

---

### **VERIFY END-TO-END** (5 minutes)

#### Step 10: Test Complete Integration

**10.1 Create Test Contact**
1. Go to Salesforce → Contacts → New
2. Fill in:
   - First Name: `Mark`
   - Last Name: `Addaman`
   - Email: `mark.addaman@techcorp.com`
   - Phone: `(555) 847-2156`
   - Account: Create new → `Brown Advisory Test Account`
3. Save

**10.2 Generate Account360 Briefing**
1. Open the Mark Addaman Contact record
2. Find the **"Account360"** or **"Pre-Call Briefing"** component
3. Click to generate the briefing

**10.3 Verify Email Data Appears**

Check that the briefing includes:

- ✓ Contact information from Salesforce (Name, Email, Phone)
- ✓ Account details from Salesforce
- ✓ **Email summary** (e.g., "Found 3 emails from the last 30 days")
- ✓ **Email highlights** (Subjects and dates of recent emails)
- ✓ **Topics discussed** (Keywords from email subjects/bodies)

**Expected Email Section Example:**
```
## Recent Email Activity
Found 3 emails from the last 30 days. Most recent: Nov 1, 2024

### Email Highlights (Last 30 Days)
• Nov 1, 2024: "Q3 Portfolio Review - Excellent Tax-Loss Harvesting Results" (to contact)
• Nov 1, 2024: "Re: Portfolio Rebalancing Discussion - Addressing Your Q3 Concerns" (to contact)
• Nov 1, 2024: "Action Items from Our Recent Meeting - Next Steps" (to contact)

### Topics Discussed via Email
Portfolio, Rebalancing, Concerns, Review, Strategy, Performance, Allocation, Volatility
```

---

## ✅ Success Checklist

### Deployment & Setup
- [x] All Apex classes deployed successfully
- [x] Named Credential created
- [x] External Credential created
- [x] Test scripts created

### Configuration
- [ ] Test emails sent from jeevan@gptfy.dev
- [ ] Graph API token obtained
- [ ] Named Credential configured with token
- [ ] Remote Site Setting added

### Testing
- [ ] Unit tests pass (4/4)
- [ ] Ping test returns OK_200
- [ ] Integration test returns email count > 0
- [ ] Debug logs show proper API responses

### Salesforce UI
- [ ] AI Data Source record created
- [ ] Brown Advisory prompt cloned
- [ ] Email data source added to prompt
- [ ] Prompt template updated with email fields

### End-to-End
- [ ] Test Contact created with email
- [ ] Account360 component shows email intelligence
- [ ] Email summary appears correctly
- [ ] Email highlights show recent subjects
- [ ] Topics extracted from emails

---

## 📝 Estimated Time Remaining

| Step | Time |
|------|------|
| Send test emails | 5 min |
| Get Graph API token | 3 min |
| Configure Named Credential | 2 min |
| Run tests | 5 min |
| Create AI Data Source | 3 min |
| Clone & configure prompt | 7 min |
| Verify end-to-end | 5 min |
| **TOTAL** | **30 minutes** |

---

## 🆘 Need Help?

### Common Issues

**Token Expired**
- Get fresh token from Graph Explorer
- Update Named Credential
- Retry test

**No Emails Returned**
- Check email address matches test emails
- Verify emails are within 30 days
- Check token has Mail.Read permission

**Can't Find AI Data Source**
- Check object is `ccai__AI_Data_Source__c`
- Field is `ccai__Connector_Class__c`
- Named Credential is `OutlookGraphAPI`

---

## 📁 All Reference Files

1. **`EMAIL_TEMPLATES_TO_SEND.md`** - Email templates for testing
2. **`STEP5_GET_GRAPH_API_TOKEN.md`** - Graph API token instructions
3. **`STEP6_CONFIGURE_NAMED_CREDENTIAL.md`** - Named Credential setup
4. **`REMAINING_STEPS_GUIDE.md`** (this file) - Complete action plan
5. **`DEPLOYMENT_STATUS.md`** - Detailed deployment status
6. **`QUICK_START_GUIDE.md`** - Quick reference
7. **`Readme.md`** - Original comprehensive guide

---

## 🎯 START HERE

**Your next immediate actions:**

1. ✉️ Send test emails using `EMAIL_TEMPLATES_TO_SEND.md`
2. 🔑 Get Graph API token using `STEP5_GET_GRAPH_API_TOKEN.md`
3. ⚙️ Configure Named Credential using `STEP6_CONFIGURE_NAMED_CREDENTIAL.md`
4. ✔️ Run tests from terminal
5. 📊 Configure Salesforce UI components
6. 🎯 Verify end-to-end integration

**Good luck! You're almost there!** 🚀

