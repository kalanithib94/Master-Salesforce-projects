/**
 * @description : Test class for GenericAgenticSkillsHandler. Covers all 38
 *                skills via executeMethod dispatch plus negative paths and
 *                helper utilities. Uses System.Assert (per project rule) and
 *                targets >75% coverage.
 * @author      : Plumcloud Labs
 * @group       : GPTfy Agent Library
 * @jira        : V2-8418
 */
@isTest
private class GenericAgenticSkillsHandlerTest {

    private static GenericAgenticSkillsHandler handler() {
        return new GenericAgenticSkillsHandler();
    }

    private static Map<String, Object> deserialize(String payload) {
        return (Map<String, Object>) JSON.deserializeUntyped(payload);
    }

    // ────────────────────────────────────────────────────────────────────────
    // Setup data
    // ────────────────────────────────────────────────────────────────────────
    @TestSetup
    static void setup() {
        Account a = new Account(Name = 'Acme Power Grid', Industry = 'Energy', Type = 'Customer - Direct', AnnualRevenue = 5000000);
        insert a;
        Account a2 = new Account(Name = 'Beta Industries', Industry = 'Manufacturing');
        insert a2;
        Contact c = new Contact(LastName = 'Smith', FirstName = 'John', Email = 'john.smith@acme.test', AccountId = a.Id);
        insert c;
        Lead l = new Lead(LastName = 'Doe', FirstName = 'Jane', Company = 'Lead Co', Email = 'jane@leadco.test', Status = 'Open - Not Contacted');
        insert l;
        Opportunity o = new Opportunity(Name = 'Acme Big Deal', StageName = 'Prospecting', CloseDate = Date.today().addDays(30), AccountId = a.Id, Amount = 25000);
        insert o;
        Case ca = new Case(Subject = 'Test case for coverage', Status = 'New', Priority = 'Medium', AccountId = a.Id);
        insert ca;
        Task t = new Task(Subject = 'Open follow-up', Status = 'Not Started', Priority = 'Normal', ActivityDate = Date.today().addDays(5));
        insert t;
    }

    private static Account anAccount() { return [SELECT Id, Name FROM Account WHERE Name = 'Acme Power Grid' LIMIT 1]; }
    private static Contact aContact() { return [SELECT Id, Name FROM Contact WHERE LastName = 'Smith' LIMIT 1]; }
    private static Lead aLead()       { return [SELECT Id, Name FROM Lead WHERE LastName = 'Doe' LIMIT 1]; }
    private static Opportunity anOpp(){ return [SELECT Id, Name FROM Opportunity WHERE Name = 'Acme Big Deal' LIMIT 1]; }
    private static Case aCase()       { return [SELECT Id, CaseNumber FROM Case WHERE Subject = 'Test case for coverage' LIMIT 1]; }
    private static Task aTask()       { return [SELECT Id FROM Task WHERE Subject = 'Open follow-up' LIMIT 1]; }

    // ────────────────────────────────────────────────────────────────────────
    // Dispatcher / unsupported skill
    // ────────────────────────────────────────────────────────────────────────
    @isTest
    static void unsupportedSkillReturnsError() {
        String r = handler().executeMethod('not_a_real_skill', new Map<String, Object>());
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(false, m.get('success'), 'Unsupported skill should return success=false');
        System.Assert.isTrue(String.valueOf(m.get('error')).contains('Unsupported skill'), 'Error message should mention Unsupported skill');
    }

    @isTest
    static void nullParametersAreHandled() {
        String r = handler().executeMethod('fuzzy_search_accounts', null);
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(false, m.get('success'), 'Missing search_term should fail');
    }

    @isTest
    static void blankMethodNameReturnsError() {
        String r = handler().executeMethod('', new Map<String, Object>());
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(false, m.get('success'), 'Blank skill name should fail');
    }

    // ────────────────────────────────────────────────────────────────────────
    // ACCOUNT (1-5)
    // ────────────────────────────────────────────────────────────────────────
    @isTest
    static void account_fuzzySearch_findsRecord() {
        String r = handler().executeMethod('fuzzy_search_accounts', new Map<String, Object>{ 'search_term' => 'power grid' });
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(true, m.get('success'));
        List<Object> records = (List<Object>) m.get('records');
        System.Assert.isTrue(records.size() >= 1, 'Should find at least one account');
        System.Assert.isNotNull(m.get('totalFound'),  'Envelope must include totalFound');
        System.Assert.isNotNull(m.get('displayed'),  'Envelope must include displayed');
        System.Assert.isNotNull(m.get('remaining'),  'Envelope must include remaining');
        // Per-record output structure: Name, Type, Industry, Website, recordUrl, viewRecord (+ Id).
        Map<String, Object> first = (Map<String, Object>) records[0];
        System.Assert.isNotNull(first.get('Id'),         'Id is required for follow-up calls');
        System.Assert.isNotNull(first.get('Name'),       'Name is required in output');
        System.Assert.isTrue(first.containsKey('Type'),     'Type key is required in output');
        System.Assert.isTrue(first.containsKey('Industry'), 'Industry key is required in output');
        System.Assert.isTrue(first.containsKey('Website'),  'Website key is required in output');
        System.Assert.isNotNull(first.get('recordUrl'),  'recordUrl is required in output');
        String anchor = (String) first.get('viewRecord');
        System.Assert.isNotNull(anchor, 'viewRecord HTML anchor is required in output');
        System.Assert.isTrue(anchor.contains('View Record'), 'viewRecord anchor text must say "View Record"');
        System.Assert.isTrue(anchor.contains('href='),       'viewRecord must be an <a href=...> hyperlink');
        System.Assert.isFalse(first.containsKey('Phone'),    'Phone is no longer part of fuzzy_search_accounts output');
    }

    @isTest
    static void account_fuzzySearch_missingTermFails() {
        String r = handler().executeMethod('fuzzy_search_accounts', new Map<String, Object>());
        System.Assert.areEqual(false, deserialize(r).get('success'));
    }

