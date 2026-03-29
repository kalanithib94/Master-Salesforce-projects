# Step 6: Configure Named Credential in Salesforce

## 🎯 Goal
Add the Microsoft Graph API access token to the Named Credential in Salesforce so the integration can authenticate.

---

## 📋 Prerequisites
- ✅ Completed Step 5: You have the access token copied
- ✅ Deployment completed: OutlookGraphAPI Named Credential exists in TSO org

---

## 🔧 Instructions

### 1. Login to Salesforce TSO Org

Open: https://tsogptfy.my.salesforce.com

**Credentials:**
- Username: `tso@gptyfy.com`
- Password: [Your Salesforce password]

### 2. Navigate to Named Credentials

1. Click the **Setup** gear icon (top right corner)
2. In the Quick Find box (left sidebar), type: **"Named Credentials"**
3. Click **"Named Credentials"** from the results

### 3. Find and Edit OutlookGraphAPI

1. In the list of Named Credentials, find **"OutlookGraphAPI"**
2. Click **"Edit"** next to it

### 4. Configure the Authorization Header

Scroll down to the **"Callout Options"** section:

**Set these fields:**

| Field | Value |
|-------|-------|
| **Generate Authorization Header** | ✓ (Checked) |
| **Authorization Scheme** | Custom |
| **Custom Authorization Header** | `Bearer YOUR_TOKEN_HERE` |

**Important:** Replace `YOUR_TOKEN_HERE` with the actual token you copied from Graph Explorer in Step 5.

**Example:**
```
Bearer <paste_full_token_from_Graph_Explorer_one_line>
```

### 5. Verify Other Settings

Make sure these settings are correct:

| Field | Value |
|-------|-------|
| **Label** | Outlook Graph API |
| **Name** | OutlookGraphAPI |
| **URL** | https://graph.microsoft.com/v1.0 |
| **Identity Type** | Named Principal |
| **Authentication Protocol** | No Authentication |
| **Callout Status** | Enabled |

### 6. Save the Configuration

Click **"Save"** at the bottom of the page.

---

## 🌐 Add Remote Site Setting (If Not Already Exists)

### 1. Navigate to Remote Site Settings

1. In Setup, Quick Find box: **"Remote Site Settings"**
2. Click **"Remote Site Settings"**

### 2. Check if MicrosoftGraph Exists

Look for a remote site named **"MicrosoftGraph"** with URL `https://graph.microsoft.com`

**If it exists:** ✅ You're done!

**If it doesn't exist:**

1. Click **"New Remote Site"**
2. Fill in:
   - **Remote Site Name**: `MicrosoftGraph`
   - **Remote Site URL**: `https://graph.microsoft.com`
   - **Description**: `Microsoft Graph API for Outlook integration`
   - **Active**: ✓ (Checked)
3. Click **"Save"**

---

## ✅ Success Criteria

You've successfully completed this step when:

- [ ] Named Credential "OutlookGraphAPI" is updated with Bearer token
- [ ] Custom Authorization Header starts with `Bearer ` followed by your token
- [ ] Settings saved successfully
- [ ] Remote Site Setting for https://graph.microsoft.com exists

---

## 🧪 Quick Test

After saving, you can do a quick test:

### Option 1: Using Developer Console

1. Setup → Developer Console
2. Debug → Open Execute Anonymous Window
3. Paste this code:
```apex
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:OutlookGraphAPI/me');
req.setMethod('GET');
Http http = new Http();
HttpResponse res = http.send(req);
System.debug('Status: ' + res.getStatusCode());
System.debug('Body: ' + res.getBody());
```
4. Click Execute
5. Check Debug Log - should see Status: 200

### Option 2: Using Our Ping Script (Recommended)

Run this from your terminal:
```powershell
cd "c:\CC\Project_SFDC\Brown Advisory"
sf apex run --file scripts/apex/ping.apex --target-org tso@gptyfy.com
```

**Expected Output:**
```
Status: OK_200
Message: Successfully retrieved messages
```

---

## ⚠️ Troubleshooting

### Problem: Save fails with "Invalid endpoint"
**Solution**: Make sure URL is exactly `https://graph.microsoft.com/v1.0` (no trailing slash)

### Problem: Test returns 401 Unauthorized
**Solution**: 
- Token may be expired (tokens last ~1 hour)
- Get fresh token from Graph Explorer (Step 5)
- Update Named Credential again

### Problem: CALLOUT_EXCEPTION error
**Solution**: Check Remote Site Setting exists for https://graph.microsoft.com

### Problem: Can't find Named Credential
**Solution**: 
- Verify deployment was successful (check Step 4)
- Named Credential name is case-sensitive: `OutlookGraphAPI`

---

## 🚀 Next Step

Once the Named Credential is configured and tested, proceed to:
**Step 7: Test the Integration**

Run the full test suite to verify everything works end-to-end.

---

## 📝 Notes

**Token Expiration:**
- Graph API tokens expire after ~1 hour
- For testing, you'll need to update the token periodically
- For production, implement OAuth 2.0 with refresh tokens (see README Production Considerations section)

**Security:**
- The token is stored securely in Salesforce Named Credential
- It's encrypted at rest
- Only authorized users can view/edit Named Credentials

