// Part 1 — ACCOUNT SKILLS (5)
final String CLASS_NAME = 'AccountAgenticSkillsHandler';
final String AGENTIC = 'Agentic';
final String ACTIVE = 'Active';
final String DATA_MAPPING = 'a04J9000002y7ShIAI';

List<ccai__AI_Prompt__c> prompts = new List<ccai__AI_Prompt__c>();

prompts.add(new ccai__AI_Prompt__c(
    Name = 'create_account',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Open a new company record after the user confirms the name and key fields.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'Name' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'REQUIRED. The Account Name (e.g. "Acme Corporation"). This is the only mandatory parameter for creating an Account — do not invoke this skill without it.'
            },
            'fields' => new Map<String, Object>{
                'type' => 'object',
                'description' => 'Optional. Map of additional Account field API names to their values — Industry, Type, AnnualRevenue, NumberOfEmployees, Phone, Website, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Description, Rating, custom fields, etc. Do NOT put "Name" here — pass it at the top level. Numbers as numbers, booleans as true/false, picklist values as the exact API value.',
                'additionalProperties' => true
            }
        },
        'required' => new List<String>{ 'Name' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fuzzy_search_accounts',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Locate a company when the user gives a partial or spoken name.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'searchTerm' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'The Account name (or partial name) to search for. Examples: "Acme", "power grid", "United Health".'
            }
        },
        'required' => new List<String>{ 'searchTerm' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_account_details',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Load key account fields and related record counts for the user.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>(),
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Account Id (001…). Prefer when known (page context / prior skill).'
            },
            'Name' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Account Name for lookup when Id is unknown. Fuzzy match on Name.'
            },
            'userContextId' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Session / page context id when chatting on an Account record page.'
            }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'update_account_fields',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Change industry, address, phone, or other account data the user confirmed.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'ONLY the Salesforce Id of the Account to update.'
            },
            'Name' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Account Name.'
            },
            'Industry' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Industry picklist API value (call fetch_picklist_values first if unsure).'
            },
            'Type' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Type picklist API value (call fetch_picklist_values first if unsure).'
            },
            'AnnualRevenue' => new Map<String, Object>{
                'type' => 'number',
                'description' => 'Annual revenue as a plain number, no currency symbol or commas.'
            },
            'Phone' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Account phone number.'
            },
            'Website' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Account website URL.'
            },
            'Description' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Long-text description of the Account.'
            }
        },
        'additionalProperties' => true
    })
));


prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_account_related_lists',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'See contacts, opportunities, cases, and other children on the account.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'ONLY the Salesforce Id of the Account whose related lists should be fetched.'
            },
            'related' => new Map<String, Object>{
                'type' => 'array',
                'description' => 'Optional. Which related lists to fetch. Allowed values: "contacts", "opportunities", "cases". If omitted, all three are returned.',
                'items' => new Map<String, Object>{
                    'type' => 'string',
                    'enum' => new List<String>{ 'contacts', 'opportunities', 'cases' }
                }
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
