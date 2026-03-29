// Create test AI Data Source record
ccai__AI_Data_Source__c ds = new ccai__AI_Data_Source__c(
    Name = 'Outlook Test',
    ccai__Named_Credential__c = 'OutlookGraphAPI',
    ccai__Connector_Class__c = 'OutlookDataSourceConnector'
);
insert ds;

// Test with one of the email addresses you used in Step 1.2
Map<String, Object> contactData = new Map<String, Object>{
    'Email' => 'test-client@example.com',  // REPLACE WITH ACTUAL EMAIL FROM STEP 1.2
    'Name' => 'Test Client',
    'Account' => new Map<String, Object>{
        'Name' => 'Brown Advisory Test Account'
    }
};

String sfDataJson = JSON.serialize(contactData);

OutlookDataSourceConnector connector = new OutlookDataSourceConnector();
String result = connector.getExternalData(ds, sfDataJson);

Map<String, Object> resultData = (Map<String, Object>) JSON.deserializeUntyped(result);
Map<String, Object> outlookEmails = (Map<String, Object>) resultData.get('OutlookEmails');

System.debug('Email Count: ' + outlookEmails.get('count'));
System.debug('Summary: ' + outlookEmails.get('summary'));
System.debug('Full Result: ' + result);

