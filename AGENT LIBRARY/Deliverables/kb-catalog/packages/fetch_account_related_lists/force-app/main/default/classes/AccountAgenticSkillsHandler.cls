/**
 * @description Account object skills for the GPTfy Agent Library (5 skills).
 *              Implements ccai.AIAgenticInterface; shared helpers live in AgenticSkillsBase.
 * @author      : Plumcloud Labs
 * @group       : GPTfy Agent Library
 * @jira        : V2-8418
 */
global with sharing class AccountAgenticSkillsHandler implements ccai.AIAgenticInterface {

    global String executeMethod(String methodName, Map<String, Object> parameters) {
        try {
            if (parameters == null) parameters = new Map<String, Object>();
            String m = String.isBlank(methodName) ? '' : methodName.trim();
            switch on m {
                when 'fuzzy_search_accounts' { return handleFuzzySearchAccounts(parameters); }
                when 'fetch_account_details' { return handleFetchAccountDetails(parameters); }
                when 'create_account' { return handleCreateAccount(parameters); }
                when 'update_account_fields' { return handleUpdateAccountFields(parameters); }
                when 'fetch_account_related_lists' { return handleFetchAccountRelatedLists(parameters); }
                when 'fetch_account_plan' { return AgenticSkillsBase.skillFetchAccountPlan(parameters); }
                when else { return AgenticSkillsBase.errorJson('Unsupported skill: ' + methodName); }
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'AccountAgenticSkillsHandler | ' + methodName + ' | ' + ex.getMessage());
            return AgenticSkillsBase.errorJson(ex.getMessage());
        }
    }

    /**
     * @description Skill 1 — fuzzy_search_accounts.
     * @jira V2-8418
     */
    private String handleFuzzySearchAccounts(Map<String, Object> p) {
        String term = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonBlank(p, new List<String>{
            'searchTerm', 'search_term', 'Name', 'accountName', 'account_name', 'name'
        }));
        if (String.isBlank(term)) return AgenticSkillsBase.errorJson('Missing required parameter: search_term');
        if (!Schema.sObjectType.Account.isAccessible()) return AgenticSkillsBase.errorJson('Account is not accessible.');
        List<SObject> all = AgenticSkillsBase.fuzzyQuery('Account', 'Name', new List<String>{ 'Industry', 'Type', 'Website' }, term);
        if (all.isEmpty()) return AgenticSkillsBase.errorJson('No account found matching "' + term + '".');
        Map<String, Object> sliced = AgenticSkillsBase.applyTopNAndCount(all, AgenticSkillsBase.FUZZY_DISPLAY_LIMIT);
        List<SObject> top = (List<SObject>) sliced.get('rows');
        List<Map<String, Object>> records = new List<Map<String, Object>>();
        for (SObject r : top) {
            Id rid = (Id) r.get('Id');
            records.add(new Map<String, Object>{
                'Id'         => rid,
                'Name'       => r.get('Name'),
                'Type'       => r.get('Type'),
                'Industry'   => r.get('Industry'),
                'Website'    => r.get('Website'),
                'recordUrl'  => AgenticSkillsBase.recordUrl(rid),
                'viewRecord' => AgenticSkillsBase.viewRecordAnchor(rid)
            });
        }
        return AgenticSkillsBase.successJson(new Map<String, Object>{
            'status'     => 'found',
            'totalFound' => sliced.get('totalFound'),
            'displayed'  => sliced.get('displayed'),
            'remaining'  => sliced.get('remaining'),
            'records'    => records
        });
    }

    /**
     * @description Skill 2 — fetch_account_details.
     *              Lookup: accountId / Id (preferred), else accountName (fuzzy).
     *              Returns core standard fields + related counts/samples.
     * @jira V2-8418
     */
    private String handleFetchAccountDetails(Map<String, Object> p) {
        if (!Schema.sObjectType.Account.isAccessible()) {
            return AgenticSkillsBase.errorJson('Account is not accessible.');
        }

        // Prefer org-style keys: primary Id; relationships AccountId / ContactId / …
        Id resolvedId = AgenticSkillsBase.resolvePrimaryId(p, 'Account');
        String accId = resolvedId != null ? String.valueOf(resolvedId) : null;
        // Name accidentally passed as Id → name lookup
        if (String.isBlank(accId)) {
            String maybeName = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonBlank(p, new List<String>{
                'Id', 'accountId', 'account_id', 'Name', 'accountName', 'account_name', 'name'
            }));
            if (String.isNotBlank(maybeName) && AgenticSkillsBase.parseSalesforceId(maybeName) == null
                && !maybeName.startsWith('001')) {
                p.put('accountName', maybeName);
            }
        }
        if (String.isNotBlank(accId)) {
            return fetchAccountDetailsJsonForId(accId);
        }

        String accName = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonBlank(p, new List<String>{
            'Name', 'accountName', 'account_name', 'name'
        }));
        if (String.isBlank(accName)) {
            return AgenticSkillsBase.errorJson(
                'Pass Id (Account Id) or Name to load account details.'
            );
        }

        List<SObject> nameMatches = AgenticSkillsBase.fuzzyQuery(
            'Account', 'Name', new List<String>{ 'Industry', 'Type', 'Website' }, accName
        );
        Integer n = nameMatches == null ? 0 : nameMatches.size();
        if (n == 0) {
            return AgenticSkillsBase.errorJson('No account found matching "' + accName + '".');
        }
        if (n >= 6) {
            return AgenticSkillsBase.errorJson(
                'Found ' + n + ' Accounts matching "' + accName
                    + '". Ask the user to refine the name, then call again with accountId.',
                new Map<String, Object>{ 'errorCode' => 'TOO_MANY_ACCOUNT_MATCHES', 'totalFound' => n }
            );
        }
        if (n >= 2) {
            List<Map<String, Object>> pickerRows = new List<Map<String, Object>>();
            for (SObject r : nameMatches) {
                Id rid = (Id) r.get('Id');
                pickerRows.add(new Map<String, Object>{
                    'Id' => rid,
                    'Name' => r.get('Name'),
                    'Type' => r.get('Type'),
                    'Industry' => r.get('Industry'),
                    'Website' => r.get('Website'),
                    'recordUrl' => AgenticSkillsBase.recordUrl(rid)
                });
            }
            return AgenticSkillsBase.errorJson(
                'Multiple Accounts match "' + accName + '". Ask the user to pick one, then call with accountId.',
                new Map<String, Object>{
                    'errorCode' => 'AMBIGUOUS_ACCOUNT_NAME',
                    'totalFound' => n,
                    'records' => pickerRows
                }
            );
        }
        return fetchAccountDetailsJsonForId(String.valueOf(nameMatches[0].get('Id')));
    }

    /**
     * Compact profile: Name, Type, Industry, Phone, Website, Owner, Location
     * + related counts and up to 3 sample Contacts / Opportunities / Cases.
     */
    private String fetchAccountDetailsJsonForId(String accId) {
        Id idVal = AgenticSkillsBase.parseSalesforceId(accId);
        if (idVal == null) {
            return AgenticSkillsBase.errorJson('Invalid accountId. Pass a Salesforce Account Id.');
        }
        if (idVal.getSObjectType() != Account.SObjectType) {
            return AgenticSkillsBase.errorJson(
                'accountId must be an Account Id, not '
                    + idVal.getSObjectType().getDescribe().getName() + '.'
            );
        }

        Map<String, Schema.SObjectField> fmap = Schema.SObjectType.Account.fields.getMap();
        List<String> selectCols = new List<String>{ 'Id', 'Name' };
        for (String f : new List<String>{
            'Type', 'Industry', 'Phone', 'Website', 'OwnerId',
            'BillingCity', 'BillingState', 'BillingCountry'
        }) {
            Schema.SObjectField token = fmap.get(f);
            if (token != null && token.getDescribe().isAccessible()) {
                selectCols.add(token.getDescribe().getName());
            }
        }
        Boolean includeOwnerName = selectCols.contains('OwnerId')
            && Schema.sObjectType.User.fields.Name.isAccessible();
        if (includeOwnerName) selectCols.add('Owner.Name');

        List<Account> rows;
        try {
            rows = Database.query(
                'SELECT ' + String.join(selectCols, ', ')
                    + ' FROM Account WHERE Id = :idVal LIMIT 1'
            );
        } catch (Exception ex) {
            try {
                rows = [SELECT Id, Name FROM Account WHERE Id = :idVal LIMIT 1];
            } catch (Exception ex2) {
                return AgenticSkillsBase.errorJson('Could not load account: ' + ex2.getMessage());
            }
        }
        if (rows == null || rows.isEmpty()) {
            return AgenticSkillsBase.errorJson('No account found for provided Id.');
        }

        Account a = rows[0];
        Map<String, Object> out = new Map<String, Object>{
            'Id' => a.Id,
            'Name' => a.Name,
            'recordUrl' => AgenticSkillsBase.recordUrl(a.Id)
        };
        if (selectCols.contains('Type')) out.put('Type', a.Type);
        if (selectCols.contains('Industry')) out.put('Industry', a.Industry);
        if (selectCols.contains('Phone')) out.put('Phone', a.Phone);
        if (selectCols.contains('Website')) out.put('Website', a.Website);
        if (includeOwnerName && a.Owner != null) out.put('Owner', a.Owner.Name);

        List<String> loc = new List<String>();
        if (selectCols.contains('BillingCity') && String.isNotBlank(a.BillingCity)) loc.add(a.BillingCity);
        if (selectCols.contains('BillingState') && String.isNotBlank(a.BillingState)) loc.add(a.BillingState);
        if (selectCols.contains('BillingCountry') && String.isNotBlank(a.BillingCountry)) loc.add(a.BillingCountry);
        if (!loc.isEmpty()) out.put('Location', String.join(loc, ', '));

        Map<String, Object> related = new Map<String, Object>();
        if (Schema.sObjectType.Contact.isAccessible()) {
            Integer cCount = [SELECT COUNT() FROM Contact WHERE AccountId = :idVal];
            related.put('contactCount', cCount);
            if (cCount > 0) {
                List<Map<String, Object>> sample = new List<Map<String, Object>>();
                for (Contact c : [
                    SELECT Id, Name, Title, Email, Phone
                    FROM Contact WHERE AccountId = :idVal
                    ORDER BY LastModifiedDate DESC LIMIT 3
                ]) {
                    sample.add(new Map<String, Object>{
                        'Id' => c.Id, 'Name' => c.Name, 'Title' => c.Title,
                        'Email' => c.Email, 'Phone' => c.Phone
                    });
                }
                related.put('contacts', sample);
            }
        }
        if (Schema.sObjectType.Opportunity.isAccessible()) {
            Integer oCount = [SELECT COUNT() FROM Opportunity WHERE AccountId = :idVal];
            related.put('opportunityCount', oCount);
            if (oCount > 0) {
                List<Map<String, Object>> sample = new List<Map<String, Object>>();
                for (Opportunity o : [
                    SELECT Id, Name, StageName, Amount, CloseDate, IsClosed
                    FROM Opportunity WHERE AccountId = :idVal
                    ORDER BY CloseDate DESC NULLS LAST LIMIT 3
                ]) {
                    sample.add(new Map<String, Object>{
                        'Id' => o.Id, 'Name' => o.Name, 'StageName' => o.StageName,
                        'Amount' => o.Amount, 'CloseDate' => o.CloseDate, 'IsClosed' => o.IsClosed
                    });
                }
                related.put('opportunities', sample);
            }
        }
        if (Schema.sObjectType.Case.isAccessible()) {
            Integer caseCount = [SELECT COUNT() FROM Case WHERE AccountId = :idVal];
            related.put('caseCount', caseCount);
            if (caseCount > 0) {
                List<Map<String, Object>> sample = new List<Map<String, Object>>();
                for (Case ca : [
                    SELECT Id, CaseNumber, Subject, Status, Priority
                    FROM Case WHERE AccountId = :idVal
                    ORDER BY CreatedDate DESC LIMIT 3
                ]) {
                    sample.add(new Map<String, Object>{
                        'Id' => ca.Id, 'CaseNumber' => ca.CaseNumber, 'Subject' => ca.Subject,
                        'Status' => ca.Status, 'Priority' => ca.Priority
                    });
                }
                related.put('cases', sample);
            }
        }
        out.put('related', related);
        return AgenticSkillsBase.successJson(out);
    }

    /**
     * @description Skill 3 — create_account.
     * @jira V2-8418
     */
    private String handleCreateAccount(Map<String, Object> p) {
        if (!Schema.sObjectType.Account.isCreateable()) {
            return AgenticSkillsBase.errorHtml('Could not create account', 'Account is not creatable.');
        }
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, null);
        if (!fields.containsKey('Name') || String.isBlank(AgenticSkillsBase.toText(fields.get('Name')))) {
            return AgenticSkillsBase.errorHtml('Could not create account', 'Account Name is required.');
        }
        try {
            Account a = new Account();
            AgenticSkillsBase.applyFieldsToSObject(a, fields, false);
            insert a;
            String body = '<ul><li><b>Name:</b> ' + AgenticSkillsBase.escapeHtml(a.Name) + '</li>'
                        + (String.isNotBlank(a.Industry) ? '<li><b>Industry:</b> ' + AgenticSkillsBase.escapeHtml(a.Industry) + '</li>' : '')
                        + '</ul>';
            return AgenticSkillsBase.successHtml('Account Created', body, a.Id, 'View Account');
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not create account', ex.getMessage());
        }
    }

    /**
     * @description Skill 4 — update_account_fields.
     * @jira V2-8418
     */
    private String handleUpdateAccountFields(Map<String, Object> p) {
        Id accResolved = AgenticSkillsBase.resolvePrimaryId(p, 'Account');
        String accId = accResolved != null ? String.valueOf(accResolved) : null;
        if (String.isBlank(accId)) return AgenticSkillsBase.errorHtml('Could not update account', 'Missing parameter: Id');

        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, new Set<String>{
            'Id', 'id', 'AccountId', 'accountId', 'account_id', 'recordId', 'record_id'
        });
        if (fields.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update account', 'Missing parameter: at least one field to update');

        if (!Schema.sObjectType.Account.isUpdateable()) return AgenticSkillsBase.errorHtml('Could not update account', 'Account is not updateable.');
        List<Account> rows = [SELECT Id, Name FROM Account WHERE Id = :accId LIMIT 1];
        if (rows.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update account', 'No account found for provided Id.');
        return AgenticSkillsBase.performGenericUpdate('Account', accId, fields, 'Account Updated', 'View Account', rows[0].Name);
    }

    /**
     * @description Skill 5 — fetch_account_related_lists.
     * @jira V2-8418
     */
    private String handleFetchAccountRelatedLists(Map<String, Object> p) {
        Id accResolved = AgenticSkillsBase.resolvePrimaryId(p, 'Account');
        String accId = accResolved != null ? String.valueOf(accResolved) : null;
        if (String.isBlank(accId)) return AgenticSkillsBase.errorJson('Missing required parameter: Id');
        if (!Schema.sObjectType.Account.isAccessible()) return AgenticSkillsBase.errorJson('Account is not accessible.');
        List<Account> accs = [SELECT Id, Name FROM Account WHERE Id = :accId LIMIT 1];
        if (accs.isEmpty()) return AgenticSkillsBase.errorJson('No account found for provided Id.');
        Set<String> wanted = new Set<String>();
        Object related = p.get('related');
        if (related instanceof List<Object>) {
            for (Object o : (List<Object>) related) wanted.add(String.valueOf(o).toLowerCase());
        }
        if (wanted.isEmpty()) wanted.addAll(new List<String>{ 'contacts', 'opportunities', 'cases' });
        Map<String, Object> result = new Map<String, Object>{ 'Id' => accs[0].Id, 'Name' => accs[0].Name };
        if (wanted.contains('contacts') && Schema.sObjectType.Contact.isAccessible()) {
            result.put('contacts', [SELECT Id, Name, Email, Phone, Title FROM Contact WHERE AccountId = :accId LIMIT 50]);
        }
        if (wanted.contains('opportunities') && Schema.sObjectType.Opportunity.isAccessible()) {
            result.put('opportunities', [SELECT Id, Name, StageName, Amount, CloseDate FROM Opportunity WHERE AccountId = :accId ORDER BY CloseDate DESC LIMIT 50]);
        }
        if (wanted.contains('cases') && Schema.sObjectType.Case.isAccessible()) {
            result.put('cases', [SELECT Id, CaseNumber, Subject, Status, Priority FROM Case WHERE AccountId = :accId ORDER BY CreatedDate DESC LIMIT 50]);
        }
        return AgenticSkillsBase.successJson(result);
    }
}
