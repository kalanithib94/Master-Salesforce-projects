// Comprehensive Test Script for CreditLineAgenticHandler
// Tests all methods to ensure they work correctly

System.debug('========================================');
System.debug('CREDIT LINE HANDLER TEST SUITE');
System.debug('========================================\n');

CreditLineAgenticHandler handler = new CreditLineAgenticHandler();

// Test Contact ID - Using Emily Reed (from earlier logs)
String testContactId = '003J900000G00dSIAR';
String testContactName = 'Emily';

// ========================================
// TEST 1: find_contact_by_name
// ========================================
System.debug('\n>>> TEST 1: find_contact_by_name');
System.debug('----------------------------------------');
try {
    Map<String, Object> params = new Map<String, Object>{ 'name' => testContactName };
    String result = handler.executeMethod('find_contact_by_name', params);
    System.debug('RESULT: ' + result);
    
    Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(result);
    System.debug('SUCCESS: ' + response.get('success'));
    System.debug('FOUND: ' + response.get('found'));
    
    if (response.get('ContactId') != null) {
        testContactId = String.valueOf(response.get('ContactId'));
        System.debug('CONTACT ID: ' + testContactId);
    }
    System.debug('✓ TEST 1 PASSED\n');
} catch(Exception ex) {
    System.debug('✗ TEST 1 FAILED: ' + ex.getMessage());
    System.debug('STACK: ' + ex.getStackTraceString());
}

// ========================================
// TEST 2: find_contact_details_by_id
// ========================================
System.debug('>>> TEST 2: find_contact_details_by_id');
System.debug('----------------------------------------');
try {
    Map<String, Object> params = new Map<String, Object>{ 'Id' => testContactId };
    String result = handler.executeMethod('find_contact_details_by_id', params);
    System.debug('RESULT: ' + result);
    
    Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(result);
    System.debug('SUCCESS: ' + response.get('success'));
    System.debug('FOUND: ' + response.get('found'));
    System.debug('CONTACT NAME: ' + response.get('ContactName'));
    System.debug('✓ TEST 2 PASSED\n');
} catch(Exception ex) {
    System.debug('✗ TEST 2 FAILED: ' + ex.getMessage());
    System.debug('STACK: ' + ex.getStackTraceString());
}

// ========================================
// TEST 3: create_credit_increase_case
// ========================================
System.debug('>>> TEST 3: create_credit_increase_case');
System.debug('----------------------------------------');
try {
    Map<String, Object> params = new Map<String, Object>{
        'ContactId' => testContactId,
        'RequestedAmount' => '$10,000',
        'Reason' => 'Test credit increase request'
    };
    String result = handler.executeMethod('create_credit_increase_case', params);
    System.debug('RESULT: ' + result);
    
    Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(result);
    System.debug('SUCCESS: ' + response.get('success'));
    System.debug('CREATED: ' + response.get('created'));
    
    if (response.get('CaseNumber') != null) {
        System.debug('CASE NUMBER: ' + response.get('CaseNumber'));
        System.debug('CASE ID: ' + response.get('CaseId'));
        System.debug('SUBJECT: ' + response.get('Subject'));
    }
    
    if (response.get('success') == true && response.get('created') == true) {
        System.debug('✓ TEST 3 PASSED - Case created successfully\n');
    } else {
        System.debug('✗ TEST 3 FAILED - Case not created');
        System.debug('ERROR: ' + response.get('message'));
    }
} catch(Exception ex) {
    System.debug('✗ TEST 3 FAILED: ' + ex.getMessage());
    System.debug('STACK: ' + ex.getStackTraceString());
}

// ========================================
// TEST 4: create_lost_card_case
// ========================================
System.debug('>>> TEST 4: create_lost_card_case');
System.debug('----------------------------------------');
try {
    Map<String, Object> params = new Map<String, Object>{
        'ContactId' => testContactId,
        'LastUsedDate' => '2025-11-28',
        'LastUsedLocation' => 'Test Location',
        'AdditionalNotes' => 'Test lost card report'
    };
    String result = handler.executeMethod('create_lost_card_case', params);
    System.debug('RESULT: ' + result);
    
    Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(result);
    System.debug('SUCCESS: ' + response.get('success'));
    System.debug('CREATED: ' + response.get('created'));
    
    if (response.get('CaseNumber') != null) {
        System.debug('CASE NUMBER: ' + response.get('CaseNumber'));
        System.debug('CASE ID: ' + response.get('CaseId'));
        System.debug('SUBJECT: ' + response.get('Subject'));
        System.debug('PRIORITY: ' + response.get('Priority'));
    }
    
    if (response.get('success') == true && response.get('created') == true) {
        System.debug('✓ TEST 4 PASSED - Lost card case created successfully\n');
    } else {
        System.debug('✗ TEST 4 FAILED - Case not created');
        System.debug('ERROR: ' + response.get('message'));
    }
} catch(Exception ex) {
    System.debug('✗ TEST 4 FAILED: ' + ex.getMessage());
    System.debug('STACK: ' + ex.getStackTraceString());
}

