// ============================================================
// TEST OUTLOOK DATA SOURCE CONNECTOR
// Copy and paste this into Developer Console → Execute Anonymous Window
// ============================================================

// Get a Contact to test with
Contact testContact = [SELECT Id, Name, Email FROM Contact WHERE Email != null LIMIT 1];
System.debug('========================================');
System.debug('TESTING WITH CONTACT:');
System.debug('  Name: ' + testContact.Name);
System.debug('  Email: ' + testContact.Email);
System.debug('========================================');

// Create the connector instance
OutlookDataSourceConnector connector = new OutlookDataSourceConnector();

// Prepare the Salesforce data (Contact information)
Map<String, Object> contactData = new Map<String, Object>{
    'Id' => testContact.Id,
    'Name' => testContact.Name,
    'Email' => testContact.Email
};

String sfDataJson = JSON.serialize(contactData);
System.debug('Input JSON: ' + sfDataJson);
System.debug('');

// Call the connector
try {
    System.debug('Calling getExternalData...');
    String result = connector.getExternalData(null, sfDataJson);
    
    // Parse the result
    Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped(result);
    Map<String, Object> outlookData = (Map<String, Object>) resultMap.get('OutlookEmails');
    
    System.debug('========================================');
    System.debug('RESULTS:');
    System.debug('========================================');
    
    if (outlookData != null) {
        Integer emailCount = (Integer) outlookData.get('count');
        Integer threadCount = (Integer) outlookData.get('threadCount');
        String summary = (String) outlookData.get('summary');
        String highlights = (String) outlookData.get('highlights');
        String topics = (String) outlookData.get('topics');
        
        System.debug('Total Emails: ' + emailCount);
        if (threadCount != null) {
            System.debug('Conversation Threads: ' + threadCount);
        }
        System.debug('Summary: ' + summary);
        System.debug('');
        System.debug('Highlights:');
        System.debug(highlights);
        System.debug('');
        System.debug('Topics: ' + topics);
        System.debug('');
        
        // Show detailed email breakdown
        List<Object> emails = (List<Object>) outlookData.get('emails');
        if (emails != null && !emails.isEmpty()) {
            System.debug('========================================');
            System.debug('DETAILED EMAIL BREAKDOWN (' + emails.size() + ' emails):');
            System.debug('========================================');
            
            Integer sentCount = 0;
            Integer receivedCount = 0;
            
            for (Object emailObj : emails) {
                Map<String, Object> email = (Map<String, Object>) emailObj;
                String subject = (String) email.get('subject');
                String fromEmail = '';
                try {
                    Map<String, Object> fromObj = (Map<String, Object>) email.get('from');
                    if (fromObj != null) {
                        Map<String, Object> emailAddr = (Map<String, Object>) fromObj.get('emailAddress');
                        if (emailAddr != null) {
                            fromEmail = (String) emailAddr.get('address');
                        }
                    }
                } catch (Exception e) {
                    fromEmail = 'Unknown';
                }
                
                String receivedDateTime = (String) email.get('receivedDateTime');
                String conversationId = (String) email.get('conversationId');
                Boolean partOfThread = (Boolean) email.get('partOfThread');
                Integer threadEmailCount = (Integer) email.get('threadEmailCount');
                
                // Count sent vs received
                if (fromEmail.equalsIgnoreCase(testContact.Email)) {
                    receivedCount++;
                } else {
                    sentCount++;
                }
                
                System.debug('  Subject: ' + subject);
                System.debug('  From: ' + fromEmail);
                System.debug('  Date: ' + receivedDateTime);
                if (partOfThread != null && partOfThread) {
                    System.debug('  Thread: Part of ' + threadEmailCount + ' email conversation');
                }
                System.debug('  Direction: ' + (fromEmail.equalsIgnoreCase(testContact.Email) ? 'RECEIVED (from contact)' : 'SENT (to contact)'));
                System.debug('  ---');
            }
            
            System.debug('');
            System.debug('========================================');
            System.debug('STATISTICS:');
            System.debug('========================================');
            System.debug('Total Emails: ' + emailCount);
            System.debug('  - Sent TO contact: ' + sentCount);
            System.debug('  - Received FROM contact: ' + receivedCount);
            
        } else {
            System.debug('No detailed email data available');
        }
        
        // Check for errors
        String error = (String) outlookData.get('error');
        if (String.isNotBlank(error)) {
            System.debug('');
            System.debug('⚠️ ERROR: ' + error);
        }
        
    } else {
        System.debug('❌ ERROR: No OutlookEmails data found in result');
    }
    
    System.debug('');
    System.debug('========================================');
    System.debug('FULL JSON RESULT:');
    System.debug('========================================');
    System.debug(result);
    
} catch (Exception e) {
    System.debug('❌ EXCEPTION: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}

