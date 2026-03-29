# Apex Class Troubleshooting Guide

## 🔍 How to Troubleshoot Errors

---

## Method 1: Check Error Messages from Flow (Easiest)

### In Your Flow:
1. After the Apex Action element, add a **Decision** element
2. Check condition: `{!Apex_Result.isSuccess} Equals false`
3. Add a **Screen** element to display:
   - Error Message: `{!Apex_Result.errorMessage}`
   - Contact ID: `{!Apex_Result.contactId}`
   - Event ID: `{!Event.Id}`

### Flow Structure:
```
Apex Action: Process Meeting Transcript
   ↓
Decision: Is Success?
   ├─ No → Show Error Screen
   │        Display: {!errorMessage}
   │
   └─ Yes → Continue with success path
```

---

## Method 2: Enable Debug Logs (Detailed)

### Step 1: Setup Debug Logs
1. Go to **Setup** → Type "Debug Logs" in Quick Find
2. Click **Debug Logs**
3. Click **New** button
4. **Traced Entity Type**: User
5. **Traced Entity Name**: Select your username
6. **Start Date**: Today
7. **Expiration Date**: Tomorrow
8. **Debug Level**: Select or create one with:
   - Apex Code: FINEST
   - Apex Profiling: FINEST
   - Database: FINEST
   - System: DEBUG
9. Click **Save**

### Step 2: Run Your Flow
1. Trigger the voice recording/flow that creates the Event
2. Wait for it to complete

### Step 3: Check the Logs
1. Go back to **Setup** → **Debug Logs**
2. Click **View** on the most recent log
3. Look for:
   - `USER_DEBUG` lines with your custom messages
   - `EXCEPTION_THROWN` for errors
   - Search for "MeetingTranscriptProcessor" to find relevant sections

### What to Look For:
```
Error messages will look like:
EXCEPTION_THROWN|[XXX]|System.DmlException: Insert failed...
or
USER_DEBUG|[XXX]|Error in processMeetingTranscript: ...
```

---

## Method 3: Test in Developer Console (Best for Testing)

### Step 1: Open Developer Console
1. Click the gear icon (⚙️) in top right
2. Select **Developer Console**

### Step 2: Create Test Event
Execute this in Anonymous Apex:
```apex
// Create a test contact first (optional, or Apex will auto-create)
Contact testContact = new Contact(
    FirstName = 'Test',
    LastName = 'Person',
    Email = 'test@example.com'
);
insert testContact;

// Create a test event with transcript
Event testEvent = new Event(
    Subject = 'Test Meeting',
    StartDateTime = System.now(),
    EndDateTime = System.now().addHours(1),
    Description = 'Met with Sarah Chen at the Family Office Summit. Interested in climate tech and impact investing. Timeline Q2 2026. Referred by Paul Chew.'
);
insert testEvent;

// Call the Apex class
MeetingTranscriptProcessor.ProcessRequest request = new MeetingTranscriptProcessor.ProcessRequest();
request.eventId = testEvent.Id;

List<MeetingTranscriptProcessor.ProcessResult> results = 
    MeetingTranscriptProcessor.processMeetingTranscript(
        new List<MeetingTranscriptProcessor.ProcessRequest>{request}
    );

// Check results
MeetingTranscriptProcessor.ProcessResult result = results[0];
System.debug('Success: ' + result.isSuccess);
System.debug('Error: ' + result.errorMessage);
System.debug('Contact ID: ' + result.contactId);
System.debug('Task ID: ' + result.taskId);
System.debug('Opportunity ID: ' + result.opportunityId);
System.debug('Suggestions: ' + result.followUpSuggestions);
```

### Step 3: Check Debug Output
1. At the bottom of Developer Console, click **Logs** tab
2. Double-click the most recent log
3. Click **Debug Only** filter
4. Look for your System.debug statements

---

## Method 4: Use Salesforce Inspector (Chrome Extension)

### Install:
1. Install "Salesforce Inspector" Chrome extension
2. Open Salesforce
3. Click the extension icon

### Check Records:
1. Go to the Event record that was created
2. Click "Show all data"
3. Verify:
   - Description field has the transcript
   - WhoId is populated (Contact linked)
4. Search for Tasks related to the Contact
5. Search for Opportunities related to the Contact

---

