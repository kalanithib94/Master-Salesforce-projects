// Test that email data is APPENDED to Salesforce data (not replaced)

// Simulate Salesforce data being passed in
Map<String, Object> contactData = new Map<String, Object>{
    'Email' => 'mark.addaman@techcorp.com',
    'Name' => 'Mark Addaman',
    'Phone' => '(555) 847-2156',
    'Account' => new Map<String, Object>{
        'Name' => 'Brown Advisory Test Account',
        'AUM__c' => 2500000
    }
};

String sfDataJson = JSON.serialize(contactData);

System.debug('==========================================');
System.debug('TESTING DATA MERGE:');
System.debug('Input Salesforce Data: ' + sfDataJson);
System.debug('==========================================');

// Create test AI Data Source record
ccai__AI_Data_Source__c ds = new ccai__AI_Data_Source__c(
    Name = 'Outlook Test',
    ccai__Named_Credential__c = 'OutlookGraphAPI',
    ccai__Connector_Class__c = 'OutlookDataSourceConnector'
);
insert ds;

// Call the connector
OutlookDataSourceConnector connector = new OutlookDataSourceConnector();
String result = connector.getExternalData(ds, sfDataJson);

System.debug('==========================================');
System.debug('OUTPUT (Merged Data):');
System.debug(result);
System.debug('==========================================');

// Parse result
Map<String, Object> resultData = (Map<String, Object>) JSON.deserializeUntyped(result);

// Verify original Salesforce data is still there
System.debug('✓ Checking if Salesforce data is preserved:');
System.debug('  Email: ' + resultData.get('Email'));
System.debug('  Name: ' + resultData.get('Name'));
System.debug('  Phone: ' + resultData.get('Phone'));
System.debug('  Account: ' + (resultData.get('Account') != null ? 'Present' : 'Missing'));

// Verify email data was added
System.debug('✓ Checking if Email data was added:');
if (resultData.containsKey('OutlookEmails')) {
    Map<String, Object> outlookEmails = (Map<String, Object>) resultData.get('OutlookEmails');
    System.debug('  Email Count: ' + outlookEmails.get('count'));
    System.debug('  Summary: ' + outlookEmails.get('summary'));
    System.debug('  SUCCESS! Data was merged correctly!');
} else {
    System.debug('  ERROR! OutlookEmails key not found!');
}

System.debug('==========================================');

// Cleanup
delete ds;

