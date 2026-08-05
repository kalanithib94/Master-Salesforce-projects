# Skill: `fetch_case_details`

**Sources:** `Deliverables/force-app/main/default/classes/GenericAgenticSkillsHandler.cls`, `Deliverables/docs/GenericCRMAssistant_SystemPrompt.txt` (v1.3.1), `Deliverables/docs/GPTfy_Agent_Prompt_Commands.md`.

## Apex Code Snippet

```apex
when 'fetch_case_details'           { return handleFetchCaseDetails(parameters); }

    private String handleFetchCaseDetails(Map<String, Object> p) {
        String cid = toText(firstNonNull(p, new List<String>{ 'case_id', 'recordId', 'Id', 'case_number' }));
        if (String.isBlank(cid)) return errorJson('Missing required parameter: case_id');
        if (!Schema.sObjectType.Case.isAccessible()) return errorJson('Case is not accessible.');
        List<Case> rows = [
            SELECT Id, CaseNumber, Subject, Description, Status, Priority, Type, Origin,
                   Reason, AccountId, Account.Name, ContactId, Contact.Name, OwnerId, IsClosed
            FROM Case WHERE Id = :cid OR CaseNumber = :cid WITH USER_MODE LIMIT 1
        ];
        if (rows.isEmpty()) return errorJson('No case found for provided Id/Number.');
        Case ca = rows[0];
        return successJson(new Map<String, Object>{
            'Id' => ca.Id, 'CaseNumber' => ca.CaseNumber, 'Subject' => ca.Subject,
            'Description' => ca.Description, 'Status' => ca.Status, 'Priority' => ca.Priority,
            'Type' => ca.Type, 'Origin' => ca.Origin, 'Reason' => ca.Reason,
            'Account' => ca.Account != null ? ca.Account.Name : null,
            'Contact' => ca.Contact != null ? ca.Contact.Name : null,
            'IsClosed' => ca.IsClosed, 'recordUrl' => recordUrl(ca.Id)
        });
    }
```

## System Prompt Excerpt

<!-- Lines 45-47 -->
STANDARD CRUD PATTERN (per object)
- fuzzy_search_<plural>     → JSON   find records by name (Opportunity also accepts an Id)
- fetch_<object>_details    → JSON   full record + key related data

<!-- Lines 52-58 -->
Object support for the standard CRUD pattern:
- The standard CRUD pattern applies to FIVE objects only: Account, Contact, Lead, Opportunity, Case. Do not assume it works for any other object — use a UTILITY skill or ask the user.
- For all five objects, the search / details / create / update skills exist and follow the pattern exactly. Substitute the object name into the pattern (e.g. for Contact: fuzzy_search_contacts, fetch_contact_details, create_contact, update_contact_fields).
- Hard delete skills are not available. Direct permanent deletion requests to the Salesforce UI or an authorized administrator.

<!-- Lines 100-117 -->
CRITICAL — Using the record Id from page context:

When the user is on a record page, the runtime supplies you with the record Id and object type as part of your context. Id prefixes identify the object (Account: 001…, Contact: 003…, Lead: 00Q…, Opportunity: 006…, Case: 500…). This page-context Id IS the confirmed record. Use it directly — do NOT call fuzzy_search_* first.

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

If a fetch_*_details schema accepts BOTH a `_id` and a `_name` parameter (e.g. fetch_account_details), ALWAYS prefer the `_id` form when you have a page-context Id. Use `_name` only when the user named the record in their message and you have no Id.

<!-- Lines 159-160 -->
Skills that do NOT require confirmation (read-only / lookup):
- All fuzzy_search_*, fetch_*_details, fetch_account_related_lists, fetch_my_open_tasks, fetch_record_history, fetch_user_info, fetch_opportunity_recent_changes, fetch_picklist_values, run_internal_prompt.

<!-- Lines 259-263 -->
READ / FETCH (fetch_*_details, fetch_account_related_lists, fetch_my_open_tasks, fetch_record_history, fetch_user_info, fetch_opportunity_recent_changes):
1. Identify the record (Rule 2) if needed.
2. Call the skill silently. Display the result in friendly prose / a clean list.
3. Do NOT output raw JSON. Format key fields as a markdown list.
4. No confirmation needed — these are read-only.

## JSON Prompt Command

```json
{
  "type": "object",
  "properties": {
    "case_id": {
      "type": "string",
      "description": "Either the Salesforce Id of the Case (starts with '500') OR the human-readable CaseNumber (e.g. '00001234')."
    }
  },
  "required": [
    "case_id"
  ]
}
```
