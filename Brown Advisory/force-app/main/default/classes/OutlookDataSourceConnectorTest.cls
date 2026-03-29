@isTest
private class OutlookDataSourceConnectorTest {
    
    @isTest
    static void testGetExternalData_Success() {
        // Setup
        ccai__AI_Data_Source__c ds = new ccai__AI_Data_Source__c(
            Name = 'Test Outlook',
            ccai__Named_Credential__c = 'OutlookGraphAPI',
            ccai__Connector_Class__c = 'OutlookDataSourceConnector'
        );
        insert ds;
        
        Map<String, Object> contactData = new Map<String, Object>{
            'Email' => 'test@example.com',
            'Name' => 'Test Contact'
        };
        String sfDataJson = JSON.serialize(contactData);
        
        // Set mock response
        Test.setMock(HttpCalloutMock.class, new OutlookGraphAPIMock(200, true));
        
        // Execute
        Test.startTest();
        OutlookDataSourceConnector connector = new OutlookDataSourceConnector();
        String result = connector.getExternalData(ds, sfDataJson);
        Test.stopTest();
        
        // Verify
        System.assertNotEquals(null, result, 'Result should not be null');
        Map<String, Object> resultData = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assert(resultData.containsKey('OutlookEmails'), 'Should contain OutlookEmails key');
        
        Map<String, Object> outlookEmails = (Map<String, Object>) resultData.get('OutlookEmails');
        System.assertNotEquals(null, outlookEmails.get('count'), 'Should have email count');
        System.assertNotEquals(null, outlookEmails.get('summary'), 'Should have summary');
    }
    
    @isTest
    static void testGetExternalData_NoEmail() {
        // Setup
        ccai__AI_Data_Source__c ds = new ccai__AI_Data_Source__c(
            Name = 'Test Outlook',
            ccai__Named_Credential__c = 'OutlookGraphAPI',
            ccai__Connector_Class__c = 'OutlookDataSourceConnector'
        );
        insert ds;
        
        Map<String, Object> contactData = new Map<String, Object>{
            'Name' => 'Test Contact'
            // No email provided
        };
        String sfDataJson = JSON.serialize(contactData);
        
        // Execute
        Test.startTest();
        OutlookDataSourceConnector connector = new OutlookDataSourceConnector();
        String result = connector.getExternalData(ds, sfDataJson);
        Test.stopTest();
        
        // Verify error response
        System.assertNotEquals(null, result, 'Result should not be null');
        Map<String, Object> resultData = (Map<String, Object>) JSON.deserializeUntyped(result);
        Map<String, Object> outlookEmails = (Map<String, Object>) resultData.get('OutlookEmails');
        System.assertEquals(0, outlookEmails.get('count'), 'Count should be 0');
        System.assert(((String)outlookEmails.get('summary')).contains('Error'), 'Should contain error message');
    }
    
    @isTest
    static void testGetExternalData_NoEmails() {
        // Setup
        ccai__AI_Data_Source__c ds = new ccai__AI_Data_Source__c(
            Name = 'Test Outlook',
            ccai__Named_Credential__c = 'OutlookGraphAPI',
            ccai__Connector_Class__c = 'OutlookDataSourceConnector'
        );
        insert ds;
        
        Map<String, Object> contactData = new Map<String, Object>{
            'Email' => 'test@example.com',
            'Name' => 'Test Contact'
        };
        String sfDataJson = JSON.serialize(contactData);
        
        // Set mock response with no emails
        Test.setMock(HttpCalloutMock.class, new OutlookGraphAPIMock(200, false));
        
        // Execute
        Test.startTest();
        OutlookDataSourceConnector connector = new OutlookDataSourceConnector();
        String result = connector.getExternalData(ds, sfDataJson);
        Test.stopTest();
        
        // Verify
        System.assertNotEquals(null, result, 'Result should not be null');
        Map<String, Object> resultData = (Map<String, Object>) JSON.deserializeUntyped(result);
        Map<String, Object> outlookEmails = (Map<String, Object>) resultData.get('OutlookEmails');
        System.assertEquals(0, outlookEmails.get('count'), 'Count should be 0');
        System.assert(((String)outlookEmails.get('summary')).contains('No recent emails'), 'Should indicate no emails found');
    }
    
    @isTest
    static void testGetExternalData_APIError() {
        // Setup
        ccai__AI_Data_Source__c ds = new ccai__AI_Data_Source__c(
            Name = 'Test Outlook',
            ccai__Named_Credential__c = 'OutlookGraphAPI',
            ccai__Connector_Class__c = 'OutlookDataSourceConnector'
        );
        insert ds;
        
        Map<String, Object> contactData = new Map<String, Object>{
            'Email' => 'test@example.com',
            'Name' => 'Test Contact'
        };
        String sfDataJson = JSON.serialize(contactData);
        
        // Set mock response with error
        Test.setMock(HttpCalloutMock.class, new OutlookGraphAPIMock(401, false));
        
        // Execute
        Test.startTest();
        OutlookDataSourceConnector connector = new OutlookDataSourceConnector();
        String result = connector.getExternalData(ds, sfDataJson);
        Test.stopTest();
        
        // Verify - should still return valid JSON
        System.assertNotEquals(null, result, 'Result should not be null');
        Map<String, Object> resultData = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assert(resultData.containsKey('OutlookEmails'), 'Should contain OutlookEmails key');
    }
    
    // Mock class for HTTP callouts
    private class OutlookGraphAPIMock implements HttpCalloutMock {
        private Integer statusCode;
        private Boolean hasEmails;
        
        public OutlookGraphAPIMock(Integer statusCode, Boolean hasEmails) {
            this.statusCode = statusCode;
            this.hasEmails = hasEmails;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setHeader('Content-Type', 'application/json');
            
            if (statusCode == 200) {
                if (hasEmails) {
                    res.setBody(getMockEmailResponse());
                } else {
                    res.setBody('{"value": []}');
                }
            } else {
                res.setBody('{"error": {"code": "Unauthorized", "message": "Invalid authentication token"}}');
            }
            
            return res;
        }
        
        private String getMockEmailResponse() {
            return '{"value": [' +
                '{' +
                    '"subject": "Q4 Portfolio Review",' +
                    '"from": {"emailAddress": {"address": "advisor@example.com"}},' +
                    '"toRecipients": [{"emailAddress": {"address": "test@example.com"}}],' +
                    '"receivedDateTime": "2024-10-15T10:30:00Z",' +
                    '"bodyPreview": "Thank you for the portfolio review discussion...",' +
                    '"importance": "normal",' +
                    '"hasAttachments": false' +
                '},' +
                '{' +
                    '"subject": "Re: Investment Strategy",' +
                    '"from": {"emailAddress": {"address": "test@example.com"}},' +
                    '"toRecipients": [{"emailAddress": {"address": "advisor@example.com"}}],' +
                    '"receivedDateTime": "2024-10-10T14:20:00Z",' +
                    '"bodyPreview": "I have some questions about the new strategy...",' +
                    '"importance": "high",' +
                    '"hasAttachments": true' +
                '},' +
                '{' +
                    '"subject": "Meeting Follow-up",' +
                    '"from": {"emailAddress": {"address": "advisor@example.com"}},' +
                    '"toRecipients": [{"emailAddress": {"address": "test@example.com"}}],' +
                    '"receivedDateTime": "2024-10-05T09:15:00Z",' +
                    '"bodyPreview": "Following up on our meeting last week...",' +
                    '"importance": "normal",' +
                    '"hasAttachments": false' +
                '}' +
            ']}';
        }
    }
}

