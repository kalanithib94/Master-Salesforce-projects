/**
 * @description Service Cloud entitlement/SLA skills for the GPTfy Agent Library (2 skills).
 * @author      : Plumcloud Labs
 * @group       : GPTfy Agent Library
 * @jira        : V2-8418
 */
global with sharing class ServiceAgenticSkillsHandler implements ccai.AIAgenticInterface {

    global String executeMethod(String methodName, Map<String, Object> parameters) {
        try {
            if (parameters == null) parameters = new Map<String, Object>();
            String m = String.isBlank(methodName) ? '' : methodName.trim();
            switch on m {
                when 'fetch_case_milestones' { return handleFetchCaseMilestones(parameters); }
                when 'fetch_case_entitlements' { return handleFetchCaseEntitlements(parameters); }
                when else { return AgenticSkillsBase.errorJson('Unsupported skill: ' + methodName); }
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'ServiceAgenticSkillsHandler | ' + methodName + ' | ' + ex.getMessage());
            return AgenticSkillsBase.errorJson(ex.getMessage());
        }
    }

    private String handleFetchCaseMilestones(Map<String, Object> p) {
        String cid = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'case_id', 'recordId', 'Id' }));
        if (String.isBlank(cid)) return AgenticSkillsBase.errorJson('Missing required parameter: case_id');
        if (!Schema.sObjectType.Case.isAccessible()) return AgenticSkillsBase.errorJson('Case is not accessible.');
        Schema.SObjectType milestoneType = Schema.getGlobalDescribe().get('CaseMilestone');
        if (milestoneType == null || !milestoneType.getDescribe().isAccessible()) {
            return successJsonUnavailable('Case milestones are not available (entitlements may not be enabled).');
        }
        List<Case> cases = [SELECT Id, CaseNumber FROM Case WHERE Id = :cid WITH USER_MODE LIMIT 1];
        if (cases.isEmpty()) return AgenticSkillsBase.errorJson('No case found for provided Id.');
        try {
            List<SObject> milestones = Database.query(
                'SELECT Id, MilestoneTypeId, MilestoneType.Name, TargetDate, CompletionDate, IsCompleted, IsViolated, TimeRemainingInMins'
                + ' FROM CaseMilestone WHERE CaseId = :cid WITH USER_MODE ORDER BY TargetDate ASC LIMIT 50'
            );
            List<Map<String, Object>> rows = new List<Map<String, Object>>();
            for (SObject ms : milestones) {
                SObject mt = ms.getSObject('MilestoneType');
                rows.add(new Map<String, Object>{
                    'Id' => ms.get('Id'),
                    'MilestoneType' => mt != null ? mt.get('Name') : null,
                    'TargetDate' => String.valueOf(ms.get('TargetDate')),
                    'CompletionDate' => String.valueOf(ms.get('CompletionDate')),
                    'IsCompleted' => ms.get('IsCompleted'),
                    'IsViolated' => ms.get('IsViolated'),
                    'TimeRemainingInMins' => ms.get('TimeRemainingInMins')
                });
            }
            return AgenticSkillsBase.successJson(new Map<String, Object>{
                'caseId' => cid, 'caseNumber' => cases[0].CaseNumber,
                'count' => rows.size(), 'milestones' => rows
            });
        } catch (Exception ex) {
            return AgenticSkillsBase.errorJson('Could not fetch case milestones: ' + ex.getMessage());
        }
    }

    private String handleFetchCaseEntitlements(Map<String, Object> p) {
        String cid = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'case_id', 'recordId', 'Id' }));
        if (String.isBlank(cid)) return AgenticSkillsBase.errorJson('Missing required parameter: case_id');
        if (!Schema.sObjectType.Case.isAccessible()) return AgenticSkillsBase.errorJson('Case is not accessible.');
        Map<String, Schema.SObjectField> caseFields = Schema.sObjectType.Case.fields.getMap();
        List<String> selectFields = new List<String>{ 'Id', 'CaseNumber' };
        if (caseFields.containsKey('EntitlementId') && caseFields.get('EntitlementId').getDescribe().isAccessible()) {
            selectFields.add('EntitlementId');
            selectFields.add('Entitlement.Name');
            selectFields.add('Entitlement.Status');
            selectFields.add('Entitlement.StartDate');
            selectFields.add('Entitlement.EndDate');
        }
        if (caseFields.containsKey('SlaStartDate') && caseFields.get('SlaStartDate').getDescribe().isAccessible()) {
            selectFields.add('SlaStartDate');
        }
        if (caseFields.containsKey('SlaExitDate') && caseFields.get('SlaExitDate').getDescribe().isAccessible()) {
            selectFields.add('SlaExitDate');
        }
        if (caseFields.containsKey('IsStopped') && caseFields.get('IsStopped').getDescribe().isAccessible()) {
            selectFields.add('IsStopped');
        }
        String soql = 'SELECT ' + String.join(selectFields, ', ') + ' FROM Case WHERE Id = :cid WITH USER_MODE LIMIT 1';
        List<SObject> caseRows = Database.query(soql);
        if (caseRows.isEmpty()) return AgenticSkillsBase.errorJson('No case found for provided Id.');
        SObject ca = caseRows[0];
        Map<String, Object> result = new Map<String, Object>{
            'caseId' => ca.get('Id'),
            'caseNumber' => ca.get('CaseNumber')
        };
        SObject ent = ca.getSObject('Entitlement');
        if (ent != null) {
            result.put('entitlement', new Map<String, Object>{
                'Id' => ent.get('Id'),
                'Name' => ent.get('Name'),
                'Status' => ent.get('Status'),
                'StartDate' => String.valueOf(ent.get('StartDate')),
                'EndDate' => String.valueOf(ent.get('EndDate'))
            });
        } else if (caseFields.containsKey('EntitlementId')) {
            result.put('entitlement', null);
        }
        if (caseFields.containsKey('SlaStartDate')) result.put('slaStartDate', String.valueOf(ca.get('SlaStartDate')));
        if (caseFields.containsKey('SlaExitDate')) result.put('slaExitDate', String.valueOf(ca.get('SlaExitDate')));
        if (caseFields.containsKey('IsStopped')) result.put('isStopped', ca.get('IsStopped'));

        Schema.SObjectType entityMsType = Schema.getGlobalDescribe().get('EntityMilestone');
        if (entityMsType != null && entityMsType.getDescribe().isAccessible()) {
            try {
                List<SObject> entityMs = Database.query(
                    'SELECT Id, MilestoneTypeId, MilestoneType.Name, TargetDate, CompletionDate, IsCompleted, IsViolated'
                    + ' FROM EntityMilestone WHERE ParentId = :cid WITH USER_MODE ORDER BY TargetDate ASC LIMIT 50'
                );
                List<Map<String, Object>> emRows = new List<Map<String, Object>>();
                for (SObject em : entityMs) {
                    SObject mt = em.getSObject('MilestoneType');
                    emRows.add(new Map<String, Object>{
                        'Id' => em.get('Id'),
                        'MilestoneType' => mt != null ? mt.get('Name') : null,
                        'TargetDate' => String.valueOf(em.get('TargetDate')),
                        'CompletionDate' => String.valueOf(em.get('CompletionDate')),
                        'IsCompleted' => em.get('IsCompleted'),
                        'IsViolated' => em.get('IsViolated')
                    });
                }
                result.put('entityMilestones', emRows);
                result.put('entityMilestoneCount', emRows.size());
            } catch (Exception ex) {
                result.put('entityMilestonesStatus', 'unavailable');
            }
        }
        return AgenticSkillsBase.successJson(result);
    }

    private String successJsonUnavailable(String msg) {
        return AgenticSkillsBase.successJson(new Map<String, Object>{ 'status' => 'unavailable', 'message' => msg });
    }
}
