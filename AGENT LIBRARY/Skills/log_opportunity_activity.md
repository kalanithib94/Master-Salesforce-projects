# Skill: `log_opportunity_activity`

**Sources:** `Deliverables/force-app/main/default/classes/GenericAgenticSkillsHandler.cls`, `Deliverables/docs/GenericCRMAssistant_SystemPrompt.txt` (v1.3.1), `Deliverables/docs/GPTfy_Agent_Prompt_Commands.md`.

## Apex Code Snippet

```apex
when 'log_opportunity_activity'     { return handleLogOpportunityActivity(parameters); }

    private String handleLogOpportunityActivity(Map<String, Object> p) {
        String oid = toText(firstNonNull(p, new List<String>{ 'opportunity_id', 'recordId', 'Id', 'WhatId' }));
        String subject = toText(p.get('activity_subject'));
        String descr   = toText(p.get('activity_description'));
        if (String.isBlank(oid))     return errorHtml('Could not log activity', 'Missing the opportunity Id.');
        if (String.isBlank(subject)) return errorHtml('Could not log activity', 'Missing the activity subject.');
        if (!Schema.sObjectType.Task.isCreateable()) return errorHtml('Could not log activity', 'Task is not creatable.');
        try {
            Task t = new Task(WhatId = oid, Subject = subject, Description = descr, Status = 'Completed', Priority = 'Normal', ActivityDate = Date.today());
            insert t;
            return successHtml('Activity Logged: ' + subject, '<ul><li><b>Status:</b> Completed</li><li><b>Date:</b> ' + escapeHtml(String.valueOf(Date.today())) + '</li></ul>', t.Id, 'View Task');
        } catch (Exception ex) {
            return errorHtml('Could not log activity', ex.getMessage());
        }
    }
```

## System Prompt Excerpt

<!-- Lines 60-61 -->
ACTIVITY-LOGGING PATTERN (Tasks tied to a parent record)
- log_<object>_activity     → HTML   available for: Contact, Lead, Opportunity. Subject MUST be confirmed (Rule 6).

<!-- Lines 104-114 -->
Per-object parameter names to pass the page-context Id under:
- Account     → fetch_account_details / update_account_fields / fetch_account_related_lists / log_*_activity → `account_id`
- Contact     → fetch_contact_details / update_contact_fields / log_contact_activity → `contact_id`
- Lead        → fetch_lead_details / update_lead_fields / convert_lead / log_lead_activity → `lead_id`
- Opportunity → fetch_opportunity_details / update_opportunity_fields / log_opportunity_activity / add_opportunity_line_item / fetch_opportunity_recent_changes → `opportunity_id`. (For fuzzy_search_opportunities you may also pass the Id as `search_term`.)
- Case        → fetch_case_details / update_case_fields / close_case → `case_id`

Page-context fast paths (apply BEFORE the priority order above):
- "Provide the [object] details" / "Show me this record" / "Summarise this account" → call fetch_<object>_details immediately with <object>_id = <page record Id>. Do NOT ask the user to name the record. Do NOT call fuzzy_search_*.
- "Update this [field]" / "Change [field] to X" → use <object>_id = <page record Id> when calling update_<object>_fields. Skip the name resolution step. Rule 3 confirmation still applies.
- "Log a call / activity" → use <object>_id = <page record Id> on the log_*_activity skill. Rule 6 ACTIVITY flow still applies.

<!-- Lines 151-157 -->
Skills that REQUIRE confirmation before invocation:
- CREATE: create_account, create_contact, create_lead, create_opportunity, create_case, create_task, create_event
- UPDATE: update_account_fields, update_contact_fields, update_lead_fields, update_opportunity_fields, update_case_fields, bulk_update_records, add_opportunity_line_item
- Hard delete is not supported; direct permanent deletion requests to the Salesforce UI or an authorized administrator.
- CONVERT: convert_lead
- CLOSE / COMPLETE: close_case, complete_task
- ACTIVITY LOGGING: log_contact_activity, log_lead_activity, log_opportunity_activity

<!-- Lines 298-302 -->
ACTIVITY LOGGING (log_contact_activity / log_lead_activity / log_opportunity_activity):
1. Identify the parent record (Rule 2).
2. If activity subject was not provided, ask: "What should the activity subject be?"
3. **MANDATORY CONFIRMATION** — show the ACTIVITY confirmation card (Rule 3) with subject and description preview, and WAIT for explicit approval.
4. On explicit approval only, call the log_*_activity skill. Display the HTML response verbatim, then append the success-confirmation sentence.

## JSON Prompt Command

```json
{
  "type": "object",
  "properties": {
    "opportunity_id": {
      "type": "string",
      "description": "ONLY the Salesforce Id of the Opportunity the activity should be logged against."
    },
    "activity_subject": {
      "type": "string",
      "description": "A short, meaningful subject for the activity. MUST NOT be a placeholder."
    },
    "activity_description": {
      "type": "string",
      "description": "Optional longer-form notes captured against the activity."
    }
  },
  "required": [
    "opportunity_id",
    "activity_subject"
  ]
}
```
