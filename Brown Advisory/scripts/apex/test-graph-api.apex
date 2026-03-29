// Test Graph API Connection
System.debug('========================================');
System.debug('TESTING GRAPH API CONNECTION');
System.debug('========================================');

try {
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:OutlookGraphAPI/me');
    req.setMethod('GET');
    req.setTimeout(120000);
    
    Http http = new Http();
    HttpResponse res = http.send(req);
    
    System.debug('Status Code: ' + res.getStatusCode());
    System.debug('Status: ' + res.getStatus());
    
    if (res.getStatusCode() == 200) {
        System.debug('✅ SUCCESS: Graph API is accessible!');
        Map<String, Object> userData = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        System.debug('User: ' + userData.get('displayName'));
        System.debug('Email: ' + userData.get('mail'));
    } else if (res.getStatusCode() == 401) {
        System.debug('❌ ERROR: 401 Unauthorized');
        System.debug('Response Body: ' + res.getBody());
        System.debug('');
        System.debug('SOLUTION: Your access token has expired or is not configured.');
        System.debug('1. Go to Graph Explorer: https://developer.microsoft.com/en-us/graph/graph-explorer');
        System.debug('2. Sign in and get a new access token');
        System.debug('3. In Salesforce: Setup → Named Credentials → OutlookGraphAPI → Edit');
        System.debug('4. Update the "Custom Authorization Header" with: Bearer [NEW_TOKEN]');
    } else {
        System.debug('❌ ERROR: ' + res.getStatusCode() + ' - ' + res.getStatus());
        System.debug('Response Body: ' + res.getBody());
    }
    
} catch (Exception e) {
    System.debug('❌ EXCEPTION: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}

