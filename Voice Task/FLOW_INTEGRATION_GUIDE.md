# Flow Integration Guide

## ✅ Deployment Complete!

**Apex Class Deployed**: `MeetingTranscriptProcessor`  
**Org**: tso@gptyfy.com

---

## How It Works Now

### Current Simplified Flow:

```
┌─────────────────┐
│ Voice Recording │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Language Model │  (Transcribes voice)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Create Event   │  **Description = Transcript**
│   (Your Flow)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Apex Action    │  ← **ADD THIS STEP**
│ "Process Meeting│
│   Transcript"   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Results Stored  │
│ - Task Created  │
│ - Opp Created   │
│ - Contact Linked│
└─────────────────┘
```

---

## How to Update Your Flow

### Step 1: Open Your Existing Flow
1. Go to **Setup** → **Flows**
2. Find your flow that creates Events from voice recordings
3. Click **Edit**

### Step 2: Add the Apex Action
After your **"Create Records"** element (that creates the Event):

1. Click the **+** icon to add a new element
2. Select **Action**
3. In the search box, type: **"Process Meeting Transcript"**
4. Select it and click **Done**

### Step 3: Configure the Action

**Label**: Process Meeting Transcript  
**API Name**: ProcessMeetingTranscript

**Input Values:**
- **Event Id**: 
  - Click the field
  - Select **{!$Record.Id}** (if using Record-Triggered Flow)
  - OR select the output ID from your "Create Records" element
  
- **LLM Parsed Data**: 
  - Leave blank for now (optional)
  - Later, if your LM can output JSON, map it here

**Store Output Values:**
Create these variables and map them:
1. **var_Success** (Boolean) → isSuccess
2. **var_ContactId** (Text) → contactId  
3. **var_TaskId** (Text) → taskId
4. **var_OpportunityId** (Text) → opportunityId
5. **var_FollowUpSuggestions** (Text) → followUpSuggestions
6. **var_ErrorMessage** (Text) → errorMessage

### Step 4: Save and Activate
1. Click **Save**
2. Click **Activate**
3. Done! ✅

---

## Important: Event Description Must Contain Transcript

**Your Flow MUST** put the transcript in the Event's Description field when creating it:

```
Create Records (Event):
  ├─ Subject: "Business Development Meeting"
  ├─ StartDateTime: {!Now}
  ├─ EndDateTime: {!Now + 1 hour}
  └─ Description: {!TranscriptFromLM}  ← **CRITICAL!**
```

The Apex class reads the transcript FROM the Event's Description field.

---

## Option: Automatic Trigger for ALL Events

If you want this to run automatically on **EVERY** Event created (not just from voice), I can create a **Record-Triggered Flow**:

### Record-Triggered Flow on Event
- **Trigger**: When Event is created
- **Condition**: Description is not empty
- **Action**: Calls MeetingTranscriptProcessor Apex

**Do you want me to create this automatic trigger?** (Let me know!)

---

## Testing

### Manual Test:
1. Create a Contact in Salesforce: **Sarah Chen**
2. Create an Event manually with this Description:
   ```
   Met with Sarah Chen at the Family Office Summit. 
   Interested in impact investing and climate tech. 
   Timeline Q2 2026. Referred by Paul Chew.
   ```
3. Run your Flow (or trigger it manually)
4. Check:
   - ✅ Event is linked to Sarah Chen
   - ✅ Task created under Sarah Chen (due in 7 days)
   - ✅ Opportunity created/updated
   - ✅ Follow-up suggestions generated

---

## What Happens Automatically

When your Flow calls the Apex action:

1. ✅ **Reads transcript** from Event.Description
2. ✅ **Identifies contact** by name (searches Salesforce)
3. ✅ **Links Event to Contact**
4. ✅ **Creates Task** under Contact with:
   - Topics of interest
   - Referral source
   - Timeline
   - Due date: 7 days
5. ✅ **Creates/Updates Opportunity** with:
   - Interests as tags
   - Close date from timeline (e.g., Q2 2026)
   - Opportunity Contact Role
6. ✅ **Returns follow-up suggestions** like:
   - "Send climate tech deal memo"
   - "Thank Paul Chew for referral"
   - "Schedule follow-up before Q2 2026"

---

## Ready to Go! 🚀

Your Apex is deployed and working. Just add the Action element to your Flow and you're done!

**Need help adding it to the Flow? Let me know!**

