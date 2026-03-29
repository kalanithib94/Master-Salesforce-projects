// Check all emails in the mailbox
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:OutlookGraphAPI/me/messages?$top=10&$orderby=receivedDateTime%20desc');
req.setMethod('GET');
req.setTimeout(30000);

Http http = new Http();
HttpResponse res = http.send(req);

System.debug('==========================================');
System.debug('ALL EMAILS IN MAILBOX:');
System.debug('Status Code: ' + res.getStatusCode());

if (res.getStatusCode() == 200) {
    Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
    List<Object> messages = (List<Object>) responseData.get('value');
    
    System.debug('Total Messages Found: ' + (messages != null ? messages.size() : 0));
    System.debug('==========================================');
    
    if (messages != null && messages.size() > 0) {
        for (Integer i = 0; i < messages.size(); i++) {
            Map<String, Object> msg = (Map<String, Object>) messages[i];
            String subject = (String) msg.get('subject');
            String receivedDate = (String) msg.get('receivedDateTime');
            
            // Get TO recipients
            List<Object> toRecipients = (List<Object>) msg.get('toRecipients');
            String toEmail = '';
            if (toRecipients != null && toRecipients.size() > 0) {
                Map<String, Object> recipient = (Map<String, Object>) toRecipients[0];
                Map<String, Object> emailAddr = (Map<String, Object>) recipient.get('emailAddress');
                toEmail = (String) emailAddr.get('address');
            }
            
            System.debug((i+1) + '. Subject: ' + subject);
            System.debug('   To: ' + toEmail);
            System.debug('   Date: ' + receivedDate);
            System.debug('---');
        }
    }
    System.debug('==========================================');
} else {
    System.debug('Error: ' + res.getBody());
}

