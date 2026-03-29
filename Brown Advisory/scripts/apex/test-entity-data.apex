// Test with Entity data structure (has Contacts__r array)

String entityData = '{' +
  '"Contacts__r": [' +
    '{"Email": "blake.addaman@highschool.edu", "FirstName": "Blake", "LastName": "Addaman"},' +
    '{"Email": "alex.addaman@student.edu", "FirstName": "Alex", "LastName": "Addaman"},' +
    '{"Email": "cathy.addaman@startupco.com", "FirstName": "Cathy", "LastName": "Addaman"},' +
    '{"Email": "mark.addaman@techcorp.com", "FirstName": "Mark", "LastName": "Addaman"}' +
  '],' +
  '"Object Name": "Entity__c",' +
  '"Name": "Addaman, Markus and Catherine",' +
  '"Annual_Revenue__c": "USD 485000.00"' +
'}';

System.debug('==========================================');
System.debug('TESTING WITH ENTITY DATA STRUCTURE:');
System.debug('==========================================');

// Create mock data source
ccai__AI_Data_Source__c ds = new ccai__AI_Data_Source__c(
    Name = 'Test',
    ccai__Named_Credential__c = 'OutlookGraphAPI'
);

// Call connector
OutlookDataSourceConnector connector = new OutlookDataSourceConnector();
String result = connector.getExternalData(ds, entityData);

System.debug('==========================================');
System.debug('RESULT:');
System.debug('==========================================');

// Parse result
Map<String, Object> resultData = (Map<String, Object>) JSON.deserializeUntyped(result);

// Check if OutlookEmails was added
if (resultData.containsKey('OutlookEmails')) {
    Map<String, Object> outlookEmails = (Map<String, Object>) resultData.get('OutlookEmails');
    
    System.debug('✓ Email Intelligence Added:');
    System.debug('  Count: ' + outlookEmails.get('count'));
    System.debug('  Summary: ' + outlookEmails.get('summary'));
    System.debug('  Topics: ' + outlookEmails.get('topics'));
    System.debug('');
    
    if ((Integer)outlookEmails.get('count') > 0) {
        System.debug('  Highlights:');
        System.debug('  ' + outlookEmails.get('highlights'));
        System.debug('');
        System.debug('✅ SUCCESS! Found emails for Addaman family!');
    } else {
        System.debug('⚠️ No emails found (but data structure is correct)');
    }
} else {
    System.debug('❌ ERROR: OutlookEmails not added');
}

System.debug('==========================================');
System.debug('Entity Data Preserved: ' + (resultData.get('Name') != null ? 'YES' : 'NO'));
System.debug('Contacts Preserved: ' + (resultData.get('Contacts__r') != null ? 'YES' : 'NO'));
System.debug('==========================================');

