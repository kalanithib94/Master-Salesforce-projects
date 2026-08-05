// Part — ORDERS & SUBSCRIPTIONS (7) — Wave 9
final String CLASS_NAME = 'OrderAgenticSkillsHandler';
final String AGENTIC = 'Agentic';
final String ACTIVE = 'Active';
final String DATA_MAPPING = 'a04J9000002y7ShIAI';

List<ccai__AI_Prompt__c> prompts = new List<ccai__AI_Prompt__c>();

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_order_details',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Load order status, account, and totals after win or fulfillment.',
    ccai__Agentic_Function_Class__c = 'OrderAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce order id.' }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'create_order',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Create an order from account or opportunity context.',
    ccai__Agentic_Function_Class__c = 'OrderAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'AccountId', 'Status', 'EffectiveDate' },
        'additionalProperties' => true,
        'properties' => new Map<String, Object>{
            'AccountId' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Parent Account Id (Order.AccountId).'
            },
            'Status' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Order.Status picklist API value (e.g. Draft).'
            },
            'EffectiveDate' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Order.EffectiveDate (yyyy-MM-dd).'
            },
            'OpportunityId' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Optional Order.OpportunityId.'
            },
            'Pricebook2Id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Optional Order.Pricebook2Id.'
            }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'update_order_fields',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Update order status or header fields during fulfillment.',
    ccai__Agentic_Function_Class__c = 'OrderAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce order id.' }
        }
        ,'additionalProperties' => true
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'add_order_item',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Add a product line to the order.',
    ccai__Agentic_Function_Class__c = 'OrderAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'OrderId' },
        'properties' => new Map<String, Object>{
            'OrderId' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Parent Order Id (OrderItem.OrderId). Not the OrderItem Id.'
            }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'update_order_item',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Adjust quantity or price on an order line.',
    ccai__Agentic_Function_Class__c = 'OrderAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce order item id.' }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_subscription_details',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Load subscription term, quantity, and billing status.',
    ccai__Agentic_Function_Class__c = 'OrderAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce subscription id.' }
        }
    })
));

prompts.add(new ccai__AI_Prompt__c(
    Name = 'update_subscription_fields',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'Change subscription quantity, term, or status fields.',
    ccai__Agentic_Function_Class__c = 'OrderAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'Id' },
        'properties' => new Map<String, Object>{
            'Id' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce subscription id.' }
        }
        ,'additionalProperties' => true
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