    /**
     * Jira V2-8418 — when more than FUZZY_DISPLAY_LIMIT (5) accounts share a
     * partial-match term, fuzzy_search_accounts must:
     *   - fetch ALL matching accounts (up to FUZZY_HARD_CAP),
     *   - return the latest FUZZY_DISPLAY_LIMIT (LastModifiedDate DESC) in records,
     *   - expose totalFound + displayed + remaining counts in the envelope so
     *     the agent can tell the user "X more not shown".
     *
     * NOTE on ordering: bulk DML inside a single test transaction stamps every
     * record with an identical LastModifiedDate (down to the second), so a
     * strict "row at index 0 is the highest-numbered one" assertion would be
     * flaky. We instead issue an extra `update` on the targeted "latest" row
     * so its timestamp is strictly newer than the bulk batch, and assert
     * membership (the bumped row must be present in the displayed slice).
     */
    @isTest
    static void account_fuzzySearch_truncatesToLatestFiveAndReportsRemaining() {
        List<Account> extras = new List<Account>();
        for (Integer i = 1; i <= 7; i++) {
            extras.add(new Account(Name = 'Acme Branch ' + i, Industry = 'Energy', Type = 'Customer - Direct', Website = 'https://acme' + i + '.test'));
        }
        insert extras;
        // Bump the targeted record so its LastModifiedDate is strictly newer
        // than the bulk-insert batch (separate DML => later timestamp).
        extras[6].Website = 'https://acme7-bumped.test';
        update extras[6];
        String r = handler().executeMethod('fuzzy_search_accounts', new Map<String, Object>{ 'search_term' => 'Acme' });
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(true, m.get('success'));
        List<Object> records = (List<Object>) m.get('records');
        System.Assert.areEqual(5, records.size(), 'Must display exactly the latest 5 records');
        System.Assert.areEqual(8, (Integer) m.get('totalFound'), 'totalFound must report all 8 matches (1 setup + 7 extras)');
        System.Assert.areEqual(5, (Integer) m.get('displayed'),  'displayed must equal the slice size');
        System.Assert.areEqual(3, (Integer) m.get('remaining'),  'remaining must report 3 records not shown');
        // Membership: the bumped row (strictly newest) must appear in the displayed slice.
        Boolean foundBumped = false;
        for (Object o : records) {
            if ('Acme Branch 7'.equals(((Map<String, Object>) o).get('Name'))) { foundBumped = true; break; }
        }
        System.Assert.isTrue(foundBumped, 'The most recently updated record must be in the latest-5 slice');
    }

    @isTest
    static void account_fuzzySearch_singleMatchReportsZeroRemaining() {
        String r = handler().executeMethod('fuzzy_search_accounts', new Map<String, Object>{ 'search_term' => 'Beta Industries' });
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(true, m.get('success'));
        System.Assert.areEqual(1, (Integer) m.get('totalFound'));
        System.Assert.areEqual(1, (Integer) m.get('displayed'));
        System.Assert.areEqual(0, (Integer) m.get('remaining'), 'Remaining must be zero when one match is found');
    }

    @isTest
    static void account_fetchDetails_returnsData() {
        Account a = anAccount();
        String r = handler().executeMethod('fetch_account_details', new Map<String, Object>{ 'account_id' => a.Id });
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(true, m.get('success'));
        System.Assert.areEqual('Acme Power Grid', m.get('Name'));
    }

    @isTest
    static void account_fetchDetails_missingIdFails() {
        String r = handler().executeMethod('fetch_account_details', new Map<String, Object>());
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(false, m.get('success'));
        String err = String.valueOf(m.get('error'));
        System.Assert.isTrue(
            err.contains('accountId') || err.contains('accountName') || err.contains('account_id') || err.contains('account_name'),
            'Error should state that accountId OR accountName is required: ' + err
        );
    }

    @isTest
    static void account_fetchDetails_byName_singleMatch() {
        String r = handler().executeMethod('fetch_account_details', new Map<String, Object>{ 'account_name' => 'Acme Power Grid' });
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(true, m.get('success'));
        System.Assert.areEqual('Acme Power Grid', m.get('Name'));
    }

    @isTest
    static void account_fetchDetails_byName_noMatches() {
        String r = handler().executeMethod('fetch_account_details', new Map<String, Object>{ 'account_name' => 'ZZZNoSuchAccountToken99987' });
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(false, m.get('success'));
        System.Assert.isTrue(String.valueOf(m.get('error')).contains('No account found'));
    }

    @isTest
    static void account_fetchDetails_byName_ambiguousReturnsPicker() {
        final String token = 'AmbigToken77331';
        insert new List<Account>{
            new Account(Name = 'Alpha ' + token, Industry = 'Energy'),
            new Account(Name = 'Bravo ' + token, Industry = 'Technology')
        };
        String r = handler().executeMethod('fetch_account_details', new Map<String, Object>{ 'account_name' => token });
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(false, m.get('success'));
        System.Assert.areEqual('AMBIGUOUS_ACCOUNT_NAME', m.get('errorCode'));
        List<Object> recs = (List<Object>) m.get('records');
        System.Assert.areEqual(2, recs.size());
    }

    @isTest
    static void account_fetchDetails_byName_tooManyReturnsCode() {
        final String token = 'ManyMatchToken88442';
        List<Account> extraAccounts = new List<Account>();
        for (Integer i = 0; i < 6; i++) {
            extraAccounts.add(new Account(Name = 'Co ' + i + ' ' + token, Industry = 'Energy'));
        }
        insert extraAccounts;
        String r = handler().executeMethod('fetch_account_details', new Map<String, Object>{ 'account_name' => token });
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(false, m.get('success'));
        System.Assert.areEqual('TOO_MANY_ACCOUNT_MATCHES', m.get('errorCode'));
        System.Assert.areEqual(6, (Integer) m.get('totalFound'));
    }

    @isTest
    static void account_fetchDetails_idPrecedenceOverName() {
        Account acme = anAccount();
        String r = handler().executeMethod('fetch_account_details', new Map<String, Object>{
            'account_id'   => acme.Id,
            'account_name' => 'Beta Industries'
        });
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(true, m.get('success'));
        System.Assert.areEqual('Acme Power Grid', m.get('Name'), 'account_id must win over account_name');
    }

    // Jira V2-8418 — All Account fields are now passed as flat top-level params.
    @isTest
    static void account_create_success() {
        String r = handler().executeMethod('create_account', new Map<String, Object>{
            'Name'          => 'Created Co',
            'Industry'      => 'Technology',
            'AnnualRevenue' => 1000000
        });
        System.Assert.isTrue(r.contains('Account Created'), 'HTML success card expected');
        System.Assert.areEqual(1, [SELECT COUNT() FROM Account WHERE Name = 'Created Co']);
        Account created = [SELECT Industry, AnnualRevenue FROM Account WHERE Name = 'Created Co' LIMIT 1];
        System.Assert.areEqual('Technology', created.Industry, 'Flat top-level Industry should be applied');
        System.Assert.areEqual(1000000, created.AnnualRevenue, 'Flat top-level AnnualRevenue should be applied');
    }

