/* =========================================================================
 * Anonymous Apex — bulk-create all 37 ccai__AI_Prompt__c records (skip-by-name).
 *
 * Each prompt is created with:
 *   - ccai__Type__c                       = "Agentic"
 *   - ccai__Status__c                     = "Active"
 *   - ccai__Agentic_Function_Class__c     = "GenericAgenticSkillsHandler"
 *   - ccai__AI_Data_Extraction_Mapping__c = "a04J9000002y7ShIAI"   (data-context mapping)
 *   - ccai__Prompt_Command__c             = JSON Schema parameter spec
 *
 * NOTE: This script's body exceeds the ~32 KB anonymous-apex compile limit on
 * most orgs. If you hit "Script too large", run the split scripts instead:
 *   scripts/Part0_DeleteAll.apex    (optional — wipes existing rows by Name)
 *   scripts/Part1_Account.apex
 *   scripts/Part2_Contact.apex
 *   scripts/Part3_Lead.apex
 *   scripts/Part4_Opportunity.apex
 *   scripts/Part5_Case.apex
 *   scripts/Part6_Activity.apex
 *   scripts/Part7_Utility.apex
 *
 * Run with:
 *   sf apex run --target-org jeevan@cloudcompliance.app_tso_gptfy --file scripts/CreateAgenticPrompts.apex
 * ========================================================================= */

final String CLASS_NAME    = 'GenericAgenticSkillsHandler';
final String AGENTIC       = 'Agentic';
final String ACTIVE        = 'Active';
final String DATA_MAPPING  = 'a04J9000002y7ShIAI';

List<ccai__AI_Prompt__c> prompts = new List<ccai__AI_Prompt__c>();

// Helper closures-style: emit a prompt
// (Apex has no closures, so we just use a small inline pattern repeatedly.)

// ════════════════════════════════════════════════════════════════════════
// 1. ACCOUNT SKILLS (5)
// ════════════════════════════════════════════════════════════════════════

prompts.add(new ccai__AI_Prompt__c(
    Name = 'create_account',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    // ccai__Description__c is Text(255) — keep this concise. Long-form guidance lives in Prompt_Command__c.
    ccai__Description__c = 'Creates a new Account. Required parameter: top-level "Name" (never invoke without it). Optional additional fields (Industry, AnnualRevenue, Phone, Website, Billing*, etc.) go inside the optional "fields" map using exact Salesforce API names.',
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
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Searches Accounts by partial Name match. Use this when the user wants to find, look up, list, or locate an Account by name. Handles spaces, hyphens, casing differences and filler words ("the", "a"). Returns up to 5 matching Account records with Id, Name, Industry, Type, Phone and Website.',
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
    Name = 'fetch_account_details',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Load key account fields and related record counts for the user.',
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>(),
        'properties' => new Map<String, Object>{
            'accountId' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Account Id (001…). Prefer when known (page context userContextId / prior skill).'
            },
            'Id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Same as accountId when the page or prior step only provides Id.'
            },
            'accountName' => new Map<String, Object>{
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
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Updates one or more fields on an existing Account. Use this when the user wants to change, set, modify, or correct any field on an Account. Supports Text, Number, Picklist, Dependent Picklist and Boolean fields in a single call. ALWAYS confirm the change with the user (current value -> new value) before invoking this skill. Never invoke without an Account Id.',
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'account_id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'ONLY the Salesforce Id of the Account to update.'
            },
            'fields' => new Map<String, Object>{
                'type' => 'object',
                'description' => 'Map of Account field API names to their NEW values. Pass only the fields the user wants to change. Use exact API names (e.g. "Industry", "AnnualRevenue", "Type", custom fields with __c suffix). Pass numbers as numbers, booleans as true/false, picklist as exact API values.',
                'additionalProperties' => true
            }
        },
        'required' => new List<String>{ 'account_id', 'fields' }
    })
));


prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_account_related_lists',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Returns the related lists for an Account — Contacts, Opportunities, and/or Cases. Use this when the user asks about an Account\'s related records, contacts on the account, deals on the account, or open cases on the account. If "related" is omitted, all three lists are returned.',
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

