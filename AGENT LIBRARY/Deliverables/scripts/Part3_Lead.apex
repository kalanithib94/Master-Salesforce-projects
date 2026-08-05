// Part 3 — LEAD SKILLS (6)
final String CLASS_NAME = 'LeadAgenticSkillsHandler';
final String AGENTIC = 'Agentic';
final String ACTIVE = 'Active';
final String DATA_MAPPING = 'a04J9000002y7ShIAI';

List<ccai__AI_Prompt__c> prompts = new List<ccai__AI_Prompt__c>();



prompts.add(new ccai__AI_Prompt__c(
    Name = 'fuzzy_search_leads',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Find a prospect by name or company before qualifying or converting.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'searchTerm' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Lead name, company name, or email to search for. Examples: "Jane Doe", "Acme Industries", "jane@acme.com".'
            }
        },
        'required' => new List<String>{ 'searchTerm' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_lead_details',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Load lead status, source, and company context for follow-up.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'ONLY the Salesforce Id of the Lead whose details should be fetched.'
            }
        },
        'required' => new List<String>{ 'Id' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'create_lead',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Capture a new prospect when there is no matching account yet.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'fields' => new Map<String, Object>{
                'type' => 'object',
                'description' => 'Map of Lead field API names to values. MUST include "LastName" AND "Company". May include FirstName, Title, Email, Phone, MobilePhone, Status, LeadSource, Industry, Rating, AnnualRevenue, NumberOfEmployees and custom fields.',
                'additionalProperties' => true
            }
        },
        'required' => new List<String>{ 'fields' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'update_lead_fields',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Update lead status, score, or contact info during qualification.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'ONLY the Salesforce Id of the Lead to update.'
            },
            'fields' => new Map<String, Object>{
                'type' => 'object',
                'description' => 'Map of Lead field API names to their NEW values. Only fields the user wants to change.',
                'additionalProperties' => true
            }
        },
        'required' => new List<String>{ 'Id', 'fields' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'convert_lead',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Turn a qualified lead into account, contact, and optional opportunity.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'ONLY the Salesforce Id of the Lead to convert.'
            },
            'AccountId' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Optional. The Salesforce Id of an EXISTING Account to merge the Lead into.'
            },
            'opportunityName' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Optional. Name for the Opportunity that will be created.'
            },
            'doNotCreateOpportunity' => new Map<String, Object>{
                'type' => 'boolean',
                'description' => 'Optional. If true, no Opportunity is created during conversion. Default false.'
            }
        },
        'required' => new List<String>{ 'Id' }
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
