# Skill: `fetch_picklist_values`

**Sources:** `Deliverables/force-app/main/default/classes/GenericAgenticSkillsHandler.cls`, `Deliverables/docs/GenericCRMAssistant_SystemPrompt.txt` (v1.3.1), `Deliverables/docs/GPTfy_Agent_Prompt_Commands.md`.

## Apex Code Snippet

```apex
when 'fetch_picklist_values'        { return handleFetchPicklistValues(parameters); }

    private String handleFetchPicklistValues(Map<String, Object> p) {
        String objApi = toText(p.get('object_api_name'));
        String fld    = toText(p.get('field_api_name'));
        String ctrl   = toText(p.get('controller_value'));
        if (String.isBlank(objApi)) return errorJson('Missing required parameter: object_api_name');
        if (String.isBlank(fld))    return errorJson('Missing required parameter: field_api_name');
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(objApi);
        if (sot == null) return errorJson('Object not found: ' + objApi);
        Schema.SObjectField f = sot.getDescribe().fields.getMap().get(fld);
        if (f == null) return errorJson('Field not found: ' + fld);
        Schema.DescribeFieldResult d = f.getDescribe();
        if (d.getType() != Schema.DisplayType.Picklist && d.getType() != Schema.DisplayType.MultiPicklist) {
            return errorJson('Field is not a picklist: ' + fld);
        }
        List<Map<String, Object>> values = new List<Map<String, Object>>();
        if (String.isNotBlank(ctrl) && d.isDependentPicklist()) {
            Schema.SObjectField ctrlField = d.getController();
            Map<String, Integer> ctrlIndex = new Map<String, Integer>();
            Integer idx = 0;
            for (Schema.PicklistEntry e : ctrlField.getDescribe().getPicklistValues()) {
                ctrlIndex.put(e.getValue(), idx++);
            }
            Integer ci = ctrlIndex.get(ctrl);
            if (ci == null) return errorJson('Controller value "' + ctrl + '" not found on ' + ctrlField.getDescribe().getName());
            Integer byteIdx = ci / 8;
            Integer bitIdx  = 7 - (Math.mod(ci, 8));
            for (Schema.PicklistEntry e : d.getPicklistValues()) {
                String payload = JSON.serialize(e);
                Map<String, Object> meta = (Map<String, Object>) JSON.deserializeUntyped(payload);
                String validFor = (String) meta.get('validFor');
                if (String.isBlank(validFor)) continue;
                Blob decoded = EncodingUtil.base64Decode(validFor);
                String hex = EncodingUtil.convertToHex(decoded);
                if (byteIdx * 2 + 2 > hex.length()) continue;
                Integer byteVal = hexToInt(hex.substring(byteIdx * 2, byteIdx * 2 + 2));
                if ((byteVal & (1 << bitIdx)) != 0) {
                    values.add(new Map<String, Object>{ 'label' => e.getLabel(), 'value' => e.getValue(), 'active' => e.isActive() });
                }
            }
        } else {
            for (Schema.PicklistEntry e : d.getPicklistValues()) {
                values.add(new Map<String, Object>{ 'label' => e.getLabel(), 'value' => e.getValue(), 'active' => e.isActive(), 'default' => e.isDefaultValue() });
            }
        }
        return successJson(new Map<String, Object>{
            'object' => objApi, 'field' => fld,
            'isDependent' => d.isDependentPicklist(),
            'controllerValue' => ctrl, 'count' => values.size(), 'values' => values
        });
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
    "object_api_name": {
      "type": "string",
      "description": "API name of the object the field lives on. Examples: 'Account', 'Opportunity', 'Custom_Object__c'."
    },
    "field_api_name": {
      "type": "string",
      "description": "API name of the picklist or multi-picklist field. Examples: 'Industry', 'StageName', 'Type__c'."
    },
    "controller_value": {
      "type": "string",
      "description": "Required ONLY for dependent picklists. The exact API value of the controlling field that the record will have AFTER the update. The skill returns only the dependent values valid for this controller value."
    }
  },
  "required": [
    "object_api_name",
    "field_api_name"
  ]
}
```
