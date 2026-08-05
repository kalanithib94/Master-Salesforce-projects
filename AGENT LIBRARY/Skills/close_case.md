# Skill: `close_case`

**Sources:** `Deliverables/force-app/main/default/classes/GenericAgenticSkillsHandler.cls`, `Deliverables/docs/GenericCRMAssistant_SystemPrompt.txt` (v1.3.1), `Deliverables/docs/GPTfy_Agent_Prompt_Commands.md`.

## Apex Code Snippet

```apex
when 'close_case'                   { return handleCloseCase(parameters); }

    private String handleCloseCase(Map<String, Object> p) {
        String cid = toText(firstNonNull(p, new List<String>{ 'case_id', 'recordId', 'Id' }));
        String reason = toText(p.get('reason'));
        String comments = toText(p.get('comments'));
        if (String.isBlank(cid)) return errorHtml('Could not close case', 'Missing parameter: case_id');
        if (!Schema.sObjectType.Case.isUpdateable()) return errorHtml('Could not close case', 'Case is not updateable.');
        List<Case> rows = [SELECT Id, CaseNumber, Status, IsClosed FROM Case WHERE Id = :cid WITH USER_MODE LIMIT 1];
        if (rows.isEmpty()) return errorHtml('Could not close case', 'No case found for provided Id.');
        if (rows[0].IsClosed) return errorHtml('Could not close case', 'Case is already closed.');
        try {
            Case c = new Case(Id = cid, Status = 'Closed');
            if (String.isNotBlank(reason)) c.Reason = reason;
            update c;
            if (String.isNotBlank(comments)) {
                insert new CaseComment(ParentId = cid, CommentBody = comments, IsPublished = true);
            }
            String body = '<ul><li><b>Case #:</b> ' + escapeHtml(rows[0].CaseNumber) + '</li>'
                        + '<li><b>Status:</b> Closed</li>'
                        + (String.isNotBlank(reason) ? '<li><b>Reason:</b> ' + escapeHtml(reason) + '</li>' : '')
                        + '</ul>';
            return successHtml('Case Closed', body, cid, 'View Case');
        } catch (Exception ex) {
            return errorHtml('Could not close case', ex.getMessage());
        }
    }
```

## System Prompt Excerpt

<!-- Lines 66-66 -->
- close_case                        → HTML   sets Status=Closed with reason + comment    (CONFIRMATION REQUIRED)

<!-- Lines 109-109 -->
- Case        → fetch_case_details / update_case_fields / close_case → `case_id`

<!-- Lines 151-157 -->
Skills that REQUIRE confirmation before invocation:
- CREATE: create_account, create_contact, create_lead, create_opportunity, create_case, create_task, create_event
- UPDATE: update_account_fields, update_contact_fields, update_lead_fields, update_opportunity_fields, update_case_fields, bulk_update_records, add_opportunity_line_item
- Hard delete is not supported; direct permanent deletion requests to the Salesforce UI or an authorized administrator.
- CONVERT: convert_lead
- CLOSE / COMPLETE: close_case, complete_task
- ACTIVITY LOGGING: log_contact_activity, log_lead_activity, log_opportunity_activity

<!-- Lines 287-291 -->
CLOSE (close_case):
1. Confirm the case is not already closed.
2. Ask for `reason` and optional `comments`.
3. **MANDATORY CONFIRMATION** — show the CLOSE confirmation card (Rule 3) and WAIT for explicit approval.
4. On explicit approval only, call close_case. Display the HTML response verbatim, then append the success-confirmation sentence.

## JSON Prompt Command

```json
{
  "type": "object",
  "properties": {
    "case_id": {
      "type": "string",
      "description": "ONLY the Salesforce Id of the Case to close."
    },
    "reason": {
      "type": "string",
      "description": "Optional. Closure reason \u2014 must be a valid Case Reason picklist value. Examples: 'User error', 'Other', 'Instructions not clear'."
    },
    "comments": {
      "type": "string",
      "description": "Optional. Public comment to add to the Case at closure."
    }
  },
  "required": [
    "case_id"
  ]
}
```
