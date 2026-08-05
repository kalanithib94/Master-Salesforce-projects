// Part — SERVICE CLOUD (9) — Wave 6
final String AGENTIC = 'Agentic';
final String ACTIVE = 'Active';
final String DATA_MAPPING = 'a04J9000002y7ShIAI';

List<ccai__AI_Prompt__c> prompts = new List<ccai__AI_Prompt__c>();

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_case_team',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'See who is collaborating on the support case.',
    ccai__Agentic_Function_Class__c = 'CaseAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'CaseId' },
        'properties' => new Map<String, Object>{
            'CaseId' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce case id.' }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'add_case_team_member',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Bring another agent or specialist onto the case team.',
    ccai__Agentic_Function_Class__c = 'CaseAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'CaseId', 'UserId' },
        'properties' => new Map<String, Object>{
            'CaseId' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce case id.' },
            'UserId' => new Map<String, Object>{ 'type' => 'string' },
            'TeamRole' => new Map<String, Object>{ 'type' => 'string' }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'search_knowledge_articles',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Find KB articles that may answer the customer\'s question.',
    ccai__Agentic_Function_Class__c = 'UtilityAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'searchTerm' },
        'properties' => new Map<String, Object>{
            'searchTerm' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Keywords to search Knowledge.' }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_knowledge_article',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Open the full article body for use in a reply.',
    ccai__Agentic_Function_Class__c = 'UtilityAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'KnowledgeArticleVersion Id or KnowledgeArticleId (primary article identity).'
            }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'link_knowledge_article_to_case',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Attach a helpful article to the case for audit and deflection.',
    ccai__Agentic_Function_Class__c = 'CaseAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'CaseId', 'KnowledgeArticleId' },
        'properties' => new Map<String, Object>{
            'CaseId' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce case id.' },
            'KnowledgeArticleId' => new Map<String, Object>{ 'type' => 'string' }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_case_milestones',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Check SLA milestone progress and breach risk on the case.',
    ccai__Agentic_Function_Class__c = 'ServiceAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'CaseId' },
        'properties' => new Map<String, Object>{
            'CaseId' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce case id.' }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_case_entitlements',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'See support coverage and entitlement levels for the customer.',
    ccai__Agentic_Function_Class__c = 'ServiceAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'CaseId' },
        'properties' => new Map<String, Object>{
            'CaseId' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce case id.' }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'assign_to_queue',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Route a record into a work queue for the next available agent.',
    ccai__Agentic_Function_Class__c = 'UtilityAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id', 'OwnerId' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce record id.' },
            'OwnerId' => new Map<String, Object>{ 'type' => 'string' }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_queue_cases',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'List cases waiting in a specific support queue.',
    ccai__Agentic_Function_Class__c = 'UtilityAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'OwnerId' },
        'properties' => new Map<String, Object>{
            'OwnerId' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce queue id.' },
            'limit' => new Map<String, Object>{ 'type' => 'integer' }
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
