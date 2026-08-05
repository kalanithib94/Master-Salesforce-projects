// =============================================================================
// SeedClientSkills.apex
// Creates agent "GPTfy Agent", inserts 25 CRM object skills, and links them.
// Prerequisites: GPTfy (ccai) installed + Apex handlers deployed via package.xml
//
// BEFORE RUNNING: set DATA_MAPPING to this org's
//   ccai__AI_Data_Extraction_Mapping__c Id (Ids do not transfer between orgs).
//
// Usage:
//   sf apex run --file client-package/SeedClientSkills.apex --target-org <alias>
// =============================================================================

final String AGENT_NAME = 'GPTfy Agent';
final String AGENTIC = 'Agentic';
final String ACTIVE = 'Active';
// TODO: replace with THIS org's Data Extraction Mapping Id
final String DATA_MAPPING = 'a07fj00000oFJAXAA4';
// Required on ccai__AI_Agent__c — references ccai__AI_Connection__c (e.g. GPTfy OpenAI)
final String AI_MODEL = 'a03fj00001PIgEnAAL';

if (DATA_MAPPING == null || DATA_MAPPING.startsWith('REPLACE_')) {
    System.debug(LoggingLevel.ERROR,
        'Stop: set DATA_MAPPING to a valid ccai__AI_Data_Extraction_Mapping__c Id before running.');
} else if (AI_MODEL == null || AI_MODEL.startsWith('REPLACE_')) {
    System.debug(LoggingLevel.ERROR,
        'Stop: set AI_MODEL to a valid ccai__AI_Connection__c Id before running.');
} else {

// --- Agent -------------------------------------------------------------------
List<ccai__AI_Agent__c> agents = [
    SELECT Id, Name, ccai__Status__c, ccai__AI_Model__c
    FROM ccai__AI_Agent__c
    WHERE Name = :AGENT_NAME
    LIMIT 1
];
ccai__AI_Agent__c agent;
if (agents.isEmpty()) {
    agent = new ccai__AI_Agent__c(
        Name = AGENT_NAME,
        ccai__Status__c = ACTIVE,
        ccai__AI_Model__c = AI_MODEL
    );
    insert agent;
    System.debug('Created agent: ' + agent.Id + ' (' + AGENT_NAME + ')');
} else {
    agent = agents[0];
    Boolean dirty = false;
    if (agent.ccai__Status__c != ACTIVE) {
        agent.ccai__Status__c = ACTIVE;
        dirty = true;
    }
    if (agent.ccai__AI_Model__c == null) {
        agent.ccai__AI_Model__c = AI_MODEL;
        dirty = true;
    }
    if (dirty) {
        update agent;
    }
    System.debug('Using existing agent: ' + agent.Id + ' (' + AGENT_NAME + ')');
}

// --- Prompts (25 skills) -----------------------------------------------------
List<ccai__AI_Prompt__c> prompts = new List<ccai__AI_Prompt__c>();

prompts.add(new ccai__AI_Prompt__c(
    Name = 'create_account',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = 'AccountAgenticSkillsHandler',
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
    ccai__Agentic_Function_Class__c = 'AccountAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'search_term' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'The Account name (or partial name) to search for. Examples: "Acme", "power grid", "United Health".'
            }
        },
        'required' => new List<String>{ 'search_term' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'update_account_fields',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = 'AccountAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'account_id' },
        'properties' => new Map<String, Object>{
            'account_id' => new Map<String, Object>{
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
    ccai__Agentic_Function_Class__c = 'AccountAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'account_id' => new Map<String, Object>{
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
        'required' => new List<String>{ 'account_id' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fuzzy_search_contacts',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = 'ContactAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'search_term' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'The Contact name OR email (or partial) to search for. Examples: "John Smith", "john@acme.com", "Khan".'
            }
        },
        'required' => new List<String>{ 'search_term' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_contact_details',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = 'ContactAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'contact_id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'ONLY the Salesforce Id of the Contact whose details should be fetched.'
            }
        },
        'required' => new List<String>{ 'contact_id' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'create_contact',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = 'ContactAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'fields' => new Map<String, Object>{
                'type' => 'object',
                'description' => 'Map of Contact field API names to values. MUST include "LastName". May include FirstName, Email, Phone, MobilePhone, Title, Department, AccountId, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry and custom fields.',
                'additionalProperties' => true
            },
            'account_name' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Optional. Account name to associate this Contact with. The skill resolves it to the AccountId. Use ONLY when the user has not supplied an AccountId directly.'
            }
        },
        'required' => new List<String>{ 'fields' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'update_contact_fields',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = 'ContactAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'contact_id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'ONLY the Salesforce Id of the Contact to update.'
            },
            'fields' => new Map<String, Object>{
                'type' => 'object',
                'description' => 'Map of Contact field API names to their NEW values. Pass only the fields the user wants to change.',
                'additionalProperties' => true
            }
        },
        'required' => new List<String>{ 'contact_id', 'fields' }
    })
));


