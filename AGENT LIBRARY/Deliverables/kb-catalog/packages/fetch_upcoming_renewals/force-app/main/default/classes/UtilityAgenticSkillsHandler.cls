/**
 * @description Utility skills for the GPTfy Agent Library (12 skills).
 *              Skill logic lives in AgenticSkillsBase; this class is the GPTfy entry point.
 * @author      : Plumcloud Labs
 * @group       : GPTfy Agent Library
 * @jira        : V2-8418
 */
global with sharing class UtilityAgenticSkillsHandler implements ccai.AIAgenticInterface {

    global String executeMethod(String methodName, Map<String, Object> parameters) {
        try {
            if (parameters == null) parameters = new Map<String, Object>();
            String m = String.isBlank(methodName) ? '' : methodName.trim();
            switch on m {
                when 'run_internal_prompt'   { return AgenticSkillsBase.skillRunInternalPrompt(parameters); }
                when 'fetch_picklist_values' { return AgenticSkillsBase.skillFetchPicklistValues(parameters); }
                when 'fetch_session_context' { return AgenticSkillsBase.skillFetchSessionContext(parameters); }
                when 'transfer_record_owner'  { return AgenticSkillsBase.skillTransferRecordOwner(parameters); }
                when 'fetch_my_open_opportunities' { return AgenticSkillsBase.skillFetchMyOpenOpportunities(parameters); }
                when 'fetch_stale_opportunities' { return AgenticSkillsBase.skillFetchStaleOpportunities(parameters); }
                when 'search_knowledge_articles' { return AgenticSkillsBase.skillSearchKnowledgeArticles(parameters); }
                when 'fetch_knowledge_article' { return AgenticSkillsBase.skillFetchKnowledgeArticle(parameters); }
                when 'assign_to_queue' { return AgenticSkillsBase.skillAssignToQueue(parameters); }
                when 'fetch_queue_cases' { return AgenticSkillsBase.skillFetchQueueCases(parameters); }
                when 'fetch_record_approvals' { return AgenticSkillsBase.skillFetchRecordApprovals(parameters); }
                when 'fetch_renewal_opportunities' { return AgenticSkillsBase.skillFetchRenewalOpportunities(parameters); }
                when 'fetch_upcoming_renewals' { return AgenticSkillsBase.skillFetchUpcomingRenewals(parameters); }
                when else                    { return AgenticSkillsBase.errorJson('Unsupported skill: ' + methodName); }
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'UtilityAgenticSkillsHandler | ' + methodName + ' | ' + ex.getMessage());
            return AgenticSkillsBase.errorJson(ex.getMessage());
        }
    }
}
