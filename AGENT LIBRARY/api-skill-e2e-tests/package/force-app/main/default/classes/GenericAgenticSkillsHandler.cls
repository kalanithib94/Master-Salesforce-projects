/**
 * @description Backward-compatible facade — delegates skills to per-object handlers.
 *              Existing ccai__AI_Prompt__c records may keep Agentic_Function_Class__c =
 *              GenericAgenticSkillsHandler; new deployments should point prompts at the
 *              object-specific handler classes directly.
 * @author      : Plumcloud Labs
 * @group       : GPTfy Agent Library
 * @jira        : V2-8418
 */
global with sharing class GenericAgenticSkillsHandler implements ccai.AIAgenticInterface {

    private static final AccountAgenticSkillsHandler ACCOUNT_HANDLER = new AccountAgenticSkillsHandler();
    private static final ContactAgenticSkillsHandler CONTACT_HANDLER = new ContactAgenticSkillsHandler();
    private static final LeadAgenticSkillsHandler LEAD_HANDLER = new LeadAgenticSkillsHandler();
    private static final OpportunityAgenticSkillsHandler OPPORTUNITY_HANDLER = new OpportunityAgenticSkillsHandler();
    private static final CaseAgenticSkillsHandler CASE_HANDLER = new CaseAgenticSkillsHandler();
    private static final ActivityAgenticSkillsHandler ACTIVITY_HANDLER = new ActivityAgenticSkillsHandler();
    private static final UtilityAgenticSkillsHandler UTILITY_HANDLER = new UtilityAgenticSkillsHandler();
    private static final ProductAgenticSkillsHandler PRODUCT_HANDLER = new ProductAgenticSkillsHandler();
    private static final CampaignAgenticSkillsHandler CAMPAIGN_HANDLER = new CampaignAgenticSkillsHandler();
    private static final QuoteAgenticSkillsHandler QUOTE_HANDLER = new QuoteAgenticSkillsHandler();
    private static final ContractAgenticSkillsHandler CONTRACT_HANDLER = new ContractAgenticSkillsHandler();
    private static final ServiceAgenticSkillsHandler SERVICE_HANDLER = new ServiceAgenticSkillsHandler();
    private static final FieldServiceAgenticSkillsHandler FIELD_SERVICE_HANDLER = new FieldServiceAgenticSkillsHandler();
    private static final CpqAgenticSkillsHandler CPQ_HANDLER = new CpqAgenticSkillsHandler();
    private static final OrderAgenticSkillsHandler ORDER_HANDLER = new OrderAgenticSkillsHandler();
    private static final PartnerAgenticSkillsHandler PARTNER_HANDLER = new PartnerAgenticSkillsHandler();
    private static final IndustryAgenticSkillsHandler INDUSTRY_HANDLER = new IndustryAgenticSkillsHandler();

    global String executeMethod(String methodName, Map<String, Object> parameters) {
        try {
            if (parameters == null) parameters = new Map<String, Object>();
            String m = String.isBlank(methodName) ? '' : methodName.trim();
            switch on m {
                when 'fuzzy_search_accounts'        { return ACCOUNT_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_account_details'        { return ACCOUNT_HANDLER.executeMethod(methodName, parameters); }
                when 'create_account'               { return ACCOUNT_HANDLER.executeMethod(methodName, parameters); }
                when 'update_account_fields'        { return ACCOUNT_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_account_related_lists'  { return ACCOUNT_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_account_plan'           { return ACCOUNT_HANDLER.executeMethod(methodName, parameters); }
                when 'fuzzy_search_contacts'        { return CONTACT_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_contact_details'        { return CONTACT_HANDLER.executeMethod(methodName, parameters); }
                when 'create_contact'               { return CONTACT_HANDLER.executeMethod(methodName, parameters); }
                when 'update_contact_fields'        { return CONTACT_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_contact_engagement_history' { return CONTACT_HANDLER.executeMethod(methodName, parameters); }
                when 'fuzzy_search_leads'           { return LEAD_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_lead_details'           { return LEAD_HANDLER.executeMethod(methodName, parameters); }
                when 'create_lead'                  { return LEAD_HANDLER.executeMethod(methodName, parameters); }
                when 'update_lead_fields'           { return LEAD_HANDLER.executeMethod(methodName, parameters); }
                when 'convert_lead'                 { return LEAD_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_opportunity_details'    { return OPPORTUNITY_HANDLER.executeMethod(methodName, parameters); }
                when 'fuzzy_search_opportunities'   { return OPPORTUNITY_HANDLER.executeMethod(methodName, parameters); }
                when 'create_opportunity'           { return OPPORTUNITY_HANDLER.executeMethod(methodName, parameters); }
                when 'update_opportunity_fields'    { return OPPORTUNITY_HANDLER.executeMethod(methodName, parameters); }
                when 'add_opportunity_line_item'    { return OPPORTUNITY_HANDLER.executeMethod(methodName, parameters); }
                when 'update_opportunity_line_item' { return OPPORTUNITY_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_opportunity_contact_roles' { return OPPORTUNITY_HANDLER.executeMethod(methodName, parameters); }
                when 'add_opportunity_contact_role' { return OPPORTUNITY_HANDLER.executeMethod(methodName, parameters); }
                when 'update_opportunity_contact_role' { return OPPORTUNITY_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_opportunity_team' { return OPPORTUNITY_HANDLER.executeMethod(methodName, parameters); }
                when 'add_opportunity_team_member' { return OPPORTUNITY_HANDLER.executeMethod(methodName, parameters); }
                when 'clone_opportunity' { return OPPORTUNITY_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_opportunity_partners' { return OPPORTUNITY_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_case_details'           { return CASE_HANDLER.executeMethod(methodName, parameters); }
                when 'fuzzy_search_cases'           { return CASE_HANDLER.executeMethod(methodName, parameters); }
                when 'create_case'                  { return CASE_HANDLER.executeMethod(methodName, parameters); }
                when 'update_case_fields'           { return CASE_HANDLER.executeMethod(methodName, parameters); }
                when 'close_case'                   { return CASE_HANDLER.executeMethod(methodName, parameters); }
                when 'add_case_comment'             { return CASE_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_case_team'              { return CASE_HANDLER.executeMethod(methodName, parameters); }
                when 'add_case_team_member'         { return CASE_HANDLER.executeMethod(methodName, parameters); }
                when 'link_knowledge_article_to_case' { return CASE_HANDLER.executeMethod(methodName, parameters); }
                when 'log_activity'                 { return ACTIVITY_HANDLER.executeMethod(methodName, parameters); }
                when 'create_task'                  { return ACTIVITY_HANDLER.executeMethod(methodName, parameters); }
                when 'update_task'                  { return ACTIVITY_HANDLER.executeMethod(methodName, parameters); }
                when 'create_event'                 { return ACTIVITY_HANDLER.executeMethod(methodName, parameters); }
                when 'update_event'                 { return ACTIVITY_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_my_open_tasks'          { return ACTIVITY_HANDLER.executeMethod(methodName, parameters); }
                when 'complete_task'                { return ACTIVITY_HANDLER.executeMethod(methodName, parameters); }
                when 'run_internal_prompt'          { return UTILITY_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_picklist_values'        { return UTILITY_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_session_context'        { return UTILITY_HANDLER.executeMethod(methodName, parameters); }
                when 'transfer_record_owner'        { return UTILITY_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_my_open_opportunities' { return UTILITY_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_stale_opportunities'   { return UTILITY_HANDLER.executeMethod(methodName, parameters); }
                when 'search_knowledge_articles'  { return UTILITY_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_knowledge_article'    { return UTILITY_HANDLER.executeMethod(methodName, parameters); }
                when 'assign_to_queue'            { return UTILITY_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_queue_cases'          { return UTILITY_HANDLER.executeMethod(methodName, parameters); }
                when 'fuzzy_search_products'        { return PRODUCT_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_product_details'        { return PRODUCT_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_pricebook_entries'      { return PRODUCT_HANDLER.executeMethod(methodName, parameters); }
                when 'fuzzy_search_campaigns'       { return CAMPAIGN_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_campaign_details'       { return CAMPAIGN_HANDLER.executeMethod(methodName, parameters); }
                when 'create_campaign'              { return CAMPAIGN_HANDLER.executeMethod(methodName, parameters); }
                when 'update_campaign_fields'       { return CAMPAIGN_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_campaign_members'       { return CAMPAIGN_HANDLER.executeMethod(methodName, parameters); }
                when 'add_campaign_member'          { return CAMPAIGN_HANDLER.executeMethod(methodName, parameters); }
                when 'update_campaign_member_status' { return CAMPAIGN_HANDLER.executeMethod(methodName, parameters); }
                when 'remove_campaign_member'       { return CAMPAIGN_HANDLER.executeMethod(methodName, parameters); }
                when 'fuzzy_search_quotes'          { return QUOTE_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_quote_details'          { return QUOTE_HANDLER.executeMethod(methodName, parameters); }
                when 'create_quote'                 { return QUOTE_HANDLER.executeMethod(methodName, parameters); }
                when 'update_quote_fields'          { return QUOTE_HANDLER.executeMethod(methodName, parameters); }
                when 'add_quote_line_item'          { return QUOTE_HANDLER.executeMethod(methodName, parameters); }
                when 'update_quote_line_item'       { return QUOTE_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_contract_details'       { return CONTRACT_HANDLER.executeMethod(methodName, parameters); }
                when 'create_contract'              { return CONTRACT_HANDLER.executeMethod(methodName, parameters); }
                when 'update_contract_fields'       { return CONTRACT_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_case_milestones'        { return SERVICE_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_case_entitlements'      { return SERVICE_HANDLER.executeMethod(methodName, parameters); }
                when 'fuzzy_search_assets'          { return SERVICE_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_asset_details'          { return SERVICE_HANDLER.executeMethod(methodName, parameters); }
                when 'update_asset_fields'          { return SERVICE_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_work_order_details'     { return FIELD_SERVICE_HANDLER.executeMethod(methodName, parameters); }
                when 'create_work_order'            { return FIELD_SERVICE_HANDLER.executeMethod(methodName, parameters); }
                when 'update_work_order_fields'     { return FIELD_SERVICE_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_service_appointment'    { return FIELD_SERVICE_HANDLER.executeMethod(methodName, parameters); }
                when 'schedule_service_appointment' { return FIELD_SERVICE_HANDLER.executeMethod(methodName, parameters); }
                when 'update_service_appointment'   { return FIELD_SERVICE_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_service_resource_availability' { return FIELD_SERVICE_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_cpq_quote_details'      { return CPQ_HANDLER.executeMethod(methodName, parameters); }
                when 'create_cpq_quote'             { return CPQ_HANDLER.executeMethod(methodName, parameters); }
                when 'update_cpq_quote_fields'      { return CPQ_HANDLER.executeMethod(methodName, parameters); }
                when 'add_cpq_quote_line'           { return CPQ_HANDLER.executeMethod(methodName, parameters); }
                when 'update_cpq_quote_line'        { return CPQ_HANDLER.executeMethod(methodName, parameters); }
                when 'calculate_cpq_quote'          { return CPQ_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_order_details'          { return ORDER_HANDLER.executeMethod(methodName, parameters); }
                when 'create_order'                 { return ORDER_HANDLER.executeMethod(methodName, parameters); }
                when 'update_order_fields'          { return ORDER_HANDLER.executeMethod(methodName, parameters); }
                when 'add_order_item'               { return ORDER_HANDLER.executeMethod(methodName, parameters); }
                when 'update_order_item'            { return ORDER_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_subscription_details'   { return ORDER_HANDLER.executeMethod(methodName, parameters); }
                when 'update_subscription_fields'   { return ORDER_HANDLER.executeMethod(methodName, parameters); }
                when 'fuzzy_search_partners'         { return PARTNER_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_partner_account'        { return PARTNER_HANDLER.executeMethod(methodName, parameters); }
                when 'add_opportunity_partner'      { return PARTNER_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_financial_account'      { return INDUSTRY_HANDLER.executeMethod(methodName, parameters); }
                when 'update_financial_account_fields' { return INDUSTRY_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_care_plan'              { return INDUSTRY_HANDLER.executeMethod(methodName, parameters); }
                when 'create_care_task'             { return INDUSTRY_HANDLER.executeMethod(methodName, parameters); }
                when 'update_care_plan_fields'      { return INDUSTRY_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_record_approvals'       { return UTILITY_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_renewal_opportunities'  { return UTILITY_HANDLER.executeMethod(methodName, parameters); }
                when 'fetch_upcoming_renewals'      { return UTILITY_HANDLER.executeMethod(methodName, parameters); }
                when else                           { return AgenticSkillsBase.errorJson('Unsupported skill: ' + methodName); }
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'GenericAgenticSkillsHandler | ' + methodName + ' | ' + ex.getMessage());
            return AgenticSkillsBase.errorJson(ex.getMessage());
        }
    }
}
