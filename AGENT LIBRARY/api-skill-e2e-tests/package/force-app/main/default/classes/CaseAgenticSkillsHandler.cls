/**
 * @description Case object skills for the GPTfy Agent Library (9 skills).
 *              Implements ccai.AIAgenticInterface; shared helpers live in AgenticSkillsBase.
 * @author      : Plumcloud Labs
 * @group       : GPTfy Agent Library
 * @jira        : V2-8418
 */
global with sharing class CaseAgenticSkillsHandler implements ccai.AIAgenticInterface {

    global String executeMethod(String methodName, Map<String, Object> parameters) {
        try {
            if (parameters == null) parameters = new Map<String, Object>();
            String m = String.isBlank(methodName) ? '' : methodName.trim();
            switch on m {
                when 'fuzzy_search_cases' { return handleFuzzySearchCases(parameters); }
                when 'fetch_case_details' { return handleFetchCaseDetails(parameters); }
                when 'create_case' { return handleCreateCase(parameters); }
                when 'update_case_fields' { return handleUpdateCaseFields(parameters); }
                when 'close_case' { return handleCloseCase(parameters); }
                when 'add_case_comment' { return handleAddCaseComment(parameters); }
                when 'fetch_case_team' { return handleFetchCaseTeam(parameters); }
                when 'add_case_team_member' { return handleAddCaseTeamMember(parameters); }
                when 'link_knowledge_article_to_case' { return handleLinkKnowledgeArticleToCase(parameters); }
                when else { return AgenticSkillsBase.errorJson('Unsupported skill: ' + methodName); }
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'CaseAgenticSkillsHandler | ' + methodName + ' | ' + ex.getMessage());
            return AgenticSkillsBase.errorJson(ex.getMessage());
        }
    }

    /**
     * @description Skill — fuzzy_search_cases. Subject or CaseNumber partial match.
     * @jira V2-8418
     */
    private String handleFuzzySearchCases(Map<String, Object> p) {
        String term = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'search_term', 'subject', 'case_number' }));
        if (String.isBlank(term)) return AgenticSkillsBase.errorJson('Missing required parameter: search_term');
        if (!Schema.sObjectType.Case.isAccessible()) return AgenticSkillsBase.errorJson('Case is not accessible.');
        List<SObject> all = AgenticSkillsBase.fuzzyQueryMulti(
            'Case',
            new List<String>{ 'Subject', 'CaseNumber' },
            new List<String>{ 'Status', 'Priority' },
            term
        );
        if (all.isEmpty()) return AgenticSkillsBase.errorJson('No case found matching "' + term + '".');
        Map<String, Object> sliced = AgenticSkillsBase.applyTopNAndCount(all, AgenticSkillsBase.FUZZY_DISPLAY_LIMIT);
        List<SObject> top = (List<SObject>) sliced.get('rows');
        List<Map<String, Object>> records = new List<Map<String, Object>>();
        for (SObject r : top) {
            Id rid = (Id) r.get('Id');
            records.add(new Map<String, Object>{
                'Id' => rid, 'CaseNumber' => r.get('CaseNumber'), 'Subject' => r.get('Subject'),
                'Status' => r.get('Status'), 'Priority' => r.get('Priority'),
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

    /**
     * @description Skill — fetch_case_details.
     *              Agents should pass CaseNumber or Subject; Salesforce Id still accepted.
     * @jira V2-8418
     */
    private String handleFetchCaseDetails(Map<String, Object> p) {
        Id cid = AgenticSkillsBase.resolvePrimaryId(p, 'Case');
        if (cid == null) {
            // Accept free-text that was passed as Id / case_id / subject
            String raw = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{
                'CaseNumber', 'case_number', 'Subject', 'subject', 'case_id', 'recordId', 'Id', 'Id'
            }));
            if (String.isNotBlank(raw)) {
                cid = AgenticSkillsBase.resolveNaturalKeyValue('Case', raw);
            }
        }
        if (cid == null) {
            return AgenticSkillsBase.errorJson(
                'Missing case identifier. Pass CaseNumber (e.g. "00001026") or Subject — Salesforce Id is optional.'
            );
        }
        if (!Schema.sObjectType.Case.isAccessible()) return AgenticSkillsBase.errorJson('Case is not accessible.');
        List<Case> rows = [
            SELECT Id, CaseNumber, Subject, Description, Status, Priority, Type, Origin,
                   Reason, AccountId, Account.Name, ContactId, Contact.Name, OwnerId, IsClosed
            FROM Case WHERE Id = :cid WITH USER_MODE LIMIT 1
        ];
        if (rows.isEmpty()) return AgenticSkillsBase.errorJson('No case found for provided CaseNumber/Subject/Id.');
        Case ca = rows[0];
        return AgenticSkillsBase.successJson(new Map<String, Object>{
            'Id' => ca.Id, 'CaseNumber' => ca.CaseNumber, 'Subject' => ca.Subject,
            'Description' => ca.Description, 'Status' => ca.Status, 'Priority' => ca.Priority,
            'Type' => ca.Type, 'Origin' => ca.Origin, 'Reason' => ca.Reason,
            'Account' => ca.Account != null ? ca.Account.Name : null,
            'Contact' => ca.Contact != null ? ca.Contact.Name : null,
            'IsClosed' => ca.IsClosed, 'recordUrl' => AgenticSkillsBase.recordUrl(ca.Id)
        });
    }

    /**
     * @description Skill — create_case.
     * @jira V2-8418
     */
    private String handleCreateCase(Map<String, Object> p) {
        if (!Schema.sObjectType.Case.isCreateable()) return AgenticSkillsBase.errorHtml('Could not create case', 'Case is not creatable.');
        // Exclude human-name helpers so they are not written as Case fields
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, new Set<String>{
            'AccountName', 'account_name', 'ContactName', 'contact_name', 'Account', 'Contact'
        });
        if (!fields.containsKey('Subject') || String.isBlank(AgenticSkillsBase.toText(fields.get('Subject')))) {
            return AgenticSkillsBase.errorHtml('Could not create case', 'Subject is required.');
        }
        // Resolve parent Account / Contact by Name (users rarely know Salesforce Ids)
        Map<String, Object> forLookup = new Map<String, Object>(p);
        forLookup.putAll(fields);
        Id accountId = AgenticSkillsBase.resolveLookupId(forLookup, 'AccountId');
        if (accountId == null) {
            String accName = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonBlank(forLookup, new List<String>{
                'AccountName', 'account_name', 'Account'
            }));
            if (String.isNotBlank(accName)) accountId = AgenticSkillsBase.resolveNaturalKeyValue('Account', accName);
        }
        if (accountId != null) fields.put('AccountId', accountId);
        Id contactId = AgenticSkillsBase.resolveLookupId(forLookup, 'ContactId');
        if (contactId == null) {
            String cName = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonBlank(forLookup, new List<String>{
                'ContactName', 'contact_name', 'Contact'
            }));
            if (String.isNotBlank(cName)) contactId = AgenticSkillsBase.resolveNaturalKeyValue('Contact', cName);
        }
        if (contactId != null) fields.put('ContactId', contactId);
        // If AccountId / ContactId were passed as names, rewrite to real Ids
        for (String lookupField : new List<String>{ 'AccountId', 'ContactId' }) {
            if (!fields.containsKey(lookupField)) continue;
            String raw = AgenticSkillsBase.toText(fields.get(lookupField));
            if (String.isBlank(raw) || AgenticSkillsBase.parseSalesforceId(raw) != null) continue;
            String target = lookupField == 'AccountId' ? 'Account' : 'Contact';
            Id resolved = AgenticSkillsBase.resolveNaturalKeyValue(target, raw);
            if (resolved != null) fields.put(lookupField, resolved);
            else fields.remove(lookupField);
        }
        try {
            Case c = new Case();
            AgenticSkillsBase.applyFieldsToSObject(c, fields, false);
            insert c;
            Case created = [SELECT Id, CaseNumber, Subject FROM Case WHERE Id = :c.Id LIMIT 1];
            String body = '<ul><li><b>Case #:</b> ' + AgenticSkillsBase.escapeHtml(created.CaseNumber) + '</li>'
                        + '<li><b>Subject:</b> ' + AgenticSkillsBase.escapeHtml(created.Subject) + '</li></ul>';
            return AgenticSkillsBase.successHtml('Case Created', body, created.Id, 'View Case');
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not create case', ex.getMessage());
        }
    }

    /**
     * @description Skill — update_case_fields.
     *              Locate case by CaseNumber / Subject / Id.
     * @jira V2-8418
     */
    private String handleUpdateCaseFields(Map<String, Object> p) {
        Id cid = AgenticSkillsBase.resolvePrimaryId(p, 'Case');
        if (cid == null) {
            String raw = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{
                'CaseNumber', 'case_number', 'Subject', 'subject', 'case_id', 'Id'
            }));
            if (String.isNotBlank(raw)) cid = AgenticSkillsBase.resolveNaturalKeyValue('Case', raw);
        }
        if (cid == null) {
            return AgenticSkillsBase.errorHtml(
                'Could not update case',
                'Missing case locator. Pass CaseNumber or Subject (Salesforce Id optional).'
            );
        }
        Map<String, Object> fields = AgenticSkillsBase.buildFieldMap(p, new Set<String>{
            'case_id', 'recordId', 'Id', 'CaseNumber', 'case_number', 'case_subject'
        });
        if (fields.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update case', 'Missing parameter: at least one field to update');
        if (!Schema.sObjectType.Case.isUpdateable()) return AgenticSkillsBase.errorHtml('Could not update case', 'Case is not updateable.');
        List<Case> rows = [SELECT Id, CaseNumber FROM Case WHERE Id = :cid WITH USER_MODE LIMIT 1];
        if (rows.isEmpty()) return AgenticSkillsBase.errorHtml('Could not update case', 'No case found for provided CaseNumber/Subject/Id.');
        return AgenticSkillsBase.performGenericUpdate('Case', cid, fields, 'Case Updated', 'View Case', rows[0].CaseNumber);
    }

    /**
     * @description Skill — close_case (sets Status to a closed value + optional Reason / comment).
     * @jira V2-8418
     */
    private String handleCloseCase(Map<String, Object> p) {
        Id cid = AgenticSkillsBase.resolvePrimaryId(p, 'Case');
        if (cid == null) {
            String raw = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonBlank(p, new List<String>{
                'CaseNumber', 'case_number', 'Subject', 'subject', 'case_id', 'recordId', 'Id'
            }));
            if (String.isNotBlank(raw)) cid = AgenticSkillsBase.resolveNaturalKeyValue('Case', raw);
        }
        String status = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonBlank(p, new List<String>{ 'Status', 'status' }));
        if (String.isBlank(status)) status = 'Closed';
        String reason = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonBlank(p, new List<String>{ 'Reason', 'reason' }));
        String comments = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonBlank(p, new List<String>{
            'Comments', 'comments', 'CommentBody', 'comment'
        }));
        if (cid == null) return AgenticSkillsBase.errorHtml('Could not close case', 'Missing parameter: Id (Case Id).');
        if (!Schema.sObjectType.Case.isUpdateable()) return AgenticSkillsBase.errorHtml('Could not close case', 'Case is not updateable.');
        List<Case> rows = [SELECT Id, CaseNumber, Status, IsClosed FROM Case WHERE Id = :cid WITH USER_MODE LIMIT 1];
        if (rows.isEmpty()) return AgenticSkillsBase.errorHtml('Could not close case', 'No case found for provided Id.');
        if (rows[0].IsClosed) return AgenticSkillsBase.errorHtml('Could not close case', 'Case is already closed.');
        try {
            Case c = new Case(Id = cid, Status = status);
            if (String.isNotBlank(reason)) c.Reason = reason;
            update c;
            // Confirm the picklist value actually closed the case (org-specific closed statuses)
            List<Case> after = [SELECT Id, Status, IsClosed FROM Case WHERE Id = :cid WITH USER_MODE LIMIT 1];
            if (!after.isEmpty() && !after[0].IsClosed) {
                return AgenticSkillsBase.errorHtml(
                    'Could not close case',
                    'Status "' + status + '" did not close the case in this org. Use a closed Case.Status value (IsClosed = true).'
                );
            }
            if (String.isNotBlank(comments) && Schema.sObjectType.CaseComment.isCreateable()) {
                insert new CaseComment(ParentId = cid, CommentBody = comments, IsPublished = true);
            }
            String body = '<ul><li><b>Case #:</b> ' + AgenticSkillsBase.escapeHtml(rows[0].CaseNumber) + '</li>'
                        + '<li><b>Status:</b> ' + AgenticSkillsBase.escapeHtml(status) + '</li>'
                        + (String.isNotBlank(reason) ? '<li><b>Reason:</b> ' + AgenticSkillsBase.escapeHtml(reason) + '</li>' : '')
                        + '</ul>';
            return AgenticSkillsBase.successHtml('Case Closed', body, cid, 'View Case');
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not close case', ex.getMessage());
        }
    }

    /**
     * @description Skill — add_case_comment. Publishes a Case feed comment.
     * @jira V2-8418
     */
    private String handleAddCaseComment(Map<String, Object> p) {
        // CaseComment.ParentId → Case; accept CaseNumber / Subject / Name, not only Id
        Id cid = AgenticSkillsBase.resolveLookupId(p, 'ParentId');
        if (cid == null) cid = AgenticSkillsBase.resolvePrimaryId(p, 'Case');
        if (cid == null) {
            String raw = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonBlank(p, new List<String>{
                'ParentId', 'CaseNumber', 'case_number', 'Subject', 'case_id', 'Id'
            }));
            if (String.isNotBlank(raw)) cid = AgenticSkillsBase.resolveNaturalKeyValue('Case', raw);
        }
        String body = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonBlank(p, new List<String>{
            'CommentBody', 'comment_body', 'comment'
        }));
        if (cid == null) {
            return AgenticSkillsBase.errorHtml(
                'Could not add case comment',
                'Missing case locator. Pass CaseNumber or Subject (ParentId / Salesforce Id optional).'
            );
        }
        if (String.isBlank(body)) return AgenticSkillsBase.errorHtml('Could not add case comment', 'Missing parameter: CommentBody');
        if (!Schema.sObjectType.CaseComment.isCreateable()) {
            return AgenticSkillsBase.errorHtml('Could not add case comment', 'CaseComment is not creatable.');
        }
        List<Case> rows = [SELECT Id, CaseNumber FROM Case WHERE Id = :cid WITH USER_MODE LIMIT 1];
        if (rows.isEmpty()) return AgenticSkillsBase.errorHtml('Could not add case comment', 'No case found for provided CaseNumber/Subject/ParentId.');
        Boolean published = true;
        Object pubRaw = AgenticSkillsBase.firstNonBlank(p, new List<String>{ 'IsPublished', 'is_published' });
        if (pubRaw != null && String.isNotBlank(AgenticSkillsBase.toText(pubRaw))) {
            published = Boolean.valueOf(AgenticSkillsBase.toText(pubRaw));
        }
        try {
            CaseComment cc = new CaseComment(ParentId = cid, CommentBody = body, IsPublished = published);
            insert cc;
            String html = '<ul><li><b>Case #:</b> ' + AgenticSkillsBase.escapeHtml(rows[0].CaseNumber) + '</li>'
                        + '<li><b>Comment:</b> ' + AgenticSkillsBase.escapeHtml(body) + '</li></ul>';
            return AgenticSkillsBase.successHtml('Case Comment Added', html, cid, 'View Case');
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not add case comment', ex.getMessage());
        }
    }

    private String handleFetchCaseTeam(Map<String, Object> p) {
        Id cid = AgenticSkillsBase.resolvePrimaryId(p, 'Case');
        if (cid == null) {
            String raw = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonBlank(p, new List<String>{
                'CaseNumber', 'Subject', 'case_id', 'CaseId', 'Id'
            }));
            if (String.isNotBlank(raw)) cid = AgenticSkillsBase.resolveNaturalKeyValue('Case', raw);
        }
        if (cid == null) {
            return AgenticSkillsBase.errorJson('Missing case locator. Pass CaseNumber or Subject (Id optional).');
        }
        if (!Schema.sObjectType.CaseTeamMember.isAccessible()) {
            return AgenticSkillsBase.errorJson('CaseTeamMember is not accessible.');
        }
        List<CaseTeamMember> members = [
            SELECT Id, MemberId, Member.Name, TeamRoleId, TeamRole.Name, CreatedDate
            FROM CaseTeamMember
            WHERE ParentId = :cid
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        for (CaseTeamMember ctm : members) {
            rows.add(new Map<String, Object>{
                'Id' => ctm.Id, 'MemberId' => ctm.MemberId,
                'MemberName' => ctm.Member != null ? ctm.Member.Name : null,
                'TeamRole' => ctm.TeamRole != null ? ctm.TeamRole.Name : null,
                'recordUrl' => AgenticSkillsBase.recordUrl(ctm.Id)
            });
        }
        return AgenticSkillsBase.successJson(new Map<String, Object>{
            'caseId' => String.valueOf(cid), 'count' => rows.size(), 'teamMembers' => rows
        });
    }

    private String handleAddCaseTeamMember(Map<String, Object> p) {
        Id cid = AgenticSkillsBase.resolvePrimaryId(p, 'Case');
        if (cid == null) {
            String raw = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonBlank(p, new List<String>{
                'CaseNumber', 'Subject', 'case_id', 'CaseId', 'Id'
            }));
            if (String.isNotBlank(raw)) cid = AgenticSkillsBase.resolveNaturalKeyValue('Case', raw);
        }
        Id userId = AgenticSkillsBase.resolveLookupId(p, 'UserId');
        if (userId == null) {
            String uRaw = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonBlank(p, new List<String>{
                'user_id', 'UserId', 'MemberId', 'member_id', 'Name', 'Username', 'Email'
            }));
            if (String.isNotBlank(uRaw)) userId = AgenticSkillsBase.resolveNaturalKeyValue('User', uRaw);
        }
        String roleId = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{
            'team_role_id', 'TeamRoleId', 'TeamRole', 'RoleId'
        }));
        if (cid == null) {
            return AgenticSkillsBase.errorHtml(
                'Could not add case team member',
                'Missing case locator. Pass CaseNumber or Subject (Id optional).'
            );
        }
        if (userId == null) return AgenticSkillsBase.errorHtml('Could not add case team member', 'Missing parameter: user name or user_id');
        if (!Schema.sObjectType.CaseTeamMember.isCreateable()) {
            return AgenticSkillsBase.errorHtml('Could not add case team member', 'CaseTeamMember is not creatable.');
        }
        List<Case> cases = [SELECT Id, CaseNumber FROM Case WHERE Id = :cid WITH USER_MODE LIMIT 1];
        if (cases.isEmpty()) return AgenticSkillsBase.errorHtml('Could not add case team member', 'No case found for provided CaseNumber/Subject/Id.');
        if (String.isBlank(roleId) || AgenticSkillsBase.parseSalesforceId(roleId) == null) {
            // allow TeamRole by name
            if (String.isNotBlank(roleId) && AgenticSkillsBase.parseSalesforceId(roleId) == null) {
                List<CaseTeamRole> named = [SELECT Id FROM CaseTeamRole WHERE Name = :roleId WITH USER_MODE LIMIT 1];
                roleId = named.isEmpty() ? null : named[0].Id;
            } else {
                roleId = null;
            }
        }
        if (String.isBlank(roleId)) {
            List<CaseTeamRole> roles = [SELECT Id FROM CaseTeamRole WITH USER_MODE LIMIT 1];
            if (roles.isEmpty()) {
                return AgenticSkillsBase.errorHtml('Could not add case team member', 'Missing parameter: team_role_id (no default CaseTeamRole found).');
            }
            roleId = roles[0].Id;
        }
        try {
            CaseTeamMember ctm = new CaseTeamMember(ParentId = cid, MemberId = userId, TeamRoleId = roleId);
            insert ctm;
            String body = '<ul><li><b>Case #:</b> ' + AgenticSkillsBase.escapeHtml(cases[0].CaseNumber) + '</li></ul>';
            return AgenticSkillsBase.successHtml('Case Team Member Added', body, ctm.Id, 'View Team Member');
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not add case team member', ex.getMessage());
        }
    }

    private String handleLinkKnowledgeArticleToCase(Map<String, Object> p) {
        String cid = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{ 'case_id', 'recordId' }));
        String articleId = AgenticSkillsBase.toText(AgenticSkillsBase.firstNonNull(p, new List<String>{
            'knowledge_article_id', 'KnowledgeArticleId', 'article_id'
        }));
        if (String.isBlank(cid)) return AgenticSkillsBase.errorHtml('Could not link article', 'Missing parameter: case_id');
        if (String.isBlank(articleId)) return AgenticSkillsBase.errorHtml('Could not link article', 'Missing parameter: knowledge_article_id');
        Schema.SObjectType caseArticleType = Schema.getGlobalDescribe().get('CaseArticle');
        if (caseArticleType == null || !caseArticleType.getDescribe().isCreateable()) {
            return AgenticSkillsBase.errorHtml('Could not link article', 'CaseArticle is not available in this org (Knowledge may not be enabled).');
        }
        List<Case> cases = [SELECT Id, CaseNumber FROM Case WHERE Id = :cid WITH USER_MODE LIMIT 1];
        if (cases.isEmpty()) return AgenticSkillsBase.errorHtml('Could not link article', 'No case found for provided Id.');
        Id resolvedArticleId = resolveKnowledgeArticleMasterId(articleId);
        if (resolvedArticleId == null) {
            return AgenticSkillsBase.errorHtml('Could not link article', 'Invalid knowledge_article_id.');
        }
        try {
            SObject ca = caseArticleType.newSObject();
            ca.put('CaseId', cid);
            ca.put('KnowledgeArticleId', resolvedArticleId);
            insert ca;
            String body = '<ul><li><b>Case #:</b> ' + AgenticSkillsBase.escapeHtml(cases[0].CaseNumber) + '</li>'
                        + '<li><b>Article linked</b></li></ul>';
            return AgenticSkillsBase.successHtml('Knowledge Article Linked', body, (Id) ca.get('Id'), 'View Link');
        } catch (Exception ex) {
            return AgenticSkillsBase.errorHtml('Could not link article', ex.getMessage());
        }
    }

    private Id resolveKnowledgeArticleMasterId(String rawId) {
        Id parsed = AgenticSkillsBase.parseSalesforceId(rawId);
        if (parsed == null) return null;
        if (parsed.getSObjectType().getDescribe().getName() == 'KnowledgeArticleVersion') {
            Schema.SObjectType kavType = Schema.getGlobalDescribe().get('KnowledgeArticleVersion');
            if (kavType != null && kavType.getDescribe().isAccessible()) {
                List<SObject> versions = Database.query(
                    'SELECT KnowledgeArticleId FROM KnowledgeArticleVersion WHERE Id = :parsed WITH USER_MODE LIMIT 1'
                );
                if (!versions.isEmpty()) return (Id) versions[0].get('KnowledgeArticleId');
            }
        }
        return parsed;
    }
}
