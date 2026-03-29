# Google Calendar to Salesforce Event - n8n Workflow

This n8n workflow automatically creates a Salesforce Event whenever a new event is created in Google Calendar.

## Overview

The workflow follows a similar structure to your existing Calendly workflow:
- **Trigger**: Google Calendar event creation
- **Data Transformation**: Format Google Calendar event data for Salesforce
- **Salesforce Integration**: Create event in Salesforce
- **Error Handling**: Send Slack notifications on errors

## Workflow Structure

1. **Google Calendar Trigger** - Monitors for new calendar events
2. **Format Event Data** - Transforms Google Calendar event data to Salesforce Event format
3. **Create Salesforce Event** - Creates the event record in Salesforce
4. **Error Trigger** - Catches any errors in the workflow
5. **Send Error to Slack** - Notifies team via Slack if errors occur

## Setup Instructions

### Prerequisites

1. **n8n Instance** - Ensure you have n8n installed and running
2. **Google Calendar API Credentials** - OAuth2 credentials for Google Calendar
3. **Salesforce API Credentials** - OAuth2 credentials for Salesforce
4. **Slack API Credentials** (optional, for error notifications)

### Salesforce Custom Fields

Before importing the workflow, ensure your Salesforce org has these custom fields on the Event object (if you want to store Google Calendar metadata):

- `Google_Calendar_Event_ID__c` (Text, 255)
- `Google_Calendar_Event_Link__c` (URL, 255)

**Note**: If you don't want to use custom fields, you can remove them from the "Create Salesforce Event" node configuration.

### Import Steps

1. Open your n8n instance
2. Click **"Workflows"** → **"Import from File"**
3. Select `google-calendar-to-salesforce-event.json`
4. Configure the credentials for each node:
   - **Google Calendar Trigger**: Set up Google Calendar OAuth2
   - **Create Salesforce Event**: Set up Salesforce OAuth2
   - **Send Error to Slack**: Set up Slack API (if using)

### Google Calendar Trigger Configuration

1. Click on the **Google Calendar Trigger** node
2. Select your Google Calendar OAuth2 credentials
3. Choose the calendar to monitor (or leave default for primary calendar)
4. Configure the event type: **"Event Created"**

### Salesforce Event Node Configuration

The workflow maps Google Calendar fields to Salesforce Event fields:

| Google Calendar | Salesforce Event |
|----------------|------------------|
| `summary` | `Subject` |
| `description` | `Description` |
| `start.dateTime` or `start.date` | `StartDateTime` |
| `end.dateTime` or `end.date` | `EndDateTime` |
| `location` | `Location` |
| `start.date` (without time) | `IsAllDayEvent` (true) |
| `id` | `Google_Calendar_Event_ID__c` (custom field) |
| `htmlLink` | `Google_Calendar_Event_Link__c` (custom field) |

### Customization Options

#### Adding Attendees

If you want to create Event Relations (attendees) in Salesforce, you can add a code node after "Format Event Data" to:
- Look up Contacts/Leads by email
- Create EventRelation records

#### Adding Slack Notifications

Similar to your Calendly workflow, you can add a Slack notification node after "Create Salesforce Event" to notify your team about new events.

#### Filtering Events

Add a filter node after "Format Event Data" to only process specific events (e.g., events with certain keywords, specific calendars, etc.).

## Testing

1. Activate the workflow in n8n
2. Create a test event in your Google Calendar
3. Check the execution logs in n8n
4. Verify the event was created in Salesforce

## Troubleshooting

### Common Issues

1. **Events not triggering**: 
   - Verify Google Calendar OAuth2 credentials
   - Check that the workflow is activated
   - Ensure webhook is properly configured

2. **Salesforce errors**:
   - Verify Salesforce OAuth2 credentials
   - Check that custom fields exist (if used)
   - Verify field permissions in Salesforce

3. **Date/time format issues**:
   - Salesforce expects ISO 8601 format (e.g., `2026-01-27T10:00:00Z`)
   - The code node handles conversion automatically

## Similar to Calendly Workflow

This workflow follows the same pattern as your Calendly workflow:
- ✅ External calendar trigger
- ✅ Data transformation/formatting
- ✅ Salesforce record creation
- ✅ Error handling with Slack notifications

The main differences:
- Uses Google Calendar trigger instead of Calendly
- Creates Events instead of Leads/Tasks
- Simpler data flow (no Apollo enrichment needed)

## Next Steps

Consider adding:
- Event update handling (when Google Calendar events are modified)
- Event deletion handling
- Attendee management (EventRelation records)
- Additional data enrichment (similar to Apollo in your Calendly flow)