prompts.add(new ccai__AI_Prompt__c(
    Name = 'log_contact_activity',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = 'ContactAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'contact_id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'ONLY the Salesforce Id of the Contact the activity should be logged against.'
            },
            'activity_subject' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'A short, meaningful subject for the activity. MUST NOT be a placeholder.'
            },
            'activity_description' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Optional longer-form notes captured against the activity.'
            }
        },
        'required' => new List<String>{ 'contact_id', 'activity_subject' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fuzzy_search_leads',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = 'LeadAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'search_term' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Lead name, company name, or email to search for. Examples: "Jane Doe", "Acme Industries", "jane@acme.com".'
            }
        },
        'required' => new List<String>{ 'search_term' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_lead_details',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = 'LeadAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'lead_id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'ONLY the Salesforce Id of the Lead whose details should be fetched.'
            }
        },
        'required' => new List<String>{ 'lead_id' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'create_lead',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = 'LeadAgenticSkillsHandler',
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
    ccai__Agentic_Function_Class__c = 'LeadAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'lead_id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'ONLY the Salesforce Id of the Lead to update.'
            },
            'fields' => new Map<String, Object>{
                'type' => 'object',
                'description' => 'Map of Lead field API names to their NEW values. Only fields the user wants to change.',
                'additionalProperties' => true
            }
        },
        'required' => new List<String>{ 'lead_id', 'fields' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'log_lead_activity',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = 'LeadAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'lead_id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'ONLY the Salesforce Id of the Lead the activity should be logged against.'
            },
            'activity_subject' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'A short, meaningful subject for the activity. MUST NOT be a placeholder.'
            },
            'activity_description' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Optional longer-form notes captured against the activity.'
            }
        },
        'required' => new List<String>{ 'lead_id', 'activity_subject' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fuzzy_search_opportunities',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = 'OpportunityAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'search_term' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'The Opportunity Name (or partial name), OR a 15-/18-character Salesforce Opportunity Id starting with "006". Examples: "Acme Big Deal", "Renewal Q3", "006A0000005Tx9X".'
            }
        },
        'required' => new List<String>{ 'search_term' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_opportunity_details',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = 'OpportunityAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'opportunity_id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'ONLY the Salesforce Id of the Opportunity whose details should be fetched.'
            }
        },
        'required' => new List<String>{ 'opportunity_id' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'create_opportunity',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = 'OpportunityAgenticSkillsHandler',
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
    ccai__Agentic_Function_Class__c = 'OpportunityAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'opportunity_id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'ONLY the Salesforce Id of the Opportunity to update.'
            },
            'fields' => new Map<String, Object>{
                'type' => 'object',
                'description' => 'Map of Opportunity field API names to NEW values. Common fields: StageName, Amount, CloseDate (yyyy-MM-dd), Probability, ForecastCategoryName, NextStep, Description and custom fields. Pass numbers as numbers, dates as "yyyy-MM-dd", booleans as true/false, picklist values as exact API values.',
                'additionalProperties' => true
            }
        },
        'required' => new List<String>{ 'opportunity_id', 'fields' }
    })
));


