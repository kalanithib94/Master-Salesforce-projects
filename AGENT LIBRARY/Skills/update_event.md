# Skill: `update_event`

**Handler:** `ActivityAgenticSkillsHandler`  
**Response:** HTML diff card

## Purpose

Partial update on an existing Event — Subject, StartDateTime, EndDateTime, Location, Description, etc.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `event_id` | Yes | Salesforce Event Id |
| Other Event fields | At least one | Flat top-level keys or nested `fields` map |

## Confirmation

Required before invocation (Rule 3).
