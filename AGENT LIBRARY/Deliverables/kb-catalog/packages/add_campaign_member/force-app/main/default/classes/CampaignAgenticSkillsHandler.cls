/**
 * @description Campaign object skills for the GPTfy Agent Library (8 skills).
 * @author      : Plumcloud Labs
 * @group       : GPTfy Agent Library
 * @jira        : V2-8418
 */
global with sharing class CampaignAgenticSkillsHandler implements ccai.AIAgenticInterface {

    global String executeMethod(String methodName, Map<String, Object> parameters) {
        try {
            if (parameters == null) parameters = new Map<String, Object>();
            String m = String.isBlank(methodName) ? '' : methodName.trim();
            switch on m {
                when 'fuzzy_search_campaigns' { return handleFuzzySearchCampaigns(parameters); }
                when 'fetch_campaign_details' { return handleFetchCampaignDetails(parameters); }
                when 'create_campaign' { return handleCreateCampaign(parameters); }
                when 'update_campaign_fields' { return handleUpdateCampaignFields(parameters); }
                when 'fetch_campaign_members' { return handleFetchCampaignMembers(parameters); }
                when 'add_campaign_member' { return handleAddCampaignMember(parameters); }
                when 'update_campaign_member_status' { return handleUpdateCampaignMemberStatus(parameters); }
                when 'remove_campaign_member' { return handleRemoveCampaignMember(parameters); }
                when else { return AgenticSkillsBase.errorJson('Unsupported skill: ' + methodName); }
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'CampaignAgenticSkillsHandler | ' + methodName + ' | ' + ex.getMessage());
            return AgenticSkillsBase.errorJson(ex.getMessage());
        }
    }

    private String handleFuzzySearchCampaigns(Map<String, Object> p) {
        String term = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'search_term', 'campaign_name', 'name' }));
        if (String.isBlank(term)) return AgenticSkillsBase.errorJson('Missing required parameter: search_term');
        if (!Schema.sObjectType.Campaign.isAccessible()) return AgenticSkillsBase.errorJson('Campaign is not accessible.');
        List<SObject> all = AgenticSkillsBase.fuzzyQuery(
            'Campaign', 'Name', new List<String>{ 'Type', 'Status', 'IsActive' }, term
        );
        if (all.isEmpty()) return AgenticSkillsBase.errorJson('No campaign found matching "' + term + '".');
        Map<String, Object> sliced = AgenticSkillsBase.applyTopNAndCount(all, AgenticSkillsBase.FUZZY_DISPLAY_LIMIT);
        List<SObject> top = (List<SObject>) sliced.get('rows');
        List<Map<String, Object>> records = new List<Map<String, Object>>();
        for (SObject r : top) {
            Id rid = (Id) r.get('Id');
            records.add(new Map<String, Object>{
                'Id' => rid, 'Name' => r.get('Name'), 'Type' => r.get('Type'),
                'Status' => r.get('Status'), 'IsActive' => r.get('IsActive'),
                'recordUrl' => AgenticSkillsBase.recordUrl(rid),
                'viewRecord' => AgenticSkillsBase.viewRecordAnchor(rid)
            });
        }
        return AgenticSkillsBase.successJson(new Map<String, Object>{
            'status' => 'found',
            'totalFound' => sliced.get('totalFound'),
            'displayed' => sliced.get('displayed'),
            'remaining' => sliced.get('remaining'),
            'records' => records
        });
    }

    private String handleFetchCampaignDetails(Map<String, Object> p) {
        String cid = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'campaign_id', 'recordId', 'Id' }));
        if (String.isBlank(cid)) return AgenticSkillsBase.errorJson('Missing required parameter: campaign_id');
        if (!Schema.sObjectType.Campaign.isAccessible()) return AgenticSkillsBase.errorJson('Campaign is not accessible.');
        List<Campaign> rows = [
            SELECT Id, Name, Type, Status, IsActive, StartDate, EndDate, Description,
                   NumberOfContacts, NumberOfLeads, NumberOfResponses, OwnerId, Owner.Name
            FROM Campaign WHERE Id = :cid WITH USER_MODE LIMIT 1
        ];
        if (rows.isEmpty()) return AgenticSkillsBase.errorJson('No campaign found for provided Id.');
        Campaign c = rows[0];
        return AgenticSkillsBase.successJson(new Map<String, Object>{
            'Id' => c.Id, 'Name' => c.Name, 'Type' => c.Type, 'Status' => c.Status,
            'IsActive' => c.IsActive, 'StartDate' => String.valueOf(c.StartDate),
            'EndDate' => String.valueOf(c.EndDate), 'Description' => c.Description,
            'NumberOfContacts' => c.NumberOfContacts, 'NumberOfLeads' => c.NumberOfLeads,
            'NumberOfResponses' => c.NumberOfResponses,
            'Owner' => c.Owner != null ? c.Owner.Name : null,
            'recordUrl' => AgenticSkillsBase.recordUrl(c.Id)
        });
    }

    private String handleCreateCampaign(Map<String, Object> p) {
        if (!Schema.sObjectType.Campaign.isCreateable()) {
            return AgenticSkillsBase.errorHtml('Could not create campaign', 'Campaign is not creatable.');
        }
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, null);
        if (!fields.containsKey('Name') || String.isBlank(AgenticSkillsBase.toText(fields.get('Name')))) {
            return AgenticSkillsBase.errorHtml('Could not create campaign', 'Campaign Name is required.');
        }
        try {
            Campaign c = new Campaign();
            AgenticSkillsBase.applyFieldsToSObject(c, fields, false);
            insert c;
            String body = '<ul><li><b>Name:</b> ' + AgenticSkillsBase.escapeHtml(c.Name) + '</li>'
                        + (String.isNotBlank(c.Type) ? '<li><b>Type:</b> ' + AgenticSkillsBase.escapeHtml(c.Type) + '</li>' : '')
                        + (String.isNotBlank(c.Status) ? '<li><b>Status:</b> ' + AgenticSkillsBase.escapeHtml(c.Status) + '</li>' : '')
                        + '</ul>';
            return AgenticSkillsBase.successHtml('Campaign Created', body, c.Id, 'View Campaign');
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not create campaign', ex.getMessage());
        }
    }

    private String handleUpdateCampaignFields(Map<String, Object> p) {
        String cid = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'campaign_id', 'recordId', 'Id' }));
        if (String.isBlank(cid)) return AgenticSkillsBase.errorHtml('Could not update campaign', 'Missing parameter: campaign_id');
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, new Set<String>{ 'campaign_id', 'recordId', 'Id' });
        if (fields.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update campaign', 'Missing parameter: at least one field to update');
        if (!Schema.sObjectType.Campaign.isUpdateable()) return AgenticSkillsBase.errorHtml('Could not update campaign', 'Campaign is not updateable.');
        List<Campaign> rows = [SELECT Id, Name FROM Campaign WHERE Id = :cid WITH USER_MODE LIMIT 1];
        if (rows.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update campaign', 'No campaign found for provided Id.');
        return AgenticSkillsBase.performGenericUpdate('Campaign', cid, fields, 'Campaign Updated', 'View Campaign', rows[0].Name);
    }

    private String handleFetchCampaignMembers(Map<String, Object> p) {
        // CampaignMember.CampaignId — parent Campaign, not CampaignMember.Id
        Id campaignId = AgenticSkillsBase.resolveLookupId(p, 'CampaignId');
        if (campaignId == null) {
            campaignId = AgenticSkillsBase.resolvePrimaryId(p, 'Campaign');
        }
        if (campaignId == null) {
            return AgenticSkillsBase.errorJson('Missing required parameter: CampaignId (parent Campaign Id).');
        }
        if (!Schema.sObjectType.CampaignMember.isAccessible()) {
            return AgenticSkillsBase.errorJson('CampaignMember is not accessible.');
        }
        Integer lim = 50;
        Object lRaw = AgenticSkillsBase.firstNonBlank(p, new List<String>{ 'limit', 'Limit' });
        if (lRaw != null && String.isNotBlank(AgenticSkillsBase.toText(lRaw))) {
            try { lim = Integer.valueOf(AgenticSkillsBase.toText(lRaw)); } catch (Exception e) { lim = 50; }
        }
        lim = Math.max(1, Math.min(lim, 200));
        List<CampaignMember> members = [
            SELECT Id, Status, CampaignId, ContactId, Contact.Name, LeadId, Lead.Name, Lead.Company, CreatedDate
            FROM CampaignMember
            WHERE CampaignId = :campaignId
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT :lim
        ];
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        for (CampaignMember cm : members) {
            rows.add(new Map<String, Object>{
                'Id' => cm.Id,
                'CampaignId' => cm.CampaignId,
                'Status' => cm.Status,
                'ContactId' => cm.ContactId,
                'ContactName' => cm.Contact != null ? cm.Contact.Name : null,
                'LeadId' => cm.LeadId,
                'LeadName' => cm.Lead != null ? cm.Lead.Name : null,
                'LeadCompany' => cm.Lead != null ? cm.Lead.Company : null,
                'recordUrl' => AgenticSkillsBase.recordUrl(cm.Id)
            });
        }
        return AgenticSkillsBase.successJson(new Map<String, Object>{
            'CampaignId' => campaignId, 'count' => rows.size(), 'members' => rows
        });
    }

    private String handleAddCampaignMember(Map<String, Object> p) {
        // Org model: CampaignMember { CampaignId, ContactId | LeadId, Status }
        Id campaignId = AgenticSkillsBase.resolveLookupId(p, 'CampaignId');
        if (campaignId == null) {
            // legacy aliases
            campaignId = AgenticSkillsBase.parseSalesforceId(AgenticSkillsBase.toText(
                AgenticSkillsBase.firstNonBlank(p, new List<String>{ 'campaign_id', 'campaignId' })
            ));
        }
        Id contactId = AgenticSkillsBase.resolveLookupId(p, 'ContactId');
        Id leadId = AgenticSkillsBase.resolveLookupId(p, 'LeadId');
        if (campaignId == null) {
            return AgenticSkillsBase.errorHtml(
                'Could not add campaign member',
                'Missing parameter: CampaignId (parent Campaign Id, not CampaignMember Id).'
            );
        }
        if (campaignId.getSObjectType() != Campaign.SObjectType) {
            return AgenticSkillsBase.errorHtml(
                'Could not add campaign member',
                'CampaignId must be a Campaign Id (prefix 701…), not '
                    + campaignId.getSObjectType().getDescribe().getName() + '.'
            );
        }
        if (contactId == null && leadId == null) {
            return AgenticSkillsBase.errorHtml(
                'Could not add campaign member',
                'Provide ContactId or LeadId (CampaignMember relationship fields).'
            );
        }
        if (contactId != null && leadId != null) {
            return AgenticSkillsBase.errorHtml(
                'Could not add campaign member',
                'Provide ContactId OR LeadId, not both.'
            );
        }
        if (!Schema.sObjectType.CampaignMember.isCreateable()) {
            return AgenticSkillsBase.errorHtml('Could not add campaign member', 'CampaignMember is not creatable.');
        }
        try {
            CampaignMember cm = new CampaignMember(CampaignId = campaignId);
            if (contactId != null) cm.ContactId = contactId;
            if (leadId != null) cm.LeadId = leadId;
            String status = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonBlank(p, new List<String>{
                'Status', 'status'
            }));
            if (String.isNotBlank(status)) cm.Status = status;
            insert cm;
            String memberLabel = contactId != null ? 'Contact' : 'Lead';
            String body = '<ul><li><b>Campaign member added</b></li>'
                        + '<li><b>Member type:</b> ' + AgenticSkillsBase.escapeHtml(memberLabel) + '</li>'
                        + (String.isNotBlank(cm.Status) ? '<li><b>Status:</b> ' + AgenticSkillsBase.escapeHtml(cm.Status) + '</li>' : '')
                        + '</ul>';
            return AgenticSkillsBase.successHtml('Campaign Member Added', body, cm.Id, 'View Member');
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not add campaign member', ex.getMessage());
        }
    }

    private String handleUpdateCampaignMemberStatus(Map<String, Object> p) {
        // Primary Id = CampaignMember row Id
        Id memberId = AgenticSkillsBase.resolvePrimaryId(p, 'CampaignMember');
        if (memberId == null) {
            memberId = AgenticSkillsBase.parseSalesforceId(AgenticSkillsBase.toText(
                AgenticSkillsBase.firstNonBlank(p, new List<String>{
                    'Id', 'campaign_member_id', 'member_id', 'recordId'
                })
            ));
        }
        String status = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonBlank(p, new List<String>{ 'Status', 'status' }));
        if (memberId == null) {
            return AgenticSkillsBase.errorHtml(
                'Could not update member status',
                'Missing parameter: Id (CampaignMember Id).'
            );
        }
        if (String.isBlank(status)) {
            return AgenticSkillsBase.errorHtml('Could not update member status', 'Missing parameter: Status');
        }
        if (!Schema.sObjectType.CampaignMember.isUpdateable()) {
            return AgenticSkillsBase.errorHtml('Could not update member status', 'CampaignMember is not updateable.');
        }
        List<CampaignMember> rows = [
            SELECT Id, Status, Contact.Name, Lead.Name
            FROM CampaignMember WHERE Id = :memberId WITH USER_MODE LIMIT 1
        ];
        if (rows.isEmpty()) {
            return AgenticSkillsBase.errorHtml('Could not update member status', 'No campaign member found for provided Id.');
        }
        String label = rows[0].Contact != null ? rows[0].Contact.Name : (rows[0].Lead != null ? rows[0].Lead.Name : 'Member');
        return AgenticSkillsBase.performGenericUpdate(
            'CampaignMember', memberId, new Map<String, Object>{ 'Status' => status },
            'Campaign Member Status Updated', 'View Member', label
        );
    }

    private String handleRemoveCampaignMember(Map<String, Object> p) {
        Id memberId = AgenticSkillsBase.resolvePrimaryId(p, 'CampaignMember');
        if (memberId == null) {
            memberId = AgenticSkillsBase.parseSalesforceId(AgenticSkillsBase.toText(
                AgenticSkillsBase.firstNonBlank(p, new List<String>{
                    'Id', 'campaign_member_id', 'member_id', 'recordId'
                })
            ));
        }
        if (memberId == null) {
            return AgenticSkillsBase.errorHtml(
                'Could not remove campaign member',
                'Missing parameter: Id (CampaignMember Id).'
            );
        }
        if (!Schema.sObjectType.CampaignMember.isDeletable()) {
            return AgenticSkillsBase.errorHtml('Could not remove campaign member', 'CampaignMember is not deletable.');
        }
        List<CampaignMember> rows = [
            SELECT Id, Contact.Name, Lead.Name, CampaignId
            FROM CampaignMember WHERE Id = :memberId WITH USER_MODE LIMIT 1
        ];
        if (rows.isEmpty()) {
            return AgenticSkillsBase.errorHtml('Could not remove campaign member', 'No campaign member found for provided Id.');
        }
        try {
            String label = rows[0].Contact != null ? rows[0].Contact.Name : (rows[0].Lead != null ? rows[0].Lead.Name : 'Member');
            delete rows[0];
            String body = '<ul><li><b>Removed:</b> ' + AgenticSkillsBase.escapeHtml(label) + '</li></ul>';
            return AgenticSkillsBase.successHtml('Campaign Member Removed', body, null, null);
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not remove campaign member', ex.getMessage());
        }
    }
}
