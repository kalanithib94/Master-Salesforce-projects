# Skill: `convert_lead`

**Sources:** `Deliverables/force-app/main/default/classes/GenericAgenticSkillsHandler.cls`, `Deliverables/docs/GenericCRMAssistant_SystemPrompt.txt` (v1.3.1), `Deliverables/docs/GPTfy_Agent_Prompt_Commands.md`.

## Apex Code Snippet

```apex
when 'convert_lead'                 { return handleConvertLead(parameters); }

    private String handleConvertLead(Map<String, Object> p) {
        String lid = toText(firstNonNull(p, new List<String>{ 'lead_id', 'recordId', 'Id' }));
        if (String.isBlank(lid)) return errorHtml('Could not convert lead', 'Missing parameter: lead_id');
        if (!Schema.sObjectType.Lead.isUpdateable()) return errorHtml('Could not convert lead', 'Lead is not updateable.');
        List<Lead> rows = [SELECT Id, Name, IsConverted FROM Lead WHERE Id = :lid WITH USER_MODE LIMIT 1];
        if (rows.isEmpty()) return errorHtml('Could not convert lead', 'No lead found for provided Id.');
        if (rows[0].IsConverted) return errorHtml('Could not convert lead', 'Lead is already converted.');
        try {
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(lid);
            String accountId = toText(p.get('account_id'));
            if (String.isNotBlank(accountId)) lc.setAccountId(accountId);
            Boolean noOpp = (Boolean) (p.get('do_not_create_opportunity') == null ? false : Boolean.valueOf(String.valueOf(p.get('do_not_create_opportunity'))));
            lc.setDoNotCreateOpportunity(noOpp);
            String oppName = toText(p.get('opportunity_name'));
            if (!noOpp && String.isNotBlank(oppName)) lc.setOpportunityName(oppName);
            List<LeadStatus> converted = [SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
            if (!converted.isEmpty()) lc.setConvertedStatus(converted[0].MasterLabel);
            Database.LeadConvertResult lcr = Database.convertLead(lc);
            if (!lcr.isSuccess()) return errorHtml('Could not convert lead', lcr.getErrors()[0].getMessage());
            String body = '<ul>'
                        + '<li><b>Account Id:</b> ' + escapeHtml(String.valueOf(lcr.getAccountId())) + '</li>'
                        + '<li><b>Contact Id:</b> ' + escapeHtml(String.valueOf(lcr.getContactId())) + '</li>'
                        + (lcr.getOpportunityId() != null ? '<li><b>Opportunity Id:</b> ' + escapeHtml(String.valueOf(lcr.getOpportunityId())) + '</li>' : '')
                        + '</ul>';
            return successHtml('Lead Converted', body, lid, 'View Lead');
        } catch (Exception ex) {
            return errorHtml('Could not convert lead', ex.getMessage());
        }
    }
```

## System Prompt Excerpt

<!-- Lines 65-65 -->
- convert_lead                      → HTML   converts to Account / Contact / Opportunity (CONFIRMATION REQUIRED)

<!-- Lines 107-107 -->
- Lead        → fetch_lead_details / update_lead_fields / convert_lead / log_lead_activity → `lead_id`

<!-- Lines 151-157 -->
Skills that REQUIRE confirmation before invocation:
- CREATE: create_account, create_contact, create_lead, create_opportunity, create_case, create_task, create_event
- UPDATE: update_account_fields, update_contact_fields, update_lead_fields, update_opportunity_fields, update_case_fields, bulk_update_records, add_opportunity_line_item
- Hard delete is not supported; direct permanent deletion requests to the Salesforce UI or an authorized administrator.
- CONVERT: convert_lead
- CLOSE / COMPLETE: close_case, complete_task
- ACTIVITY LOGGING: log_contact_activity, log_lead_activity, log_opportunity_activity

<!-- Lines 280-285 -->
CONVERT (convert_lead):
1. Confirm the lead is not already converted (call fetch_lead_details first).
2. Ask whether to create an Opportunity (yes by default). If yes, ask for opportunity_name.
3. Optionally accept account_id to merge into an existing account.
4. **MANDATORY CONFIRMATION** — show the CONVERT confirmation card (Rule 3) listing the lead, target Account (new or merged), Opportunity name (or skipped), and WAIT for explicit approval.
5. On explicit approval only, call convert_lead. Display the HTML response verbatim, then append the success-confirmation sentence.

## JSON Prompt Command

```json
{
  "type": "object",
  "properties": {
    "lead_id": {
      "type": "string",
      "description": "ONLY the Salesforce Id of the Lead to convert."
    },
    "account_id": {
      "type": "string",
      "description": "Optional. The Salesforce Id of an EXISTING Account to merge the Lead into. If omitted, a new Account is created based on Lead's Company."
    },
    "opportunity_name": {
      "type": "string",
      "description": "Optional. Name for the Opportunity that will be created. Ignored if 'do_not_create_opportunity' is true."
    },
    "do_not_create_opportunity": {
      "type": "boolean",
      "description": "Optional. If true, no Opportunity is created during conversion. Default false."
    }
  },
  "required": [
    "lead_id"
  ]
}
```
