// V1 skill names — Wave 1 subset of MasterSkills.apex (33 skills).
// Locked full list: Deliverables/docs/MASTER_SKILL_LIST.md

List<String> V1_SKILLS = new List<String>{
    // Account
    'fuzzy_search_accounts', 'fetch_account_details', 'create_account',
    'update_account_fields', 'fetch_account_related_lists',
    // Contact
    'fuzzy_search_contacts', 'fetch_contact_details', 'create_contact', 'update_contact_fields',
    // Lead
    'fuzzy_search_leads', 'fetch_lead_details', 'create_lead', 'update_lead_fields', 'convert_lead',
    // Opportunity
    'fetch_opportunity_details', 'create_opportunity', 'update_opportunity_fields',
    'add_opportunity_line_item', 'update_opportunity_line_item',
    // Case
    'fetch_case_details', 'create_case', 'update_case_fields', 'close_case',
    // Activity
    'log_activity', 'create_task', 'update_task', 'create_event', 'update_event',
    'fetch_my_open_tasks', 'complete_task',
    // Helpers
    'fetch_session_context', 'fetch_picklist_values', 'run_internal_prompt'
};