## 🐛 Common Errors and Solutions

### Error 1: "Event Description (transcript) cannot be empty"
**Cause**: Event.Description is null or blank

**Solution**:
- Verify your Flow puts the transcript in Event.Description field
- Check: `Create Event` → `Description` field is mapped to your transcript variable

---

### Error 2: "Could not identify or create contact from transcript"
**Cause**: Unable to parse contact name from transcript

**Solutions**:
1. Check transcript format includes: "Met with [First Last]"
2. Update Event Description to have clearer name format
3. Or provide LLM Parsed Data with contactName field

**Test in Developer Console**:
```apex
String transcript = 'YOUR TRANSCRIPT HERE';
System.debug('Testing extraction...');
Pattern p = Pattern.compile('(?i)met with ([A-Z][a-z]+ [A-Z][a-z]+)');
Matcher m = p.matcher(transcript);
if (m.find()) {
    System.debug('Found contact: ' + m.group(1));
} else {
    System.debug('No contact name found!');
}
```

---

### Error 3: "Insert failed" or "DML Exception"
**Causes**:
- Missing required fields on Contact/Account/Opportunity
- Validation rules failing
- Insufficient permissions

**Solutions**:
1. Check validation rules on Contact, Account, Opportunity, Task objects
2. Verify user has Create permission on all objects
3. Check required fields on these objects
4. Look at the full error message in debug logs for specific field

**Check Permissions**:
```
Setup → Users → [Your User] → Permission Sets
Verify permissions for:
- Create on Contact
- Create on Account  
- Create on Opportunity
- Create on Task
- Create on Event
- Edit on Event (to link WhoId)
```

---

### Error 4: "Apex CPU time limit exceeded"
**Cause**: Processing taking too long (usually not an issue for single records)

**Solution**:
- Process one Event at a time
- Check for infinite loops or unnecessary queries in customizations

---

### Error 5: "SOQL 101 Error" or "Too many SOQL queries"
**Cause**: Too many database queries (governor limit: 100)

**Solution**:
- Process Events individually, not in bulk
- Contact support if processing single Event

---

## 📊 Quick Diagnostic Checklist

Run through this checklist:

```
□ Event record exists? Check Event ID
□ Event.Description has transcript text?
□ Transcript contains contact name after "Met with"?
□ User has Create permission on Contact, Account, Opportunity, Task?
□ No validation rules blocking Contact/Account/Opportunity creation?
□ Debug logs enabled for your user?
□ Checked debug logs for error details?
```

---

## 🔧 Advanced: Enable More Detailed Logging

Add this to the Apex class temporarily for more debugging:

### In Developer Console:
1. Open `MeetingTranscriptProcessor` class
2. Add more debug statements:

```apex
// Around line 85, add:
System.debug('Event Description: ' + evt.Description);
System.debug('Parsed contact name: ' + meetingData.contactName);
System.debug('Parsed event name: ' + meetingData.eventName);
System.debug('Parsed interests: ' + meetingData.interests);
System.debug('Parsed timeline: ' + meetingData.timeline);
```

Then run your test and check debug logs.

---

## 📞 Get Help

If still stuck, provide these details:

1. **Error Message**: The exact error from `errorMessage` output
2. **Event ID**: The ID of the Event that was created
3. **Transcript**: The transcript text in Event.Description
4. **Debug Log**: Copy the relevant portions from Setup → Debug Logs
5. **What worked**: Did it find the contact? Create the task?

---

## ✅ Success Indicators

When working correctly, you should see:

```
In Debug Logs:
- "Created new Contact: [Name] (ID: ...)" 
- No EXCEPTION_THROWN lines
- No DML errors

In Salesforce:
- Event has WhoId populated (linked to Contact)
- Task exists under Contact (Related Items)
- Opportunity exists for Account
- No error emails sent
```

---

## 🚀 Pro Tips

1. **Test with Simple Data First**: Use a basic transcript like "Met with John Smith"
2. **One Thing at a Time**: Test just the Apex class first, then integrate with Flow
3. **Use Developer Console**: Fastest way to test and debug
4. **Check Object Permissions**: Most errors are permission-related
5. **Read Full Error Message**: Don't just look at first line, read the complete stack trace

---

Need help with a specific error? Share the error message and I'll help you fix it! 🛠️

