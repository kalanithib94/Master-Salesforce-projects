// Creates fetch_session_context prompt and links it to Agent 1 (a0sJ9000001BWalIAG).
final String AGENT_ID = 'a0sJ9000001BWalIAG';
final String CLASS_NAME = 'GenericAgenticSkillsHandler';
final String DATA_MAPPING = 'a04J9000002y7ShIAI';

List<ccai__AI_Prompt__c> existing = [
    SELECT Id, Name
    FROM ccai__AI_Prompt__c
    WHERE Name = 'fetch_session_context'
    LIMIT 1
];

ccai__AI_Prompt__c prompt;
if (existing.isEmpty()) {
    prompt = new ccai__AI_Prompt__c(
        Name = 'fetch_session_context',
        ccai__Type__c = 'Agentic',
        ccai__Status__c = 'Active',
        ccai__Agentic_Function_Class__c = CLASS_NAME,
        ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
        ccai__Description__c = 'Returns userContextId and the related record Id as WhoId (Contact/Lead) or WhatId (Account/Opportunity/Case/other). Call when you need the session thread Id or Task/Event relation field. userContextId is injected by the runtime.',
        ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
            'type' => 'object',
            'properties' => new Map<String, Object>{
                'record_id' => new Map<String, Object>{
                    'type' => 'string',
                    'description' => 'Optional. Salesforce Id of the page-context or related record (15 or 18 characters). Pass when you have a confirmed record Id from the record page. If omitted, the skill resolves from the session record or userContextId when applicable.'
                }
            },
            'required' => new List<String>()
        })
    );
    insert prompt;
    System.debug('Created prompt: ' + prompt.Id);
} else {
    prompt = existing[0];
    System.debug('Prompt already exists: ' + prompt.Id);
}

List<ccai__AI_Agent_Skill__c> links = [
    SELECT Id
    FROM ccai__AI_Agent_Skill__c
    WHERE ccai__AI_Agent__c = :AGENT_ID
      AND ccai__AI_Prompt__c = :prompt.Id
    LIMIT 1
];

if (links.isEmpty()) {
    ccai__AI_Agent_Skill__c skill = new ccai__AI_Agent_Skill__c(
        ccai__AI_Agent__c = AGENT_ID,
        ccai__AI_Prompt__c = prompt.Id
    );
    insert skill;
    System.debug('Linked skill to Agent 1: ' + skill.Id);
} else {
    System.debug('Skill already linked: ' + links[0].Id);
}
