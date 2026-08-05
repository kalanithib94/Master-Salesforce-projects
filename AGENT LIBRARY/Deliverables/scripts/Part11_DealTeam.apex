// Part — DEAL TEAM & PIPELINE (11) — Wave 5
final String AGENTIC = 'Agentic';
final String ACTIVE = 'Active';
final String DATA_MAPPING = 'a04J9000002y7ShIAI';

List<ccai__AI_Prompt__c> prompts = new List<ccai__AI_Prompt__c>();

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_opportunity_contact_roles',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'See who on the buying committee is linked to the deal.',
    ccai__Agentic_Function_Class__c = 'OpportunityAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'OpportunityId' },
        'properties' => new Map<String, Object>{
            'OpportunityId' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Opportunity Id (OpportunityContactRole.OpportunityId). Not the contact-role Id.'
            }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'add_opportunity_contact_role',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Link a contact to the deal with a role such as Decision Maker.',
    ccai__Agentic_Function_Class__c = 'OpportunityAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'OpportunityId', 'ContactId', 'Role' },
        'properties' => new Map<String, Object>{
            'OpportunityId' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Opportunity Id (OpportunityContactRole.OpportunityId).'
            },
            'ContactId' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Contact Id (OpportunityContactRole.ContactId).'
            },
            'Role' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'OCR Role picklist API value (e.g. Decision Maker).'
            },
            'IsPrimary' => new Map<String, Object>{
                'type' => 'boolean',
                'description' => 'Optional. OpportunityContactRole.IsPrimary.'
            }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'update_opportunity_contact_role',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Change role or primary flag for someone on the deal.',
    ccai__Agentic_Function_Class__c = 'OpportunityAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce contact role id.' }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_opportunity_team',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'List internal sellers and specialists on the deal team.',
    ccai__Agentic_Function_Class__c = 'OpportunityAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'OpportunityId' },
        'properties' => new Map<String, Object>{
            'OpportunityId' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Opportunity Id (OpportunityTeamMember.OpportunityId). Not the team-member Id.'
            }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'add_opportunity_team_member',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Add a colleague to the deal with a team role.',
    ccai__Agentic_Function_Class__c = 'OpportunityAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'OpportunityId', 'UserId' },
        'properties' => new Map<String, Object>{
            'OpportunityId' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce opportunity id.' },
            'UserId' => new Map<String, Object>{ 'type' => 'string' },
            'TeamRole' => new Map<String, Object>{ 'type' => 'string' }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_my_open_opportunities',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Pipeline view of the current user\'s open deals.',
    ccai__Agentic_Function_Class__c = 'UtilityAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>(),
        'properties' => new Map<String, Object>{
            'limit' => new Map<String, Object>{ 'type' => 'integer', 'description' => 'Max rows (default 50).' }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_stale_opportunities',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Surface deals with little recent activity that may need attention.',
    ccai__Agentic_Function_Class__c = 'UtilityAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>(),
        'properties' => new Map<String, Object>{
            'daysStale' => new Map<String, Object>{ 'type' => 'integer', 'description' => 'Days since last activity (default 30).' }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'clone_opportunity',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Duplicate a deal to start a related or renewal opportunity faster.',
    ccai__Agentic_Function_Class__c = 'OpportunityAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Opportunity Id to clone (primary Id of the source Opportunity).'
            },
            'Name' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Optional name for the clone (defaults to source Name + Copy).'
            }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_contract_details',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Load contract status, term dates, and account linkage.',
    ccai__Agentic_Function_Class__c = 'ContractAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Contract Id (primary Id of Contract).'
            }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'create_contract',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Create a contract record under the customer account.',
    ccai__Agentic_Function_Class__c = 'ContractAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'AccountId' },
        'additionalProperties' => true,
        'properties' => new Map<String, Object>{
            'AccountId' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Parent Account Id (Contract.AccountId). Required.'
            },
            'Status' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Contract.Status picklist API value.' },
            'StartDate' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Contract.StartDate (yyyy-MM-dd).' },
            'ContractTerm' => new Map<String, Object>{ 'type' => 'integer', 'description' => 'Contract.ContractTerm (months).' },
            'Description' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Contract.Description.' }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'update_contract_fields',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Update contract status, dates, or terms after review.',
    ccai__Agentic_Function_Class__c = 'ContractAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'additionalProperties' => true,
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Contract Id to update (primary Id of Contract).'
            }
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
