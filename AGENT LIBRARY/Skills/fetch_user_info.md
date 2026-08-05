# Skill: `fetch_user_info`

**Sources:** `Deliverables/force-app/main/default/classes/GenericAgenticSkillsHandler.cls`, `Deliverables/docs/GenericCRMAssistant_SystemPrompt.txt` (v1.3.1), `Deliverables/docs/GPTfy_Agent_Prompt_Commands.md`.

## Apex Code Snippet

```apex
when 'fetch_user_info'              { return handleFetchUserInfo(parameters); }

    private String handleFetchUserInfo(Map<String, Object> p) {
        Id me = UserInfo.getUserId();
        List<User> us = [
            SELECT Id, Name, Username, Email, FirstName, LastName, IsActive,
                   ProfileId, Profile.Name, UserRoleId, UserRole.Name,
                   TimeZoneSidKey, LocaleSidKey, LanguageLocaleKey
            FROM User WHERE Id = :me LIMIT 1
        ];
        if (us.isEmpty()) return errorJson('User not found.');
        User u = us[0];
        return successJson(new Map<String, Object>{
            'Id' => u.Id, 'Name' => u.Name, 'Email' => u.Email,
            'Username' => u.Username, 'IsActive' => u.IsActive,
            'Profile' => u.Profile != null ? u.Profile.Name : null,
            'Role'    => u.UserRole != null ? u.UserRole.Name : null,
            'TimeZone' => u.TimeZoneSidKey, 'Locale' => u.LocaleSidKey, 'Language' => u.LanguageLocaleKey,
            'currentdate__c' => String.valueOf(Date.today())
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
  "properties": {},
  "required": []
}
```
