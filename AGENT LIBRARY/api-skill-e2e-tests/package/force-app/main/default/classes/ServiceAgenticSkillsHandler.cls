/**
 * @description Service Cloud entitlement/SLA + Asset skills for the GPTfy Agent Library.
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
                when 'fuzzy_search_assets' { return handleFuzzySearchAssets(parameters); }
                when 'fetch_asset_details' { return handleFetchAssetDetails(parameters); }
                when 'update_asset_fields' { return handleUpdateAssetFields(parameters); }
                when else { return AgenticSkillsBase.errorJson('Unsupported skill: ' + methodName); }
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'ServiceAgenticSkillsHandler | ' + methodName + ' | ' + ex.getMessage());
            return AgenticSkillsBase.errorJson(ex.getMessage());
        }
    }

    private String handleFuzzySearchAssets(Map<String, Object> p) {
        String term = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{
            'searchTerm', 'search_term', 'Name', 'name', 'SerialNumber'
        }));
        if (String.isBlank(term)) return AgenticSkillsBase.errorJson('Missing required parameter: searchTerm');
        if (!Schema.sObjectType.Asset.isAccessible()) {
            return AgenticSkillsBase.errorJson('Asset is not accessible in this org.');
        }
        List<SObject> all = AgenticSkillsBase.fuzzyQueryMulti(
            'Asset',
            new List<String>{ 'Name', 'SerialNumber' },
            new List<String>{ 'Status', 'AccountId', 'ContactId', 'Product2Id' },
            term
        );
        if (all.isEmpty()) return AgenticSkillsBase.errorJson('No asset found matching "' + term + '".');
        Map<String, Object> sliced = AgenticSkillsBase.applyTopNAndCount(all, AgenticSkillsBase.FUZZY_DISPLAY_LIMIT);
        List<SObject> top = (List<SObject>) sliced.get('rows');
        List<Map<String, Object>> records = new List<Map<String, Object>>();
        for (SObject r : top) {
            Id rid = (Id) r.get('Id');
            records.add(new Map<String, Object>{
                'Id' => rid,
                'Name' => r.get('Name'),
                'SerialNumber' => r.get('SerialNumber'),
                'Status' => r.get('Status'),
                'AccountId' => r.get('AccountId'),
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

    private String handleFetchAssetDetails(Map<String, Object> p) {
        Id aid = AgenticSkillsBase.resolvePrimaryId(p, 'Asset');
        if (aid == null) {
            aid = AgenticSkillsBase.parseSalesforceId(AgenticSkillsBase.toText(
                AgenticSkillsBase.firstNonBlank(p, new List<String>{ 'asset_id', 'AssetId', 'Id', 'recordId' })
            ));
        }
        if (aid == null) return AgenticSkillsBase.errorJson('Missing required parameter: Id (Asset Id).');
        if (!Schema.sObjectType.Asset.isAccessible()) {
            return AgenticSkillsBase.errorJson('Asset is not accessible in this org.');
        }
        List<Asset> rows = [
            SELECT Id, Name, SerialNumber, Status, InstallDate, PurchaseDate, Price,
                   AccountId, Account.Name, ContactId, Contact.Name, Product2Id, Product2.Name, Description
            FROM Asset WHERE Id = :aid WITH USER_MODE LIMIT 1
        ];
        if (rows.isEmpty()) return AgenticSkillsBase.errorJson('No asset found for provided Id.');
        Asset a = rows[0];
        return AgenticSkillsBase.successJson(new Map<String, Object>{
            'Id' => a.Id,
            'Name' => a.Name,
            'SerialNumber' => a.SerialNumber,
            'Status' => a.Status,
            'InstallDate' => String.valueOf(a.InstallDate),
            'PurchaseDate' => String.valueOf(a.PurchaseDate),
            'Price' => a.Price,
            'AccountId' => a.AccountId,
            'AccountName' => a.Account != null ? a.Account.Name : null,
            'ContactId' => a.ContactId,
            'ContactName' => a.Contact != null ? a.Contact.Name : null,
            'Product2Id' => a.Product2Id,
            'ProductName' => a.Product2 != null ? a.Product2.Name : null,
            'Description' => a.Description,
            'recordUrl' => AgenticSkillsBase.recordUrl(a.Id)
        });
    }

    private String handleUpdateAssetFields(Map<String, Object> p) {
        Id aid = AgenticSkillsBase.resolvePrimaryId(p, 'Asset');
        if (aid == null) {
            aid = AgenticSkillsBase.parseSalesforceId(AgenticSkillsBase.toText(
                AgenticSkillsBase.firstNonBlank(p, new List<String>{ 'asset_id', 'AssetId', 'Id', 'recordId' })
            ));
        }
        if (aid == null) return AgenticSkillsBase.errorHtml('Could not update asset', 'Missing parameter: Id (Asset Id).');
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, new Set<String>{
            'asset_id', 'AssetId', 'Id', 'id', 'recordId'
        });
        if (fields.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update asset', 'Missing parameter: at least one field to update');
        if (!Schema.sObjectType.Asset.isUpdateable()) {
            return AgenticSkillsBase.errorHtml('Could not update asset', 'Asset is not updateable.');
        }
        List<Asset> rows = [SELECT Id, Name FROM Asset WHERE Id = :aid WITH USER_MODE LIMIT 1];
        if (rows.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update asset', 'No asset found for provided Id.');
        return AgenticSkillsBase.performGenericUpdate('Asset', aid, fields, 'Asset Updated', 'View Asset', rows[0].Name);
    }


    private String handleFetchCaseMilestones(Map<String, Object> p) {
        Id cid = AgenticSkillsBase.resolvePrimaryId(p, 'Case');
        if (cid == null) {
            String raw = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonBlank(p, new List<String>{
                'CaseNumber', 'Subject', 'case_id', 'CaseId', 'Id', 'recordId'
            }));
            if (String.isNotBlank(raw)) cid = AgenticSkillsBase.resolveNaturalKeyValue('Case', raw);
        }
        if (cid == null) {
            return AgenticSkillsBase.errorJson('Missing case locator. Pass CaseNumber or Subject (Id optional).');
        }
        if (!Schema.sObjectType.Case.isAccessible()) return AgenticSkillsBase.errorJson('Case is not accessible.');
        Schema.SObjectType milestoneType = Schema.getGlobalDescribe().get('CaseMilestone');
        if (milestoneType == null || !milestoneType.getDescribe().isAccessible()) {
            return successJsonUnavailable('Case milestones are not available (entitlements may not be enabled).');
        }
        List<Case> cases = [SELECT Id, CaseNumber FROM Case WHERE Id = :cid WITH USER_MODE LIMIT 1];
        if (cases.isEmpty()) return AgenticSkillsBase.errorJson('No case found for provided CaseNumber/Subject/Id.');
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
                'caseId' => String.valueOf(cid), 'caseNumber' => cases[0].CaseNumber,
                'count' => rows.size(), 'milestones' => rows
            });
        } catch (Exception ex) {
            return AgenticSkillsBase.errorJson('Could not fetch case milestones: ' + ex.getMessage());
        }
    }

    private String handleFetchCaseEntitlements(Map<String, Object> p) {
        Id cid = AgenticSkillsBase.resolvePrimaryId(p, 'Case');
        if (cid == null) {
            String raw = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonBlank(p, new List<String>{
                'CaseNumber', 'Subject', 'case_id', 'CaseId', 'Id', 'recordId'
            }));
            if (String.isNotBlank(raw)) cid = AgenticSkillsBase.resolveNaturalKeyValue('Case', raw);
        }
        if (cid == null) {
            return AgenticSkillsBase.errorJson('Missing case locator. Pass CaseNumber or Subject (Id optional).');
        }
        if (!Schema.sObjectType.Case.isAccessible()) return AgenticSkillsBase.errorJson('Case is not accessible.');
        Map<String, Schema.SObjectField> caseFields = Schema.sObjectType.Case.fields.getMap();
        List<String> selectFields = new List<String>{ 'Id', 'CaseNumber' };
        if (caseFields.containsKey('EntitlementId') && caseFields.get('EntitlementId').getDescribe().isAccessible()) {
            selectFields.add('EntitlementId');
            selectFields.add('Entitlement.Id');
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
        if (caseRows.isEmpty()) return AgenticSkillsBase.errorJson('No case found for provided CaseNumber/Subject/Id.');
        SObject ca = caseRows[0];
        Map<String, Object> result = new Map<String, Object>{
            'caseId' => ca.get('Id'),
            'caseNumber' => ca.get('CaseNumber')
        };
        Set<String> selected = new Set<String>(selectFields);
        if (selected.contains('Entitlement.Name') || selected.contains('EntitlementId')) {
            SObject ent = null;
            try { ent = ca.getSObject('Entitlement'); } catch (Exception ignoreEnt) { ent = null; }
            if (ent != null) {
                Object entIdVal = null;
                try { entIdVal = ent.get('Id'); } catch (Exception ignoreId) { entIdVal = ca.get('EntitlementId'); }
                result.put('entitlement', new Map<String, Object>{
                    'Id' => entIdVal != null ? entIdVal : ca.get('EntitlementId'),
                    'Name' => safeGet(ent, 'Name'),
                    'Status' => safeGet(ent, 'Status'),
                    'StartDate' => String.valueOf(safeGet(ent, 'StartDate')),
                    'EndDate' => String.valueOf(safeGet(ent, 'EndDate'))
                });
            } else {
                result.put('entitlement', null);
                if (selected.contains('EntitlementId')) result.put('entitlementId', ca.get('EntitlementId'));
            }
        }
        if (selected.contains('SlaStartDate')) result.put('slaStartDate', String.valueOf(ca.get('SlaStartDate')));
        if (selected.contains('SlaExitDate')) result.put('slaExitDate', String.valueOf(ca.get('SlaExitDate')));
        if (selected.contains('IsStopped')) result.put('isStopped', ca.get('IsStopped'));

        Schema.SObjectType entityMsType = Schema.getGlobalDescribe().get('EntityMilestone');
        if (entityMsType != null && entityMsType.getDescribe().isAccessible()) {
            try {
                List<SObject> entityMs = Database.query(
                    'SELECT Id, MilestoneTypeId, MilestoneType.Name, TargetDate, CompletionDate, IsCompleted, IsViolated'
                    + ' FROM EntityMilestone WHERE ParentId = :cid WITH USER_MODE ORDER BY TargetDate ASC LIMIT 50'
                );
                List<Map<String, Object>> emRows = new List<Map<String, Object>>();
                for (SObject em : entityMs) {
                    SObject mt = null;
                    try { mt = em.getSObject('MilestoneType'); } catch (Exception ignoreMt) {}
                    emRows.add(new Map<String, Object>{
                        'Id' => em.get('Id'),
                        'MilestoneType' => mt != null ? safeGet(mt, 'Name') : null,
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

    private Object safeGet(SObject row, String fieldName) {
        try {
            return row.get(fieldName);
        } catch (Exception e) {
            return null;
        }
    }

    private String successJsonUnavailable(String msg) {
        return AgenticSkillsBase.successJson(new Map<String, Object>{ 'status' => 'unavailable', 'message' => msg });
    }
}
