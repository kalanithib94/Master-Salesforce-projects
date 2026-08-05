/**
 * @description Product & pricebook skills for the GPTfy Agent Library (3 skills).
 * @author      : Plumcloud Labs
 * @group       : GPTfy Agent Library
 * @jira        : V2-8418
 */
global with sharing class ProductAgenticSkillsHandler implements ccai.AIAgenticInterface {

    global String executeMethod(String methodName, Map<String, Object> parameters) {
        try {
            if (parameters == null) parameters = new Map<String, Object>();
            String m = String.isBlank(methodName) ? '' : methodName.trim();
            switch on m {
                when 'fuzzy_search_products' { return handleFuzzySearchProducts(parameters); }
                when 'fetch_product_details' { return handleFetchProductDetails(parameters); }
                when 'fetch_pricebook_entries' { return handleFetchPricebookEntries(parameters); }
                when else { return AgenticSkillsBase.errorJson('Unsupported skill: ' + methodName); }
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'ProductAgenticSkillsHandler | ' + methodName + ' | ' + ex.getMessage());
            return AgenticSkillsBase.errorJson(ex.getMessage());
        }
    }

    private String handleFuzzySearchProducts(Map<String, Object> p) {
        String term = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'search_term', 'product_name', 'name' }));
        if (String.isBlank(term)) return AgenticSkillsBase.errorJson('Missing required parameter: search_term');
        if (!Schema.sObjectType.Product2.isAccessible()) return AgenticSkillsBase.errorJson('Product2 is not accessible.');
        List<SObject> all = AgenticSkillsBase.fuzzyQueryMulti(
            'Product2',
            new List<String>{ 'Name', 'ProductCode' },
            new List<String>{ 'Description', 'Family', 'IsActive' },
            term
        );
        if (all.isEmpty()) return AgenticSkillsBase.errorJson('No product found matching "' + term + '".');
        Map<String, Object> sliced = AgenticSkillsBase.applyTopNAndCount(all, AgenticSkillsBase.FUZZY_DISPLAY_LIMIT);
        List<SObject> top = (List<SObject>) sliced.get('rows');
        List<Map<String, Object>> records = new List<Map<String, Object>>();
        for (SObject r : top) {
            Id rid = (Id) r.get('Id');
            records.add(new Map<String, Object>{
                'Id' => rid, 'Name' => r.get('Name'), 'ProductCode' => r.get('ProductCode'),
                'Family' => r.get('Family'), 'IsActive' => r.get('IsActive'),
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

    private String handleFetchProductDetails(Map<String, Object> p) {
        String pid = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'product_id', 'recordId', 'Id' }));
        if (String.isBlank(pid)) return AgenticSkillsBase.errorJson('Missing required parameter: product_id');
        if (!Schema.sObjectType.Product2.isAccessible()) return AgenticSkillsBase.errorJson('Product2 is not accessible.');
        List<Product2> rows = [
            SELECT Id, Name, ProductCode, Description, Family, IsActive
            FROM Product2 WHERE Id = :pid WITH USER_MODE LIMIT 1
        ];
        if (rows.isEmpty()) return AgenticSkillsBase.errorJson('No product found for provided Id.');
        Product2 prod = rows[0];
        return AgenticSkillsBase.successJson(new Map<String, Object>{
            'Id' => prod.Id, 'Name' => prod.Name, 'ProductCode' => prod.ProductCode,
            'Description' => prod.Description, 'Family' => prod.Family, 'IsActive' => prod.IsActive,
            'recordUrl' => AgenticSkillsBase.recordUrl(prod.Id)
        });
    }

    private String handleFetchPricebookEntries(Map<String, Object> p) {
        if (!Schema.sObjectType.PricebookEntry.isAccessible()) {
            return AgenticSkillsBase.errorJson('PricebookEntry is not accessible.');
        }
        String pbId = AgenticSkillsBase.toText(p.get('pricebook_id'));
        String prodId = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'product_id', 'recordId' }));
        Id pricebook2Id;
        if (String.isNotBlank(pbId)) {
            try { pricebook2Id = Id.valueOf(pbId); } catch (Exception e) {
                return AgenticSkillsBase.errorJson('Invalid pricebook_id.');
            }
        } else {
            pricebook2Id = Test.isRunningTest() ? Test.getStandardPricebookId() : [
                SELECT Id FROM Pricebook2 WHERE IsStandard = true WITH USER_MODE LIMIT 1
            ].Id;
        }
        Integer lim = 25;
        Object lRaw = p.get('limit');
        if (lRaw != null && String.isNotBlank(AgenticSkillsBase.toText(lRaw))) {
            try { lim = Integer.valueOf(AgenticSkillsBase.toText(lRaw)); } catch (Exception e) { lim = 25; }
        }
        lim = Math.max(1, Math.min(lim, 200));
        List<PricebookEntry> entries;
        if (String.isNotBlank(prodId)) {
            entries = [
                SELECT Id, Product2Id, Product2.Name, UnitPrice, IsActive, Pricebook2Id
                FROM PricebookEntry
                WHERE Pricebook2Id = :pricebook2Id AND Product2Id = :prodId AND IsActive = true
                WITH USER_MODE LIMIT :lim
            ];
        } else {
            entries = [
                SELECT Id, Product2Id, Product2.Name, UnitPrice, IsActive, Pricebook2Id
                FROM PricebookEntry
                WHERE Pricebook2Id = :pricebook2Id AND IsActive = true
                WITH USER_MODE ORDER BY Product2.Name ASC LIMIT :lim
            ];
        }
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        for (PricebookEntry e : entries) {
            rows.add(new Map<String, Object>{
                'Id' => e.Id, 'Product2Id' => e.Product2Id,
                'ProductName' => e.Product2 != null ? e.Product2.Name : null,
                'UnitPrice' => e.UnitPrice, 'IsActive' => e.IsActive,
                'recordUrl' => AgenticSkillsBase.recordUrl(e.Id)
            });
        }
        return AgenticSkillsBase.successJson(new Map<String, Object>{
            'pricebookId' => pricebook2Id, 'count' => rows.size(), 'entries' => rows
        });
    }
}
