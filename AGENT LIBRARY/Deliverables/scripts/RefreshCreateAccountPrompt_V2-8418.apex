// Jira V2-8418 — refresh the create_account AI_Prompt__c with the new Option B schema (top-level Name).
// Idempotent: updates the existing record in place; runs whether the description was previously set or not.

// ccai__Description__c is Text(255) — keep this concise.
String newDescription = 'Creates a new Account. Required parameter: top-level "Name" (never invoke without it). Optional additional fields (Industry, AnnualRevenue, Phone, Website, Billing*, etc.) go inside the optional "fields" map using exact Salesforce API names.';

String newPromptCommand = JSON.serializePretty(new Map<String, Object>{
    'type' => 'object',
    'properties' => new Map<String, Object>{
        'Name' => new Map<String, Object>{
            'type' => 'string',
            'description' => 'REQUIRED. The Account Name (e.g. "Acme Corporation"). This is the only mandatory parameter for creating an Account — do not invoke this skill without it.'
        },
        'fields' => new Map<String, Object>{
            'type' => 'object',
            'description' => 'Optional. Map of additional Account field API names to their values — Industry, Type, AnnualRevenue, NumberOfEmployees, Phone, Website, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Description, Rating, custom fields, etc. Do NOT put "Name" here — pass it at the top level. Numbers as numbers, booleans as true/false, picklist values as the exact API value.',
            'additionalProperties' => true
        }
    },
    'required' => new List<String>{ 'Name' }
});

List<ccai__AI_Prompt__c> existing = [
    SELECT Id, Name, ccai__Description__c, ccai__Prompt_Command__c
    FROM ccai__AI_Prompt__c
    WHERE Name = 'create_account'
    LIMIT 5
];
System.debug('Found ' + existing.size() + ' create_account prompt record(s).');

if (existing.isEmpty()) {
    System.debug('WARNING: No create_account AI_Prompt__c found. Nothing to refresh. Run Part1_Account.apex to insert it first.');
} else {
    for (ccai__AI_Prompt__c p : existing) {
        p.ccai__Description__c   = newDescription;
        p.ccai__Prompt_Command__c = newPromptCommand;
    }
    update existing;
    for (ccai__AI_Prompt__c p : existing) {
        System.debug('Refreshed AI_Prompt__c ' + p.Id + ' (' + p.Name + ')');
    }
    System.debug('Refreshed ' + existing.size() + ' record(s).');
}