    // Jira V2-8418 — Name only (no optional fields) should still create successfully
    @isTest
    static void account_create_nameOnlySucceeds() {
        String r = handler().executeMethod('create_account', new Map<String, Object>{
            'Name' => 'Name-Only Co'
        });
        System.Assert.isTrue(r.contains('Account Created'), 'Name-only call should succeed');
        System.Assert.areEqual(1, [SELECT COUNT() FROM Account WHERE Name = 'Name-Only Co']);
    }

    // Jira V2-8418 — missing Name must fail with the expected error
    @isTest
    static void account_create_missingNameFails() {
        String r = handler().executeMethod('create_account', new Map<String, Object>{
            'Industry' => 'Technology'
        });
        System.Assert.isTrue(r.contains('Account Name is required'),
            'Missing Name should return the Account Name is required error');
    }

    // Jira V2-8418 — legacy nested { "fields": { … } } shape must still create successfully
    @isTest
    static void account_create_legacyFieldsMapStillWorks() {
        String r = handler().executeMethod('create_account', new Map<String, Object>{
            'fields' => new Map<String, Object>{ 'Name' => 'Legacy Acct', 'Industry' => 'Energy' }
        });
        System.Assert.isTrue(r.contains('Account Created'), 'Legacy nested fields map should still create the Account');
        Account created = [SELECT Industry FROM Account WHERE Name = 'Legacy Acct' LIMIT 1];
        System.Assert.areEqual('Energy', created.Industry, 'Legacy nested Industry should be applied');
    }

    // Jira V2-8418 — blank top-level Name must fail with the expected error
    @isTest
    static void account_create_blankNameFails() {
        String r = handler().executeMethod('create_account', new Map<String, Object>{
            'Name' => '   '
        });
        System.Assert.isTrue(r.contains('Account Name is required'),
            'Blank top-level Name should return the Account Name is required error');
    }

    @isTest
    static void account_update_diffCardRendered() {
        Account a = anAccount();
        String r = handler().executeMethod('update_account_fields', new Map<String, Object>{
            'account_id'    => a.Id,
            'Industry'      => 'Technology',
            'AnnualRevenue' => 7500000
        });
        System.Assert.isTrue(r.contains('Account Updated'),
            'Diff card should be rendered on update success');
        Account refreshed = [SELECT Industry FROM Account WHERE Id = :a.Id];
        System.Assert.areEqual('Technology', refreshed.Industry,
            'Industry should be updated to Technology');
    }

    @isTest
    static void account_update_missingIdFails() {
        String r = handler().executeMethod('update_account_fields', new Map<String, Object>{
            'Industry' => 'X'
        });
        System.Assert.isTrue(r.contains('Missing parameter: accountId') || r.contains('Missing parameter: account_id'),
            'Should fail with accountId missing error when no Id is provided');
    }

    @isTest
    static void account_update_noFieldsFails() {
        Account a = anAccount();
        String r = handler().executeMethod('update_account_fields', new Map<String, Object>{
            'account_id' => a.Id
        });
        System.Assert.isTrue(r.contains('at least one field to update'),
            'Should fail when no field-to-update parameters are supplied');
    }

    @isTest
    static void account_relatedLists_returnsChildren() {
        Account a = anAccount();
        String r = handler().executeMethod('fetch_account_related_lists', new Map<String, Object>{
            'account_id' => a.Id, 'related' => new List<Object>{ 'contacts', 'opportunities' }
        });
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(true, m.get('success'));
        System.Assert.isNotNull(m.get('contacts'));
        System.Assert.isNotNull(m.get('opportunities'));
    }

    // ────────────────────────────────────────────────────────────────────────
    // CONTACT (6-10)
    // ────────────────────────────────────────────────────────────────────────
    @isTest
    static void contact_fuzzySearch_byEmail() {
        String r = handler().executeMethod('fuzzy_search_contacts', new Map<String, Object>{ 'search_term' => 'john.smith' });
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(true, m.get('success'));
        System.Assert.isNotNull(m.get('totalFound'));
        System.Assert.isNotNull(m.get('displayed'));
        System.Assert.isNotNull(m.get('remaining'));
        Map<String, Object> first = (Map<String, Object>) ((List<Object>) m.get('records'))[0];
        System.Assert.isNotNull(first.get('viewRecord'), 'Contact fuzzy rows must carry the View Record hyperlink');
    }

    /**
     * Jira V2-8418 — multi-field fuzzy (Contact: Name OR Email) must also
     * fetch ALL matches, return the latest 5, and report remaining count.
     */
    @isTest
    static void contact_fuzzySearch_truncatesAndReportsRemaining() {
        Account a = anAccount();
        List<Contact> extras = new List<Contact>();
        for (Integer i = 1; i <= 7; i++) {
            extras.add(new Contact(LastName = 'Smithson' + i, FirstName = 'Match', Email = 'match' + i + '@acme.test', AccountId = a.Id));
        }
        insert extras;
        String r = handler().executeMethod('fuzzy_search_contacts', new Map<String, Object>{ 'search_term' => 'Smith' });
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(true, m.get('success'));
        Integer total = (Integer) m.get('totalFound');
        System.Assert.isTrue(total >= 7, 'Should find at least the 7 newly inserted Smithson contacts');
        System.Assert.areEqual(5, ((List<Object>) m.get('records')).size(), 'Must display exactly the latest 5 records');
        System.Assert.areEqual(5, (Integer) m.get('displayed'));
        System.Assert.areEqual(total - 5, (Integer) m.get('remaining'));
    }

    @isTest
    static void contact_fetchDetails_returnsData() {
        Contact c = aContact();
        String r = handler().executeMethod('fetch_contact_details', new Map<String, Object>{ 'contact_id' => c.Id });
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(true, m.get('success'));
        System.Assert.areEqual('John Smith', m.get('Name'));
    }

    @isTest
    static void contact_create_resolvesAccountByName() {
        String r = handler().executeMethod('create_contact', new Map<String, Object>{
            'LastName' => 'Resolver',
            'Email' => 'r@a.com',
            'account_name' => 'Acme Power Grid'
        });
        System.Assert.isTrue(r.contains('Contact Created'), 'Expected Contact Created HTML, got: ' + r);
        Contact found = [SELECT AccountId FROM Contact WHERE LastName = 'Resolver' LIMIT 1];
        System.Assert.isNotNull(found.AccountId, 'AccountId should have been resolved from account_name');
    }

    @isTest
    static void contact_create_missingLastNameFails() {
        String r = handler().executeMethod('create_contact', new Map<String, Object>{
            'FirstName' => 'X'
        });
        System.Assert.isTrue(r.contains('LastName is required'), 'Expected LastName-required error, got: ' + r);
    }

