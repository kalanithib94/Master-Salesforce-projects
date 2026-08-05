# Skill: `log_activity`

**Handler:** `ActivityAgenticSkillsHandler`  
**Response:** HTML  
**V1:** Unified activity logging — replaces `log_contact_activity`, `log_lead_activity`, `log_opportunity_activity`.

## Purpose

Logs a **completed Task** on any CRM record. Sets `WhoId` for Contact/Lead; `WhatId` for Account, Opportunity, Case, and other objects.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `record_id` | Yes | Salesforce Id of the parent record |
| `activity_subject` | Yes | Subject — must be confirmed with the user |
| `activity_description` | No | Optional notes |

## Confirmation

Required before invocation (Rule 3). Ask for subject if not provided.

## Example

```json
{
  "record_id": "006XXXXXXXXXXXX",
  "activity_subject": "Quarterly review call",
  "activity_description": "Customer wants to push close date to Q4."
}
```
