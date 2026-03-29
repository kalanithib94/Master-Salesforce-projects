@Jeevan CC @Kalanithi Here are the more detailed version from AI

# Brown Advisory - Outlook Email Integration Setup Guide

## Overview
This guide will help you set up the Outlook/Exchange email integration for Brown Advisory's Account360 Pre-Call Briefing in the TSO Salesforce org.

---

## Prerequisites

- Access to TSO Salesforce org (tso@gptyfy.com)
- Access to jeevan@gptfy.dev email account
- Salesforce CLI installed (for deployment)
- Access to Microsoft Graph Explorer

---

## Step 1: Setup Test Email Account (jeevan@gptfy.dev)

### 1.1 Login to Email Account
1. Go to https://outlook.office.com
2. Login with: *jeevan@gptfy.dev*
3. Verify you can access the mailbox

### 1.2 Send Sample Test Emails
Send test emails to simulate client communication. Use the content from this ChatGPT conversation:
https://chatgpt.com/c/6905a7d7-cecc-832d-86b4-b9ec059a16f2

*Sample Email Template:*

To: test-client@example.com (use any test email address)
Subject: Re: Q4 Portfolio Review Discussion

Hi [Client Name],

Thank you for taking the time to discuss your portfolio performance yesterday. 
As promised, I'm following up with the key points we covered:

1. Q4 Performance Summary
2. Asset Allocation Recommendations
3. Tax-Loss Harvesting Opportunities

Please let me know if you have any questions before our next meeting.

Best regards,
Jeevan


