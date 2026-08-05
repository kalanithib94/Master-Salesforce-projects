# Skill: `add_opportunity_line_item`

**Sources:** `Deliverables/force-app/main/default/classes/GenericAgenticSkillsHandler.cls`, `Deliverables/docs/GenericCRMAssistant_SystemPrompt.txt` (v1.3.1), `Deliverables/docs/GPTfy_Agent_Prompt_Commands.md`.

## Apex Code Snippet

```apex
when 'add_opportunity_line_item'    { return handleAddOpportunityLineItem(parameters); }

    private String handleAddOpportunityLineItem(Map<String, Object> p) {
        String oid = toText(firstNonNull(p, new List<String>{ 'opportunity_id', 'recordId' }));
        if (String.isBlank(oid)) return errorHtml('Could not add line item', 'Missing parameter: opportunity_id');
        Object qtyRaw = p.get('quantity');
        Object priceRaw = p.get('unit_price');
        if (qtyRaw == null) return errorHtml('Could not add line item', 'Missing parameter: quantity');
        if (priceRaw == null) return errorHtml('Could not add line item', 'Missing parameter: unit_price');
        if (!Schema.sObjectType.OpportunityLineItem.isCreateable()) return errorHtml('Could not add line item', 'OpportunityLineItem is not creatable.');
        List<Opportunity> opps = [SELECT Id, Pricebook2Id FROM Opportunity WHERE Id = :oid WITH USER_MODE LIMIT 1];
        if (opps.isEmpty()) return errorHtml('Could not add line item', 'No opportunity found for provided Id.');
        Id pbeId;
        String pbeRaw = toText(p.get('pricebook_entry_id'));
        if (String.isNotBlank(pbeRaw)) {
            try { pbeId = Id.valueOf(pbeRaw); } catch (Exception e) { return errorHtml('Could not add line item', 'Invalid pricebook_entry_id.'); }
        } else {
            String pname = toText(p.get('product_name'));
            if (String.isBlank(pname)) return errorHtml('Could not add line item', 'Provide pricebook_entry_id or product_name.');
            List<PricebookEntry> pbes = [
                SELECT Id FROM PricebookEntry
                WHERE Product2.Name = :pname AND IsActive = true AND Pricebook2Id = :opps[0].Pricebook2Id
                WITH USER_MODE LIMIT 1
            ];
            if (pbes.isEmpty()) return errorHtml('Could not add line item', 'No active PricebookEntry found for "' + pname + '" on this opportunity\'s pricebook.');
            pbeId = pbes[0].Id;
        }
        try {
            OpportunityLineItem oli = new OpportunityLineItem(
                OpportunityId = oid, PricebookEntryId = pbeId,
                Quantity = Decimal.valueOf(String.valueOf(qtyRaw)),
                UnitPrice = Decimal.valueOf(String.valueOf(priceRaw))
            );
            insert oli;
            String body = '<ul><li><b>Quantity:</b> ' + escapeHtml(String.valueOf(qtyRaw)) + '</li>'
                        + '<li><b>Unit Price:</b> ' + escapeHtml(String.valueOf(priceRaw)) + '</li></ul>';
            return successHtml('Product Added to Opportunity', body, oid, 'View Opportunity');
        } catch (Exception ex) {
            return errorHtml('Could not add line item', ex.getMessage());
        }
    }
```

## System Prompt Excerpt

<!-- Lines 67-67 -->
- add_opportunity_line_item         → HTML   add a Product to an Opportunity             (CONFIRMATION REQUIRED)

<!-- Lines 108-108 -->
- Opportunity → fetch_opportunity_details / update_opportunity_fields / log_opportunity_activity / add_opportunity_line_item / fetch_opportunity_recent_changes → `opportunity_id`. (For fuzzy_search_opportunities you may also pass the Id as `search_term`.)

<!-- Lines 151-153 -->
Skills that REQUIRE confirmation before invocation:
- CREATE: create_account, create_contact, create_lead, create_opportunity, create_case, create_task, create_event
- UPDATE: update_account_fields, update_contact_fields, update_lead_fields, update_opportunity_fields, update_case_fields, bulk_update_records, add_opportunity_line_item

<!-- Lines 265-271 -->
UPDATE (update_*_fields / bulk_update_records / add_opportunity_line_item):
1. Identify the record(s) (Rule 2).
2. Silently fetch current values to enable the diff (use fetch_*_details or fuzzy_search_*).
3. Resolve picklist values (Rule 5) and dates (Rule 4).
4. **MANDATORY CONFIRMATION** — show the UPDATE confirmation card (Rule 3) with current → new values, and WAIT for explicit approval. Do NOT call the skill before the user confirms.
5. On explicit approval only, call the update skill with `fields` map.
6. Display the HTML diff card verbatim, then append the success-confirmation sentence (see "AFTER A SUCCESSFUL MUTATION" below).

## JSON Prompt Command

```json
{
  "type": "object",
  "properties": {
    "opportunity_id": {
      "type": "string",
      "description": "ONLY the Salesforce Id of the Opportunity to add the line item to."
    },
    "pricebook_entry_id": {
      "type": "string",
      "description": "Optional. The Salesforce Id of the PricebookEntry to add. Use this if you already know the PricebookEntry Id."
    },
    "product_name": {
      "type": "string",
      "description": "Optional. Name of the Product. The skill will resolve it to an active PricebookEntry on the Opportunity's Pricebook. Use this when the user gave a product name instead of a PricebookEntry Id."
    },
    "quantity": {
      "type": "number",
      "description": "Quantity of the product (must be > 0)."
    },
    "unit_price": {
      "type": "number",
      "description": "Unit price for the line item."
    }
  },
  "required": [
    "opportunity_id",
    "quantity",
    "unit_price"
  ]
}
```