prompts.add(new ccai__AI_Prompt__c(
    Name = 'log_opportunity_activity',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = 'OpportunityAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'opportunity_id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'ONLY the Salesforce Id of the Opportunity the activity should be logged against.'
            },
            'activity_subject' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'A short, meaningful subject for the activity. MUST NOT be a placeholder.'
            },
            'activity_description' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Optional longer-form notes captured against the activity.'
            }
        },
        'required' => new List<String>{ 'opportunity_id', 'activity_subject' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'add_opportunity_line_item',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = 'OpportunityAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'opportunity_id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'ONLY the Salesforce Id of the Opportunity to add the line item to.'
            },
            'pricebook_entry_id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Optional. The Salesforce Id of the PricebookEntry to add. Use this if you already know the PricebookEntry Id.'
            },
            'product_name' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Optional. Name of the Product. The skill will resolve it to an active PricebookEntry on the Opportunity Pricebook. Use this when the user gave a product name instead of a PricebookEntry Id.'
            },
            'quantity' => new Map<String, Object>{
                'type' => 'number',
                'description' => 'Quantity of the product (must be > 0).'
            },
            'unit_price' => new Map<String, Object>{
                'type' => 'number',
                'description' => 'Unit price for the line item.'
            }
        },
        'required' => new List<String>{ 'opportunity_id', 'quantity', 'unit_price' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fuzzy_search_cases',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = 'CaseAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'search_term' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'CaseNumber (e.g. "00001234") or part of the Case Subject. Examples: "login", "00001234", "crash".'
            }
        },
        'required' => new List<String>{ 'search_term' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_case_details',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = 'CaseAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'case_id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Either the Salesforce Id of the Case (starts with "500") OR the human-readable CaseNumber (e.g. "00001234").'
            }
        },
        'required' => new List<String>{ 'case_id' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'create_case',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = 'CaseAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'fields' => new Map<String, Object>{
                'type' => 'object',
                'description' => 'Map of Case field API names to values. MUST include "Subject". May include Description, Status, Priority, Type, Origin, Reason, AccountId, ContactId, OwnerId and custom fields.',
                'additionalProperties' => true
            }
        },
        'required' => new List<String>{ 'fields' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'update_case_fields',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = 'CaseAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'case_id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'ONLY the Salesforce Id of the Case to update.'
            },
            'fields' => new Map<String, Object>{
                'type' => 'object',
                'description' => 'Map of Case field API names to NEW values. Only the fields the user wants to change.',
                'additionalProperties' => true
            }
        },
        'required' => new List<String>{ 'case_id', 'fields' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'close_case',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = 'CaseAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'case_id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'ONLY the Salesforce Id of the Case to close.'
            },
            'reason' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Optional. Closure reason — must be a valid Case Reason picklist value. Examples: "User error", "Other", "Instructions not clear".'
            },
            'comments' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Optional. Public comment to add to the Case at closure.'
            }
        },
        'required' => new List<String>{ 'case_id' }
    })
));

Set<String> proposedNames = new Set<String>();
for (ccai__AI_Prompt__c p : prompts) proposedNames.add(p.Name);

Map<String, Id> existingByName = new Map<String, Id>();
for (ccai__AI_Prompt__c p : [
    SELECT Id, Name FROM ccai__AI_Prompt__c WHERE Name IN :proposedNames
]) {
    existingByName.put(p.Name, p.Id);
}

List<ccai__AI_Prompt__c> toInsert = new List<ccai__AI_Prompt__c>();
List<String> skipped = new List<String>();
for (ccai__AI_Prompt__c p : prompts) {
    if (existingByName.containsKey(p.Name)) skipped.add(p.Name);
    else toInsert.add(p);
}
if (!toInsert.isEmpty()) insert toInsert;
System.debug('Prompts inserted ' + toInsert.size() + ' / skipped ' + skipped.size() + ' -> ' + skipped);

// Refresh Id map with newly inserted rows
for (ccai__AI_Prompt__c p : toInsert) existingByName.put(p.Name, p.Id);
for (ccai__AI_Prompt__c p : [
    SELECT Id, Name FROM ccai__AI_Prompt__c WHERE Name IN :proposedNames
]) {
    existingByName.put(p.Name, p.Id);
}

// --- Link skills to GPTfy Agent ---------------------------------------------
Set<Id> promptIds = new Set<Id>(existingByName.values());
Set<Id> alreadyLinked = new Set<Id>();
for (ccai__AI_Agent_Skill__c link : [
    SELECT ccai__AI_Prompt__c
    FROM ccai__AI_Agent_Skill__c
    WHERE ccai__AI_Agent__c = :agent.Id
      AND ccai__AI_Prompt__c IN :promptIds
]) {
    alreadyLinked.add(link.ccai__AI_Prompt__c);
}

List<ccai__AI_Agent_Skill__c> newLinks = new List<ccai__AI_Agent_Skill__c>();
for (String skillName : proposedNames) {
    Id pid = existingByName.get(skillName);
    if (pid == null) continue;
    if (alreadyLinked.contains(pid)) continue;
    newLinks.add(new ccai__AI_Agent_Skill__c(
        ccai__AI_Agent__c = agent.Id,
        ccai__AI_Prompt__c = pid
    ));
}
if (!newLinks.isEmpty()) insert newLinks;
System.debug('Agent skill links created: ' + newLinks.size());
System.debug('Done. Agent Id=' + agent.Id + ' Name=' + AGENT_NAME
    + ' Skills expected=' + proposedNames.size());
} // end DATA_MAPPING guard
