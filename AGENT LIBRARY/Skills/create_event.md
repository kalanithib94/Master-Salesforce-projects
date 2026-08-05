# Skill: `create_event`

**Sources:** `Deliverables/force-app/main/default/classes/GenericAgenticSkillsHandler.cls`, `Deliverables/docs/GenericCRMAssistant_SystemPrompt.txt` (v1.3.1), `Deliverables/docs/GPTfy_Agent_Prompt_Commands.md`.

## Apex Code Snippet

```apex
when 'create_event'                 { return handleCreateEvent(parameters); }

    /**
     * @description Skill 33 — create_event. Accepts Event field API names as
     *              flat top-level parameters (e.g. Subject, StartDateTime,
     *              EndDateTime, DurationInMinutes, WhoId, WhatId, Description, …).
     *              Subject and StartDateTime are required; DurationInMinutes
     *              defaults to 30 when neither EndDateTime nor DurationInMinutes
     *              is supplied. The legacy nested { "fields": { … } } shape is
     *              still accepted for backward compatibility.
     * @jira V2-8418
     */
    private String handleCreateEvent(Map<String, Object> p) {
        if (!Schema.sObjectType.Event.isCreateable()) return errorHtml('Could not create event', 'Event is not creatable.');
        Map<String, Object> fields = buildFieldMap(p, null);
        for (String required : new List<String>{ 'Subject', 'StartDateTime' }) {
            if (!fields.containsKey(required) || String.isBlank(toText(fields.get(required)))) {
                return errorHtml('Could not create event', required + ' is required.');
            }
        }
        try {
            Event e = new Event();
            if (!fields.containsKey('EndDateTime') && !fields.containsKey('DurationInMinutes')) {
                fields.put('DurationInMinutes', 30);
            }
            applyFieldsToSObject(e, fields, false);
            insert e;
            String body = '<ul><li><b>Subject:</b> ' + escapeHtml(String.valueOf(fields.get('Subject'))) + '</li></ul>';
            return successHtml('Event Created', body, e.Id, 'View Event');
        } catch (Exception ex) {
            return errorHtml('Could not create event', ex.getMessage());
        }
    }
```

## System Prompt Excerpt

<!-- Lines 45-58 -->
STANDARD CRUD PATTERN (per object)
- fuzzy_search_<plural>     → JSON   find records by name (Opportunity also accepts an Id)
- fetch_<object>_details    → JSON   full record + key related data
- create_<object>           → HTML   new record           (CONFIRMATION REQUIRED — Rule 3)
- update_<object>_fields    → HTML   partial update       (CONFIRMATION REQUIRED — Rule 3)

Object support for the standard CRUD pattern:
- The standard CRUD pattern applies to FIVE objects only: Account, Contact, Lead, Opportunity, Case. Do not assume it works for any other object — use a UTILITY skill or ask the user.
- For all five objects, the search / details / create / update skills exist and follow the pattern exactly. Substitute the object name into the pattern (e.g. for Contact: fuzzy_search_contacts, fetch_contact_details, create_contact, update_contact_fields).
- Hard delete skills are not available. Direct permanent deletion requests to the Salesforce UI or an authorized administrator.

<!-- Lines 151-177 -->
Skills that REQUIRE confirmation before invocation:
- CREATE: create_account, create_contact, create_lead, create_opportunity, create_case, create_task, create_event
- UPDATE: update_account_fields, update_contact_fields, update_lead_fields, update_opportunity_fields, update_case_fields, bulk_update_records, add_opportunity_line_item
- CONVERT: convert_lead
- CLOSE / COMPLETE: close_case, complete_task
- ACTIVITY LOGGING: log_contact_activity, log_lead_activity, log_opportunity_activity

Skills that do NOT require confirmation (read-only / lookup):
- All fuzzy_search_*, fetch_*_details, fetch_account_related_lists, fetch_my_open_tasks, fetch_record_history, fetch_user_info, fetch_opportunity_recent_changes, fetch_picklist_values, run_internal_prompt.

Confirmation card format (UPDATE):

**[Record Name]**

[Field] - **[Current value]** → **[New value]**
[Field] - **[Current value]** → **[New value]**

Shall I proceed? (yes / no)

Confirmation card format (CREATE):

**Create new [Object]:**
- [Field] - **[Value]**
- [Field] - **[Value]**

Shall I create this record? (yes / no)

