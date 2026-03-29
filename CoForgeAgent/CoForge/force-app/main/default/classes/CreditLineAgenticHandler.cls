/**
 * @description:
 *   CreditLineAgenticHandler implements the AIAgenticInterface and serves as a comprehensive handler for
 *   Credit Line Assistant operations including contact search, contact details retrieval, and case creation
 *   for specific requests (credit line increase, lost card, account closure).
 *
 *   Supported Methods:
 *   - find_contact_by_name: Search contacts by first or last name
 *   - find_contact_details_by_id: Get contact details by Salesforce ID
 *   - create_case_for_contact: Create a general case for a contact
 *   - create_credit_increase_case: Create a credit line increase request case
 *   - create_lost_card_case: Create a lost/stolen card report case
 *   - create_account_closure_case: Create an account closure request case
 *
 * @author              : GPTfy
 * @group               : GPTfy
 * @last modified on    : 28-11-2025
 */
global with sharing class CreditLineAgenticHandler implements ccai.AIAgenticInterface {

    // Configuration
    private static final Integer MAX_SEARCH_RESULTS = 50;
    private static final Integer MIN_SEARCH_LENGTH = 2;
    private static final Boolean DEBUG_ENABLED = true;

    //==========================================================================
    // DEBUG LOGGING HELPERS
    //==========================================================================
    
    private void log(String method, String message) {
        if (DEBUG_ENABLED) {
            System.debug('>>> [' + method + '] ' + message);
        }
    }

    private void logStart(String method) {
        if (DEBUG_ENABLED) {
            System.debug('>>> [' + method + '] ==================== START ====================');
        }
    }

    private void logEnd(String method) {
        if (DEBUG_ENABLED) {
            System.debug('>>> [' + method + '] ====================  END  ====================');
        }
    }

    private void logParams(String method, Map<String, Object> params) {
        if (DEBUG_ENABLED) {
            System.debug('>>> [' + method + '] ----- INPUT PARAMETERS -----');
            if (params == null) {
                System.debug('>>> [' + method + '] params: NULL');
            } else if (params.isEmpty()) {
                System.debug('>>> [' + method + '] params: EMPTY');
            } else {
                for (String key : params.keySet()) {
                    System.debug('>>> [' + method + '] ' + key + ' = ' + params.get(key));
                }
            }
            System.debug('>>> [' + method + '] -----------------------------');
        }
    }

    private void logResponse(String method, Map<String, Object> response) {
        if (DEBUG_ENABLED) {
            System.debug('>>> [' + method + '] ----- OUTPUT RESPONSE -----');
            for (String key : response.keySet()) {
                System.debug('>>> [' + method + '] ' + key + ' = ' + response.get(key));
            }
            System.debug('>>> [' + method + '] ----------------------------');
        }
    }

    //==========================================================================
    // UTILITY METHODS
    //==========================================================================

    private Boolean hasObjectPerm(String sObjectName, String permType) {
        Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get(sObjectName).getDescribe();
        if (permType == 'read')      return describeResult.isAccessible();
        if (permType == 'create')    return describeResult.isCreateable();
        if (permType == 'update')    return describeResult.isUpdateable();
        if (permType == 'delete')    return describeResult.isDeletable();
        return false;
    }

    private Boolean isValidSalesforceId(String recordId) {
        if (String.isBlank(recordId)) return false;
        if (recordId.length() != 15 && recordId.length() != 18) return false;
        Pattern idPattern = Pattern.compile('^[a-zA-Z0-9]{15,18}$');
        return idPattern.matcher(recordId).matches();
    }

    private String sanitizeInput(String input) {
        if (String.isBlank(input)) return '';
        String sanitized = input.trim();
        sanitized = String.escapeSingleQuotes(sanitized);
        sanitized = sanitized.replaceAll('[^a-zA-Z0-9\\s\\-\'\\$\\,\\.]', '');
        return sanitized;
    }

    private String maskEmail(String email) {
        if (String.isBlank(email)) return 'Not on file';
        List<String> parts = email.split('@');
        if (parts.size() != 2) return '***@***.***';
        return parts[0].substring(0, 1) + '***@' + parts[1];
    }

    private String maskPhone(String phone) {
        if (String.isBlank(phone)) return 'Not on file';
        if (phone.length() < 4) return '***';
        return '***-***-' + phone.substring(phone.length() - 4);
    }

    private String buildRecordUrl(Id recordId) {
        if (recordId == null) return null;
        return URL.getOrgDomainUrl().toExternalForm() + '/' + recordId;
    }

    //==========================================================================
    // ERROR RESPONSE BUILDERS
    //==========================================================================

    private String buildErrorResponse(String message, String errorCode) {
        Map<String, Object> response = new Map<String, Object>{
            'success' => false,
            'error' => true,
            'errorCode' => errorCode,
            'message' => message
        };
        log('buildErrorResponse', 'Error [' + errorCode + ']: ' + message);
        return JSON.serialize(response);
    }

    private String buildErrorResponse(Exception ex) {
        log('buildErrorResponse', 'Exception: ' + ex.getMessage());
        log('buildErrorResponse', 'Stack: ' + ex.getStackTraceString());
        return buildErrorResponse(ex.getMessage(), 'EXCEPTION');
    }

    //==========================================================================
    // MAIN ENTRY POINT - executeMethod (from AIAgenticInterface)
    //==========================================================================

    /**
     * @description
     *   Entry point for all agentic function calls. Routes to appropriate handler method.
     * @param methodName    The name of the operation to execute
     * @param parameters    Input map containing parameters for the execution
     * @return String       JSON-encoded response
     */
    global String executeMethod(String methodName, Map<String, Object> parameters) {
        logStart('executeMethod');
        log('executeMethod', 'Method requested: ' + methodName);
        logParams('executeMethod', parameters);
        
        String response;
        
        try {
            if (parameters == null) {
                parameters = new Map<String, Object>();
                log('executeMethod', 'WARNING: Parameters was null, initialized to empty map');
            }
            
            switch on methodName {
                when 'find_contact_by_name'         { response = findContactByName(parameters); }
                when 'find_contact_details_by_id'   { response = findContactDetailsById(parameters); }
                when 'create_case_for_contact'      { response = createCaseForContact(parameters); }
                when 'create_credit_increase_case'  { response = createCreditIncreaseCase(parameters); }
                when 'create_lost_card_case'        { response = createLostCardCase(parameters); }
                when 'create_account_closure_case'  { response = createAccountClosureCase(parameters); }
                when else { 
                    log('executeMethod', 'ERROR: Unknown method - ' + methodName);
                    response = buildErrorResponse('Method "' + methodName + '" is not defined. Available methods: find_contact_by_name, find_contact_details_by_id, create_case_for_contact, create_credit_increase_case, create_lost_card_case, create_account_closure_case', 'METHOD_NOT_FOUND'); 
                }
            }
        } catch(Exception ex) {
            response = buildErrorResponse(ex);
        }
        
        log('executeMethod', 'FINAL RESPONSE: ' + response);
        logEnd('executeMethod');
        
        return response;
    }

    //==========================================================================
    // CONTACT SEARCH METHODS
    //==========================================================================

    /**
     * @description Finds contacts by name (first or last) using LIKE matching
     * @param parameters Map containing 'name' key
     * @return JSON response with contact(s) found
     */
    public String findContactByName(Map<String, Object> parameters) {
        String method = 'findContactByName';
        logStart(method);
        logParams(method, parameters);
        
        // Permission check
        if (!hasObjectPerm('Contact', 'read')) {
            log(method, 'PERMISSION DENIED');
            return buildErrorResponse('Insufficient read permission on Contact object.', 'PERMISSION_DENIED');
        }
        
        try {
            // Validate 'name' parameter
            if (!parameters.containsKey('name') || parameters.get('name') == null) {
                log(method, 'MISSING PARAMETER: name');
                return buildErrorResponse('Parameter "name" is required for contact search.', 'MISSING_PARAMETER');
            }
            
            String rawName = String.valueOf(parameters.get('name'));
            log(method, 'Raw name input: "' + rawName + '"');
            
            String searchName = sanitizeInput(rawName);
            log(method, 'Sanitized name: "' + searchName + '"');
            
            if (String.isBlank(searchName)) {
                log(method, 'INVALID: Name is blank after sanitization');
                return buildErrorResponse('Contact name is required for search.', 'INVALID_INPUT');
            }
            
            if (searchName.length() < MIN_SEARCH_LENGTH) {
                log(method, 'INVALID: Name too short (' + searchName.length() + ' chars)');
                return buildErrorResponse('Search name must be at least ' + MIN_SEARCH_LENGTH + ' characters long.', 'INVALID_INPUT');
            }
            
            String searchPattern = '%' + searchName + '%';
            log(method, 'SOQL search pattern: ' + searchPattern);
            
            // Execute query
            log(method, 'Executing SOQL query...');
            List<Contact> contacts = [
                SELECT 
                    Id, LastName, FirstName, Phone, Fax, MobilePhone, HomePhone, Email,
                    Current_Credit_limit__c, Current_balance__c,
                    Payment_History__c, Credit_lines__c
                FROM Contact 
                WHERE FirstName LIKE :searchPattern OR LastName LIKE :searchPattern
                ORDER BY LastName, FirstName
                LIMIT :MAX_SEARCH_RESULTS
            ];
            
            log(method, 'Query returned ' + contacts.size() + ' contact(s)');
            
            Map<String, Object> response = new Map<String, Object>();
            
            // No contacts found
            if (contacts.isEmpty()) {
                log(method, 'RESULT: No contacts found');
                response = new Map<String, Object>{
                    'success' => true,
                    'found' => false,
                    'count' => 0,
                    'message' => 'No contacts found matching: ' + searchName,
                    'contacts' => new List<Object>(),
                    'ContactId' => null,
                    'instruction' => 'INFORM_USER_NO_RECORD_FOUND'
                };
            }
            // Multiple contacts found
            else if (contacts.size() > 1) {
                log(method, 'RESULT: Multiple contacts found - verification required');
                List<Map<String, Object>> maskedContacts = new List<Map<String, Object>>();
                for (Contact c : contacts) {
                    log(method, '  - ' + c.Id + ': ' + c.FirstName + ' ' + c.LastName);
                    maskedContacts.add(new Map<String, Object>{
                        'Id' => c.Id,
                        'FirstName' => c.FirstName,
                        'LastName' => c.LastName,
                        'Email' => maskEmail(c.Email),
                        'Phone' => maskPhone(c.Phone)
                    });
                }
                response = new Map<String, Object>{
                    'success' => true,
                    'found' => true,
                    'multipleMatches' => true,
                    'count' => contacts.size(),
                    'message' => 'Found ' + contacts.size() + ' contacts matching: ' + searchName + '. Please verify identity.',
                    'contacts' => maskedContacts,
                    'ContactId' => null,
                    'instruction' => 'ASK_USER_TO_VERIFY_IDENTITY'
                };
            }
            // Single contact found
            else {
                Contact c = contacts[0];
                log(method, 'RESULT: Single contact found');
                log(method, '  Id: ' + c.Id);
                log(method, '  Name: ' + c.FirstName + ' ' + c.LastName);
                log(method, '  Email: ' + c.Email);
                log(method, '  Phone: ' + c.Phone);
                log(method, '  Current_Credit_limit__c: ' + c.Current_Credit_limit__c);
                log(method, '  Current_balance__c: ' + c.Current_balance__c);
                log(method, '  Payment_History__c: ' + c.Payment_History__c);
                log(method, '  Credit_lines__c: ' + c.Credit_lines__c);
                
                response = new Map<String, Object>{
                    'success' => true,
                    'found' => true,
                    'multipleMatches' => false,
                    'count' => 1,
                    'message' => 'Found contact: ' + c.FirstName + ' ' + c.LastName,
                    'contact' => c,
                    'ContactId' => c.Id,
                    'ContactName' => c.FirstName + ' ' + c.LastName,
                    'instruction' => 'PROCEED_WITH_CONTACT'
                };
            }
            
            logResponse(method, response);
            logEnd(method);
            return JSON.serialize(response);
            
        } catch(Exception ex) {
            log(method, 'EXCEPTION: ' + ex.getMessage());
            logEnd(method);
            return buildErrorResponse(ex);
        }
    }

    /**
     * @description Finds a contact by Salesforce ID
     * @param parameters Map containing 'Id' key
     * @return JSON response with contact details
     */
    public String findContactDetailsById(Map<String, Object> parameters) {
        String method = 'findContactDetailsById';
        logStart(method);
        logParams(method, parameters);
        
        // Permission check
        if (!hasObjectPerm('Contact', 'read')) {
            log(method, 'PERMISSION DENIED');
            return buildErrorResponse('Insufficient read permission on Contact object.', 'PERMISSION_DENIED');
        }
        
        try {
            // Validate 'Id' parameter
            if (!parameters.containsKey('Id') || parameters.get('Id') == null) {
                log(method, 'MISSING PARAMETER: Id');
                return buildErrorResponse('Parameter "Id" is required to fetch contact details.', 'MISSING_PARAMETER');
            }
            
            String contactId = String.valueOf(parameters.get('Id')).trim();
            log(method, 'Input ContactId: "' + contactId + '"');
            
            if (String.isBlank(contactId)) {
                log(method, 'INVALID: ContactId is blank');
                return buildErrorResponse('Contact Id cannot be empty.', 'INVALID_INPUT');
            }
            
            if (!isValidSalesforceId(contactId)) {
                log(method, 'INVALID: ContactId format invalid');
                return buildErrorResponse('Invalid Contact Id format: ' + contactId, 'INVALID_ID_FORMAT');
            }
            
            // Execute query
            log(method, 'Executing SOQL query...');
            List<Contact> contacts = [
                SELECT 
                    Id, LastName, FirstName, Phone, Fax, MobilePhone, HomePhone, Email,
                    Current_Credit_limit__c, Current_balance__c,
                    Payment_History__c, Credit_lines__c
                FROM Contact 
                WHERE Id = :contactId
                LIMIT 1
            ];
            
            log(method, 'Query returned ' + contacts.size() + ' contact(s)');
            
            Map<String, Object> response = new Map<String, Object>();
            
            if (contacts.isEmpty()) {
                log(method, 'RESULT: No contact found with Id: ' + contactId);
                response = new Map<String, Object>{
                    'success' => true,
                    'found' => false,
                    'count' => 0,
                    'message' => 'No Contact found with Id: ' + contactId,
                    'contact' => null,
                    'ContactId' => null,
                    'instruction' => 'INFORM_USER_NO_RECORD_FOUND'
                };
            } else {
                Contact c = contacts[0];
                log(method, 'RESULT: Contact found');
                log(method, '  Id: ' + c.Id);
                log(method, '  Name: ' + c.FirstName + ' ' + c.LastName);
                log(method, '  Email: ' + c.Email);
                log(method, '  Phone: ' + c.Phone);
                log(method, '  Current_Credit_limit__c: ' + c.Current_Credit_limit__c);
                log(method, '  Current_balance__c: ' + c.Current_balance__c);
                log(method, '  Payment_History__c: ' + c.Payment_History__c);
                log(method, '  Credit_lines__c: ' + c.Credit_lines__c);
                
                response = new Map<String, Object>{
                    'success' => true,
                    'found' => true,
                    'count' => 1,
                    'message' => 'Found contact: ' + c.FirstName + ' ' + c.LastName,
                    'contact' => c,
                    'ContactId' => c.Id,
                    'ContactName' => c.FirstName + ' ' + c.LastName,
                    'instruction' => 'DISPLAY_CONTACT_DETAILS'
                };
            }
            
            logResponse(method, response);
            logEnd(method);
            return JSON.serialize(response);
            
        } catch(Exception ex) {
            log(method, 'EXCEPTION: ' + ex.getMessage());
            logEnd(method);
            return buildErrorResponse(ex);
        }
    }

    //==========================================================================
    // HELPER: Validate and Get Contact
    //==========================================================================

    private Contact getValidatedContact(String contactId, String method) {
        log(method, 'Validating ContactId: ' + contactId);
        
        if (String.isBlank(contactId)) {
            log(method, 'INVALID: ContactId is blank');
            return null;
        }
        
        if (!isValidSalesforceId(contactId)) {
            log(method, 'INVALID: ContactId format');
            return null;
        }
        
        List<Contact> contacts = [
            SELECT Id, FirstName, LastName, AccountId, Current_Credit_limit__c, Current_balance__c 
            FROM Contact 
            WHERE Id = :contactId 
            LIMIT 1
        ];
        
        if (contacts.isEmpty()) {
            log(method, 'Contact NOT FOUND');
            return null;
        }
        
        Contact c = contacts[0];
        log(method, 'Contact VALIDATED: ' + c.FirstName + ' ' + c.LastName + ' (AccountId: ' + c.AccountId + ')');
        return c;
    }

    //==========================================================================
    // CASE CREATION METHODS
    //==========================================================================

    /**
     * @description Creates a general case for a contact
     * @param parameters Map containing 'ContactId' and 'Subject' (required), plus optional case fields
     * @return JSON response with created case details
     */
    public String createCaseForContact(Map<String, Object> parameters) {
        String method = 'createCaseForContact';
        logStart(method);
        logParams(method, parameters);
        
        // Permission checks
        if (!hasObjectPerm('Case', 'create')) {
            log(method, 'PERMISSION DENIED: Case create');
            return buildErrorResponse('Insufficient create permission on Case object.', 'PERMISSION_DENIED');
        }
        if (!hasObjectPerm('Contact', 'read')) {
            log(method, 'PERMISSION DENIED: Contact read');
            return buildErrorResponse('Insufficient read permission on Contact object.', 'PERMISSION_DENIED');
        }
        
        try {
            // Validate ContactId
            if (!parameters.containsKey('ContactId') || parameters.get('ContactId') == null) {
                log(method, 'MISSING PARAMETER: ContactId');
                return buildErrorResponse('Parameter "ContactId" is required.', 'MISSING_PARAMETER');
            }
            
            String contactId = String.valueOf(parameters.get('ContactId')).trim();
            log(method, 'Input ContactId: ' + contactId);
            
            Contact relatedContact = getValidatedContact(contactId, method);
            if (relatedContact == null) {
                return buildErrorResponse('No Contact found with ContactId: ' + contactId, 'CONTACT_NOT_FOUND');
            }
            
            // Validate Subject
            if (!parameters.containsKey('Subject') || String.isBlank(String.valueOf(parameters.get('Subject')))) {
                log(method, 'MISSING PARAMETER: Subject');
                return buildErrorResponse('Parameter "Subject" is required.', 'MISSING_PARAMETER');
            }
            
            String contactFullName = relatedContact.FirstName + ' ' + relatedContact.LastName;
            
            // Build Case
            Case newCase = new Case();
            newCase.ContactId = Id.valueOf(contactId);
            log(method, 'Set Case.ContactId = ' + newCase.ContactId);
            
            if (relatedContact.AccountId != null) {
                newCase.AccountId = relatedContact.AccountId;
                log(method, 'Set Case.AccountId = ' + newCase.AccountId);
            }
            
            // Set allowed fields
            Set<String> allowedFields = new Set<String>{'Subject', 'Description', 'Status', 'Priority', 'Origin', 'Type', 'Reason'};
            for (String key : parameters.keySet()) {
                if (allowedFields.contains(key) && parameters.get(key) != null) {
                    newCase.put(key, String.valueOf(parameters.get(key)));
                    log(method, 'Set Case.' + key + ' = ' + parameters.get(key));
                }
            }
            
            // Insert
            log(method, 'INSERTING CASE...');
            insert newCase;
            log(method, 'CASE INSERTED: ' + newCase.Id);
            
            // Query created case
            Case createdCase = [
                SELECT Id, CaseNumber, Subject, Description, Status, Priority, Origin, Type, ContactId, AccountId, CreatedDate
                FROM Case WHERE Id = :newCase.Id LIMIT 1
            ];
            
            log(method, '===== CREATED CASE DETAILS =====');
            log(method, 'CaseId: ' + createdCase.Id);
            log(method, 'CaseNumber: ' + createdCase.CaseNumber);
            log(method, 'Subject: ' + createdCase.Subject);
            log(method, 'ContactId: ' + createdCase.ContactId);
            log(method, 'AccountId: ' + createdCase.AccountId);
            log(method, '================================');
            
            Map<String, Object> response = new Map<String, Object>{
                'status' => 'success',
                'success' => true,
                'created' => true,
                'message' => 'Successfully created case ' + createdCase.CaseNumber + ' for ' + contactFullName + ' with RecordId: ' + createdCase.Id,
                'id' => createdCase.Id,
                'CaseId' => String.valueOf(createdCase.Id),
                'CaseNumber' => createdCase.CaseNumber,
                'CaseUrl' => buildRecordUrl(createdCase.Id),
                'Subject' => createdCase.Subject,
                'ContactId' => String.valueOf(createdCase.ContactId),
                'ContactName' => contactFullName,
                'AccountId' => createdCase.AccountId != null ? String.valueOf(createdCase.AccountId) : null,
                'Status' => createdCase.Status,
                'Priority' => createdCase.Priority,
                'instruction' => 'DISPLAY_CASE_NUMBER_AND_URL_TO_USER'
            };
            
            logResponse(method, response);
            logEnd(method);
            return JSON.serialize(response);
            
        } catch(Exception ex) {
            log(method, 'EXCEPTION: ' + ex.getMessage());
            logEnd(method);
            return buildErrorResponse('Failed to create Case: ' + ex.getMessage(), 'CASE_CREATION_FAILED');
        }
    }

    /**
     * @description Creates a Credit Line Increase Request case
     * @param parameters Map containing 'ContactId' (required), 'RequestedAmount', 'Reason' (optional)
     * @return JSON response with created case details
     */
    public String createCreditIncreaseCase(Map<String, Object> parameters) {
        String method = 'createCreditIncreaseCase';
        logStart(method);
        logParams(method, parameters);
        
        // Permission checks
        if (!hasObjectPerm('Case', 'create')) {
            log(method, 'PERMISSION DENIED: Case create');
            return buildErrorResponse('Insufficient create permission on Case object.', 'PERMISSION_DENIED');
        }
        if (!hasObjectPerm('Contact', 'read')) {
            log(method, 'PERMISSION DENIED: Contact read');
            return buildErrorResponse('Insufficient read permission on Contact object.', 'PERMISSION_DENIED');
        }
        
        try {
            // Validate ContactId
            if (!parameters.containsKey('ContactId') || parameters.get('ContactId') == null) {
                log(method, 'MISSING PARAMETER: ContactId');
                return buildErrorResponse('Parameter "ContactId" is required.', 'MISSING_PARAMETER');
            }
            
            String contactId = String.valueOf(parameters.get('ContactId')).trim();
            log(method, 'Input ContactId: ' + contactId);
            
            Contact relatedContact = getValidatedContact(contactId, method);
            if (relatedContact == null) {
                return buildErrorResponse('No Contact found with ContactId: ' + contactId, 'CONTACT_NOT_FOUND');
            }
            
            String contactFullName = relatedContact.FirstName + ' ' + relatedContact.LastName;
            log(method, 'Contact: ' + contactFullName);
            log(method, 'Current Credit Limit: ' + relatedContact.Current_Credit_limit__c);
            
            // Get optional parameters
            String requestedAmount = parameters.containsKey('RequestedAmount') && parameters.get('RequestedAmount') != null
                ? sanitizeInput(String.valueOf(parameters.get('RequestedAmount')))
                : 'Not specified';
            String reason = parameters.containsKey('Reason') && parameters.get('Reason') != null
                ? sanitizeInput(String.valueOf(parameters.get('Reason')))
                : 'Customer requested credit line increase';
            
            log(method, 'RequestedAmount: ' + requestedAmount);
            log(method, 'Reason: ' + reason);
            
            // Build description
            String description = 'Credit Line Increase Request\n' +
                '-----------------------------------\n' +
                'Contact: ' + contactFullName + '\n' +
                'Contact Id: ' + relatedContact.Id + '\n' +
                'Current Credit Limit: ' + (relatedContact.Current_Credit_limit__c != null ? '$' + relatedContact.Current_Credit_limit__c : 'N/A') + '\n' +
                'Requested New Limit: ' + requestedAmount + '\n' +
                'Reason: ' + reason;
            
            // Build Case
            Case newCase = new Case();
            newCase.ContactId = Id.valueOf(contactId);
            newCase.Subject = 'Credit Line Increase Request - ' + contactFullName;
            newCase.Description = description;
            newCase.Status = 'New';
            newCase.Priority = 'Medium';
            newCase.Origin = 'Chat';
            newCase.Type = 'Service Request';
            
            if (relatedContact.AccountId != null) {
                newCase.AccountId = relatedContact.AccountId;
            }
            
            log(method, 'Case.ContactId = ' + newCase.ContactId);
            log(method, 'Case.Subject = ' + newCase.Subject);
            log(method, 'Case.AccountId = ' + newCase.AccountId);
            
            // Insert
            log(method, 'INSERTING CASE...');
            insert newCase;
            log(method, 'CASE INSERTED: ' + newCase.Id);
            
            // Query created case
            Case createdCase = [
                SELECT Id, CaseNumber, Subject, Status, Priority, ContactId, AccountId, CreatedDate
                FROM Case WHERE Id = :newCase.Id LIMIT 1
            ];
            
            log(method, '===== CREATED CASE DETAILS =====');
            log(method, 'CaseId: ' + createdCase.Id);
            log(method, 'CaseNumber: ' + createdCase.CaseNumber);
            log(method, 'Subject: ' + createdCase.Subject);
            log(method, 'ContactId: ' + createdCase.ContactId);
            log(method, 'AccountId: ' + createdCase.AccountId);
            log(method, '================================');
            
            Map<String, Object> response = new Map<String, Object>{
                'status' => 'success',
                'success' => true,
                'created' => true,
                'message' => 'Successfully created credit increase case ' + createdCase.CaseNumber + ' for ' + contactFullName + ' with RecordId: ' + createdCase.Id,
                'id' => createdCase.Id,
                'CaseId' => String.valueOf(createdCase.Id),
                'CaseNumber' => createdCase.CaseNumber,
                'CaseUrl' => buildRecordUrl(createdCase.Id),
                'Subject' => createdCase.Subject,
                'ContactId' => String.valueOf(createdCase.ContactId),
                'ContactName' => contactFullName,
                'AccountId' => createdCase.AccountId != null ? String.valueOf(createdCase.AccountId) : null,
                'CurrentCreditLimit' => relatedContact.Current_Credit_limit__c,
                'RequestedAmount' => requestedAmount,
                'Status' => createdCase.Status,
                'Priority' => createdCase.Priority,
                'instruction' => 'DISPLAY_CASE_NUMBER_AND_URL_TO_USER'
            };
            
            logResponse(method, response);
            logEnd(method);
            return JSON.serialize(response);
            
        } catch(Exception ex) {
            log(method, 'EXCEPTION: ' + ex.getMessage());
            logEnd(method);
            return buildErrorResponse('Failed to create Credit Increase Case: ' + ex.getMessage(), 'CASE_CREATION_FAILED');
        }
    }

    /**
     * @description Creates a Lost/Stolen Card Report case (HIGH PRIORITY)
     * @param parameters Map containing 'ContactId' (required), 'LastUsedDate', 'LastUsedLocation', 'AdditionalNotes' (optional)
     * @return JSON response with created case details
     */
    public String createLostCardCase(Map<String, Object> parameters) {
        String method = 'createLostCardCase';
        logStart(method);
        logParams(method, parameters);
        
        // Permission checks
        if (!hasObjectPerm('Case', 'create')) {
            log(method, 'PERMISSION DENIED: Case create');
            return buildErrorResponse('Insufficient create permission on Case object.', 'PERMISSION_DENIED');
        }
        if (!hasObjectPerm('Contact', 'read')) {
            log(method, 'PERMISSION DENIED: Contact read');
            return buildErrorResponse('Insufficient read permission on Contact object.', 'PERMISSION_DENIED');
        }
        
        try {
            // Validate ContactId
            if (!parameters.containsKey('ContactId') || parameters.get('ContactId') == null) {
                log(method, 'MISSING PARAMETER: ContactId');
                return buildErrorResponse('Parameter "ContactId" is required.', 'MISSING_PARAMETER');
            }
            
            String contactId = String.valueOf(parameters.get('ContactId')).trim();
            log(method, 'Input ContactId: ' + contactId);
            
            Contact relatedContact = getValidatedContact(contactId, method);
            if (relatedContact == null) {
                return buildErrorResponse('No Contact found with ContactId: ' + contactId, 'CONTACT_NOT_FOUND');
            }
            
            String contactFullName = relatedContact.FirstName + ' ' + relatedContact.LastName;
            log(method, 'Contact: ' + contactFullName);
            
            // Get optional parameters
            String lastUsedDate = parameters.containsKey('LastUsedDate') && parameters.get('LastUsedDate') != null
                ? sanitizeInput(String.valueOf(parameters.get('LastUsedDate')))
                : 'Not specified';
            String lastUsedLocation = parameters.containsKey('LastUsedLocation') && parameters.get('LastUsedLocation') != null
                ? sanitizeInput(String.valueOf(parameters.get('LastUsedLocation')))
                : 'Not specified';
            String additionalNotes = parameters.containsKey('AdditionalNotes') && parameters.get('AdditionalNotes') != null
                ? sanitizeInput(String.valueOf(parameters.get('AdditionalNotes')))
                : '';
            
            log(method, 'LastUsedDate: ' + lastUsedDate);
            log(method, 'LastUsedLocation: ' + lastUsedLocation);
            log(method, 'AdditionalNotes: ' + additionalNotes);
            
            // Build description
            String description = 'URGENT: Lost/Stolen Credit Card Report\n' +
                '-----------------------------------\n' +
                'Contact: ' + contactFullName + '\n' +
                'Contact Id: ' + relatedContact.Id + '\n' +
                'Current Credit Limit: ' + (relatedContact.Current_Credit_limit__c != null ? '$' + relatedContact.Current_Credit_limit__c : 'N/A') + '\n' +
                'Current Balance: ' + (relatedContact.Current_balance__c != null ? '$' + relatedContact.Current_balance__c : 'N/A') + '\n' +
                'Last Used Date: ' + lastUsedDate + '\n' +
                'Last Used Location: ' + lastUsedLocation + '\n' +
                'Additional Notes: ' + additionalNotes + '\n\n' +
                'ACTION REQUIRED: Block card immediately and issue replacement.';
            
            // Build Case
            Case newCase = new Case();
            newCase.ContactId = Id.valueOf(contactId);
            newCase.Subject = 'URGENT: Lost/Stolen Credit Card - ' + contactFullName;
            newCase.Description = description;
            newCase.Status = 'New';
            newCase.Priority = 'High';
            newCase.Origin = 'Chat';
            newCase.Type = 'Problem';
            
            if (relatedContact.AccountId != null) {
                newCase.AccountId = relatedContact.AccountId;
            }
            
            log(method, 'Case.ContactId = ' + newCase.ContactId);
            log(method, 'Case.Subject = ' + newCase.Subject);
            log(method, 'Case.Priority = ' + newCase.Priority);
            
            // Insert
            log(method, 'INSERTING CASE...');
            insert newCase;
            log(method, 'CASE INSERTED: ' + newCase.Id);
            
            // Query created case
            Case createdCase = [
                SELECT Id, CaseNumber, Subject, Status, Priority, ContactId, AccountId, CreatedDate
                FROM Case WHERE Id = :newCase.Id LIMIT 1
            ];
            
            log(method, '===== CREATED CASE DETAILS =====');
            log(method, 'CaseId: ' + createdCase.Id);
            log(method, 'CaseNumber: ' + createdCase.CaseNumber);
            log(method, 'Subject: ' + createdCase.Subject);
            log(method, 'ContactId: ' + createdCase.ContactId);
            log(method, 'Priority: ' + createdCase.Priority);
            log(method, '================================');
            
            Map<String, Object> response = new Map<String, Object>{
                'status' => 'success',
                'success' => true,
                'created' => true,
                'message' => 'Successfully created urgent lost card case ' + createdCase.CaseNumber + ' for ' + contactFullName + ' with RecordId: ' + createdCase.Id + '. Card will be blocked immediately.',
                'id' => createdCase.Id,
                'CaseId' => String.valueOf(createdCase.Id),
                'CaseNumber' => createdCase.CaseNumber,
                'CaseUrl' => buildRecordUrl(createdCase.Id),
                'Subject' => createdCase.Subject,
                'ContactId' => String.valueOf(createdCase.ContactId),
                'ContactName' => contactFullName,
                'AccountId' => createdCase.AccountId != null ? String.valueOf(createdCase.AccountId) : null,
                'Status' => createdCase.Status,
                'Priority' => createdCase.Priority,
                'instruction' => 'DISPLAY_CASE_NUMBER_AND_URL_TO_USER'
            };
            
            logResponse(method, response);
            logEnd(method);
            return JSON.serialize(response);
            
        } catch(Exception ex) {
            log(method, 'EXCEPTION: ' + ex.getMessage());
            logEnd(method);
            return buildErrorResponse('Failed to create Lost Card Case: ' + ex.getMessage(), 'CASE_CREATION_FAILED');
        }
    }

    /**
     * @description Creates an Account Closure Request case
     * @param parameters Map containing 'ContactId' (required), 'Reason', 'AdditionalNotes' (optional)
     * @return JSON response with created case details
     */
    public String createAccountClosureCase(Map<String, Object> parameters) {
        String method = 'createAccountClosureCase';
        logStart(method);
        logParams(method, parameters);
        
        // Permission checks
        if (!hasObjectPerm('Case', 'create')) {
            log(method, 'PERMISSION DENIED: Case create');
            return buildErrorResponse('Insufficient create permission on Case object.', 'PERMISSION_DENIED');
        }
        if (!hasObjectPerm('Contact', 'read')) {
            log(method, 'PERMISSION DENIED: Contact read');
            return buildErrorResponse('Insufficient read permission on Contact object.', 'PERMISSION_DENIED');
        }
        
        try {
            // Validate ContactId
            if (!parameters.containsKey('ContactId') || parameters.get('ContactId') == null) {
                log(method, 'MISSING PARAMETER: ContactId');
                return buildErrorResponse('Parameter "ContactId" is required.', 'MISSING_PARAMETER');
            }
            
            String contactId = String.valueOf(parameters.get('ContactId')).trim();
            log(method, 'Input ContactId: ' + contactId);
            
            Contact relatedContact = getValidatedContact(contactId, method);
            if (relatedContact == null) {
                return buildErrorResponse('No Contact found with ContactId: ' + contactId, 'CONTACT_NOT_FOUND');
            }
            
            String contactFullName = relatedContact.FirstName + ' ' + relatedContact.LastName;
            log(method, 'Contact: ' + contactFullName);
            log(method, 'Current Balance: ' + relatedContact.Current_balance__c);
            
            // Get optional parameters
            String reason = parameters.containsKey('Reason') && parameters.get('Reason') != null
                ? sanitizeInput(String.valueOf(parameters.get('Reason')))
                : 'Customer requested account closure';
            String additionalNotes = parameters.containsKey('AdditionalNotes') && parameters.get('AdditionalNotes') != null
                ? sanitizeInput(String.valueOf(parameters.get('AdditionalNotes')))
                : '';
            
            log(method, 'Reason: ' + reason);
            log(method, 'AdditionalNotes: ' + additionalNotes);
            
            // Build description
            String description = 'Account Closure Request\n' +
                '-----------------------------------\n' +
                'Contact: ' + contactFullName + '\n' +
                'Contact Id: ' + relatedContact.Id + '\n' +
                'Current Credit Limit: ' + (relatedContact.Current_Credit_limit__c != null ? '$' + relatedContact.Current_Credit_limit__c : 'N/A') + '\n' +
                'Current Balance: ' + (relatedContact.Current_balance__c != null ? '$' + relatedContact.Current_balance__c : 'N/A') + '\n' +
                'Reason for Closure: ' + reason + '\n' +
                'Additional Notes: ' + additionalNotes + '\n\n' +
                'NOTE: Verify outstanding balance before processing.';
            
            // Build Case
            Case newCase = new Case();
            newCase.ContactId = Id.valueOf(contactId);
            newCase.Subject = 'Account Closure Request - ' + contactFullName;
            newCase.Description = description;
            newCase.Status = 'New';
            newCase.Priority = 'Medium';
            newCase.Origin = 'Chat';
            newCase.Type = 'Service Request';
            
            if (relatedContact.AccountId != null) {
                newCase.AccountId = relatedContact.AccountId;
            }
            
            log(method, 'Case.ContactId = ' + newCase.ContactId);
            log(method, 'Case.Subject = ' + newCase.Subject);
            
            // Insert
            log(method, 'INSERTING CASE...');
            insert newCase;
            log(method, 'CASE INSERTED: ' + newCase.Id);
            
            // Query created case
            Case createdCase = [
                SELECT Id, CaseNumber, Subject, Status, Priority, ContactId, AccountId, CreatedDate
                FROM Case WHERE Id = :newCase.Id LIMIT 1
            ];
            
            log(method, '===== CREATED CASE DETAILS =====');
            log(method, 'CaseId: ' + createdCase.Id);
            log(method, 'CaseNumber: ' + createdCase.CaseNumber);
            log(method, 'Subject: ' + createdCase.Subject);
            log(method, 'ContactId: ' + createdCase.ContactId);
            log(method, '================================');
            
            Map<String, Object> response = new Map<String, Object>{
                'status' => 'success',
                'success' => true,
                'created' => true,
                'message' => 'Successfully created account closure case ' + createdCase.CaseNumber + ' for ' + contactFullName + ' with RecordId: ' + createdCase.Id,
                'id' => createdCase.Id,
                'CaseId' => String.valueOf(createdCase.Id),
                'CaseNumber' => createdCase.CaseNumber,
                'CaseUrl' => buildRecordUrl(createdCase.Id),
                'Subject' => createdCase.Subject,
                'ContactId' => String.valueOf(createdCase.ContactId),
                'ContactName' => contactFullName,
                'AccountId' => createdCase.AccountId != null ? String.valueOf(createdCase.AccountId) : null,
                'CurrentBalance' => relatedContact.Current_balance__c,
                'Status' => createdCase.Status,
                'Priority' => createdCase.Priority,
                'instruction' => 'DISPLAY_CASE_NUMBER_AND_URL_TO_USER'
            };
            
            logResponse(method, response);
            logEnd(method);
            return JSON.serialize(response);
            
        } catch(Exception ex) {
            log(method, 'EXCEPTION: ' + ex.getMessage());
            logEnd(method);
            return buildErrorResponse('Failed to create Account Closure Case: ' + ex.getMessage(), 'CASE_CREATION_FAILED');
        }
    }
}
