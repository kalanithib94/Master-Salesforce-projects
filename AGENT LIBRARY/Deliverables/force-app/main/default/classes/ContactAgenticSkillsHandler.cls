/**
 * @description Contact object skills for the GPTfy Agent Library (4 skills).
 *              Implements ccai.AIAgenticInterface; shared helpers live in AgenticSkillsBase.
 * @author      : Plumcloud Labs
 * @group       : GPTfy Agent Library
 * @jira        : V2-8418
 */
global with sharing class ContactAgenticSkillsHandler implements ccai.AIAgenticInterface {

    global String executeMethod(String methodName, Map<String, Object> parameters) {
        try {
            if (parameters == null) parameters = new Map<String, Object>();
            String m = String.isBlank(methodName) ? '' : methodName.trim();
            switch on m {
                when 'fuzzy_search_contacts' { return handleFuzzySearchContacts(parameters); }
                when 'fetch_contact_details' { return handleFetchContactDetails(parameters); }
                when 'create_contact' { return handleCreateContact(parameters); }
                when 'update_contact_fields' { return handleUpdateContactFields(parameters); }
                when 'fetch_contact_engagement_history' { return AgenticSkillsBase.skillFetchContactEngagementHistory(parameters); }
                when else { return AgenticSkillsBase.errorJson('Unsupported skill: ' + methodName); }
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'ContactAgenticSkillsHandler | ' + methodName + ' | ' + ex.getMessage());
            return AgenticSkillsBase.errorJson(ex.getMessage());
        }
    }

/**
     * @description Skill 6 — fuzzy_search_contacts (Name + Email). Fetches ALL
     *              matching Contacts (capped at AgenticSkillsBase.FUZZY_HARD_CAP) ordered by
     *              LastModifiedDate DESC; the agent displays the latest
     *              AgenticSkillsBase.FUZZY_DISPLAY_LIMIT and the response carries totalFound /
     *              displayed / remaining for the agent to surface.
     * @jira V2-8418
     */
    private String handleFuzzySearchContacts(Map<String, Object> p) {
        String term = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonBlank(p, new List<String>{
            'searchTerm', 'search_term', 'Name', 'name', 'Email', 'email'
        }));
        if (String.isBlank(term)) return AgenticSkillsBase.errorJson('Missing required parameter: searchTerm');
        if (!Schema.sObjectType.Contact.isAccessible()) return AgenticSkillsBase.errorJson('Contact is not accessible.');
        List<SObject> all = AgenticSkillsBase.fuzzyQueryMulti(
            'Contact',
            new List<String>{ 'Name', 'Email' },
            new List<String>{ 'Phone', 'Title', 'AccountId', 'Account.Name' },
            term
        );
        if (all.isEmpty()) return AgenticSkillsBase.errorJson('No contact found matching "' + term + '".');
        Map<String, Object> sliced = AgenticSkillsBase.applyTopNAndCount(all, AgenticSkillsBase.FUZZY_DISPLAY_LIMIT);
        List<SObject> top = (List<SObject>) sliced.get('rows');
        List<Map<String, Object>> records = new List<Map<String, Object>>();
        for (SObject r : top) {
            Contact c = (Contact) r;
            records.add(new Map<String, Object>{
                'Id'         => c.Id,  'Name'    => c.Name,  'Email'   => c.Email,
                'Phone'      => c.Phone, 'Title'  => c.Title,
                'AccountId'  => c.AccountId,
                'Account'    => c.Account != null ? c.Account.Name : null,
                'recordUrl'  => AgenticSkillsBase.recordUrl(c.Id),
                'viewRecord' => AgenticSkillsBase.viewRecordAnchor(c.Id)
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
     * @description Skill 7 — fetch_contact_details.
     * @jira V2-8418
     */
    private String handleFetchContactDetails(Map<String, Object> p) {
        Id cid = AgenticSkillsBase.resolvePrimaryId(p, 'Contact');
        if (cid == null) return AgenticSkillsBase.errorJson('Missing required parameter: Id (Contact Id).');
        if (!Schema.sObjectType.Contact.isAccessible()) return AgenticSkillsBase.errorJson('Contact is not accessible.');
        List<Contact> rows = [
            SELECT Id, Name, FirstName, LastName, Email, Phone, MobilePhone, Title,
                   Department, AccountId, Account.Name, OwnerId, Owner.Name,
                   MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry
            FROM Contact WHERE Id = :cid LIMIT 1
        ];
        if (rows.isEmpty()) return AgenticSkillsBase.errorJson('No contact found for provided Id.');
        Contact c = rows[0];
        return AgenticSkillsBase.successJson(new Map<String, Object>{
            'Id' => c.Id, 'Name' => c.Name, 'FirstName' => c.FirstName, 'LastName' => c.LastName,
            'Email' => c.Email, 'Phone' => c.Phone, 'MobilePhone' => c.MobilePhone,
            'Title' => c.Title, 'Department' => c.Department,
            'AccountId' => c.AccountId,
            'Account' => c.Account != null ? c.Account.Name : null,
            'OwnerId' => c.OwnerId,
            'Owner'   => c.Owner   != null ? c.Owner.Name   : null,
            'MailingAddress' => AgenticSkillsBase.buildAddress(c.MailingStreet, c.MailingCity, c.MailingState, c.MailingPostalCode, c.MailingCountry),
            'recordUrl' => AgenticSkillsBase.recordUrl(c.Id)
        });
    }

    /**
     * @description Skill 8 — create_contact. Contact field API names as params
     *              (LastName, FirstName, Email, AccountId, …). Optional accountName
     *              resolves AccountId when not set.
     * @jira V2-8418
     */
    private String handleCreateContact(Map<String, Object> p) {
        if (!Schema.sObjectType.Contact.isCreateable()) {
            return AgenticSkillsBase.errorHtml('Could not create contact', 'Contact is not creatable.');
        }
        Map<String, Object> applyFields = AgenticSkillsBase.buildFieldMap(p, new Set<String>{
            'account_name', 'accountName', 'searchTerm', 'search_term'
        });
        if (!applyFields.containsKey('LastName') || String.isBlank(AgenticSkillsBase.toText(applyFields.get('LastName')))) {
            return AgenticSkillsBase.errorHtml('Could not create contact', 'LastName is required.');
        }
        // Prefer org relationship field AccountId (+ aliases)
        Id accountLookup = AgenticSkillsBase.resolveLookupId(p, 'AccountId');
        if (accountLookup != null) {
            applyFields.put('AccountId', accountLookup);
        }
        if (applyFields.containsKey('AccountId') && AgenticSkillsBase.isBlankish(applyFields.get('AccountId'))) {
            applyFields.remove('AccountId');
        }
        String accName = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonBlank(p, new List<String>{
            'accountName', 'account_name'
        }));
        if (!applyFields.containsKey('AccountId') && String.isNotBlank(accName) && !AgenticSkillsBase.isBlankish(accName)) {
            List<Account> accs = [SELECT Id FROM Account WHERE Name = :accName LIMIT 1];
            if (accs.isEmpty()) return AgenticSkillsBase.errorHtml('Could not create contact', 'Account "' + accName + '" not found.');
            applyFields.put('AccountId', accs[0].Id);
        }
        try {
            Contact c = new Contact();
            AgenticSkillsBase.applyFieldsToSObject(c, applyFields, false);
            insert c;
            String body = '<ul><li><b>Name:</b> ' + AgenticSkillsBase.escapeHtml((String) applyFields.get('LastName')) + '</li></ul>';
            return AgenticSkillsBase.successHtml('Contact Created', body, c.Id, 'View Contact');
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not create contact', ex.getMessage());
        }
    }

    /**
     * @description Skill 9 — update_contact_fields. Primary Id + org field APIs.
     * @jira V2-8418
     */
    private String handleUpdateContactFields(Map<String, Object> p) {
        Id cid = AgenticSkillsBase.resolvePrimaryId(p, 'Contact');
        if (cid == null) return AgenticSkillsBase.errorHtml('Could not update contact', 'Missing parameter: Id');
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, new Set<String>{
            'Id', 'id', 'ContactId', 'contactId', 'contact_id', 'recordId', 'record_id'
        });
        // Normalize relationship if passed as aliases only
        Id accountLookup = AgenticSkillsBase.resolveLookupId(p, 'AccountId');
        if (accountLookup != null && !fields.containsKey('AccountId')) {
            fields.put('AccountId', accountLookup);
        }
        if (fields.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update contact', 'Missing parameter: at least one field to update');
        if (!Schema.sObjectType.Contact.isUpdateable()) return AgenticSkillsBase.errorHtml('Could not update contact', 'Contact is not updateable.');
        List<Contact> rows = [SELECT Id, Name FROM Contact WHERE Id = :cid LIMIT 1];
        if (rows.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update contact', 'No contact found for provided Id.');
        return AgenticSkillsBase.performGenericUpdate('Contact', cid, fields, 'Contact Updated', 'View Contact', rows[0].Name);
    }
}
