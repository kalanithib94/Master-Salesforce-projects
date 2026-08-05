// Part — CAMPAIGN SKILLS (7) — Wave 3
final String CLASS_NAME = 'CampaignAgenticSkillsHandler';
final String AGENTIC = 'Agentic';
final String ACTIVE = 'Active';
final String DATA_MAPPING = 'a04J9000002y7ShIAI';

List<ccai__AI_Prompt__c> prompts = new List<ccai__AI_Prompt__c>();

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fuzzy_search_campaigns',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Find a marketing campaign by name for member or status work.',
    ccai__Agentic_Function_Class__c = 'CampaignAgenticSkillsHandler',
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
    Name = 'fetch_campaign_details',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Load campaign dates, type, status, and response counts.',
    ccai__Agentic_Function_Class__c = 'CampaignAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Campaign Id (primary Id of Campaign, prefix 701…).'
            }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'create_campaign',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Set up a new marketing campaign with name and schedule.',
    ccai__Agentic_Function_Class__c = 'CampaignAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Name' },
        'additionalProperties' => true,
        'properties' => new Map<String, Object>{
            'Name' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'REQUIRED. Campaign Name (org field).'
            },
            'Status' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Campaign Status picklist API value.' },
            'Type' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Campaign Type picklist API value.' },
            'StartDate' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Campaign StartDate (yyyy-MM-dd).' },
            'EndDate' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Campaign EndDate (yyyy-MM-dd).' }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'update_campaign_fields',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Change campaign status, dates, or type after launch planning.',
    ccai__Agentic_Function_Class__c = 'CampaignAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'additionalProperties' => true,
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Campaign Id to update (primary Id of Campaign).'
            }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_campaign_members',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'List who is already on the campaign and their status.',
    ccai__Agentic_Function_Class__c = 'CampaignAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'CampaignId' },
        'properties' => new Map<String, Object>{
            'CampaignId' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Campaign Id (CampaignMember.CampaignId relationship). Not the CampaignMember Id.'
            }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'add_campaign_member',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Enroll a lead or contact into the campaign.',
    ccai__Agentic_Function_Class__c = 'CampaignAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'CampaignId' },
        'properties' => new Map<String, Object>{
            'CampaignId' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Parent Campaign Id (CampaignMember.CampaignId). Create a CampaignMember under this campaign — do NOT pass CampaignMember Id.'
            },
            'ContactId' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Contact to enroll (CampaignMember.ContactId). Use ContactId OR LeadId, not both.'
            },
            'LeadId' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Lead to enroll (CampaignMember.LeadId). Use LeadId OR ContactId, not both.'
            },
            'Status' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Optional CampaignMember.Status picklist API value (e.g. Sent, Responded).'
            }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'update_campaign_member_status',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Mark someone as Sent, Responded, or another member status.',
    ccai__Agentic_Function_Class__c = 'CampaignAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id', 'Status' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'CampaignMember Id (primary Id of the member row being updated).'
            },
            'Status' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'New CampaignMember.Status picklist API value.'
            }
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
