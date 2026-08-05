// Emit the agent's system prompt as a single base64 line for clean extraction.
ccai__AI_Agent__c agent = [
    SELECT ccai__System_Prompt__c
    FROM ccai__AI_Agent__c
    WHERE Id = 'a0sJ9000001BSF5IAO'
    LIMIT 1
];
String sp = agent.ccai__System_Prompt__c == null ? '' : agent.ccai__System_Prompt__c;
System.debug('ORG_SYSPROMPT_LEN=' + sp.length());
String b64 = EncodingUtil.base64Encode(Blob.valueOf(sp));
// Print in 4000-char chunks so a single debug line never exceeds Salesforce limits
Integer n = b64.length();
Integer chunk = 4000;
Integer parts = (Integer)Math.ceil(((Decimal)n) / chunk);
for (Integer i = 0; i < parts; i++) {
    Integer s = i * chunk;
    Integer e = Math.min(s + chunk, n);
    System.debug('ORG_SYSPROMPT_B64_' + i + '_' + parts + ':' + b64.substring(s, e));
}
