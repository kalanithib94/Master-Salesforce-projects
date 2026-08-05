# Skill: `update_opportunity_line_item`

**Handler:** `OpportunityAgenticSkillsHandler`  
**Response:** HTML diff card

## Purpose

Updates an existing OpportunityLineItem — Quantity, UnitPrice, Discount, and other updateable fields.

## Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `line_item_id` | Yes | OpportunityLineItem Id |
| `Quantity`, `UnitPrice`, `Discount`, … | At least one | Field API names as flat keys or `fields` map |

## Confirmation

Required before invocation (Rule 3). Pair with `add_opportunity_line_item` for full product lifecycle on deals.
