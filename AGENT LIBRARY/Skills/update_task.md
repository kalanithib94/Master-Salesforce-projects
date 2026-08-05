# Skill: `update_task`

**Handler:** `ActivityAgenticSkillsHandler`  
**Response:** HTML diff card

## Purpose

Partial update on an existing Task — Subject, Status, Priority, ActivityDate, Description, OwnerId, etc.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `task_id` | Yes | Salesforce Task Id |
| Other Task fields | At least one | Flat top-level keys or nested `fields` map |

## Confirmation

Required before invocation (Rule 3).
