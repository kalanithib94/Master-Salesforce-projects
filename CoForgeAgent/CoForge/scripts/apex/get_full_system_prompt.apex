// Get and display the complete system prompt
ccai__AI_Agent__c agent = [
    SELECT Id, Name, CCAI__SYSTEM_PROMPT__C 
    FROM ccai__AI_Agent__c 
    WHERE Id = 'a0sJ9000000TnoCIAS' 
    LIMIT 1
];

System.debug('=== COMPLETE SYSTEM PROMPT ===');
System.debug(agent.CCAI__SYSTEM_PROMPT__C);
System.debug('=== END SYSTEM PROMPT ===');

