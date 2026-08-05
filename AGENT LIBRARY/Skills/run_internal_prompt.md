# Skill: `run_internal_prompt`

**Sources:** `Deliverables/force-app/main/default/classes/GenericAgenticSkillsHandler.cls`, `Deliverables/docs/GenericCRMAssistant_SystemPrompt.txt` (v1.3.1), `Deliverables/docs/GPTfy_Agent_Prompt_Commands.md`.

## Apex Code Snippet

```apex
when 'run_internal_prompt'          { return handleRunInternalPrompt(parameters); }

    private String handleRunInternalPrompt(Map<String, Object> p) {
        String prid = toText(firstNonNull(p, new List<String>{ 'prompt_request_id', 'promptRequestId' }));
        String rid  = toText(firstNonNull(p, new List<String>{ 'record_id', 'recordId', 'Id' }));
        if (String.isBlank(prid)) return errorJson('Missing required parameter: prompt_request_id');
        if (String.isBlank(rid))  return errorJson('Missing required parameter: record_id');
        Id resolved;
        try { resolved = Id.valueOf(rid); } catch (Exception e) { return errorJson('Invalid record_id.'); }
        if (Test.isRunningTest() && bypassPromptForUnitTest) {
            return successJson(new Map<String, Object>{ 'status' => 'success', 'message' => 'UNIT_TEST_PLACEHOLDER', 'recordId' => resolved });
        }
        try {
            ccai.AIPromptProcessingInvokable.RequestWrapper wrap = new ccai.AIPromptProcessingInvokable.RequestWrapper();
            wrap.promptRequestId     = prid;
            wrap.recordId            = resolved;
            wrap.customPromptCommand = '';
            List<ccai.AIPromptProcessingInvokable.ResponseWrapper> resp =
                ccai.AIPromptProcessingInvokable.processRequest(new List<ccai.AIPromptProcessingInvokable.RequestWrapper>{ wrap });
            if (resp == null || resp.isEmpty()) return errorJson('No response from AI prompt processing.');
            return successJson(new Map<String, Object>{ 'status' => 'success', 'message' => resp[0].responseBody, 'recordId' => resolved });
        } catch (Exception ex) {
            return errorJson('Prompt invocation failed: ' + ex.getMessage());
        }
    }
```

## System Prompt Excerpt

<!-- Lines 79-80 -->
- fetch_picklist_values             → JSON   discover valid picklist options for any object/field
- run_internal_prompt               → JSON   run a configured GPTfy prompt against a record (Rule 7)

<!-- Lines 159-160 -->
Skills that do NOT require confirmation (read-only / lookup):
- All fuzzy_search_*, fetch_*_details, fetch_account_related_lists, fetch_my_open_tasks, fetch_record_history, fetch_user_info, fetch_opportunity_recent_changes, fetch_picklist_values, run_internal_prompt.

<!-- Lines 324-336 -->
RULE 7 — INTERNAL PROMPT (run_internal_prompt)
═══════════════════════════════════════════════════
This is your "Mixed Operation" skill — combines DML (record context) with an AI-generated narrative.

When the user asks for a "summary", "overview", "objections", "stakeholders", "meeting prep" or any open-ended LLM-style question against a specific record:
1. Identify the record (Rule 2).
2. Identify the correct GPTfy promptRequestId from the agent configuration. Each prompt has a unique Id like "96a10206d7…".
   If the promptRequestId for the requested prompt type is NOT available in your configuration context, do NOT guess or hallucinate an Id. Instead ask the user:
       "Which prompt type would you like to run? (e.g. Summary, Meeting Prep, Objections)"
   and wait for clarification before proceeding. If the user names a prompt type that still has no configured Id, tell them so honestly: "I don't have a configured prompt for '[type]' — please ask your admin to set one up, or pick one of: [list]."
3. Call run_internal_prompt with `prompt_request_id` and `record_id`.
4. The skill returns `{ success: true, message: "<llm-text>" }`. Display the `message` value verbatim — it is already LLM-formatted prose.
5. Never ask the AI prompt for fields you can fetch yourself via a fetch_*_details skill.

## JSON Prompt Command

```json
{
  "type": "object",
  "properties": {
    "prompt_request_id": {
      "type": "string",
      "description": "The pre-configured GPTfy Prompt Request Id to invoke. Example: '96a10206d7990a5fabc728ddfd83be0fbd5a9'. Must exist in the org configuration \u2014 never make this up."
    },
    "record_id": {
      "type": "string",
      "description": "ONLY the Salesforce Id of the record the prompt should run against (e.g. an Opportunity Id for a Deal Overview prompt)."
    }
  },
  "required": [
    "prompt_request_id",
    "record_id"
  ]
}
```
