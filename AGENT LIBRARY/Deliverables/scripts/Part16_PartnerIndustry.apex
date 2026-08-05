// Part — PARTNER, INDUSTRY & PLATFORM (12) — Waves 10–12
final String AGENTIC = 'Agentic';
final String ACTIVE = 'Active';
final String DATA_MAPPING = 'a04J9000002y7ShIAI';

List<ccai__AI_Prompt__c> prompts = new List<ccai__AI_Prompt__c>();

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fuzzy_search_partners',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Find partner accounts by name for deal registration or teaming.',
    ccai__Agentic_Function_Class__c = 'PartnerAgenticSkillsHandler',
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
    Name = 'fetch_partner_account',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Load partner account profile and relationship details.',
    ccai__Agentic_Function_Class__c = 'PartnerAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Partner account Id (primary Id of the Account / partner record).'
            }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'add_opportunity_partner',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Associate a partner account with a deal and role.',
    ccai__Agentic_Function_Class__c = 'PartnerAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'OpportunityId' },
        'properties' => new Map<String, Object>{
            'OpportunityId' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce opportunity id.' },
            'AccountId' => new Map<String, Object>{ 'type' => 'string' },
            'Role' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Partner role for the opportunity-account relationship.' }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_opportunity_partners',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'List partners already tied to the opportunity.',
    ccai__Agentic_Function_Class__c = 'OpportunityAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'OpportunityId' },
        'properties' => new Map<String, Object>{
            'OpportunityId' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce opportunity id.' }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_financial_account',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Load FSC financial account balances and ownership when licensed.',
    ccai__Agentic_Function_Class__c = 'IndustryAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce record id.' }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'update_financial_account_fields',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Update financial account status or attributes in FSC orgs.',
    ccai__Agentic_Function_Class__c = 'IndustryAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce financial account id.' }
        }
        ,'additionalProperties' => true
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_care_plan',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Load a Health Cloud care plan and related goals when available.',
    ccai__Agentic_Function_Class__c = 'IndustryAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce record id.' }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_record_approvals',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'See pending approval requests and submitters on a record.',
    ccai__Agentic_Function_Class__c = 'UtilityAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce record id.' }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_renewal_opportunities',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'List open renewal-type deals for pipeline or CSM review.',
    ccai__Agentic_Function_Class__c = 'UtilityAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>(),
        'properties' => new Map<String, Object>{
            'AccountId' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Optional Account filter (Opportunity.AccountId).' }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'remove_campaign_member',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Take a lead or contact off a campaign membership.',
    ccai__Agentic_Function_Class__c = 'CampaignAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'CampaignMember Id (primary Id of the membership row to delete). Not CampaignId.'
            }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'create_care_task',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Add a care-plan task for clinical or care-team follow-up.',
    ccai__Agentic_Function_Class__c = 'IndustryAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'WhatId', 'Subject' },
        'additionalProperties' => true,
        'properties' => new Map<String, Object>{
            'WhatId' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Care Plan (or related) record Id for Task.WhatId — parent, not the task Id.'
            },
            'Subject' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Task.Subject (required).'
            },
            'Status' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Optional Task.Status (default Not Started).' },
            'Priority' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Optional Task.Priority (default Normal).' },
            'Description' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Optional Task.Description.' },
            'ActivityDate' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Optional Task.ActivityDate (yyyy-MM-dd).' }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'update_care_plan_fields',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Update care plan status or dates in Health Cloud orgs.',
    ccai__Agentic_Function_Class__c = 'IndustryAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce care plan id.' }
        }
        ,'additionalProperties' => true
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