    @isTest
    static void contact_create_flatFieldsSucceeds() {
        String r = handler().executeMethod('create_contact', new Map<String, Object>{
            'LastName' => 'Flat',
            'FirstName' => 'Top',
            'Email' => 'flat@a.com'
        });
        System.Assert.isTrue(r.contains('Contact Created'), 'Expected Contact Created HTML, got: ' + r);
        Contact found = [SELECT FirstName, Email FROM Contact WHERE LastName = 'Flat' LIMIT 1];
        System.Assert.areEqual('Top', found.FirstName, 'FirstName should be set from flat top-level parameter');
        System.Assert.areEqual('flat@a.com', found.Email, 'Email should be set from flat top-level parameter');
    }

    @isTest
    static void contact_create_legacyFieldsMapStillWorks() {
        String r = handler().executeMethod('create_contact', new Map<String, Object>{
            'fields' => new Map<String, Object>{ 'LastName' => 'Legacy', 'Email' => 'legacy@a.com' }
        });
        System.Assert.isTrue(r.contains('Contact Created'), 'Expected Contact Created HTML for legacy nested shape, got: ' + r);
        Contact found = [SELECT Email FROM Contact WHERE LastName = 'Legacy' LIMIT 1];
        System.Assert.areEqual('legacy@a.com', found.Email, 'Email should be set from legacy nested fields map');
    }

    @isTest
    static void contact_create_emptyParametersFails() {
        String r = handler().executeMethod('create_contact', new Map<String, Object>());
        System.Assert.isTrue(r.contains('LastName is required'), 'Empty parameters should fall through to the LastName-required error, got: ' + r);
    }

    @isTest
    static void contact_update_success() {
        Contact c = aContact();
        String r = handler().executeMethod('update_contact_fields', new Map<String, Object>{
            'contact_id' => c.Id,
            'Title'      => 'CEO',
            'Phone'      => '555-1212'
        });
        System.Assert.isTrue(r.contains('Contact Updated'));
    }

    // Jira V2-8418 — legacy nested fields shape back-compat for update_contact_fields
    @isTest
    static void contact_update_legacyFieldsMapStillWorks() {
        Contact c = aContact();
        String r = handler().executeMethod('update_contact_fields', new Map<String, Object>{
            'contact_id' => c.Id,
            'fields'     => new Map<String, Object>{ 'Title' => 'Legacy CEO', 'Phone' => '555-9999' }
        });
        System.Assert.isTrue(r.contains('Contact Updated'), 'Legacy nested fields shape should still update the Contact');
    }

    @isTest
    static void activity_logActivity_onContact_success() {
        Contact c = aContact();
        String r = handler().executeMethod('log_activity', new Map<String, Object>{
            'record_id' => c.Id, 'activity_subject' => 'Welcome call', 'activity_description' => 'Intro chat'
        });
        System.Assert.isTrue(r.contains('Activity Logged'));
    }

    @isTest
    static void activity_logActivity_missingSubject() {
        Contact c = aContact();
        String r = handler().executeMethod('log_activity', new Map<String, Object>{ 'record_id' => c.Id });
        System.Assert.isTrue(r.contains('Missing the activity subject'));
    }

    // ────────────────────────────────────────────────────────────────────────
    // LEAD (11-16)
    // ────────────────────────────────────────────────────────────────────────
    @isTest
    static void lead_fuzzySearch_byCompany() {
        String r = handler().executeMethod('fuzzy_search_leads', new Map<String, Object>{ 'search_term' => 'Lead Co' });
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(true, m.get('success'));
        System.Assert.isNotNull(m.get('totalFound'));
        System.Assert.isNotNull(m.get('displayed'));
        System.Assert.isNotNull(m.get('remaining'));
        Map<String, Object> first = (Map<String, Object>) ((List<Object>) m.get('records'))[0];
        System.Assert.isNotNull(first.get('viewRecord'), 'Lead fuzzy rows must carry the View Record hyperlink');
    }

    @isTest
    static void lead_fetchDetails_returnsData() {
        Lead l = aLead();
        String r = handler().executeMethod('fetch_lead_details', new Map<String, Object>{ 'lead_id' => l.Id });
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(true, m.get('success'));
        System.Assert.areEqual('Lead Co', m.get('Company'));
    }

    @isTest
    static void lead_create_success() {
        String r = handler().executeMethod('create_lead', new Map<String, Object>{
            'LastName' => 'Created',
            'Company'  => 'NewCo',
            'Status'   => 'Open - Not Contacted'
        });
        System.Assert.isTrue(r.contains('Lead Created'));
    }

    @isTest
    static void lead_create_missingCompanyFails() {
        String r = handler().executeMethod('create_lead', new Map<String, Object>{
            'LastName' => 'NoCompany'
        });
        System.Assert.isTrue(r.contains('Company is required'));
    }

    // Jira V2-8418 — legacy nested fields shape back-compat
    @isTest
    static void lead_create_legacyFieldsMapStillWorks() {
        String r = handler().executeMethod('create_lead', new Map<String, Object>{
            'fields' => new Map<String, Object>{ 'LastName' => 'Legacy', 'Company' => 'OldCo' }
        });
        System.Assert.isTrue(r.contains('Lead Created'), 'Legacy nested fields shape should still create the Lead');
    }

    @isTest
    static void lead_update_success() {
        Lead l = aLead();
        String r = handler().executeMethod('update_lead_fields', new Map<String, Object>{
            'lead_id' => l.Id,
            'Title'   => 'Director'
        });
        System.Assert.isTrue(r.contains('Lead Updated'));
    }

    // Jira V2-8418 — legacy nested fields shape back-compat for update_lead_fields
    @isTest
    static void lead_update_legacyFieldsMapStillWorks() {
        Lead l = aLead();
        String r = handler().executeMethod('update_lead_fields', new Map<String, Object>{
            'lead_id' => l.Id,
            'fields'  => new Map<String, Object>{ 'Title' => 'Legacy Director' }
        });
        System.Assert.isTrue(r.contains('Lead Updated'), 'Legacy nested fields shape should still update the Lead');
    }

    @isTest
    static void lead_convert_success() {
        Lead l = aLead();
        String r = handler().executeMethod('convert_lead', new Map<String, Object>{
            'lead_id' => l.Id, 'do_not_create_opportunity' => true
        });
        System.Assert.isTrue(r.contains('Lead Converted'));
    }

