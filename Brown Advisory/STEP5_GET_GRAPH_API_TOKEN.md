# Step 5: Get Microsoft Graph API Access Token

## 🎯 Goal
Get an access token from Microsoft Graph Explorer to configure the Named Credential in Salesforce.

---

## 📋 Instructions

### 1. Open Graph Explorer
✅ Already open: https://developer.microsoft.com/en-us/graph/graph-explorer

### 2. Sign In with jeevan@gptfy.dev

**Look for the sign-in button:**
- Top right corner: Look for a profile icon or "Sign in" button
- Or click on "Tenant: Sample" to switch tenants

**Sign in with:**
- Email: `jeevan@gptfy.dev`
- Password: `L(759256348078om`
- Complete MFA if required

### 3. Change the Query to Get Messages

Once signed in, you'll see a query box that says:
```
GET    https://graph.microsoft.com/v1.0/me
```

**Change it to:**
```
GET    https://graph.microsoft.com/v1.0/me/messages?$top=5
```

### 4. Consent to Mail.Read Permission

Before running the query, you need to consent to permissions:

1. Click the **"Modify Permissions"** tab (next to "Request Body")
2. Look for **"Mail.Read"** permission in the list
3. Click the **"Consent"** button next to it
4. Accept the permission request popup

### 5. Test the Query

Click the **"Run query"** button (blue button on the right)

**Expected Result:**
- Status: 200 OK
- Response: JSON with your emails (if any exist in the mailbox)

### 6. Get the Access Token

This is the MOST IMPORTANT step:

1. Click on your **profile picture/icon** (top right)
2. OR click on the **"Access token"** tab
3. A panel will appear showing a very long token starting with `eyJ...`
4. Click **"Copy"** to copy the entire token
5. **SAVE THIS TOKEN** - you'll need it in the next step!

**Example token format:**
```
eyJ0eXAiOiJKV1QiLCJub25jZSI6InhJR0...very...long...string...
```

**⚠️ Important:** This token expires after ~1 hour. If you get authentication errors later, you'll need to come back and get a fresh token.

---

## 🧪 **Test the Token (Optional but Recommended)**

Before leaving Graph Explorer, verify the token works:

**Query 1: Get your profile**
```
GET https://graph.microsoft.com/v1.0/me
```
Expected: Your user profile information

**Query 2: Get messages**
```
GET https://graph.microsoft.com/v1.0/me/messages?$top=5
```
Expected: List of your emails (may be empty if no emails sent yet)

**Query 3: Get messages with filter**
```
GET https://graph.microsoft.com/v1.0/me/messages?$filter=receivedDateTime ge 2024-10-01T00:00:00Z&$top=10
```
Expected: Emails from October 2024 onwards

---

## ✅ Success Criteria

You've successfully completed this step when:

- [ ] Signed in to Graph Explorer with jeevan@gptfy.dev
- [ ] Consented to Mail.Read permission
- [ ] Successfully ran a query and got 200 OK
- [ ] **Copied and saved the access token**

---

## 🚀 Next Step

Once you have the access token, proceed to:
**Step 6: Configure Named Credential in Salesforce**

You'll need to paste the token into the Salesforce Named Credential configuration.

---

## 📞 Troubleshooting

### Problem: Can't find sign-in button
**Solution**: Look for "Sign in to Graph Explorer" link or profile icon at top right

### Problem: Permission consent fails
**Solution**: Make sure you're signed in with jeevan@gptfy.dev (not sample tenant)

### Problem: Query returns 401 Unauthorized
**Solution**: You need to consent to Mail.Read permission first

### Problem: Can't find Access token
**Solution**: Look for "Access token" tab near "Request Body" or click your profile picture

---

## 📝 Save Your Token Here (Temporarily)

Once you copy the token, save it here temporarily:

```
ACCESS_TOKEN=

[Paste your token above after copying from Graph Explorer]
```

**Remember:** Token expires in ~1 hour. Don't wait too long before using it in Step 6!

