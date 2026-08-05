/**
 * @description Standard Quote object skills for the GPTfy Agent Library (6 skills).
 * @author      : Plumcloud Labs
 * @group       : GPTfy Agent Library
 * @jira        : V2-8418
 */
global with sharing class QuoteAgenticSkillsHandler implements ccai.AIAgenticInterface {

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
        String term = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'search_term', 'quote_name', 'name' }));
        if (String.isBlank(term)) return AgenticSkillsBase.errorJson('Missing required parameter: search_term');
        if (!Schema.sObjectType.Quote.isAccessible()) return AgenticSkillsBase.errorJson('Quote is not accessible.');
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
        if (!Schema.sObjectType.Quote.isAccessible()) return AgenticSkillsBase.errorJson('Quote is not accessible.');
        List<Quote> rows = [
            SELECT Id, Name, QuoteNumber, Status, GrandTotal, Subtotal, TotalPrice, Discount,
                   ExpirationDate, Description, OpportunityId, Opportunity.Name,
                   AccountId, Account.Name, OwnerId, Owner.Name, Pricebook2Id
            FROM Quote WHERE Id = :qid WITH USER_MODE LIMIT 1
        ];
        if (rows.isEmpty()) return AgenticSkillsBase.errorJson('No quote found for provided Id.');
        Quote q = rows[0];
        return AgenticSkillsBase.successJson(new Map<String, Object>{
            'Id' => q.Id, 'Name' => q.Name, 'QuoteNumber' => q.QuoteNumber,
            'Status' => q.Status, 'GrandTotal' => q.GrandTotal, 'Subtotal' => q.Subtotal,
            'TotalPrice' => q.TotalPrice, 'Discount' => q.Discount,
            'ExpirationDate' => String.valueOf(q.ExpirationDate), 'Description' => q.Description,
            'Opportunity' => q.Opportunity != null ? q.Opportunity.Name : null,
            'Account' => q.Account != null ? q.Account.Name : null,
            'Owner' => q.Owner != null ? q.Owner.Name : null,
            'Pricebook2Id' => q.Pricebook2Id,
            'recordUrl' => AgenticSkillsBase.recordUrl(q.Id)
        });
    }

    private String handleCreateQuote(Map<String, Object> p) {
        if (!Schema.sObjectType.Quote.isCreateable()) {
            return AgenticSkillsBase.errorHtml('Could not create quote', 'Quote is not creatable.');
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
            Quote q = new Quote();
            AgenticSkillsBase.applyFieldsToSObject(q, fields, false);
            insert q;
            String body = '<ul><li><b>Name:</b> ' + AgenticSkillsBase.escapeHtml(q.Name) + '</li>'
                        + (String.isNotBlank(q.Status) ? '<li><b>Status:</b> ' + AgenticSkillsBase.escapeHtml(q.Status) + '</li>' : '')
                        + '</ul>';
            return AgenticSkillsBase.successHtml('Quote Created', body, q.Id, 'View Quote');
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not create quote', ex.getMessage());
        }
    }

    private String handleUpdateQuoteFields(Map<String, Object> p) {
        String qid = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'quote_id', 'recordId', 'Id' }));
        if (String.isBlank(qid)) return AgenticSkillsBase.errorHtml('Could not update quote', 'Missing parameter: quote_id');
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, new Set<String>{ 'quote_id', 'recordId', 'Id' });
        if (fields.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update quote', 'Missing parameter: at least one field to update');
        if (!Schema.sObjectType.Quote.isUpdateable()) return AgenticSkillsBase.errorHtml('Could not update quote', 'Quote is not updateable.');
        List<Quote> rows = [SELECT Id, Name FROM Quote WHERE Id = :qid WITH USER_MODE LIMIT 1];
        if (rows.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update quote', 'No quote found for provided Id.');
        return AgenticSkillsBase.performGenericUpdate('Quote', qid, fields, 'Quote Updated', 'View Quote', rows[0].Name);
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
        if (!Schema.sObjectType.QuoteLineItem.isCreateable()) {
            return AgenticSkillsBase.errorHtml('Could not add quote line item', 'QuoteLineItem is not creatable.');
        }
        List<Quote> quotes = [SELECT Id, Pricebook2Id FROM Quote WHERE Id = :qid WITH USER_MODE LIMIT 1];
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
            List<PricebookEntry> pbes = [
                SELECT Id FROM PricebookEntry
                WHERE Product2.Name = :pname AND IsActive = true AND Pricebook2Id = :quotes[0].Pricebook2Id
                WITH USER_MODE LIMIT 1
            ];
            if (pbes.isEmpty()) {
                return AgenticSkillsBase.errorHtml('Could not add quote line item', 'No active PricebookEntry found for "' + pname + '" on this quote\'s pricebook.');
            }
            pbeId = pbes[0].Id;
        }
        try {
            QuoteLineItem qli = new QuoteLineItem(
                QuoteId = qid, PricebookEntryId = pbeId,
                Quantity = Decimal.valueOf(String.valueOf(qtyRaw)),
                UnitPrice = Decimal.valueOf(String.valueOf(priceRaw))
            );
            insert qli;
            String body = '<ul><li><b>Quantity:</b> ' + AgenticSkillsBase.escapeHtml(String.valueOf(qtyRaw)) + '</li>'
                        + '<li><b>Unit Price:</b> ' + AgenticSkillsBase.escapeHtml(String.valueOf(priceRaw)) + '</li></ul>';
            return AgenticSkillsBase.successHtml('Quote Line Item Added', body, qli.Id, 'View Line Item');
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not add quote line item', ex.getMessage());
        }
    }

    private String handleUpdateQuoteLineItem(Map<String, Object> p) {
        String qliId = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'line_item_id', 'quote_line_item_id', 'recordId', 'Id' }));
        if (String.isBlank(qliId)) return AgenticSkillsBase.errorHtml('Could not update quote line item', 'Missing parameter: line_item_id');
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, new Set<String>{ 'line_item_id', 'quote_line_item_id', 'recordId', 'Id', 'quote_id' });
        if (fields.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update quote line item', 'Missing parameter: at least one field to update');
        if (!Schema.sObjectType.QuoteLineItem.isUpdateable()) {
            return AgenticSkillsBase.errorHtml('Could not update quote line item', 'QuoteLineItem is not updateable.');
        }
        List<QuoteLineItem> rows = [
            SELECT Id, Quantity, UnitPrice FROM QuoteLineItem WHERE Id = :qliId WITH USER_MODE LIMIT 1
        ];
        if (rows.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update quote line item', 'No line item found for provided Id.');
        String label = 'Line item (' + String.valueOf(rows[0].Quantity) + ' @ ' + String.valueOf(rows[0].UnitPrice) + ')';
        return AgenticSkillsBase.performGenericUpdate('QuoteLineItem', qliId, fields, 'Quote Line Item Updated', 'View Line Item', label);
    }
}