    @isTest
    static void lead_convert_alreadyConvertedFails() {
        Lead l = aLead();
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(l.Id);
        lc.setDoNotCreateOpportunity(true);
        lc.setConvertedStatus([SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1].MasterLabel);
        Database.convertLead(lc);
        String r = handler().executeMethod('convert_lead', new Map<String, Object>{ 'lead_id' => l.Id });
        System.Assert.isTrue(r.contains('already converted'));
    }

    @isTest
    static void opp_fuzzySearch_byName() {
        String r = handler().executeMethod('fuzzy_search_opportunities', new Map<String, Object>{ 'search_term' => 'big deal' });
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(true, m.get('success'));
        System.Assert.isNotNull(m.get('totalFound'));
        Map<String, Object> first = (Map<String, Object>) ((List<Object>) m.get('records'))[0];
        System.Assert.isNotNull(first.get('viewRecord'));
    }

    @isTest
    static void opp_fuzzySearch_byId() {
        Opportunity o = anOpp();
        String r = handler().executeMethod('fuzzy_search_opportunities', new Map<String, Object>{ 'search_term' => String.valueOf(o.Id) });
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(true, m.get('success'));
        System.Assert.areEqual('id', m.get('matchedVia'));
    }

    @isTest
    static void opp_fetchDetails_returnsData() {
        Opportunity o = anOpp();
        String r = handler().executeMethod('fetch_opportunity_details', new Map<String, Object>{ 'opportunity_id' => o.Id });
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(true, m.get('success'));
        System.Assert.areEqual('Acme Big Deal', m.get('Name'));
    }

    @isTest
    static void opp_create_success() {
        Account a = anAccount();
        String r = handler().executeMethod('create_opportunity', new Map<String, Object>{
            'Name'      => 'New Opp',
            'StageName' => 'Prospecting',
            'CloseDate' => String.valueOf(Date.today().addDays(60)),
            'AccountId' => a.Id,
            'Amount'    => 50000
        });
        System.Assert.isTrue(r.contains('Opportunity Created'));
    }

    @isTest
    static void opp_create_missingStageFails() {
        String r = handler().executeMethod('create_opportunity', new Map<String, Object>{
            'Name'      => 'X',
            'CloseDate' => '2026-12-31'
        });
        System.Assert.isTrue(r.contains('StageName is required'));
    }

    // Jira V2-8418 — legacy nested fields shape back-compat
    @isTest
    static void opp_create_legacyFieldsMapStillWorks() {
        String r = handler().executeMethod('create_opportunity', new Map<String, Object>{
            'fields' => new Map<String, Object>{
                'Name' => 'Legacy Opp', 'StageName' => 'Prospecting',
                'CloseDate' => String.valueOf(Date.today().addDays(30))
            }
        });
        System.Assert.isTrue(r.contains('Opportunity Created'), 'Legacy nested fields shape should still create the Opportunity');
    }

    @isTest
    static void opp_update_diffCard() {
        Opportunity o = anOpp();
        String r = handler().executeMethod('update_opportunity_fields', new Map<String, Object>{
            'opportunity_id' => o.Id,
            'StageName'      => 'Negotiation/Review',
            'Amount'         => 30000
        });
        System.Assert.isTrue(r.contains('Opportunity Updated'));
    }

    // Jira V2-8418 — legacy nested fields shape back-compat for update_opportunity_fields
    @isTest
    static void opp_update_legacyFieldsMapStillWorks() {
        Opportunity o = anOpp();
        String r = handler().executeMethod('update_opportunity_fields', new Map<String, Object>{
            'opportunity_id' => o.Id,
            'fields'         => new Map<String, Object>{ 'StageName' => 'Closed Won', 'Amount' => 99999 }
        });
        System.Assert.isTrue(r.contains('Opportunity Updated'), 'Legacy nested fields shape should still update the Opportunity');
    }

    @isTest
    static void opp_logActivity_success() {
        Opportunity o = anOpp();
        String r = handler().executeMethod('log_activity', new Map<String, Object>{
            'record_id' => o.Id, 'activity_subject' => 'Prep call'
        });
        System.Assert.isTrue(r.contains('Activity Logged'));
    }

