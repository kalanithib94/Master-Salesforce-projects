// Part 4 — OPPORTUNITY SKILLS (6) — v1 + wave 2
final String CLASS_NAME = 'OpportunityAgenticSkillsHandler';
final String AGENTIC = 'Agentic';
final String ACTIVE = 'Active';
final String DATA_MAPPING = 'a04J9000002y7ShIAI';

List<ccai__AI_Prompt__c> prompts = new List<ccai__AI_Prompt__c>();

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fuzzy_search_opportunities',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Find a deal by name when the user cannot provide the Id.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'searchTerm' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Opportunity Name (partial) OR Salesforce Opportunity Id (006…).'
            }
        },
        'required' => new List<String>{ 'searchTerm' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_opportunity_details',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Load stage, amount, close date, and deal context for review.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'ONLY the Salesforce Id of the Opportunity whose details should be fetched.'
            }
        },
        'required' => new List<String>{ 'Id' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'create_opportunity',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Start a new deal with account, stage, and close date confirmed.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'fields' => new Map<String, Object>{
                'type' => 'object',
                'description' => 'Map of Opportunity field API names to values. MUST include "Name", "StageName", AND "CloseDate" (yyyy-MM-dd). May include AccountId, Amount, Probability, Type, LeadSource, NextStep, Description, Pricebook2Id and custom fields.',
                'additionalProperties' => true
            }
        },
        'required' => new List<String>{ 'fields' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'update_opportunity_fields',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Move stage, change amount or close date, or edit other deal fields.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'ONLY the Salesforce Id of the Opportunity to update.'
            },
            'fields' => new Map<String, Object>{
                'type' => 'object',
                'description' => 'Map of Opportunity field API names to NEW values. Common fields: StageName, Amount, CloseDate (yyyy-MM-dd), Probability, ForecastCategoryName, NextStep, Description and custom fields. Pass numbers as numbers, dates as "yyyy-MM-dd", booleans as true/false, picklist values as exact API values.',
                'additionalProperties' => true
            }
        },
        'required' => new List<String>{ 'Id', 'fields' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'add_opportunity_line_item',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Attach a priced product from the price book to the deal.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'OpportunityId' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Parent Opportunity Id (OpportunityLineItem.OpportunityId). Not the line-item Id.'
            },
            'PricebookEntryId' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Optional. PricebookEntry Id. Use when already known.'
            },
            'Name' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Optional. Product name resolved to an active PricebookEntry on the Opportunity price book.'
            },
            'Quantity' => new Map<String, Object>{
                'type' => 'number',
                'description' => 'Quantity of the product (must be > 0). OpportunityLineItem.Quantity.'
            },
            'UnitPrice' => new Map<String, Object>{
                'type' => 'number',
                'description' => 'Unit price for the line item (OpportunityLineItem.UnitPrice).'
            }
        },
        'required' => new List<String>{ 'OpportunityId', 'Quantity', 'UnitPrice' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'update_opportunity_line_item',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Adjust quantity, price, or discount on an existing product line.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Salesforce Id of the OpportunityLineItem to update.'
            },
            'Quantity' => new Map<String, Object>{ 'type' => 'number' },
            'UnitPrice' => new Map<String, Object>{ 'type' => 'number' },
            'Discount' => new Map<String, Object>{ 'type' => 'number' }
        },
        'required' => new List<String>{ 'Id' },
        'additionalProperties' => true
    })
));

Set<String> proposedNames = new Set<String>();
for (ccai__AI_Prompt__c p : prompts) proposedNames.add(p.Name);
Set<String> existingNames = new Set<String>();
for (ccai__AI_Prompt__c p : [SELECT Name FROM ccai__AI_Prompt__c WHERE Name IN :proposedNames]) {
    existingNames.add(p.Name);
}
List<ccai__AI_Prompt__c> toInsert = new List<ccai__AI_Prompt__c>();
List<String> skipped = new List<String>();
for (ccai__AI_Prompt__c p : prompts) {
    if (existingNames.contains(p.Name)) skipped.add(p.Name);
    else toInsert.add(p);
}
if (!toInsert.isEmpty()) insert toInsert;
System.debug('Inserted ' + toInsert.size() + ' / Skipped ' + skipped.size() + ' -> ' + skipped);
for (ccai__AI_Prompt__c p : toInsert) System.debug('  + ' + p.Name + ' -> ' + p.Id);
