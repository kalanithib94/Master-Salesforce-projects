/**
 * @description Industry cloud skills (FSC, Health) for the GPTfy Agent Library.
 * @author      : Plumcloud Labs
 * @group       : GPTfy Agent Library
 * @jira        : V2-8418
 */
global with sharing class IndustryAgenticSkillsHandler implements ccai.AIAgenticInterface {

    global String executeMethod(String methodName, Map<String, Object> parameters) {
        try {
            if (parameters == null) parameters = new Map<String, Object>();
            String m = String.isBlank(methodName) ? '' : methodName.trim();
            switch on m {
                when 'fetch_financial_account'          { return handleFetchFinancialAccount(parameters); }
                when 'update_financial_account_fields'  { return handleUpdateFinancialAccountFields(parameters); }
                when 'fetch_care_plan'                  { return handleFetchCarePlan(parameters); }
                when 'create_care_task'                 { return handleCreateCareTask(parameters); }
                when 'update_care_plan_fields'          { return handleUpdateCarePlanFields(parameters); }
                when else { return AgenticSkillsBase.errorJson('Unsupported skill: ' + methodName); }
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'IndustryAgenticSkillsHandler | ' + methodName + ' | ' + ex.getMessage());
            return AgenticSkillsBase.errorJson(ex.getMessage());
        }
    }

    private static String financialAccountApi() {
        for (String candidate : new List<String>{ 'FinServ__FinancialAccount__c', 'FinancialAccount__c' }) {
            Schema.SObjectType sot = Schema.getGlobalDescribe().get(candidate);
            if (sot != null && sot.getDescribe().isAccessible()) return candidate;
        }
        return null;
    }

    private static String carePlanApi() {
        for (String candidate : new List<String>{ 'CarePlan', 'HealthCloudGA__CarePlan__c', 'CarePlan__c' }) {
            Schema.SObjectType sot = Schema.getGlobalDescribe().get(candidate);
            if (sot != null && sot.getDescribe().isAccessible()) return candidate;
        }
        return null;
    }

    private String handleFetchFinancialAccount(Map<String, Object> p) {
        String faApi = financialAccountApi();
        if (faApi == null) {
            return AgenticSkillsBase.errorJson('Financial Account object (FinServ__FinancialAccount__c) is not available in this org.');
        }
        String fid = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'financial_account_id', 'recordId', 'Id' }));
        if (String.isBlank(fid)) return AgenticSkillsBase.errorJson('Missing required parameter: financial_account_id');
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(faApi);
        Map<String, Schema.SObjectField> fmap = sot.getDescribe().fields.getMap();
        List<String> fields = new List<String>{ 'Id', 'Name' };
        for (String f : new List<String>{
            'FinServ__Status__c', 'FinServ__FinancialAccountNumber__c', 'FinServ__Balance__c',
            'FinServ__PrimaryOwner__c', 'FinServ__AccountType__c', 'Status__c', 'Balance__c', 'AccountNumber__c'
        }) {
            if (fmap.containsKey(f)) fields.add(f);
        }
        String soql = 'SELECT ' + String.join(fields, ', ') + ' FROM ' + faApi + ' WHERE Id = :fid WITH USER_MODE LIMIT 1';
        List<SObject> rows = Database.query(soql);
        if (rows.isEmpty()) return AgenticSkillsBase.errorJson('No financial account found for provided Id.');
        SObject fa = rows[0];
        Map<String, Object> result = new Map<String, Object>{ 'object' => faApi, 'recordUrl' => AgenticSkillsBase.recordUrl((Id) fa.get('Id')) };
        for (String f : fields) result.put(f, fa.get(f));
        return AgenticSkillsBase.successJson(result);
    }

    private String handleUpdateFinancialAccountFields(Map<String, Object> p) {
        String faApi = financialAccountApi();
        if (faApi == null) return AgenticSkillsBase.errorHtml('Could not update financial account', 'FinServ__FinancialAccount__c is not available in this org.');
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(faApi);
        if (!sot.getDescribe().isUpdateable()) return AgenticSkillsBase.errorHtml('Could not update financial account', faApi + ' is not updateable.');
        String fid = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'financial_account_id', 'recordId', 'Id' }));
        if (String.isBlank(fid)) return AgenticSkillsBase.errorHtml('Could not update financial account', 'Missing parameter: financial_account_id');
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, new Set<String>{ 'financial_account_id', 'recordId', 'Id' });
        if (fields.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update financial account', 'Missing parameter: at least one field to update');
        List<SObject> rows = Database.query('SELECT Id, Name FROM ' + faApi + ' WHERE Id = :fid WITH USER_MODE LIMIT 1');
        if (rows.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update financial account', 'No financial account found for provided Id.');
        return AgenticSkillsBase.performGenericUpdate(faApi, fid, fields, 'Financial Account Updated', 'View Financial Account', String.valueOf(rows[0].get('Name')));
    }

    private String handleFetchCarePlan(Map<String, Object> p) {
        String cpApi = carePlanApi();
        if (cpApi == null) return AgenticSkillsBase.errorJson('Care Plan object is not available in this org.');
        String cpid = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'care_plan_id', 'recordId', 'Id' }));
        if (String.isBlank(cpid)) return AgenticSkillsBase.errorJson('Missing required parameter: care_plan_id');
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(cpApi);
        Map<String, Schema.SObjectField> fmap = sot.getDescribe().fields.getMap();
        List<String> fields = new List<String>{ 'Id', 'Name' };
        for (String f : new List<String>{ 'Status', 'StartDate', 'EndDate', 'Description', 'SubjectId', 'CaseId', 'AccountId' }) {
            if (fmap.containsKey(f)) fields.add(f);
        }
        String soql = 'SELECT ' + String.join(fields, ', ') + ' FROM ' + cpApi + ' WHERE Id = :cpid WITH USER_MODE LIMIT 1';
        List<SObject> rows = Database.query(soql);
        if (rows.isEmpty()) return AgenticSkillsBase.errorJson('No care plan found for provided Id.');
        SObject cp = rows[0];
        Map<String, Object> result = new Map<String, Object>{ 'object' => cpApi, 'recordUrl' => AgenticSkillsBase.recordUrl((Id) cp.get('Id')) };
        for (String f : fields) result.put(f, cp.get(f));
        return AgenticSkillsBase.successJson(result);
    }

    private String handleCreateCareTask(Map<String, Object> p) {
        Id whatId = AgenticSkillsBase.resolveLookupId(p, 'WhatId');
        if (whatId == null) {
            whatId = AgenticSkillsBase.parseSalesforceId(AgenticSkillsBase.toText(
                AgenticSkillsBase.firstNonBlank(p, new List<String>{ 'care_plan_id', 'CarePlanId', 'recordId', 'Id' })
            ));
        }
        if (whatId == null) return AgenticSkillsBase.errorHtml('Could not create care task', 'Missing parameter: WhatId (care plan / parent record).');
        if (!Schema.sObjectType.Task.isCreateable()) return AgenticSkillsBase.errorHtml('Could not create care task', 'Task is not creatable.');
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, new Set<String>{
            'care_plan_id', 'CarePlanId', 'WhatId', 'recordId', 'Id', 'id'
        });
        if (!fields.containsKey('Subject') || String.isBlank(AgenticSkillsBase.toText(fields.get('Subject')))) {
            return AgenticSkillsBase.errorHtml('Could not create care task', 'Subject is required.');
        }
        try {
            Task t = new Task();
            AgenticSkillsBase.applyFieldsToSObject(t, fields, false);
            t.WhatId = whatId;
            if (!fields.containsKey('Status') || AgenticSkillsBase.isBlankish(fields.get('Status'))) {
                t.Status = 'Not Started';
            }
            if (!fields.containsKey('Priority') || AgenticSkillsBase.isBlankish(fields.get('Priority'))) {
                t.Priority = 'Normal';
            }
            insert t;
            String body = '<ul><li><b>Subject:</b> ' + AgenticSkillsBase.escapeHtml(String.valueOf(fields.get('Subject'))) + '</li>'
                        + '<li><b>WhatId:</b> ' + AgenticSkillsBase.escapeHtml(String.valueOf(whatId)) + '</li></ul>';
            return AgenticSkillsBase.successHtml('Care Task Created', body, t.Id, 'View Task');
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not create care task', ex.getMessage());
        }
    }

    private String handleUpdateCarePlanFields(Map<String, Object> p) {
        String cpApi = carePlanApi();
        if (cpApi == null) return AgenticSkillsBase.errorHtml('Could not update care plan', 'Care Plan object is not available in this org.');
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(cpApi);
        if (!sot.getDescribe().isUpdateable()) return AgenticSkillsBase.errorHtml('Could not update care plan', cpApi + ' is not updateable.');
        String cpid = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'care_plan_id', 'recordId', 'Id' }));
        if (String.isBlank(cpid)) return AgenticSkillsBase.errorHtml('Could not update care plan', 'Missing parameter: care_plan_id');
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, new Set<String>{ 'care_plan_id', 'recordId', 'Id' });
        if (fields.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update care plan', 'Missing parameter: at least one field to update');
        List<SObject> rows = Database.query('SELECT Id, Name FROM ' + cpApi + ' WHERE Id = :cpid WITH USER_MODE LIMIT 1');
        if (rows.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update care plan', 'No care plan found for provided Id.');
        return AgenticSkillsBase.performGenericUpdate(cpApi, cpid, fields, 'Care Plan Updated', 'View Care Plan', String.valueOf(rows[0].get('Name')));
    }
}
