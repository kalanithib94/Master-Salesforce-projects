// ============================================================
// TEST GRAPH API CONNECTION AFTER TOKEN UPDATE
// Run this after updating the Named Credential with the new token
// ============================================================

System.debug('========================================');
System.debug('TESTING GRAPH API CONNECTION');
System.debug('========================================');

try {
    // Test 1: Simple connection test
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:OutlookGraphAPI/me');
    req.setMethod('GET');
    req.setTimeout(120000);
    
    Http http = new Http();
    HttpResponse res = http.send(req);
    
    System.debug('Status Code: ' + res.getStatusCode());
    System.debug('Status: ' + res.getStatus());
    
    if (res.getStatusCode() == 200) {
        System.debug('✅ SUCCESS: Graph API connection is working!');
        Map<String, Object> userData = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        System.debug('User: ' + userData.get('displayName'));
        System.debug('Email: ' + userData.get('mail'));
        System.debug('');
        
        // Test 2: Test fetching messages
        System.debug('========================================');
        System.debug('TESTING MESSAGE FETCH');
        System.debug('========================================');
        
        HttpRequest req2 = new HttpRequest();
        req2.setEndpoint('callout:OutlookGraphAPI/me/messages?$top=5');
        req2.setMethod('GET');
        req2.setTimeout(120000);
        
        HttpResponse res2 = http.send(req2);
        
        if (res2.getStatusCode() == 200) {
            Map<String, Object> messagesData = (Map<String, Object>) JSON.deserializeUntyped(res2.getBody());
            List<Object> messages = (List<Object>) messagesData.get('value');
            System.debug('✅ SUCCESS: Retrieved ' + (messages != null ? messages.size() : 0) + ' messages');
            
            if (messages != null && !messages.isEmpty()) {
                System.debug('');
                System.debug('Sample Messages:');
                for (Integer i = 0; i < Math.min(3, messages.size()); i++) {
                    Map<String, Object> msg = (Map<String, Object>) messages[i];
                    System.debug('  ' + (i+1) + '. Subject: ' + msg.get('subject'));
                    System.debug('     From: ' + ((Map<String, Object>) ((Map<String, Object>) msg.get('from')).get('emailAddress')).get('address'));
                }
            }
        } else {
            System.debug('❌ ERROR fetching messages: ' + res2.getStatusCode());
            System.debug('Response: ' + res2.getBody());
        }
        
    } else if (res.getStatusCode() == 401) {
        System.debug('❌ ERROR: 401 Unauthorized');
        System.debug('Response Body: ' + res.getBody());
        System.debug('');
        System.debug('The token in Named Credential may be:');
        System.debug('  - Expired (tokens last ~1 hour)');
        System.debug('  - Incorrectly formatted');
        System.debug('  - Missing "Bearer " prefix');
    } else {
        System.debug('❌ ERROR: ' + res.getStatusCode() + ' - ' + res.getStatus());
        System.debug('Response Body: ' + res.getBody());
    }
    
} catch (Exception e) {
    System.debug('❌ EXCEPTION: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}

System.debug('');
System.debug('========================================');
System.debug('TEST COMPLETE');
System.debug('========================================');

