/**
 * @description Contract object skills for the GPTfy Agent Library (3 skills).
 * @author      : Plumcloud Labs
 * @group       : GPTfy Agent Library
 * @jira        : V2-8418
 */
global with sharing class ContractAgenticSkillsHandler implements ccai.AIAgenticInterface {

    global String executeMethod(String methodName, Map<String, Object> parameters) {
        try {
            if (parameters == null) parameters = new Map<String, Object>();
            String m = String.isBlank(methodName) ? '' : methodName.trim();
            switch on m {
                when 'fetch_contract_details' { return handleFetchContractDetails(parameters); }
                when 'create_contract' { return handleCreateContract(parameters); }
                when 'update_contract_fields' { return handleUpdateContractFields(parameters); }
                when else { return AgenticSkillsBase.errorJson('Unsupported skill: ' + methodName); }
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'ContractAgenticSkillsHandler | ' + methodName + ' | ' + ex.getMessage());
            return AgenticSkillsBase.errorJson(ex.getMessage());
        }
    }

    private String handleFetchContractDetails(Map<String, Object> p) {
        Id cid = AgenticSkillsBase.resolvePrimaryId(p, 'Contract');
        if (cid == null) return AgenticSkillsBase.errorJson('Missing required parameter: Id (Contract Id).');
        if (!Schema.sObjectType.Contract.isAccessible()) return AgenticSkillsBase.errorJson('Contract is not accessible.');
        List<Contract> rows = [
            SELECT Id, ContractNumber, AccountId, Account.Name, Status, StartDate, EndDate,
                   ContractTerm, OwnerId, Owner.Name, Description, CustomerSignedDate,
                   CompanySignedDate, SpecialTerms
            FROM Contract WHERE Id = :cid WITH USER_MODE LIMIT 1
        ];
        if (rows.isEmpty()) return AgenticSkillsBase.errorJson('No contract found for provided Id.');
        Contract c = rows[0];
        return AgenticSkillsBase.successJson(new Map<String, Object>{
            'Id' => c.Id, 'ContractNumber' => c.ContractNumber,
            'AccountId' => c.AccountId,
            'Account' => c.Account != null ? c.Account.Name : null,
            'Status' => c.Status, 'StartDate' => String.valueOf(c.StartDate),
            'EndDate' => String.valueOf(c.EndDate), 'ContractTerm' => c.ContractTerm,
            'Owner' => c.Owner != null ? c.Owner.Name : null,
            'Description' => c.Description,
            'CustomerSignedDate' => String.valueOf(c.CustomerSignedDate),
            'CompanySignedDate' => String.valueOf(c.CompanySignedDate),
            'SpecialTerms' => c.SpecialTerms,
            'recordUrl' => AgenticSkillsBase.recordUrl(c.Id)
        });
    }

    private String handleCreateContract(Map<String, Object> p) {
        if (!Schema.sObjectType.Contract.isCreateable()) {
            return AgenticSkillsBase.errorHtml('Could not create contract', 'Contract is not creatable.');
        }
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, new Set<String>{ 'Id', 'id', 'recordId' });
        Id accountId = AgenticSkillsBase.resolveLookupId(p, 'AccountId');
        if (accountId != null) fields.put('AccountId', accountId);
        if (!fields.containsKey('AccountId') || AgenticSkillsBase.isBlankish(fields.get('AccountId'))) {
            return AgenticSkillsBase.errorHtml('Could not create contract', 'AccountId is required.');
        }
        for (String required : new List<String>{ 'Status', 'ContractTerm', 'StartDate' }) {
            if (!fields.containsKey(required) || AgenticSkillsBase.isBlankish(fields.get(required))) {
                return AgenticSkillsBase.errorHtml('Could not create contract', required + ' is required.');
            }
        }
        try {
            Contract c = new Contract();
            AgenticSkillsBase.applyFieldsToSObject(c, fields, false);
            insert c;
            String body = '<ul><li><b>Contract #:</b> ' + AgenticSkillsBase.escapeHtml(c.ContractNumber) + '</li>'
                        + '<li><b>Status:</b> ' + AgenticSkillsBase.escapeHtml(c.Status) + '</li>'
                        + '<li><b>Start Date:</b> ' + AgenticSkillsBase.escapeHtml(String.valueOf(c.StartDate)) + '</li></ul>';
            return AgenticSkillsBase.successHtml('Contract Created', body, c.Id, 'View Contract');
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not create contract', ex.getMessage());
        }
    }

    private String handleUpdateContractFields(Map<String, Object> p) {
        Id cid = AgenticSkillsBase.resolvePrimaryId(p, 'Contract');
        if (cid == null) return AgenticSkillsBase.errorHtml('Could not update contract', 'Missing parameter: Id (Contract Id).');
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, new Set<String>{
            'contract_id', 'ContractId', 'recordId', 'Id', 'id'
        });
        if (fields.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update contract', 'Missing parameter: at least one field to update');
        if (!Schema.sObjectType.Contract.isUpdateable()) return AgenticSkillsBase.errorHtml('Could not update contract', 'Contract is not updateable.');
        List<Contract> rows = [SELECT Id, ContractNumber FROM Contract WHERE Id = :cid WITH USER_MODE LIMIT 1];
        if (rows.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update contract', 'No contract found for provided Id.');
        return AgenticSkillsBase.performGenericUpdate('Contract', cid, fields, 'Contract Updated', 'View Contract', rows[0].ContractNumber);
    }
}
