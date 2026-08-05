// Part — CPQ SKILLS (6) — Wave 8
final String CLASS_NAME = 'CpqAgenticSkillsHandler';
final String AGENTIC = 'Agentic';
final String ACTIVE = 'Active';
final String DATA_MAPPING = 'a04J9000002y7ShIAI';

List<ccai__AI_Prompt__c> prompts = new List<ccai__AI_Prompt__c>();

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_cpq_quote_details',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Load Salesforce CPQ quote header and configuration context.',
    ccai__Agentic_Function_Class__c = 'CpqAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce cpq quote id.' }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'create_cpq_quote',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Start a CPQ quote from an opportunity for guided selling.',
    ccai__Agentic_Function_Class__c = 'CpqAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'OpportunityId' },
        'additionalProperties' => true,
        'properties' => new Map<String, Object>{
            'OpportunityId' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Parent Opportunity Id (SBQQ__Quote__c.SBQQ__Opportunity2__c or equivalent).'
            },
            'Name' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Optional CPQ quote Name.'
            }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'update_cpq_quote_fields',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Edit CPQ quote status or header fields before calculation.',
    ccai__Agentic_Function_Class__c = 'CpqAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce cpq quote id.' }
        }
        ,'additionalProperties' => true
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'add_cpq_quote_line',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Add a CPQ product or bundle line to the quote.',
    ccai__Agentic_Function_Class__c = 'CpqAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'SBQQ__Quote__c' },
        'properties' => new Map<String, Object>{
            'SBQQ__Quote__c' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Parent CPQ Quote Id (SBQQ__QuoteLine__c.SBQQ__Quote__c). Not the quote-line Id.'
            }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'update_cpq_quote_line',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Change quantity, options, or pricing on a CPQ line.',
    ccai__Agentic_Function_Class__c = 'CpqAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce line id.' }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'calculate_cpq_quote',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Run CPQ pricing so totals and discounts refresh.',
    ccai__Agentic_Function_Class__c = 'CpqAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce cpq quote id.' }
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
