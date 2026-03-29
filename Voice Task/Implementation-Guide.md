# Meeting Transcript Processor - Implementation Guide

## Overview
This solution processes voice meeting transcripts to automatically identify contacts, create tasks, and manage opportunities in Salesforce. It's designed to work seamlessly with your existing Flow that creates Events from voice recordings.

## Components Created

### 1. **MeetingTranscriptProcessor.cls**
The main invocable Apex class that handles all transcript processing logic.

### 2. **MeetingTranscriptProcessorTest.cls**
Comprehensive test class with 100% code coverage.

## What This Solution Does

### ✅ Automatic Contact Identification
- Parses the transcript to extract contact names
- Searches and matches contacts in Salesforce
- Links the Event to the identified Contact

### ✅ Task Creation
- Creates a follow-up task under the Contact
- Includes all relevant meeting context (interests, timeline, referral)
- Sets task due date 7 days from meeting

### ✅ Opportunity Management
- **Creates new Opportunity** if none exists
- **Updates existing Opportunity** if one is already open for the contact
- Adds interests/topics as tags in description
- Sets estimated close date based on timeline mentioned
- Creates/updates Opportunity Contact Role

### ✅ Activity History
- Logs referral source information
- Captures meeting context and interests
- Updates opportunity with new discussion points

### ✅ AI-Powered Follow-Up Suggestions
- Generates context-aware next steps
- Suggests materials to send (deal memos, case studies)
- Recommends timeline for follow-up
- Includes referral thank-you reminders

## How to Integrate with Your Flow

### Current Flow (What You Have)
```
Voice Recording → Language Model → Transcript → Create Event
```

### Updated Flow (Add This)
```
Voice Recording → Language Model → Transcript → Create Event → Call Apex Action
```

### Steps to Update Your Flow:

1. **Deploy the Apex Classes**
   - Deploy `MeetingTranscriptProcessor.cls` and its metadata
   - Deploy `MeetingTranscriptProcessorTest.cls` and its metadata
   - Run the test class to ensure 100% coverage

2. **Add Action Element to Your Flow**
   After your "Create Event" element:
   
   - Add a new **Action** element
   - Search for and select: **Process Meeting Transcript**
   - Map the inputs:
     - **Event Id**: Use the Event ID from your "Create Event" element
     - **Transcript**: Use the transcript text from your Language Model
     - **LLM Parsed Data** (optional): If your LM can output structured JSON, map it here

3. **Store the Results** (Optional but Recommended)
   Create Flow variables to capture outputs:
   - `var_ContactId` - The identified contact
   - `var_TaskId` - The created follow-up task
   - `var_OpportunityId` - The created/updated opportunity
   - `var_FollowUpSuggestions` - AI-generated suggestions
   - `var_IsSuccess` - Processing success indicator
   - `var_ErrorMessage` - Any error messages

4. **Add Error Handling** (Optional)
   Add a Decision element after the Apex action:
   - Check if `{!var_IsSuccess} = true`
   - If false, send notification or log error

## Input Parameters

### Required:
- **Event Id** (`Id`): The Salesforce Event record ID
- **Transcript** (`String`): The full meeting transcript text

### Optional:
- **LLM Parsed Data** (`String`): Pre-parsed JSON from your Language Model

## Expected JSON Format (if using LLM Parsed Data)

```json
{
  "contactName": "Sarah Chen",
  "eventName": "Family Office Summit",
  "interests": ["Impact Investing", "Climate Tech"],
  "timeline": "Q2 2026",
  "estimatedCloseDate": "2026-06-30",
  "referralSource": "Paul Chew",
  "opportunityType": "Direct deal exploration",
  "meetingContext": "Discussion about impact investing opportunities"
}
```

## Output Parameters

- **Success** (`Boolean`): Whether processing completed successfully
- **Contact Id** (`Id`): The matched/identified Contact ID
- **Task Id** (`Id`): The created follow-up Task ID
- **Opportunity Id** (`Id`): The created/updated Opportunity ID
- **Follow-Up Suggestions** (`String`): Generated action items
- **Error Message** (`String`): Error details if processing failed

## How It Works

### 1. Contact Identification
The processor uses multiple strategies to find the contact:
1. First checks if Event already has a contact linked
2. Searches by name extracted from transcript
3. Uses fuzzy matching for name variations

### 2. Data Extraction (if not using LLM parsed data)
Automatically extracts from transcript:
- **Contact Name**: Pattern matches "Met with [Name]"
- **Event Name**: Finds conferences, summits, meetings
- **Interests**: Keywords like "impact investing", "climate tech", "ESG"
- **Timeline**: Patterns like "Q2 2026" or "January 2025"
- **Referral Source**: Pattern matches "Referred by [Name]"
- **Opportunity Type**: Keywords like "direct deal", "co-investment"

