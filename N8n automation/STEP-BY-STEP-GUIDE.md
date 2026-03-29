# Step-by-Step Guide: Creating Google Calendar to Salesforce Event Workflow in n8n

This guide walks you through creating the complete workflow in n8n from scratch.

---

## Prerequisites Checklist

Before starting, ensure you have:
- [ ] Access to n8n instance (cloud or self-hosted)
- [ ] Google Calendar account with API access
- [ ] Salesforce org with API access
- [ ] Slack workspace (for notifications)
- [ ] Admin access to create custom fields in Salesforce (optional)

---

## Part 1: Salesforce Setup (Do This First)

### Step 1.1: Create Custom Fields in Salesforce

1. **Log into Salesforce**
   - Go to Setup (gear icon → Setup)

2. **Navigate to Object Manager**
   - In Quick Find, type "Object Manager"
   - Click on "Object Manager"

3. **Select Event Object**
   - Find and click on "Event" in the list

4. **Create First Custom Field: Google Calendar Event ID**
   - Click "Fields & Relationships" in the left sidebar
   - Click "New" button
   - Select "Text" as the field type
   - Click "Next"
   - **Field Label**: `Google Calendar Event ID`
   - **Field Name**: `Google_Calendar_Event_ID` (auto-populated)
   - **Length**: `255`
   - **Required**: Unchecked
   - Click "Next"
   - **Field-Level Security**: Check "Visible" for profiles that need access
   - Click "Next"
   - **Page Layout Assignment**: Add to relevant page layouts
   - Click "Save"

5. **Create Second Custom Field: Google Calendar Event Link**
   - Click "New" again
   - Select "URL" as the field type
   - Click "Next"
   - **Field Label**: `Google Calendar Event Link`
   - **Field Name**: `Google_Calendar_Event_Link` (auto-populated)
   - **Required**: Unchecked
   - Click "Next"
   - **Field-Level Security**: Check "Visible" for profiles that need access
   - Click "Next"
   - **Page Layout Assignment**: Add to relevant page layouts
   - Click "Save"

6. **Note the Field API Names**
   - `Google_Calendar_Event_ID__c`
   - `Google_Calendar_Event_Link__c`
   - You'll need these in the workflow

---

## Part 2: n8n Workflow Creation

### Step 2.1: Create New Workflow

1. **Open n8n**
   - Navigate to your n8n instance
   - Log in if needed

2. **Create New Workflow**
   - Click "Workflows" in the left sidebar
   - Click the "+" button or "Add Workflow"
   - Name it: `Google Calendar to Salesforce Event`

3. **Save the Workflow**
   - Click "Save" (top right) to save the empty workflow

---

## Part 2.2: Set Up Google Calendar OAuth2 Credentials

1. **Go to Credentials**
   - Click the menu icon (☰) in the top left
   - Select "Credentials"

2. **Add Google Calendar Credential**
   - Click "Add Credential"
   - Search for "Google Calendar"
   - Select "Google Calendar OAuth2 API"

3. **Configure OAuth2**
   - **Credential Name**: `Google Calendar OAuth2 API`
   - Click "Connect my account"
   - You'll be redirected to Google sign-in
   - Sign in with the Google account that has the calendar you want to monitor
   - Grant permissions:
     - ✅ View your calendars
     - ✅ View events on your calendars
   - Click "Allow"
   - You'll be redirected back to n8n
   - The credential should now be saved

4. **Test the Connection**
   - The credential should show as "Connected"
   - If there's an error, check your Google account permissions

---

## Part 2.3: Set Up Salesforce OAuth2 Credentials

1. **Add Salesforce Credential**
   - Still in Credentials section
   - Click "Add Credential"
   - Search for "Salesforce"
   - Select "Salesforce OAuth2 API"

2. **Configure Salesforce OAuth2**
   - **Credential Name**: `Salesforce OAuth2 API`
   - **Environment**: Select "Production" or "Sandbox" based on your org
   - Click "Connect my account"
   - You'll be redirected to Salesforce login
   - Log in with your Salesforce credentials
   - Click "Allow" to grant access
   - You'll be redirected back to n8n
   - The credential should now be saved

3. **Test the Connection**
   - The credential should show as "Connected"
   - If there's an error, verify your Salesforce org URL and permissions

---

## Part 2.4: Set Up Slack Credentials (Optional but Recommended)

1. **Add Slack Credential**
   - Still in Credentials section
   - Click "Add Credential"
   - Search for "Slack"
   - Select "Slack API"

