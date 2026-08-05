// Part 7 — UTILITY SKILLS (4) — v1 + wave 2
final String CLASS_NAME = 'UtilityAgenticSkillsHandler';
final String AGENTIC = 'Agentic';
final String ACTIVE = 'Active';
final String DATA_MAPPING = 'a04J9000002y7ShIAI';

List<ccai__AI_Prompt__c> prompts = new List<ccai__AI_Prompt__c>();

prompts.add(new ccai__AI_Prompt__c(
    Name = 'run_internal_prompt',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Generate a 360, summary, meeting prep, or draft from record data.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'promptRequestId' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'The pre-configured GPTfy Prompt Request Id to invoke. Example: "96a10206d7990a5fabc728ddfd83be0fbd5a9". Must exist in the org configuration — never make this up.'
            },
            'Id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'ONLY the Salesforce Id of the record the prompt should run against (e.g. an Opportunity Id for a Deal Overview prompt).'
            }
        },
        'required' => new List<String>{ 'promptRequestId', 'Id' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_picklist_values',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'List valid choices for a field before setting a picklist value.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'objectApiName' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'API name of the object the field lives on. Examples: "Account", "Opportunity", "Custom_Object__c".'
            },
            'fieldApiName' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'API name of the picklist or multi-picklist field. Examples: "Industry", "StageName", "Type__c".'
            },
            'controllerValue' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Required ONLY for dependent picklists. The exact API value of the controlling field that the record will have AFTER the update. The skill returns only the dependent values valid for this controller value.'
            }
        },
        'required' => new List<String>{ 'objectApiName', 'fieldApiName' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_session_context',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'See which record and related people the chat is on, so the agent can act without asking for Ids. Use before updates, summaries, logging activity, or drafting follow-ups.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Optional. Salesforce Id of the page-context or related record (15 or 18 characters). Pass when you have a confirmed record Id from the record page. If omitted, the skill resolves from the session record or userContextId when applicable.'
            }
        },
        'required' => new List<String>()
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'transfer_record_owner',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Reassign ownership of a record to another user.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Salesforce Id of the record to reassign.'
            },
            'OwnerId' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'User Id (005…) or Queue Id (00G…) for the new owner.'
            }
        },
        'required' => new List<String>{ 'Id', 'OwnerId' }
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
