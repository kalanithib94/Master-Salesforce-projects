# Skill: `bulk_update_records`

**Sources:** `Deliverables/force-app/main/default/classes/GenericAgenticSkillsHandler.cls`, `Deliverables/docs/GenericCRMAssistant_SystemPrompt.txt` (v1.3.1), `Deliverables/docs/GPTfy_Agent_Prompt_Commands.md`.

## Apex Code Snippet

```apex
when 'bulk_update_records'          { return handleBulkUpdateRecords(parameters); }

    private String handleBulkUpdateRecords(Map<String, Object> p) {
        String objApi = toText(p.get('object_api_name'));
        Object recsRaw = p.get('records');
        if (String.isBlank(objApi)) return errorHtml('Could not bulk update', 'Missing parameter: object_api_name');
        if (!(recsRaw instanceof List<Object>)) return errorHtml('Could not bulk update', 'Missing parameter: records (List)');
        List<Object> recs = (List<Object>) recsRaw;
        if (recs.isEmpty()) return errorHtml('Could not bulk update', 'records list is empty.');
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(objApi);
        if (sot == null || !sot.getDescribe().isUpdateable()) return errorHtml('Could not bulk update', 'Object not updateable: ' + objApi);
        List<SObject> toUpdate = new List<SObject>();
        Integer skipped = 0;
        try {
            for (Object o : recs) {
                if (!(o instanceof Map<String, Object>)) { skipped++; continue; }
                Map<String, Object> row = (Map<String, Object>) o;
                String idStr = toText(row.get('Id'));
                if (String.isBlank(idStr)) { skipped++; continue; }
                SObject s = sot.newSObject((Id) idStr);
                Map<String, Object> apply = new Map<String, Object>(row);
                apply.remove('Id');
                applyFieldsToSObject(s, apply, true);
                toUpdate.add(s);
            }
            if (toUpdate.isEmpty()) return errorHtml('Could not bulk update', 'No valid rows in payload.');
            Database.SaveResult[] srs = Database.update(toUpdate, false);
            Integer ok = 0, fail = 0;
            List<String> errors = new List<String>();
            for (Database.SaveResult sr : srs) {
                if (sr.isSuccess()) ok++;
                else { fail++; errors.add(sr.getErrors()[0].getMessage()); }
            }
            String body = '<ul><li><b>Object:</b> ' + escapeHtml(objApi) + '</li>'
                        + '<li><b>Succeeded:</b> ' + ok + '</li>'
                        + '<li><b>Failed:</b> ' + fail + '</li>'
                        + '<li><b>Skipped:</b> ' + skipped + '</li></ul>';
            if (!errors.isEmpty()) {
                body += '<b>First errors:</b><ul>';
                for (Integer i = 0; i < Math.min(3, errors.size()); i++) body += '<li>' + escapeHtml(errors[i]) + '</li>';
                body += '</ul>';
            }
            return successHtml('Bulk Update Complete', body, null, null);
        } catch (Exception ex) {
            return errorHtml('Could not bulk update', ex.getMessage());
        }
    }
```

## System Prompt Excerpt

<!-- Lines 76-76 -->
- bulk_update_records               → HTML   update many records of one object (CONFIRMATION REQUIRED — Rule 8)

<!-- Lines 151-153 -->
Skills that REQUIRE confirmation before invocation:
- CREATE: create_account, create_contact, create_lead, create_opportunity, create_case, create_task, create_event
- UPDATE: update_account_fields, update_contact_fields, update_lead_fields, update_opportunity_fields, update_case_fields, bulk_update_records, add_opportunity_line_item

<!-- Lines 235-235 -->
Before calling any update_*_fields, create_* or bulk_update_records skill:

<!-- Lines 265-271 -->
UPDATE (update_*_fields / bulk_update_records / add_opportunity_line_item):
1. Identify the record(s) (Rule 2).
2. Silently fetch current values to enable the diff (use fetch_*_details or fuzzy_search_*).
3. Resolve picklist values (Rule 5) and dates (Rule 4).
4. **MANDATORY CONFIRMATION** — show the UPDATE confirmation card (Rule 3) with current → new values, and WAIT for explicit approval. Do NOT call the skill before the user confirms.
5. On explicit approval only, call the update skill with `fields` map.
6. Display the HTML diff card verbatim, then append the success-confirmation sentence (see "AFTER A SUCCESSFUL MUTATION" below).

<!-- Lines 339-360 -->
RULE 8 — BULK OPERATIONS (bulk_update_records)
═══════════════════════════════════════════════════
Use bulk_update_records ONLY when the user asks to update multiple records at once on the same object. The skill accepts:
{
  "object_api_name": "Opportunity",
  "records": [
    { "Id": "006...", "StageName": "Closed Won", "Amount": 50000 },
    { "Id": "006...", "StageName": "Closed Lost" }
  ]
}

Rules:
- Each row's "Id" is REQUIRED.
- Each row may include any updateable fields of any supported type.
- **MANDATORY CONFIRMATION** — show a confirmation card listing the total record count, the object, and a per-row sample of changes (current → new where available). Example:
    "About to update **5 Opportunities**:
    - **Acme Big Deal**: StageName **Negotiation/Review** → **Closed Won**
    - **Q3 Renewal**: Amount **50,000** → **75,000**
    … and 3 more.
    Shall I proceed? (yes / no)"
  WAIT for explicit approval. Do NOT call the skill before the user confirms.
- The skill continues on per-row errors and returns success/fail counts. Display the HTML summary verbatim, then append the success-confirmation sentence per Rule 6 (use the partial-success pattern when applicable).

## JSON Prompt Command

```json
{
  "type": "object",
  "properties": {
    "object_api_name": {
      "type": "string",
      "description": "API name of the Salesforce object the records belong to. Examples: 'Account', 'Opportunity', 'Custom_Object__c'. ALL records in 'records' must belong to this object."
    },
    "records": {
      "type": "array",
      "description": "List of record-update objects. Each MUST contain 'Id' plus any updateable fields with their new values.",
      "items": {
        "type": "object",
        "properties": {
          "Id": {
            "type": "string",
            "description": "Salesforce record Id of the row to update."
          }
        },
        "required": [
          "Id"
        ],
        "additionalProperties": true
      }
    }
  },
  "required": [
    "object_api_name",
    "records"
  ]
}
```