// ════════════════════════════════════════════════════════════════════════
// 2. CONTACT SKILLS (5)
// ════════════════════════════════════════════════════════════════════════

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fuzzy_search_contacts',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Searches Contacts by Name OR Email (partial match). Use this when the user wants to find, look up, or locate a Contact. Returns up to 5 matching Contact records with Id, Name, Email, Phone, Title and Account name.',
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
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Returns the full detail of a single Contact — FirstName, LastName, Email, Phone, MobilePhone, Title, Department, Account, Owner and MailingAddress. Use this ONLY after you have a confirmed Contact Id.',
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
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Creates a new Contact. Use when the user asks to create, add, or register a new Contact. "LastName" is mandatory. If the user gives an Account name (instead of an AccountId), pass it via "account_name" — the skill will resolve it. If you already have an AccountId, place it inside "fields" as "AccountId".',
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
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Updates one or more fields on an existing Contact. Always confirm with the user before invoking. Supports Text, Number, Picklist, Dependent Picklist and Boolean fields in a single call.',
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
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Logs a completed Task on a Contact. Use this when the user wants to log, record, or capture a call, email, meeting note or follow-up activity tied to a Contact. ALWAYS ask for a meaningful subject if not provided.',
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

// ════════════════════════════════════════════════════════════════════════
// 3. LEAD SKILLS (6)
// ════════════════════════════════════════════════════════════════════════

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fuzzy_search_leads',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Searches Leads by Name, Company, or Email (partial match). Use this when the user asks to find, list or look up Leads. Returns up to 5 matches with Id, Name, Company, Email, Phone, Status and IsConverted flag.',
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
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Returns full detail of a single Lead — FirstName, LastName, Company, Title, Email, Phone, Status, LeadSource, Industry, Rating, AnnualRevenue, IsConverted plus the converted Account/Contact/Opportunity Ids if converted.',
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
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Creates a new Lead. Use when the user explicitly asks to create or capture a new Lead. Both "LastName" AND "Company" are mandatory.',
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
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Updates one or more fields on an existing Lead. Always confirm before invoking. Cannot be used on a Lead that is already converted.',
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
    Name = 'convert_lead',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Converts a Lead into Account + Contact + (optionally) Opportunity. Use ONLY when the user has explicitly asked to convert the lead and confirmed. By default an Opportunity is created — set "do_not_create_opportunity" = true to skip. Provide "account_id" to merge into an existing Account instead of creating a new one. Provide "opportunity_name" to set the Opportunity Name.',
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'lead_id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'ONLY the Salesforce Id of the Lead to convert.'
            },
            'account_id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Optional. The Salesforce Id of an EXISTING Account to merge the Lead into.'
            },
            'opportunity_name' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Optional. Name for the Opportunity that will be created.'
            },
            'do_not_create_opportunity' => new Map<String, Object>{
                'type' => 'boolean',
                'description' => 'Optional. If true, no Opportunity is created during conversion. Default false.'
            }
        },
        'required' => new List<String>{ 'lead_id' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'log_lead_activity',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Logs a completed Task on a Lead. Use when the user wants to log, record, or capture a call, email, meeting note or follow-up activity tied to a Lead. ALWAYS ask for a meaningful subject if not provided.',
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

// ════════════════════════════════════════════════════════════════════════
// 4. OPPORTUNITY SKILLS (7)
// ════════════════════════════════════════════════════════════════════════

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fuzzy_search_opportunities',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Searches Opportunities by Name (partial match). Also accepts a Salesforce Opportunity Id (starts with "006") as the search_term — in which case it returns that exact opportunity and sets matchedVia="id". Use this whenever you need to find or look up an Opportunity, OR silently fetch current Stage/CloseDate when you already have a record Id from page context.',
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
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Returns full detail of a single Opportunity — Name, StageName, Amount, CloseDate, Probability, ForecastCategory, Account, Owner, Description, Type, LeadSource — plus "currentdate__c" (today date) for use as a date anchor.',
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
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Creates a new Opportunity. Use when the user explicitly asks to create or add an Opportunity. Three fields are mandatory: "Name", "StageName" and "CloseDate" (yyyy-MM-dd). Resolve any relative date expressions to yyyy-MM-dd BEFORE calling.',
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
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Updates one or more fields on an existing Opportunity. Supports Text, Number, Picklist, Dependent Picklist and Boolean fields in a single call. Always confirm with the user (current -> new) before invoking. All relative date expressions MUST be resolved to yyyy-MM-dd before being passed.',
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
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Logs a completed Task on an Opportunity. Use when the user wants to record a call, email, demo, meeting note, or follow-up tied to an Opportunity. ALWAYS ask for a meaningful subject if not provided.',
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
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Adds a Product (OpportunityLineItem) to an Opportunity. Use when the user asks to add a product, line item or SKU to a deal. EITHER "pricebook_entry_id" OR "product_name" must be supplied — never both. "quantity" and "unit_price" are mandatory.',
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
    Name = 'fetch_opportunity_recent_changes',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Returns the field-history audit for an Opportunity over the last N days. Use when the user asks "what changed", "recent changes", "audit history", or wants to investigate edits to an Opportunity. Requires Field History Tracking to be enabled on the Opportunity object.',
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'opportunity_id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'ONLY the Salesforce Id of the Opportunity whose recent changes should be fetched.'
            },
            'days' => new Map<String, Object>{
                'type' => 'integer',
                'description' => 'Optional. Lookback window in days (1-365). Defaults to 30.'
            }
        },
        'required' => new List<String>{ 'opportunity_id' }
    })
));

