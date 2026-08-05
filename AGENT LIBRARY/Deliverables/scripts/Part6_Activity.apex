// Part 6 — ACTIVITY SKILLS (7) — v1
final String CLASS_NAME = 'ActivityAgenticSkillsHandler';
final String AGENTIC = 'Agentic';
final String ACTIVE = 'Active';
final String DATA_MAPPING = 'a04J9000002y7ShIAI';

List<ccai__AI_Prompt__c> prompts = new List<ccai__AI_Prompt__c>();

prompts.add(new ccai__AI_Prompt__c(
    Name = 'log_activity',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Record a completed call, email, or note against any CRM record.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Subject' },
        'properties' => new Map<String, Object>{
            'WhatId' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Related record for Task.WhatId (Account, Opportunity, Case, etc.). Use WhatId OR WhoId.'
            },
            'WhoId' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Person for Task.WhoId (Contact or Lead). Use WhoId OR WhatId.'
            },
            'Subject' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Task.Subject for the completed activity — must be confirmed with the user.'
            },
            'Description' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Optional Task.Description notes/summary.'
            }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'create_task',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Schedule a follow-up to-do with due date and owner.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'fields' => new Map<String, Object>{
                'type' => 'object',
                'description' => 'Map of Task field API names to values. MUST include "Subject". Set "WhatId" to the Account/Opportunity/Case Id OR "WhoId" to the Contact/Lead Id. May also include Description, Status, Priority, ActivityDate (yyyy-MM-dd), OwnerId and custom fields.',
                'additionalProperties' => true
            }
        },
        'required' => new List<String>{ 'fields' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'update_task',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Reschedule, reassign, or edit an existing to-do.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce Task Id.' },
            'Subject' => new Map<String, Object>{ 'type' => 'string' },
            'Status' => new Map<String, Object>{ 'type' => 'string' },
            'Priority' => new Map<String, Object>{ 'type' => 'string' },
            'ActivityDate' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Due date yyyy-MM-dd.' },
            'Description' => new Map<String, Object>{ 'type' => 'string' }
        },
        'additionalProperties' => true
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'create_event',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Book a meeting on the calendar linked to a person or record.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'fields' => new Map<String, Object>{
                'type' => 'object',
                'description' => 'Map of Event field API names to values. MUST include "Subject" AND "StartDateTime" (ISO 8601, e.g. "2026-05-31T14:30:00Z"). Provide EITHER "EndDateTime" OR "DurationInMinutes". May also include "Description", "Location", "WhatId" (record like Account/Opportunity), "WhoId" (Contact/Lead), "IsAllDayEvent" and custom fields.',
                'additionalProperties' => true
            }
        },
        'required' => new List<String>{ 'fields' }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'update_event',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Reschedule or edit meeting time, location, or notes.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce Event Id.' },
            'Subject' => new Map<String, Object>{ 'type' => 'string' },
            'StartDateTime' => new Map<String, Object>{ 'type' => 'string' },
            'EndDateTime' => new Map<String, Object>{ 'type' => 'string' },
            'Location' => new Map<String, Object>{ 'type' => 'string' },
            'Description' => new Map<String, Object>{ 'type' => 'string' }
        },
        'additionalProperties' => true
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_my_open_tasks',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Show the current user\'s incomplete to-dos for the day or week.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'limit' => new Map<String, Object>{
                'type' => 'integer',
                'description' => 'Optional. Maximum number of tasks to return (1-200). Defaults to 25.'
            }
        },
        'required' => new List<String>()
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'complete_task',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Mark a follow-up done after the work is finished.',
    ccai__Agentic_Function_Class__c = CLASS_NAME,
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'ONLY the Salesforce Id of the Task to mark Completed.'
            }
        },
        'required' => new List<String>{ 'Id' }
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