2. **Configure Slack API**
   - **Credential Name**: `Slack API`
   - **Authentication**: Select "OAuth2" or "Access Token"
   
   **Option A: OAuth2 (Recommended)**
   - Click "Connect my account"
   - Authorize n8n in Slack
   - Select the workspace
   - Grant permissions: `chat:write`, `chat:write.public`
   - Click "Allow"
   
   **Option B: Access Token**
   - Create a Slack App at https://api.slack.com/apps
   - Generate a Bot Token
   - Paste the token in the credential

3. **Test the Connection**
   - The credential should show as "Connected"

---

## Part 3: Building the Workflow Nodes

### Step 3.1: Add Google Calendar Trigger Node

1. **Add Trigger Node**
   - Go back to your workflow
   - Click the "+" button in the canvas
   - Search for "Google Calendar"
   - Select "Google Calendar Trigger"

2. **Configure the Trigger**
   - **Node Name**: `Google Calendar Trigger`
   - **Credential**: Select "Google Calendar OAuth2 API" (the one you created)
   - **Event**: Select "Event Created"
   - **Calendar**: Leave as "primary" or select a specific calendar ID
   - Click "Execute Node" to test (this will show sample data)

3. **Save the Node**
   - Click outside the node or press Ctrl+S to save

---

### Step 3.2: Add Format Event Data Code Node

1. **Add Code Node**
   - Click the "+" button after the Google Calendar Trigger
   - Search for "Code"
   - Select "Code"

2. **Configure the Code Node**
   - **Node Name**: `Format Event Data`
   - **Mode**: Select "Run Once for All Items" or "Run Once for Each Item"
   - **Language**: JavaScript

3. **Add the JavaScript Code**
   - In the code editor, paste the following:

```javascript
// Format Google Calendar event data for Salesforce Event
const googleEvent = $input.item.json;

// Extract relevant data from Google Calendar event
const eventData = {
  Subject: googleEvent.summary || 'Untitled Event',
  Description: googleEvent.description || '',
  StartDateTime: googleEvent.start?.dateTime || googleEvent.start?.date,
  EndDateTime: googleEvent.end?.dateTime || googleEvent.end?.date,
  Location: googleEvent.location || '',
  IsAllDayEvent: !googleEvent.start?.dateTime && !!googleEvent.start?.date,
  // Map Google Calendar attendees to Salesforce Event attendees
  Attendees: googleEvent.attendees?.map(attendee => attendee.email) || [],
  // Store Google Calendar event ID for reference
  GoogleCalendarEventId: googleEvent.id,
  GoogleCalendarEventLink: googleEvent.htmlLink || '',
  // Additional metadata
  OrganizerEmail: googleEvent.organizer?.email || '',
  Status: googleEvent.status || 'confirmed'
};

return {
  json: eventData
};
```

4. **Test the Node**
   - Click "Execute Node" to test with sample data
   - Verify the output shows the formatted data structure

5. **Save the Node**

---

### Step 3.3: Add Create Salesforce Event Node

1. **Add Salesforce Node**
   - Click the "+" button after the Format Event Data node
   - Search for "Salesforce"
   - Select "Salesforce"

2. **Configure the Salesforce Node**
   - **Node Name**: `Create Salesforce Event`
   - **Credential**: Select "Salesforce OAuth2 API"
   - **Resource**: Select "Event"
   - **Operation**: Select "Create"

3. **Configure Fields**
   - Click "Add Field" for each field you want to map:
   
   **Required Fields:**
   - **Subject**: Click the field, then click the expression icon (fx), enter: `{{ $json.Subject }}`
   - **StartDateTime**: Expression: `{{ $json.StartDateTime }}`
   - **EndDateTime**: Expression: `{{ $json.EndDateTime }}`
   
   **Optional Fields:**
   - **Description**: Expression: `{{ $json.Description }}`
   - **Location**: Expression: `{{ $json.Location }}`
   - **IsAllDayEvent**: Expression: `{{ $json.IsAllDayEvent }}`
   
   **Custom Fields:**
   - **Google_Calendar_Event_ID__c**: Expression: `{{ $json.GoogleCalendarEventId }}`
   - **Google_Calendar_Event_Link__c**: Expression: `{{ $json.GoogleCalendarEventLink }}`

4. **Alternative: Use Fields JSON**
   - Instead of adding fields one by one, you can click "Fields (JSON)" tab
   - Paste this JSON:

