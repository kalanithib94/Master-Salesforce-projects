// Part 0 — Delete all master-list skill prompts before recreating (safe-by-name).
// Includes retired skill names so org migrations can clean up old prompts.

Set<String> targetNames = new Set<String>{
    // All 108 master skills
    'fuzzy_search_accounts', 'fetch_account_details', 'create_account',
    'update_account_fields', 'fetch_account_related_lists',
    'fuzzy_search_contacts', 'fetch_contact_details', 'create_contact', 'update_contact_fields',
    'fuzzy_search_leads', 'fetch_lead_details', 'create_lead', 'update_lead_fields', 'convert_lead',
    'fetch_opportunity_details', 'create_opportunity', 'update_opportunity_fields',
    'add_opportunity_line_item', 'update_opportunity_line_item',
    'fetch_case_details', 'create_case', 'update_case_fields', 'close_case',
    'log_activity', 'create_task', 'update_task', 'create_event', 'update_event',
    'fetch_my_open_tasks', 'complete_task',
    'fetch_session_context', 'fetch_picklist_values', 'run_internal_prompt',
    'fuzzy_search_opportunities', 'fuzzy_search_cases', 'add_case_comment',
    'fuzzy_search_products', 'fetch_product_details', 'fetch_pricebook_entries',
    'transfer_record_owner',
    'fuzzy_search_campaigns', 'fetch_campaign_details', 'create_campaign', 'update_campaign_fields',
    'fetch_campaign_members', 'add_campaign_member', 'update_campaign_member_status',
    'fuzzy_search_quotes', 'fetch_quote_details', 'create_quote', 'update_quote_fields',
    'add_quote_line_item', 'update_quote_line_item',
    'fetch_opportunity_contact_roles', 'add_opportunity_contact_role', 'update_opportunity_contact_role',
    'fetch_opportunity_team', 'add_opportunity_team_member',
    'fetch_my_open_opportunities', 'fetch_stale_opportunities', 'clone_opportunity',
    'fetch_contract_details', 'create_contract', 'update_contract_fields',
    'fetch_case_team', 'add_case_team_member',
    'search_knowledge_articles', 'fetch_knowledge_article', 'link_knowledge_article_to_case',
    'fetch_case_milestones', 'fetch_case_entitlements',
    'assign_to_queue', 'fetch_queue_cases',
    'fuzzy_search_assets', 'fetch_asset_details', 'update_asset_fields',
    'fetch_work_order_details', 'create_work_order', 'update_work_order_fields',
    'fetch_service_appointment', 'schedule_service_appointment', 'update_service_appointment',
    'fetch_service_resource_availability',
    'fetch_cpq_quote_details', 'create_cpq_quote', 'update_cpq_quote_fields',
    'add_cpq_quote_line', 'update_cpq_quote_line', 'calculate_cpq_quote',
    'fetch_order_details', 'create_order', 'update_order_fields',
    'add_order_item', 'update_order_item',
    'fetch_subscription_details', 'update_subscription_fields',
    'fuzzy_search_partners', 'fetch_partner_account', 'add_opportunity_partner',
    'fetch_opportunity_partners',
    'fetch_financial_account', 'update_financial_account_fields', 'fetch_care_plan',
    'fetch_record_approvals', 'fetch_renewal_opportunities', 'remove_campaign_member',
    'create_care_task', 'update_care_plan_fields',
    'fetch_upcoming_renewals', 'fetch_account_plan', 'fetch_contact_engagement_history',
    // Retired (remove from org on migration)
    'delete_account', 'delete_contact', 'delete_opportunity',
    'log_contact_activity', 'log_lead_activity', 'log_opportunity_activity',
    'fetch_opportunity_recent_changes',
    'bulk_update_records', 'fetch_record_history', 'fetch_user_info', 'fetch_customer_360'
};

List<ccai__AI_Prompt__c> toDelete = [
    SELECT Id, Name FROM ccai__AI_Prompt__c WHERE Name IN :targetNames
];

System.debug('========================================');
System.debug('Found ' + toDelete.size() + ' prompts to delete (out of ' + targetNames.size() + ' target names):');
for (ccai__AI_Prompt__c p : toDelete) {
    System.debug('  - ' + p.Name + ' (' + p.Id + ')');
}

if (!toDelete.isEmpty()) {
    delete toDelete;
    System.debug('Deleted ' + toDelete.size() + ' prompt records.');
} else {
    System.debug('Nothing to delete.');
}
System.debug('========================================');
