/**
 * @description Standard Quote object skills for the GPTfy Agent Library (6 skills).
 *              Uses dynamic describe so the class compiles when Quotes are not enabled.
 * @author      : Plumcloud Labs
 * @group       : GPTfy Agent Library
 * @jira        : V2-8418
 */
global with sharing class QuoteAgenticSkillsHandler implements ccai.AIAgenticInterface {

    private static Schema.SObjectType quoteType() {
        return Schema.getGlobalDescribe().get('Quote');
    }
    private static Schema.SObjectType quoteLineType() {
        return Schema.getGlobalDescribe().get('QuoteLineItem');
    }

    global String executeMethod(String methodName, Map<String, Object> parameters) {
        try {
            if (parameters == null) parameters = new Map<String, Object>();
            String m = String.isBlank(methodName) ? '' : methodName.trim();
            switch on m {
                when 'fuzzy_search_quotes' { return handleFuzzySearchQuotes(parameters); }
                when 'fetch_quote_details' { return handleFetchQuoteDetails(parameters); }
                when 'create_quote' { return handleCreateQuote(parameters); }
                when 'update_quote_fields' { return handleUpdateQuoteFields(parameters); }
                when 'add_quote_line_item' { return handleAddQuoteLineItem(parameters); }
                when 'update_quote_line_item' { return handleUpdateQuoteLineItem(parameters); }
                when else { return AgenticSkillsBase.errorJson('Unsupported skill: ' + methodName); }
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'QuoteAgenticSkillsHandler | ' + methodName + ' | ' + ex.getMessage());
            return AgenticSkillsBase.errorJson(ex.getMessage());
        }
    }

    private String handleFuzzySearchQuotes(Map<String, Object> p) {
        String term = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'search_term', 'searchTerm', 'quote_name', 'name', 'Name' }));
        if (String.isBlank(term)) return AgenticSkillsBase.errorJson('Missing required parameter: search_term');
        Schema.SObjectType qt = quoteType();
        if (qt == null || !qt.getDescribe().isAccessible()) {
            return AgenticSkillsBase.errorJson('Quote is not available or accessible in this org (enable Quotes).');
        }
        List<SObject> all = AgenticSkillsBase.fuzzyQueryMulti(
            'Quote',
            new List<String>{ 'Name', 'QuoteNumber' },
            new List<String>{ 'Status', 'GrandTotal', 'OpportunityId' },
            term
        );
        if (all.isEmpty()) return AgenticSkillsBase.errorJson('No quote found matching "' + term + '".');
        Map<String, Object> sliced = AgenticSkillsBase.applyTopNAndCount(all, AgenticSkillsBase.FUZZY_DISPLAY_LIMIT);
        List<SObject> top = (List<SObject>) sliced.get('rows');
        List<Map<String, Object>> records = new List<Map<String, Object>>();
        for (SObject r : top) {
            Id rid = (Id) r.get('Id');
            records.add(new Map<String, Object>{
                'Id' => rid, 'Name' => r.get('Name'), 'QuoteNumber' => r.get('QuoteNumber'),
                'Status' => r.get('Status'), 'GrandTotal' => r.get('GrandTotal'),
                'OpportunityId' => r.get('OpportunityId'),
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

    private String handleFetchQuoteDetails(Map<String, Object> p) {
        String qid = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'quote_id', 'recordId', 'Id' }));
        if (String.isBlank(qid)) return AgenticSkillsBase.errorJson('Missing required parameter: quote_id');
        Schema.SObjectType qt = quoteType();
        if (qt == null || !qt.getDescribe().isAccessible()) {
            return AgenticSkillsBase.errorJson('Quote is not available or accessible in this org (enable Quotes).');
        }
        List<SObject> rows = Database.query(
            'SELECT Id, Name, QuoteNumber, Status, GrandTotal, Subtotal, TotalPrice, Discount,'
            + ' ExpirationDate, Description, OpportunityId, Opportunity.Name,'
            + ' AccountId, Account.Name, OwnerId, Owner.Name, Pricebook2Id'
            + ' FROM Quote WHERE Id = :qid WITH USER_MODE LIMIT 1'
        );
        if (rows.isEmpty()) return AgenticSkillsBase.errorJson('No quote found for provided Id.');
        SObject q = rows[0];
        SObject opp = q.getSObject('Opportunity');
        SObject acc = q.getSObject('Account');
        SObject owner = q.getSObject('Owner');
        return AgenticSkillsBase.successJson(new Map<String, Object>{
            'Id' => q.get('Id'), 'Name' => q.get('Name'), 'QuoteNumber' => q.get('QuoteNumber'),
            'Status' => q.get('Status'), 'GrandTotal' => q.get('GrandTotal'), 'Subtotal' => q.get('Subtotal'),
            'TotalPrice' => q.get('TotalPrice'), 'Discount' => q.get('Discount'),
            'ExpirationDate' => String.valueOf(q.get('ExpirationDate')), 'Description' => q.get('Description'),
            'Opportunity' => opp != null ? opp.get('Name') : null,
            'Account' => acc != null ? acc.get('Name') : null,
            'Owner' => owner != null ? owner.get('Name') : null,
            'Pricebook2Id' => q.get('Pricebook2Id'),
            'recordUrl' => AgenticSkillsBase.recordUrl((Id) q.get('Id'))
        });
    }

    private String handleCreateQuote(Map<String, Object> p) {
        Schema.SObjectType qt = quoteType();
        if (qt == null || !qt.getDescribe().isCreateable()) {
            return AgenticSkillsBase.errorHtml('Could not create quote', 'Quote is not creatable (enable Quotes).');
        }
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, new Set<String>{ 'Id', 'id', 'recordId' });
        Id opportunityId = AgenticSkillsBase.resolveLookupId(p, 'OpportunityId');
        if (opportunityId != null) fields.put('OpportunityId', opportunityId);
        if (!fields.containsKey('Name') || String.isBlank(AgenticSkillsBase.toText(fields.get('Name')))) {
            return AgenticSkillsBase.errorHtml('Could not create quote', 'Quote Name is required.');
        }
        if (!fields.containsKey('OpportunityId') || AgenticSkillsBase.isBlankish(fields.get('OpportunityId'))) {
            return AgenticSkillsBase.errorHtml('Could not create quote', 'OpportunityId is required.');
        }
        try {
            SObject q = qt.newSObject();
            AgenticSkillsBase.applyFieldsToSObject(q, fields, false);
            insert q;
            String qName = String.valueOf(q.get('Name'));
            String qStatus = q.get('Status') != null ? String.valueOf(q.get('Status')) : null;
            String body = '<ul><li><b>Name:</b> ' + AgenticSkillsBase.escapeHtml(qName) + '</li>'
                        + (String.isNotBlank(qStatus) ? '<li><b>Status:</b> ' + AgenticSkillsBase.escapeHtml(qStatus) + '</li>' : '')
                        + '</ul>';
            return AgenticSkillsBase.successHtml('Quote Created', body, (Id) q.get('Id'), 'View Quote');
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not create quote', ex.getMessage());
        }
    }

    private String handleUpdateQuoteFields(Map<String, Object> p) {
        String qid = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'quote_id', 'recordId', 'Id' }));
        if (String.isBlank(qid)) return AgenticSkillsBase.errorHtml('Could not update quote', 'Missing parameter: quote_id');
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, new Set<String>{ 'quote_id', 'recordId', 'Id' });
        if (fields.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update quote', 'Missing parameter: at least one field to update');
        Schema.SObjectType qt = quoteType();
        if (qt == null || !qt.getDescribe().isUpdateable()) {
            return AgenticSkillsBase.errorHtml('Could not update quote', 'Quote is not updateable.');
        }
        List<SObject> rows = Database.query('SELECT Id, Name FROM Quote WHERE Id = :qid WITH USER_MODE LIMIT 1');
        if (rows.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update quote', 'No quote found for provided Id.');
        return AgenticSkillsBase.performGenericUpdate('Quote', qid, fields, 'Quote Updated', 'View Quote', String.valueOf(rows[0].get('Name')));
    }

    private String handleAddQuoteLineItem(Map<String, Object> p) {
        Id qid = AgenticSkillsBase.resolveLookupId(p, 'QuoteId');
        if (qid == null) {
            qid = AgenticSkillsBase.parseSalesforceId(AgenticSkillsBase.toText(
                AgenticSkillsBase.firstNonBlank(p, new List<String>{ 'quote_id', 'recordId', 'Id' })
            ));
        }
        if (qid == null) return AgenticSkillsBase.errorHtml('Could not add quote line item', 'Missing parameter: QuoteId');
        Object qtyRaw = AgenticSkillsBase.firstNonBlank(p, new List<String>{ 'Quantity', 'quantity' });
        Object priceRaw = AgenticSkillsBase.firstNonBlank(p, new List<String>{ 'UnitPrice', 'unit_price', 'unitPrice' });
        if (qtyRaw == null) return AgenticSkillsBase.errorHtml('Could not add quote line item', 'Missing parameter: Quantity');
        if (priceRaw == null) return AgenticSkillsBase.errorHtml('Could not add quote line item', 'Missing parameter: UnitPrice');
        Schema.SObjectType qlt = quoteLineType();
        if (qlt == null || !qlt.getDescribe().isCreateable()) {
            return AgenticSkillsBase.errorHtml('Could not add quote line item', 'QuoteLineItem is not creatable.');
        }
        List<SObject> quotes = Database.query('SELECT Id, Pricebook2Id FROM Quote WHERE Id = :qid WITH USER_MODE LIMIT 1');
        if (quotes.isEmpty()) return AgenticSkillsBase.errorHtml('Could not add quote line item', 'No quote found for provided QuoteId.');
        Id pbeId;
        String pbeRaw = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonBlank(p, new List<String>{
            'PricebookEntryId', 'pricebook_entry_id', 'pricebookEntryId'
        }));
        if (String.isNotBlank(pbeRaw)) {
            try { pbeId = Id.valueOf(pbeRaw); } catch (Exception e) {
                return AgenticSkillsBase.errorHtml('Could not add quote line item', 'Invalid PricebookEntryId.');
            }
        } else {
            String pname = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonBlank(p, new List<String>{
                'Name', 'product_name', 'Product2Id'
            }));
            if (String.isBlank(pname)) return AgenticSkillsBase.errorHtml('Could not add quote line item', 'Provide PricebookEntryId or product Name.');
            Id pbId = (Id) quotes[0].get('Pricebook2Id');
            List<PricebookEntry> pbes = [
                SELECT Id FROM PricebookEntry
                WHERE Product2.Name = :pname AND IsActive = true AND Pricebook2Id = :pbId
                WITH USER_MODE LIMIT 1
            ];
            if (pbes.isEmpty()) {
                return AgenticSkillsBase.errorHtml('Could not add quote line item', 'No active PricebookEntry found for "' + pname + '" on this quote\'s pricebook.');
            }
            pbeId = pbes[0].Id;
        }
        try {
            SObject qli = qlt.newSObject();
            qli.put('QuoteId', qid);
            qli.put('PricebookEntryId', pbeId);
            qli.put('Quantity', Decimal.valueOf(String.valueOf(qtyRaw)));
            qli.put('UnitPrice', Decimal.valueOf(String.valueOf(priceRaw)));
            insert qli;
            String body = '<ul><li><b>Quantity:</b> ' + AgenticSkillsBase.escapeHtml(String.valueOf(qtyRaw)) + '</li>'
                        + '<li><b>Unit Price:</b> ' + AgenticSkillsBase.escapeHtml(String.valueOf(priceRaw)) + '</li></ul>';
            return AgenticSkillsBase.successHtml('Quote Line Item Added', body, (Id) qli.get('Id'), 'View Line Item');
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not add quote line item', ex.getMessage());
        }
    }

    private String handleUpdateQuoteLineItem(Map<String, Object> p) {
        String qliId = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'line_item_id', 'quote_line_item_id', 'recordId', 'Id' }));
        if (String.isBlank(qliId)) return AgenticSkillsBase.errorHtml('Could not update quote line item', 'Missing parameter: line_item_id');
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, new Set<String>{ 'line_item_id', 'quote_line_item_id', 'recordId', 'Id', 'quote_id' });
        if (fields.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update quote line item', 'Missing parameter: at least one field to update');
        Schema.SObjectType qlt = quoteLineType();
        if (qlt == null || !qlt.getDescribe().isUpdateable()) {
            return AgenticSkillsBase.errorHtml('Could not update quote line item', 'QuoteLineItem is not updateable.');
        }
        List<SObject> rows = Database.query(
            'SELECT Id, Quantity, UnitPrice FROM QuoteLineItem WHERE Id = :qliId WITH USER_MODE LIMIT 1'
        );
        if (rows.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update quote line item', 'No line item found for provided Id.');
        String label = 'Line item (' + String.valueOf(rows[0].get('Quantity')) + ' @ ' + String.valueOf(rows[0].get('UnitPrice')) + ')';
        return AgenticSkillsBase.performGenericUpdate('QuoteLineItem', qliId, fields, 'Quote Line Item Updated', 'View Line Item', label);
    }
}
