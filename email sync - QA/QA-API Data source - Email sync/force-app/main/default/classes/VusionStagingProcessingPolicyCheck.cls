/**
 * @description Vusion-specific AI data source. Delegates core payload build to
 *              StagingProcessingPolicyCheck, then enriches JSON with Vusion context:
 *              WhoId-is-Contact flag, domain-vs-website matching (Contact + toAddresses),
 *              and hints for multi-account / opportunity selection.
 *              Relevancy is evaluated per imported email record (thread messages are independent);
 *              this class preserves per-message fields used by prompt-layer thread handling rules.
 *              Lead WhoId context does not imply relevance by itself; prompt layer still evaluates content intent.
 * @see Vusion/Vusion Requirements.md — update class when that doc changes.
 */
global class VusionStagingProcessingPolicyCheck implements ccai_qa.AIDataSourceInterface {

    global String getExternalData(AI_Data_Source__c dataSource, String extractedData) {
        String baseJson = new StagingProcessingPolicyCheck().getExternalData(dataSource, extractedData);
        return enrichVusionContext(baseJson, extractedData);
    }

    /**
     * Parses base JSON, adds Vusion-only keys. Does not remove or alter base keys.
     */
    private String enrichVusionContext(String baseProcessedJson, String extractedData) {
        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(baseProcessedJson);
        String stagingId = (String) root.get('stagingRecordId');

        Boolean whoIdIsContact = resolveWhoIdIsContact(extractedData, stagingId);
        root.put('vusionWhoIdIsContact', whoIdIsContact);

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
        root.put('vusionDomainMatchedAccounts', domainHits);

        return JSON.serialize(root);
    }

    /**
     * True when staging WhoId points to a Contact (domain rules apply per Vusion spec).
     */
    private Boolean resolveWhoIdIsContact(String extractedData, String stagingRecordId) {
        String whoVal;
        if (String.isNotBlank(extractedData)) {
            try {
                Map<String, Object> ext = (Map<String, Object>) JSON.deserializeUntyped(extractedData);
                whoVal = (String) ext.get('WhoId__c');
                if (String.isBlank(whoVal)) {
                    whoVal = (String) ext.get('WhoId');
                }
            } catch (Exception e) {
                System.debug('VusionStagingProcessingPolicyCheck - extract WhoId parse: ' + e.getMessage());
            }
        }
        if (String.isBlank(whoVal) && String.isNotBlank(stagingRecordId)) {
            List<AI_Workspace_Staging__c> rows = [
                SELECT WhoId__c
                FROM AI_Workspace_Staging__c
                WHERE Id = :stagingRecordId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            if (!rows.isEmpty()) {
                whoVal = rows[0].WhoId__c;
            }
        }
        if (String.isBlank(whoVal)) {
            return false;
        }
        try {
            Id wid = (Id) whoVal.trim();
            return wid.getSObjectType() == Contact.SObjectType;
        } catch (Exception e) {
            return false;
        }
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
