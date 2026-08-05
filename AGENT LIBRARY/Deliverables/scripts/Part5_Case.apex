// Part 5 — CASE SKILLS (6) — v1 + wave 2
final String CLASS_NAME = 'CaseAgenticSkillsHandler';
final String AGENTIC = 'Agentic';
final String ACTIVE = 'Active';
final String DATA_MAPPING = 'a04J9000002y7ShIAI';

List<ccai__AI_Prompt__c> prompts = new List<ccai__AI_Prompt__c>();

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fuzzy_search_cases',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Find a ticket by subject or case number from chat.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'searchTerm' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Case Subject partial text or CaseNumber (e.g. 00001234).'
            }
        },
        'required' => new List<String>{ 'searchTerm' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_case_details',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Load case status, priority, and customer context for support work.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'CaseNumber' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Prefer this. Case Number as users say it (e.g. "00001026").'
            },
            'Subject' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Prefer if CaseNumber unknown. Case Subject text (e.g. "Billing issue").'
            },
            'Id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Optional. Salesforce Case Id only when already known from a prior skill.'
            }
        },
        'required' => new List<String>{ }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'create_case',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Open a support ticket linked to the right account or contact.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'Subject' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Required case subject as the user states it.'
            },
            'AccountName' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Prefer this. Parent Account Name (not Salesforce Id).'
            },
            'ContactName' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Prefer this. Parent Contact full name or email (not Salesforce Id).'
            },
            'AccountId' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Optional. Account Name or Salesforce Id if already known.'
            },
            'ContactId' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Optional. Contact Name/Email or Salesforce Id if already known.'
            },
            'fields' => new Map<String, Object>{
                'type' => 'object',
                'description' => 'Optional map of Case field API names. Prefer top-level AccountName/ContactName over raw Ids.',
                'additionalProperties' => true
            }
        },
        'required' => new List<String>{ 'Subject' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'update_case_fields',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Change status, priority, owner, or other case fields mid-work.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'CaseNumber' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Prefer this. Case Number as users say it.'
            },
            'Subject' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Prefer if CaseNumber unknown. Case Subject text.'
            },
            'Id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Optional. Salesforce Case Id only when already known.'
            },
            'fields' => new Map<String, Object>{
                'type' => 'object',
                'description' => 'Map of Case field API names to NEW values. Only the fields the user wants to change.',
                'additionalProperties' => true
            }
        },
        'required' => new List<String>{ 'fields' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'close_case',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Resolve and close a ticket after the customer issue is handled.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'CaseNumber' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Prefer this. Case Number to close.'
            },
            'Subject' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Prefer if CaseNumber unknown.'
            },
            'Id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Optional. Salesforce Case Id only when already known.'
            },
            'Status' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Optional. Case.Status picklist closed value (default Closed). Use org closed values such as Closed, Resolved.'
            },
            'Reason' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Optional. Case.Reason picklist API value at closure (e.g. User error, Other).'
            },
            'Comments' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Optional. Public CaseComment.CommentBody to post at closure.'
            }
        },
        'required' => new List<String>{ }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'add_case_comment',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Post an internal or public update on the case thread.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'ParentId' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Case Id to comment on (CaseComment.ParentId). Not the CaseComment Id.'
            },
            'CommentBody' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Text of the public case comment — must be confirmed with the user.'
            },
            'IsPublished' => new Map<String, Object>{
                'type' => 'boolean',
                'description' => 'Optional. Defaults true (visible to customer portal when applicable).'
            }
        },
        'required' => new List<String>{ 'ParentId', 'CommentBody' }
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
