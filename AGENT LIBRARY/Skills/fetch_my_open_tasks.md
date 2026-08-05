# Skill: `fetch_my_open_tasks`

**Sources:** `Deliverables/force-app/main/default/classes/GenericAgenticSkillsHandler.cls`, `Deliverables/docs/GenericCRMAssistant_SystemPrompt.txt` (v1.3.1), `Deliverables/docs/GPTfy_Agent_Prompt_Commands.md`.

## Apex Code Snippet

```apex
when 'fetch_my_open_tasks'          { return handleFetchMyOpenTasks(parameters); }

    private String handleFetchMyOpenTasks(Map<String, Object> p) {
        if (!Schema.sObjectType.Task.isAccessible()) return errorJson('Task is not accessible.');
        Integer lim = 25;
        Object lRaw = p.get('limit');
        if (lRaw != null && String.isNotBlank(toText(lRaw))) {
            try { lim = Integer.valueOf(toText(lRaw)); } catch (Exception e) { lim = 25; }
        }
        lim = Math.max(1, Math.min(lim, 200));
        Id me = UserInfo.getUserId();
        List<Task> tasks = [
            SELECT Id, Subject, Status, Priority, ActivityDate, WhatId, WhoId
            FROM Task WHERE OwnerId = :me AND IsClosed = false
            WITH USER_MODE ORDER BY ActivityDate ASC NULLS LAST LIMIT :lim
        ];
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        for (Task t : tasks) {
            rows.add(new Map<String, Object>{
                'Id' => t.Id, 'Subject' => t.Subject, 'Status' => t.Status,
                'Priority' => t.Priority, 'DueDate' => String.valueOf(t.ActivityDate),
                'WhatId' => t.WhatId, 'WhoId' => t.WhoId, 'recordUrl' => recordUrl(t.Id)
            });
        }
        return successJson(new Map<String, Object>{ 'count' => rows.size(), 'tasks' => rows });
    }
```

## System Prompt Excerpt

<!-- Lines 70-73 -->
ACTIVITY SKILLS (Task / Event)
- create_task / create_event        → HTML   new Task or Event       (CONFIRMATION REQUIRED)
- complete_task                     → HTML   mark a Task as completed (CONFIRMATION REQUIRED)
- fetch_my_open_tasks               → JSON   running user's open tasks

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
    "limit": {
      "type": "integer",
      "description": "Optional. Maximum number of tasks to return (1-200). Defaults to 25."
    }
  },
  "required": []
}
```