    @isTest
    static void opp_updateLineItem_success() {
        Product2 prod = new Product2(Name = 'Update Line Product', IsActive = true);
        insert prod;
        Id pbId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pbId, Product2Id = prod.Id, UnitPrice = 100, IsActive = true);
        insert pbe;
        Opportunity o = anOpp();
        o.Pricebook2Id = pbId;
        update o;
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = o.Id, PricebookEntryId = pbe.Id, Quantity = 2, UnitPrice = 100
        );
        insert oli;
        String r = handler().executeMethod('update_opportunity_line_item', new Map<String, Object>{
            'line_item_id' => oli.Id, 'Quantity' => 10, 'UnitPrice' => 95
        });
        System.Assert.isTrue(r.contains('Line Item Updated'));
    }

    @isTest
    static void opp_addLineItem_byProductName() {
        // Set up a product + active pricebook entry
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;
        Id pbId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pbId, Product2Id = prod.Id, UnitPrice = 100, IsActive = true);
        insert pbe;
        Opportunity o = anOpp();
        o.Pricebook2Id = pbId;
        update o;
        String r = handler().executeMethod('add_opportunity_line_item', new Map<String, Object>{
            'opportunity_id' => o.Id, 'product_name' => 'Test Product',
            'quantity' => 5, 'unit_price' => 120
        });
        System.Assert.isTrue(r.contains('Product Added'));
    }

    // ────────────────────────────────────────────────────────────────────────
    // CASE
    // ────────────────────────────────────────────────────────────────────────
    @isTest
    static void case_fuzzySearch_bySubject() {
        String r = handler().executeMethod('fuzzy_search_cases', new Map<String, Object>{ 'search_term' => 'coverage' });
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(true, m.get('success'));
        System.Assert.isNotNull(m.get('totalFound'));
    }

    @isTest
    static void case_addComment_success() {
        Case c = aCase();
        String r = handler().executeMethod('add_case_comment', new Map<String, Object>{
            'case_id' => c.Id, 'comment_body' => 'Customer confirmed fix works.'
        });
        System.Assert.isTrue(r.contains('Case Comment Added'));
    }

    @isTest
    static void case_fetchDetails_byCaseNumber() {
        Case c = aCase();
        String r = handler().executeMethod('fetch_case_details', new Map<String, Object>{ 'case_id' => c.CaseNumber });
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(true, m.get('success'));
    }

    @isTest
    static void case_create_success() {
        String r = handler().executeMethod('create_case', new Map<String, Object>{
            'Subject'  => 'New issue',
            'Priority' => 'High',
            'Status'   => 'New'
        });
        System.Assert.isTrue(r.contains('Case Created'));
    }

    // Jira V2-8418 — legacy nested fields shape back-compat
    @isTest
    static void case_create_legacyFieldsMapStillWorks() {
        String r = handler().executeMethod('create_case', new Map<String, Object>{
            'fields' => new Map<String, Object>{ 'Subject' => 'Legacy issue', 'Priority' => 'Medium' }
        });
        System.Assert.isTrue(r.contains('Case Created'), 'Legacy nested fields shape should still create the Case');
    }

    @isTest
    static void case_update_success() {
        Case c = aCase();
        String r = handler().executeMethod('update_case_fields', new Map<String, Object>{
            'case_id'  => c.Id,
            'Priority' => 'Low'
        });
        System.Assert.isTrue(r.contains('Case Updated'));
    }

    // Jira V2-8418 — legacy nested fields shape back-compat for update_case_fields
    @isTest
    static void case_update_legacyFieldsMapStillWorks() {
        Case c = aCase();
        String r = handler().executeMethod('update_case_fields', new Map<String, Object>{
            'case_id' => c.Id,
            'fields'  => new Map<String, Object>{ 'Priority' => 'Medium' }
        });
        System.Assert.isTrue(r.contains('Case Updated'), 'Legacy nested fields shape should still update the Case');
    }

    @isTest
    static void case_close_success() {
        Case c = aCase();
        String r = handler().executeMethod('close_case', new Map<String, Object>{
            'case_id' => c.Id, 'reason' => 'Other', 'comments' => 'Resolved during call'
        });
        System.Assert.isTrue(r.contains('Case Closed'));
    }

    @isTest
    static void case_close_alreadyClosedFails() {
        Case c = aCase();
        c.Status = 'Closed';
        update c;
        String r = handler().executeMethod('close_case', new Map<String, Object>{ 'case_id' => c.Id });
        System.Assert.isTrue(r.contains('already closed'));
    }

    // ────────────────────────────────────────────────────────────────────────
    // ACTIVITY (29-32)
    // ────────────────────────────────────────────────────────────────────────
    @isTest
    static void activity_createTask_success() {
        Account a = anAccount();
        String r = handler().executeMethod('create_task', new Map<String, Object>{
            'Subject'  => 'Follow up',
            'WhatId'   => a.Id,
            'Status'   => 'Not Started',
            'Priority' => 'High'
        });
        System.Assert.isTrue(r.contains('Task Created'));
    }

    // Jira V2-8418 — legacy nested fields shape back-compat for create_task
    @isTest
    static void activity_createTask_legacyFieldsMapStillWorks() {
        Account a = anAccount();
        String r = handler().executeMethod('create_task', new Map<String, Object>{
            'fields' => new Map<String, Object>{ 'Subject' => 'Legacy task', 'WhatId' => a.Id, 'Status' => 'Not Started' }
        });
        System.Assert.isTrue(r.contains('Task Created'), 'Legacy nested fields shape should still create the Task');
    }

    @isTest
    static void activity_createEvent_success() {
        Account a = anAccount();
        String r = handler().executeMethod('create_event', new Map<String, Object>{
            'Subject'           => 'Demo',
            'WhatId'            => a.Id,
            'StartDateTime'     => String.valueOf(Datetime.now().addDays(2)),
            'DurationInMinutes' => 60
        });
        System.Assert.isTrue(r.contains('Event Created'));
    }

    // Jira V2-8418 — legacy nested fields shape back-compat for create_event
    @isTest
    static void activity_createEvent_legacyFieldsMapStillWorks() {
        Account a = anAccount();
        String r = handler().executeMethod('create_event', new Map<String, Object>{
            'fields' => new Map<String, Object>{
                'Subject' => 'Legacy event', 'WhatId' => a.Id,
                'StartDateTime' => String.valueOf(Datetime.now().addDays(3)),
                'DurationInMinutes' => 30
            }
        });
        System.Assert.isTrue(r.contains('Event Created'), 'Legacy nested fields shape should still create the Event');
    }

    @isTest
    static void activity_updateTask_success() {
        Task t = aTask();
        String r = handler().executeMethod('update_task', new Map<String, Object>{
            'task_id' => t.Id, 'Priority' => 'High', 'Description' => 'Updated via test'
        });
        System.Assert.isTrue(r.contains('Task Updated'));
    }

    @isTest
    static void activity_updateEvent_success() {
        Account a = anAccount();
        Event e = new Event(
            Subject = 'Original demo',
            WhatId = a.Id,
            StartDateTime = Datetime.now().addDays(1),
            DurationInMinutes = 30
        );
        insert e;
        String r = handler().executeMethod('update_event', new Map<String, Object>{
            'event_id' => e.Id, 'Subject' => 'Rescheduled demo'
        });
        System.Assert.isTrue(r.contains('Event Updated'));
    }

    @isTest
    static void activity_fetchMyOpenTasks_returnsList() {
        String r = handler().executeMethod('fetch_my_open_tasks', new Map<String, Object>{ 'limit' => 10 });
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(true, m.get('success'));
        System.Assert.isTrue(((List<Object>) m.get('tasks')).size() >= 1);
    }

    @isTest
    static void activity_completeTask_success() {
        Task t = aTask();
        String r = handler().executeMethod('complete_task', new Map<String, Object>{ 'task_id' => t.Id });
        System.Assert.isTrue(r.contains('Task Completed'));
    }

    // ────────────────────────────────────────────────────────────────────────
    // PRODUCT (Wave 2)
    // ────────────────────────────────────────────────────────────────────────
    @isTest
    static void product_fuzzySearch_byName() {
        Product2 prod = new Product2(Name = 'Wave2 Widget Pro', ProductCode = 'W2W-100', IsActive = true);
        insert prod;
        String r = handler().executeMethod('fuzzy_search_products', new Map<String, Object>{ 'search_term' => 'Widget' });
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(true, m.get('success'));
        System.Assert.isTrue(((List<Object>) m.get('records')).size() >= 1);
    }

    @isTest
    static void product_fetchDetails_returnsData() {
        Product2 prod = new Product2(Name = 'Detail Product', IsActive = true);
        insert prod;
        String r = handler().executeMethod('fetch_product_details', new Map<String, Object>{ 'product_id' => prod.Id });
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(true, m.get('success'));
        System.Assert.areEqual('Detail Product', m.get('Name'));
    }

    @isTest
    static void product_fetchPricebookEntries_returnsList() {
        Product2 prod = new Product2(Name = 'PBE Product', IsActive = true);
        insert prod;
        Id pbId = Test.getStandardPricebookId();
        insert new PricebookEntry(Pricebook2Id = pbId, Product2Id = prod.Id, UnitPrice = 50, IsActive = true);
        String r = handler().executeMethod('fetch_pricebook_entries', new Map<String, Object>{
            'product_id' => prod.Id, 'pricebook_id' => pbId
        });
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(true, m.get('success'));
        System.Assert.isTrue(((List<Object>) m.get('entries')).size() >= 1);
    }

    // ────────────────────────────────────────────────────────────────────────
    // UTILITY (v1 + Wave 2)
    // ────────────────────────────────────────────────────────────────────────
    @isTest
    static void util_transferOwner_success() {
        Lead l = aLead();
        String r = handler().executeMethod('transfer_record_owner', new Map<String, Object>{
            'record_id' => l.Id, 'new_owner_id' => UserInfo.getUserId()
        });
        System.Assert.isTrue(r.contains('Owner Transferred') || r.contains('already owned'));
    }

    @isTest
    static void util_runInternalPrompt_bypassPath() {
        Account a = anAccount();
        AgenticSkillsBase.bypassPromptForUnitTest = true;
        String r = handler().executeMethod('run_internal_prompt', new Map<String, Object>{
            'prompt_request_id' => 'fake-id', 'record_id' => a.Id
        });
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(true, m.get('success'));
        System.Assert.areEqual('UNIT_TEST_PLACEHOLDER', m.get('message'));
    }

    @isTest
    static void util_runInternalPrompt_missingParamsFail() {
        String r = handler().executeMethod('run_internal_prompt', new Map<String, Object>());
        System.Assert.areEqual(false, deserialize(r).get('success'));
    }

    @isTest
    static void util_picklistValues_industry() {
        String r = handler().executeMethod('fetch_picklist_values', new Map<String, Object>{
            'object_api_name' => 'Account', 'field_api_name' => 'Industry'
        });
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(true, m.get('success'));
        System.Assert.isTrue(((List<Object>) m.get('values')).size() > 0);
    }

    @isTest
    static void util_picklistValues_invalidFieldFails() {
        String r = handler().executeMethod('fetch_picklist_values', new Map<String, Object>{
            'object_api_name' => 'Account', 'field_api_name' => 'NotARealField'
        });
        System.Assert.areEqual(false, deserialize(r).get('success'));
    }

    @isTest
    static void util_picklistValues_nonPicklistFieldFails() {
        String r = handler().executeMethod('fetch_picklist_values', new Map<String, Object>{
            'object_api_name' => 'Account', 'field_api_name' => 'Name'
        });
        System.Assert.areEqual(false, deserialize(r).get('success'));
    }

    @isTest
    static void util_fetchSessionContext_accountMapsToWhatId() {
        Account a = anAccount();
        String r = handler().executeMethod('fetch_session_context', new Map<String, Object>{
            'userContextId' => 'conv_test_123',
            'record_id' => a.Id
        });
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(true, m.get('success'));
        System.Assert.areEqual('conv_test_123', m.get('userContextId'));
        System.Assert.areEqual(a.Id, m.get('recordId'));
        System.Assert.areEqual(a.Id, m.get('WhatId'));
        System.Assert.areEqual('WhatId', m.get('relationType'));
        System.Assert.isNull(m.get('WhoId'));
        System.Assert.isTrue(String.valueOf(m.get('message')).contains('User Context Id: conv_test_123'));
        System.Assert.isTrue(String.valueOf(m.get('message')).contains('Record Id: ' + a.Id));
    }

    @isTest
    static void util_fetchSessionContext_contactMapsToWhoId() {
        Account a = anAccount();
        Contact c = new Contact(LastName = 'CtxTest', AccountId = a.Id);
        insert c;
        String r = handler().executeMethod('fetch_session_context', new Map<String, Object>{
            'userContextId' => 'conv_test_456',
            'recordId' => c.Id
        });
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(true, m.get('success'));
        System.Assert.areEqual(c.Id, m.get('WhoId'));
        System.Assert.areEqual('WhoId', m.get('relationType'));
        System.Assert.isNull(m.get('WhatId'));
    }

    @isTest
    static void util_fetchSessionContext_noRecordStillReturnsUserContext() {
        String r = handler().executeMethod('fetch_session_context', new Map<String, Object>{
            'userContextId' => 'conv_only'
        });
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(true, m.get('success'));
        System.Assert.areEqual('conv_only', m.get('userContextId'));
        System.Assert.isNull(m.get('recordId'));
        System.Assert.isNull(m.get('WhoId'));
        System.Assert.isNull(m.get('WhatId'));
    }

    @isTest
    static void utilityHandler_directInvocationForCoverage() {
        UtilityAgenticSkillsHandler utility = new UtilityAgenticSkillsHandler();
        Contact c = aContact();

        String session = utility.executeMethod('fetch_session_context', new Map<String, Object>{
            'userContextId' => 'conv_direct',
            'record_id' => c.Id
        });
        System.Assert.areEqual(true, deserialize(session).get('success'));

        String picklist = utility.executeMethod('fetch_picklist_values', new Map<String, Object>{
            'object_api_name' => 'Case',
            'field_api_name' => 'Status'
        });
        System.Assert.areEqual(true, deserialize(picklist).get('success'));

        AgenticSkillsBase.bypassPromptForUnitTest = true;
        String prompt = utility.executeMethod('run_internal_prompt', new Map<String, Object>{
            'prompt_request_id' => 'test-prompt-id',
            'record_id' => c.Id
        });
        AgenticSkillsBase.bypassPromptForUnitTest = false;
        System.Assert.areEqual(true, deserialize(prompt).get('success'));

        String ctxFromId = utility.executeMethod('fetch_session_context', new Map<String, Object>{
            'userContextId' => String.valueOf(c.Id)
        });
        System.Assert.areEqual(c.Id, deserialize(ctxFromId).get('recordId'));

        System.Assert.areEqual(false, deserialize(utility.executeMethod('fetch_picklist_values', new Map<String, Object>())).get('success'));
        System.Assert.areEqual(false, deserialize(utility.executeMethod('run_internal_prompt', new Map<String, Object>())).get('success'));
        System.Assert.areEqual(false, deserialize(utility.executeMethod('run_internal_prompt', new Map<String, Object>{
            'prompt_request_id' => 'bad', 'record_id' => 'not-an-id'
        })).get('success'));

        String xfer = utility.executeMethod('transfer_record_owner', new Map<String, Object>());
        System.Assert.isTrue(String.valueOf(xfer).contains('Missing parameter'));
    }

    @isTest
    static void base_sessionContextHelpers() {
        Contact c = aContact();
        Account a = anAccount();
        System.Assert.isTrue(AgenticSkillsBase.isSalesforceIdToken(String.valueOf(c.Id)));
        System.Assert.areEqual(c.Id, AgenticSkillsBase.parseSalesforceId(String.valueOf(c.Id)));
        System.Assert.isTrue(AgenticSkillsBase.isWhoIdObject(c.Id));
        System.Assert.isFalse(AgenticSkillsBase.isWhoIdObject(a.Id));
        System.Assert.isNotNull(AgenticSkillsBase.buildSessionContextMessage('ctx', c.Id, new Map<String, Object>{
            'objectType' => 'Contact', 'relationType' => 'WhoId', 'WhoId' => c.Id
        }));
    }

    // ────────────────────────────────────────────────────────────────────────
    // Helper coverage — fuzzy candidate generator + parseToDate edge cases
    // ────────────────────────────────────────────────────────────────────────
    @isTest
    static void fuzzyCandidates_handlesVariations() {
        List<String> a = AgenticSkillsBase.buildFuzzySearchCandidates('the Power Grid');
        System.Assert.isTrue(a.size() > 0);
        List<String> b = AgenticSkillsBase.buildFuzzySearchCandidates('  ');
        System.Assert.areEqual(0, b.size());
    }

    // ────────────────────────────────────────────────────────────────────────
    // WAVE 13
    // ────────────────────────────────────────────────────────────────────────
    @isTest
    static void wave13_fetchUpcomingRenewals_returnsJson() {
        String r = handler().executeMethod('fetch_upcoming_renewals', new Map<String, Object>{ 'days_ahead' => 90 });
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(true, m.get('success'), r);
        System.Assert.isTrue(m.containsKey('records'));
    }

    @isTest
    static void wave13_fetchAccountPlan_requiresAccountId() {
        String r = handler().executeMethod('fetch_account_plan', new Map<String, Object>());
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(false, m.get('success'));
    }

    @isTest
    static void wave13_fetchAccountPlan_byAccountId() {
        Account a = anAccount();
        String r = handler().executeMethod('fetch_account_plan', new Map<String, Object>{ 'account_id' => a.Id });
        Map<String, Object> m = deserialize(r);
        if (m.get('success') == true) {
            System.Assert.isTrue(m.containsKey('plans'));
        } else {
            System.Assert.isTrue(String.valueOf(m.get('error')).contains('not available')
                || String.valueOf(m.get('error')).contains('Account Plan'));
        }
    }

    @isTest
    static void wave13_fetchContactEngagementHistory() {
        Contact c = aContact();
        String r = handler().executeMethod('fetch_contact_engagement_history', new Map<String, Object>{
            'contact_id' => c.Id, 'days_back' => 365
        });
        Map<String, Object> m = deserialize(r);
        System.Assert.areEqual(true, m.get('success'), r);
        System.Assert.isTrue(m.containsKey('engagement'));
    }

    // ────────────────────────────────────────────────────────────────────────
    // Facade — all skills dispatch without exception
    // ────────────────────────────────────────────────────────────────────────
    @isTest
    static void facade_allSkillsDispatchReturnPayload() {
        List<String> allSkills = new List<String>{
            'fuzzy_search_accounts','fetch_account_details','create_account','update_account_fields','fetch_account_related_lists',
            'fuzzy_search_contacts','fetch_contact_details','create_contact','update_contact_fields',
            'fuzzy_search_leads','fetch_lead_details','create_lead','update_lead_fields','convert_lead',
            'fetch_opportunity_details','create_opportunity','update_opportunity_fields','add_opportunity_line_item','update_opportunity_line_item',
            'fetch_case_details','create_case','update_case_fields','close_case',
            'log_activity','create_task','update_task','create_event','update_event','fetch_my_open_tasks','complete_task',
            'fetch_session_context','fetch_picklist_values','run_internal_prompt',
            'fuzzy_search_opportunities','fuzzy_search_cases','add_case_comment',
            'fuzzy_search_products','fetch_product_details','fetch_pricebook_entries','transfer_record_owner',
            'fuzzy_search_campaigns','fetch_campaign_details','create_campaign','update_campaign_fields',
            'fetch_campaign_members','add_campaign_member','update_campaign_member_status',
            'fuzzy_search_quotes','fetch_quote_details','create_quote','update_quote_fields','add_quote_line_item','update_quote_line_item',
            'fetch_opportunity_contact_roles','add_opportunity_contact_role','update_opportunity_contact_role',
            'fetch_opportunity_team','add_opportunity_team_member','fetch_my_open_opportunities','fetch_stale_opportunities','clone_opportunity',
            'fetch_contract_details','create_contract','update_contract_fields',
            'fetch_case_team','add_case_team_member','search_knowledge_articles','fetch_knowledge_article','link_knowledge_article_to_case',
            'fetch_case_milestones','fetch_case_entitlements','assign_to_queue','fetch_queue_cases',
            'fuzzy_search_assets','fetch_asset_details','update_asset_fields',
            'fetch_work_order_details','create_work_order','update_work_order_fields',
            'fetch_service_appointment','schedule_service_appointment','update_service_appointment','fetch_service_resource_availability',
            'fetch_cpq_quote_details','create_cpq_quote','update_cpq_quote_fields','add_cpq_quote_line','update_cpq_quote_line','calculate_cpq_quote',
            'fetch_order_details','create_order','update_order_fields','add_order_item','update_order_item',
            'fetch_subscription_details','update_subscription_fields',
            'fuzzy_search_partners','fetch_partner_account','add_opportunity_partner','fetch_opportunity_partners',
            'fetch_financial_account','update_financial_account_fields','fetch_care_plan',
            'fetch_record_approvals','fetch_renewal_opportunities','remove_campaign_member','create_care_task','update_care_plan_fields',
            'fetch_upcoming_renewals','fetch_account_plan','fetch_contact_engagement_history'
        };
        System.Assert.areEqual(111, allSkills.size(), 'Master skill count');
        GenericAgenticSkillsHandler facade = handler();
        for (String skill : allSkills) {
            String r = facade.executeMethod(skill, new Map<String, Object>());
            System.Assert.isFalse(String.isBlank(r), 'Empty response for ' + skill);
            System.Assert.isTrue(
                r.startsWith('{') || r.startsWith('<'),
                'Expected JSON or HTML for ' + skill + ': ' + r.left(80)
            );
        }
    }
}