// ════════════════════════════════════════════════════════════════════════
// 5. CASE SKILLS (5)
// ════════════════════════════════════════════════════════════════════════

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fuzzy_search_cases',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Searches Cases by CaseNumber or Subject (partial match). Use when the user wants to find, look up or list Cases. Returns up to 5 matches with Id, CaseNumber, Subject, Status, Priority and AccountId.',
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
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Returns the full detail of a single Case — Subject, Description, Status, Priority, Type, Origin, Reason, Account, Contact, IsClosed. Accepts EITHER a Salesforce Case Id OR a CaseNumber as input.',
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
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Creates a new Case. Use when the user explicitly asks to open, create, log or raise a Case. "Subject" is mandatory.',
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
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Updates one or more fields on an existing Case. Always confirm with the user before invoking.',
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
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Closes a Case (sets Status = "Closed"). Optionally accepts a reason and a public comment that is added to the Case. Use ONLY when the user has explicitly asked to close, resolve, or mark a Case as Closed. Cannot be used on an already-closed Case.',
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

// ════════════════════════════════════════════════════════════════════════
// 6. ACTIVITY SKILLS (4)
// ════════════════════════════════════════════════════════════════════════

prompts.add(new ccai__AI_Prompt__c(
    Name = 'create_task',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Creates a Task on any record. Use when the user asks to create a task or to-do tied to ANY record (Account, Contact, Opportunity, Lead, Case, custom object). "Subject" is mandatory. Use "WhatId" for non-people records (Account, Opportunity, Case, custom object) and "WhoId" for people (Contact, Lead).',
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'fields' => new Map<String, Object>{
                'type' => 'object',
                'description' => 'Map of Task field API names to values. MUST include "Subject". Set "WhatId" to the Account/Opportunity/Case Id OR "WhoId" to the Contact/Lead Id. May also include Description, Status, Priority, ActivityDate (yyyy-MM-dd), OwnerId and custom fields.',
                'additionalProperties' => true
            }
        },
        'required' => new List<String>{ 'fields' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'create_event',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Creates an Event (calendar entry) on any record. Use when the user asks to schedule a meeting, demo, call or appointment. "Subject" AND "StartDateTime" are mandatory. If neither EndDateTime nor DurationInMinutes is provided, the skill defaults DurationInMinutes to 30.',
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'fields' => new Map<String, Object>{
                'type' => 'object',
                'description' => 'Map of Event field API names to values. MUST include "Subject" AND "StartDateTime" (ISO 8601, e.g. "2026-05-31T14:30:00Z"). Provide EITHER "EndDateTime" OR "DurationInMinutes". May also include "Description", "Location", "WhatId" (record like Account/Opportunity), "WhoId" (Contact/Lead), "IsAllDayEvent" and custom fields.',
                'additionalProperties' => true
            }
        },
        'required' => new List<String>{ 'fields' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_my_open_tasks',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Returns the running user open Tasks (IsClosed = false), sorted by ActivityDate ascending. Use when the user asks "what is on my plate", "show my open tasks", "my to-dos", or similar.',
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'limit' => new Map<String, Object>{
                'type' => 'integer',
                'description' => 'Optional. Maximum number of tasks to return (1-200). Defaults to 25.'
            }
        },
        'required' => new List<String>()
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'complete_task',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Marks a Task as Status = "Completed". Use when the user explicitly asks to mark a task as done, complete, or finished.',
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'task_id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'ONLY the Salesforce Id of the Task to mark Completed.'
            }
        },
        'required' => new List<String>{ 'task_id' }
    })
));

// ════════════════════════════════════════════════════════════════════════
// 7. UTILITY SKILLS (5)
// ════════════════════════════════════════════════════════════════════════

