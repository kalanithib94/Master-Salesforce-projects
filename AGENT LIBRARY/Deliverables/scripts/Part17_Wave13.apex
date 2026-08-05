// Part 17 — WAVE 13 (3 skills)
final String AGENTIC = 'Agentic';
final String ACTIVE = 'Active';
final String DATA_MAPPING = 'a04J9000002y7ShIAI';

List<ccai__AI_Prompt__c> prompts = new List<ccai__AI_Prompt__c>();

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_upcoming_renewals',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Show renewals closing within the next N days for outreach planning.',
    ccai__Agentic_Function_Class__c = 'UtilityAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>(),
        'properties' => new Map<String, Object>{
            'daysAhead' => new Map<String, Object>{ 'type' => 'integer', 'description' => 'Days ahead to look (default 90).' },
            'AccountId' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Optional Account filter.' },
            'OwnerId' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Optional owner filter.' },
            'limit' => new Map<String, Object>{ 'type' => 'integer', 'description' => 'Max rows (default 50).' }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_account_plan',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Load strategic plan and objectives for the account when the object exists.',
    ccai__Agentic_Function_Class__c = 'AccountAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Account Id (primary Id of Account whose plan to load).'
            }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_contact_engagement_history',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Timeline of recent tasks, meetings, and emails with the contact.',
    ccai__Agentic_Function_Class__c = 'ContactAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Contact Id (primary Id of Contact).'
            },
            'daysBack' => new Map<String, Object>{ 'type' => 'integer', 'description' => 'How far back to look (default 90 days).' },
            'limit' => new Map<String, Object>{ 'type' => 'integer', 'description' => 'Max items (default 50).' }
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
