// Update the create_credit_increase_case function description to be more explicit
ccai__AI_Prompt__c prompt = [
    SELECT Id, Name, CCAI__DESCRIPTION__C, CCAI__PROMPT_COMMAND__C
    FROM ccai__AI_Prompt__c 
    WHERE Name = 'create_credit_increase_case' 
    LIMIT 1
];

// Update the description to be very explicit (max 255 chars)
prompt.CCAI__DESCRIPTION__C = 'Call IMMEDIATELY when user requests credit increase/limit raise. Use ContactId from find_contact_by_name or find_contact_details_by_id. Creates case for credit increase. MUST call when user asks to increase limit - do not just show contact info.';

update prompt;

System.debug('Updated create_credit_increase_case description: ' + prompt.CCAI__DESCRIPTION__C);