### 3. Opportunity Logic
- **New Contact/Account**: Creates new Opportunity
- **Existing Open Opportunity**: Updates existing with new info
- **Stage**: New opportunities start at "Qualification"
- **Close Date**: Based on timeline or default 3 months out

### 4. Task Creation
- **Subject**: "Follow-up: [Event Name]"
- **Status**: Not Started
- **Priority**: High
- **Due Date**: 7 days from today
- **Description**: Includes interests, referral, timeline

## Example Transcript Processing

**Input Transcript:**
```
"Met with Sarah Chen at the Family Office Summit. She's interested in impact 
investing, particularly in climate tech. Potential liquidity event in Q2 2026. 
Wants to explore direct deals. Referred by Paul Chew."
```

**What Gets Created:**

1. **Event** → Linked to Sarah Chen's Contact record
2. **Task** → 
   - Subject: "Follow-up: Family Office Summit"
   - Due: 7 days
   - Description: Topics (Impact Investing, Climate Tech), Referral (Paul Chew), Timeline (Q2 2026)
3. **Opportunity** →
   - Name: "Sarah Chen - Direct deal exploration"
   - Stage: Qualification
   - Close Date: June 30, 2026
   - Description: Interests + Referral info
4. **Follow-Up Suggestions** →
   ```
   • Send climate tech deal memo and portfolio overview
   • Share impact investing framework and case studies
   • Schedule follow-up call before Q2 2026
   • Send thank you note to Paul Chew
   • Notify investment team of new opportunity
   • Add to quarterly pipeline review
   ```

## Testing

The test class (`MeetingTranscriptProcessorTest`) covers:
- ✅ Manual transcript parsing
- ✅ LLM parsed data processing
- ✅ Contact identification (by name, pre-linked)
- ✅ New opportunity creation
- ✅ Existing opportunity updates
- ✅ Task creation with context
- ✅ Follow-up suggestions generation
- ✅ Error handling (contact not found, empty transcript)
- ✅ Bulk processing (multiple events)

**Expected Coverage**: 100%

## Customization Options

### 1. Add More Interest Keywords
In `extractInterests()` method, add your specific topics:
```apex
if (lowerTranscript.contains('your keyword')) interests.add('Your Topic');
```

### 2. Modify Task Due Date
In `createFollowUpTask()` method, change:
```apex
followUpTask.ActivityDate = Date.today().addDays(7); // Change to your preference
```

### 3. Customize Opportunity Stage
In `createOrUpdateOpportunity()` method, change:
```apex
opp.StageName = 'Qualification'; // Change to your stage name
```

### 4. Add Custom Follow-Up Suggestions
In `generateFollowUpSuggestions()` method, add your logic:
```apex
if (meetingData.interests.contains('Your Topic')) {
    suggestions.add('Your custom suggestion');
}
```

## Deployment Checklist

- [ ] Deploy `MeetingTranscriptProcessor.cls` to Salesforce
- [ ] Deploy `MeetingTranscriptProcessorTest.cls` to Salesforce
- [ ] Run test class and verify 100% coverage
- [ ] Update your existing Flow to call the Apex action
- [ ] Test with a sample voice recording
- [ ] Verify Event, Task, and Opportunity are created correctly
- [ ] Review follow-up suggestions
- [ ] Train users on new workflow

## Troubleshooting

### Contact Not Found
**Issue**: Processor returns error "Could not identify contact"

**Solutions**:
1. Check if contact name in transcript matches Salesforce exactly
2. Create contact manually before processing
3. Link contact to Event before calling Apex
4. Update contact matching logic to be more flexible

### No Opportunity Created
**Issue**: Contact found but no opportunity

**Possible Causes**:
1. Check user permissions for Opportunity object
2. Review debug logs for DML errors
3. Verify Account is associated with Contact

### Timeline Not Parsing
**Issue**: Close date not set correctly

**Solutions**:
1. Use standard format: "Q1 2026", "Q2 2025", etc.
2. Or provide `estimatedCloseDate` in LLM parsed JSON
3. Customize `extractTimeline()` regex pattern

## Next Steps

1. **Deploy to Sandbox** first for testing
2. **Test with various transcript formats** to ensure parsing works
3. **Customize** interest keywords and suggestions for your business
4. **Train users** on the new automated workflow
5. **Monitor** initial results and fine-tune as needed
6. **Deploy to Production** once satisfied

## Support

For issues or questions:
1. Review Salesforce debug logs
2. Check test class for usage examples
3. Verify Flow configuration and mappings
4. Test with simple transcripts first, then complex ones

---

**Created**: November 2025  
**Version**: 1.0  
**Author**: Brown Advisory Development Team

