global class OutlookDataSourceConnector implements ccai.AIDataSourceInterface {
    
    // Configuration
    private static final Integer DEFAULT_DAYS_BACK = 30;
    private static final Integer MAX_EMAILS = 50;
    private static final String GRAPH_ENDPOINT = 'callout:OutlookGraphAPI';
    
    /**
     * Main method to fetch external data from Outlook/Exchange
     * @param dataSource The AI Data Source configuration record
     * @param sfData JSON string containing Salesforce data (Contact, Account, etc.)
     * @return JSON string with email data
     */
    public String getExternalData(ccai__AI_Data_Source__c dataSource, String sfData) {
        try {
            // Parse incoming Salesforce data (Contact, Account, Entity, etc.)
            Map<String, Object> mainMap = (Map<String, Object>) JSON.deserializeUntyped(sfData);
            
            // Extract email addresses - handle both Contact and Entity objects
            List<String> emailAddresses = new List<String>();
            
            // Check for direct Email field (Contact object)
            String directEmail = (String) mainMap.get('Email');
            if (String.isNotBlank(directEmail)) {
                emailAddresses.add(directEmail);
            }
            
            // Check for related contacts (Entity/Account object)
            if (mainMap.containsKey('Contacts__r')) {
                List<Object> contacts = (List<Object>) mainMap.get('Contacts__r');
                if (contacts != null) {
                    for (Object contact : contacts) {
                        Map<String, Object> contactMap = (Map<String, Object>) contact;
                        String contactEmail = (String) contactMap.get('Email');
                        if (String.isNotBlank(contactEmail)) {
                            emailAddresses.add(contactEmail);
                        }
                    }
                }
            }
            
            // If no email addresses found
            if (emailAddresses.isEmpty()) {
                mainMap.put('OutlookEmails', new Map<String, Object>{
                    'count' => 0,
                    'summary' => 'No email addresses found in Contact or related Contacts',
                    'highlights' => 'Unable to retrieve emails',
                    'topics' => 'N/A',
                    'error' => 'No email address provided'
                });
                return JSON.serialize(mainMap);
            }
            
            // Fetch emails for all email addresses
            List<Map<String, Object>> allEmails = new List<Map<String, Object>>();
            Set<String> uniqueMessageIds = new Set<String>(); // Track unique emails
            
            for (String emailAddress : emailAddresses) {
                List<Map<String, Object>> emails = fetchEmails(emailAddress, DEFAULT_DAYS_BACK);
                
                // Add only unique emails (deduplicate by message ID)
                for (Map<String, Object> email : emails) {
                    String messageId = (String) email.get('id');
                    if (!uniqueMessageIds.contains(messageId)) {
                        uniqueMessageIds.add(messageId);
                        allEmails.add(email);
                    }
                }
            }
            
            // Build email intelligence from all emails
            String primaryEmail = emailAddresses[0]; // Use first email for context
            Map<String, Object> emailData = buildEmailIntelligence(allEmails, primaryEmail);
            
            // Add family context if multiple contacts
            if (emailAddresses.size() > 1) {
                emailData.put('familyMembersCount', emailAddresses.size());
                emailData.put('familyMembers', String.join(emailAddresses, '; '));
            }
            
            // Add email data to the existing Salesforce data (append, don't replace)
            mainMap.put('OutlookEmails', emailData);
            
            // Return merged data (Salesforce + Email intelligence)
            return JSON.serialize(mainMap);
            
        } catch (Exception e) {
            System.debug('Error in OutlookDataSourceConnector: ' + e.getMessage());
            // On error, still return the original data with error info
            Map<String, Object> mainMap = (Map<String, Object>) JSON.deserializeUntyped(sfData);
            mainMap.put('OutlookEmails', new Map<String, Object>{
                'count' => 0,
                'summary' => 'Error: ' + e.getMessage(),
                'highlights' => 'Unable to retrieve emails',
                'topics' => 'N/A',
                'error' => e.getMessage()
            });
            return JSON.serialize(mainMap);
        }
    }
    
    /**
     * Fetches emails from Microsoft Graph API
     */
    private List<Map<String, Object>> fetchEmails(String emailAddress, Integer daysBack) {
        List<Map<String, Object>> results = new List<Map<String, Object>>();
        
        try {
            // Calculate date range
            DateTime startDate = DateTime.now().addDays(-daysBack);
            String startDateStr = startDate.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
            
            // Build OData filter - search for emails sent TO this address
            // Simplified query to avoid encoding issues
            String filter = 'receivedDateTime ge ' + startDateStr;
            
            // Build query URL - including conversationId for thread rollup
            String endpoint = GRAPH_ENDPOINT + '/me/messages';
            endpoint += '?$filter=' + EncodingUtil.urlEncode(filter, 'UTF-8');
            endpoint += '&$select=subject,from,toRecipients,ccRecipients,receivedDateTime,bodyPreview,importance,hasAttachments,conversationId';
            endpoint += '&$top=100'; // Fetch more to capture full threads
            
            // Make callout
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            req.setTimeout(120000);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                List<Object> messages = (List<Object>) responseData.get('value');
                
                // Track matching conversation IDs for thread rollup
                Set<String> matchingConversationIds = new Set<String>();
                Map<String, List<Map<String, Object>>> emailsByConversation = new Map<String, List<Map<String, Object>>>();
                
                if (messages != null) {
                    // First pass: Group all emails by conversation and identify matches
                    for (Object msg : messages) {
                        Map<String, Object> msgMap = (Map<String, Object>) msg;
                        
                        // Get subject and sender for filtering
                        String subject = (String) msgMap.get('subject');
                        String fromEmail = extractEmailAddress(msgMap.get('from'));
                        String conversationId = (String) msgMap.get('conversationId');
                        
                        // Skip bounce/undeliverable messages
                        if (isBounceMessage(subject, fromEmail)) {
                            continue;
                        }
                        
                        // Group all emails by conversation ID
                        if (String.isNotBlank(conversationId)) {
                            if (!emailsByConversation.containsKey(conversationId)) {
                                emailsByConversation.put(conversationId, new List<Map<String, Object>>());
                            }
                            emailsByConversation.get(conversationId).add(msgMap);
                        }
                        
                        // Check if email matches contact (TO, FROM, or CC)
                        Boolean matchesEmail = checkEmailMatch(msgMap, emailAddress);
                        
                        // If this email matches, mark its entire conversation for inclusion (THREAD ROLLUP)
                        if (matchesEmail && String.isNotBlank(conversationId)) {
                            matchingConversationIds.add(conversationId);
                        }
                    }
                    
                    // Second pass: Add ALL emails from matching conversations (full thread rollup)
                    for (String conversationId : matchingConversationIds) {
                        if (emailsByConversation.containsKey(conversationId)) {
                            List<Map<String, Object>> threadEmails = emailsByConversation.get(conversationId);
                            for (Map<String, Object> threadEmail : threadEmails) {
                                // Mark emails as part of a rolled-up thread
                                threadEmail.put('partOfThread', true);
                                threadEmail.put('threadEmailCount', threadEmails.size());
                                results.add(threadEmail);
                                
                                // Limit total results
                                if (results.size() >= MAX_EMAILS) {
                                    break;
                                }
                            }
                            if (results.size() >= MAX_EMAILS) {
                                break;
                            }
                        }
                    }
                }
            } else {
                System.debug('Graph API Error: ' + res.getStatusCode() + ' - ' + res.getBody());
            }
            
        } catch (Exception e) {
            System.debug('Error fetching emails: ' + e.getMessage());
        }
        
        return results;
    }
    
    /**
     * Checks if an email matches the contact in TO, FROM, or CC fields
     */
    private Boolean checkEmailMatch(Map<String, Object> msgMap, String emailAddress) {
        String fromEmail = extractEmailAddress(msgMap.get('from'));
        
        // Check FROM field (for replies from contact)
        if (fromEmail != null && fromEmail.equalsIgnoreCase(emailAddress)) {
            return true;
        }
        
        // Check TO recipients (for emails sent to contact)
        List<Object> toRecipients = (List<Object>) msgMap.get('toRecipients');
        if (toRecipients != null) {
            for (Object recipient : toRecipients) {
                Map<String, Object> recipientMap = (Map<String, Object>) recipient;
                Map<String, Object> emailAddrMap = (Map<String, Object>) recipientMap.get('emailAddress');
                if (emailAddrMap != null) {
                    String toEmail = (String) emailAddrMap.get('address');
                    if (toEmail != null && toEmail.equalsIgnoreCase(emailAddress)) {
                        return true;
                    }
                }
            }
        }
        
        // Check CC recipients (contact might be CC'd)
        List<Object> ccRecipients = (List<Object>) msgMap.get('ccRecipients');
        if (ccRecipients != null) {
            for (Object recipient : ccRecipients) {
                Map<String, Object> recipientMap = (Map<String, Object>) recipient;
                Map<String, Object> emailAddrMap = (Map<String, Object>) recipientMap.get('emailAddress');
                if (emailAddrMap != null) {
                    String ccEmail = (String) emailAddrMap.get('address');
                    if (ccEmail != null && ccEmail.equalsIgnoreCase(emailAddress)) {
                        return true;
                    }
                }
            }
        }
        
        return false;
    }
    
    /**
     * Builds email intelligence from raw email data
     */
    private Map<String, Object> buildEmailIntelligence(List<Map<String, Object>> emails, String contactEmail) {
        Map<String, Object> intelligence = new Map<String, Object>();
        
        Integer emailCount = emails.size();
        intelligence.put('count', emailCount);
        
        if (emailCount == 0) {
            intelligence.put('summary', 'No recent emails found in the last ' + DEFAULT_DAYS_BACK + ' days');
            intelligence.put('highlights', 'No email activity');
            intelligence.put('topics', 'No topics discussed');
            return intelligence;
        }
        
        // Count unique threads
        Set<String> uniqueThreads = new Set<String>();
        for (Map<String, Object> email : emails) {
            String conversationId = (String) email.get('conversationId');
            if (String.isNotBlank(conversationId)) {
                uniqueThreads.add(conversationId);
            }
        }
        
        // Build summary with thread information
        String lastEmailDate = '';
        if (!emails.isEmpty()) {
            Map<String, Object> lastEmail = emails[0];
            lastEmailDate = (String) lastEmail.get('receivedDateTime');
        }
        
        String summary = 'Found ' + emailCount + ' email';
        if (emailCount > 1) {
            summary += 's';
        }
        summary += ' across ' + uniqueThreads.size() + ' conversation thread';
        if (uniqueThreads.size() != 1) {
            summary += 's';
        }
        summary += ' from the last ' + DEFAULT_DAYS_BACK + ' days';
        if (String.isNotBlank(lastEmailDate)) {
            summary += '. Most recent: ' + formatDate(lastEmailDate);
        }
        intelligence.put('summary', summary);
        intelligence.put('threadCount', uniqueThreads.size());
        
        // Extract highlights (recent email subjects)
        List<String> highlights = new List<String>();
        Integer highlightCount = Math.min(5, emailCount);
        for (Integer i = 0; i < highlightCount; i++) {
            Map<String, Object> email = emails[i];
            String subject = (String) email.get('subject');
            String emailDate = formatDate((String) email.get('receivedDateTime'));
            String fromEmail = extractEmailAddress(email.get('from'));
            
            String highlight = '• ' + emailDate + ': "' + subject + '"';
            if (fromEmail.equalsIgnoreCase(contactEmail)) {
                highlight += ' (from contact)';
            } else {
                highlight += ' (to contact)';
            }
            highlights.add(highlight);
        }
        intelligence.put('highlights', String.join(highlights, '\n'));
        
        // Extract topics (keywords from subjects and body previews)
        Set<String> topics = new Set<String>();
        for (Map<String, Object> email : emails) {
            String subject = (String) email.get('subject');
            String bodyPreview = (String) email.get('bodyPreview');
            
            if (String.isNotBlank(subject)) {
                // Extract meaningful words from subject
                topics.addAll(extractKeywords(subject));
            }
        }
        
        List<String> topicsList = new List<String>(topics);
        if (topicsList.size() > 10) {
            topicsList = new List<String>();
            for (Integer i = 0; i < 10; i++) {
                topicsList.add(new List<String>(topics)[i]);
            }
        }
        
        String topicsStr = topicsList.isEmpty() ? 'No specific topics identified' : String.join(topicsList, ', ');
        intelligence.put('topics', topicsStr);
        
        // Add raw email data for reference
        intelligence.put('emails', emails);
        
        return intelligence;
    }
    
    /**
     * Extracts email address from Graph API email object
     */
    private String extractEmailAddress(Object emailObj) {
        if (emailObj == null) {
            return '';
        }
        
        try {
            Map<String, Object> emailData = (Map<String, Object>) emailObj;
            Map<String, Object> emailAddress = (Map<String, Object>) emailData.get('emailAddress');
            return (String) emailAddress.get('address');
        } catch (Exception e) {
            return '';
        }
    }
    
    /**
     * Formats ISO date to readable format
     */
    private String formatDate(String isoDate) {
        if (String.isBlank(isoDate)) {
            return '';
        }
        
        try {
            DateTime dt = DateTime.valueOfGmt(isoDate.replace('T', ' ').replace('Z', ''));
            return dt.format('MMM d, yyyy');
        } catch (Exception e) {
            return isoDate.substring(0, 10);
        }
    }
    
    /**
     * Checks if a message is a bounce/undeliverable notification
     */
    private Boolean isBounceMessage(String subject, String fromEmail) {
        if (String.isBlank(subject) || String.isBlank(fromEmail)) {
            return false;
        }
        
        // Check subject for bounce indicators
        String subjectLower = subject.toLowerCase();
        if (subjectLower.startsWith('undeliverable:') ||
            subjectLower.startsWith('delivery status notification') ||
            subjectLower.startsWith('mail delivery failed') ||
            subjectLower.startsWith('returned mail:') ||
            subjectLower.startsWith('delivery failure') ||
            subjectLower.contains('message not delivered')) {
            return true;
        }
        
        // Check sender for system/automated addresses
        String fromEmailLower = fromEmail.toLowerCase();
        if (fromEmailLower.contains('postmaster@') ||
            fromEmailLower.contains('mailer-daemon@') ||
            fromEmailLower.contains('noreply@') ||
            fromEmailLower.startsWith('no-reply@') ||
            fromEmailLower.contains('do-not-reply@')) {
            return true;
        }
        
        return false;
    }
    
    /**
     * Extracts keywords from text
     */
    private Set<String> extractKeywords(String text) {
        Set<String> keywords = new Set<String>();
        
        if (String.isBlank(text)) {
            return keywords;
        }
        
        // Common stop words to ignore
        Set<String> stopWords = new Set<String>{
            'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
            'of', 'with', 'by', 'from', 're', 'fw', 'fwd', 'is', 'are', 'was', 'were'
        };
        
        // Split and clean
        List<String> words = text.toLowerCase().split('[^a-z0-9]+');
        for (String word : words) {
            if (String.isNotBlank(word) && word.length() > 3 && !stopWords.contains(word)) {
                keywords.add(word.capitalize());
            }
        }
        
        return keywords;
    }
    
}

