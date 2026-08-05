# Skill: `fetch_record_history`

**Sources:** `Deliverables/force-app/main/default/classes/GenericAgenticSkillsHandler.cls`, `Deliverables/docs/GenericCRMAssistant_SystemPrompt.txt` (v1.3.1), `Deliverables/docs/GPTfy_Agent_Prompt_Commands.md`.

## Apex Code Snippet

```apex
when 'fetch_record_history'         { return handleFetchRecordHistory(parameters); }

    private String handleFetchRecordHistory(Map<String, Object> p) {
        String rid    = toText(firstNonNull(p, new List<String>{ 'record_id', 'recordId', 'Id' }));
        String objApi = toText(p.get('object_api_name'));
        if (String.isBlank(rid))    return errorJson('Missing required parameter: record_id');
        if (String.isBlank(objApi)) return errorJson('Missing required parameter: object_api_name');
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(objApi);
        if (sot == null || !sot.getDescribe().isAccessible()) return errorJson('Object not accessible: ' + objApi);
        Integer days = 30;
        Object dRaw = p.get('days');
        if (dRaw != null && String.isNotBlank(toText(dRaw))) {
            try { days = Integer.valueOf(toText(dRaw)); } catch (Exception e) { days = 30; }
        }
        days = Math.max(1, Math.min(days, 365));
        // Field history object is typically <Object>History or <CustomObject>__History
        String histObj = objApi.endsWith('__c') ? objApi.replace('__c', '__History') : objApi + 'History';
        Schema.SObjectType histSot = Schema.getGlobalDescribe().get(histObj);
        if (histSot == null || !histSot.getDescribe().isAccessible()) {
            return successJson(new Map<String, Object>{ 'status' => 'unavailable', 'message' => 'Field history not enabled for ' + objApi + '.' });
        }
        Datetime cutoff = System.now().addDays(-days);
        // Parent id field name varies — for standard objects it's <Object>Id (e.g. AccountId), for custom it's ParentId
        String parentField = objApi.endsWith('__c') ? 'ParentId' : (objApi + 'Id');
        try {
            String soql = 'SELECT Field, OldValue, NewValue, CreatedDate, CreatedBy.Name FROM ' + histObj
                        + ' WHERE ' + parentField + ' = :rid AND CreatedDate >= :cutoff'
                        + ' WITH USER_MODE ORDER BY CreatedDate DESC LIMIT 500';
            List<SObject> hist = Database.query(soql);
            List<Map<String, Object>> rows = new List<Map<String, Object>>();
            for (SObject h : hist) {
                rows.add(new Map<String, Object>{
                    'field'     => h.get('Field'),
                    'oldValue'  => h.get('OldValue') != null ? String.valueOf(h.get('OldValue')) : null,
                    'newValue'  => h.get('NewValue') != null ? String.valueOf(h.get('NewValue')) : null,
                    'changedAt' => String.valueOf(h.get('CreatedDate'))
                });
            }
            return successJson(new Map<String, Object>{ 'recordId' => rid, 'object' => objApi, 'lookbackDays' => days, 'changeCount' => rows.size(), 'history' => rows });
        } catch (Exception ex) {
            return errorJson('Could not read history: ' + ex.getMessage());
        }
    }
```

## System Prompt Excerpt

<!-- Lines 75-80 -->
UTILITY SKILLS (object-agnostic)
- bulk_update_records               → HTML   update many records of one object (CONFIRMATION REQUIRED — Rule 8)
- fetch_record_history              → JSON   field-history audit for any record
- fetch_user_info                   → JSON   running user or named user info
- fetch_picklist_values             → JSON   discover valid picklist options for any object/field
- run_internal_prompt               → JSON   run a configured GPTfy prompt against a record (Rule 7)

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
    "record_id": {
      "type": "string",
      "description": "ONLY the Salesforce Id of the record whose change history should be fetched."
    },
    "object_api_name": {
      "type": "string",
      "description": "API name of the record's object. Examples: 'Account', 'Opportunity', 'Custom_Object__c'."
    },
    "days": {
      "type": "integer",
      "description": "Optional. Lookback window in days (1-365). Defaults to 30."
    }
  },
  "required": [
    "record_id",
    "object_api_name"
  ]
}
```