```json
{
  "Subject": "={{ $json.Subject }}",
  "Description": "={{ $json.Description }}",
  "StartDateTime": "={{ $json.StartDateTime }}",
  "EndDateTime": "={{ $json.EndDateTime }}",
  "Location": "={{ $json.Location }}",
  "IsAllDayEvent": "={{ $json.IsAllDayEvent }}",
  "Google_Calendar_Event_ID__c": "={{ $json.GoogleCalendarEventId }}",
  "Google_Calendar_Event_Link__c": "={{ $json.GoogleCalendarEventLink }}"
}
```

5. **Test the Node** (Optional - will create a real event in Salesforce)
   - Click "Execute Node" to test
   - ⚠️ **Warning**: This will create an actual event in Salesforce!
   - Check your Salesforce org to verify the event was created

6. **Save the Node**

---

### Step 3.4: Add Slack Alert Node (Success Notification)

1. **Add Slack Node**
   - Click the "+" button after the Create Salesforce Event node
   - Search for "Slack"
   - Select "Slack"

2. **Configure the Slack Node**
   - **Node Name**: `Slack Alert`
   - **Credential**: Select "Slack API"
   - **Resource**: Select "Message"
   - **Operation**: Select "Post"

3. **Configure Message**
   - **Channel**: Enter channel name (e.g., `#n8n-alerts`) or use expression: `{{ $env.SLACK_CHANNEL || '#n8n-alerts' }}`
   - **Text**: Click the expression icon (fx) and enter:

```
✅ *New Google Calendar Event Synced to Salesforce*

*Event:* {{ $('Format Event Data').item.json.Subject }}
*Start:* {{ $('Format Event Data').item.json.StartDateTime }}
*End:* {{ $('Format Event Data').item.json.EndDateTime }}
*Location:* {{ $('Format Event Data').item.json.Location || 'N/A' }}
*Salesforce Event ID:* {{ $json.id }}
*Google Calendar Link:* {{ $('Format Event Data').item.json.GoogleCalendarEventLink }}
```

4. **Test the Node** (Optional)
   - Click "Execute Node" to test
   - Check your Slack channel for the message

5. **Save the Node**

---

### Step 3.5: Add Error Trigger Node

1. **Add Error Trigger**
   - Click the "+" button in an empty area of the canvas (not connected to main flow)
   - Search for "Error Trigger"
   - Select "Error Trigger"

2. **Configure Error Trigger**
   - **Node Name**: `Error Trigger`
   - **Continue on Fail**: Check this box (allows workflow to continue processing other events)
   - This node automatically catches errors from any node in the workflow

3. **Position the Node**
   - Drag it to a separate area below the main flow (for visual clarity)

4. **Save the Node**

---

### Step 3.6: Add Send Error to Slack Node

1. **Add Another Slack Node**
   - Click the "+" button after the Error Trigger node
   - Search for "Slack"
   - Select "Slack"

2. **Configure the Error Slack Node**
   - **Node Name**: `Send Error to Slack`
   - **Credential**: Select "Slack API"
   - **Resource**: Select "Message"
   - **Operation**: Select "Post"

3. **Configure Error Message**
   - **Channel**: Enter channel name (e.g., `#n8n-alerts`) or use expression: `{{ $env.SLACK_CHANNEL || '#n8n-alerts' }}`
   - **Text**: Click the expression icon (fx) and enter:

```
❌ *Google Calendar to Salesforce Event Error*

*Error:* {{ $json.error.message }}
*Node:* {{ $json.node.name }}
*Workflow:* {{ $json.workflow.name }}
*Execution ID:* {{ $json.execution.id }}

*Event Data:*
```json
{{ JSON.stringify($json.executionData, null, 2) }}
```
```

4. **Save the Node**

---

## Part 4: Connect the Nodes

### Step 4.1: Connect Main Flow

1. **Connect Google Calendar Trigger → Format Event Data**
   - Hover over the Google Calendar Trigger node
   - Click and drag from the output dot (right side) to the Format Event Data node

2. **Connect Format Event Data → Create Salesforce Event**
   - Drag from Format Event Data output to Create Salesforce Event input

3. **Connect Create Salesforce Event → Slack Alert**
   - Drag from Create Salesforce Event output to Slack Alert input

### Step 4.2: Connect Error Flow

1. **Connect Error Trigger → Send Error to Slack**
   - Drag from Error Trigger output to Send Error to Slack input

---

## Part 5: Final Configuration & Testing

### Step 5.1: Save the Workflow

1. **Save All Changes**
   - Click "Save" button (top right)
   - Or press Ctrl+S / Cmd+S

### Step 5.2: Test the Workflow

1. **Manual Test Execution**
   - Click "Execute Workflow" button (top right)
   - This will run the workflow with sample/test data
   - Review each node's output to ensure data flows correctly

