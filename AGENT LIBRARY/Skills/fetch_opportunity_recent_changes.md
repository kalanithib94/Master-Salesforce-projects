# Skill: `fetch_opportunity_recent_changes`

**Sources:** `Deliverables/force-app/main/default/classes/GenericAgenticSkillsHandler.cls`, `Deliverables/docs/GenericCRMAssistant_SystemPrompt.txt` (v1.3.1), `Deliverables/docs/GPTfy_Agent_Prompt_Commands.md`.

## Apex Code Snippet

```apex
when 'fetch_opportunity_recent_changes' { return handleFetchOpportunityRecentChanges(parameters); }

    private String handleFetchOpportunityRecentChanges(Map<String, Object> p) {
        String oid = toText(firstNonNull(p, new List<String>{ 'opportunity_id', 'recordId', 'Id' }));
        if (String.isBlank(oid)) return errorJson('Missing required parameter: opportunity_id');
        if (!Schema.sObjectType.Opportunity.isAccessible()) return errorJson('Opportunity is not accessible.');
        List<Opportunity> opps = [SELECT Id, Name, CloseDate, StageName, LastModifiedDate FROM Opportunity WHERE Id = :oid WITH USER_MODE LIMIT 1];
        if (opps.isEmpty()) return errorJson('No opportunity found for provided Id.');
        Integer days = 30;
        Object dRaw = p.get('days');
        if (dRaw != null && String.isNotBlank(toText(dRaw))) {
            try { days = Integer.valueOf(toText(dRaw)); } catch (Exception e) { days = 30; }
        }
        days = Math.max(1, Math.min(days, 365));
        if (!Schema.sObjectType.OpportunityFieldHistory.isAccessible()) {
            return successJson(new Map<String, Object>{ 'status' => 'unavailable', 'message' => 'OpportunityFieldHistory not enabled.' });
        }
        Datetime cutoff = System.now().addDays(-days);
        List<OpportunityFieldHistory> hist = [
            SELECT Field, OldValue, NewValue, CreatedDate, CreatedBy.Name
            FROM OpportunityFieldHistory
            WHERE OpportunityId = :oid AND CreatedDate >= :cutoff
            ORDER BY CreatedDate DESC LIMIT 500
        ];
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        Map<String, Integer> byField = new Map<String, Integer>();
        for (OpportunityFieldHistory h : hist) {
            String f = String.valueOf(h.Field);
            byField.put(f, (byField.containsKey(f) ? byField.get(f) : 0) + 1);
            rows.add(new Map<String, Object>{
                'field' => h.Field,
                'oldValue' => h.OldValue != null ? String.valueOf(h.OldValue) : null,
                'newValue' => h.NewValue != null ? String.valueOf(h.NewValue) : null,
                'changedAt' => String.valueOf(h.CreatedDate),
                'changedBy' => h.CreatedBy != null ? h.CreatedBy.Name : null
            });
        }
        return successJson(new Map<String, Object>{
            'opportunityId' => opps[0].Id, 'opportunityName' => opps[0].Name,
            'currentCloseDate' => String.valueOf(opps[0].CloseDate),
            'currentStageName' => opps[0].StageName,
            'lookbackDays' => days, 'changeCount' => hist.size(),
            'byField' => byField, 'history' => rows
        });
    }
```

## System Prompt Excerpt

<!-- Lines 67-68 -->
- add_opportunity_line_item         → HTML   add a Product to an Opportunity             (CONFIRMATION REQUIRED)
- fetch_opportunity_recent_changes  → JSON   field history for an Opportunity

<!-- Lines 108-108 -->
- Opportunity → fetch_opportunity_details / update_opportunity_fields / log_opportunity_activity / add_opportunity_line_item / fetch_opportunity_recent_changes → `opportunity_id`. (For fuzzy_search_opportunities you may also pass the Id as `search_term`.)

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
      "description": "ONLY the Salesforce Id of the Opportunity whose recent changes should be fetched."
    },
    "days": {
      "type": "integer",
      "description": "Optional. Lookback window in days (1-365). Defaults to 30."
    }
  },
  "required": [
    "opportunity_id"
  ]
}
```
