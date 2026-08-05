# Skill: `fetch_account_details`

**Sources:** `Deliverables/force-app/main/default/classes/GenericAgenticSkillsHandler.cls` (`handleFetchAccountDetails`, `fetchAccountDetailsJsonForId`), `Deliverables/docs/GenericCRMAssistant_SystemPrompt.txt` (v1.3.2+), `Deliverables/docs/GPTfy_Agent_Prompt_Commands.md`.

## Behaviour (summary)

- **`account_id` / `recordId` / `Id` (non-blank):** Runs the detail `SELECT` by Id. `account_name` is ignored.
- **Otherwise `account_name` / `Name`:** Uses the same `fuzzyQuery('Account', 'Name', …)` as `fuzzy_search_accounts`.
  - **0** matches → `success: false`, not found.
  - **1** match → same success JSON as the Id path (full detail fields).
  - **2–5** matches → `success: false`, `errorCode: AMBIGUOUS_ACCOUNT_NAME`, `records` picker rows (`Id`, `Name`, `Type`, `Industry`, `Website`, `recordUrl`, `viewRecord`).
  - **6+** matches → `success: false`, `errorCode: TOO_MANY_ACCOUNT_MATCHES`, `totalFound` (no exhaustive row list).

`Account.Rating` is intentionally excluded from the detail `SELECT` (Jira V2-8418 — some orgs disable the field).

## Apex entry (dispatch)

```apex
when 'fetch_account_details' { return handleFetchAccountDetails(parameters); }
```

Implementation detail: `handleFetchAccountDetails` delegates the final detail payload to `fetchAccountDetailsJsonForId` after Id resolution (direct or single name match). Extended errors use `errorJson(String msg, Map<String, Object> extra)`.

## System prompt (high level)

- Record page / confirmed Id → `account_id` only; no fuzzy.
- User names Account + asks for details or fields → `account_name` when no Id; one-line match banner on single hit; picker / refine flows for multi-match error codes (see Rule 2 in `GenericCRMAssistant_SystemPrompt.txt`).

## JSON Prompt Command (`Prompt_Command__c`)

`account_id` and `account_name` are both optional at the root, with **`anyOf`** requiring exactly one branch:

```json
{
  "type": "object",
  "properties": {
    "account_id": {
      "type": "string",
      "description": "Salesforce Account Id (15 or 18 characters). Use when you have a confirmed Id (record page, prior turn, or user pasted Id). Preferred over account_name when both could apply."
    },
    "account_name": {
      "type": "string",
      "description": "Account Name as the user stated it. Use when you have no Account Id. The skill fuzzy-matches on Name; see skill Description for single vs multi-match behaviour."
    }
  },
  "anyOf": [
    { "required": ["account_id"] },
    { "required": ["account_name"] }
  ]
}
```

Canonical copy: [`Deliverables/docs/GPTfy_Agent_Prompt_Commands.md`](../Deliverables/docs/GPTfy_Agent_Prompt_Commands.md) §1.2.
