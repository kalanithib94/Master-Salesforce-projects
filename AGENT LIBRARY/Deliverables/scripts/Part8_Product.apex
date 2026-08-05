// Part 8 — PRODUCT SKILLS (3) — Wave 2
final String CLASS_NAME = 'ProductAgenticSkillsHandler';
final String AGENTIC = 'Agentic';
final String ACTIVE = 'Active';
final String DATA_MAPPING = 'a04J9000002y7ShIAI';

List<ccai__AI_Prompt__c> prompts = new List<ccai__AI_Prompt__c>();

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fuzzy_search_products',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Find a SKU or product name before adding lines to a deal or quote.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'searchTerm' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Product name or product code partial match.'
            }
        },
        'required' => new List<String>{ 'searchTerm' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_product_details',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Load product code, family, and description for configuration.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Salesforce Product2 Id.'
            }
        },
        'required' => new List<String>{ 'Id' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_pricebook_entries',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Show list prices for products in a chosen or standard price book.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'Pricebook2Id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Optional. Pricebook2 Id. Defaults to standard pricebook.'
            },
            'Id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Optional. Filter entries to one Product2 Id.'
            },
            'limit' => new Map<String, Object>{
                'type' => 'integer',
                'description' => 'Optional. Max rows (1-200). Default 25.'
            }
        },
        'required' => new List<String>()
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
