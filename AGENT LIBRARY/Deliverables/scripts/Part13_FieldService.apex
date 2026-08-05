// Part — ASSET & FIELD SERVICE (10) — Wave 7
final String AGENTIC = 'Agentic';
final String ACTIVE = 'Active';
final String DATA_MAPPING = 'a04J9000002y7ShIAI';

List<ccai__AI_Prompt__c> prompts = new List<ccai__AI_Prompt__c>();

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fuzzy_search_assets',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Find installed equipment by name or serial number.',
    ccai__Agentic_Function_Class__c = 'ServiceAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'searchTerm' },
        'properties' => new Map<String, Object>{
            'searchTerm' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Partial name or keyword to search.' }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_asset_details',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Load asset status, account, and product information.',
    ccai__Agentic_Function_Class__c = 'ServiceAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce asset id.' }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'update_asset_fields',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Update asset status, location, or warranty-related fields.',
    ccai__Agentic_Function_Class__c = 'ServiceAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce asset id.' }
        }
        ,'additionalProperties' => true
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_work_order_details',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Load field service work order status and related customer data.',
    ccai__Agentic_Function_Class__c = 'FieldServiceAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce work order id.' }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'create_work_order',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Open a work order for on-site or remote service.',
    ccai__Agentic_Function_Class__c = 'FieldServiceAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>(),
        'properties' => new Map<String, Object>{
            'AccountId' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce account id.' },
            'Name' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Record name (required for most objects).' }
        }
        ,'additionalProperties' => true
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'update_work_order_fields',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Change work order status, priority, or schedule fields.',
    ccai__Agentic_Function_Class__c = 'FieldServiceAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce work order id.' }
        }
        ,'additionalProperties' => true
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_service_appointment',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Load appointment time window and assigned resource.',
    ccai__Agentic_Function_Class__c = 'FieldServiceAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce record id.' }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'schedule_service_appointment',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Set or change when a technician visit is booked.',
    ccai__Agentic_Function_Class__c = 'FieldServiceAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce service appointment id.' },
            'StartDateTime' => new Map<String, Object>{ 'type' => 'string' },
            'EndDateTime' => new Map<String, Object>{ 'type' => 'string' }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'update_service_appointment',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Edit appointment status, time, or assignment details.',
    ccai__Agentic_Function_Class__c = 'FieldServiceAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce service appointment id.' }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_service_resource_availability',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Check when a technician or resource is free to schedule.',
    ccai__Agentic_Function_Class__c = 'FieldServiceAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'ServiceResource Id (primary Id of the resource whose availability to check).'
            },
            'StartDate' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Optional window start (yyyy-MM-dd).' },
            'EndDate' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Optional window end (yyyy-MM-dd).' }
        }
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
