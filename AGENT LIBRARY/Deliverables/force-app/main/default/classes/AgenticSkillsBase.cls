/**
 * @description Shared helpers for GPTfy Agent Library per-object skill handlers.
 * @author      : Plumcloud Labs
 * @group       : GPTfy Agent Library
 * @jira        : V2-8418
 */
public with sharing class AgenticSkillsBase {

    public class SkillException extends Exception {}

    @TestVisible public static Boolean bypassPromptForUnitTest = false;

    /**
     * @description Runtime / session keys injected into skill parameter bags
     *              by GPTfy. Never treat these as Salesforce field API names.
     * @jira V2-8418
     */
    @TestVisible
    public static final Set<String> RUNTIME_META_KEYS = new Set<String>{
        'userContextId',
        'user_context_id',
        'recordId',
        'record_id',
        'relatedToId',
        'related_to_id'
    };

// ────────────────────────────────────────────────────────────────────────
    // HELPERS — String / JSON / HTML / URL
    // ────────────────────────────────────────────────────────────────────────

    public static String toText(Object o) {
        if (o == null) return null;
        return (o instanceof String) ? (String) o : String.valueOf(o);
    }

    public static String escapeHtml(String s) {
        if (s == null) return '';
        return s.escapeHtml4();
    }

    public static String orgUrl() {
        return Url.getOrgDomainUrl().toExternalForm();
    }

    public static String recordUrl(Id rid) {
        return orgUrl() + '/lightning/r/' + String.valueOf(rid.getSObjectType()) + '/' + rid + '/view';
    }

    /**
     * @description Wraps action-skill HTML in JSON so GPTfy AIAgenticUtility can
     *              deserialize the response; getMessageFromResult extracts message.
     * @jira V2-8418
     */
    public static String actionHtmlResponse(String html, Boolean success, Id recordId) {
        Map<String, Object> payload = new Map<String, Object>{
            'success' => success,
            'message' => html
        };
        if (recordId != null) {
            payload.put('recordId', String.valueOf(recordId));
        }
        return JSON.serialize(payload);
    }

    /**
     * @description Builds an HTML success card with optional record link.
     * @jira V2-8418
     */
    public static String successHtml(String title, String bodyHtml, Id recordId, String linkLabel) {
        String html = '<div>✅ <b>' + escapeHtml(title) + '</b>' + (String.isBlank(bodyHtml) ? '' : bodyHtml);
        if (recordId != null) {
            html += '<br/>👉 <a href="' + recordUrl(recordId) + '" target="_blank"><b>'
                  + escapeHtml(String.isBlank(linkLabel) ? 'View Record' : linkLabel) + '</b></a>';
        }
        return actionHtmlResponse(html + '</div>', true, recordId);
    }

    /**
     * @description Builds an HTML error card.
     * @jira V2-8418
     */
    public static String errorHtml(String title, String message) {
        String html = '<div>⚠️ <b>' + escapeHtml(title) + '</b><br/>' + escapeHtml(message) + '</div>';
        return actionHtmlResponse(html, false, null);
    }

    /**
     * @description Standard error JSON used by all data skills.
     * @jira V2-8418
     */
    public static String errorJson(String msg) {
        return JSON.serialize(new Map<String, Object>{ 'success' => false, 'error' => msg });
    }

    /**
     * @description Error JSON with optional extra keys (e.g. errorCode, records) for agent UX.
     * @jira V2-8418
     */
    public static String errorJson(String msg, Map<String, Object> extra) {
        Map<String, Object> root = new Map<String, Object>{ 'success' => false, 'error' => msg };
        if (extra != null) {
            for (String k : extra.keySet()) {
                root.put(k, extra.get(k));
            }
        }
        return JSON.serialize(root);
    }

    /**
     * @description Standard success JSON used by all data skills.
     * @jira V2-8418
     */
    public static String successJson(Map<String, Object> result) {
        result.put('success', true);
        return JSON.serialize(result);
    }

    public static Object firstNonNull(Map<String, Object> m, List<String> keys) {
        for (String k : keys) {
            if (m.containsKey(k) && m.get(k) != null) return m.get(k);
        }
        return null;
    }

    /**
     * First non-null, non-blank parameter value (skips "" which GPTfy often injects).
     */
    public static Object firstNonBlank(Map<String, Object> m, List<String> keys) {
        if (m == null || keys == null) return null;
        for (String k : keys) {
            if (!m.containsKey(k) || m.get(k) == null) continue;
            String t = toText(m.get(k));
            if (String.isNotBlank(t)) return m.get(k);
        }
        return null;
    }

    /**
     * Param key lists for a primary record Id of `objectApiName`.
     * Convention: Prompt Command uses org-style names —
     *   primary = Id; relationships = AccountId, OwnerId, ContactId, …
     * Snake / camel aliases kept so older agents still work.
     */
    public static List<String> primaryIdParamKeys(String objectApiName) {
        List<String> keys = new List<String>{ 'Id', 'id', 'recordId', 'record_id' };
        if (String.isBlank(objectApiName)) return keys;
        String o = objectApiName.trim();
        // Object-specific primary keys (Id first — org shape)
        if (o == 'Account') {
            keys.addAll(new List<String>{ 'AccountId', 'accountId', 'account_id' }); // AccountId only as alias when agents confuse names
        } else if (o == 'Contact') {
            keys.addAll(new List<String>{ 'ContactId', 'contactId', 'contact_id' });
        } else if (o == 'Lead') {
            keys.addAll(new List<String>{ 'LeadId', 'leadId', 'lead_id' });
        } else if (o == 'Opportunity') {
            keys.addAll(new List<String>{ 'OpportunityId', 'opportunityId', 'opportunity_id' });
        } else if (o == 'Case') {
            keys.addAll(new List<String>{ 'CaseId', 'caseId', 'case_id' });
        } else if (o == 'Task') {
            keys.addAll(new List<String>{ 'TaskId', 'taskId', 'task_id' });
        } else if (o == 'Event') {
            keys.addAll(new List<String>{ 'EventId', 'eventId', 'event_id' });
        }         else if (o == 'Campaign') {
            keys.addAll(new List<String>{ 'CampaignId', 'campaignId', 'campaign_id' });
        } else if (o == 'CampaignMember') {
            keys.addAll(new List<String>{ 'CampaignMemberId', 'campaignMemberId', 'campaign_member_id', 'member_id' });
        } else if (o == 'Product2') {
            keys.addAll(new List<String>{ 'Product2Id', 'ProductId', 'productId', 'product_id' });
        } else if (o == 'Order') {
            keys.addAll(new List<String>{ 'OrderId', 'orderId', 'order_id' });
        } else if (o == 'Contract') {
            keys.addAll(new List<String>{ 'ContractId', 'contractId', 'contract_id' });
        } else if (o == 'Quote') {
            keys.addAll(new List<String>{ 'QuoteId', 'quoteId', 'quote_id' });
        } else if (o == 'WorkOrder') {
            keys.addAll(new List<String>{ 'WorkOrderId', 'workOrderId', 'work_order_id' });
        } else if (o == 'Asset') {
            keys.addAll(new List<String>{ 'AssetId', 'assetId', 'asset_id' });
        }         else if (o == 'ServiceAppointment') {
            keys.addAll(new List<String>{ 'ServiceAppointmentId', 'serviceAppointmentId', 'service_appointment_id' });
        } else if (o == 'ServiceResource') {
            keys.addAll(new List<String>{ 'ServiceResourceId', 'serviceResourceId', 'service_resource_id' });
        }
        return keys;
    }

    /** Keys for a *relationship* field that already matches org API (plus aliases). */
    public static List<String> lookupIdParamKeys(String fieldApiName) {
        List<String> keys = new List<String>();
        if (String.isBlank(fieldApiName)) return keys;
        String f = fieldApiName.trim();
        keys.add(f);
        if (f.length() > 1) {
            keys.add(f.substring(0, 1).toLowerCase() + f.substring(1));
        }
        if (f == 'AccountId') keys.addAll(new List<String>{ 'account_id', 'accountId' });
        else if (f == 'ContactId') keys.addAll(new List<String>{ 'contact_id', 'contactId' });
        else if (f == 'OwnerId') keys.addAll(new List<String>{ 'owner_id', 'ownerId', 'new_owner_id', 'newOwnerId' });
        else if (f == 'LeadId') keys.addAll(new List<String>{ 'lead_id', 'leadId' });
        else if (f == 'OpportunityId') keys.addAll(new List<String>{ 'opportunity_id', 'opportunityId' });
        else if (f == 'CaseId') keys.addAll(new List<String>{ 'case_id', 'caseId' });
        else if (f == 'CampaignId') keys.addAll(new List<String>{ 'campaign_id', 'campaignId' });
        else if (f == 'ParentId') keys.addAll(new List<String>{ 'parent_id', 'parentId', 'CaseId', 'caseId', 'case_id' });
        else if (f == 'QuoteId') keys.addAll(new List<String>{ 'quote_id', 'quoteId' });
        else if (f == 'OrderId') keys.addAll(new List<String>{ 'order_id', 'orderId' });
        else if (f == 'WhatId' || f == 'WhoId') keys.addAll(new List<String>{ 'record_id', 'recordId', 'Id' });
        else if (f.endsWith('Id') && f.length() > 2) {
            // OpportunityLineItemId → opportunity_line_item_id (approx)
            keys.add(f.substring(0, f.length() - 2).toLowerCase() + '_id');
        }
        return keys;
    }

    /**
     * Resolve the primary record Id for a skill on `objectApiName`.
     * Accepts Salesforce Id OR human keys (CaseNumber/Subject, Name, Email, …).
     */
    public static Id resolvePrimaryId(Map<String, Object> p, String objectApiName) {
        if (p == null) p = new Map<String, Object>();
        // Human-facing keys (preferred for agents before raw Ids)
        Id byHuman = resolveByNaturalKey(p, objectApiName);
        if (byHuman != null) return byHuman;

        String raw = toText(firstNonBlank(p, primaryIdParamKeys(objectApiName)));
        Id rid = parseSalesforceId(raw);
        if (rid != null) {
            if (String.isNotBlank(objectApiName)) {
                try {
                    if (rid.getSObjectType() != Schema.getGlobalDescribe().get(objectApiName)) {
                        rid = null;
                    }
                } catch (Exception e) {
                    // keep rid if describe fails
                }
            }
            if (rid != null) return rid;
        }
        // raw human text in Id / case_id / etc.
        if (String.isNotBlank(raw) && parseSalesforceId(raw) == null) {
            Id fromRaw = resolveNaturalKeyValue(objectApiName, raw);
            if (fromRaw != null) return fromRaw;
        }
        Id session = resolveSessionRecordId(p, resolveUserContextId(p));
        if (session == null || String.isBlank(objectApiName)) return session;
        try {
            if (session.getSObjectType() == Schema.getGlobalDescribe().get(objectApiName)) {
                return session;
            }
        } catch (Exception e) {
            return session;
        }
        return null;
    }

    /**
     * Resolve a relationship Id. Accepts Salesforce Id OR parent Name / CaseNumber, etc.
     * e.g. AccountId="Acme", CampaignId="Webinar 2024", ParentId="00001026".
     */
    public static Id resolveLookupId(Map<String, Object> p, String fieldApiName) {
        if (p == null || String.isBlank(fieldApiName)) return null;
        String raw = toText(firstNonBlank(p, lookupIdParamKeys(fieldApiName)));
        if (String.isBlank(raw)) {
            // companion *Name keys: AccountName, CampaignName, etc.
            String base = fieldApiName.endsWith('Id') ? fieldApiName.substring(0, fieldApiName.length() - 2) : fieldApiName;
            raw = toText(firstNonBlank(p, new List<String>{
                base + 'Name', base + '_name', base + 'Name',
                base, // pass-through of Account, Campaign, …
                'account_name', 'contact_name', 'opportunity_name', 'campaign_name', 'case_number', 'CaseNumber', 'Subject'
            }));
        }
        if (String.isBlank(raw)) return null;
        Id asId = parseSalesforceId(raw);
        if (asId != null) return asId;
        String targetObject = lookupTargetObject(fieldApiName);
        return resolveNaturalKeyValue(targetObject, raw);
    }

    /** Map relationship field → SObject type API name for natural-key resolution. */
    public static String lookupTargetObject(String fieldApiName) {
        if (String.isBlank(fieldApiName)) return null;
        String f = fieldApiName.trim();
        if (f == 'AccountId' || f == 'AccountToId') return 'Account';
        if (f == 'ContactId') return 'Contact';
        if (f == 'LeadId') return 'Lead';
        if (f == 'OpportunityId') return 'Opportunity';
        if (f == 'CaseId' || f == 'ParentId') return 'Case';
        if (f == 'CampaignId') return 'Campaign';
        if (f == 'OwnerId' || f == 'UserId') return 'User';
        if (f == 'Product2Id' || f == 'ProductId') return 'Product2';
        if (f == 'OrderId') return 'Order';
        if (f == 'ContractId') return 'Contract';
        if (f == 'QuoteId') return 'Quote';
        if (f == 'AssetId') return 'Asset';
        if (f == 'WorkOrderId') return 'WorkOrder';
        if (f.endsWith('Id') && f.length() > 2) return f.substring(0, f.length() - 2);
        return null;
    }

    /**
     * From parameter map, collect human identifiers for `objectApiName` and resolve.
     */
    public static Id resolveByNaturalKey(Map<String, Object> p, String objectApiName) {
        if (p == null || String.isBlank(objectApiName)) return null;
        String o = objectApiName.trim();
        List<String> keys = new List<String>();
        if (o == 'Case') {
            keys.addAll(new List<String>{
                'CaseNumber', 'caseNumber', 'case_number', 'Subject', 'subject', 'case_subject'
            });
        } else if (o == 'Account') {
            keys.addAll(new List<String>{ 'Name', 'AccountName', 'account_name', 'accountName' });
        } else if (o == 'Contact') {
            keys.addAll(new List<String>{
                'Name', 'ContactName', 'contact_name', 'Email', 'email', 'FirstName', 'LastName'
            });
        } else if (o == 'Lead') {
            keys.addAll(new List<String>{ 'Name', 'LeadName', 'lead_name', 'Email', 'email', 'Company', 'company' });
        } else if (o == 'Opportunity') {
            keys.addAll(new List<String>{ 'Name', 'OpportunityName', 'opportunity_name' });
        } else if (o == 'Campaign') {
            keys.addAll(new List<String>{ 'Name', 'CampaignName', 'campaign_name' });
        } else if (o == 'Product2') {
            keys.addAll(new List<String>{ 'Name', 'ProductName', 'product_name', 'ProductCode', 'productCode' });
        } else if (o == 'Asset') {
            keys.addAll(new List<String>{ 'Name', 'AssetName', 'asset_name', 'SerialNumber', 'serialNumber' });
        } else if (o == 'User') {
            keys.addAll(new List<String>{ 'Name', 'Username', 'Email', 'email' });
        } else {
            keys.addAll(new List<String>{ 'Name', 'name' });
        }
        for (String k : keys) {
            String v = toText(p.get(k));
            if (String.isBlank(v)) continue;
            if (parseSalesforceId(v) != null) continue; // ids handled elsewhere
            Id hit = resolveNaturalKeyValue(o, v);
            if (hit != null) return hit;
        }
        // Contact Full Name from First+Last
        if (o == 'Contact' || o == 'Lead') {
            String fn = toText(p.get('FirstName'));
            String ln = toText(p.get('LastName'));
            if (String.isNotBlank(fn) || String.isNotBlank(ln)) {
                String full = ((fn == null ? '' : fn) + ' ' + (ln == null ? '' : ln)).trim();
                if (String.isNotBlank(full)) {
                    Id hit = resolveNaturalKeyValue(o, full);
                    if (hit != null) return hit;
                }
            }
        }
        return null;
    }

    /**
     * Resolve one natural key value to an Id for the object. Exact match preferred; unique LIKE fallback.
     */
    public static Id resolveNaturalKeyValue(String objectApiName, String value) {
        if (String.isBlank(objectApiName) || String.isBlank(value)) return null;
        String o = objectApiName.trim();
        String v = value.trim();
        Id asId = parseSalesforceId(v);
        if (asId != null) {
            try {
                if (asId.getSObjectType() == Schema.getGlobalDescribe().get(o)) return asId;
            } catch (Exception e) {
                return asId;
            }
        }
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(o);
        if (sot == null || !sot.getDescribe().isAccessible()) return null;
        try {
            if (o == 'Case') {
                List<Case> byNum = [
                    SELECT Id FROM Case WHERE CaseNumber = :v WITH USER_MODE LIMIT 2
                ];
                if (byNum.size() == 1) return byNum[0].Id;
                List<Case> bySubj = [
                    SELECT Id FROM Case WHERE Subject = :v WITH USER_MODE LIMIT 2
                ];
                if (bySubj.size() == 1) return bySubj[0].Id;
                String likeV = '%' + String.escapeSingleQuotes(v) + '%';
                List<Case> fuzzy = [
                    SELECT Id FROM Case
                    WHERE Subject LIKE :likeV OR CaseNumber LIKE :likeV
                    WITH USER_MODE
                    LIMIT 2
                ];
                if (fuzzy.size() == 1) return fuzzy[0].Id;
                return null;
            }
            if (o == 'Account') {
                Id exact = uniqueQueryId('SELECT Id FROM Account WHERE Name = :v WITH USER_MODE LIMIT 2', v);
                return exact != null ? exact : uniqueLikeId('Account', 'Name', v);
            }
            if (o == 'Contact') {
                Id exactEmail = uniqueQueryId(
                    'SELECT Id FROM Contact WHERE Email = :v WITH USER_MODE LIMIT 2', v
                );
                if (exactEmail != null) return exactEmail;
                Id exactName = uniqueQueryId(
                    'SELECT Id FROM Contact WHERE Name = :v WITH USER_MODE LIMIT 2', v
                );
                if (exactName != null) return exactName;
                return uniqueLikeId('Contact', 'Name', v);
            }
            if (o == 'Lead') {
                Id exactEmail = uniqueQueryId(
                    'SELECT Id FROM Lead WHERE Email = :v AND IsConverted = false WITH USER_MODE LIMIT 2', v
                );
                if (exactEmail != null) return exactEmail;
                Id exactName = uniqueQueryId(
                    'SELECT Id FROM Lead WHERE Name = :v AND IsConverted = false WITH USER_MODE LIMIT 2', v
                );
                if (exactName != null) return exactName;
                return uniqueLikeId('Lead', 'Name', v);
            }
            if (o == 'Opportunity') {
                Id exact = uniqueQueryId(
                    'SELECT Id FROM Opportunity WHERE Name = :v WITH USER_MODE LIMIT 2', v
                );
                return exact != null ? exact : uniqueLikeId('Opportunity', 'Name', v);
            }
            if (o == 'Campaign') {
                Id exact = uniqueQueryId(
                    'SELECT Id FROM Campaign WHERE Name = :v WITH USER_MODE LIMIT 2', v
                );
                return exact != null ? exact : uniqueLikeId('Campaign', 'Name', v);
            }
            if (o == 'Product2') {
                Id byName = uniqueQueryId(
                    'SELECT Id FROM Product2 WHERE Name = :v WITH USER_MODE LIMIT 2', v
                );
                if (byName != null) return byName;
                Id byCode = uniqueQueryId(
                    'SELECT Id FROM Product2 WHERE ProductCode = :v WITH USER_MODE LIMIT 2', v
                );
                return byCode != null ? byCode : uniqueLikeId('Product2', 'Name', v);
            }
            if (o == 'Asset') {
                Id bySerial = uniqueQueryId(
                    'SELECT Id FROM Asset WHERE SerialNumber = :v WITH USER_MODE LIMIT 2', v
                );
                if (bySerial != null) return bySerial;
                Id byName = uniqueQueryId(
                    'SELECT Id FROM Asset WHERE Name = :v WITH USER_MODE LIMIT 2', v
                );
                return byName != null ? byName : uniqueLikeId('Asset', 'Name', v);
            }
            if (o == 'User') {
                List<User> users = [
                    SELECT Id FROM User
                    WHERE IsActive = true AND (Name = :v OR Username = :v OR Email = :v)
                    WITH USER_MODE LIMIT 2
                ];
                if (users.size() == 1) return users[0].Id;
                return null;
            }
            if (o == 'Order') {
                // OrderNumber if present
                Map<String, Schema.SObjectField> fmap = sot.getDescribe().fields.getMap();
                if (fmap.containsKey('OrderNumber')) {
                    List<SObject> rows = Database.query(
                        'SELECT Id FROM Order WHERE OrderNumber = :v WITH USER_MODE LIMIT 2'
                    );
                    if (rows.size() == 1) return (Id) rows[0].get('Id');
                }
            }
            // Generic Name field
            if (sot.getDescribe().fields.getMap().containsKey('Name')) {
                Id exact = uniqueQueryId(
                    'SELECT Id FROM ' + o + ' WHERE Name = :v WITH USER_MODE LIMIT 2', v
                );
                return exact != null ? exact : uniqueLikeId(o, 'Name', v);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'resolveNaturalKeyValue ' + o + ': ' + e.getMessage());
        }
        return null;
    }

    private static Id uniqueQueryId(String soql, String v) {
        // soql must bind :v
        List<SObject> rows = Database.query(soql);
        return rows.size() == 1 ? (Id) rows[0].get('Id') : null;
    }

    private static Id uniqueLikeId(String objectApi, String fieldApi, String v) {
        String likeV = '%' + String.escapeSingleQuotes(v) + '%';
        String soql = 'SELECT Id FROM ' + objectApi + ' WHERE ' + fieldApi + ' LIKE :likeV WITH USER_MODE LIMIT 2';
        List<SObject> rows = Database.query(soql);
        return rows.size() == 1 ? (Id) rows[0].get('Id') : null;
    }

    /** Resolve a parent CRM Id from common skill param aliases + session context. */
    public static Id resolveRelatedRecordId(Map<String, Object> p) {
        if (p == null) p = new Map<String, Object>();
        String explicit = toText(firstNonBlank(p, new List<String>{
            'WhatId', 'WhoId',
            'AccountId', 'ContactId', 'LeadId', 'OpportunityId', 'CaseId',
            'Id', 'recordId', 'record_id',
            'account_id', 'contact_id', 'lead_id', 'opportunity_id', 'case_id',
            'relatedToId', 'related_to_id'
        }));
        Id resolved = parseSalesforceId(explicit);
        if (resolved != null) return resolved;
        return resolveSessionRecordId(p, resolveUserContextId(p));
    }

    /**
     * True if Task.WhatId can reference this object type (polymorphic What).
     */
    public static Boolean isWhatIdObject(Id recordId) {
        if (recordId == null) return false;
        Schema.SObjectType sot = recordId.getSObjectType();
        // Who-only objects must not be assigned to WhatId
        if (sot == Contact.SObjectType || sot == Lead.SObjectType) return false;
        // Users are not valid Task WhatId targets
        if (sot == User.SObjectType) return false;
        return true;
    }

    // ────────────────────────────────────────────────────────────────────────
    // HELPERS — Fuzzy candidate generator (mirrors sample SP_CI_Agent logic)
    // ────────────────────────────────────────────────────────────────────────

    @TestVisible
    public static List<String> buildFuzzySearchCandidates(String rawName) {
        if (String.isBlank(rawName)) return new List<String>();
        String original  = rawName.trim();
        String stripped  = original.replaceAll('(?i)^(the|a|an)\\s+', '').trim();
        String collapsed = original.toLowerCase()
                                   .replaceAll('[\\s\\-_]+', '')
                                   .replaceAll('[^a-z0-9]', '');
        List<String> candidates = new List<String>();
        Set<String> seen = new Set<String>();
        for (String c : new List<String>{
            original,
            stripped,
            collapsed,
            stripped.replaceAll('[\\s\\-_]+', '').replaceAll('[^a-zA-Z0-9]', '')
        }) {
            if (String.isNotBlank(c) && !seen.contains(c.toLowerCase())) {
                candidates.add(c);
                seen.add(c.toLowerCase());
            }
        }
        for (String w : original.replaceAll('[\\-_]', ' ').split('\\s+')) {
            String wc = w.replaceAll('[^a-zA-Z0-9]', '');
            if (wc.length() >= 3 && !seen.contains(wc.toLowerCase())) {
                candidates.add(wc);
                seen.add(wc.toLowerCase());
            }
        }
        return candidates;
    }

    // ────────────────────────────────────────────────────────────────────────
    // HELPERS — Field coercion & generic field application
    // ────────────────────────────────────────────────────────────────────────

    /**
     * @description Coerces a raw value to the SObject field's expected Apex
     *              type. Supports Text, Number (Integer/Double/Currency/
     *              Percent), Boolean, Picklist, Multi-picklist, Date, Datetime,
     *              and Reference fields. Dependent picklists are accepted as
     *              raw strings — Salesforce validates the controller/dependent
     *              relationship at DML time.
     * @jira V2-8418
     */
    /**
     * @description True for empty / placeholder values the LLM often emits for
     *              optional skill params (e.g. AccountId: "" or "null").
     * @jira V2-8418
     */
    @TestVisible
    public static Boolean isBlankish(Object rawValue) {
        if (rawValue == null) return true;
        String s = String.valueOf(rawValue).trim();
        return String.isBlank(s)
            || s.equalsIgnoreCase('null')
            || s.equalsIgnoreCase('undefined')
            || s.equalsIgnoreCase('none')
            || s.equalsIgnoreCase('n/a');
    }

    public static Object coerceFieldValue(Schema.DescribeFieldResult d, Object rawValue) {
        if (rawValue == null) return null;
        Schema.DisplayType t = d.getType();
        String s = String.valueOf(rawValue).trim();
        if (t == Schema.DisplayType.Boolean) {
            if (rawValue instanceof Boolean) return rawValue;
            return s.equalsIgnoreCase('true') || s.equals('1') || s.equalsIgnoreCase('yes');
        }
        if (t == Schema.DisplayType.Integer) {
            return Integer.valueOf(s);
        }
        if (t == Schema.DisplayType.Double || t == Schema.DisplayType.Currency || t == Schema.DisplayType.Percent) {
            return Decimal.valueOf(s);
        }
        if (t == Schema.DisplayType.Date) {
            return parseToDate(rawValue);
        }
        if (t == Schema.DisplayType.DateTime) {
            try { return Datetime.valueOfGmt(s.replace('T', ' ').replace('Z', '')); } catch (Exception e) {}
            try { return Datetime.valueOf(s); } catch (Exception e) {}
            return null;
        }
        if (t == Schema.DisplayType.MultiPicklist) {
            if (rawValue instanceof List<Object>) {
                List<String> parts = new List<String>();
                for (Object o : (List<Object>) rawValue) parts.add(String.valueOf(o));
                return String.join(parts, ';');
            }
            return s;
        }
        if (t == Schema.DisplayType.Reference) {
            if (isBlankish(rawValue)) return null;
            Id parsed = parseSalesforceId(s);
            if (parsed == null) {
                throw new SkillException('Invalid Id value "' + s + '"');
            }
            // Ensure lookup Id matches an allowed reference target (e.g. AccountId ≠ Contact Id).
            List<Schema.SObjectType> targets = d.getReferenceTo();
            if (targets != null && !targets.isEmpty()) {
                Schema.SObjectType actual = parsed.getSObjectType();
                Boolean ok = false;
                for (Schema.SObjectType tRef : targets) {
                    if (tRef == actual) { ok = true; break; }
                }
                if (!ok) {
                    throw new SkillException(
                        'Id "' + s + '" is a ' + String.valueOf(actual) +
                        ' Id, but ' + d.getName() + ' requires ' + String.valueOf(targets[0])
                    );
                }
            }
            return parsed;
        }
        return s;
    }

    /**
     * @description Applies a Map<String,Object> of field values to an SObject
     *              with FLS / type validation. Throws SkillException when the
     *              field is unknown, not editable or value cannot be coerced.
     *              Blank / placeholder values are skipped on create (so optional
     *              lookups like AccountId:"" do not fail). On update, blank
     *              reference values clear the lookup.
     * @jira V2-8418
     */
    public static void applyFieldsToSObject(SObject record, Map<String, Object> fields, Boolean isUpdate) {
        if (fields == null || fields.isEmpty()) return;
        Schema.DescribeSObjectResult od = record.getSObjectType().getDescribe();
        Map<String, Schema.SObjectField> fmap = od.fields.getMap();
        for (String key : fields.keySet()) {
            if (RUNTIME_META_KEYS.contains(key)) continue;
            Schema.SObjectField f = fmap.get(key);
            if (f == null) {
                throw new SkillException('Unknown field "' + key + '" on ' + od.getName());
            }
            Schema.DescribeFieldResult d = f.getDescribe();
            if (isUpdate && !d.isUpdateable()) throw new SkillException('Field not updateable: ' + key);
            if (!isUpdate && !d.isCreateable()) throw new SkillException('Field not createable: ' + key);
            Object raw = fields.get(key);
            if (isBlankish(raw)) {
                // Create: omit empty optional fields (LLM often sends AccountId:"" / "null").
                if (!isUpdate) continue;
                // Update: only clear nullable non-required fields.
                if (d.isNillable()) {
                    record.put(f, null);
                }
                continue;
            }
            try {
                record.put(f, coerceFieldValue(d, raw));
            } catch (SkillException sex) {
                throw sex;
            } catch (Exception ex) {
                throw new SkillException('Could not set "' + key + '" — ' + ex.getMessage());
            }
        }
    }

    /**
     * @description Concrete date parser (yyyy-MM-dd, dd/MM/yyyy, MM/dd/yyyy).
     *              Relative expressions ("next monday") MUST be resolved by
     *              the system prompt before reaching this method.
     * @jira V2-8418
     */
    /**
     * @description Hex string to integer (used by fetch_picklist_values bitmap decoding).
     * @jira V2-8418
     */
    public static Integer hexToInt(String s) {
        if (String.isBlank(s)) return 0;
        Integer val = 0;
        String lower = s.toLowerCase();
        String chars = '0123456789abcdef';
        for (Integer i = 0; i < lower.length(); i++) {
            Integer d = chars.indexOf(lower.substring(i, i + 1));
            if (d < 0) return 0;
            val = val * 16 + d;
        }
        return val;
    }

    public static Date parseToDate(Object o) {
        if (o == null) return null;
        if (o instanceof Date) return (Date) o;
        if (o instanceof Datetime) return ((Datetime) o).date();
        String s = toText(o);
        if (String.isBlank(s)) return null;
        s = s.trim();
        try { if (s.length() == 10 && s.contains('-')) return Date.valueOf(s); } catch (Exception e) {}
        try {
            if (s.contains('/')) {
                List<String> parts = s.split('/', 0);
                if (parts.size() == 3) {
                    Integer a = Integer.valueOf(parts[0].trim());
                    Integer b = Integer.valueOf(parts[1].trim());
                    String  yStr = parts[2].trim();
                    Integer y = yStr.length() <= 2 ? Integer.valueOf('20' + yStr) : Integer.valueOf(yStr);
                    if (a > 12) return Date.newInstance(y, b, a);
                    if (b > 12) return Date.newInstance(y, a, b);
                    return Date.newInstance(y, a, b);
                }
            }
        } catch (Exception e) {}
        try { return Date.valueOf(s); } catch (Exception e) {}
        return null;
    }

    /**
     * @description Builds an HTML diff card body listing old → new values.
     * @jira V2-8418
     */
    public static String buildDiffBody(Map<String, Object> oldMap, Map<String, Object> newMap) {
        String body = '<ul>';
        for (String k : newMap.keySet()) {
            Object oldV = oldMap.get(k);
            Object newV = newMap.get(k);
            String oldS = oldV == null ? '(none)' : escapeHtml(String.valueOf(oldV));
            String newS = newV == null ? '(none)' : escapeHtml(String.valueOf(newV));
            body += '<li><b>' + escapeHtml(k) + ':</b> ' + oldS + ' → <b>' + newS + '</b></li>';
        }
        return body + '</ul>';
    }

    /**
     * @description Maximum number of matching records the fuzzy search will
     *              fetch from the database in a single skill invocation.
     *              The agent only displays the latest 5 of these (see
     *              applyTopNAndCount); the remainder is reported as a count
     *              so the user knows how many additional close matches exist.
     *              Capped to stay safely under SOQL row governor limits.
     * @jira V2-8418
     */
    @TestVisible
    public static Integer FUZZY_HARD_CAP = 200;

    /**
     * @description Number of records the agent should DISPLAY out of the full
     *              fuzzy-match set (the rest are surfaced via `remaining`).
     * @jira V2-8418
     */
    @TestVisible
    public static Integer FUZZY_DISPLAY_LIMIT = 5;

    /**
     * @description Generic fuzzy search for any object using its Name (or
     *              equivalent) field. Returns ALL deduped matches (up to
     *              FUZZY_HARD_CAP), ordered by LastModifiedDate DESC. Callers
     *              are expected to slice the returned list with
     *              applyTopNAndCount(..) for display.
     * @jira V2-8418
     */
    public static List<SObject> fuzzyQuery(String objectApiName, String nameField, List<String> additionalFields, String searchTerm) {
        return fuzzyQueryMulti(objectApiName, new List<String>{ nameField }, additionalFields, searchTerm);
    }

    /**
     * @description Multi-field fuzzy search variant — ORs every field in
     *              `searchFields` against each generated candidate pattern.
     *              Implementation does a two-pass query: pass 1 collects Ids
     *              (cheap, ordered, deduped); pass 2 re-queries the full
     *              fieldset for the merged Id set with a single global
     *              ORDER BY LastModifiedDate DESC. This guarantees the
     *              caller-visible ordering is correct across candidates.
     *              Hard-capped at FUZZY_HARD_CAP rows.
     * @jira V2-8418
     */
    public static List<SObject> fuzzyQueryMulti(String objectApiName, List<String> searchFields, List<String> additionalFields, String searchTerm) {
        List<String> candidates = buildFuzzySearchCandidates(searchTerm);
        if (candidates.isEmpty() || searchFields == null || searchFields.isEmpty()) {
            return new List<SObject>();
        }
        Set<Id> matchedIds = new Set<Id>();
        for (String cand : candidates) {
            if (matchedIds.size() >= FUZZY_HARD_CAP) break;
            String pattern = '%' + cand + '%';
            List<String> ors = new List<String>();
            for (String f : searchFields) ors.add(f + ' LIKE :pattern');
            String idSoql = 'SELECT Id FROM ' + objectApiName
                          + ' WHERE (' + String.join(ors, ' OR ') + ')'
                          + ' WITH USER_MODE ORDER BY LastModifiedDate DESC LIMIT ' + FUZZY_HARD_CAP;
            for (SObject r : Database.query(idSoql)) {
                matchedIds.add((Id) r.get('Id'));
                if (matchedIds.size() >= FUZZY_HARD_CAP) break;
            }
        }
        if (matchedIds.isEmpty()) return new List<SObject>();
        Set<String> sel = new Set<String>{ 'Id' };
        sel.addAll(searchFields);
        if (additionalFields != null) sel.addAll(additionalFields);
        String fieldList = String.join(new List<String>(sel), ', ');
        String soql = 'SELECT ' + fieldList + ' FROM ' + objectApiName
                    + ' WHERE Id IN :matchedIds'
                    + ' WITH USER_MODE ORDER BY LastModifiedDate DESC LIMIT ' + FUZZY_HARD_CAP;
        return Database.query(soql);
    }

    /**
     * @description Slices a fuzzy-search result list into "the latest N" plus
     *              a count of how many additional matches exist beyond the
     *              displayed slice. Returns a Map with keys `rows`,
     *              `totalFound`, `displayed`, `remaining` — used uniformly
     *              by every fuzzy_search_* skill.
     * @jira V2-8418
     */
    public static Map<String, Object> applyTopNAndCount(List<SObject> rows, Integer n) {
        Integer total = rows == null ? 0 : rows.size();
        List<SObject> top = new List<SObject>();
        Integer take = Math.min(n, total);
        for (Integer i = 0; i < take; i++) top.add(rows[i]);
        return new Map<String, Object>{
            'rows'       => top,
            'totalFound' => total,
            'displayed'  => top.size(),
            'remaining'  => Math.max(0, total - top.size())
        };
    }

    /**
     * @description Builds the standard `<a href="...">View Record</a>` HTML
     *              anchor used in fuzzy search result rows. Centralised so
     *              every fuzzy_search_* skill renders the View Record
     *              hyperlink identically.
     * @jira V2-8418
     */
    public static String viewRecordAnchor(Id rid) {
        return '<a href="' + recordUrl(rid) + '" target="_blank">View Record</a>';
    }

public static String buildAddress(String s, String c, String st, String z, String co) {
        List<String> parts = new List<String>();
        if (String.isNotBlank(s))  parts.add(s);
        if (String.isNotBlank(c))  parts.add(c);
        if (String.isNotBlank(st)) parts.add(st);
        if (String.isNotBlank(z))  parts.add(z);
        if (String.isNotBlank(co)) parts.add(co);
        return String.join(parts, ', ');
    }

    /**
     * @description Builds a flat field-map from a parameter bag. Every top-level
     *              key in `p` is treated as a Salesforce field API name, EXCEPT
     *              keys listed in `reservedKeys`, the legacy 'fields' wrapper,
     *              and RUNTIME_META_KEYS (e.g. userContextId injected by GPTfy).
     *              For backward compatibility, if a legacy nested 'fields' map
     *              is present, its entries are merged in first; flat top-level
     *              keys then win on conflict.
     * @jira V2-8418
     */
    public static Map<String, Object> buildFieldMap(Map<String, Object> p, Set<String> reservedKeys) {
        Map<String, Object> result = new Map<String, Object>();
        if (p == null) return result;
        Set<String> fullReserved = (reservedKeys == null) ? new Set<String>() : new Set<String>(reservedKeys);
        fullReserved.add('fields');
        fullReserved.addAll(RUNTIME_META_KEYS);
        Object legacy = p.get('fields');
        if (legacy instanceof Map<String, Object>) {
            for (String k : ((Map<String, Object>) legacy).keySet()) {
                if (fullReserved.contains(k)) continue;
                result.put(k, ((Map<String, Object>) legacy).get(k));
            }
        }
        for (String k : p.keySet()) {
            if (fullReserved.contains(k)) continue;
            result.put(k, p.get(k));
        }
        return result;
    }

    /**
     * @description Strips runtime meta keys (userContextId, etc.) from a field
     *              map so they never reach SOQL or DML.
     * @jira V2-8418
     */
    @TestVisible
    public static Map<String, Object> stripRuntimeMetaKeys(Map<String, Object> fields) {
        Map<String, Object> cleaned = new Map<String, Object>();
        if (fields == null) return cleaned;
        for (String k : fields.keySet()) {
            if (RUNTIME_META_KEYS.contains(k)) continue;
            cleaned.put(k, fields.get(k));
        }
        return cleaned;
    }

    /**
     * @description Reusable generic update used by every update_*_fields skill.
     *              Captures pre-update values, applies coerced fields, persists,
     *              then renders an HTML diff card. Returns errorHtml on failure.
     * @jira V2-8418
     */
    public static String performGenericUpdate(String objApi, Id recId, Map<String, Object> fields, String successTitle, String linkLabel, String recordLabel) {
        try {
            Map<String, Object> safeFields = stripRuntimeMetaKeys(fields);
            if (safeFields.isEmpty()) {
                return errorHtml('Could not update record', 'Missing parameter: at least one field to update');
            }
            Schema.SObjectType sot = Schema.getGlobalDescribe().get(objApi);
            if (sot == null) {
                return errorHtml('Could not update record', 'Unknown object: ' + objApi);
            }
            Map<String, Schema.SObjectField> fmap = sot.getDescribe().fields.getMap();
            List<String> selectFields = new List<String>();
            for (String key : safeFields.keySet()) {
                Schema.SObjectField ftoken = fmap.get(key);
                if (ftoken == null) {
                    return errorHtml('Could not update record', 'Unknown field "' + key + '" on ' + objApi);
                }
                // Use describe name only — never raw client keys in SOQL
                selectFields.add(ftoken.getDescribe().getName());
            }
            String soql = 'SELECT Id, ' + String.join(selectFields, ', ')
                + ' FROM ' + objApi + ' WHERE Id = :recId WITH USER_MODE LIMIT 1';
            List<SObject> existing = Database.query(soql);
            if (existing.isEmpty()) return errorHtml('Could not update record', 'No record found for provided Id.');
            SObject before = existing[0];
            Map<String, Object> oldMap = new Map<String, Object>();
            for (String k : selectFields) oldMap.put(k, before.get(k));
            SObject toUpdate = before.getSObjectType().newSObject(recId);
            applyFieldsToSObject(toUpdate, safeFields, true);
            Database.update(toUpdate, AccessLevel.USER_MODE);
            // Re-query to display saved values
            List<SObject> after = Database.query(soql);
            Map<String, Object> newMap = new Map<String, Object>();
            for (String k : selectFields) newMap.put(k, after[0].get(k));
            String header = '<br/><b>' + escapeHtml(recordLabel) + '</b>';
            return successHtml(successTitle, header + buildDiffBody(oldMap, newMap), recId, linkLabel);
        } catch (Exception ex) {
            return errorHtml('Could not update record', ex.getMessage());
        }
    }

    public static String buildSessionContextMessage(String userContextId, Id recordId, Map<String, Object> ctx) {
        List<String> parts = new List<String>();
        parts.add('User Context Id: ' + (String.isBlank(userContextId) ? 'not available yet' : userContextId));
        parts.add('Record Id: ' + (recordId == null ? 'none' : String.valueOf(recordId)));
        if (recordId != null && ctx.get('objectType') != null) {
            parts.add('Object: ' + String.valueOf(ctx.get('objectType')));
        }
        if (ctx.get('relationType') != null) {
            Object relId = ctx.get('WhoId') != null ? ctx.get('WhoId') : ctx.get('WhatId');
            parts.add(String.valueOf(ctx.get('relationType')) + ': ' + String.valueOf(relId));
        }
        return String.join(parts, ' | ');
    }

    @TestVisible
    public static String resolveUserContextId(Map<String, Object> p) {
        String ctx = toText(firstNonNull(p, new List<String>{ 'userContextId', 'user_context_id' }));
        if (String.isNotBlank(ctx)) return ctx;

        List<ccai__AI_Response__c> responses = [
            SELECT Name, ccai__User_Context_Id__c
            FROM ccai__AI_Response__c
            WHERE OwnerId = :UserInfo.getUserId()
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        if (responses.isEmpty()) return null;
        if (String.isNotBlank(responses[0].ccai__User_Context_Id__c)) {
            return responses[0].ccai__User_Context_Id__c;
        }
        return responses[0].Name;
    }

    @TestVisible
    public static Id resolveSessionRecordId(Map<String, Object> p, String userContextId) {
        String explicit = toText(firstNonBlank(p, new List<String>{
            'record_id', 'recordId', 'relatedToId', 'related_to_id', 'Id'
        }));
        Id resolved = parseSalesforceId(explicit);
        if (resolved != null) return resolved;

        if (String.isNotBlank(userContextId)) {
            List<ccai__AI_Response__c> responses = [
                SELECT ccai__Record_Id__c
                FROM ccai__AI_Response__c
                WHERE ccai__User_Context_Id__c = :userContextId OR Name = :userContextId
                WITH USER_MODE
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            if (!responses.isEmpty() && String.isNotBlank(responses[0].ccai__Record_Id__c)) {
                resolved = parseSalesforceId(responses[0].ccai__Record_Id__c);
                if (resolved != null) return resolved;
            }
            if (isSalesforceIdToken(userContextId)) {
                return parseSalesforceId(userContextId);
            }
        }
        return null;
    }

    @TestVisible
    public static Boolean isSalesforceIdToken(String raw) {
        if (String.isBlank(raw)) return false;
        String s = raw.trim();
        return (s.length() == 15 || s.length() == 18) && parseSalesforceId(s) != null;
    }

    @TestVisible
    public static Id parseSalesforceId(String raw) {
        if (String.isBlank(raw)) return null;
        try {
            return Id.valueOf(raw.trim());
        } catch (Exception e) {
            return null;
        }
    }

    @TestVisible
    public static Boolean isWhoIdObject(Id recordId) {
        Schema.SObjectType sot = recordId.getSObjectType();
        return sot == Contact.SObjectType || sot == Lead.SObjectType;
    }

    // ── Utility skills (called by UtilityAgenticSkillsHandler) ──

    public static String skillBulkUpdateRecords(Map<String, Object> p) {
        String objApi = toText(p.get('object_api_name'));
        Object recsRaw = p.get('records');
        if (String.isBlank(objApi)) return errorHtml('Could not bulk update', 'Missing parameter: object_api_name');
        if (!(recsRaw instanceof List<Object>)) return errorHtml('Could not bulk update', 'Missing parameter: records (List)');
        List<Object> recs = (List<Object>) recsRaw;
        if (recs.isEmpty()) return errorHtml('Could not bulk update', 'records list is empty.');
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(objApi);
        if (sot == null || !sot.getDescribe().isUpdateable()) return errorHtml('Could not bulk update', 'Object not updateable: ' + objApi);
        List<SObject> toUpdate = new List<SObject>();
        Integer skipped = 0;
        try {
            for (Object o : recs) {
                if (!(o instanceof Map<String, Object>)) { skipped++; continue; }
                Map<String, Object> row = (Map<String, Object>) o;
                String idStr = toText(row.get('Id'));
                if (String.isBlank(idStr)) { skipped++; continue; }
                SObject s = sot.newSObject((Id) idStr);
                Map<String, Object> apply = stripRuntimeMetaKeys(new Map<String, Object>(row));
                apply.remove('Id');
                applyFieldsToSObject(s, apply, true);
                toUpdate.add(s);
            }
            if (toUpdate.isEmpty()) return errorHtml('Could not bulk update', 'No valid rows in payload.');
            Database.SaveResult[] srs = Database.update(toUpdate, false);
            Integer ok = 0, fail = 0;
            List<String> errors = new List<String>();
            for (Database.SaveResult sr : srs) {
                if (sr.isSuccess()) ok++;
                else { fail++; errors.add(sr.getErrors()[0].getMessage()); }
            }
            String body = '<ul><li><b>Object:</b> ' + escapeHtml(objApi) + '</li>'
                        + '<li><b>Succeeded:</b> ' + ok + '</li>'
                        + '<li><b>Failed:</b> ' + fail + '</li>'
                        + '<li><b>Skipped:</b> ' + skipped + '</li></ul>';
            if (!errors.isEmpty()) {
                body += '<b>First errors:</b><ul>';
                for (Integer i = 0; i < Math.min(3, errors.size()); i++) body += '<li>' + escapeHtml(errors[i]) + '</li>';
                body += '</ul>';
            }
            return successHtml('Bulk Update Complete', body, null, null);
        } catch (Exception ex) {
            return errorHtml('Could not bulk update', ex.getMessage());
        }
    }

    public static String skillFetchRecordHistory(Map<String, Object> p) {
        String rid    = toText(firstNonNull(p, new List<String>{ 'record_id', 'recordId', 'Id' }));
        String objApi = toText(p.get('object_api_name'));
        if (String.isBlank(rid))    return errorJson('Missing required parameter: record_id');
        if (String.isBlank(objApi)) return errorJson('Missing required parameter: object_api_name');
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(objApi);
        if (sot == null || !sot.getDescribe().isAccessible()) return errorJson('Object not accessible: ' + objApi);
        Integer days = 30;
        Object dRaw = p.get('days');
        if (dRaw != null && String.isNotBlank(toText(dRaw))) {
            try { days = Integer.valueOf(toText(dRaw)); } catch (Exception e) { days = 30; }
        }
        days = Math.max(1, Math.min(days, 365));
        String histObj = objApi.endsWith('__c') ? objApi.replace('__c', '__History') : objApi + 'History';
        Schema.SObjectType histSot = Schema.getGlobalDescribe().get(histObj);
        if (histSot == null || !histSot.getDescribe().isAccessible()) {
            return successJson(new Map<String, Object>{ 'status' => 'unavailable', 'message' => 'Field history not enabled for ' + objApi + '.' });
        }
        Datetime cutoff = System.now().addDays(-days);
        String parentField = objApi.endsWith('__c') ? 'ParentId' : (objApi + 'Id');
        try {
            String soql = 'SELECT Field, OldValue, NewValue, CreatedDate, CreatedBy.Name FROM ' + histObj
                        + ' WHERE ' + parentField + ' = :rid AND CreatedDate >= :cutoff'
                        + ' WITH USER_MODE ORDER BY CreatedDate DESC LIMIT 500';
            List<SObject> hist = Database.query(soql);
            List<Map<String, Object>> rows = new List<Map<String, Object>>();
            for (SObject h : hist) {
                rows.add(new Map<String, Object>{
                    'field'     => h.get('Field'),
                    'oldValue'  => h.get('OldValue') != null ? String.valueOf(h.get('OldValue')) : null,
                    'newValue'  => h.get('NewValue') != null ? String.valueOf(h.get('NewValue')) : null,
                    'changedAt' => String.valueOf(h.get('CreatedDate'))
                });
            }
            return successJson(new Map<String, Object>{ 'recordId' => rid, 'object' => objApi, 'lookbackDays' => days, 'changeCount' => rows.size(), 'history' => rows });
        } catch (Exception ex) {
            return errorJson('Could not read history: ' + ex.getMessage());
        }
    }

    public static String skillFetchUserInfo(Map<String, Object> p) {
        Id me = UserInfo.getUserId();
        List<User> us = [
            SELECT Id, Name, Username, Email, FirstName, LastName, IsActive,
                   ProfileId, Profile.Name, UserRoleId, UserRole.Name,
                   TimeZoneSidKey, LocaleSidKey, LanguageLocaleKey
            FROM User WHERE Id = :me LIMIT 1
        ];
        if (us.isEmpty()) return errorJson('User not found.');
        User u = us[0];
        return successJson(new Map<String, Object>{
            'Id' => u.Id, 'Name' => u.Name, 'Email' => u.Email,
            'Username' => u.Username, 'IsActive' => u.IsActive,
            'Profile' => u.Profile != null ? u.Profile.Name : null,
            'Role'    => u.UserRole != null ? u.UserRole.Name : null,
            'TimeZone' => u.TimeZoneSidKey, 'Locale' => u.LocaleSidKey, 'Language' => u.LanguageLocaleKey,
            'currentdate__c' => String.valueOf(Date.today())
        });
    }

    public static String skillRunInternalPrompt(Map<String, Object> p) {
        String prid = toText(firstNonNull(p, new List<String>{ 'prompt_request_id', 'promptRequestId' }));
        String rid  = toText(firstNonNull(p, new List<String>{ 'record_id', 'recordId', 'Id' }));
        if (String.isBlank(prid)) return errorJson('Missing required parameter: prompt_request_id');
        if (String.isBlank(rid))  return errorJson('Missing required parameter: record_id');
        Id resolved;
        try { resolved = Id.valueOf(rid); } catch (Exception e) { return errorJson('Invalid record_id.'); }
        if (Test.isRunningTest() && bypassPromptForUnitTest) {
            return successJson(new Map<String, Object>{ 'status' => 'success', 'message' => 'UNIT_TEST_PLACEHOLDER', 'recordId' => resolved });
        }
        try {
            ccai.AIPromptProcessingInvokable.RequestWrapper wrap = new ccai.AIPromptProcessingInvokable.RequestWrapper();
            wrap.promptRequestId     = prid;
            wrap.recordId            = resolved;
            wrap.customPromptCommand = '';
            List<ccai.AIPromptProcessingInvokable.ResponseWrapper> resp =
                ccai.AIPromptProcessingInvokable.processRequest(new List<ccai.AIPromptProcessingInvokable.RequestWrapper>{ wrap });
            if (resp == null || resp.isEmpty()) return errorJson('No response from AI prompt processing.');
            return successJson(new Map<String, Object>{ 'status' => 'success', 'message' => resp[0].responseBody, 'recordId' => resolved });
        } catch (Exception ex) {
            return errorJson('Prompt invocation failed: ' + ex.getMessage());
        }
    }

    public static String skillFetchPicklistValues(Map<String, Object> p) {
        String objApi = toText(p.get('object_api_name'));
        String fld    = toText(p.get('field_api_name'));
        String ctrl   = toText(p.get('controller_value'));
        if (String.isBlank(objApi)) return errorJson('Missing required parameter: object_api_name');
        if (String.isBlank(fld))    return errorJson('Missing required parameter: field_api_name');
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(objApi);
        if (sot == null) return errorJson('Object not found: ' + objApi);
        Schema.SObjectField f = sot.getDescribe().fields.getMap().get(fld);
        if (f == null) return errorJson('Field not found: ' + fld);
        Schema.DescribeFieldResult d = f.getDescribe();
        if (d.getType() != Schema.DisplayType.Picklist && d.getType() != Schema.DisplayType.MultiPicklist) {
            return errorJson('Field is not a picklist: ' + fld);
        }
        List<Map<String, Object>> values = new List<Map<String, Object>>();
        if (String.isNotBlank(ctrl) && d.isDependentPicklist()) {
            Schema.SObjectField ctrlField = d.getController();
            Map<String, Integer> ctrlIndex = new Map<String, Integer>();
            Integer idx = 0;
            for (Schema.PicklistEntry e : ctrlField.getDescribe().getPicklistValues()) {
                ctrlIndex.put(e.getValue(), idx++);
            }
            Integer ci = ctrlIndex.get(ctrl);
            if (ci == null) return errorJson('Controller value "' + ctrl + '" not found on ' + ctrlField.getDescribe().getName());
            Integer byteIdx = ci / 8;
            Integer bitIdx  = 7 - (Math.mod(ci, 8));
            for (Schema.PicklistEntry e : d.getPicklistValues()) {
                String payload = JSON.serialize(e);
                Map<String, Object> meta = (Map<String, Object>) JSON.deserializeUntyped(payload);
                String validFor = (String) meta.get('validFor');
                if (String.isBlank(validFor)) continue;
                Blob decoded = EncodingUtil.base64Decode(validFor);
                String hex = EncodingUtil.convertToHex(decoded);
                if (byteIdx * 2 + 2 > hex.length()) continue;
                Integer byteVal = hexToInt(hex.substring(byteIdx * 2, byteIdx * 2 + 2));
                if ((byteVal & (1 << bitIdx)) != 0) {
                    values.add(new Map<String, Object>{ 'label' => e.getLabel(), 'value' => e.getValue(), 'active' => e.isActive() });
                }
            }
        } else {
            for (Schema.PicklistEntry e : d.getPicklistValues()) {
                values.add(new Map<String, Object>{ 'label' => e.getLabel(), 'value' => e.getValue(), 'active' => e.isActive(), 'default' => e.isDefaultValue() });
            }
        }
        return successJson(new Map<String, Object>{
            'object' => objApi, 'field' => fld,
            'isDependent' => d.isDependentPicklist(),
            'controllerValue' => ctrl, 'count' => values.size(), 'values' => values
        });
    }

    public static String skillFetchSessionContext(Map<String, Object> p) {
        String userContextId = resolveUserContextId(p);
        Id recordId = resolveSessionRecordId(p, userContextId);
        Map<String, Object> result = new Map<String, Object>{
            'userContextId' => userContextId,
            'userId' => UserInfo.getUserId(),
            'recordId' => recordId,
            'WhoId' => null,
            'WhatId' => null,
            'relationType' => null,
            'objectType' => null
        };
        if (recordId != null) {
            String objectType = String.valueOf(recordId.getSObjectType());
            result.put('objectType', objectType);
            if (isWhoIdObject(recordId)) {
                result.put('WhoId', recordId);
                result.put('relationType', 'WhoId');
            } else {
                result.put('WhatId', recordId);
                result.put('relationType', 'WhatId');
            }
        }
        result.put('message', buildSessionContextMessage(userContextId, recordId, result));
        return successJson(result);
    }

    /**
     * @description Skill — transfer_record_owner. Updates OwnerId on any
     *              updateable object that exposes OwnerId.
     * @jira V2-8418
     */
    public static String skillTransferRecordOwner(Map<String, Object> p) {
        String rid = toText(firstNonNull(p, new List<String>{ 'record_id', 'recordId', 'Id' }));
        String newOwner = toText(firstNonNull(p, new List<String>{ 'new_owner_id', 'owner_id', 'OwnerId' }));
        if (String.isBlank(rid)) return errorHtml('Could not transfer owner', 'Missing parameter: record_id');
        if (String.isBlank(newOwner)) return errorHtml('Could not transfer owner', 'Missing parameter: new_owner_id');
        Id recId;
        Id ownerId;
        try {
            recId = Id.valueOf(rid.trim());
            ownerId = Id.valueOf(newOwner.trim());
        } catch (Exception e) {
            return errorHtml('Could not transfer owner', 'Invalid record_id or new_owner_id.');
        }
        Schema.SObjectType sot = recId.getSObjectType();
        String objApi = sot.getDescribe().getName();
        if (!sot.getDescribe().isUpdateable()) {
            return errorHtml('Could not transfer owner', objApi + ' is not updateable.');
        }
        Map<String, Schema.SObjectField> fmap = sot.getDescribe().fields.getMap();
        if (!fmap.containsKey('OwnerId') || !fmap.get('OwnerId').getDescribe().isUpdateable()) {
            return errorHtml('Could not transfer owner', 'OwnerId is not updateable on ' + objApi + '.');
        }
        String labelField = 'Id';
        if (fmap.containsKey('Name')) labelField = 'Name';
        else if (fmap.containsKey('CaseNumber')) labelField = 'CaseNumber';
        else if (fmap.containsKey('Subject')) labelField = 'Subject';
        String soql = 'SELECT Id, OwnerId, ' + labelField + ' FROM ' + objApi + ' WHERE Id = :recId WITH USER_MODE LIMIT 1';
        List<SObject> rows = Database.query(soql);
        if (rows.isEmpty()) return errorHtml('Could not transfer owner', 'No record found for provided Id.');
        SObject row = rows[0];
        Id oldOwner = (Id) row.get('OwnerId');
        if (oldOwner == ownerId) {
            return errorHtml('Could not transfer owner', 'Record is already owned by that user or queue.');
        }
        String recordLabel = String.valueOf(row.get(labelField));
        return performGenericUpdate(objApi, recId, new Map<String, Object>{ 'OwnerId' => ownerId }, 'Owner Transferred', 'View Record', recordLabel);
    }

    public static String skillFetchMyOpenOpportunities(Map<String, Object> p) {
        if (!Schema.sObjectType.Opportunity.isAccessible()) return errorJson('Opportunity is not accessible.');
        Id ownerId = UserInfo.getUserId();
        Integer lim = 25;
        Object lRaw = p.get('limit');
        if (lRaw != null && String.isNotBlank(toText(lRaw))) {
            try { lim = Integer.valueOf(toText(lRaw)); } catch (Exception e) { lim = 25; }
        }
        lim = Math.max(1, Math.min(lim, 200));
        List<Opportunity> opps = [
            SELECT Id, Name, StageName, CloseDate, Amount, AccountId, Account.Name
            FROM Opportunity
            WHERE OwnerId = :ownerId AND IsClosed = false
            WITH USER_MODE
            ORDER BY CloseDate ASC
            LIMIT :lim
        ];
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        for (Opportunity o : opps) {
            rows.add(new Map<String, Object>{
                'Id' => o.Id, 'Name' => o.Name, 'StageName' => o.StageName,
                'CloseDate' => String.valueOf(o.CloseDate), 'Amount' => o.Amount,
                'Account' => o.Account != null ? o.Account.Name : null,
                'recordUrl' => recordUrl(o.Id), 'viewRecord' => viewRecordAnchor(o.Id)
            });
        }
        return successJson(new Map<String, Object>{
            'ownerId' => ownerId, 'count' => rows.size(), 'opportunities' => rows
        });
    }

    public static String skillFetchStaleOpportunities(Map<String, Object> p) {
        if (!Schema.sObjectType.Opportunity.isAccessible()) return errorJson('Opportunity is not accessible.');
        Id ownerId = UserInfo.getUserId();
        Object ownerOnly = p.get('my_opportunities_only');
        Boolean scopeMine = ownerOnly == null || !String.valueOf(ownerOnly).equalsIgnoreCase('false');
        Integer lim = 25;
        Object lRaw = p.get('limit');
        if (lRaw != null && String.isNotBlank(toText(lRaw))) {
            try { lim = Integer.valueOf(toText(lRaw)); } catch (Exception e) { lim = 25; }
        }
        lim = Math.max(1, Math.min(lim, 200));
        Date today = Date.today();
        List<Opportunity> opps;
        if (scopeMine) {
            opps = [
                SELECT Id, Name, StageName, CloseDate, Amount, LastModifiedDate, AccountId, Account.Name
                FROM Opportunity
                WHERE OwnerId = :ownerId AND IsClosed = false AND CloseDate < :today
                WITH USER_MODE
                ORDER BY CloseDate ASC
                LIMIT :lim
            ];
        } else {
            opps = [
                SELECT Id, Name, StageName, CloseDate, Amount, LastModifiedDate, AccountId, Account.Name, OwnerId, Owner.Name
                FROM Opportunity
                WHERE IsClosed = false AND CloseDate < :today
                WITH USER_MODE
                ORDER BY CloseDate ASC
                LIMIT :lim
            ];
        }
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        for (Opportunity o : opps) {
            Map<String, Object> row = new Map<String, Object>{
                'Id' => o.Id, 'Name' => o.Name, 'StageName' => o.StageName,
                'CloseDate' => String.valueOf(o.CloseDate), 'Amount' => o.Amount,
                'LastModifiedDate' => String.valueOf(o.LastModifiedDate),
                'Account' => o.Account != null ? o.Account.Name : null,
                'recordUrl' => recordUrl(o.Id), 'viewRecord' => viewRecordAnchor(o.Id)
            };
            if (!scopeMine) row.put('Owner', o.Owner != null ? o.Owner.Name : null);
            rows.add(row);
        }
        return successJson(new Map<String, Object>{
            'staleDefinition' => 'Open opportunities with CloseDate before today',
            'scopedToCurrentUser' => scopeMine,
            'count' => rows.size(),
            'opportunities' => rows
        });
    }

    public static String skillSearchKnowledgeArticles(Map<String, Object> p) {
        String term = toText(firstNonNull(p, new List<String>{ 'search_term', 'query', 'keyword' }));
        if (String.isBlank(term)) return errorJson('Missing required parameter: search_term');
        Schema.SObjectType kavType = Schema.getGlobalDescribe().get('KnowledgeArticleVersion');
        if (kavType == null || !kavType.getDescribe().isAccessible()) {
            return successJson(new Map<String, Object>{
                'status' => 'unavailable', 'message' => 'Knowledge is not enabled in this org.'
            });
        }
        Integer lim = 10;
        Object lRaw = p.get('limit');
        if (lRaw != null && String.isNotBlank(toText(lRaw))) {
            try { lim = Integer.valueOf(toText(lRaw)); } catch (Exception e) { lim = 10; }
        }
        lim = Math.max(1, Math.min(lim, 25));
        try {
            String escaped = String.escapeSingleQuotes(term);
            String sosl = 'FIND {' + escaped + '} IN ALL FIELDS RETURNING KnowledgeArticleVersion'
                + '(Id, Title, Summary, ArticleNumber, UrlName, KnowledgeArticleId'
                + ' WHERE PublishStatus = \'Online\') LIMIT ' + lim;
            List<List<SObject>> searchResults = Search.query(sosl);
            List<SObject> articles = searchResults.isEmpty() ? new List<SObject>() : searchResults[0];
            List<Map<String, Object>> rows = new List<Map<String, Object>>();
            for (SObject art : articles) {
                Id rid = (Id) art.get('Id');
                rows.add(new Map<String, Object>{
                    'Id' => rid,
                    'KnowledgeArticleId' => art.get('KnowledgeArticleId'),
                    'Title' => art.get('Title'),
                    'Summary' => art.get('Summary'),
                    'ArticleNumber' => art.get('ArticleNumber'),
                    'UrlName' => art.get('UrlName'),
                    'recordUrl' => recordUrl(rid)
                });
            }
            return successJson(new Map<String, Object>{
                'searchTerm' => term, 'count' => rows.size(), 'articles' => rows
            });
        } catch (Exception ex) {
            return errorJson('Knowledge search failed: ' + ex.getMessage());
        }
    }

    public static String skillFetchKnowledgeArticle(Map<String, Object> p) {
        Schema.SObjectType kavType = Schema.getGlobalDescribe().get('KnowledgeArticleVersion');
        if (kavType == null || !kavType.getDescribe().isAccessible()) {
            return successJson(new Map<String, Object>{
                'status' => 'unavailable', 'message' => 'Knowledge is not enabled in this org.'
            });
        }
        String articleId = toText(firstNonNull(p, new List<String>{
            'Id', 'id', 'KnowledgeArticleId', 'article_id', 'knowledge_article_id', 'recordId', 'url_name', 'article_number'
        }));
        if (String.isBlank(articleId)) return errorJson('Missing required parameter: Id (article Id).');
        try {
            List<SObject> rows;
            Id parsed = parseSalesforceId(articleId);
            if (parsed != null) {
                rows = Database.query(
                    'SELECT Id, Title, Summary, ArticleNumber, UrlName, KnowledgeArticleId, VersionNumber, PublishStatus'
                    + ' FROM KnowledgeArticleVersion WHERE Id = :parsed WITH USER_MODE LIMIT 1'
                );
                if (rows.isEmpty()) {
                    rows = Database.query(
                        'SELECT Id, Title, Summary, ArticleNumber, UrlName, KnowledgeArticleId, VersionNumber, PublishStatus'
                        + ' FROM KnowledgeArticleVersion WHERE KnowledgeArticleId = :parsed AND PublishStatus = \'Online\''
                        + ' WITH USER_MODE ORDER BY VersionNumber DESC LIMIT 1'
                    );
                }
            } else {
                rows = Database.query(
                    'SELECT Id, Title, Summary, ArticleNumber, UrlName, KnowledgeArticleId, VersionNumber, PublishStatus'
                    + ' FROM KnowledgeArticleVersion WHERE (UrlName = :articleId OR ArticleNumber = :articleId)'
                    + ' AND PublishStatus = \'Online\' WITH USER_MODE ORDER BY VersionNumber DESC LIMIT 1'
                );
            }
            if (rows.isEmpty()) return errorJson('No knowledge article found for provided identifier.');
            SObject art = rows[0];
            return successJson(new Map<String, Object>{
                'Id' => art.get('Id'),
                'KnowledgeArticleId' => art.get('KnowledgeArticleId'),
                'Title' => art.get('Title'),
                'Summary' => art.get('Summary'),
                'ArticleNumber' => art.get('ArticleNumber'),
                'UrlName' => art.get('UrlName'),
                'VersionNumber' => art.get('VersionNumber'),
                'PublishStatus' => art.get('PublishStatus'),
                'recordUrl' => recordUrl((Id) art.get('Id'))
            });
        } catch (Exception ex) {
            return errorJson('Could not fetch knowledge article: ' + ex.getMessage());
        }
    }

    public static String skillAssignToQueue(Map<String, Object> p) {
        String rid = toText(firstNonNull(p, new List<String>{ 'record_id', 'recordId', 'Id' }));
        String queueId = toText(firstNonNull(p, new List<String>{ 'queue_id', 'owner_id', 'OwnerId' }));
        if (String.isBlank(rid)) return errorHtml('Could not assign to queue', 'Missing parameter: record_id');
        if (String.isBlank(queueId)) return errorHtml('Could not assign to queue', 'Missing parameter: queue_id');
        Id recId;
        Id ownerId;
        try {
            recId = Id.valueOf(rid.trim());
            ownerId = Id.valueOf(queueId.trim());
        } catch (Exception e) {
            return errorHtml('Could not assign to queue', 'Invalid record_id or queue_id.');
        }
        Schema.SObjectType sot = recId.getSObjectType();
        String objApi = sot.getDescribe().getName();
        if (objApi != 'Case' && objApi != 'Lead') {
            return errorHtml('Could not assign to queue', 'assign_to_queue supports Case and Lead only.');
        }
        if (!sot.getDescribe().isUpdateable()) {
            return errorHtml('Could not assign to queue', objApi + ' is not updateable.');
        }
        List<Group> queues = [
            SELECT Id, Name, Type FROM Group
            WHERE Id = :ownerId AND Type = 'Queue'
            WITH USER_MODE LIMIT 1
        ];
        if (queues.isEmpty()) {
            return errorHtml('Could not assign to queue', 'Provided queue_id is not a valid queue.');
        }
        String labelField = objApi == 'Case' ? 'CaseNumber' : 'Name';
        String soql = 'SELECT Id, OwnerId, ' + labelField + ' FROM ' + objApi + ' WHERE Id = :recId WITH USER_MODE LIMIT 1';
        List<SObject> rows = Database.query(soql);
        if (rows.isEmpty()) return errorHtml('Could not assign to queue', 'No record found for provided Id.');
        String recordLabel = String.valueOf(rows[0].get(labelField));
        return performGenericUpdate(objApi, recId, new Map<String, Object>{ 'OwnerId' => ownerId },
            'Assigned to Queue', 'View Record', recordLabel);
    }

    public static String skillFetchQueueCases(Map<String, Object> p) {
        String queueId = toText(firstNonNull(p, new List<String>{ 'queue_id', 'owner_id', 'OwnerId' }));
        if (String.isBlank(queueId)) return errorJson('Missing required parameter: queue_id');
        if (!Schema.sObjectType.Case.isAccessible()) return errorJson('Case is not accessible.');
        Id ownerId;
        try { ownerId = Id.valueOf(queueId.trim()); } catch (Exception e) {
            return errorJson('Invalid queue_id.');
        }
        Integer lim = 25;
        Object lRaw = p.get('limit');
        if (lRaw != null && String.isNotBlank(toText(lRaw))) {
            try { lim = Integer.valueOf(toText(lRaw)); } catch (Exception e) { lim = 25; }
        }
        lim = Math.max(1, Math.min(lim, 200));
        List<Case> cases = [
            SELECT Id, CaseNumber, Subject, Status, Priority, CreatedDate
            FROM Case
            WHERE OwnerId = :ownerId AND IsClosed = false
            WITH USER_MODE
            ORDER BY CreatedDate ASC
            LIMIT :lim
        ];
        List<Map<String, Object>> rows = new List<Map<String, Object>>();
        for (Case ca : cases) {
            rows.add(new Map<String, Object>{
                'Id' => ca.Id, 'CaseNumber' => ca.CaseNumber, 'Subject' => ca.Subject,
                'Status' => ca.Status, 'Priority' => ca.Priority,
                'CreatedDate' => String.valueOf(ca.CreatedDate),
                'recordUrl' => recordUrl(ca.Id), 'viewRecord' => viewRecordAnchor(ca.Id)
            });
        }
        return successJson(new Map<String, Object>{
            'queueId' => ownerId, 'count' => rows.size(), 'cases' => rows
        });
    }

    /**
     * @description Skill — fetch_record_approvals. Pending/completed approvals for a record.
     * @jira V2-8418
     */
    public static String skillFetchRecordApprovals(Map<String, Object> p) {
        String rid = toText(firstNonNull(p, new List<String>{ 'record_id', 'recordId', 'Id' }));
        if (String.isBlank(rid)) return errorJson('Missing required parameter: record_id');
        Id recId = parseSalesforceId(rid);
        if (recId == null) return errorJson('Invalid record_id.');
        Schema.SObjectType wiType = Schema.getGlobalDescribe().get('ProcessInstanceWorkitem');
        if (wiType == null || !wiType.getDescribe().isAccessible()) {
            return successJson(new Map<String, Object>{
                'status' => 'unavailable', 'message' => 'Approval process objects are not accessible.', 'approvals' => new List<Object>()
            });
        }
        try {
            String soql = 'SELECT Id, ActorId, Actor.Name, CreatedDate, OriginalActorId,'
                        + ' ProcessInstanceId, ProcessInstance.Status, ProcessInstance.TargetObjectId,'
                        + ' ProcessInstance.SubmittedById, ProcessInstance.SubmittedBy.Name, ProcessInstance.CreatedDate'
                        + ' FROM ProcessInstanceWorkitem'
                        + ' WHERE ProcessInstance.TargetObjectId = :recId'
                        + ' WITH USER_MODE ORDER BY CreatedDate DESC LIMIT 100';
            List<SObject> rows = Database.query(soql);
            List<Map<String, Object>> approvals = new List<Map<String, Object>>();
            for (SObject wi : rows) {
                SObject pi = wi.getSObject('ProcessInstance');
                SObject actor = wi.getSObject('Actor');
                SObject submitter = pi != null ? pi.getSObject('SubmittedBy') : null;
                approvals.add(new Map<String, Object>{
                    'workitemId' => wi.get('Id'),
                    'actorId' => wi.get('ActorId'),
                    'actorName' => actor != null ? actor.get('Name') : null,
                    'createdDate' => String.valueOf(wi.get('CreatedDate')),
                    'processStatus' => pi != null ? pi.get('Status') : null,
                    'submittedBy' => submitter != null ? submitter.get('Name') : null,
                    'submittedDate' => pi != null ? String.valueOf(pi.get('CreatedDate')) : null
                });
            }
            return successJson(new Map<String, Object>{
                'recordId' => rid, 'count' => approvals.size(), 'approvals' => approvals
            });
        } catch (Exception ex) {
            return errorJson('Could not fetch approvals: ' + ex.getMessage());
        }
    }

    /**
     * @description Skill — fetch_renewal_opportunities. Configurable SOQL filter for renewal opps.
     * @jira V2-8418
     */
    public static String skillFetchRenewalOpportunities(Map<String, Object> p) {
        if (!Schema.sObjectType.Opportunity.isAccessible()) return errorJson('Opportunity is not accessible.');
        String customFilter = toText(p.get('soql_filter'));
        Integer lim = 50;
        Object lRaw = p.get('limit');
        if (lRaw != null && String.isNotBlank(toText(lRaw))) {
            try { lim = Integer.valueOf(toText(lRaw)); } catch (Exception e) { lim = 50; }
        }
        lim = Math.max(1, Math.min(lim, 200));
        String ownerFilter = toText(p.get('owner_id'));
        Id ownerId = parseSalesforceId(ownerFilter);
        if (ownerId == null && String.isBlank(ownerFilter)) ownerId = UserInfo.getUserId();
        List<Opportunity> rows;
        if (String.isNotBlank(customFilter)) {
            String soql = 'SELECT Id, Name, StageName, CloseDate, Amount, Type, AccountId, Account.Name, OwnerId, Owner.Name'
                        + ' FROM Opportunity WHERE (' + customFilter + ')';
            if (ownerId != null) soql += ' AND OwnerId = :ownerId';
            soql += ' WITH USER_MODE ORDER BY CloseDate ASC NULLS LAST LIMIT :lim';
            rows = Database.query(soql);
        } else {
            String renewalType = toText(p.get('renewal_type'));
            if (String.isBlank(renewalType)) renewalType = 'Renewal';
            String namePattern = '%renewal%';
            rows = [
                SELECT Id, Name, StageName, CloseDate, Amount, Type, AccountId, Account.Name, OwnerId, Owner.Name
                FROM Opportunity
                WHERE (Type = :renewalType OR Name LIKE :namePattern)
                  AND OwnerId = :ownerId AND IsClosed = false
                WITH USER_MODE
                ORDER BY CloseDate ASC NULLS LAST
                LIMIT :lim
            ];
        }
        List<Map<String, Object>> records = new List<Map<String, Object>>();
        for (Opportunity o : rows) {
            records.add(new Map<String, Object>{
                'Id' => o.Id, 'Name' => o.Name, 'StageName' => o.StageName,
                'CloseDate' => String.valueOf(o.CloseDate), 'Amount' => o.Amount, 'Type' => o.Type,
                'Account' => o.Account != null ? o.Account.Name : null,
                'Owner' => o.Owner != null ? o.Owner.Name : null,
                'recordUrl' => recordUrl(o.Id)
            });
        }
        return successJson(new Map<String, Object>{
            'count' => records.size(), 'ownerId' => ownerId, 'records' => records
        });
    }

    /**
     * @description Skill — fetch_upcoming_renewals. Open renewal opportunities closing within N days.
     * @jira V2-8418
     */
    public static String skillFetchUpcomingRenewals(Map<String, Object> p) {
        if (!Schema.sObjectType.Opportunity.isAccessible()) return errorJson('Opportunity is not accessible.');
        Integer daysAhead = 90;
        Object dRaw = firstNonNull(p, new List<String>{ 'days_ahead', 'days' });
        if (dRaw != null && String.isNotBlank(toText(dRaw))) {
            try { daysAhead = Integer.valueOf(toText(dRaw)); } catch (Exception e) { daysAhead = 90; }
        }
        daysAhead = Math.max(1, Math.min(daysAhead, 365));
        Date today = Date.today();
        Date endDate = today.addDays(daysAhead);
        Integer lim = 50;
        Object lRaw = p.get('limit');
        if (lRaw != null && String.isNotBlank(toText(lRaw))) {
            try { lim = Integer.valueOf(toText(lRaw)); } catch (Exception e) { lim = 50; }
        }
        lim = Math.max(1, Math.min(lim, 200));
        String renewalType = toText(p.get('renewal_type'));
        if (String.isBlank(renewalType)) renewalType = 'Renewal';
        String namePattern = '%renewal%';
        Id accountId = parseSalesforceId(toText(firstNonNull(p, new List<String>{ 'account_id', 'AccountId' })));
        Id ownerId = parseSalesforceId(toText(firstNonNull(p, new List<String>{ 'owner_id', 'OwnerId' })));
        List<Opportunity> rows;
        if (accountId != null && ownerId != null) {
            rows = [
                SELECT Id, Name, StageName, CloseDate, Amount, Type, AccountId, Account.Name, OwnerId, Owner.Name
                FROM Opportunity
                WHERE IsClosed = false AND CloseDate >= :today AND CloseDate <= :endDate
                  AND (Type = :renewalType OR Name LIKE :namePattern)
                  AND AccountId = :accountId AND OwnerId = :ownerId
                WITH USER_MODE
                ORDER BY CloseDate ASC NULLS LAST
                LIMIT :lim
            ];
        } else if (accountId != null) {
            rows = [
                SELECT Id, Name, StageName, CloseDate, Amount, Type, AccountId, Account.Name, OwnerId, Owner.Name
                FROM Opportunity
                WHERE IsClosed = false AND CloseDate >= :today AND CloseDate <= :endDate
                  AND (Type = :renewalType OR Name LIKE :namePattern)
                  AND AccountId = :accountId
                WITH USER_MODE
                ORDER BY CloseDate ASC NULLS LAST
                LIMIT :lim
            ];
        } else if (ownerId != null) {
            rows = [
                SELECT Id, Name, StageName, CloseDate, Amount, Type, AccountId, Account.Name, OwnerId, Owner.Name
                FROM Opportunity
                WHERE IsClosed = false AND CloseDate >= :today AND CloseDate <= :endDate
                  AND (Type = :renewalType OR Name LIKE :namePattern)
                  AND OwnerId = :ownerId
                WITH USER_MODE
                ORDER BY CloseDate ASC NULLS LAST
                LIMIT :lim
            ];
        } else {
            rows = [
                SELECT Id, Name, StageName, CloseDate, Amount, Type, AccountId, Account.Name, OwnerId, Owner.Name
                FROM Opportunity
                WHERE IsClosed = false AND CloseDate >= :today AND CloseDate <= :endDate
                  AND (Type = :renewalType OR Name LIKE :namePattern)
                WITH USER_MODE
                ORDER BY CloseDate ASC NULLS LAST
                LIMIT :lim
            ];
        }
        List<Map<String, Object>> records = new List<Map<String, Object>>();
        for (Opportunity o : rows) {
            records.add(new Map<String, Object>{
                'Id' => o.Id, 'Name' => o.Name, 'StageName' => o.StageName,
                'CloseDate' => String.valueOf(o.CloseDate), 'Amount' => o.Amount, 'Type' => o.Type,
                'Account' => o.Account != null ? o.Account.Name : null,
                'AccountId' => o.AccountId,
                'Owner' => o.Owner != null ? o.Owner.Name : null,
                'daysUntilClose' => o.CloseDate != null ? o.CloseDate.daysBetween(today) * -1 : null,
                'recordUrl' => recordUrl(o.Id)
            });
        }
        return successJson(new Map<String, Object>{
            'daysAhead' => daysAhead,
            'fromDate' => String.valueOf(today),
            'toDate' => String.valueOf(endDate),
            'count' => records.size(),
            'records' => records
        });
    }

    /**
     * @description Skill — fetch_account_plan. Account plan + objectives when object exists in org.
     * @jira V2-8418
     */
    public static String skillFetchAccountPlan(Map<String, Object> p) {
        String planApi = accountPlanObjectApi();
        if (planApi == null) {
            return errorJson('Account Plan is not available in this org.');
        }
        String aid = toText(firstNonNull(p, new List<String>{ 'Id', 'id', 'AccountId', 'account_id', 'recordId' }));
        if (String.isBlank(aid)) return errorJson('Missing required parameter: Id (Account Id).');
        Id accountId = parseSalesforceId(aid);
        if (accountId == null) return errorJson('Invalid Id (Account).');
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(planApi);
        if (sot == null || !sot.getDescribe().isAccessible()) {
            return errorJson('Account Plan is not accessible.');
        }
        Map<String, Schema.SObjectField> fmap = sot.getDescribe().fields.getMap();
        List<String> planFields = new List<String>{ 'Id', 'Name' };
        for (String f : new List<String>{
            'AccountId', 'Status', 'StartDate', 'EndDate', 'Description', 'Notes',
            'OwnerId', 'Owner.Name', 'CreatedDate', 'LastModifiedDate'
        }) {
            if (fmap.containsKey(f)) planFields.add(f);
        }
        String accountField = accountPlanAccountField(fmap);
        if (String.isBlank(accountField)) {
            return errorJson('Account Plan object has no Account lookup field.');
        }
        String soql = 'SELECT ' + String.join(planFields, ', ')
                    + ' FROM ' + planApi + ' WHERE ' + accountField + ' = :accountId'
                    + ' WITH USER_MODE ORDER BY LastModifiedDate DESC NULLS LAST LIMIT 10';
        List<SObject> plans = Database.query(soql);
        List<Map<String, Object>> planRows = new List<Map<String, Object>>();
        Set<Id> planIds = new Set<Id>();
        for (SObject plan : plans) {
            Id pid = (Id) plan.get('Id');
            planIds.add(pid);
            Map<String, Object> row = new Map<String, Object>{
                'Id' => pid, 'Name' => plan.get('Name'), 'recordUrl' => recordUrl(pid)
            };
            for (String f : planFields) {
                if (f == 'Id' || f == 'Owner.Name') continue;
                if (f == 'OwnerId' && fmap.containsKey('OwnerId')) {
                    SObject owner = plan.getSObject('Owner');
                    row.put('Owner', owner != null ? owner.get('Name') : null);
                } else {
                    row.put(f, plan.get(f));
                }
            }
            planRows.add(row);
        }
        List<Map<String, Object>> objectives = fetchAccountPlanObjectives(planIds);
        return successJson(new Map<String, Object>{
            'accountId' => accountId,
            'object' => planApi,
            'planCount' => planRows.size(),
            'plans' => planRows,
            'objectives' => objectives
        });
    }

    private static String accountPlanObjectApi() {
        for (String candidate : new List<String>{ 'AccountPlan', 'Account_Plan__c', 'AccountPlan__c' }) {
            Schema.SObjectType sot = Schema.getGlobalDescribe().get(candidate);
            if (sot != null && sot.getDescribe().isAccessible()) return candidate;
        }
        return null;
    }

    private static String accountPlanAccountField(Map<String, Schema.SObjectField> fmap) {
        for (String f : new List<String>{ 'AccountId', 'Account__c', 'FinServ__Account__c' }) {
            if (fmap.containsKey(f)) return f;
        }
        return null;
    }

    private static List<Map<String, Object>> fetchAccountPlanObjectives(Set<Id> planIds) {
        List<Map<String, Object>> out = new List<Map<String, Object>>();
        if (planIds.isEmpty()) return out;
        String objApi = null;
        for (String candidate : new List<String>{ 'AccountPlanObjective', 'AccountPlanObjective__c', 'Account_Plan_Objective__c' }) {
            Schema.SObjectType sot = Schema.getGlobalDescribe().get(candidate);
            if (sot != null && sot.getDescribe().isAccessible()) {
                objApi = candidate;
                break;
            }
        }
        if (objApi == null) return out;
        Map<String, Schema.SObjectField> fmap = Schema.getGlobalDescribe().get(objApi).getDescribe().fields.getMap();
        String planField = null;
        for (String f : new List<String>{ 'AccountPlanId', 'AccountPlan__c', 'Account_Plan__c' }) {
            if (fmap.containsKey(f)) { planField = f; break; }
        }
        if (planField == null) return out;
        List<String> fields = new List<String>{ 'Id', 'Name' };
        for (String f : new List<String>{ 'Status', 'Description', 'TargetValue', 'StartDate', 'EndDate', 'Priority' }) {
            if (fmap.containsKey(f)) fields.add(f);
        }
        String soql = 'SELECT ' + String.join(fields, ', ') + ' FROM ' + objApi
                    + ' WHERE ' + planField + ' IN :planIds WITH USER_MODE ORDER BY Name ASC LIMIT 100';
        for (SObject obj : Database.query(soql)) {
            Map<String, Object> row = new Map<String, Object>{ 'Id' => obj.get('Id'), 'Name' => obj.get('Name') };
            for (String f : fields) {
                if (f != 'Id') row.put(f, obj.get(f));
            }
            out.add(row);
        }
        return out;
    }

    /**
     * @description Skill — fetch_contact_engagement_history. Recent tasks, events, and emails for a contact.
     * @jira V2-8418
     */
    public static String skillFetchContactEngagementHistory(Map<String, Object> p) {
        String cid = toText(firstNonNull(p, new List<String>{ 'Id', 'id', 'ContactId', 'contact_id', 'recordId' }));
        if (String.isBlank(cid)) return errorJson('Missing required parameter: Id (Contact Id).');
        Id contactId = parseSalesforceId(cid);
        if (contactId == null) return errorJson('Invalid Id (Contact).');
        if (!Schema.sObjectType.Contact.isAccessible()) return errorJson('Contact is not accessible.');
        List<Contact> contacts = [SELECT Id, Name FROM Contact WHERE Id = :contactId WITH USER_MODE LIMIT 1];
        if (contacts.isEmpty()) return errorJson('No contact found for provided Id.');
        Integer daysBack = 90;
        Object dRaw = firstNonNull(p, new List<String>{ 'daysBack', 'days_back', 'days' });
        if (dRaw != null && String.isNotBlank(toText(dRaw))) {
            try { daysBack = Integer.valueOf(toText(dRaw)); } catch (Exception e) { daysBack = 90; }
        }
        daysBack = Math.max(1, Math.min(daysBack, 365));
        Integer lim = 50;
        Object lRaw = p.get('limit');
        if (lRaw != null && String.isNotBlank(toText(lRaw))) {
            try { lim = Integer.valueOf(toText(lRaw)); } catch (Exception e) { lim = 50; }
        }
        lim = Math.max(1, Math.min(lim, 200));
        Datetime sinceDt = Datetime.now().addDays(-daysBack);
        Date sinceDate = Date.today().addDays(-daysBack);
        List<Map<String, Object>> items = new List<Map<String, Object>>();
        // Use literal LIMIT (avoids rare Apex "tmpVarN" binder bugs with multi-bind + LIMIT :var)
        Integer queryLimit = lim;
        if (Schema.sObjectType.Task.isAccessible()) {
            String taskSoql =
                'SELECT Id, Subject, Status, ActivityDate, Type, Description, CreatedDate'
                + ' FROM Task WHERE WhoId = :contactId'
                + ' AND (ActivityDate >= :sinceDate OR CreatedDate >= :sinceDt)'
                + ' WITH USER_MODE'
                + ' ORDER BY CreatedDate DESC'
                + ' LIMIT ' + String.valueOf(queryLimit);
            try {
                for (SObject t : Database.query(taskSoql)) {
                    Date ad = (Date) t.get('ActivityDate');
                    Datetime cd = (Datetime) t.get('CreatedDate');
                    items.add(new Map<String, Object>{
                        'kind' => 'Task',
                        'Id' => t.get('Id'),
                        'Subject' => t.get('Subject'),
                        'Status' => t.get('Status'),
                        'Type' => t.get('Type'),
                        'ActivityDate' => String.valueOf(ad),
                        'Description' => t.get('Description'),
                        'sortDate' => ad != null ? Datetime.newInstance(ad, Time.newInstance(0, 0, 0, 0)) : cd,
                        'recordUrl' => recordUrl((Id) t.get('Id'))
                    });
                }
            } catch (Exception taskEx) {
                System.debug(LoggingLevel.ERROR, 'engagement Task query: ' + taskEx.getMessage());
            }
        }
        if (Schema.sObjectType.Event.isAccessible()) {
            String eventSoql =
                'SELECT Id, Subject, StartDateTime, EndDateTime, Type, Description, Location, CreatedDate'
                + ' FROM Event WHERE WhoId = :contactId AND StartDateTime >= :sinceDt'
                + ' WITH USER_MODE ORDER BY StartDateTime DESC'
                + ' LIMIT ' + String.valueOf(queryLimit);
            try {
                for (SObject ev : Database.query(eventSoql)) {
                    items.add(new Map<String, Object>{
                        'kind' => 'Event',
                        'Id' => ev.get('Id'),
                        'Subject' => ev.get('Subject'),
                        'StartDateTime' => String.valueOf(ev.get('StartDateTime')),
                        'EndDateTime' => String.valueOf(ev.get('EndDateTime')),
                        'Type' => ev.get('Type'),
                        'Location' => ev.get('Location'),
                        'Description' => ev.get('Description'),
                        'sortDate' => (Datetime) ev.get('StartDateTime'),
                        'recordUrl' => recordUrl((Id) ev.get('Id'))
                    });
                }
            } catch (Exception eventEx) {
                System.debug(LoggingLevel.ERROR, 'engagement Event query: ' + eventEx.getMessage());
            }
        }
        Schema.SObjectType emailType = Schema.getGlobalDescribe().get('EmailMessage');
        if (emailType != null && emailType.getDescribe().isAccessible()) {
            try {
                String emailSoql =
                    'SELECT Id, Subject, MessageDate, FromAddress, ToAddress, Status'
                    + ' FROM EmailMessage WHERE RelatedToId = :contactId AND MessageDate >= :sinceDt'
                    + ' WITH USER_MODE ORDER BY MessageDate DESC'
                    + ' LIMIT ' + String.valueOf(queryLimit);
                for (SObject em : Database.query(emailSoql)) {
                    items.add(new Map<String, Object>{
                        'kind' => 'Email',
                        'Id' => em.get('Id'),
                        'Subject' => em.get('Subject'),
                        'MessageDate' => String.valueOf(em.get('MessageDate')),
                        'FromAddress' => em.get('FromAddress'),
                        'ToAddress' => em.get('ToAddress'),
                        'Status' => em.get('Status'),
                        'sortDate' => (Datetime) em.get('MessageDate'),
                        'recordUrl' => recordUrl((Id) em.get('Id'))
                    });
                }
            } catch (Exception emEx) {
                System.debug(LoggingLevel.FINE, 'EmailMessage query skipped: ' + emEx.getMessage());
            }
        }
        // Manual sort by sortDate desc (no System.Comparator / tmpVar issues)
        for (Integer i = 0; i < items.size(); i++) {
            for (Integer j = i + 1; j < items.size(); j++) {
                Datetime di = (Datetime) items[i].get('sortDate');
                Datetime dj = (Datetime) items[j].get('sortDate');
                Boolean swap = false;
                if (di == null && dj != null) swap = true;
                else if (di != null && dj != null && dj > di) swap = true;
                if (swap) {
                    Map<String, Object> tmp = items[i];
                    items[i] = items[j];
                    items[j] = tmp;
                }
            }
        }
        List<Map<String, Object>> displayed = new List<Map<String, Object>>();
        Integer total = items.size();
        for (Integer i = 0; i < Math.min(lim, items.size()); i++) {
            Map<String, Object> row = new Map<String, Object>(items[i]);
            row.remove('sortDate');
            displayed.add(row);
        }
        return successJson(new Map<String, Object>{
            'contactId' => contactId,
            'contactName' => contacts[0].Name,
            'daysBack' => daysBack,
            'totalFound' => total,
            'displayed' => displayed.size(),
            'engagement' => displayed
        });
    }
}
