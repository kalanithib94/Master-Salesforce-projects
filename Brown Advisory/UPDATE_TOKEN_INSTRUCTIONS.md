# How to Update the Access Token in Salesforce

## ⚠️ Important: Token Format

Your token should be entered in the Named Credential **exactly** like this:

```
Bearer <PASTE_MICROSOFT_GRAPH_TOKEN_FROM_GRAPH_EXPLORER>
```

**Note:** Obtain a short-lived token from [Microsoft Graph Explorer](https://developer.microsoft.com/graph/graph-explorer); do not commit real tokens to git.

---

## Step-by-Step Instructions

### 1. Login to Salesforce
- URL: https://tsogptfy.my.salesforce.com
- Login with: `tso@gptyfy.com`

### 2. Navigate to Named Credentials
1. Click **Setup** (gear icon, top right)
2. In Quick Find box (left sidebar), type: **"Named Credentials"**
3. Click **"Named Credentials"** from results

### 3. Edit OutlookGraphAPI
1. Find **"OutlookGraphAPI"** in the list
2. Click **"Edit"** button next to it

### 4. Configure Callout Options
Scroll down to **"Callout Options"** section:

1. ✅ Check **"Generate Authorization Header"**
2. **Authorization Scheme**: Select **"Custom"** from dropdown
3. **Custom Authorization Header**: Paste this EXACT value:

```
Bearer <PASTE_MICROSOFT_GRAPH_TOKEN_FROM_GRAPH_EXPLORER>
```

**⚠️ CRITICAL:**
- Must start with `Bearer ` (with a space after Bearer)
- Must be all on ONE line (no line breaks)
- No extra spaces before or after
- No quotes around it

### 5. Save
Click **"Save"** at the bottom

---

## Test After Updating

After saving, run this test script in Developer Console:

1. **Developer Console** → **Debug** → **Open Execute Anonymous Window**
2. Copy the code from: `scripts/apex/test-with-token.apex`
3. Paste and click **Execute**
4. Check the debug log - you should see:
   - ✅ Status Code: 200
   - ✅ User information
   - ✅ Message count

---

## ⚠️ Important Notes

1. **Token Expiration**: This token expires in ~1 hour. If you get 401 errors later, get a fresh token from Graph Explorer.

2. **Token Format**: The token must be exactly:
   ```
   Bearer [your-token-here]
   ```
   - One space between "Bearer" and the token
   - No extra characters
   - All on one line

3. **If Still Getting Errors**: 
   - Verify the token hasn't expired
   - Check for extra spaces or characters
   - Make sure "Generate Authorization Header" is checked
   - Make sure "Authorization Scheme" is set to "Custom"