*Action Items:*
- [ ] Send at least 3-5 test emails to different "client" email addresses
- [ ] Make sure emails have relevant financial advisory content
- [ ] Note down the email addresses you used (you'll need them for testing)

---

## Step 2: Fix Salesforce Metadata Files

The current Named Credential metadata files have API version compatibility issues. We need to fix them before deployment.

### 2.1 Fix External Credential Metadata

*File:* force-app/main/default/externalCredentials/OutlookGraphAPI.externalCredential-meta.xml

Replace the entire file content with:

xml
<?xml version="1.0" encoding="UTF-8"?>
<ExternalCredential xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Outlook Graph API</label>
    <authenticationProtocol>Custom</authenticationProtocol>
</ExternalCredential>


*What changed:* Removed the <principalType> element which is not supported in older API versions.

### 2.2 Fix Named Credential Metadata

*File:* force-app/main/default/namedCredentials/OutlookGraphAPI.namedCredential-meta.xml

Replace the entire file content with:

xml
<?xml version="1.0" encoding="UTF-8"?>
<NamedCredential xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Outlook Graph API</label>
    <endpoint>https://graph.microsoft.com/v1.0</endpoint>
    <protocol>NoAuthentication</protocol>
    <principalType>NamedUser</principalType>
    <calloutStatus>Enabled</calloutStatus>
</NamedCredential>


*What changed:* 
- Removed <identityType> element
- Changed to NoAuthentication protocol (we'll add the Bearer token via custom header in the UI)
- Simplified structure for compatibility

---

## Step 3: Deploy to Salesforce TSO Org

### 3.1 Authenticate with Salesforce

Open terminal and run:

bash
sf org login web --alias tso-gptfy --set-default


This will open a browser. Login with: *tso@gptyfy.com*

### 3.2 Deploy the Code

bash
cd /path/to/outlook-graph-api-data-source
sf project deploy start


*Expected Output:*

Status: Succeeded
Components Deployed: 9


*If deployment fails:*
- Check the error message
- Verify you're logged into the correct org: sf org list
- Make sure the metadata files were updated correctly (Step 2)

### 3.3 Verify Deployment

bash
sf apex list class | grep -i outlook


You should see:
- OutlookDataSourceConnector
- OutlookDataSourceConnectorTest
- OutlookGraphPing

---

## Step 4: Get Microsoft Graph API Access Token

### 4.1 Open Graph Explorer
1. Go to: https://developer.microsoft.com/en-us/graph/graph-explorer
2. Click *"Sign in to Graph Explorer"* (top right)
3. Sign in with: *jeevan@gptfy.dev*

### 4.2 Consent to Permissions
1. After signing in, click *"Modify permissions"* (left sidebar)
2. Find *"Mail.Read"* permission
3. Click *"Consent"* if not already consented
4. Accept the permission request

### 4.3 Get Access Token
1. Click on your profile picture (top right)
2. Click *"Access token"*
3. Copy the entire token (it's a long string starting with "eyJ...")
4. *Important:* Save this token - you'll need it in the next step

*Note:* Tokens expire after ~1 hour. If you get authentication errors later, come back here and get a fresh token.

### 4.4 Test the Token (Optional but Recommended)

In Graph Explorer, run this query to verify it works:


GET https://graph.microsoft.com/v1.0/me/messages?$top=5


You should see the test emails you sent in Step 1.

---

## Step 5: Configure Named Credential in Salesforce

### 5.1 Navigate to Named Credentials
1. Login to Salesforce TSO org: https://tsogptfy.my.salesforce.com
2. Click *Setup* (gear icon, top right)
3. In Quick Find, search: *"Named Credentials"*
4. Click *"Named Credentials"*

### 5.2 Configure OutlookGraphAPI

*Option A: If you see "OutlookGraphAPI" in the list:*
1. Click *"Edit"* next to OutlookGraphAPI
2. Scroll to *"Callout Options"* section
3. Check *"Generate Authorization Header"*
4. In the *"Authorization Scheme"* dropdown, select *"Custom"*
5. In the *"Custom Authorization Header"* field, enter:
   
   Bearer YOUR_TOKEN_HERE
   
   Replace YOUR_TOKEN_HERE with the token you copied in Step 4.3
6. Click *"Save"*

*Option B: If OutlookGraphAPI doesn't exist, create it:*
1. Click *"New Named Credential"*
2. Fill in:
   - *Label:* Outlook Graph API
   - *Name:* OutlookGraphAPI
   - *URL:* https://graph.microsoft.com/v1.0
   - *Identity Type:* Named Principal
   - *Authentication Protocol:* No Authentication
   - *Generate Authorization Header:* ✓ (checked)
   - *Authorization Scheme:* Custom
   - *Custom Authorization Header:* Bearer YOUR_TOKEN_HERE
3. Click *"Save"*

### 5.3 Add Remote Site Setting (if needed)

1. In Setup, search: *"Remote Site Settings"*
2. Click *"New Remote Site"*
3. Fill in:
   - *Remote Site Name:* MicrosoftGraph
   - *Remote Site URL:* https://graph.microsoft.com
   - *Active:* ✓ (checked)
4. Click *"Save"*

---

## Step 6: Test the Integration

### 6.1 Run Unit Tests

In terminal, run:

bash
sf apex run test --tests OutlookDataSourceConnectorTest --result-format human --code-coverage


*Expected Output:*

Test Results:
  Pass: 10
  Fail: 0
  Code Coverage: >75%


### 6.2 Test Named Credential Connectivity

Create a test file: scripts/apex/ping.apex

apex
OutlookGraphPing.PingResult result = OutlookGraphPing.ping();
System.debug('Status: ' + result.status);
System.debug('Message: ' + result.message);
System.debug('Response: ' + result.responseBody);


Run it:
bash
sf apex run --file scripts/apex/ping.apex


*Expected Output:*

Status: OK_200
Message: Successfully retrieved messages


*If you get errors:*
- NON_200 or UNAUTHORIZED: Token expired - get fresh token from Graph Explorer (Step 4.3) and update Named Credential (Step 5.2)
- CALLOUT_EXCEPTION: Check Remote Site Settings (Step 5.3)

### 6.3 Test with Real Email Address

Create file: scripts/apex/test-integration.apex

apex
// Create test AI Data Source record
ccai__AI_Data_Source__c ds = new ccai__AI_Data_Source__c(
    Name = 'Outlook Test',
    ccai__Named_Credential__c = 'OutlookGraphAPI',
    ccai__Apex_Class_Name__c = 'OutlookDataSourceConnector'
);
insert ds;

// Test with one of the email addresses you used in Step 1.2
Map<String, Object> contactData = new Map<String, Object>{
    'Email' => 'test-client@example.com',  // REPLACE WITH ACTUAL EMAIL FROM STEP 1.2
    'Name' => 'Test Client',
    'Account' => new Map<String, Object>{
        'Name' => 'Brown Advisory Test Account'
    }
};

String sfDataJson = JSON.serialize(contactData);

OutlookDataSourceConnector connector = new OutlookDataSourceConnector();
String result = connector.getExternalData(ds, sfDataJson);

Map<String, Object> resultData = (Map<String, Object>) JSON.deserializeUntyped(result);
Map<String, Object> outlookEmails = (Map<String, Object>) resultData.get('OutlookEmails');

System.debug('Email Count: ' + outlookEmails.get('count'));
System.debug('Summary: ' + outlookEmails.get('summary'));
System.debug('Full Result: ' + result);


Run it:
bash
sf apex run --file scripts/apex/test-integration.apex


*Expected Output:*

Email Count: 3
Summary: Found 3 emails from the last 30 days


---

## Step 7: Review & Fix Apex Classes (If Needed)

### 7.1 Review the Classes

The three Apex classes are:

1. *OutlookDataSourceConnector.cls* - Main connector that implements GPTfy AI Data Source interface
2. *OutlookDataSourceConnectorTest.cls* - Unit tests with mocks
3. *OutlookGraphPing.cls* - Simple connectivity test utility

### 7.2 Common Issues & Fixes

*Issue 1: No emails returned*

Check the query filter in OutlookDataSourceConnector.cls around line 150:

apex
String emailFilter = '(from/emailAddress/address eq \'' + emailAddress + '\' or toRecipients/any(r:r/emailAddress/address eq \'' + emailAddress + '\'))';


This filters emails where the contact is either the sender OR recipient.

*Issue 2: Date range too restrictive*

Default is 30 days. To change, modify line 4:

apex
private static final Integer DEFAULT_DAYS_BACK = 30;  // Change to 60, 90, etc.


*Issue 3: Token keeps expiring*

For production, you'll need to implement OAuth 2.0 refresh tokens. For now, just update the Named Credential with a fresh token when it expires.

---

## Step 8: Configure AI Data Source in Salesforce

### 8.1 Create AI Data Source Record

1. In Salesforce, go to *App Launcher* → Search for *"AI Data Sources"*
2. Click *"New"*
3. Fill in:
   - *Data Source Name:* Email / MS Exchange - Outlook
   - *Apex Class Name:* OutlookDataSourceConnector
   - *Named Credential:* OutlookGraphAPI
   - *Active:* ✓ (checked)
   - *Description:* Retrieves email history from Microsoft Outlook/Exchange for relationship intelligence
4. Click *"Save"*
5. *Copy the Record ID* - you'll need this for the prompt

---

## Step 9: Clone Financial House Prompt for Brown Advisory

### 9.1 Find the TVAMP Financial House Prompt

1. In Salesforce, go to *App Launcher* → Search for *"Prompts"* or *"AI Prompts"*
2. Find the *"Financial House Prompt"* used for TVAMP
3. Click on it to open

### 9.2 Clone the Prompt

1. Click *"Clone"* button
2. Rename to: *"Brown Advisory Account360 Prompt"*
3. Update the description: Account360 Pre-Call Briefing combining Salesforce data and Outlook email intelligence for Brown Advisory

### 9.3 Add Email Data Source to Prompt

1. In the cloned prompt, find the *"Data Sources"* section
2. Click *"Add Data Source"*
3. Select: *"Email / MS Exchange - Outlook"* (the one you created in Step 8)
4. Click *"Save"*

### 9.4 Update Prompt Template

Add email intelligence to the prompt template. Find the section where it generates the briefing and add:


## Recent Email Activity
{OutlookEmails.summary}

### Key Email Highlights
{OutlookEmails.highlights}

### Recent Topics Discussed
{OutlookEmails.topics}


*Full example prompt structure:*


You are a financial advisor assistant preparing a pre-call briefing for Brown Advisory.

## Client Information
- Name: {Contact.Name}
- Account: {Account.Name}
- Title: {Contact.Title}
- Phone: {Contact.Phone}
- Email: {Contact.Email}

## Account Details
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


### 9.5 Test the Prompt

1. Open a *Contact* record that has one of the test email addresses from Step 1.2
2. Click on the *"Account360"* or *"Pre-Call Briefing"* component
3. The AI should now generate a briefing that includes:
   - Salesforce data (Account, Contact, Opportunities)
   - Email data (recent emails, topics, highlights)

---

## Step 10: Verify End-to-End Integration

### 10.1 Create Test Contact

1. Create a new Contact in Salesforce:
   - *First Name:* Test
   - *Last Name:* Client
   - *Email:* (use one of the email addresses from Step 1.2)
   - *Account:* Brown Advisory Test Account

### 10.2 Generate Account360 Briefing

1. Open the Contact record
2. Click on the *Account360* component
3. Verify the briefing includes:
   - ✓ Contact information from Salesforce
   - ✓ Account details from Salesforce
   - ✓ Email summary from Outlook
   - ✓ Recent email topics
   - ✓ Email highlights

### 10.3 Validate Email Data

Check that the email section shows:
- Number of emails exchanged
- Date of last email
- Key topics discussed
- Email subjects
- Relevant snippets from email body

---

## Troubleshooting

### Problem: Token Expired Error

*Symptom:* InvalidAuthenticationToken or TokenIssuedBeforeRevocationTimestamp

*Solution:*
1. Go to Graph Explorer: https://developer.microsoft.com/en-us/graph/graph-explorer
2. Make sure you're signed in with jeevan@gptfy.dev
3. Get fresh token: Profile → Access token → Copy
4. Update Named Credential in Salesforce (Step 5.2)

### Problem: No Emails Returned

*Symptom:* Email count is 0 even though emails exist

*Possible Causes:*
1. Email address mismatch - verify the Contact email matches the test emails
2. Date range too restrictive - emails older than 30 days won't show
3. Token doesn't have Mail.Read permission

*Solution:*
1. Verify email address in Contact record matches test emails from Step 1.2
2. Check date of test emails - must be within last 30 days
3. Re-consent to Mail.Read permission in Graph Explorer

### Problem: Deployment Failed

*Symptom:* sf project deploy start fails with metadata errors

*Solution:*
1. Make sure you updated the metadata files in Step 2
2. Check API version compatibility
3. Try deploying just the Apex classes first:
   bash
   sf project deploy start --source-dir force-app/main/default/classes
   

### Problem: Named Credential Not Found

*Symptom:* CALLOUT_EXCEPTION: Named Credential 'OutlookGraphAPI' not found

*Solution:*
1. Verify Named Credential exists: Setup → Named Credentials
2. Check the exact name matches: OutlookGraphAPI (case-sensitive)
3. Verify it's enabled: Callout Status = Enabled

---

## Production Considerations

### Token Refresh Strategy

The current implementation uses a hardcoded Bearer token that expires after ~1 hour. For production:

*Option 1: OAuth 2.0 with Refresh Tokens (Recommended)*
1. Register an Azure AD application
2. Configure OAuth 2.0 in Named Credential
3. Use refresh tokens to automatically renew access

*Option 2: Service Account*
1. Create a dedicated service account (e.g., salesforce-integration@gptfy.dev)
2. Use Azure AD app with client credentials flow
3. Longer-lived tokens

*Option 3: Scheduled Token Refresh*
1. Create a scheduled Apex job to refresh token daily
2. Store token in Custom Metadata or Custom Setting
3. Update Named Credential programmatically

### Performance Optimization

- *Caching:* Cache email results for 5-10 minutes to reduce API calls
- *Batch Processing:* If processing multiple contacts, batch API calls
- *Async Processing:* Use @future or Queueable for large data volumes

### Security Best Practices

- *Least Privilege:* Ensure service account only has Mail.Read permission
- *Audit Logging:* Enable field history tracking on AI Data Source records
- *Data Retention:* Implement data retention policies for cached email data
- *Access Control:* Restrict who can view email intelligence in Account360

---

## Success Criteria

You'll know the integration is working when:

- [x] Deployment succeeds with no errors
- [x] Unit tests pass (10/10)
- [x] Ping test returns OK_200
- [x] Integration test returns email count > 0
- [x] AI Data Source record is created and active
- [x] Brown Advisory prompt includes email data source
- [x] Account360 briefing shows email intelligence
- [x] Email summary includes recent topics and highlights

---

## Next Steps After Setup

1. *Train the team* on how to interpret email intelligence in Account360
2. *Monitor API usage* - Microsoft Graph has rate limits
3. *Implement OAuth 2.0* for production (see Production Considerations)
4. *Gather feedback* from advisors using the briefings
5. *Iterate on prompt* based on feedback to improve relevance

---

## Support & Resources

- *Graph API Documentation:* https://learn.microsoft.com/en-us/graph/api/user-list-messages
- *Salesforce Named Credentials:* https://help.salesforce.com/s/articleView?id=sf.named_credentials_about.htm
- *Repository:* https://github.com/kaizenmantra/outlook-graph-api-data-source
- *Deployment Guide:* See DEPLOYMENT-GUIDE.md in the repository

---

## Contact

If you encounter issues not covered in this guide:
1. Check the troubleshooting section above
2. Review the deployment logs: sf project deploy report
3. Check Salesforce debug logs: Setup → Debug Logs
4. Review Graph API responses in the ping test output