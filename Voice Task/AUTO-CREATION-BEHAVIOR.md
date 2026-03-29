# Auto-Creation Behavior - Complete Guide

## ✅ **Successfully Deployed!**

**Org**: tso@gptyfy.com  
**Date**: November 3, 2025

---

## 🎯 **What Happens Now**

### Scenario 1: Contact EXISTS in Salesforce
```
Voice Recording → Transcript → Event Created
   ↓
Apex finds existing Contact "Sarah Chen"
   ↓
✅ Links Event to Contact
✅ Creates Task under Contact
✅ Checks for existing Opportunity:
   - If EXISTS → Updates it with new info
   - If NO Opportunity → Creates NEW Opportunity
✅ Returns follow-up suggestions
```

### Scenario 2: Contact DOES NOT EXIST (NEW FEATURE!)
```
Voice Recording → Transcript → Event Created
   ↓
Apex searches for Contact "Michael Johnson"
   ↓
❌ Not found in Salesforce
   ↓
✅ Auto-creates NEW Account: "Johnson Family Office"
✅ Auto-creates NEW Contact: Michael Johnson
✅ Links Contact to Account
✅ Links Event to new Contact
✅ Creates Task under new Contact
✅ Creates NEW Opportunity (always new for new contacts)
✅ Returns follow-up suggestions
```

### Scenario 3: Cannot Parse Contact Name
```
Voice Recording → Transcript → Event Created
   ↓
Apex tries to extract contact name from transcript
   ↓
❌ No valid name found (e.g., "Met with someone")
   ↓
❌ Process fails with error
   ℹ️  Manual intervention required
```

---

## 📊 **Opportunity Creation/Update Logic**

### For NEW Contacts:
- ✅ **Always creates NEW Opportunity**
- Stage: "Qualification"
- Close Date: From timeline or default +3 months
- Includes interests, referral info
- Creates Opportunity Contact Role

### For EXISTING Contacts:
- **Checks Account and Contact Roles** for open Opportunities
- **If found**: Updates existing Opportunity with new discussion notes
- **If NOT found**: Creates NEW Opportunity

---

## 🔍 **What Gets Created**

### Account (if needed):
- **Name**: `[LastName] Family Office`
- **Example**: "Johnson Family Office"

### Contact (if needed):
- **FirstName**: Parsed from transcript
- **LastName**: Parsed from transcript
- **AccountId**: Links to created Account
- **Description**: "Auto-created from voice meeting transcript. Event: [Event Name]"

### Task (always):
- **Subject**: "Follow-up: [Event Name]"
- **WhoId**: Contact ID
- **Status**: Not Started
- **Priority**: High
- **Due Date**: +7 days from today
- **Description**: Includes interests, referral source, timeline

### Opportunity (always):
- **Name**: "[Contact Name] - [Opportunity Type]"
- **AccountId**: Contact's Account
- **StageName**: "Qualification" (for new)
- **CloseDate**: From timeline (e.g., Q2 2026 → June 30, 2026)
- **Type**: Direct deal exploration / Fund Investment / etc.
- **Description**: Interests and referral info

### Opportunity Contact Role (for new opportunities):
- **ContactId**: The identified/created contact
- **Role**: Decision Maker
- **IsPrimary**: true

---

## 📝 **Input Requirements**

### Event Description Must Include:
```
Met with [First Last] at the [Event Name].
Interested in [topic 1], [topic 2].
Timeline: Q2 2026
Referred by [Referral Name]
```

### Flow Input:
- **Event Id**: ID of the created Event (required)
- **LLM Parsed Data**: Optional JSON with structured data

### Optional LLM JSON Format:
```json
{
  "contactName": "Michael Johnson",
  "eventName": "Investment Summit",
  "interests": ["ESG", "Impact Investing"],
  "timeline": "Q3 2026",
  "estimatedCloseDate": "2026-09-30",
  "referralSource": "Paul Chew",
  "opportunityType": "Direct deal exploration"
}
```

---

## ✅ **Success Outputs**

- **isSuccess**: true
- **contactId**: ID of identified or newly created Contact
- **taskId**: ID of created Task
- **opportunityId**: ID of created or updated Opportunity
- **followUpSuggestions**: AI-generated action items
- **errorMessage**: null

---

## ❌ **Error Scenarios**

### Error 1: Empty Description
- **Message**: "Event Description (transcript) cannot be empty"
- **Cause**: Event has no Description field populated
- **Fix**: Ensure your Flow puts the transcript in Event.Description

### Error 2: Cannot Parse Contact Name
- **Message**: "Could not identify or create contact from transcript. Unable to parse contact name."
- **Cause**: Transcript doesn't contain recognizable name pattern
- **Fix**: 
  - Use clearer format: "Met with [First Last]"
  - OR provide LLM Parsed Data with contactName field

### Error 3: DML Errors
- **Message**: "Error processing transcript: [Salesforce error]"
- **Cause**: Permission issues, validation rules, required fields
- **Fix**: Check user permissions, org validation rules

---

## 🎨 **Example Use Cases**

### Use Case 1: First Meeting with New Prospect
```
Transcript: "Met with Jennifer Williams at the Private Equity Conference. 
She's interested in ESG investing and impact funds. Timeline Q1 2026. 
Referred by David Miller."

Result:
✅ Account created: "Williams Family Office"
✅ Contact created: Jennifer Williams
✅ Event linked to Jennifer
✅ Task created: Due in 7 days
✅ Opportunity created: "Jennifer Williams - New Business Opportunity"
   - Stage: Qualification
   - Close Date: March 31, 2026
   - Description: "Interests: ESG, Impact Investing / Referral: David Miller"
✅ Suggestions: 
   - "Share impact investing framework and case studies"
   - "Schedule follow-up call before Q1 2026"
   - "Send thank you note to David Miller"
```

### Use Case 2: Follow-up with Existing Contact
```
Transcript: "Met with Sarah Chen at follow-up lunch. 
Discussed climate tech portfolio. She wants to see Q4 2026 opportunities."

Result:
✅ Contact found: Sarah Chen (existing)
✅ Event linked to Sarah
✅ Task created: Due in 7 days
✅ Opportunity UPDATED (if one exists) or CREATED (if none)
   - Updates existing with: "[Updated from meeting: 11/3/2025] Additional Interests: Climate Tech"
   - Close Date updated to Dec 31, 2026 if later than current
✅ Suggestions:
   - "Send climate tech deal memo and portfolio overview"
   - "Schedule follow-up call before Q4 2026"
```

---

## 🚀 **Ready to Use!**

The solution is deployed and ready. Your Flow just needs to:

1. Create Event with transcript in Description
2. Call Apex Action: "Process Meeting Transcript"
3. Pass Event ID
4. Done! Everything else is automatic.

**No manual Contact/Opportunity creation needed anymore!** 🎉

