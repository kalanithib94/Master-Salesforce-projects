// Part — QUOTE SKILLS (6) — Wave 4
final String CLASS_NAME = 'QuoteAgenticSkillsHandler';
final String AGENTIC = 'Agentic';
final String ACTIVE = 'Active';
final String DATA_MAPPING = 'a04J9000002y7ShIAI';

List<ccai__AI_Prompt__c> prompts = new List<ccai__AI_Prompt__c>();

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fuzzy_search_quotes',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Find a quote by name when the quote number is unknown.',
    ccai__Agentic_Function_Class__c = 'QuoteAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'searchTerm' },
        'properties' => new Map<String, Object>{
            'searchTerm' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Partial name or keyword to search.' }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_quote_details',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Load quote header, status, and totals for review.',
    ccai__Agentic_Function_Class__c = 'QuoteAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce quote id.' }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'create_quote',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Create a standard quote for an opportunity.',
    ccai__Agentic_Function_Class__c = 'QuoteAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Name', 'OpportunityId' },
        'additionalProperties' => true,
        'properties' => new Map<String, Object>{
            'Name' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Quote.Name (required).'
            },
            'OpportunityId' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Parent Opportunity Id (Quote.OpportunityId).'
            },
            'ExpirationDate' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Optional Quote.ExpirationDate (yyyy-MM-dd).'
            },
            'Status' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Optional Quote.Status picklist API value.'
            }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'update_quote_fields',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Change quote status, expiration, or header fields.',
    ccai__Agentic_Function_Class__c = 'QuoteAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce quote id.' }
        }
        ,'additionalProperties' => true
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'add_quote_line_item',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Add a priced product line to the quote.',
    ccai__Agentic_Function_Class__c = 'QuoteAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'QuoteId' },
        'properties' => new Map<String, Object>{
            'QuoteId' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Parent Quote Id (QuoteLineItem.QuoteId). Not the line-item Id.'
            }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'update_quote_line_item',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Change quantity or price on an existing quote line.',
    ccai__Agentic_Function_Class__c = 'QuoteAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce line item id.' }
        }
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
