// Updates Agent 1 system prompt + fetch_session_context skill description for dual-ID responses.
final String AGENT_ID = 'a0sJ9000001BWalIAG';

String sessionSkillBlock =
    '<h3>Session Context (fetch_session_context skill)</h3>' +
    '<p>When the user asks about <b>session context</b>, <b>user context id</b>, <b>chat context</b>, ' +
    '<b>record context</b>, or <b>what record they are on</b>, you MUST call the ' +
    '<code>fetch_session_context</code> skill immediately. Do NOT answer from memory or page context alone.</p>' +
    '<ul>' +
    '<li>When on a record page, pass the page-context record Id as <code>record_id</code>.</li>' +
    '<li>After the skill returns, always show BOTH values to the user in plain language:</li>' +
    '<ul><li><b>User Context Id</b> (conversation/session id, e.g. A-14718)</li>' +
    '<li><b>Record Id</b> (Salesforce page-context record id)</li></ul>' +
    '<li>Also mention WhoId or WhatId when the skill returns them.</li>' +
    '</ul>';

ccai__AI_Agent__c agent = [
    SELECT Id, ccai__System_Prompt__c
    FROM ccai__AI_Agent__c
    WHERE Id = :AGENT_ID
    LIMIT 1
];

String sp = agent.ccai__System_Prompt__c == null ? '' : agent.ccai__System_Prompt__c;
if (!sp.contains('fetch_session_context')) {
    agent.ccai__System_Prompt__c = sp + sessionSkillBlock;
    update agent;
    System.debug('Updated Agent 1 system prompt');
} else {
    System.debug('Agent 1 system prompt already contains fetch_session_context guidance');
}

ccai__AI_Prompt__c prompt = [
    SELECT Id, ccai__Description__c
    FROM ccai__AI_Prompt__c
    WHERE Name = 'fetch_session_context'
    LIMIT 1
];

prompt.ccai__Description__c =
    'MUST call when user asks for session context, user context id, chat context, or record context. ' +
    'Returns userContextId (conversation id like A-14718) AND recordId (page record). ' +
    'Always pass record_id from page context when on a record page.';
update prompt;
System.debug('Updated fetch_session_context description: ' + prompt.Id);
