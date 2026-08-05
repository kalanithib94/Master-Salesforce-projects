# Skill: `fetch_session_context`

**Sources:** `Deliverables/force-app/main/default/classes/GenericAgenticSkillsHandler.cls`, GPTfy runtime (V2-8560 userContextId injection).

## Purpose

Returns the current chat **userContextId** (session/thread Id) and the related record Id mapped to **WhoId** (Contact/Lead) or **WhatId** (Account, Opportunity, Case, and other non-person records) for Task/Event linking.

## Apex Code Snippet

```apex
when 'fetch_session_context'        { return handleFetchSessionContext(parameters); }

private String handleFetchSessionContext(Map<String, Object> p) {
    String userContextId = toText(firstNonNull(p, new List<String>{ 'userContextId', 'user_context_id' }));
    Id recordId = resolveSessionRecordId(p, userContextId);
    // ... maps recordId → WhoId or WhatId based on object type
    return successJson(result);
}
```

Record resolution order:
1. Explicit parameter (`record_id`, `recordId`, `relatedToId`)
2. `ccai__AI_Response__c.ccai__Record_Id__c` for the session
3. `userContextId` when it is itself a valid Salesforce Id

## When to call

- Before creating Tasks/Events and you need the correct WhoId/WhatId for the page-context record
- When you need the session `userContextId` returned to the GPTfy runtime
- When linking uploaded files or activities to the current record

## JSON Prompt Command

```json
{
  "type": "object",
  "properties": {
    "record_id": {
      "type": "string",
      "description": "Optional. Salesforce Id of the page-context or related record (15 or 18 characters)."
    }
  },
  "required": []
}
```

## Sample response

```json
{
  "success": true,
  "userContextId": "conv_3801kv52phh9f299ys583b2r4bz4",
  "userId": "005XXXXXXXXXXXX",
  "recordId": "001XXXXXXXXXXXX",
  "objectType": "Account",
  "WhoId": null,
  "WhatId": "001XXXXXXXXXXXX",
  "relationType": "WhatId"
}
```
