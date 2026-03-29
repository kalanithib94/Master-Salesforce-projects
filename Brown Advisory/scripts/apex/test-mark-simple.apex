// Simple test with Mark's email - no DML

// Simulate Contact data for Mark Addaman
Map<String, Object> contactData = new Map<String, Object>{
    'Email' => 'mark.addaman@techcorp.com',
    'Name' => 'Mark Addaman',
    'Phone' => '(555) 847-2156',
    'Title' => 'Senior Software Engineering Manager',
    'Account' => new Map<String, Object>{
        'Name' => 'Addaman Family',
        'AUM__c' => 2500000
    }
};

String sfDataJson = JSON.serialize(contactData);

System.debug('==========================================');
System.debug('INPUT (Salesforce Data):');
System.debug(sfDataJson);
System.debug('==========================================');

// Create mock data source (not inserted, just for interface)
ccai__AI_Data_Source__c ds = new ccai__AI_Data_Source__c(
    Name = 'Test',
    ccai__Named_Credential__c = 'OutlookGraphAPI'
);

// Call connector directly
OutlookDataSourceConnector connector = new OutlookDataSourceConnector();
String result = connector.getExternalData(ds, sfDataJson);

System.debug('==========================================');
System.debug('OUTPUT (Merged Data):');
System.debug('==========================================');

// Parse and display nicely
Map<String, Object> resultData = (Map<String, Object>) JSON.deserializeUntyped(result);

System.debug('Salesforce Data (Preserved):');
System.debug('  Name: ' + resultData.get('Name'));
System.debug('  Email: ' + resultData.get('Email'));
System.debug('  Phone: ' + resultData.get('Phone'));

if (resultData.containsKey('OutlookEmails')) {
    Map<String, Object> outlookEmails = (Map<String, Object>) resultData.get('OutlookEmails');
    System.debug('');
    System.debug('Email Intelligence (Added):');
    System.debug('  Count: ' + outlookEmails.get('count'));
    System.debug('  Summary: ' + outlookEmails.get('summary'));
    System.debug('');
    if ((Integer)outlookEmails.get('count') > 0) {
        System.debug('  Highlights:');
        System.debug('  ' + outlookEmails.get('highlights'));
        System.debug('');
        System.debug('  Topics: ' + outlookEmails.get('topics'));
    }
}

System.debug('==========================================');
System.debug('RESULT: Data merge ' + (resultData.containsKey('Email') && resultData.containsKey('OutlookEmails') ? 'SUCCESS!' : 'FAILED'));
System.debug('==========================================');

