/**
* @description       : Data source implementation for AI Workspace Staging Policy Check.
*                      Extracts staging record data, decrypts sensitive fields, queries related
*                      Contacts/Leads with their details, and constructs a comprehensive data map
*                      for AI processing to determine if the staging record should be processed.
* @author            : Piyush Chourasia
* @group             : Plumcloud Labs
* @last modified on  : 03-12-2026
* @last modified by  : Piyush Chourasia
* @Jira              : V2-7889
**/
global class StagingProcessingPolicyCheck implements ccai_qa.AIDataSourceInterface {

    /**
     * Main method to fetch and process staging record data with related entities.
     *
     * @param dataSource The AI Data Source configuration record
     * @param extractedData JSON string containing the staging record data
     * @return JSON string with comprehensive staging data including decrypted fields and related records
     */
    global String getExternalData(AI_Data_Source__c dataSource, String extractedData) {
        System.debug('StagingProcessingPolicyCheck - extractedData: ' + extractedData);
        System.debug('StagingProcessingPolicyCheck - dataSource: ' + dataSource);

        try {
            Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(extractedData);

            String stagingRecordId = (String) dataMap.get('Id');
            if (String.isBlank(stagingRecordId)) {
                throw new StagingPolicyException('Staging Record ID is missing in extracted data');
            }

            AI_Workspace_Staging__c stagingRecord = queryStagingRecord(stagingRecordId);

            Id userId = getUserIdFromWorkspaceUser(stagingRecord.AI_Workspace_User__c);

            Map<String, Object> processedData = buildProcessedDataMap(stagingRecord, userId);

            return JSON.serialize(processedData);

        } catch (Exception e) {
            System.debug('StagingProcessingPolicyCheck - Error: ' + e.getMessage());
            throw new StagingPolicyException('Error processing staging record: ' + e.getMessage());
        }
    }

    /**
     * Queries the staging record with all necessary fields.
     *
     * @param stagingRecordId The ID of the staging record
     * @return AI_Workspace_Staging__c record with all fields
     */
    private AI_Workspace_Staging__c queryStagingRecord(String stagingRecordId) {
        List<AI_Workspace_Staging__c> stagingRecords = [
            SELECT Id, Subject__c, Html_Body__c, Text_Body__c, To_Address__c,
                   Cc_Address__c, From_Address__c, Attendees__c, Organizer__c,
                   WhoId__c, AI_Workspace_User__c, Provider__c, Status__c,
                   Message_Date__c, Is_Incoming__c, Importance__c, Has_Attachments__c,
                   From_Name__c, RecordType.DeveloperName
            FROM AI_Workspace_Staging__c
            WHERE Id = :stagingRecordId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        if (stagingRecords.isEmpty()) {
            throw new StagingPolicyException('Staging record not found: ' + stagingRecordId);
        }

        return stagingRecords[0];
    }

    /**
     * Retrieves the User ID from AI_Workspace_User__c record.
     *
     * @param workspaceUserId The ID of the AI_Workspace_User__c record
     * @return User ID from the workspace user record
     */
    private Id getUserIdFromWorkspaceUser(Id workspaceUserId) {
        if (workspaceUserId == null) {
            throw new StagingPolicyException('AI_Workspace_User__c is missing on staging record');
        }

        List<AI_Workspace_User__c> workspaceUsers = [
            SELECT Id, User__c, Provider__c, Service_User_Email__c
            FROM AI_Workspace_User__c
            WHERE Id = :workspaceUserId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        if (workspaceUsers.isEmpty()) {
            throw new StagingPolicyException('AI_Workspace_User__c record not found: ' + workspaceUserId);
        }

        if (workspaceUsers[0].User__c == null) {
            throw new StagingPolicyException('User__c is missing on AI_Workspace_User__c record');
        }

        return workspaceUsers[0].User__c;
    }

    /**
     * Builds the comprehensive processed data map with all staging and related record details.
     *
     * @param stagingRecord The staging record
     * @param userId The Salesforce User ID for decryption
     * @return Map containing all processed data
     */
    private Map<String, Object> buildProcessedDataMap(AI_Workspace_Staging__c stagingRecord, Id userId) {
        Map<String, Object> processedData = new Map<String, Object>();

        processedData.put('stagingRecordId', stagingRecord.Id);
        processedData.put('recordType', stagingRecord.RecordType.DeveloperName);
        processedData.put('provider', stagingRecord.Provider__c);
        processedData.put('status', stagingRecord.Status__c);
        processedData.put('messageDate', stagingRecord.Message_Date__c);
        processedData.put('isIncoming', stagingRecord.Is_Incoming__c);
        processedData.put('importance', stagingRecord.Importance__c);
        processedData.put('hasAttachments', stagingRecord.Has_Attachments__c);
        processedData.put('fromName', stagingRecord.From_Name__c);

        processedData.put('emailSubject', decryptField(stagingRecord.Subject__c, userId));
        processedData.put('emailHtmlBody', decryptField(stagingRecord.Html_Body__c, userId));
        processedData.put('emailTextBody', decryptField(stagingRecord.Text_Body__c, userId));

        processedData.put('toAddresses', stagingRecord.To_Address__c);
        processedData.put('ccAddresses', stagingRecord.Cc_Address__c);
        processedData.put('fromAddress', stagingRecord.From_Address__c);
        processedData.put('attendeeList', stagingRecord.Attendees__c);
        processedData.put('organizerEmails', stagingRecord.Organizer__c);

        // Always attempt to gather Contact/Lead details:
        // 1) Prefer WhoId__c when present
        // 2) If WhoId__c is missing/insufficient, fall back to email-address matching from headers
        Set<Id> contactIds = new Set<Id>();
        Set<Id> leadIds = new Set<Id>();
        parseWhoIds(stagingRecord.WhoId__c, contactIds, leadIds);

        if (contactIds.isEmpty() && leadIds.isEmpty()) {
            Set<String> emails = extractEmailsFromHeaders(
                stagingRecord.From_Address__c,
                stagingRecord.To_Address__c,
                stagingRecord.Cc_Address__c,
                stagingRecord.Attendees__c,
                stagingRecord.Organizer__c
            );
            if (!emails.isEmpty()) {
                contactIds.addAll(getContactIdsByEmail(emails));
                leadIds.addAll(getLeadIdsByEmail(emails));
            }
        }

        processedData.put(
            'contacts',
            contactIds.isEmpty() ? new List<Map<String, Object>>() : queryContacts(contactIds)
        );
        processedData.put(
            'leads',
            leadIds.isEmpty() ? new List<Map<String, Object>>() : queryLeads(leadIds)
        );

        // Always attempt Opportunity candidates based on Account(s) related to the Contacts
        Set<Id> accountIds = contactIds.isEmpty() ? new Set<Id>() : getAccountIdsFromContacts(contactIds);
        processedData.put(
            'opportunities',
            accountIds.isEmpty() ? new List<Map<String, Object>>() : queryOpportunities(accountIds)
        );

        return processedData;
    }

    /**
     * Decrypts a field using AIGlobalUtility.decryptData method.
     *
     * @param encryptedValue The encrypted value
     * @param userId The User ID for decryption
     * @return Decrypted value or null if input is blank
     */
    private String decryptField(String encryptedValue, Id userId) {
        if (String.isBlank(encryptedValue)) {
            return null;
        }

        try {
            return AIGlobalUtility.decryptData(encryptedValue, userId);
        } catch (Exception e) {
            System.debug('StagingProcessingPolicyCheck - Decryption failed: ' + e.getMessage());
            return null;
        }
    }

    /**
     * Parses comma-separated WhoId__c field into Contact and Lead ID sets.
     *
     * @param whoIdString Comma-separated string of Contact and Lead IDs
     * @param contactIds Set to populate with Contact IDs
     * @param leadIds Set to populate with Lead IDs
     */
    private void parseWhoIds(String whoIdString, Set<Id> contactIds, Set<Id> leadIds) {
        if (String.isBlank(whoIdString)) {
            return;
        }

        List<String> idStrings = whoIdString.split(',');
        for (String idString : idStrings) {
            String trimmedId = idString.trim();
            if (String.isBlank(trimmedId)) continue;
            try {
                Id recordId = (Id) trimmedId;
                String objectType = recordId.getSObjectType().getDescribe().getName();
                if (objectType == 'Contact') {
                    contactIds.add(recordId);
                } else if (objectType == 'Lead') {
                    leadIds.add(recordId);
                }
            } catch (Exception e) {
                // Ignore invalid IDs
            }
        }
    }

    /**
     * Queries Contacts with their primary Account and ALL related Accounts (AccountContactRelation).
     *
     * Output per contact includes:
     * - account: primary account (Contact.Account)
     * - relatedAccounts: list of related accounts from AccountContactRelation (with roles)
     *
     * @param contactIds Set of Contact IDs to query
     * @return List of maps containing Contact and Account data
     */
    private List<Map<String, Object>> queryContacts(Set<Id> contactIds) {
        List<Map<String, Object>> contactDataList = new List<Map<String, Object>>();

        List<Contact> contacts = [
            SELECT Id, FirstName, LastName, Email, Phone, Title, Department,
                   MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry,
                   Account.Id, Account.Name, Account.Type, Account.Industry, Account.Website,
                   Account.Phone, Account.BillingStreet, Account.BillingCity, Account.BillingState,
                   Account.BillingPostalCode, Account.BillingCountry, Account.NumberOfEmployees,
                   Account.AnnualRevenue, Account.Description
            FROM Contact
            WHERE Id IN :contactIds
            WITH SECURITY_ENFORCED
        ];

        // All related Accounts for these Contacts
        List<AccountContactRelation> acrs = [
            SELECT ContactId, AccountId, Roles,
                   Account.Id, Account.Name, Account.Type, Account.Industry, Account.Website,
                   Account.Phone, Account.BillingStreet, Account.BillingCity, Account.BillingState,
                   Account.BillingPostalCode, Account.BillingCountry, Account.NumberOfEmployees,
                   Account.AnnualRevenue, Account.Description
            FROM AccountContactRelation
            WHERE ContactId IN :contactIds
            WITH SECURITY_ENFORCED
        ];

        Map<Id, List<AccountContactRelation>> acrsByContactId = new Map<Id, List<AccountContactRelation>>();
        for (AccountContactRelation acr : acrs) {
            if (!acrsByContactId.containsKey(acr.ContactId)) {
                acrsByContactId.put(acr.ContactId, new List<AccountContactRelation>());
            }
            acrsByContactId.get(acr.ContactId).add(acr);
        }

        for (Contact con : contacts) {
            Map<String, Object> contactData = new Map<String, Object>();
            contactData.put('id', con.Id);
            contactData.put('firstName', con.FirstName);
            contactData.put('lastName', con.LastName);
            contactData.put('email', con.Email);
            contactData.put('phone', con.Phone);
            contactData.put('title', con.Title);
            contactData.put('department', con.Department);
            contactData.put('mailingStreet', con.MailingStreet);
            contactData.put('mailingCity', con.MailingCity);
            contactData.put('mailingState', con.MailingState);
            contactData.put('mailingPostalCode', con.MailingPostalCode);
            contactData.put('mailingCountry', con.MailingCountry);

            // Primary Account (Contact.Account)
            if (con.Account != null) {
                Map<String, Object> accountData = new Map<String, Object>();
                accountData.put('id', con.Account.Id);
                accountData.put('name', con.Account.Name);
                accountData.put('type', con.Account.Type);
                accountData.put('industry', con.Account.Industry);
                accountData.put('website', con.Account.Website);
                accountData.put('phone', con.Account.Phone);
                accountData.put('billingStreet', con.Account.BillingStreet);
                accountData.put('billingCity', con.Account.BillingCity);
                accountData.put('billingState', con.Account.BillingState);
                accountData.put('billingPostalCode', con.Account.BillingPostalCode);
                accountData.put('billingCountry', con.Account.BillingCountry);
                accountData.put('numberOfEmployees', con.Account.NumberOfEmployees);
                accountData.put('annualRevenue', con.Account.AnnualRevenue);
                accountData.put('description', con.Account.Description);
                contactData.put('account', accountData);
            }

            // Related Accounts (AccountContactRelation)
            List<Map<String, Object>> relatedAccounts = new List<Map<String, Object>>();
            if (acrsByContactId.containsKey(con.Id)) {
                for (AccountContactRelation acr : acrsByContactId.get(con.Id)) {
                    if (acr.Account == null) continue;

                    Map<String, Object> rel = new Map<String, Object>();
                    rel.put('accountId', acr.AccountId);
                    rel.put('roles', acr.Roles);

                    Map<String, Object> acc = new Map<String, Object>();
                    acc.put('id', acr.Account.Id);
                    acc.put('name', acr.Account.Name);
                    acc.put('type', acr.Account.Type);
                    acc.put('industry', acr.Account.Industry);
                    acc.put('website', acr.Account.Website);
                    acc.put('phone', acr.Account.Phone);
                    acc.put('billingStreet', acr.Account.BillingStreet);
                    acc.put('billingCity', acr.Account.BillingCity);
                    acc.put('billingState', acr.Account.BillingState);
                    acc.put('billingPostalCode', acr.Account.BillingPostalCode);
                    acc.put('billingCountry', acr.Account.BillingCountry);
                    acc.put('numberOfEmployees', acr.Account.NumberOfEmployees);
                    acc.put('annualRevenue', acr.Account.AnnualRevenue);
                    acc.put('description', acr.Account.Description);

                    rel.put('account', acc);
                    relatedAccounts.add(rel);
                }
            }
            contactData.put('relatedAccounts', relatedAccounts);

            contactDataList.add(contactData);
        }

        return contactDataList;
    }

    /**
     * Queries Leads with their details.
     *
     * @param leadIds Set of Lead IDs to query
     * @return List of maps containing Lead data
     */
    private List<Map<String, Object>> queryLeads(Set<Id> leadIds) {
        List<Map<String, Object>> leadDataList = new List<Map<String, Object>>();

        List<Lead> leads = [
            SELECT Id, FirstName, LastName, Email, Phone, Company, Title, Industry,
                   Status, Rating, LeadSource, Street, City, State, PostalCode, Country,
                   Website, NumberOfEmployees, AnnualRevenue, Description
            FROM Lead
            WHERE Id IN :leadIds
            WITH SECURITY_ENFORCED
        ];

        for (Lead ld : leads) {
            Map<String, Object> leadData = new Map<String, Object>();
            leadData.put('id', ld.Id);
            leadData.put('firstName', ld.FirstName);
            leadData.put('lastName', ld.LastName);
            leadData.put('email', ld.Email);
            leadData.put('phone', ld.Phone);
            leadData.put('company', ld.Company);
            leadData.put('title', ld.Title);
            leadData.put('industry', ld.Industry);
            leadData.put('status', ld.Status);
            leadData.put('rating', ld.Rating);
            leadData.put('leadSource', ld.LeadSource);
            leadData.put('street', ld.Street);
            leadData.put('city', ld.City);
            leadData.put('state', ld.State);
            leadData.put('postalCode', ld.PostalCode);
            leadData.put('country', ld.Country);
            leadData.put('website', ld.Website);
            leadData.put('numberOfEmployees', ld.NumberOfEmployees);
            leadData.put('annualRevenue', ld.AnnualRevenue);
            leadData.put('description', ld.Description);

            leadDataList.add(leadData);
        }

        return leadDataList;
    }

    /**
     * Extracts email addresses from header-like fields.
     * Accepts raw strings that may contain comma/semicolon-separated addresses and/or display names.
     */
    private Set<String> extractEmailsFromHeaders(
        String fromAddress,
        String toAddresses,
        String ccAddresses,
        String attendees,
        String organizer
    ) {
        Set<String> emails = new Set<String>();
        Set<String> parts = new Set<String>();

        for (String s : new List<String>{ fromAddress, toAddresses, ccAddresses, attendees, organizer }) {
            if (String.isBlank(s)) continue;
            for (String p : s.replace(';', ',').split(',')) {
                if (String.isNotBlank(p)) parts.add(p.trim());
            }
        }

        // Best-effort extraction: handle "Name <email@x.com>" and plain "email@x.com"
        for (String p : parts) {
            if (String.isBlank(p)) continue;
            String candidate = p;
            Integer lt = candidate.indexOf('<');
            Integer gt = candidate.indexOf('>');
            if (lt >= 0 && gt > lt) {
                candidate = candidate.substring(lt + 1, gt).trim();
            }
            candidate = candidate.toLowerCase();
            if (candidate.contains('@') && candidate.contains('.')) {
                emails.add(candidate);
            }
        }
        return emails;
    }

    private Set<Id> getContactIdsByEmail(Set<String> emails) {
        Set<Id> ids = new Set<Id>();
        if (emails == null || emails.isEmpty()) return ids;
        for (Contact c : [
            SELECT Id
            FROM Contact
            WHERE Email IN :emails
            WITH SECURITY_ENFORCED
            LIMIT 50
        ]) {
            ids.add(c.Id);
        }
        return ids;
    }

    private Set<Id> getLeadIdsByEmail(Set<String> emails) {
        Set<Id> ids = new Set<Id>();
        if (emails == null || emails.isEmpty()) return ids;
        for (Lead l : [
            SELECT Id
            FROM Lead
            WHERE Email IN :emails
            WITH SECURITY_ENFORCED
            LIMIT 50
        ]) {
            ids.add(l.Id);
        }
        return ids;
    }

    /**
     * Collects Account IDs related to a set of Contacts (primary Account and AccountContactRelation Accounts).
     *
     * @param contactIds Set of Contact IDs
     * @return Set of related Account IDs
     */
    private Set<Id> getAccountIdsFromContacts(Set<Id> contactIds) {
        Set<Id> accountIds = new Set<Id>();

        for (Contact con : [
            SELECT Id, AccountId
            FROM Contact
            WHERE Id IN :contactIds
            WITH SECURITY_ENFORCED
        ]) {
            if (con.AccountId != null) {
                accountIds.add(con.AccountId);
            }
        }

        for (AccountContactRelation acr : [
            SELECT ContactId, AccountId
            FROM AccountContactRelation
            WHERE ContactId IN :contactIds
            WITH SECURITY_ENFORCED
        ]) {
            if (acr.AccountId != null) {
                accountIds.add(acr.AccountId);
            }
        }

        return accountIds;
    }

    /**
     * Queries recent Opportunities for the given Accounts.
     *
     * @param accountIds Set of Account IDs
     * @return List of maps containing Opportunity data
     */
    private List<Map<String, Object>> queryOpportunities(Set<Id> accountIds) {
        List<Map<String, Object>> oppDataList = new List<Map<String, Object>>();

        // Keep payload bounded; adjust LIMIT if needed for your policy logic.
        List<Opportunity> opps = [
            SELECT Id, Name, StageName, Amount, CloseDate, AccountId, Type, LeadSource, Description, LastModifiedDate
            FROM Opportunity
            WHERE AccountId IN :accountIds
            WITH SECURITY_ENFORCED
            ORDER BY LastModifiedDate DESC
            LIMIT 50
        ];

        for (Opportunity opp : opps) {
            Map<String, Object> oppData = new Map<String, Object>();
            oppData.put('id', opp.Id);
            oppData.put('name', opp.Name);
            oppData.put('stageName', opp.StageName);
            oppData.put('amount', opp.Amount);
            oppData.put('closeDate', opp.CloseDate);
            oppData.put('accountId', opp.AccountId);
            oppData.put('type', opp.Type);
            oppData.put('leadSource', opp.LeadSource);
            oppData.put('description', opp.Description);
            oppData.put('lastModifiedDate', opp.LastModifiedDate);
            oppDataList.add(oppData);
        }

        return oppDataList;
    }

    /**
     * Custom exception for staging policy check errors.
     */
    public class StagingPolicyException extends Exception {}
}