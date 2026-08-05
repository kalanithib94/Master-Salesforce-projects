# Skill: `fetch_opportunity_details`

**Sources:** `Deliverables/force-app/main/default/classes/GenericAgenticSkillsHandler.cls`, `Deliverables/docs/GenericCRMAssistant_SystemPrompt.txt` (v1.3.1), `Deliverables/docs/GPTfy_Agent_Prompt_Commands.md`.

## Apex Code Snippet

```apex
when 'fetch_opportunity_details'    { return handleFetchOpportunityDetails(parameters); }

    private String handleFetchOpportunityDetails(Map<String, Object> p) {
        String oid = toText(firstNonNull(p, new List<String>{ 'opportunity_id', 'recordId', 'Id' }));
        if (String.isBlank(oid)) return errorJson('Missing required parameter: opportunity_id');
        if (!Schema.sObjectType.Opportunity.isAccessible()) return errorJson('Opportunity is not accessible.');
        List<Opportunity> rows = [
            SELECT Id, Name, StageName, Amount, CloseDate, Probability, ForecastCategoryName,
                   AccountId, Account.Name, OwnerId, Owner.Name, Description, Type, LeadSource
            FROM Opportunity WHERE Id = :oid WITH USER_MODE LIMIT 1
        ];
        if (rows.isEmpty()) return errorJson('No opportunity found for provided Id.');
        Opportunity o = rows[0];
        return successJson(new Map<String, Object>{
            'Id' => o.Id, 'Name' => o.Name, 'StageName' => o.StageName,
            'Amount' => o.Amount, 'CloseDate' => String.valueOf(o.CloseDate),
            'Probability' => o.Probability, 'ForecastCategory' => o.ForecastCategoryName,
            'Account' => o.Account != null ? o.Account.Name : null,
            'Owner' => o.Owner != null ? o.Owner.Name : null,
            'Description' => o.Description, 'Type' => o.Type, 'LeadSource' => o.LeadSource,
            'currentdate__c' => String.valueOf(Date.today()),
            'recordUrl' => recordUrl(o.Id)
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
    "opportunity_id": {
      "type": "string",
      "description": "ONLY the Salesforce Id of the Opportunity whose details should be fetched."
    }
  },
  "required": [
    "opportunity_id"
  ]
}
```
