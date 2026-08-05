# Skill: `update_contact_fields`

**Sources:** `Deliverables/force-app/main/default/classes/GenericAgenticSkillsHandler.cls`, `Deliverables/docs/GenericCRMAssistant_SystemPrompt.txt` (v1.3.1), `Deliverables/docs/GPTfy_Agent_Prompt_Commands.md`.

## Apex Code Snippet

```apex
when 'update_contact_fields'        { return handleUpdateContactFields(parameters); }

    /**
     * @description Skill 10 — update_contact_fields. Field updates are passed as
     *              flat top-level keys (e.g. { contact_id, Title, Phone }). The
     *              legacy nested { "fields": { … } } shape is still accepted for
     *              backward compatibility.
     * @jira V2-8418
     */
    private String handleUpdateContactFields(Map<String, Object> p) {
        String cid = toText(firstNonNull(p, new List<String>{ 'contact_id', 'recordId', 'Id' }));
        if (String.isBlank(cid)) return errorHtml('Could not update contact', 'Missing parameter: contact_id');
        Map<String, Object> fields = buildFieldMap(p, new Set<String>{ 'contact_id', 'recordId', 'Id' });
        if (fields.isEmpty()) return errorHtml('Could not update contact', 'Missing parameter: at least one field to update');
        if (!Schema.sObjectType.Contact.isUpdateable()) return errorHtml('Could not update contact', 'Contact is not updateable.');
        List<Contact> rows = [SELECT Id, Name FROM Contact WHERE Id = :cid WITH USER_MODE LIMIT 1];
        if (rows.isEmpty()) return errorHtml('Could not update contact', 'No contact found for provided Id.');
        return performGenericUpdate('Contact', cid, fields, 'Contact Updated', 'View Contact', rows[0].Name);
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

<!-- Lines 92-98 -->
Before any update, deletion, activity, or detail fetch, you need a confirmed record Id.

Priority order:
1. Record page context — if the user is on a record page, you already have the record Id and object type from the page context. This IS the confirmed record. Never ask "Which record?"
2. Already confirmed in conversation — reuse that Id.
3. Name hint in the message — call the matching fuzzy_search_* skill silently and pick the best match.
4. No context — ask: "Which [object] should I update? Please provide the name."

<!-- Lines 151-169 -->
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

<!-- Lines 265-271 -->
UPDATE (update_*_fields / bulk_update_records / add_opportunity_line_item):
1. Identify the record(s) (Rule 2).
2. Silently fetch current values to enable the diff (use fetch_*_details or fuzzy_search_*).
3. Resolve picklist values (Rule 5) and dates (Rule 4).
4. **MANDATORY CONFIRMATION** — show the UPDATE confirmation card (Rule 3) with current → new values, and WAIT for explicit approval. Do NOT call the skill before the user confirms.
5. On explicit approval only, call the update skill with `fields` map.
6. Display the HTML diff card verbatim, then append the success-confirmation sentence (see "AFTER A SUCCESSFUL MUTATION" below).

<!-- Skill-specific: `update_contact_fields` — use the matching *_id per Rule 2. -->

## JSON Prompt Command

Field updates are passed as **flat top-level keys** (NOT nested under a `fields` object). Common Contact fields are declared explicitly to steer the LLM, and any other standard or custom field (including `__c` fields) can be passed via `additionalProperties: true` and will be picked up by the Apex.

```json
{
  "type": "object",
  "required": ["contact_id"],
  "properties": {
    "contact_id": {
      "type": "string",
      "description": "ONLY the Salesforce Id of the Contact to update."
    },
    "FirstName": {
      "type": "string",
      "description": "Optional. New first name."
    },
    "LastName": {
      "type": "string",
      "description": "Optional. New last name."
    },
    "Email": {
      "type": "string",
      "description": "Optional. New email address."
    },
    "Phone": {
      "type": "string",
      "description": "Optional. New work phone."
    },
    "MobilePhone": {
      "type": "string",
      "description": "Optional. New mobile phone."
    },
    "Title": {
      "type": "string",
      "description": "Optional. New job title."
    },
    "Department": {
      "type": "string",
      "description": "Optional. New department."
    },
    "AccountId": {
      "type": "string",
      "description": "Optional. New Salesforce Account Id."
    }
  },
  "additionalProperties": true
}
```
