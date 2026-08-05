# Skill: `fetch_account_related_lists`

**Sources:** `Deliverables/force-app/main/default/classes/GenericAgenticSkillsHandler.cls`, `Deliverables/docs/GenericCRMAssistant_SystemPrompt.txt` (v1.3.1), `Deliverables/docs/GPTfy_Agent_Prompt_Commands.md`.

## Apex Code Snippet

```apex
when 'fetch_account_related_lists'  { return handleFetchAccountRelatedLists(parameters); }

    private String handleFetchAccountRelatedLists(Map<String, Object> p) {
        String accId = toText(firstNonNull(p, new List<String>{ 'account_id', 'recordId', 'Id' }));
        if (String.isBlank(accId)) return errorJson('Missing required parameter: account_id');
        if (!Schema.sObjectType.Account.isAccessible()) return errorJson('Account is not accessible.');
        List<Account> accs = [SELECT Id, Name FROM Account WHERE Id = :accId WITH USER_MODE LIMIT 1];
        if (accs.isEmpty()) return errorJson('No account found for provided Id.');
        Set<String> wanted = new Set<String>();
        Object related = p.get('related');
        if (related instanceof List<Object>) {
            for (Object o : (List<Object>) related) wanted.add(String.valueOf(o).toLowerCase());
        }
        if (wanted.isEmpty()) wanted.addAll(new List<String>{ 'contacts', 'opportunities', 'cases' });
        Map<String, Object> result = new Map<String, Object>{ 'accountId' => accs[0].Id, 'accountName' => accs[0].Name };
        if (wanted.contains('contacts') && Schema.sObjectType.Contact.isAccessible()) {
            result.put('contacts', [SELECT Id, Name, Email, Phone, Title FROM Contact WHERE AccountId = :accId WITH USER_MODE LIMIT 50]);
        }
        if (wanted.contains('opportunities') && Schema.sObjectType.Opportunity.isAccessible()) {
            result.put('opportunities', [SELECT Id, Name, StageName, Amount, CloseDate FROM Opportunity WHERE AccountId = :accId WITH USER_MODE ORDER BY CloseDate DESC LIMIT 50]);
        }
        if (wanted.contains('cases') && Schema.sObjectType.Case.isAccessible()) {
            result.put('cases', [SELECT Id, CaseNumber, Subject, Status, Priority FROM Case WHERE AccountId = :accId WITH USER_MODE ORDER BY CreatedDate DESC LIMIT 50]);
        }
        return successJson(result);
    }
```

## System Prompt Excerpt

<!-- Lines 63-64 -->
OBJECT-SPECIFIC SKILLS (do not follow the CRUD pattern)
- fetch_account_related_lists       → JSON   child records (Contacts, Opportunities, Cases…)

<!-- Lines 104-105 -->
Per-object parameter names to pass the page-context Id under:
- Account     → fetch_account_details / update_account_fields / fetch_account_related_lists / log_*_activity → `account_id`

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
    "account_id": {
      "type": "string",
      "description": "ONLY the Salesforce Id of the Account whose related lists should be fetched."
    },
    "related": {
      "type": "array",
      "description": "Optional. Which related lists to fetch. Allowed values: 'contacts', 'opportunities', 'cases'. If omitted, all three are returned.",
      "items": {
        "type": "string",
        "enum": [
          "contacts",
          "opportunities",
          "cases"
        ]
      }
    }
  },
  "required": [
    "account_id"
  ]
}
```
