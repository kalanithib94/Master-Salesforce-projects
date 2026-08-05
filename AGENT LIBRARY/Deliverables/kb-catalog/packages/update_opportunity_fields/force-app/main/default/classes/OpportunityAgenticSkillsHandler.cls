/**
 * @description Opportunity object skills for the GPTfy Agent Library (13 skills).
 *              Implements ccai.AIAgenticInterface; shared helpers live in AgenticSkillsBase.
 * @author      : Plumcloud Labs
 * @group       : GPTfy Agent Library
 * @jira        : V2-8418
 */
global with sharing class OpportunityAgenticSkillsHandler implements ccai.AIAgenticInterface {

    global String executeMethod(String methodName, Map<String, Object> parameters) {
        try {
            if (parameters == null) parameters = new Map<String, Object>();
            String m = String.isBlank(methodName) ? '' : methodName.trim();
            switch on m {
                when 'fuzzy_search_opportunities' { return handleFuzzySearchOpportunities(parameters); }
                when 'fetch_opportunity_details' { return handleFetchOpportunityDetails(parameters); }
                when 'create_opportunity' { return handleCreateOpportunity(parameters); }
                when 'update_opportunity_fields' { return handleUpdateOpportunityFields(parameters); }
                when 'add_opportunity_line_item' { return handleAddOpportunityLineItem(parameters); }
                when 'update_opportunity_line_item' { return handleUpdateOpportunityLineItem(parameters); }
                when 'fetch_opportunity_contact_roles' { return handleFetchOpportunityContactRoles(parameters); }
                when 'add_opportunity_contact_role' { return handleAddOpportunityContactRole(parameters); }
                when 'update_opportunity_contact_role' { return handleUpdateOpportunityContactRole(parameters); }
                when 'fetch_opportunity_team' { return handleFetchOpportunityTeam(parameters); }
                when 'add_opportunity_team_member' { return handleAddOpportunityTeamMember(parameters); }
                when 'clone_opportunity' { return handleCloneOpportunity(parameters); }
                when 'fetch_opportunity_partners' { return handleFetchOpportunityPartners(parameters); }
                when else { return AgenticSkillsBase.errorJson('Unsupported skill: ' + methodName); }
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'OpportunityAgenticSkillsHandler | ' + methodName + ' | ' + ex.getMessage());
            return AgenticSkillsBase.errorJson(ex.getMessage());
        }
    }

    /**
     * @description Skill — fuzzy_search_opportunities. Accepts Name or Opportunity Id (006…).
     * @jira V2-8418
     */
    private String handleFuzzySearchOpportunities(Map<String, Object> p) {
        String term = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'search_term', 'name' }));
        if (String.isBlank(term)) return AgenticSkillsBase.errorJson('Missing required parameter: search_term');
        if (!Schema.sObjectType.Opportunity.isAccessible()) return AgenticSkillsBase.errorJson('Opportunity is not accessible.');

        if (AgenticSkillsBase.isSalesforceIdToken(term)) {
            Id oid = AgenticSkillsBase.parseSalesforceId(term);
            if (oid != null && oid.getSObjectType() == Opportunity.SObjectType) {
                List<Opportunity> byId = [
                    SELECT Id, Name, StageName, CloseDate, Amount
                    FROM Opportunity WHERE Id = :oid WITH USER_MODE LIMIT 1
                ];
                if (byId.isEmpty()) return AgenticSkillsBase.errorJson('No opportunity found for provided Id.');
                Opportunity o = byId[0];
                Map<String, Object> row = new Map<String, Object>{
                    'Id' => o.Id, 'Name' => o.Name, 'StageName' => o.StageName,
                    'CloseDate' => String.valueOf(o.CloseDate), 'Amount' => o.Amount,
                    'recordUrl' => AgenticSkillsBase.recordUrl(o.Id),
                    'viewRecord' => AgenticSkillsBase.viewRecordAnchor(o.Id)
                };
                return AgenticSkillsBase.successJson(new Map<String, Object>{
                    'status' => 'found', 'matchedVia' => 'id',
                    'totalFound' => 1, 'displayed' => 1, 'remaining' => 0,
                    'records' => new List<Object>{ row }
                });
            }
        }

        List<SObject> all = AgenticSkillsBase.fuzzyQuery(
            'Opportunity', 'Name', new List<String>{ 'StageName', 'CloseDate', 'Amount' }, term
        );
        if (all.isEmpty()) return AgenticSkillsBase.errorJson('No opportunity found matching "' + term + '".');
        Map<String, Object> sliced = AgenticSkillsBase.applyTopNAndCount(all, AgenticSkillsBase.FUZZY_DISPLAY_LIMIT);
        List<SObject> top = (List<SObject>) sliced.get('rows');
        List<Map<String, Object>> records = new List<Map<String, Object>>();
        for (SObject r : top) {
            Id rid = (Id) r.get('Id');
            records.add(new Map<String, Object>{
                'Id' => rid, 'Name' => r.get('Name'), 'StageName' => r.get('StageName'),
                'CloseDate' => String.valueOf(r.get('CloseDate')), 'Amount' => r.get('Amount'),
                'recordUrl' => AgenticSkillsBase.recordUrl(rid),
                'viewRecord' => AgenticSkillsBase.viewRecordAnchor(rid)
            });
        }
        return AgenticSkillsBase.successJson(new Map<String, Object>{
            'status' => 'found', 'matchedVia' => 'name',
            'totalFound' => sliced.get('totalFound'),
            'displayed' => sliced.get('displayed'),
            'remaining' => sliced.get('remaining'),
            'records' => records
        });
    }

    /**
     * @description Skill — fetch_opportunity_details.
     * @jira V2-8418
     */
    private String handleFetchOpportunityDetails(Map<String, Object> p) {
        String oid = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'opportunity_id', 'recordId', 'Id' }));
        if (String.isBlank(oid)) return AgenticSkillsBase.errorJson('Missing required parameter: opportunity_id');
        if (!Schema.sObjectType.Opportunity.isAccessible()) return AgenticSkillsBase.errorJson('Opportunity is not accessible.');
        List<Opportunity> rows = [
            SELECT Id, Name, StageName, Amount, CloseDate, Probability, ForecastCategoryName,
                   AccountId, Account.Name, OwnerId, Owner.Name, Description, Type, LeadSource
            FROM Opportunity WHERE Id = :oid WITH USER_MODE LIMIT 1
        ];
        if (rows.isEmpty()) return AgenticSkillsBase.errorJson('No opportunity found for provided Id.');
        Opportunity o = rows[0];
        return AgenticSkillsBase.successJson(new Map<String, Object>{
            'Id' => o.Id, 'Name' => o.Name, 'StageName' => o.StageName,
            'Amount' => o.Amount, 'CloseDate' => String.valueOf(o.CloseDate),
            'Probability' => o.Probability, 'ForecastCategory' => o.ForecastCategoryName,
            'Account' => o.Account != null ? o.Account.Name : null,
            'Owner' => o.Owner != null ? o.Owner.Name : null,
            'Description' => o.Description, 'Type' => o.Type, 'LeadSource' => o.LeadSource,
            'currentdate__c' => String.valueOf(Date.today()),
            'recordUrl' => AgenticSkillsBase.recordUrl(o.Id)
        });
    }

    /**
     * @description Skill — create_opportunity.
     * @jira V2-8418
     */
    private String handleCreateOpportunity(Map<String, Object> p) {
        if (!Schema.sObjectType.Opportunity.isCreateable()) return AgenticSkillsBase.errorHtml('Could not create opportunity', 'Opportunity is not creatable.');
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, null);
        for (String required : new List<String>{ 'Name', 'StageName', 'CloseDate' }) {
            if (!fields.containsKey(required) || String.isBlank(AgenticSkillsBase.toText(fields.get(required)))) {
                return AgenticSkillsBase.errorHtml('Could not create opportunity', required + ' is required.');
            }
        }
        try {
            Opportunity o = new Opportunity();
            AgenticSkillsBase.applyFieldsToSObject(o, fields, false);
            insert o;
            String body = '<ul><li><b>Name:</b> ' + AgenticSkillsBase.escapeHtml(String.valueOf(fields.get('Name'))) + '</li>'
                        + '<li><b>Stage:</b> ' + AgenticSkillsBase.escapeHtml(String.valueOf(fields.get('StageName'))) + '</li>'
                        + '<li><b>Close Date:</b> ' + AgenticSkillsBase.escapeHtml(String.valueOf(fields.get('CloseDate'))) + '</li></ul>';
            return AgenticSkillsBase.successHtml('Opportunity Created', body, o.Id, 'View Opportunity');
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not create opportunity', ex.getMessage());
        }
    }

    /**
     * @description Skill — update_opportunity_fields.
     * @jira V2-8418
     */
    private String handleUpdateOpportunityFields(Map<String, Object> p) {
        String oid = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'opportunity_id', 'recordId', 'Id' }));
        if (String.isBlank(oid)) return AgenticSkillsBase.errorHtml('Could not update opportunity', 'Missing parameter: opportunity_id');
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, new Set<String>{ 'opportunity_id', 'recordId', 'Id' });
        if (fields.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update opportunity', 'Missing parameter: at least one field to update');
        if (!Schema.sObjectType.Opportunity.isUpdateable()) return AgenticSkillsBase.errorHtml('Could not update opportunity', 'Opportunity is not updateable.');
        List<Opportunity> rows = [SELECT Id, Name FROM Opportunity WHERE Id = :oid WITH USER_MODE LIMIT 1];
        if (rows.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update opportunity', 'No opportunity found for provided Id.');
        return AgenticSkillsBase.performGenericUpdate('Opportunity', oid, fields, 'Opportunity Updated', 'View Opportunity', rows[0].Name);
    }

    /**
     * @description Skill — add_opportunity_line_item.
     * @jira V2-8418
     */
    private String handleAddOpportunityLineItem(Map<String, Object> p) {
        Id oid = AgenticSkillsBase.resolveLookupId(p, 'OpportunityId');
        if (oid == null) {
            oid = AgenticSkillsBase.parseSalesforceId(AgenticSkillsBase.toText(
                AgenticSkillsBase.firstNonBlank(p, new List<String>{ 'opportunity_id', 'recordId', 'Id' })
            ));
        }
        Object qtyRaw = AgenticSkillsBase.firstNonBlank(p, new List<String>{ 'Quantity', 'quantity' });
        Object priceRaw = AgenticSkillsBase.firstNonBlank(p, new List<String>{ 'UnitPrice', 'unit_price', 'unitPrice' });
        if (oid == null) return AgenticSkillsBase.errorHtml('Could not add line item', 'Missing parameter: OpportunityId');
        if (qtyRaw == null) return AgenticSkillsBase.errorHtml('Could not add line item', 'Missing parameter: Quantity');
        if (priceRaw == null) return AgenticSkillsBase.errorHtml('Could not add line item', 'Missing parameter: UnitPrice');
        if (!Schema.sObjectType.OpportunityLineItem.isCreateable()) return AgenticSkillsBase.errorHtml('Could not add line item', 'OpportunityLineItem is not creatable.');
        List<Opportunity> opps = [SELECT Id, Pricebook2Id FROM Opportunity WHERE Id = :oid WITH USER_MODE LIMIT 1];
        if (opps.isEmpty()) return AgenticSkillsBase.errorHtml('Could not add line item', 'No opportunity found for provided OpportunityId.');
        Id pbeId;
        String pbeRaw = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonBlank(p, new List<String>{
            'PricebookEntryId', 'pricebook_entry_id', 'pricebookEntryId'
        }));
        if (String.isNotBlank(pbeRaw)) {
            try { pbeId = Id.valueOf(pbeRaw); } catch (Exception e) { return AgenticSkillsBase.errorHtml('Could not add line item', 'Invalid PricebookEntryId.'); }
        } else {
            String pname = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonBlank(p, new List<String>{
                'Name', 'product_name', 'productName'
            }));
            if (String.isBlank(pname)) return AgenticSkillsBase.errorHtml('Could not add line item', 'Provide PricebookEntryId or Name (product).');
            List<PricebookEntry> pbes = [
                SELECT Id FROM PricebookEntry
                WHERE Product2.Name = :pname AND IsActive = true AND Pricebook2Id = :opps[0].Pricebook2Id
                WITH USER_MODE LIMIT 1
            ];
            if (pbes.isEmpty()) return AgenticSkillsBase.errorHtml('Could not add line item', 'No active PricebookEntry found for "' + pname + '" on this opportunity\'s pricebook.');
            pbeId = pbes[0].Id;
        }
        try {
            OpportunityLineItem oli = new OpportunityLineItem(
                OpportunityId = oid, PricebookEntryId = pbeId,
                Quantity = Decimal.valueOf(String.valueOf(qtyRaw)),
                UnitPrice = Decimal.valueOf(String.valueOf(priceRaw))
            );
            insert oli;
            String body = '<ul><li><b>Quantity:</b> ' + AgenticSkillsBase.escapeHtml(String.valueOf(qtyRaw)) + '</li>'
                        + '<li><b>Unit Price:</b> ' + AgenticSkillsBase.escapeHtml(String.valueOf(priceRaw)) + '</li></ul>';
            return AgenticSkillsBase.successHtml('Product Added to Opportunity', body, oli.Id, 'View Line Item');
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not add line item', ex.getMessage());
        }
    }

    /**
     * @description Skill — update_opportunity_line_item (Quantity, UnitPrice, etc.).
     * @jira V2-8418
     */
    private String handleUpdateOpportunityLineItem(Map<String, Object> p) {
        String oliId = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'line_item_id', 'opportunity_line_item_id', 'recordId', 'Id' }));
        if (String.isBlank(oliId)) return AgenticSkillsBase.errorHtml('Could not update line item', 'Missing parameter: line_item_id');
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, new Set<String>{ 'line_item_id', 'opportunity_line_item_id', 'recordId', 'Id', 'opportunity_id' });
        if (fields.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update line item', 'Missing parameter: at least one field to update');
        if (!Schema.sObjectType.OpportunityLineItem.isUpdateable()) return AgenticSkillsBase.errorHtml('Could not update line item', 'OpportunityLineItem is not updateable.');
        List<OpportunityLineItem> rows = [
            SELECT Id, OpportunityId, Quantity, UnitPrice
            FROM OpportunityLineItem WHERE Id = :oliId WITH USER_MODE LIMIT 1
        ];
        if (rows.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update line item', 'No line item found for provided Id.');
        String label = 'Line item (' + String.valueOf(rows[0].Quantity) + ' @ ' + String.valueOf(rows[0].UnitPrice) + ')';
        return AgenticSkillsBase.performGenericUpdate('OpportunityLineItem', oliId, fields, 'Line Item Updated', 'View Line Item', label);
    }

    private String handleFetchOpportunityContactRoles(Map<String, Object> p) {
        Id oid = AgenticSkillsBase.resolveLookupId(p, 'OpportunityId');
        if (oid == null) {
            oid = AgenticSkillsBase.parseSalesforceId(AgenticSkillsBase.toText(
                AgenticSkillsBase.firstNonBlank(p, new List<String>{ 'opportunity_id', 'recordId', 'Id' })
            ));
        }
        if (oid == null) return AgenticSkillsBase.errorJson('Missing required parameter: OpportunityId');
        if (!Schema.sObjectType.OpportunityContactRole.isAccessible()) {
            return AgenticSkillsBase.errorJson('OpportunityContactRole is not accessible.');
        }
        List<OpportunityContactRole> roles = [
            SELECT Id, ContactId, Contact.Name, Role, IsPrimary
            FROM OpportunityContactRole
            WHERE OpportunityId = :oid
            WITH USER_MODE
            ORDER BY IsPrimary DESC, Contact.Name ASC
            LIMIT 50
        ];
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        for (OpportunityContactRole ocr : roles) {
            rows.add(new Map<String, Object>{
                'Id' => ocr.Id, 'ContactId' => ocr.ContactId,
                'ContactName' => ocr.Contact != null ? ocr.Contact.Name : null,
                'Role' => ocr.Role, 'IsPrimary' => ocr.IsPrimary,
                'recordUrl' => AgenticSkillsBase.recordUrl(ocr.Id)
            });
        }
        return AgenticSkillsBase.successJson(new Map<String, Object>{
            'OpportunityId' => oid, 'count' => rows.size(), 'contactRoles' => rows
        });
    }

    private String handleAddOpportunityContactRole(Map<String, Object> p) {
        Id oid = AgenticSkillsBase.resolveLookupId(p, 'OpportunityId');
        if (oid == null) {
            oid = AgenticSkillsBase.parseSalesforceId(AgenticSkillsBase.toText(
                AgenticSkillsBase.firstNonBlank(p, new List<String>{ 'opportunity_id', 'recordId' })
            ));
        }
        Id contactId = AgenticSkillsBase.resolveLookupId(p, 'ContactId');
        String role = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonBlank(p, new List<String>{ 'Role', 'role' }));
        if (oid == null) return AgenticSkillsBase.errorHtml('Could not add contact role', 'Missing parameter: OpportunityId');
        if (contactId == null) return AgenticSkillsBase.errorHtml('Could not add contact role', 'Missing parameter: ContactId');
        if (String.isBlank(role)) return AgenticSkillsBase.errorHtml('Could not add contact role', 'Missing parameter: Role');
        if (!Schema.sObjectType.OpportunityContactRole.isCreateable()) {
            return AgenticSkillsBase.errorHtml('Could not add contact role', 'OpportunityContactRole is not creatable.');
        }
        try {
            OpportunityContactRole ocr = new OpportunityContactRole(
                OpportunityId = oid, ContactId = contactId, Role = role
            );
            Object primaryRaw = AgenticSkillsBase.firstNonBlank(p, new List<String>{ 'IsPrimary', 'is_primary' });
            if (primaryRaw != null && !AgenticSkillsBase.isBlankish(primaryRaw)) {
                ocr.IsPrimary = Boolean.valueOf(AgenticSkillsBase.toText(primaryRaw));
            }
            insert ocr;
            String body = '<ul><li><b>Role:</b> ' + AgenticSkillsBase.escapeHtml(role) + '</li></ul>';
            return AgenticSkillsBase.successHtml('Contact Role Added', body, ocr.Id, 'View Contact Role');
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not add contact role', ex.getMessage());
        }
    }

    private String handleUpdateOpportunityContactRole(Map<String, Object> p) {
        String ocrId = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'contact_role_id', 'recordId', 'Id' }));
        if (String.isBlank(ocrId)) return AgenticSkillsBase.errorHtml('Could not update contact role', 'Missing parameter: contact_role_id');
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, new Set<String>{ 'contact_role_id', 'recordId', 'Id', 'opportunity_id' });
        if (fields.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update contact role', 'Missing parameter: at least one field to update');
        if (!Schema.sObjectType.OpportunityContactRole.isUpdateable()) {
            return AgenticSkillsBase.errorHtml('Could not update contact role', 'OpportunityContactRole is not updateable.');
        }
        List<OpportunityContactRole> rows = [
            SELECT Id, Contact.Name, Role FROM OpportunityContactRole WHERE Id = :ocrId WITH USER_MODE LIMIT 1
        ];
        if (rows.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update contact role', 'No contact role found for provided Id.');
        String label = rows[0].Contact != null ? rows[0].Contact.Name + ' (' + rows[0].Role + ')' : rows[0].Role;
        return AgenticSkillsBase.performGenericUpdate('OpportunityContactRole', ocrId, fields, 'Contact Role Updated', 'View Contact Role', label);
    }

    private String handleFetchOpportunityTeam(Map<String, Object> p) {
        Id oid = AgenticSkillsBase.resolveLookupId(p, 'OpportunityId');
        if (oid == null) {
            oid = AgenticSkillsBase.parseSalesforceId(AgenticSkillsBase.toText(
                AgenticSkillsBase.firstNonBlank(p, new List<String>{ 'opportunity_id', 'recordId', 'Id' })
            ));
        }
        if (oid == null) return AgenticSkillsBase.errorJson('Missing required parameter: OpportunityId');
        if (!Schema.sObjectType.OpportunityTeamMember.isAccessible()) {
            return AgenticSkillsBase.errorJson('OpportunityTeamMember is not accessible.');
        }
        List<OpportunityTeamMember> members = [
            SELECT Id, UserId, User.Name, TeamMemberRole
            FROM OpportunityTeamMember
            WHERE OpportunityId = :oid
            WITH USER_MODE
            ORDER BY User.Name ASC
            LIMIT 50
        ];
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        for (OpportunityTeamMember otm : members) {
            rows.add(new Map<String, Object>{
                'Id' => otm.Id, 'UserId' => otm.UserId,
                'UserName' => otm.User != null ? otm.User.Name : null,
                'TeamMemberRole' => otm.TeamMemberRole,
                'recordUrl' => AgenticSkillsBase.recordUrl(otm.Id)
            });
        }
        return AgenticSkillsBase.successJson(new Map<String, Object>{
            'OpportunityId' => oid, 'count' => rows.size(), 'teamMembers' => rows
        });
    }

    private String handleAddOpportunityTeamMember(Map<String, Object> p) {
        String oid = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'opportunity_id', 'recordId' }));
        String userId = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'user_id', 'UserId' }));
        String teamRole = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'team_member_role', 'TeamMemberRole', 'role' }));
        if (String.isBlank(oid)) return AgenticSkillsBase.errorHtml('Could not add team member', 'Missing parameter: opportunity_id');
        if (String.isBlank(userId)) return AgenticSkillsBase.errorHtml('Could not add team member', 'Missing parameter: user_id');
        if (String.isBlank(teamRole)) return AgenticSkillsBase.errorHtml('Could not add team member', 'Missing parameter: team_member_role');
        if (!Schema.sObjectType.OpportunityTeamMember.isCreateable()) {
            return AgenticSkillsBase.errorHtml('Could not add team member', 'OpportunityTeamMember is not creatable.');
        }
        try {
            OpportunityTeamMember otm = new OpportunityTeamMember(
                OpportunityId = oid, UserId = userId, TeamMemberRole = teamRole
            );
            insert otm;
            String body = '<ul><li><b>Team role:</b> ' + AgenticSkillsBase.escapeHtml(teamRole) + '</li></ul>';
            return AgenticSkillsBase.successHtml('Team Member Added', body, otm.Id, 'View Team Member');
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not add team member', ex.getMessage());
        }
    }

    private String handleCloneOpportunity(Map<String, Object> p) {
        Id oid = AgenticSkillsBase.resolvePrimaryId(p, 'Opportunity');
        if (oid == null) return AgenticSkillsBase.errorHtml('Could not clone opportunity', 'Missing parameter: Id (Opportunity Id).');
        if (!Schema.sObjectType.Opportunity.isCreateable()) {
            return AgenticSkillsBase.errorHtml('Could not clone opportunity', 'Opportunity is not creatable.');
        }
        List<Opportunity> source = [
            SELECT Id, Name, AccountId, StageName, CloseDate, Amount, Type, LeadSource,
                   Description, Probability, Pricebook2Id
            FROM Opportunity WHERE Id = :oid WITH USER_MODE LIMIT 1
        ];
        if (source.isEmpty()) return AgenticSkillsBase.errorHtml('Could not clone opportunity', 'No opportunity found for provided Id.');
        try {
            Opportunity src = source[0];
            String newName = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonBlank(p, new List<String>{ 'Name', 'name' }));
            if (String.isBlank(newName)) newName = src.Name + ' Copy';
            Opportunity clone = new Opportunity(
                Name = newName,
                AccountId = src.AccountId,
                StageName = src.StageName,
                CloseDate = src.CloseDate,
                Amount = src.Amount,
                Type = src.Type,
                LeadSource = src.LeadSource,
                Description = src.Description,
                Probability = src.Probability,
                Pricebook2Id = src.Pricebook2Id
            );
            insert clone;
            String body = '<ul><li><b>Name:</b> ' + AgenticSkillsBase.escapeHtml(clone.Name) + '</li>'
                        + '<li><b>Stage:</b> ' + AgenticSkillsBase.escapeHtml(clone.StageName) + '</li>'
                        + '<li><b>Cloned from:</b> ' + AgenticSkillsBase.escapeHtml(src.Name) + '</li></ul>';
            return AgenticSkillsBase.successHtml('Opportunity Cloned', body, clone.Id, 'View Opportunity');
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not clone opportunity', ex.getMessage());
        }
    }

    private String handleFetchOpportunityPartners(Map<String, Object> p) {
        String oid = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'opportunity_id', 'recordId', 'Id' }));
        if (String.isBlank(oid)) return AgenticSkillsBase.errorJson('Missing required parameter: opportunity_id');
        Schema.SObjectType partnerType = Schema.getGlobalDescribe().get('OpportunityPartner');
        if (partnerType == null || !partnerType.getDescribe().isAccessible()) {
            return AgenticSkillsBase.successJson(new Map<String, Object>{
                'status' => 'unavailable',
                'message' => 'OpportunityPartner is not available in this org.',
                'opportunityId' => oid
            });
        }
        try {
            List<SObject> partners = Database.query(
                'SELECT Id, AccountToId, AccountTo.Name, Role, IsPrimary, ReversePartnerId'
                + ' FROM OpportunityPartner WHERE OpportunityId = :oid WITH USER_MODE ORDER BY IsPrimary DESC LIMIT 50'
            );
            List<Map<String, Object>> rows = new List<Map<String, Object>>();
            for (SObject op : partners) {
                SObject acct = op.getSObject('AccountTo');
                rows.add(new Map<String, Object>{
                    'Id' => op.get('Id'),
                    'AccountToId' => op.get('AccountToId'),
                    'AccountName' => acct != null ? acct.get('Name') : null,
                    'Role' => op.get('Role'),
                    'IsPrimary' => op.get('IsPrimary'),
                    'recordUrl' => AgenticSkillsBase.recordUrl((Id) op.get('Id'))
                });
            }
            return AgenticSkillsBase.successJson(new Map<String, Object>{
                'opportunityId' => oid, 'count' => rows.size(), 'partners' => rows
            });
        } catch (Exception ex) {
            return AgenticSkillsBase.errorJson('Could not fetch opportunity partners: ' + ex.getMessage());
        }
    }
}
