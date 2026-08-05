// =============================================================================
// seed.apex — single skill: link_knowledge_article_to_case
// Creates/reuses agent "GPTfy Agent", inserts this prompt, links it.
// BEFORE RUNNING: set DATA_MAPPING and AI_MODEL for THIS org.
// =============================================================================

final String AGENT_NAME = 'GPTfy Agent';
final String AGENTIC = 'Agentic';
final String ACTIVE = 'Active';
// TODO: replace with THIS org's Ids
final String DATA_MAPPING = 'REPLACE_WITH_DATA_EXTRACTION_MAPPING_ID';
final String AI_MODEL = 'REPLACE_WITH_AI_CONNECTION_ID';

if (DATA_MAPPING == null || DATA_MAPPING.startsWith('REPLACE_')
    || AI_MODEL == null || AI_MODEL.startsWith('REPLACE_')) {
    System.debug(LoggingLevel.ERROR,
        'Stop: set DATA_MAPPING and AI_MODEL to valid org Ids before running.');
} else {

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
    System.debug('Created agent: ' + agent.Id);
} else {
    agent = agents[0];
    Boolean dirty = false;
    if (agent.ccai__Status__c != ACTIVE) { agent.ccai__Status__c = ACTIVE; dirty = true; }
    if (agent.ccai__AI_Model__c == null) { agent.ccai__AI_Model__c = AI_MODEL; dirty = true; }
    if (dirty) update agent;
    System.debug('Using existing agent: ' + agent.Id);
}

List<ccai__AI_Prompt__c> prompts = new List<ccai__AI_Prompt__c>();

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

Set<String> proposedNames = new Set<String>();
for (ccai__AI_Prompt__c p : prompts) proposedNames.add(p.Name);

Map<String, Id> existingByName = new Map<String, Id>();
for (ccai__AI_Prompt__c p : [
    SELECT Id, Name FROM ccai__AI_Prompt__c WHERE Name IN :proposedNames
]) {
    existingByName.put(p.Name, p.Id);
}

List<ccai__AI_Prompt__c> toInsert = new List<ccai__AI_Prompt__c>();
List<ccai__AI_Prompt__c> toUpdate = new List<ccai__AI_Prompt__c>();
for (ccai__AI_Prompt__c p : prompts) {
    if (!existingByName.containsKey(p.Name)) {
        toInsert.add(p);
    } else {
        // Refresh schema + class so reinstall picks up Prompt Command fixes
        p.Id = existingByName.get(p.Name);
        toUpdate.add(p);
    }
}
if (!toInsert.isEmpty()) insert toInsert;
if (!toUpdate.isEmpty()) update toUpdate;
for (ccai__AI_Prompt__c p : toInsert) existingByName.put(p.Name, p.Id);
for (ccai__AI_Prompt__c p : [
    SELECT Id, Name FROM ccai__AI_Prompt__c WHERE Name IN :proposedNames
]) {
    existingByName.put(p.Name, p.Id);
}

Set<Id> promptIds = new Set<Id>(existingByName.values());
Set<Id> alreadyLinked = new Set<Id>();
for (ccai__AI_Agent_Skill__c link : [
    SELECT ccai__AI_Prompt__c FROM ccai__AI_Agent_Skill__c
    WHERE ccai__AI_Agent__c = :agent.Id AND ccai__AI_Prompt__c IN :promptIds
]) {
    alreadyLinked.add(link.ccai__AI_Prompt__c);
}

List<ccai__AI_Agent_Skill__c> newLinks = new List<ccai__AI_Agent_Skill__c>();
for (String skillName : proposedNames) {
    Id pid = existingByName.get(skillName);
    if (pid == null || alreadyLinked.contains(pid)) continue;
    newLinks.add(new ccai__AI_Agent_Skill__c(
        ccai__AI_Agent__c = agent.Id,
        ccai__AI_Prompt__c = pid
    ));
}
if (!newLinks.isEmpty()) insert newLinks;
System.debug('Done. Skill=link_knowledge_article_to_case Agent=' + agent.Id
    + ' PromptId=' + existingByName.get('link_knowledge_article_to_case')
    + ' NewLinks=' + newLinks.size());
}