<!-- Lines 216-230 -->
RULE 4 — RESOLVE DATES BEFORE CALLING SKILLS
═══════════════════════════════════════════════════
Before passing any date to a skill, resolve every relative or natural-language expression to yyyy-MM-dd. Never pass "next monday", "sep 1", "end of quarter" etc. to a skill — always resolve first.

Year resolution: when the user says a month/day without a year (e.g. "sep 1", "March 15"), use the same year as the record's current relevant date (CloseDate for Opportunity, ActivityDate for Tasks). If that resolves to a past date, use the next year.

Examples:
- "sep 1" and CloseDate year is 2026 → 2026-09-01
- "feb 1" and today is April 2026 → 2027-02-01
- "next monday" → the coming Monday's date
- "end of this month" → last calendar day of current month
- "next quarter" → last day of next quarter
- "in 2 weeks" → today + 14 days

If ambiguous (e.g. "sometime next quarter"), ask the user for a specific date.

<!-- Lines 235-245 -->
Before calling any update_*_fields, create_* or bulk_update_records skill:

- Number fields: pass as plain numbers, no currency symbol or commas.
- Boolean fields: pass true / false (lowercase).
- Date fields: yyyy-MM-dd.
- Datetime fields: ISO 8601 (yyyy-MM-ddTHH:mm:ssZ).
- Picklist fields: pass the exact API value. If you are unsure, call fetch_picklist_values silently first.
- Dependent picklists: when the user asks to set a dependent picklist (e.g. SubType), call fetch_picklist_values with both `field_api_name` (the dependent field) AND `controller_value` (the parent value the record will have AFTER the update). Only present valid options.
- Multi-picklist: pass values joined with ";" or as a list — the skill normalises both.

If a picklist value the user gave does not match any returned option, do NOT pass it. Instead ask: "I couldn't find '[value]' as a valid [field] option. Did you mean: [option1, option2, option3]?"

<!-- Lines 251-257 -->
CREATE (create_account / create_contact / create_lead / create_opportunity / create_case / create_task / create_event):
1. Collect required fields from the user (or confirm sensible defaults).
2. Resolve any picklist values via fetch_picklist_values if uncertain.
3. Resolve any dates (Rule 4).
4. **MANDATORY CONFIRMATION** — show the CREATE confirmation card (Rule 3) and WAIT for explicit approval. Do NOT call the skill before the user confirms.
5. On explicit approval only, call the create skill with `fields` map.
6. Display the HTML response verbatim, then append the success-confirmation sentence (see "AFTER A SUCCESSFUL MUTATION" below).

<!-- Skill-specific: `create_event` follows the CREATE branch above (substitute object name). -->

## JSON Prompt Command

Event field API names are passed as **flat top-level keys** (NOT nested under a `fields` object). `Subject` and `StartDateTime` are required; common Event fields are declared explicitly to steer the LLM, and any other standard or custom field (including `__c` fields) can be passed via `additionalProperties: true` and will be picked up by the Apex.

```json
{
  "type": "object",
  "required": ["Subject", "StartDateTime"],
  "properties": {
    "Subject": {
      "type": "string",
      "description": "Required. Short subject of the Event."
    },
    "StartDateTime": {
      "type": "string",
      "description": "Required. Event start in ISO 8601 (e.g. '2026-05-31T14:30:00Z')."
    },
    "EndDateTime": {
      "type": "string",
      "description": "Optional. Event end in ISO 8601. Provide either EndDateTime or DurationInMinutes (DurationInMinutes defaults to 30 when both are omitted)."
    },
    "DurationInMinutes": {
      "type": "number",
      "description": "Optional. Event length in minutes. Provide either EndDateTime or DurationInMinutes (defaults to 30 when both are omitted)."
    },
    "Description": {
      "type": "string",
      "description": "Optional. Long-text description / agenda."
    },
    "Location": {
      "type": "string",
      "description": "Optional. Event location."
    },
    "WhatId": {
      "type": "string",
      "description": "Optional. Salesforce Id of the related Account / Opportunity / Case (NOT a Contact or Lead)."
    },
    "WhoId": {
      "type": "string",
      "description": "Optional. Salesforce Id of the related Contact or Lead."
    },
    "IsAllDayEvent": {
      "type": "boolean",
      "description": "Optional. true when the Event spans the entire day."
    }
  },
  "additionalProperties": true
}
```
