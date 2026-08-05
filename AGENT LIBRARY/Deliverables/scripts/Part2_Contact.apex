// Part 2 — CONTACT SKILLS (5)
final String CLASS_NAME = 'ContactAgenticSkillsHandler';
final String AGENTIC = 'Agentic';
final String ACTIVE = 'Active';
final String DATA_MAPPING = 'a04J9000002y7ShIAI';

List<ccai__AI_Prompt__c> prompts = new List<ccai__AI_Prompt__c>();



prompts.add(new ccai__AI_Prompt__c(
    Name = 'fuzzy_search_contacts',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Find a person by name or email when the Salesforce Id is unknown.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'searchTerm' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'The Contact name OR email (or partial) to search for. Examples: "John Smith", "john@acme.com", "Khan".'
            }
        },
        'required' => new List<String>{ 'searchTerm' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_contact_details',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Load contact profile, title, and account link for outreach or updates.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'ONLY the Salesforce Id of the Contact whose details should be fetched.'
            }
        },
        'required' => new List<String>{ 'Id' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'create_contact',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Add a person to Salesforce, usually under an existing account.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>(),
        'additionalProperties' => true,
        'properties' => new Map<String, Object>{
            'LastName' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'REQUIRED. Contact LastName (org field API name).'
            },
            'FirstName' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Contact FirstName.'
            },
            'Email' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Contact Email.'
            },
            'Phone' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Contact Phone.'
            },
            'Title' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Contact Title.'
            },
            'AccountId' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Parent Account Id (org relationship field AccountId). Prefer over accountName when known.'
            },
            'accountName' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Optional. Parent Account Name when AccountId is unknown — skill resolves to AccountId.'
            }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'update_contact_fields',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Correct email, phone, title, or other contact details after confirmation.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'ONLY the Salesforce Id of the Contact to update.'
            },
            'fields' => new Map<String, Object>{
                'type' => 'object',
                'description' => 'Map of Contact field API names to their NEW values. Pass only the fields the user wants to change.',
                'additionalProperties' => true
            }
        },
        'required' => new List<String>{ 'Id', 'fields' }
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
