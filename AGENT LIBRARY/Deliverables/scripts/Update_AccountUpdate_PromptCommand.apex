// Jira V2-8418 — Update update_account_fields prompt command to Option C (flat top-level field keys)
ccai__AI_Prompt__c prompt = [
    SELECT Id, ccai__Prompt_Command__c
    FROM ccai__AI_Prompt__c
    WHERE Name = 'update_account_fields'
    LIMIT 1
];

prompt.ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
    'type' => 'object',
    'required' => new List<String>{ 'account_id' },
    'properties' => new Map<String, Object>{
        'account_id' => new Map<String, Object>{
            'type' => 'string',
            'description' => 'ONLY the Salesforce Id of the Account to update.'
        },
        'Name' => new Map<String, Object>{
            'type' => 'string',
            'description' => 'Account Name.'
        },
        'Industry' => new Map<String, Object>{
            'type' => 'string',
            'description' => 'Industry picklist API value (call fetch_picklist_values first if unsure).'
        },
        'Type' => new Map<String, Object>{
            'type' => 'string',
            'description' => 'Type picklist API value (call fetch_picklist_values first if unsure).'
        },
        'AnnualRevenue' => new Map<String, Object>{
            'type' => 'number',
            'description' => 'Annual revenue as a plain number, no currency symbol or commas.'
        },
        'Phone' => new Map<String, Object>{
            'type' => 'string',
            'description' => 'Account phone number.'
        },
        'Website' => new Map<String, Object>{
            'type' => 'string',
            'description' => 'Account website URL.'
        },
        'Description' => new Map<String, Object>{
            'type' => 'string',
            'description' => 'Long-text description of the Account.'
        }
    },
    'additionalProperties' => true
});

update prompt;
System.debug('Updated prompt Id: ' + prompt.Id);
System.debug('New Prompt_Command__c:\n' + prompt.ccai__Prompt_Command__c);