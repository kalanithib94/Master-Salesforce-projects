// One-shot sync: ccai__AI_Prompt__c "fetch_account_details" Prompt_Command__c + Description__c
// Mirrors CreateAgenticPrompts.apex (Jira V2-8418). Run: sf apex run --file scripts/SyncFetchAccountPromptToOrg.apex

List<ccai__AI_Prompt__c> rows = [
    SELECT Id, Name FROM ccai__AI_Prompt__c WHERE Name = 'fetch_account_details' LIMIT 1
];
if (rows.isEmpty()) {
    System.debug('SYNC_FETCH_ACCOUNT_PROMPT_ERROR=no_prompt_row');
} else {
    ccai__AI_Prompt__c p = rows[0];
    // ccai__Description__c is max 255 chars in org — keep concise; long guidance is in the system prompt + Prompt_Command descriptions.
    p.ccai__Description__c =
        'Account detail JSON: pass account_id (preferred on 001 page) OR account_name. Name fuzzy: 1 match = full row; 2-5 = AMBIGUOUS_ACCOUNT_NAME + picker rows; 6+ = TOO_MANY_ACCOUNT_MATCHES. No Rating. Never pass an Id as account_name.';
    p.ccai__Prompt_Command__c = JSON.serializePretty(
        new Map<String, Object>{
            'type' => 'object',
            'properties' => new Map<String, Object>{
                'account_id' => new Map<String, Object>{
                    'type' => 'string',
                    'description' => 'Salesforce Account Id (15 or 18 characters). Use when you have a confirmed Id (record page, prior turn, or user pasted Id). Preferred over account_name when both could apply.'
                },
                'account_name' => new Map<String, Object>{
                    'type' => 'string',
                    'description' => 'Account Name as the user stated it. Use when you have no Account Id. The skill fuzzy-matches on Name; see Description for single vs multi-match behaviour.'
                }
            },
            'anyOf' => new List<Object>{
                new Map<String, Object>{ 'required' => new List<String>{ 'account_id' } },
                new Map<String, Object>{ 'required' => new List<String>{ 'account_name' } }
            }
        }
    );
    update p;
    System.debug('SYNC_FETCH_ACCOUNT_PROMPT_OK=' + p.Id);
}
