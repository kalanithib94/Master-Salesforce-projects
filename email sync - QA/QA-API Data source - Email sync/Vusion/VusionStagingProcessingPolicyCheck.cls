/**
 * @description Vusion-specific AI data source. Delegates core payload build to
 *              StagingProcessingPolicyCheck, then enriches JSON with Vusion context:
 *              WhoId-is-Contact flag, domain-vs-website matching (Contact + toAddresses),
 *              and hints for multi-account / opportunity selection.
 * @see Vusion/Vusion Requirements.md - update class when that doc changes.
 */
global class VusionStagingProcessingPolicyCheck implements ccai.AIDataSourceInterface {

    global String getExternalData(ccai__AI_Data_Source__c dataSource, String extractedData) {
        String baseJson = new StagingProcessingPolicyCheck().getExternalData(dataSource, extractedData);
        return enrichVusionContext(baseJson, extractedData);
    }

    /**
     * Parses base JSON, adds Vusion-only keys. Does not remove or alter base keys.
     */
    private String enrichVusionContext(String baseProcessedJson, String extractedData) {
        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(baseProcessedJson);
        String stagingId = (String) root.get('stagingRecordId');

        // Enforce Vusion rule: only open opportunities should be available for AI selection.
        root.put('opportunities', filterOpenOpportunities(root));

        Id whoContactId = getWhoIdContactId(extractedData, stagingId);
        Id whoLeadId = getWhoIdLeadId(extractedData, stagingId);
        Boolean whoIdIsContact = (whoContactId != null);
        Boolean whoIdIsLead = (whoLeadId != null);
        root.put('vusionWhoIdIsContact', whoIdIsContact);
        root.put('vusionWhoIdIsLead', whoIdIsLead);

        Set<String> domainsForMatch = new Set<String>();
        if (whoIdIsContact) {
            domainsForMatch.addAll(domainsFromContactsPayload(root));
            domainsForMatch.addAll(domainsFromStagingAddresses(root));
        }

        List<String> domainList = new List<String>(domainsForMatch);
        domainList.sort();
        root.put('vusionDomainsUsedForMatch', domainList);

        List<Map<String, Object>> domainHits = new List<Map<String, Object>>();
        if (whoIdIsContact && !domainsForMatch.isEmpty()) {
            domainHits = findDomainMatchedAccounts(root, domainsForMatch);
        }

        Boolean hasAccountCandidates = hasWhoContactAccountCandidates(root, whoContactId);
        Boolean hasOpenOpportunityCandidates = hasWhoContactOpenOpportunityCandidates(root, whoContactId);
        Boolean hasRelatedToCandidates = hasAccountCandidates || hasOpenOpportunityCandidates;
        Boolean likelyInviteEmail = isLikelyCalendarInviteEmail(root);

        // Clean AI-first payload (single structure, no duplicate legacy blocks).
        Map<String, Object> structured = buildVusionStructuredContext(
            root,
            whoContactId,
            whoLeadId,
            domainsForMatch,
            domainHits,
            hasAccountCandidates,
            hasOpenOpportunityCandidates,
            hasRelatedToCandidates,
            likelyInviteEmail
        );
        return JSON.serialize(structured);
    }

    /**
     * Adds a relationship-first structure without removing existing keys.
     * This keeps old prompt compatibility while offering deterministic linkage context.
     */
    private Map<String, Object> buildVusionStructuredContext(
        Map<String, Object> root,
        Id whoContactId,
        Id whoLeadId,
        Set<String> domainsForMatch,
        List<Map<String, Object>> domainHits,
        Boolean hasAccountCandidates,
        Boolean hasOpenOpportunityCandidates,
        Boolean hasRelatedToCandidates,
        Boolean likelyInviteEmail
    ) {
        Map<String, Object> out = new Map<String, Object>();

        // Staging metadata
        Map<String, Object> staging = new Map<String, Object>();
        staging.put('stagingRecordId', root.get('stagingRecordId'));
        staging.put('recordType', root.get('recordType'));
        staging.put('provider', root.get('provider'));
        staging.put('messageDate', root.get('messageDate'));
        staging.put('isIncoming', root.get('isIncoming'));
        staging.put('importance', root.get('importance'));
        staging.put('hasAttachments', root.get('hasAttachments'));
        out.put('staging', staging);

        // Email metadata
        Map<String, Object> email = new Map<String, Object>();
        email.put('subject', root.get('emailSubject'));
        email.put('textBody', root.get('emailTextBody'));
        email.put('htmlBody', root.get('emailHtmlBody'));
        Map<String, Object> fromObj = new Map<String, Object>();
        fromObj.put('email', root.get('fromAddress'));
        fromObj.put('name', root.get('fromName'));
        email.put('from', fromObj);
        email.put('to', splitHeaderEmails((String) root.get('toAddresses')));
        email.put('cc', splitHeaderEmails((String) root.get('ccAddresses')));
        email.put('attendees', splitHeaderEmails((String) root.get('attendeeList')));
        email.put('organizers', splitHeaderEmails((String) root.get('organizerEmails')));
        out.put('email', email);

        // Who context
        Map<String, Object> who = new Map<String, Object>();
        who.put('whoType', whoContactId != null ? 'Contact' : (whoLeadId != null ? 'Lead' : 'Unknown'));
        who.put('whoIdContact', whoContactId == null ? '' : String.valueOf(whoContactId));
        who.put('whoIdLead', whoLeadId == null ? '' : String.valueOf(whoLeadId));
        who.put('hasAccountCandidates', hasAccountCandidates);
        who.put('hasOpenOpportunityCandidates', hasOpenOpportunityCandidates);
        who.put('hasRelatedToCandidates', hasRelatedToCandidates);
        out.put('whoContext', who);

        // Build account candidates with explicit nested opportunities
        List<Object> contactsRaw = (List<Object>) root.get('contacts');
        List<Object> oppsRaw = (List<Object>) root.get('opportunities');
        Map<String, List<Map<String, Object>>> oppsByAccountId = new Map<String, List<Map<String, Object>>>();
        Map<String, Map<String, Object>> accountById = new Map<String, Map<String, Object>>();
        Map<String, Set<String>> accountContactIds = new Map<String, Set<String>>();
        Set<String> whoScopedAccountIds = new Set<String>();
        Set<String> whoScopedOppIds = new Set<String>();

        if (contactsRaw != null) {
            for (Object co : contactsRaw) {
                if (!(co instanceof Map<String, Object>)) continue;
                Map<String, Object> c = (Map<String, Object>) co;
                String contactId = (String) c.get('id');
                Boolean isWhoContact = (whoContactId != null && contactId == String.valueOf(whoContactId));

                addAccountCandidate(accountById, accountContactIds, c.get('account'), 'primary', contactId, isWhoContact, whoScopedAccountIds);
                List<Object> rel = (List<Object>) c.get('relatedAccounts');
                if (rel != null) {
                    for (Object ro : rel) {
                        if (!(ro instanceof Map<String, Object>)) continue;
                        Map<String, Object> rr = (Map<String, Object>) ro;
                        addAccountCandidate(accountById, accountContactIds, rr.get('account'), 'related', contactId, isWhoContact, whoScopedAccountIds);
                    }
                }
            }
        }

        // Attach opportunities to account candidates
        if (oppsRaw != null) {
            for (Object oo : oppsRaw) {
                if (!(oo instanceof Map<String, Object>)) continue;
                Map<String, Object> opp = (Map<String, Object>) oo;
                String accountId = (String) opp.get('accountId');
                String oppId = (String) opp.get('id');
                if (String.isBlank(accountId) || !accountById.containsKey(accountId)) continue;

                Map<String, Object> acc = accountById.get(accountId);
                List<Map<String, Object>> nestedOpps = (List<Map<String, Object>>) acc.get('opportunities');
                Map<String, Object> no = new Map<String, Object>();
                no.put('id', oppId);
                no.put('name', opp.get('name'));
                no.put('stageName', opp.get('stageName'));
                no.put('amount', opp.get('amount'));
                no.put('closeDate', opp.get('closeDate'));
                no.put('accountId', opp.get('accountId'));
                no.put('type', opp.get('type'));
                no.put('leadSource', opp.get('leadSource'));
                no.put('description', opp.get('description'));
                no.put('lastModifiedDate', opp.get('lastModifiedDate'));
                no.put('isOpen', true); // opportunities are pre-filtered as open
                nestedOpps.add(no);

                if (!oppsByAccountId.containsKey(accountId)) {
                    oppsByAccountId.put(accountId, new List<Map<String, Object>>());
                }
                oppsByAccountId.get(accountId).add(no);

                if (whoScopedAccountIds.contains(accountId) && String.isNotBlank(oppId)) {
                    whoScopedOppIds.add(oppId);
                }
            }
        }

        // Primary AI relationship structure:
        // contacts -> accounts -> related opportunities.
        List<Map<String, Object>> contactsStructured = new List<Map<String, Object>>();
        if (contactsRaw != null) {
            for (Object co : contactsRaw) {
                if (!(co instanceof Map<String, Object>)) continue;
                Map<String, Object> c = (Map<String, Object>) co;
                Map<String, Object> cOut = new Map<String, Object>();
                String contactId = (String) c.get('id');
                cOut.put('id', contactId);
                cOut.put('firstName', c.get('firstName'));
                cOut.put('lastName', c.get('lastName'));
                cOut.put('email', c.get('email'));
                cOut.put('phone', c.get('phone'));
                cOut.put('title', c.get('title'));
                cOut.put('department', c.get('department'));
                cOut.put('mailingStreet', c.get('mailingStreet'));
                cOut.put('mailingCity', c.get('mailingCity'));
                cOut.put('mailingState', c.get('mailingState'));
                cOut.put('mailingPostalCode', c.get('mailingPostalCode'));
                cOut.put('mailingCountry', c.get('mailingCountry'));
                cOut.put('isWhoContact', whoContactId != null && contactId == String.valueOf(whoContactId));

                cOut.put('primaryAccount', buildContactAccountNode(c.get('account'), 'primary', oppsByAccountId));

                List<Map<String, Object>> relatedAccOut = new List<Map<String, Object>>();
                List<Object> rel = (List<Object>) c.get('relatedAccounts');
                if (rel != null) {
                    for (Object ro : rel) {
                        if (!(ro instanceof Map<String, Object>)) continue;
                        Map<String, Object> rr = (Map<String, Object>) ro;
                        Map<String, Object> relNode = buildContactAccountNode(rr.get('account'), 'related', oppsByAccountId);
                        if (!relNode.isEmpty()) {
                            relNode.put('roles', rr.get('roles'));
                            relatedAccOut.add(relNode);
                        }
                    }
                }
                cOut.put('relatedAccounts', relatedAccOut);
                contactsStructured.add(cOut);
            }
        }
        out.put('contacts', contactsStructured);

        // Emit candidates and indexes
        List<Map<String, Object>> accountCandidates = new List<Map<String, Object>>();
        Set<String> allowedIds = new Set<String>();
        for (String accId : accountById.keySet()) {
            Map<String, Object> acc = accountById.get(accId);
            Set<String> cids = accountContactIds.containsKey(accId) ? accountContactIds.get(accId) : new Set<String>();
            acc.put('contactsLinked', new List<String>(cids));
            accountCandidates.add(acc);
            allowedIds.add(accId);
            List<Map<String, Object>> no = (List<Map<String, Object>>) acc.get('opportunities');
            for (Map<String, Object> o : no) {
                String oid = (String) o.get('id');
                if (String.isNotBlank(oid)) allowedIds.add(oid);
            }
        }

        out.put('accountCandidates', accountCandidates);

        Map<String, Object> indexes = new Map<String, Object>();
        indexes.put('allowedRelatedToIds', new List<String>(allowedIds));
        indexes.put('whoScopedAccountIds', new List<String>(whoScopedAccountIds));
        indexes.put('whoScopedOpportunityIds', new List<String>(whoScopedOppIds));
        out.put('candidateIndexes', indexes);

        Map<String, Object> signals = new Map<String, Object>();
        signals.put('isLikelyCalendarInviteEmail', likelyInviteEmail);
        signals.put('domainsUsedForMatch', new List<String>(domainsForMatch));
        signals.put('domainMatchedAccounts', domainHits);
        signals.put('isWhoIdContact', whoContactId != null);
        signals.put('isWhoIdLead', whoLeadId != null);
        out.put('signals', signals);

        Map<String, Object> hints = new Map<String, Object>();
        hints.put('relatedToIdMode', 'BEST_EFFORT_OPTIONAL');
        hints.put('rejectionReasonMode', 'DETAILED_ALLOWED_REASONS');
        hints.put('summaryMode', 'VERBATIM_RELEVANT_EXCERPT_ONLY');
        hints.put('threadHandlingMode', 'NEW_CONTENT_FIRST');
        out.put('policyHints', hints);

        return out;
    }

    private Map<String, Object> buildContactAccountNode(
        Object accountObj,
        String source,
        Map<String, List<Map<String, Object>>> oppsByAccountId
    ) {
        Map<String, Object> out = new Map<String, Object>();
        if (!(accountObj instanceof Map<String, Object>)) {
            return out;
        }
        Map<String, Object> acc = (Map<String, Object>) accountObj;
        String accountId = (String) acc.get('id');
        if (String.isBlank(accountId)) {
            return out;
        }

        out.put('accountId', accountId);
        out.put('name', acc.get('name'));
        out.put('type', acc.get('type'));
        out.put('industry', acc.get('industry'));
        out.put('website', acc.get('website'));
        out.put('phone', acc.get('phone'));
        out.put('billingStreet', acc.get('billingStreet'));
        out.put('billingCity', acc.get('billingCity'));
        out.put('billingState', acc.get('billingState'));
        out.put('billingPostalCode', acc.get('billingPostalCode'));
        out.put('billingCountry', acc.get('billingCountry'));
        out.put('numberOfEmployees', acc.get('numberOfEmployees'));
        out.put('annualRevenue', acc.get('annualRevenue'));
        out.put('description', acc.get('description'));
        out.put('source', source);
        out.put(
            'relatedOpportunities',
            oppsByAccountId.containsKey(accountId)
                ? oppsByAccountId.get(accountId)
                : new List<Map<String, Object>>()
        );
        return out;
    }

    private void addAccountCandidate(
        Map<String, Map<String, Object>> accountById,
        Map<String, Set<String>> accountContactIds,
        Object accountObj,
        String source,
        String contactId,
        Boolean isWhoContact,
        Set<String> whoScopedAccountIds
    ) {
        if (!(accountObj instanceof Map<String, Object>)) return;
        Map<String, Object> a = (Map<String, Object>) accountObj;
        String accountId = (String) a.get('id');
        if (String.isBlank(accountId)) return;

        if (!accountById.containsKey(accountId)) {
            Map<String, Object> row = new Map<String, Object>();
            row.put('accountId', accountId);
            row.put('name', a.get('name'));
            row.put('type', a.get('type'));
            row.put('industry', a.get('industry'));
            row.put('website', a.get('website'));
            row.put('phone', a.get('phone'));
            row.put('billingStreet', a.get('billingStreet'));
            row.put('billingCity', a.get('billingCity'));
            row.put('billingState', a.get('billingState'));
            row.put('billingPostalCode', a.get('billingPostalCode'));
            row.put('billingCountry', a.get('billingCountry'));
            row.put('numberOfEmployees', a.get('numberOfEmployees'));
            row.put('annualRevenue', a.get('annualRevenue'));
            row.put('description', a.get('description'));
            row.put('source', new List<String>());
            row.put('opportunities', new List<Map<String, Object>>());
            accountById.put(accountId, row);
        }
        Map<String, Object> row = accountById.get(accountId);
        List<String> sources = (List<String>) row.get('source');
        if (!sources.contains(source)) sources.add(source);

        if (!accountContactIds.containsKey(accountId)) accountContactIds.put(accountId, new Set<String>());
        if (String.isNotBlank(contactId)) accountContactIds.get(accountId).add(contactId);
        if (isWhoContact) whoScopedAccountIds.add(accountId);
    }

    private List<String> splitHeaderEmails(String headerVal) {
        List<String> out = new List<String>();
        if (String.isBlank(headerVal)) return out;
        String normalized = headerVal.replace(';', ',');
        for (String p : normalized.split(',')) {
            if (String.isBlank(p)) continue;
            String candidate = p.trim();
            Integer lt = candidate.indexOf('<');
            Integer gt = candidate.indexOf('>');
            if (lt >= 0 && gt > lt) {
                candidate = candidate.substring(lt + 1, gt).trim();
            }
            if (String.isNotBlank(candidate)) out.add(candidate);
        }
        return out;
    }

    /**
     * Best-effort signal to distinguish invite-generated emails from normal emails.
     * This helps prompt logic avoid rejecting calendar invite emails as generic noise.
     */
    private Boolean isLikelyCalendarInviteEmail(Map<String, Object> root) {
        String provider = ((String) root.get('provider'));
        String subject = ((String) root.get('emailSubject'));
        String textBody = ((String) root.get('emailTextBody'));
        String htmlBody = ((String) root.get('emailHtmlBody'));
        String attendees = ((String) root.get('attendeeList'));
        String organizer = ((String) root.get('organizerEmails'));

        if (String.isNotBlank(provider)) {
            String p = provider.trim().toUpperCase();
            if (p == 'MICROSOFT_CALENDAR' || p == 'GOOGLE_CALENDAR') {
                return true;
            }
        }

        String signalText = (
            (String.isBlank(subject) ? '' : subject + ' ') +
            (String.isBlank(textBody) ? '' : textBody + ' ') +
            (String.isBlank(htmlBody) ? '' : htmlBody)
        ).toLowerCase();

        if (String.isNotBlank(attendees) || String.isNotBlank(organizer)) {
            if (
                signalText.contains('meeting invitation') ||
                signalText.contains('calendar invite') ||
                signalText.contains('invited you') ||
                signalText.contains('accepted') ||
                signalText.contains('declined') ||
                signalText.contains('tentative') ||
                signalText.contains('rescheduled') ||
                signalText.contains('updated invitation')
            ) {
                return true;
            }
        }

        return false;
    }

    /**
     * Keeps only open opportunities (stage does not start with 'Closed').
     */
    private List<Map<String, Object>> filterOpenOpportunities(Map<String, Object> root) {
        List<Map<String, Object>> openOpps = new List<Map<String, Object>>();
        List<Object> raw = (List<Object>) root.get('opportunities');
        if (raw == null) {
            return openOpps;
        }
        for (Object o : raw) {
            if (!(o instanceof Map<String, Object>)) {
                continue;
            }
            Map<String, Object> opp = (Map<String, Object>) o;
            String stage = (String) opp.get('stageName');
            if (String.isBlank(stage)) {
                continue;
            }
            if (!stage.trim().toLowerCase().startsWith('closed')) {
                openOpps.add(opp);
            }
        }
        return openOpps;
    }

    /**
     * Returns WhoId when it is a Contact Id; otherwise null.
     */
    private Id getWhoIdContactId(String extractedData, String stagingRecordId) {
        String whoVal;
        if (String.isNotBlank(extractedData)) {
            try {
                Map<String, Object> ext = (Map<String, Object>) JSON.deserializeUntyped(extractedData);
                whoVal = (String) ext.get('ccai__WhoId__c');
                if (String.isBlank(whoVal)) {
                    whoVal = (String) ext.get('WhoId__c');
                }
                if (String.isBlank(whoVal)) {
                    whoVal = (String) ext.get('WhoId');
                }
            } catch (Exception e) {
                System.debug('VusionStagingProcessingPolicyCheck - extract WhoId parse: ' + e.getMessage());
            }
        }
        if (String.isBlank(whoVal) && String.isNotBlank(stagingRecordId)) {
            List<ccai__AI_Workspace_Staging__c> rows = [
                SELECT ccai__WhoId__c
                FROM ccai__AI_Workspace_Staging__c
                WHERE Id = :stagingRecordId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            if (!rows.isEmpty()) {
                whoVal = rows[0].ccai__WhoId__c;
            }
        }
        if (String.isBlank(whoVal)) {
            return null;
        }
        try {
            Id wid = (Id) whoVal.trim();
            return wid.getSObjectType() == Contact.SObjectType ? wid : null;
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Returns WhoId when it is a Lead Id; otherwise null.
     */
    private Id getWhoIdLeadId(String extractedData, String stagingRecordId) {
        String whoVal;
        if (String.isNotBlank(extractedData)) {
            try {
                Map<String, Object> ext = (Map<String, Object>) JSON.deserializeUntyped(extractedData);
                whoVal = (String) ext.get('ccai__WhoId__c');
                if (String.isBlank(whoVal)) {
                    whoVal = (String) ext.get('WhoId__c');
                }
                if (String.isBlank(whoVal)) {
                    whoVal = (String) ext.get('WhoId');
                }
            } catch (Exception e) {
                System.debug('VusionStagingProcessingPolicyCheck - extract WhoId parse: ' + e.getMessage());
            }
        }
        if (String.isBlank(whoVal) && String.isNotBlank(stagingRecordId)) {
            List<ccai__AI_Workspace_Staging__c> rows = [
                SELECT ccai__WhoId__c
                FROM ccai__AI_Workspace_Staging__c
                WHERE Id = :stagingRecordId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            if (!rows.isEmpty()) {
                whoVal = rows[0].ccai__WhoId__c;
            }
        }
        if (String.isBlank(whoVal)) {
            return null;
        }
        try {
            Id wid = (Id) whoVal.trim();
            return wid.getSObjectType() == Lead.SObjectType ? wid : null;
        } catch (Exception e) {
            return null;
        }
    }

    private Boolean hasWhoContactAccountCandidates(Map<String, Object> root, Id whoContactId) {
        Set<String> accountIds = getWhoContactAccountIds(root, whoContactId);
        return !accountIds.isEmpty();
    }

    private Boolean hasWhoContactOpenOpportunityCandidates(Map<String, Object> root, Id whoContactId) {
        Set<String> whoAccountIds = getWhoContactAccountIds(root, whoContactId);
        if (whoAccountIds.isEmpty()) {
            return false;
        }
        List<Object> opps = (List<Object>) root.get('opportunities');
        if (opps == null) {
            return false;
        }
        for (Object o : opps) {
            if (!(o instanceof Map<String, Object>)) {
                continue;
            }
            Map<String, Object> opp = (Map<String, Object>) o;
            String accId = (String) opp.get('accountId');
            if (String.isNotBlank(accId) && whoAccountIds.contains(accId)) {
                return true;
            }
        }
        return false;
    }

    private Set<String> getWhoContactAccountIds(Map<String, Object> root, Id whoContactId) {
        Set<String> out = new Set<String>();
        if (whoContactId == null) {
            return out;
        }
        List<Object> contacts = (List<Object>) root.get('contacts');
        if (contacts == null) {
            return out;
        }
        for (Object o : contacts) {
            if (!(o instanceof Map<String, Object>)) {
                continue;
            }
            Map<String, Object> c = (Map<String, Object>) o;
            String cid = (String) c.get('id');
            if (String.isBlank(cid) || cid != String.valueOf(whoContactId)) {
                continue;
            }
            if (c.get('account') instanceof Map<String, Object>) {
                Map<String, Object> acc = (Map<String, Object>) c.get('account');
                String aid = (String) acc.get('id');
                if (String.isNotBlank(aid)) out.add(aid);
            }
            List<Object> rel = (List<Object>) c.get('relatedAccounts');
            if (rel != null) {
                for (Object r : rel) {
                    if (!(r instanceof Map<String, Object>)) continue;
                    Map<String, Object> rr = (Map<String, Object>) r;
                    if (rr.get('account') instanceof Map<String, Object>) {
                        Map<String, Object> racc = (Map<String, Object>) rr.get('account');
                        String raid = (String) racc.get('id');
                        if (String.isNotBlank(raid)) out.add(raid);
                    }
                }
            }
            break;
        }
        return out;
    }

    /**
     * Domains from contacts[].email in the payload.
     */
    private Set<String> domainsFromContactsPayload(Map<String, Object> root) {
        Set<String> domains = new Set<String>();
        List<Object> raw = (List<Object>) root.get('contacts');
        if (raw == null) {
            return domains;
        }
        for (Object o : raw) {
            if (!(o instanceof Map<String, Object>)) {
                continue;
            }
            Map<String, Object> c = (Map<String, Object>) o;
            String email = (String) c.get('email');
            domains.addAll(domainsFromEmailAddress(email));
        }
        return domains;
    }

    /**
     * Domains from staging toAddresses (and fromAddress as secondary signal).
     */
    private Set<String> domainsFromStagingAddresses(Map<String, Object> root) {
        Set<String> domains = new Set<String>();
        domains.addAll(domainsFromHeaderField((String) root.get('toAddresses')));
        domains.addAll(domainsFromHeaderField((String) root.get('fromAddress')));
        return domains;
    }

    private Set<String> domainsFromEmailAddress(String email) {
        Set<String> out = new Set<String>();
        if (String.isBlank(email)) {
            return out;
        }
        String e = email.trim().toLowerCase();
        Integer at = e.lastIndexOf('@');
        if (at < 0 || at >= e.length() - 1) {
            return out;
        }
        String d = e.substring(at + 1).trim();
        if (String.isNotBlank(d)) {
            out.add(d);
        }
        return out;
    }

    private Set<String> domainsFromHeaderField(String header) {
        Set<String> out = new Set<String>();
        if (String.isBlank(header)) {
            return out;
        }
        String normalized = header.replace(';', ',');
        for (String piece : normalized.split(',')) {
            if (String.isBlank(piece)) {
                continue;
            }
            String p = piece.trim();
            Integer lt = p.indexOf('<');
            Integer gt = p.indexOf('>');
            if (lt >= 0 && gt > lt) {
                p = p.substring(lt + 1, gt).trim();
            }
            out.addAll(domainsFromEmailAddress(p));
        }
        return out;
    }

    /**
     * Compare domains to website on primary account + relatedAccounts for each contact.
     */
    private List<Map<String, Object>> findDomainMatchedAccounts(
        Map<String, Object> root,
        Set<String> domains
    ) {
        Set<String> seenAccountIds = new Set<String>();
        List<Map<String, Object>> hits = new List<Map<String, Object>>();

        List<Object> raw = (List<Object>) root.get('contacts');
        if (raw == null) {
            return hits;
        }

        for (Object o : raw) {
            if (!(o instanceof Map<String, Object>)) {
                continue;
            }
            Map<String, Object> c = (Map<String, Object>) o;
            addWebsiteMatchesForAccountMap(c.get('account'), domains, seenAccountIds, hits);
            List<Object> rel = (List<Object>) c.get('relatedAccounts');
            if (rel != null) {
                for (Object ro : rel) {
                    if (!(ro instanceof Map<String, Object>)) {
                        continue;
                    }
                    Map<String, Object> relRow = (Map<String, Object>) ro;
                    addWebsiteMatchesForAccountMap(relRow.get('account'), domains, seenAccountIds, hits);
                }
            }
        }
        return hits;
    }

    private void addWebsiteMatchesForAccountMap(
        Object accountObj,
        Set<String> domains,
        Set<String> seenAccountIds,
        List<Map<String, Object>> hits
    ) {
        if (accountObj == null || !(accountObj instanceof Map<String, Object>)) {
            return;
        }
        Map<String, Object> acc = (Map<String, Object>) accountObj;
        String accId = (String) acc.get('id');
        String website = (String) acc.get('website');
        if (String.isBlank(accId) || String.isBlank(website)) {
            return;
        }
        String host = websiteToHost(website);
        if (String.isBlank(host)) {
            return;
        }
        for (String dom : domains) {
            if (domainMatchesHost(dom, host)) {
                if (!seenAccountIds.contains(accId)) {
                    seenAccountIds.add(accId);
                    Map<String, Object> row = new Map<String, Object>();
                    row.put('accountId', accId);
                    row.put('website', website);
                    row.put('matchedDomain', dom);
                    hits.add(row);
                }
                break;
            }
        }
    }

    private String websiteToHost(String website) {
        if (String.isBlank(website)) {
            return null;
        }
        String w = website.trim().toLowerCase();
        w = w.replace('https://', '').replace('http://', '');
        Integer slash = w.indexOf('/');
        if (slash > 0) {
            w = w.substring(0, slash);
        }
        while (w.startsWith('www.')) {
            w = w.substring(4);
        }
        return String.isBlank(w) ? null : w;
    }

    private Boolean domainMatchesHost(String domain, String host) {
        if (String.isBlank(domain) || String.isBlank(host)) {
            return false;
        }
        String d = domain.trim().toLowerCase();
        String h = host.trim().toLowerCase();
        if (d == h) {
            return true;
        }
        if (h.endsWith('.' + d)) {
            return true;
        }
        return false;
    }
}
