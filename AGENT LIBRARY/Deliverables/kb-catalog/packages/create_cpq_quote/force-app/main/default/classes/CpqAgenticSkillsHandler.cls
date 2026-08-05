/**
 * @description Salesforce CPQ skills for the GPTfy Agent Library.
 * @author      : Plumcloud Labs
 * @group       : GPTfy Agent Library
 * @jira        : V2-8418
 */
global with sharing class CpqAgenticSkillsHandler implements ccai.AIAgenticInterface {

    private static final String QUOTE_OBJ = 'SBQQ__Quote__c';
    private static final String LINE_OBJ = 'SBQQ__QuoteLine__c';

    global String executeMethod(String methodName, Map<String, Object> parameters) {
        try {
            if (parameters == null) parameters = new Map<String, Object>();
            String m = String.isBlank(methodName) ? '' : methodName.trim();
            switch on m {
                when 'fetch_cpq_quote_details'  { return handleFetchCpqQuoteDetails(parameters); }
                when 'create_cpq_quote'         { return handleCreateCpqQuote(parameters); }
                when 'update_cpq_quote_fields'  { return handleUpdateCpqQuoteFields(parameters); }
                when 'add_cpq_quote_line'       { return handleAddCpqQuoteLine(parameters); }
                when 'update_cpq_quote_line'     { return handleUpdateCpqQuoteLine(parameters); }
                when 'calculate_cpq_quote'       { return handleCalculateCpqQuote(parameters); }
                when else { return AgenticSkillsBase.errorJson('Unsupported skill: ' + methodName); }
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'CpqAgenticSkillsHandler | ' + methodName + ' | ' + ex.getMessage());
            return AgenticSkillsBase.errorJson(ex.getMessage());
        }
    }

    private static Schema.SObjectType quoteType() {
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(QUOTE_OBJ);
        return (sot != null && sot.getDescribe().isAccessible()) ? sot : null;
    }

    private static Schema.SObjectType lineType() {
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(LINE_OBJ);
        return (sot != null && sot.getDescribe().isAccessible()) ? sot : null;
    }

    private static String cpqUnavailableMsg() {
        return 'Salesforce CPQ is not installed or SBQQ__Quote__c / SBQQ__QuoteLine__c are not accessible in this org.';
    }

    private static String cpqUnavailableJson() {
        return AgenticSkillsBase.errorJson(cpqUnavailableMsg());
    }

    private String handleFetchCpqQuoteDetails(Map<String, Object> p) {
        Schema.SObjectType sot = quoteType();
        if (sot == null) return cpqUnavailableJson();
        String qid = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'quote_id', 'cpq_quote_id', 'recordId', 'Id' }));
        if (String.isBlank(qid)) return AgenticSkillsBase.errorJson('Missing required parameter: quote_id');
        Map<String, Schema.SObjectField> fmap = sot.getDescribe().fields.getMap();
        List<String> fields = new List<String>{ 'Id', 'Name' };
        for (String f : new List<String>{
            'SBQQ__Account__c', 'SBQQ__Opportunity2__c', 'SBQQ__Status__c', 'SBQQ__Type__c',
            'SBQQ__NetAmount__c', 'SBQQ__CustomerAmount__c', 'SBQQ__ExpirationDate__c'
        }) {
            if (fmap.containsKey(f)) fields.add(f);
        }
        String soql = 'SELECT ' + String.join(fields, ', ') + ' FROM SBQQ__Quote__c WHERE Id = :qid WITH USER_MODE LIMIT 1';
        List<SObject> rows = Database.query(soql);
        if (rows.isEmpty()) return AgenticSkillsBase.errorJson('No CPQ quote found for provided Id.');
        SObject q = rows[0];
        Map<String, Object> result = new Map<String, Object>{ 'recordUrl' => AgenticSkillsBase.recordUrl((Id) q.get('Id')) };
        for (String f : fields) result.put(f, q.get(f));
        if (lineType() != null) {
            String lineSoql = 'SELECT Id, Name FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :qid WITH USER_MODE ORDER BY Name ASC LIMIT 100';
            List<Map<String, Object>> lines = new List<Map<String, Object>>();
            for (SObject ln : Database.query(lineSoql)) {
                lines.add(new Map<String, Object>{ 'Id' => ln.get('Id'), 'Name' => ln.get('Name') });
            }
            result.put('lineCount', lines.size());
            result.put('lines', lines);
        }
        return AgenticSkillsBase.successJson(result);
    }

    private String handleCreateCpqQuote(Map<String, Object> p) {
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(QUOTE_OBJ);
        if (sot == null || !sot.getDescribe().isCreateable()) return AgenticSkillsBase.errorHtml('Could not create CPQ quote', cpqUnavailableMsg());
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, null);
        Map<String, Schema.SObjectField> fmap = sot.getDescribe().fields.getMap();
        Boolean hasOpp = fields.containsKey('SBQQ__Opportunity2__c') && !AgenticSkillsBase.isBlankish(fields.get('SBQQ__Opportunity2__c'));
        Boolean hasAcct = fields.containsKey('SBQQ__Account__c') && !AgenticSkillsBase.isBlankish(fields.get('SBQQ__Account__c'));
        if (!hasOpp && !hasAcct) {
            return AgenticSkillsBase.errorHtml('Could not create CPQ quote', 'SBQQ__Opportunity2__c or SBQQ__Account__c is required.');
        }
        try {
            SObject q = sot.newSObject();
            AgenticSkillsBase.applyFieldsToSObject(q, fields, false);
            insert q;
            String label = fmap.containsKey('Name') ? String.valueOf(q.get('Name')) : 'CPQ Quote';
            return AgenticSkillsBase.successHtml('CPQ Quote Created', '<ul><li><b>Name:</b> ' + AgenticSkillsBase.escapeHtml(label) + '</li></ul>', (Id) q.get('Id'), 'View CPQ Quote');
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not create CPQ quote', ex.getMessage());
        }
    }

    private String handleUpdateCpqQuoteFields(Map<String, Object> p) {
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(QUOTE_OBJ);
        if (sot == null || !sot.getDescribe().isUpdateable()) return AgenticSkillsBase.errorHtml('Could not update CPQ quote', cpqUnavailableMsg());
        String qid = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'quote_id', 'cpq_quote_id', 'recordId', 'Id' }));
        if (String.isBlank(qid)) return AgenticSkillsBase.errorHtml('Could not update CPQ quote', 'Missing parameter: quote_id');
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, new Set<String>{ 'quote_id', 'cpq_quote_id', 'recordId', 'Id' });
        if (fields.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update CPQ quote', 'Missing parameter: at least one field to update');
        List<SObject> rows = Database.query('SELECT Id, Name FROM SBQQ__Quote__c WHERE Id = :qid WITH USER_MODE LIMIT 1');
        if (rows.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update CPQ quote', 'No CPQ quote found for provided Id.');
        return AgenticSkillsBase.performGenericUpdate(QUOTE_OBJ, qid, fields, 'CPQ Quote Updated', 'View CPQ Quote', String.valueOf(rows[0].get('Name')));
    }

    private String handleAddCpqQuoteLine(Map<String, Object> p) {
        Schema.SObjectType sot = lineType();
        if (sot == null || !sot.getDescribe().isCreateable()) return AgenticSkillsBase.errorHtml('Could not add CPQ quote line', cpqUnavailableMsg());
        // Parent: SBQQ__QuoteLine__c.SBQQ__Quote__c
        Id qid = AgenticSkillsBase.parseSalesforceId(AgenticSkillsBase.toText(
            AgenticSkillsBase.firstNonBlank(p, new List<String>{
                'SBQQ__Quote__c', 'QuoteId', 'quoteId', 'quote_id', 'cpq_quote_id', 'Id'
            })
        ));
        if (qid == null) return AgenticSkillsBase.errorHtml('Could not add CPQ quote line', 'Missing parameter: SBQQ__Quote__c (parent CPQ Quote Id).');
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, new Set<String>{
            'SBQQ__Quote__c', 'QuoteId', 'quoteId', 'quote_id', 'cpq_quote_id', 'Id', 'recordId'
        });
        fields.put('SBQQ__Quote__c', qid);
        Map<String, Schema.SObjectField> fmap = sot.getDescribe().fields.getMap();
        Boolean hasProduct = fields.containsKey('SBQQ__Product__c') && !AgenticSkillsBase.isBlankish(fields.get('SBQQ__Product__c'));
        if (!hasProduct && fmap.containsKey('SBQQ__Product__c')) {
            return AgenticSkillsBase.errorHtml('Could not add CPQ quote line', 'SBQQ__Product__c is required.');
        }
        try {
            SObject line = sot.newSObject();
            AgenticSkillsBase.applyFieldsToSObject(line, fields, false);
            insert line;
            String body = '<ul><li><b>Quote:</b> ' + AgenticSkillsBase.escapeHtml(String.valueOf(qid)) + '</li></ul>';
            return AgenticSkillsBase.successHtml('CPQ Quote Line Added', body, (Id) line.get('Id'), 'View Quote Line');
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not add CPQ quote line', ex.getMessage());
        }
    }

    private String handleUpdateCpqQuoteLine(Map<String, Object> p) {
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(LINE_OBJ);
        if (sot == null || !sot.getDescribe().isUpdateable()) return AgenticSkillsBase.errorHtml('Could not update CPQ quote line', cpqUnavailableMsg());
        String lid = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'quote_line_id', 'line_id', 'recordId', 'Id' }));
        if (String.isBlank(lid)) return AgenticSkillsBase.errorHtml('Could not update CPQ quote line', 'Missing parameter: quote_line_id');
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, new Set<String>{ 'quote_line_id', 'line_id', 'recordId', 'Id', 'quote_id', 'cpq_quote_id' });
        if (fields.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update CPQ quote line', 'Missing parameter: at least one field to update');
        List<SObject> rows = Database.query('SELECT Id, Name FROM SBQQ__QuoteLine__c WHERE Id = :lid WITH USER_MODE LIMIT 1');
        if (rows.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update CPQ quote line', 'No quote line found for provided Id.');
        return AgenticSkillsBase.performGenericUpdate(LINE_OBJ, lid, fields, 'CPQ Quote Line Updated', 'View Quote Line', String.valueOf(rows[0].get('Name')));
    }

    private String handleCalculateCpqQuote(Map<String, Object> p) {
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(QUOTE_OBJ);
        if (sot == null || !sot.getDescribe().isUpdateable()) return AgenticSkillsBase.errorHtml('Could not calculate CPQ quote', cpqUnavailableMsg());
        String qid = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'quote_id', 'cpq_quote_id', 'recordId', 'Id' }));
        if (String.isBlank(qid)) return AgenticSkillsBase.errorHtml('Could not calculate CPQ quote', 'Missing parameter: quote_id');
        List<SObject> rows = Database.query('SELECT Id, Name FROM SBQQ__Quote__c WHERE Id = :qid WITH USER_MODE LIMIT 1');
        if (rows.isEmpty()) return AgenticSkillsBase.errorHtml('Could not calculate CPQ quote', 'No CPQ quote found for provided Id.');
        Map<String, Schema.SObjectField> fmap = sot.getDescribe().fields.getMap();
        try {
            if (fmap.containsKey('SBQQ__Uncalculated__c') && fmap.get('SBQQ__Uncalculated__c').getDescribe().isUpdateable()) {
                SObject q = sot.newSObject((Id) qid);
                q.put('SBQQ__Uncalculated__c', true);
                update q;
                return AgenticSkillsBase.successHtml(
                    'CPQ Quote Calculation Triggered',
                    '<ul><li>Quote flagged for recalculation via SBQQ__Uncalculated__c.</li></ul>',
                    (Id) qid, 'View CPQ Quote'
                );
            }
            return AgenticSkillsBase.errorHtml(
                'Could not calculate CPQ quote',
                'CPQ QuoteCalculator API is not available. Install Salesforce CPQ or enable quote calculation fields.'
            );
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not calculate CPQ quote', ex.getMessage());
        }
    }
}