2. **Test with Real Google Calendar Event**
   - Create a test event in your Google Calendar
   - Wait a few seconds
   - Check n8n execution logs to see if the workflow triggered
   - Verify the event was created in Salesforce
   - Check Slack for notifications

### Step 5.3: Activate the Workflow

1. **Activate the Workflow**
   - Toggle the "Active" switch at the top of the workflow (or in workflow settings)
   - The workflow is now live and will trigger automatically when Google Calendar events are created

2. **Verify Activation**
   - The workflow should show as "Active" in the workflows list
   - The Google Calendar Trigger should show as listening for events

---

## Part 6: Monitoring & Troubleshooting

### Step 6.1: Monitor Executions

1. **View Execution History**
   - Click on "Executions" in the left sidebar
   - Filter by your workflow name
   - Click on any execution to see detailed logs

2. **Check Node Outputs**
   - In execution view, click on each node to see:
     - Input data
     - Output data
     - Any errors

### Step 6.2: Common Issues & Solutions

**Issue: Workflow not triggering**
- ✅ Check if workflow is "Active"
- ✅ Verify Google Calendar OAuth2 credentials are valid
- ✅ Check Google Calendar webhook is properly configured
- ✅ Verify the calendar you're monitoring has events

**Issue: Salesforce event not created**
- ✅ Verify Salesforce OAuth2 credentials
- ✅ Check field API names are correct (especially custom fields)
- ✅ Verify you have permission to create Events in Salesforce
- ✅ Check Salesforce API limits haven't been exceeded

**Issue: Slack notifications not sending**
- ✅ Verify Slack API credentials
- ✅ Check channel name is correct (include # for public channels)
- ✅ Verify bot has permission to post in the channel
- ✅ Check Slack API rate limits

**Issue: Date/time format errors**
- ✅ Verify Google Calendar is sending dates in ISO 8601 format
- ✅ Check timezone handling in the Format Event Data node
- ✅ Ensure Salesforce is receiving dates in correct format

**Issue: Custom fields not saving**
- ✅ Verify custom fields exist in Salesforce
- ✅ Check field API names match exactly (case-sensitive)
- ✅ Verify field-level security allows updates
- ✅ Ensure fields are on the Event page layout

---

## Part 7: Optional Enhancements

### Step 7.1: Add Event Filtering

If you only want to sync certain events:

1. **Add IF Node**
   - Add an "IF" node between Format Event Data and Create Salesforce Event
   - Configure condition (e.g., only sync events with specific keywords)

2. **Example Filter**
   - Condition: `{{ $json.Subject }}` contains "Meeting"
   - Only events with "Meeting" in the subject will proceed

### Step 7.2: Add Multiple Calendar Support

1. **Modify Google Calendar Trigger**
   - Add multiple trigger nodes for different calendars
   - Or use a loop to process multiple calendars

### Step 7.3: Add Attendee Management

1. **Add Code Node After Format Event Data**
   - Look up Contacts/Leads by email from attendees array
   - Create EventRelation records in Salesforce

---

## Part 8: Workflow Summary

Your complete workflow should look like this:

```
Google Calendar Trigger
    ↓
Format Event Data (Code)
    ↓
Create Salesforce Event
    ↓
Slack Alert

Error Trigger (separate branch)
    ↓
Send Error to Slack
```

---

## Quick Reference: Node Configuration Summary

| Node | Credential | Key Settings |
|------|-----------|--------------|
| Google Calendar Trigger | Google Calendar OAuth2 | Event: "Event Created" |
| Format Event Data | None | JavaScript code for transformation |
| Create Salesforce Event | Salesforce OAuth2 | Resource: Event, Operation: Create |
| Slack Alert | Slack API | Resource: Message, Operation: Post |
| Error Trigger | None | Continue on Fail: Enabled |
| Send Error to Slack | Slack API | Resource: Message, Operation: Post |

---

## Next Steps

1. ✅ Test the workflow thoroughly
2. ✅ Monitor first few real executions
3. ✅ Adjust field mappings if needed
4. ✅ Customize Slack notification format
5. ✅ Consider adding filtering or other enhancements

---

## Support Resources

- **n8n Documentation**: https://docs.n8n.io/
- **Google Calendar API**: https://developers.google.com/calendar/api
- **Salesforce REST API**: https://developer.salesforce.com/docs/atlas.en-us.api_rest.meta/api_rest/
- **Slack API**: https://api.slack.com/

---

**Congratulations!** Your Google Calendar to Salesforce Event workflow is now set up and running! 🎉