prompts.add(new ccai__AI_Prompt__c(
    Name = 'bulk_update_records',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Generic bulk multi-record / multi-field / multi-type update for ANY standard or custom Salesforce object. Use when the user asks to update multiple records of the SAME object in a single action. Each row in "records" must contain "Id" plus the fields to update. Continues on per-row errors and returns counts of succeeded / failed / skipped. Always show the user a summary of what will change BEFORE invoking.',
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'object_api_name' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'API name of the Salesforce object the records belong to. Examples: "Account", "Opportunity", "Custom_Object__c". ALL records in "records" must belong to this object.'
            },
            'records' => new Map<String, Object>{
                'type' => 'array',
                'description' => 'List of record-update objects. Each MUST contain "Id" plus any updateable fields with their new values.',
                'items' => new Map<String, Object>{
                    'type' => 'object',
                    'properties' => new Map<String, Object>{
                        'Id' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce record Id of the row to update.' }
                    },
                    'required' => new List<String>{ 'Id' },
                    'additionalProperties' => true
                }
            }
        },
        'required' => new List<String>{ 'object_api_name', 'records' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_record_history',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Returns field-history audit for any record on any object that has Field History Tracking enabled. Works for both standard objects (e.g. Account -> AccountHistory) and custom objects (e.g. Project__c -> Project__History). Use when the user asks for change history, audit trail or "what changed" on any record.',
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'record_id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'ONLY the Salesforce Id of the record whose change history should be fetched.'
            },
            'object_api_name' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'API name of the record object. Examples: "Account", "Opportunity", "Custom_Object__c".'
            },
            'days' => new Map<String, Object>{
                'type' => 'integer',
                'description' => 'Optional. Lookback window in days (1-365). Defaults to 30.'
            }
        },
        'required' => new List<String>{ 'record_id', 'object_api_name' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_user_info',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Returns the running user information — Name, Username, Email, Profile, Role, TimeZone, Locale, Language and "currentdate__c" (today date). Use as a date anchor for relative-date resolution and to personalise responses. Takes no parameters.',
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>(),
        'required' => new List<String>()
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'run_internal_prompt',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Invokes an internal GPTfy AI Prompt against a specific record and returns the LLM-generated narrative. This is the "Mixed Operation" skill — combines record context (DML) with an internal prompt to generate prose answers (deal overview, stakeholder map, meeting prep, executive summary, etc.). Use whenever the user asks an open-ended question against a specific record that is best answered by a configured GPTfy Prompt Request. The prompt_request_id MUST be a pre-configured GPTfy Prompt Request Id that exists in the org — never invent it.',
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'prompt_request_id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'The pre-configured GPTfy Prompt Request Id to invoke. Example: "96a10206d7990a5fabc728ddfd83be0fbd5a9". Must exist in the org configuration — never make this up.'
            },
            'record_id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'ONLY the Salesforce Id of the record the prompt should run against (e.g. an Opportunity Id for a Deal Overview prompt).'
            }
        },
        'required' => new List<String>{ 'prompt_request_id', 'record_id' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_picklist_values',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Description__c = 'Returns the valid picklist (or multi-picklist) values for a field on any object. Supports DEPENDENT picklists — when "controller_value" is supplied, only the values valid for that controller value are returned. Call this skill SILENTLY before any update_*_fields or create_* skill whenever you are unsure whether a picklist value the user gave is valid.',
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'object_api_name' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'API name of the object the field lives on. Examples: "Account", "Opportunity", "Custom_Object__c".'
            },
            'field_api_name' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'API name of the picklist or multi-picklist field. Examples: "Industry", "StageName", "Type__c".'
            },
            'controller_value' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Required ONLY for dependent picklists. The exact API value of the controlling field that the record will have AFTER the update. The skill returns only the dependent values valid for this controller value.'
            }
        },
        'required' => new List<String>{ 'object_api_name', 'field_api_name' }
    })
));

// ════════════════════════════════════════════════════════════════════════
// SKIP-BY-NAME + INSERT
// ════════════════════════════════════════════════════════════════════════

Set<String> proposedNames = new Set<String>();
for (ccai__AI_Prompt__c p : prompts) proposedNames.add(p.Name);

Set<String> existingNames = new Set<String>();
for (ccai__AI_Prompt__c p : [SELECT Name FROM ccai__AI_Prompt__c WHERE Name IN :proposedNames]) {
    existingNames.add(p.Name);
}

List<ccai__AI_Prompt__c> toInsert = new List<ccai__AI_Prompt__c>();
List<String> skipped = new List<String>();
for (ccai__AI_Prompt__c p : prompts) {
    if (existingNames.contains(p.Name)) {
        skipped.add(p.Name);
    } else {
        toInsert.add(p);
    }
}

if (!toInsert.isEmpty()) {
    insert toInsert;
}

System.debug('========================================');
System.debug('Proposed: ' + prompts.size());
System.debug('Skipped (already exist): ' + skipped.size() + ' -> ' + skipped);
System.debug('Inserted: ' + toInsert.size());
for (ccai__AI_Prompt__c p : toInsert) {
    System.debug('  + ' + p.Name + ' (' + p.Id + ')');
}
System.debug('========================================');
