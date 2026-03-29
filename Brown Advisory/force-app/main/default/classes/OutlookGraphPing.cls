public class OutlookGraphPing {
    
    public class PingResult {
        public String status;
        public String message;
        public String responseBody;
        public Integer statusCode;
        
        public PingResult(String status, String message, String responseBody, Integer statusCode) {
            this.status = status;
            this.message = message;
            this.responseBody = responseBody;
            this.statusCode = statusCode;
        }
    }
    
    /**
     * Tests connectivity to Microsoft Graph API
     * @return PingResult with status and details
     */
    public static PingResult ping() {
        try {
            // Simple ping to get messages (just top 1)
            String endpoint = 'callout:OutlookGraphAPI/me/messages?$top=1';
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setTimeout(30000);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            Integer statusCode = res.getStatusCode();
            String responseBody = res.getBody();
            
            if (statusCode == 200) {
                // Parse response to check if we got data
                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                List<Object> messages = (List<Object>) responseData.get('value');
                
                String message = 'Successfully retrieved messages. Count: ';
                if (messages != null) {
                    message += messages.size();
                } else {
                    message += '0';
                }
                
                return new PingResult('OK_' + statusCode, message, responseBody, statusCode);
            } else if (statusCode == 401) {
                return new PingResult('UNAUTHORIZED_' + statusCode, 
                    'Authentication failed. Token may be expired or invalid.', 
                    responseBody, 
                    statusCode);
            } else {
                return new PingResult('ERROR_' + statusCode, 
                    'Graph API returned error: ' + statusCode, 
                    responseBody, 
                    statusCode);
            }
            
        } catch (System.CalloutException e) {
            return new PingResult('CALLOUT_EXCEPTION', 
                'Callout failed: ' + e.getMessage() + '. Check Named Credential and Remote Site Settings.', 
                null, 
                0);
        } catch (Exception e) {
            return new PingResult('EXCEPTION', 
                'Unexpected error: ' + e.getMessage(), 
                null, 
                0);
        }
    }
    
    /**
     * Simple test method that can be called from Execute Anonymous
     */
    public static void test() {
        PingResult result = ping();
        System.debug('=== Outlook Graph API Ping Test ===');
        System.debug('Status: ' + result.status);
        System.debug('Status Code: ' + result.statusCode);
        System.debug('Message: ' + result.message);
        System.debug('Response Body: ' + result.responseBody);
        System.debug('===================================');
    }
}

