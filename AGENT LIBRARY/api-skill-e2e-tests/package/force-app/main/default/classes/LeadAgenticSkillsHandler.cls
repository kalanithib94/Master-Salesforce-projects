/**
 * @description Lead object skills for the GPTfy Agent Library (5 skills).
 *              Implements ccai.AIAgenticInterface; shared helpers live in AgenticSkillsBase.
 * @author      : Plumcloud Labs
 * @group       : GPTfy Agent Library
 * @jira        : V2-8418
 */
global with sharing class LeadAgenticSkillsHandler implements ccai.AIAgenticInterface {

    global String executeMethod(String methodName, Map<String, Object> parameters) {
        try {
            if (parameters == null) parameters = new Map<String, Object>();
            String m = String.isBlank(methodName) ? '' : methodName.trim();
            switch on m {
                when 'fuzzy_search_leads' { return handleFuzzySearchLeads(parameters); }
                when 'fetch_lead_details' { return handleFetchLeadDetails(parameters); }
                when 'create_lead' { return handleCreateLead(parameters); }
                when 'update_lead_fields' { return handleUpdateLeadFields(parameters); }
                when 'convert_lead' { return handleConvertLead(parameters); }
                when else { return AgenticSkillsBase.errorJson('Unsupported skill: ' + methodName); }
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'LeadAgenticSkillsHandler | ' + methodName + ' | ' + ex.getMessage());
            return AgenticSkillsBase.errorJson(ex.getMessage());
        }
    }

/**
     * @description Skill 11 — fuzzy_search_leads. Fetches ALL matching Leads
     *              (capped at AgenticSkillsBase.FUZZY_HARD_CAP) ordered by LastModifiedDate
     *              DESC; the agent displays the latest AgenticSkillsBase.FUZZY_DISPLAY_LIMIT
     *              with totalFound / displayed / remaining counts in the
     *              envelope for "X more not shown" messaging.
     * @jira V2-8418
     */
    private String handleFuzzySearchLeads(Map<String, Object> p) {
        String term = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'search_term', 'lead_name', 'name', 'email', 'company' }));
        if (String.isBlank(term)) return AgenticSkillsBase.errorJson('Missing required parameter: search_term');
        if (!Schema.sObjectType.Lead.isAccessible()) return AgenticSkillsBase.errorJson('Lead is not accessible.');
        List<SObject> all = AgenticSkillsBase.fuzzyQueryMulti(
            'Lead',
            new List<String>{ 'Name', 'Company', 'Email' },
            new List<String>{ 'Phone', 'Status', 'IsConverted' },
            term
        );
        if (all.isEmpty()) return AgenticSkillsBase.errorJson('No lead found matching "' + term + '".');
        Map<String, Object> sliced = AgenticSkillsBase.applyTopNAndCount(all, AgenticSkillsBase.FUZZY_DISPLAY_LIMIT);
        List<SObject> top = (List<SObject>) sliced.get('rows');
        List<Map<String, Object>> records = new List<Map<String, Object>>();
        for (SObject r : top) {
            Lead l = (Lead) r;
            records.add(new Map<String, Object>{
                'Id' => l.Id, 'Name' => l.Name, 'Company' => l.Company,
                'Email' => l.Email, 'Phone' => l.Phone, 'Status' => l.Status,
                'IsConverted' => l.IsConverted,
                'recordUrl'   => AgenticSkillsBase.recordUrl(l.Id),
                'viewRecord'  => AgenticSkillsBase.viewRecordAnchor(l.Id)
            });
        }
        return AgenticSkillsBase.successJson(new Map<String, Object>{
            'status'     => 'found',
            'totalFound' => sliced.get('totalFound'),
            'displayed'  => sliced.get('displayed'),
            'remaining'  => sliced.get('remaining'),
            'records'    => records
        });
    }

    /**
     * @description Skill 12 — fetch_lead_details.
     * @jira V2-8418
     */
    private String handleFetchLeadDetails(Map<String, Object> p) {
        String lid = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'lead_id', 'recordId', 'Id' }));
        if (String.isBlank(lid)) return AgenticSkillsBase.errorJson('Missing required parameter: lead_id');
        if (!Schema.sObjectType.Lead.isAccessible()) return AgenticSkillsBase.errorJson('Lead is not accessible.');
        // Jira V2-8418: Removed Lead.Rating and Lead.MobilePhone from SELECT —
        // both fields are disabled at the org level in some orgs (e.g. tsogptfy).
        // Including them causes a System.QueryException ("No such column ...") at
        // runtime. Re-add only after confirming each field is enabled on the
        // target org.
        List<Lead> rows = [
            SELECT Id, Name, FirstName, LastName, Company, Title, Email, Phone,
                   Status, LeadSource, Industry, AnnualRevenue, NumberOfEmployees,
                   IsConverted, ConvertedAccountId, ConvertedContactId, ConvertedOpportunityId,
                   OwnerId, Owner.Name
            FROM Lead WHERE Id = :lid WITH USER_MODE LIMIT 1
        ];
        if (rows.isEmpty()) return AgenticSkillsBase.errorJson('No lead found for provided Id.');
        Lead l = rows[0];
        return AgenticSkillsBase.successJson(new Map<String, Object>{
            'Id' => l.Id, 'Name' => l.Name, 'FirstName' => l.FirstName, 'LastName' => l.LastName,
            'Company' => l.Company, 'Title' => l.Title, 'Email' => l.Email, 'Phone' => l.Phone,
            'Status' => l.Status, 'LeadSource' => l.LeadSource, 'Industry' => l.Industry,
            'AnnualRevenue' => l.AnnualRevenue,
            'IsConverted' => l.IsConverted, 'ConvertedAccountId' => l.ConvertedAccountId,
            'ConvertedContactId' => l.ConvertedContactId, 'ConvertedOpportunityId' => l.ConvertedOpportunityId,
            'Owner' => l.Owner != null ? l.Owner.Name : null,
            'recordUrl' => AgenticSkillsBase.recordUrl(l.Id)
        });
    }

    /**
     * @description Skill 13 — create_lead. Accepts Lead field API names as flat
     *              top-level parameters (e.g. LastName, Company, FirstName, Email,
     *              Status, …). LastName and Company are required. The legacy
     *              nested { "fields": { … } } shape is still accepted for
     *              backward compatibility.
     * @jira V2-8418
     */
    private String handleCreateLead(Map<String, Object> p) {
        if (!Schema.sObjectType.Lead.isCreateable()) return AgenticSkillsBase.errorHtml('Could not create lead', 'Lead is not creatable.');
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, null);
        for (String required : new List<String>{ 'LastName', 'Company' }) {
            if (!fields.containsKey(required) || String.isBlank(AgenticSkillsBase.toText(fields.get(required)))) {
                return AgenticSkillsBase.errorHtml('Could not create lead', required + ' is required.');
            }
        }
        try {
            Lead l = new Lead();
            AgenticSkillsBase.applyFieldsToSObject(l, fields, false);
            insert l;
            String body = '<ul><li><b>Name:</b> ' + AgenticSkillsBase.escapeHtml(String.valueOf(fields.get('LastName'))) + '</li>'
                        + '<li><b>Company:</b> ' + AgenticSkillsBase.escapeHtml(String.valueOf(fields.get('Company'))) + '</li></ul>';
            return AgenticSkillsBase.successHtml('Lead Created', body, l.Id, 'View Lead');
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not create lead', ex.getMessage());
        }
    }

    /**
     * @description Skill 14 — update_lead_fields. Field updates are passed as
     *              flat top-level keys (e.g. { lead_id, Title, Status }). The
     *              legacy nested { "fields": { … } } shape is still accepted for
     *              backward compatibility.
     * @jira V2-8418
     */
    private String handleUpdateLeadFields(Map<String, Object> p) {
        String lid = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'lead_id', 'recordId', 'Id' }));
        if (String.isBlank(lid)) return AgenticSkillsBase.errorHtml('Could not update lead', 'Missing parameter: lead_id');
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, new Set<String>{ 'lead_id', 'recordId', 'Id' });
        if (fields.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update lead', 'Missing parameter: at least one field to update');
        if (!Schema.sObjectType.Lead.isUpdateable()) return AgenticSkillsBase.errorHtml('Could not update lead', 'Lead is not updateable.');
        List<Lead> rows = [SELECT Id, Name FROM Lead WHERE Id = :lid WITH USER_MODE LIMIT 1];
        if (rows.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update lead', 'No lead found for provided Id.');
        return AgenticSkillsBase.performGenericUpdate('Lead', lid, fields, 'Lead Updated', 'View Lead', rows[0].Name);
    }

    /**
     * @description Skill 15 — convert_lead. Honors optional account_id, opportunity_name, do_not_create_opportunity.
     * @jira V2-8418
     */
    private String handleConvertLead(Map<String, Object> p) {
        String lid = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'lead_id', 'recordId', 'Id' }));
        if (String.isBlank(lid)) return AgenticSkillsBase.errorHtml('Could not convert lead', 'Missing parameter: lead_id');
        if (!Schema.sObjectType.Lead.isUpdateable()) return AgenticSkillsBase.errorHtml('Could not convert lead', 'Lead is not updateable.');
        List<Lead> rows = [SELECT Id, Name, IsConverted FROM Lead WHERE Id = :lid WITH USER_MODE LIMIT 1];
        if (rows.isEmpty()) return AgenticSkillsBase.errorHtml('Could not convert lead', 'No lead found for provided Id.');
        if (rows[0].IsConverted) return AgenticSkillsBase.errorHtml('Could not convert lead', 'Lead is already converted.');
        try {
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(lid);
            String accountId = AgenticSkillsBase.toText(p.get('account_id'));
            if (String.isNotBlank(accountId)) lc.setAccountId(accountId);
            Boolean noOpp = (Boolean) (p.get('do_not_create_opportunity') == null ? false : Boolean.valueOf(String.valueOf(p.get('do_not_create_opportunity'))));
            lc.setDoNotCreateOpportunity(noOpp);
            String oppName = AgenticSkillsBase.toText(p.get('opportunity_name'));
            if (!noOpp && String.isNotBlank(oppName)) lc.setOpportunityName(oppName);
            List<LeadStatus> converted = [SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
            if (!converted.isEmpty()) lc.setConvertedStatus(converted[0].MasterLabel);
            Database.LeadConvertResult lcr = Database.convertLead(lc);
            if (!lcr.isSuccess()) return AgenticSkillsBase.errorHtml('Could not convert lead', lcr.getErrors()[0].getMessage());
            String body = '<ul>'
                        + '<li><b>Account Id:</b> ' + AgenticSkillsBase.escapeHtml(String.valueOf(lcr.getAccountId())) + '</li>'
                        + '<li><b>Contact Id:</b> ' + AgenticSkillsBase.escapeHtml(String.valueOf(lcr.getContactId())) + '</li>'
                        + (lcr.getOpportunityId() != null ? '<li><b>Opportunity Id:</b> ' + AgenticSkillsBase.escapeHtml(String.valueOf(lcr.getOpportunityId())) + '</li>' : '')
                        + '</ul>';
            return AgenticSkillsBase.successHtml('Lead Converted', body, lid, 'View Lead');
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not convert lead', ex.getMessage());
        }
    }
}
