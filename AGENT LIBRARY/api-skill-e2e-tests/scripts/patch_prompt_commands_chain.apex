/**
 * Patch Prompt Command (schema JSON only) for natural-key create chain.
 * Does NOT touch ccai__AI_Data_Extraction_Mapping__c.
 * Target agent: GPTfy Master Agent prompts by Name.
 */
Map<String, String> commands = new Map<String, String>();

commands.put('create_contact', JSON.serializePretty(new Map<String, Object>{
    'type' => 'object',
    'required' => new List<String>(),
    'additionalProperties' => true,
    'properties' => new Map<String, Object>{
        'LastName' => new Map<String, Object>{ 'type' => 'string', 'description' => 'REQUIRED. Contact LastName.' },
        'FirstName' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Contact FirstName.' },
        'Email' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Contact Email.' },
        'Phone' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Contact Phone.' },
        'AccountId' => new Map<String, Object>{
            'type' => 'string',
            'description' => 'Parent Account Id OR Account Name. Prefer AccountName — users rarely know Ids.'
        },
        'AccountName' => new Map<String, Object>{
            'type' => 'string',
            'description' => 'Preferred. Parent Account Name resolved to AccountId.'
        },
        'accountName' => new Map<String, Object>{
            'type' => 'string',
            'description' => 'Alias of AccountName.'
        }
    }
}));

commands.put('create_opportunity', JSON.serializePretty(new Map<String, Object>{
    'type' => 'object',
    'required' => new List<String>(),
    'additionalProperties' => true,
    'properties' => new Map<String, Object>{
        'Name' => new Map<String, Object>{ 'type' => 'string', 'description' => 'REQUIRED. Opportunity name.' },
        'StageName' => new Map<String, Object>{ 'type' => 'string', 'description' => 'REQUIRED. Stage.' },
        'CloseDate' => new Map<String, Object>{ 'type' => 'string', 'description' => 'REQUIRED. yyyy-MM-dd.' },
        'AccountName' => new Map<String, Object>{
            'type' => 'string',
            'description' => 'Preferred. Parent Account Name (natural key).'
        },
        'AccountId' => new Map<String, Object>{
            'type' => 'string',
            'description' => 'Parent Account Id or Name — prefer AccountName.'
        },
        'Description' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Optional Description.' },
        'fields' => new Map<String, Object>{
            'type' => 'object',
            'description' => 'Legacy nested fields map. Prefer flat params.',
            'additionalProperties' => true
        }
    }
}));

commands.put('create_case', JSON.serializePretty(new Map<String, Object>{
    'type' => 'object',
    'required' => new List<String>(),
    'additionalProperties' => true,
    'properties' => new Map<String, Object>{
        'Subject' => new Map<String, Object>{ 'type' => 'string', 'description' => 'REQUIRED. Case Subject.' },
        'Status' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Case Status (e.g. New).' },
        'Origin' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Case Origin (e.g. Web).' },
        'AccountName' => new Map<String, Object>{
            'type' => 'string',
            'description' => 'Preferred. Account Name — resolved to AccountId.'
        },
        'ContactName' => new Map<String, Object>{
            'type' => 'string',
            'description' => 'Preferred. Contact Name — resolved to ContactId.'
        },
        'AccountId' => new Map<String, Object>{
            'type' => 'string',
            'description' => 'Account Id or Name. Prefer AccountName.'
        },
        'ContactId' => new Map<String, Object>{
            'type' => 'string',
            'description' => 'Contact Id or Name. Prefer ContactName.'
        },
        'Description' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Case Description.' },
        'fields' => new Map<String, Object>{
            'type' => 'object',
            'description' => 'Legacy nested fields. Prefer flat Subject/AccountName/ContactName.',
            'additionalProperties' => true
        }
    }
}));

commands.put('create_account', JSON.serializePretty(new Map<String, Object>{
    'type' => 'object',
    'required' => new List<String>(),
    'additionalProperties' => true,
    'properties' => new Map<String, Object>{
        'Name' => new Map<String, Object>{ 'type' => 'string', 'description' => 'REQUIRED. Account Name (natural key for later skills).' },
        'Industry' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Optional Industry.' },
        'Phone' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Optional Phone.' },
        'Website' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Optional Website.' },
        'Description' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Optional Description.' },
        'fields' => new Map<String, Object>{
            'type' => 'object',
            'description' => 'Legacy nested fields map.',
            'additionalProperties' => true
        }
    }
}));

commands.put('create_campaign', JSON.serializePretty(new Map<String, Object>{
    'type' => 'object',
    'required' => new List<String>(),
    'additionalProperties' => true,
    'properties' => new Map<String, Object>{
        'Name' => new Map<String, Object>{ 'type' => 'string', 'description' => 'REQUIRED. Campaign Name (natural key).' },
        'Status' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Campaign Status.' },
        'IsActive' => new Map<String, Object>{ 'type' => 'boolean', 'description' => 'Whether campaign is active.' },
        'Description' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Optional Description.' }
    }
}));

commands.put('create_lead', JSON.serializePretty(new Map<String, Object>{
    'type' => 'object',
    'required' => new List<String>(),
    'additionalProperties' => true,
    'properties' => new Map<String, Object>{
        'LastName' => new Map<String, Object>{ 'type' => 'string', 'description' => 'REQUIRED. Lead LastName.' },
        'Company' => new Map<String, Object>{ 'type' => 'string', 'description' => 'REQUIRED. Lead Company.' },
        'FirstName' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Lead FirstName.' },
        'Email' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Lead Email.' },
        'Status' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Lead Status.' },
        'Description' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Lead Description.' }
    }
}));

Integer updated = 0;
for (ccai__AI_Prompt__c p : [
    SELECT Id, Name, ccai__Prompt_Command__c
    FROM ccai__AI_Prompt__c
    WHERE Name IN :commands.keySet() AND ccai__Type__c = 'Agentic'
]) {
    p.ccai__Prompt_Command__c = commands.get(p.Name);
    // Do not set Data Extraction Mapping
    update p;
    updated++;
    System.debug('Updated PromptCommand ' + p.Name);
}
System.debug('PROMPT_PATCH_DONE=' + updated);
