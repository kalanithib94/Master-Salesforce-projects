# Skill: `complete_task`

**Sources:** `Deliverables/force-app/main/default/classes/GenericAgenticSkillsHandler.cls`, `Deliverables/docs/GenericCRMAssistant_SystemPrompt.txt` (v1.3.1), `Deliverables/docs/GPTfy_Agent_Prompt_Commands.md`.

## Apex Code Snippet

```apex
when 'complete_task'                { return handleCompleteTask(parameters); }

    private String handleCompleteTask(Map<String, Object> p) {
        String tid = toText(firstNonNull(p, new List<String>{ 'task_id', 'recordId', 'Id' }));
        if (String.isBlank(tid)) return errorHtml('Could not complete task', 'Missing parameter: task_id');
        if (!Schema.sObjectType.Task.isUpdateable()) return errorHtml('Could not complete task', 'Task is not updateable.');
        List<Task> rows = [SELECT Id, Subject, Status FROM Task WHERE Id = :tid WITH USER_MODE LIMIT 1];
        if (rows.isEmpty()) return errorHtml('Could not complete task', 'No task found for provided Id.');
        try {
            update new Task(Id = tid, Status = 'Completed');
            return successHtml('Task Completed', '<ul><li><b>Subject:</b> ' + escapeHtml(rows[0].Subject) + '</li></ul>', tid, 'View Task');
        } catch (Exception ex) {
            return errorHtml('Could not complete task', ex.getMessage());
        }
    }
```

## System Prompt Excerpt

<!-- Lines 72-72 -->
- complete_task                     → HTML   mark a Task as completed (CONFIRMATION REQUIRED)

<!-- Lines 156-157 -->
- CLOSE / COMPLETE: close_case, complete_task
- ACTIVITY LOGGING: log_contact_activity, log_lead_activity, log_opportunity_activity

<!-- Lines 293-296 -->
COMPLETE (complete_task):
1. Identify the task (Rule 2).
2. **MANDATORY CONFIRMATION** — show: "Mark task '[Subject]' as Completed? (yes / no)" and WAIT for explicit approval.
3. On explicit approval only, call complete_task. Display the HTML response verbatim, then append the success-confirmation sentence.

## JSON Prompt Command

```json
{
  "type": "object",
  "properties": {
    "task_id": {
      "type": "string",
      "description": "ONLY the Salesforce Id of the Task to mark Completed."
    }
  },
  "required": [
    "task_id"
  ]
}
```