// ========================================
// TEST 5: create_account_closure_case
// ========================================
System.debug('>>> TEST 5: create_account_closure_case');
System.debug('----------------------------------------');
try {
    Map<String, Object> params = new Map<String, Object>{
        'ContactId' => testContactId,
        'Reason' => 'Test account closure',
        'AdditionalNotes' => 'Testing account closure functionality'
    };
    String result = handler.executeMethod('create_account_closure_case', params);
    System.debug('RESULT: ' + result);
    
    Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(result);
    System.debug('SUCCESS: ' + response.get('success'));
    System.debug('CREATED: ' + response.get('created'));
    
    if (response.get('CaseNumber') != null) {
        System.debug('CASE NUMBER: ' + response.get('CaseNumber'));
        System.debug('CASE ID: ' + response.get('CaseId'));
        System.debug('SUBJECT: ' + response.get('Subject'));
    }
    
    if (response.get('success') == true && response.get('created') == true) {
        System.debug('✓ TEST 5 PASSED - Account closure case created successfully\n');
    } else {
        System.debug('✗ TEST 5 FAILED - Case not created');
        System.debug('ERROR: ' + response.get('message'));
    }
} catch(Exception ex) {
    System.debug('✗ TEST 5 FAILED: ' + ex.getMessage());
    System.debug('STACK: ' + ex.getStackTraceString());
}

// ========================================
// TEST 6: create_case_for_contact
// ========================================
System.debug('>>> TEST 6: create_case_for_contact');
System.debug('----------------------------------------');
try {
    Map<String, Object> params = new Map<String, Object>{
        'ContactId' => testContactId,
        'Subject' => 'Test General Case',
        'Description' => 'This is a test case created by anonymous Apex',
        'Priority' => 'Low',
        'Status' => 'New'
    };
    String result = handler.executeMethod('create_case_for_contact', params);
    System.debug('RESULT: ' + result);
    
    Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(result);
    System.debug('SUCCESS: ' + response.get('success'));
    System.debug('CREATED: ' + response.get('created'));
    
    if (response.get('CaseNumber') != null) {
        System.debug('CASE NUMBER: ' + response.get('CaseNumber'));
        System.debug('CASE ID: ' + response.get('CaseId'));
        System.debug('SUBJECT: ' + response.get('Subject'));
    }
    
    if (response.get('success') == true && response.get('created') == true) {
        System.debug('✓ TEST 6 PASSED - General case created successfully\n');
    } else {
        System.debug('✗ TEST 6 FAILED - Case not created');
        System.debug('ERROR: ' + response.get('message'));
    }
} catch(Exception ex) {
    System.debug('✗ TEST 6 FAILED: ' + ex.getMessage());
    System.debug('STACK: ' + ex.getStackTraceString());
}

// ========================================
// TEST 7: Invalid Method Name
// ========================================
System.debug('>>> TEST 7: Invalid Method Name (Error Handling)');
System.debug('----------------------------------------');
try {
    Map<String, Object> params = new Map<String, Object>();
    String result = handler.executeMethod('invalid_method_name', params);
    System.debug('RESULT: ' + result);
    
    Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(result);
    System.debug('SUCCESS: ' + response.get('success'));
    System.debug('ERROR: ' + response.get('error'));
    System.debug('ERROR CODE: ' + response.get('errorCode'));
    
    if (response.get('success') == false && response.get('error') == true) {
        System.debug('✓ TEST 7 PASSED - Error handling works correctly\n');
    } else {
        System.debug('✗ TEST 7 FAILED - Error not handled properly');
    }
} catch(Exception ex) {
    System.debug('✗ TEST 7 FAILED: ' + ex.getMessage());
}

// ========================================
// TEST SUMMARY
// ========================================
System.debug('========================================');
System.debug('TEST SUITE COMPLETE');
System.debug('========================================');
System.debug('Check the results above for each test.');
System.debug('All tests that show ✓ PASSED are working correctly.');
System.debug('Any tests showing ✗ FAILED need investigation.');

