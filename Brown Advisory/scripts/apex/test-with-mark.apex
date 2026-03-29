// Test with Mark's email (should find the 3 emails we sent to him)

// Query existing AI Data Source
ccai__AI_Data_Source__c ds = [SELECT Id, Name FROM ccai__AI_Data_Source__c WHERE Name = 'Outlook Test' LIMIT 1];

// Simulate Contact data for Mark Addaman
Map<String, Object> contactData = new Map<String, Object>{
    'Email' => 'mark.addaman@techcorp.com',
    'Name' => 'Mark Addaman',
    'Phone' => '(555) 847-2156',
    'Title' => 'Senior Software Engineering Manager',
    'Account' => new Map<String, Object>{
        'Name' => 'Addaman Family',
        'AUM__c' => 2500000,
        'Type' => 'Individual Client'
    }
};

String sfDataJson = JSON.serialize(contactData);

System.debug('==========================================');
System.debug('TESTING WITH MARK ADDAMAN:');
System.debug('==========================================');

// Call connector
OutlookDataSourceConnector connector = new OutlookDataSourceConnector();
String result = connector.getExternalData(ds, sfDataJson);

System.debug('==========================================');
System.debug('MERGED RESULT:');
System.debug(result);
System.debug('==========================================');

// Parse and display
Map<String, Object> resultData = (Map<String, Object>) JSON.deserializeUntyped(result);

System.debug('✓ Salesforce Data Preserved:');
System.debug('  Name: ' + resultData.get('Name'));
System.debug('  Email: ' + resultData.get('Email'));
System.debug('  Phone: ' + resultData.get('Phone'));

if (resultData.containsKey('OutlookEmails')) {
    Map<String, Object> outlookEmails = (Map<String, Object>) resultData.get('OutlookEmails');
    System.debug('');
    System.debug('✓ Email Intelligence Added:');
    System.debug('  Count: ' + outlookEmails.get('count'));
    System.debug('  Summary: ' + outlookEmails.get('summary'));
    System.debug('  Highlights: ' + outlookEmails.get('highlights'));
    System.debug('  Topics: ' + outlookEmails.get('topics'));
}

System.debug('==========================================');

