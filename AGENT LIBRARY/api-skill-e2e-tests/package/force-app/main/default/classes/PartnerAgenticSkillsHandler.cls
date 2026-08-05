/**
 * @description Partner / PRM skills for the GPTfy Agent Library.
 * @author      : Plumcloud Labs
 * @group       : GPTfy Agent Library
 * @jira        : V2-8418
 */
global with sharing class PartnerAgenticSkillsHandler implements ccai.AIAgenticInterface {

    global String executeMethod(String methodName, Map<String, Object> parameters) {
        try {
            if (parameters == null) parameters = new Map<String, Object>();
            String m = String.isBlank(methodName) ? '' : methodName.trim();
            switch on m {
                when 'fuzzy_search_partners'     { return handleFuzzySearchPartners(parameters); }
                when 'fetch_partner_account'     { return handleFetchPartnerAccount(parameters); }
                when 'add_opportunity_partner'   { return handleAddOpportunityPartner(parameters); }
                when else { return AgenticSkillsBase.errorJson('Unsupported skill: ' + methodName); }
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'PartnerAgenticSkillsHandler | ' + methodName + ' | ' + ex.getMessage());
            return AgenticSkillsBase.errorJson(ex.getMessage());
        }
    }

    private class PartnerSource {
        String objectApi;
        String nameField;
        String idField;
        List<String> extraFields;
        String whereClause;
    }

    private PartnerSource resolvePartnerSource() {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        if (gd.containsKey('Partner__c') && gd.get('Partner__c').getDescribe().isAccessible()) {
            PartnerSource ps = new PartnerSource();
            ps.objectApi = 'Partner__c';
            ps.nameField = gd.get('Partner__c').getDescribe().fields.getMap().containsKey('Name') ? 'Name' : 'Id';
            ps.idField = 'Id';
            ps.extraFields = new List<String>();
            Map<String, Schema.SObjectField> fmap = gd.get('Partner__c').getDescribe().fields.getMap();
            for (String f : new List<String>{ 'Account__c', 'Status__c', 'Partner_Type__c' }) {
                if (fmap.containsKey(f)) ps.extraFields.add(f);
            }
            return ps;
        }
        if (Schema.sObjectType.Account.isAccessible()) {
            PartnerSource ps = new PartnerSource();
            ps.objectApi = 'Account';
            ps.nameField = 'Name';
            ps.idField = 'Id';
            ps.extraFields = new List<String>{ 'Type', 'Industry', 'Website' };
            Map<String, Schema.SObjectField> fmap = Schema.sObjectType.Account.fields.getMap();
            if (fmap.containsKey('IsPartner')) {
                ps.whereClause = 'IsPartner = true';
            } else {
                ps.whereClause = 'Type LIKE \'%Partner%\'';
            }
            return ps;
        }
        return null;
    }

    private String handleFuzzySearchPartners(Map<String, Object> p) {
        String term = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'search_term', 'partner_name', 'name' }));
        if (String.isBlank(term)) return AgenticSkillsBase.errorJson('Missing required parameter: search_term');
        PartnerSource src = resolvePartnerSource();
        if (src == null) return AgenticSkillsBase.errorJson('No partner object (Partner__c or Account) is accessible in this org.');
        List<SObject> all = AgenticSkillsBase.fuzzyQueryMulti(
            src.objectApi, new List<String>{ src.nameField }, src.extraFields, term
        );
        if (String.isNotBlank(src.whereClause) && !all.isEmpty()) {
            List<SObject> filtered = new List<SObject>();
            for (SObject r : all) {
                if (matchesPartnerFilter(r, src)) filtered.add(r);
            }
            all = filtered;
        }
        if (all.isEmpty()) return AgenticSkillsBase.errorJson('No partner found matching "' + term + '".');
        Map<String, Object> sliced = AgenticSkillsBase.applyTopNAndCount(all, AgenticSkillsBase.FUZZY_DISPLAY_LIMIT);
        List<SObject> top = (List<SObject>) sliced.get('rows');
        List<Map<String, Object>> records = new List<Map<String, Object>>();
        for (SObject r : top) {
            Id rid = (Id) r.get('Id');
            Map<String, Object> row = new Map<String, Object>{
                'Id' => rid, 'Name' => r.get(src.nameField), 'object' => src.objectApi,
                'recordUrl' => AgenticSkillsBase.recordUrl(rid),
                'viewRecord' => AgenticSkillsBase.viewRecordAnchor(rid)
            };
            for (String f : src.extraFields) row.put(f, r.get(f));
            records.add(row);
        }
        return AgenticSkillsBase.successJson(new Map<String, Object>{
            'status' => 'found', 'sourceObject' => src.objectApi,
            'totalFound' => sliced.get('totalFound'),
            'displayed' => sliced.get('displayed'),
            'remaining' => sliced.get('remaining'),
            'records' => records
        });
    }

    private Boolean matchesPartnerFilter(SObject r, PartnerSource src) {
        if (src.objectApi != 'Account') return true;
        Map<String, Schema.SObjectField> fmap = Schema.sObjectType.Account.fields.getMap();
        if (fmap.containsKey('IsPartner')) {
            Object v = r.get('IsPartner');
            return v == true || String.valueOf(v).equalsIgnoreCase('true');
        }
        String t = String.valueOf(r.get('Type'));
        return String.isNotBlank(t) && t.toLowerCase().contains('partner');
    }

    private String handleFetchPartnerAccount(Map<String, Object> p) {
        String pid = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonBlank(p, new List<String>{
            'Id', 'id', 'AccountId', 'partner_id', 'account_id', 'recordId'
        }));
        if (String.isBlank(pid)) return AgenticSkillsBase.errorJson('Missing required parameter: Id (partner Account Id).');
        PartnerSource src = resolvePartnerSource();
        if (src == null) return AgenticSkillsBase.errorJson('No partner object is accessible in this org.');
        List<String> fields = new List<String>{ 'Id', src.nameField };
        fields.addAll(src.extraFields);
        String soql = 'SELECT ' + String.join(fields, ', ') + ' FROM ' + src.objectApi + ' WHERE Id = :pid WITH USER_MODE LIMIT 1';
        List<SObject> rows = Database.query(soql);
        if (rows.isEmpty()) return AgenticSkillsBase.errorJson('No partner found for provided Id.');
        SObject r = rows[0];
        Map<String, Object> result = new Map<String, Object>{
            'object' => src.objectApi, 'recordUrl' => AgenticSkillsBase.recordUrl((Id) r.get('Id'))
        };
        for (String f : fields) result.put(f, r.get(f));
        if (src.objectApi == 'Partner__c') {
            Map<String, Schema.SObjectField> fmap = Schema.getGlobalDescribe().get('Partner__c').getDescribe().fields.getMap();
            if (fmap.containsKey('Account__c') && r.get('Account__c') != null && Schema.sObjectType.Account.isAccessible()) {
                Id linkedAccountId = (Id) r.get('Account__c');
                List<Account> accts = [
                    SELECT Id, Name, Type, Industry
                    FROM Account
                    WHERE Id = :linkedAccountId
                    WITH USER_MODE
                    LIMIT 1
                ];
                if (!accts.isEmpty()) {
                    result.put('linkedAccount', new Map<String, Object>{
                        'Id' => accts[0].Id, 'Name' => accts[0].Name,
                        'Type' => accts[0].Type, 'Industry' => accts[0].Industry
                    });
                }
            }
        }
        return AgenticSkillsBase.successJson(result);
    }

    private String handleAddOpportunityPartner(Map<String, Object> p) {
        Id oid = AgenticSkillsBase.resolveLookupId(p, 'OpportunityId');
        if (oid == null) {
            oid = AgenticSkillsBase.parseSalesforceId(AgenticSkillsBase.toText(
                AgenticSkillsBase.firstNonBlank(p, new List<String>{ 'opportunity_id', 'recordId', 'Id' })
            ));
        }
        if (oid == null) return AgenticSkillsBase.errorHtml('Could not add opportunity partner', 'Missing parameter: OpportunityId');
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        if (gd.containsKey('OpportunityPartner') && gd.get('OpportunityPartner').getDescribe().isCreateable()) {
            return addStandardOpportunityPartner(p, String.valueOf(oid));
        }
        if (gd.containsKey('Partner__c') && gd.get('Partner__c').getDescribe().isCreateable()) {
            return addCustomPartnerLink(p, oid);
        }
        return AgenticSkillsBase.errorHtml(
            'Could not add opportunity partner',
            'Neither OpportunityPartner nor Partner__c is available for partner linking in this org.'
        );
    }

    private String addStandardOpportunityPartner(Map<String, Object> p, String oid) {
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, new Set<String>{
            'opportunity_id', 'OpportunityId', 'recordId', 'Id', 'Role', 'role', 'AccountId', 'account_id'
        });
        fields.put('OpportunityId', oid);
        Id acctId = AgenticSkillsBase.resolveLookupId(p, 'AccountId');
        if (acctId == null) {
            acctId = AgenticSkillsBase.parseSalesforceId(AgenticSkillsBase.toText(
                AgenticSkillsBase.firstNonBlank(p, new List<String>{ 'account_id', 'partner_account_id', 'AccountToId' })
            ));
        }
        if (acctId == null && !fields.containsKey('AccountToId')) {
            return AgenticSkillsBase.errorHtml('Could not add opportunity partner', 'AccountId (partner account) is required.');
        }
        if (acctId != null) fields.put('AccountToId', acctId);
        String role = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonBlank(p, new List<String>{ 'Role', 'role' }));
        if (String.isNotBlank(role)) fields.put('Role', role);
        if (!fields.containsKey('Role') || AgenticSkillsBase.isBlankish(fields.get('Role'))) {
            fields.put('Role', 'Partner');
        }
        try {
            SObject op = Schema.getGlobalDescribe().get('OpportunityPartner').newSObject();
            AgenticSkillsBase.applyFieldsToSObject(op, fields, false);
            insert op;
            String body = '<ul><li><b>Opportunity:</b> ' + AgenticSkillsBase.escapeHtml(oid) + '</li>'
                        + '<li><b>Partner Account:</b> ' + AgenticSkillsBase.escapeHtml(String.valueOf(fields.get('AccountToId'))) + '</li></ul>';
            return AgenticSkillsBase.successHtml('Opportunity Partner Added', body, (Id) op.get('Id'), 'View Partner Role');
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not add opportunity partner', ex.getMessage());
        }
    }

    private String addCustomPartnerLink(Map<String, Object> p, String oid) {
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, new Set<String>{ 'opportunity_id', 'recordId' });
        Map<String, Schema.SObjectField> fmap = Schema.getGlobalDescribe().get('Partner__c').getDescribe().fields.getMap();
        if (fmap.containsKey('Opportunity__c')) fields.put('Opportunity__c', oid);
        else return AgenticSkillsBase.errorHtml('Could not add opportunity partner', 'Partner__c has no Opportunity__c lookup field.');
        try {
            SObject partner = Schema.getGlobalDescribe().get('Partner__c').newSObject();
            AgenticSkillsBase.applyFieldsToSObject(partner, fields, false);
            insert partner;
            return AgenticSkillsBase.successHtml('Partner Record Created', '<ul><li>Linked to opportunity.</li></ul>', (Id) partner.get('Id'), 'View Partner');
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not add opportunity partner', ex.getMessage());
        }
    }
}
