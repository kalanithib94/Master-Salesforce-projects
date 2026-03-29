/**
 * @description Invocable Apex class to process meeting transcripts from voice recordings
 * Identifies contacts, creates tasks, manages opportunities, and provides follow-up suggestions
 * @author Brown Advisory
 * @date 2025
 */
public with sharing class MeetingTranscriptProcessor {
    
    /**
     * @description Wrapper class for input parameters from Flow
     */
    public class ProcessRequest {
        @InvocableVariable(label='Event Id' description='The Id of the Event record created from the transcript' required=true)
        public Id eventId;
        
        @InvocableVariable(label='LLM Parsed Data' description='JSON string with parsed data from LLM (optional)' required=false)
        public String llmParsedData;
    }
    
    /**
     * @description Wrapper class for output results to Flow
     */
    public class ProcessResult {
        @InvocableVariable(label='Success' description='Whether processing was successful')
        public Boolean isSuccess;
        
        @InvocableVariable(label='Contact Id' description='The Id of the identified/matched Contact')
        public Id contactId;
        
        @InvocableVariable(label='Task Id' description='The Id of the created Task')
        public Id taskId;
        
        @InvocableVariable(label='Opportunity Id' description='The Id of the created/updated Opportunity')
        public Id opportunityId;
        
        @InvocableVariable(label='Follow-Up Suggestions' description='AI-generated follow-up suggestions')
        public String followUpSuggestions;
        
        @InvocableVariable(label='Error Message' description='Error message if processing failed')
        public String errorMessage;
    }
    
    /**
     * @description Data structure for parsed meeting information
     */
    public class MeetingData {
        public String contactName;
        public String eventName;
        public List<String> interests;
        public String timeline;
        public Date estimatedCloseDate;
        public String referralSource;
        public String opportunityType;
        public String meetingContext;
    }
    
    /**
     * @description Main invocable method called from Flow
     * @param requests List of ProcessRequest objects
     * @return List of ProcessResult objects
     */
    @InvocableMethod(label='Process Meeting Transcript' description='Processes transcript to identify contact, create task, and manage opportunity')
    public static List<ProcessResult> processMeetingTranscript(List<ProcessRequest> requests) {
        List<ProcessResult> results = new List<ProcessResult>();
        
        for (ProcessRequest request : requests) {
            ProcessResult result = new ProcessResult();
            result.isSuccess = false;
            
            try {
                // Get the Event record with description (transcript)
                Event evt = getEventRecord(request.eventId);
                
                // Validate that event has description
                if (String.isBlank(evt.Description)) {
                    result.errorMessage = 'Event Description (transcript) cannot be empty';
                    results.add(result);
                    continue;
                }
                
                // Parse the transcript from Event Description
                MeetingData meetingData = parseTranscript(evt.Description, request.llmParsedData);
                
                // Get or create Account from Event
                Id accountId = getOrCreateAccountFromEvent(evt, meetingData);
                
                // Identify and match contact
                Contact identifiedContact = identifyContact(meetingData, evt, accountId);
                
                // If contact not found, create new one under the Account
                if (identifiedContact == null && String.isNotBlank(meetingData.contactName)) {
                    identifiedContact = createNewContact(meetingData, accountId);
                }
                
                if (identifiedContact != null) {
                    result.contactId = identifiedContact.Id;
                    
                    // Link Event to both Contact and Account
                    linkEventToContactAndAccount(request.eventId, identifiedContact.Id, accountId);
                    
                    // Create Task under Contact and Account
                    result.taskId = createFollowUpTask(identifiedContact.Id, accountId, meetingData);
                    
                    // Create or Update Opportunity
                    result.opportunityId = createOrUpdateOpportunity(identifiedContact.Id, accountId, meetingData);
                    
                    // Generate follow-up suggestions
                    result.followUpSuggestions = generateFollowUpSuggestions(meetingData);
                    
                    result.isSuccess = true;
                } else {
                    result.errorMessage = 'Could not identify or create contact from transcript. Unable to parse contact name.';
                }
                
            } catch (Exception e) {
                result.errorMessage = 'Error processing transcript: ' + e.getMessage();
                System.debug('Error in processMeetingTranscript: ' + e.getMessage() + '\n' + e.getStackTraceString());
            }
            
            results.add(result);
        }
        
        return results;
    }
    
    /**
     * @description Parse transcript to extract structured data
     * @param transcript The raw transcript text
     * @param llmParsedData Optional pre-parsed JSON from LLM
     * @return MeetingData object with extracted information
     */
    private static MeetingData parseTranscript(String transcript, String llmParsedData) {
        MeetingData data = new MeetingData();
        
        // If LLM already parsed the data, use it
        if (String.isNotBlank(llmParsedData)) {
            try {
                Map<String, Object> parsedMap = (Map<String, Object>) JSON.deserializeUntyped(llmParsedData);
                data.contactName = (String) parsedMap.get('contactName');
                data.eventName = (String) parsedMap.get('eventName');
                data.interests = (List<String>) parsedMap.get('interests');
                data.timeline = (String) parsedMap.get('timeline');
                data.referralSource = (String) parsedMap.get('referralSource');
                data.opportunityType = (String) parsedMap.get('opportunityType');
                data.meetingContext = (String) parsedMap.get('meetingContext');
                
                // Parse close date if available
                if (parsedMap.containsKey('estimatedCloseDate')) {
                    String closeDateStr = (String) parsedMap.get('estimatedCloseDate');
                    data.estimatedCloseDate = parseCloseDate(closeDateStr);
                }
                
                return data;
            } catch (Exception e) {
                System.debug('Error parsing LLM data, falling back to manual parsing: ' + e.getMessage());
            }
        }
        
        // Manual parsing as fallback
        data.contactName = extractContactName(transcript);
        data.eventName = extractEventName(transcript);
        data.interests = extractInterests(transcript);
        data.timeline = extractTimeline(transcript);
        data.estimatedCloseDate = extractCloseDate(transcript);
        data.referralSource = extractReferralSource(transcript);
        data.opportunityType = extractOpportunityType(transcript);
        data.meetingContext = transcript.left(5000); // Store first 5000 chars as context
        
        return data;
    }
    
    /**
     * @description Extract contact name from transcript
     * Handles format: "Contact: Name" or "Contact: Not specified"
     */
    private static String extractContactName(String transcript) {
        // Try "Contact: [Name]" format (from LLM structured output)
        Pattern colonPattern = Pattern.compile('(?i)Contact:\\s*([^\\n]+)');
        Matcher colonMatcher = colonPattern.matcher(transcript);
        if (colonMatcher.find()) {
            String contactName = colonMatcher.group(1).trim();
            // Ignore if blank or "Not specified"
            if (String.isNotBlank(contactName) && 
                !contactName.equalsIgnoreCase('Not specified') &&
                !contactName.equalsIgnoreCase('Not Specified')) {
                return contactName;
            }
        }
        
        // Fallback: Pattern "Met with [Name]" or "Meeting with [Name]"
        Pattern p = Pattern.compile('(?i)met with ([A-Z][a-z]+ [A-Z][a-z]+)');
        Matcher m = p.matcher(transcript);
        if (m.find()) {
            return m.group(1);
        }
        return null;
    }
    
    /**
     * @description Extract event name from transcript
     * Handles format: "Event: Name" or "Event: Not specified"
     */
    private static String extractEventName(String transcript) {
        // Try "Event: [Name]" format (from LLM structured output)
        Pattern colonPattern = Pattern.compile('(?i)Event:\\s*([^\\n]+)');
        Matcher colonMatcher = colonPattern.matcher(transcript);
        if (colonMatcher.find()) {
            String eventName = colonMatcher.group(1).trim();
            // Ignore if blank or "Not specified"
            if (String.isNotBlank(eventName) && 
                !eventName.equalsIgnoreCase('Not specified') &&
                !eventName.equalsIgnoreCase('Not Specified')) {
                return eventName;
            }
        }
        
        // Fallback: Pattern "at the [Event]"
        Pattern p = Pattern.compile('(?i)at the ([A-Z][\\w\\s]+Summit|[A-Z][\\w\\s]+Conference|[A-Z][\\w\\s]+Meeting)');
        Matcher m = p.matcher(transcript);
        if (m.find()) {
            return m.group(1);
        }
        return null;
    }
    
    /**
     * @description Extract interests/topics from transcript
     * Handles format: "Interests: Topic1, Topic2" or "Interests: Not specified"
     */
    private static List<String> extractInterests(String transcript) {
        List<String> interests = new List<String>();
        
        // Try "Interests: [Topics]" format (from LLM structured output)
        Pattern colonPattern = Pattern.compile('(?i)Interests?:\\s*([^\\n]+)');
        Matcher colonMatcher = colonPattern.matcher(transcript);
        if (colonMatcher.find()) {
            String interestsText = colonMatcher.group(1).trim();
            // Ignore if blank or "Not specified"
            if (String.isNotBlank(interestsText) && 
                !interestsText.equalsIgnoreCase('Not specified') &&
                !interestsText.equalsIgnoreCase('Not Specified')) {
                // Split by comma and clean up
                List<String> parts = interestsText.split(',');
                for (String part : parts) {
                    String cleaned = part.trim();
                    if (String.isNotBlank(cleaned)) {
                        interests.add(cleaned);
                    }
                }
                if (!interests.isEmpty()) {
                    return interests;
                }
            }
        }
        
        // Fallback: Search for common investment topics
        String lowerTranscript = transcript.toLowerCase();
        if (lowerTranscript.contains('impact investing')) {
            interests.add('Impact Investing');
        }
        if (lowerTranscript.contains('climate tech')) {
            interests.add('Climate Tech');
        }
        if (lowerTranscript.contains('direct deal')) {
            interests.add('Direct Deals');
        }
        if (lowerTranscript.contains('private equity')) {
            interests.add('Private Equity');
        }
        if (lowerTranscript.contains('venture capital')) {
            interests.add('Venture Capital');
        }
        if (lowerTranscript.contains('esg')) {
            interests.add('ESG');
        }
        
        return interests;
    }
    
    /**
     * @description Extract timeline from transcript
     * Handles format: "Timeline: Q2 2026" or "Timeline: Not specified"
     */
    private static String extractTimeline(String transcript) {
        // Try "Timeline: [Date]" format (from LLM structured output)
        Pattern colonPattern = Pattern.compile('(?i)Timeline:\\s*([^\\n]+)');
        Matcher colonMatcher = colonPattern.matcher(transcript);
        if (colonMatcher.find()) {
            String timeline = colonMatcher.group(1).trim();
            // Ignore if blank or "Not specified"
            if (String.isNotBlank(timeline) && 
                !timeline.equalsIgnoreCase('Not specified') &&
                !timeline.equalsIgnoreCase('Not Specified')) {
                return timeline;
            }
        }
        
        // Fallback: Search for Q1-Q4 2024 or Month 2024 format
        Pattern p = Pattern.compile('(?i)(Q[1-4]\\s*\\d{4}|[A-Z][a-z]+\\s*\\d{4})');
        Matcher m = p.matcher(transcript);
        if (m.find()) {
            return m.group(1);
        }
        return null;
    }
    
    /**
     * @description Extract and parse close date from timeline
     */
    private static Date extractCloseDate(String transcript) {
        String timeline = extractTimeline(transcript);
        return parseCloseDate(timeline);
    }
    
    /**
     * @description Parse close date from timeline string
     */
    private static Date parseCloseDate(String timeline) {
        if (String.isBlank(timeline)) return null;
        
        try {
            // Parse Q1-Q4 2024 format
            Pattern p = Pattern.compile('Q([1-4])\\s*(\\d{4})');
            Matcher m = p.matcher(timeline);
            if (m.find()) {
                Integer quarter = Integer.valueOf(m.group(1));
                Integer year = Integer.valueOf(m.group(2));
                Integer month = (quarter * 3); // End of quarter
                return Date.newInstance(year, month, 1).addMonths(1).addDays(-1);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Error parsing close date: ' + e.getMessage());
        }
        
        return null;
    }
    
    /**
     * @description Extract referral source from transcript
     * Handles format: "Referral: Name" or "Referral: Not specified"
     */
    private static String extractReferralSource(String transcript) {
        // Try "Referral: [Name]" format (from LLM structured output)
        Pattern colonPattern = Pattern.compile('(?i)Referral:\\s*([^\\n]+)');
        Matcher colonMatcher = colonPattern.matcher(transcript);
        if (colonMatcher.find()) {
            String referral = colonMatcher.group(1).trim();
            // Ignore if blank or "Not specified"
            if (String.isNotBlank(referral) && 
                !referral.equalsIgnoreCase('Not specified') &&
                !referral.equalsIgnoreCase('Not Specified')) {
                return referral;
            }
        }
        
        // Fallback: Pattern "referred by [Name]"
        Pattern p = Pattern.compile('(?i)referred by ([A-Z][a-z]+ [A-Z][a-z]+)');
        Matcher m = p.matcher(transcript);
        if (m.find()) {
            return m.group(1);
        }
        return null;
    }
    
    /**
     * @description Extract opportunity type from transcript
     * Handles format: "Opportunity: Type" or "Opportunity: Not specified"
     */
    private static String extractOpportunityType(String transcript) {
        // Try "Opportunity: [Type]" format (from LLM structured output)
        Pattern colonPattern = Pattern.compile('(?i)Opportunity:\\s*([^\\n]+)');
        Matcher colonMatcher = colonPattern.matcher(transcript);
        if (colonMatcher.find()) {
            String oppType = colonMatcher.group(1).trim();
            // Ignore if blank or "Not specified"
            if (String.isNotBlank(oppType) && 
                !oppType.equalsIgnoreCase('Not specified') &&
                !oppType.equalsIgnoreCase('Not Specified')) {
                return oppType;
            }
        }
        
        // Fallback: Search for keywords
        String lowerTranscript = transcript.toLowerCase();
        if (lowerTranscript.contains('direct deal')) {
            return 'Direct deal exploration';
        }
        if (lowerTranscript.contains('fund investment')) {
            return 'Fund Investment';
        }
        if (lowerTranscript.contains('co-investment')) {
            return 'Co-Investment';
        }
        return 'New Business';
    }
    
    /**
     * @description Get Event record
     */
    private static Event getEventRecord(Id eventId) {
        return [SELECT Id, Subject, StartDateTime, WhoId, WhatId, Description 
                FROM Event 
                WHERE Id = :eventId 
                LIMIT 1];
    }
    
    /**
     * @description Get or create Account from Event
     * If Event already has WhatId (Account), use that
     * Otherwise create new Account based on contact name
     */
    private static Id getOrCreateAccountFromEvent(Event evt, MeetingData meetingData) {
        // Check if Event already has an Account linked
        if (evt.WhatId != null) {
            try {
                // Verify it's an Account (not another object type)
                Account existingAccount = [SELECT Id, Name FROM Account WHERE Id = :evt.WhatId LIMIT 1];
                System.debug('Using existing Account from Event: ' + existingAccount.Name);
                return existingAccount.Id;
            } catch (Exception e) {
                System.debug('WhatId is not an Account, will create new Account');
            }
        }
        
        // Create new Account
        String accountName = 'Family Office';
        if (String.isNotBlank(meetingData.contactName)) {
            // Extract last name for account
            String lastName = meetingData.contactName;
            if (meetingData.contactName.contains(' ')) {
                List<String> nameParts = meetingData.contactName.split(' ');
                lastName = nameParts[nameParts.size() - 1]; // Get last part
            }
            accountName = lastName + ' Family Office';
        }
        
        Account newAccount = new Account(Name = accountName);
        insert newAccount;
        System.debug('Created new Account: ' + accountName);
        
        return newAccount.Id;
    }
    
    /**
     * @description Identify and match contact from meeting data
     * @param meetingData Parsed meeting information
     * @param evt Event record
     * @param accountId Account to search within (preferred)
     * @return Found Contact or null
     */
    private static Contact identifyContact(MeetingData meetingData, Event evt, Id accountId) {
        // First check if Event already has a contact linked
        if (evt.WhoId != null) {
            try {
                return [SELECT Id, Name, AccountId FROM Contact WHERE Id = :evt.WhoId LIMIT 1];
            } catch (Exception e) {
                System.debug('Contact from Event not found: ' + e.getMessage());
            }
        }
        
        // Search by name from parsed data, prioritize within the Account
        if (String.isNotBlank(meetingData.contactName)) {
            String searchName = '%' + meetingData.contactName + '%';
            
            // First try to find contact within the Account (case-insensitive)
            List<Contact> contactsInAccount = [SELECT Id, Name, AccountId 
                                               FROM Contact 
                                               WHERE AccountId = :accountId
                                               AND (Name LIKE :searchName 
                                                    OR FirstName LIKE :searchName 
                                                    OR LastName LIKE :searchName)
                                               LIMIT 1];
            if (!contactsInAccount.isEmpty()) {
                System.debug('Found existing Contact in Account: ' + contactsInAccount[0].Name);
                return contactsInAccount[0];
            }
            
            // If not found in Account, search globally
            List<Contact> contacts = [SELECT Id, Name, AccountId 
                                     FROM Contact 
                                     WHERE Name LIKE :searchName 
                                     OR FirstName LIKE :searchName 
                                     OR LastName LIKE :searchName
                                     LIMIT 1];
            if (!contacts.isEmpty()) {
                System.debug('Found existing Contact globally: ' + contacts[0].Name);
                return contacts[0];
            }
            
            System.debug('No existing Contact found for: ' + meetingData.contactName);
        }
        
        return null;
    }
    
    /**
     * @description Create new Contact when not found in Salesforce
     * @param meetingData Parsed meeting information
     * @param accountId Account to link Contact to
     * @return Newly created Contact
     */
    private static Contact createNewContact(MeetingData meetingData, Id accountId) {
        try {
            // Parse first and last name
            String firstName = '';
            String lastName = meetingData.contactName;
            
            if (meetingData.contactName.contains(' ')) {
                List<String> nameParts = meetingData.contactName.split(' ');
                if (nameParts.size() >= 2) {
                    firstName = nameParts[0];
                    // Build lastName from remaining parts
                    List<String> lastNameParts = new List<String>();
                    for (Integer i = 1; i < nameParts.size(); i++) {
                        lastNameParts.add(nameParts[i]);
                    }
                    lastName = String.join(lastNameParts, ' ');
                }
            }
            
            // Create Contact under the provided Account
            Contact newContact = new Contact(
                FirstName = firstName,
                LastName = lastName,
                AccountId = accountId,
                Description = 'Auto-created from voice meeting transcript. Event: ' + meetingData.eventName
            );
            
            insert newContact;
            
            System.debug('Created new Contact: ' + newContact.FirstName + ' ' + newContact.LastName + ' (ID: ' + newContact.Id + ') under Account: ' + accountId);
            
            return newContact;
            
        } catch (Exception e) {
            System.debug('Error creating new contact: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Link Event to Contact and Account
     * @param eventId Event record ID
     * @param contactId Contact record ID
     * @param accountId Account record ID
     */
    private static void linkEventToContactAndAccount(Id eventId, Id contactId, Id accountId) {
        Event evt = new Event(
            Id = eventId, 
            WhoId = contactId,  // Link to Contact (shows on Contact's Activity History)
            WhatId = accountId  // Link to Account (shows on Account's Activity History)
        );
        update evt;
        System.debug('Linked Event to Contact: ' + contactId + ' and Account: ' + accountId);
    }
    
    /**
     * @description Create follow-up task under contact and account
     * @param contactId Contact record ID
     * @param accountId Account record ID
     * @param meetingData Parsed meeting information
     * @return Task ID
     */
    private static Id createFollowUpTask(Id contactId, Id accountId, MeetingData meetingData) {
        System.debug('Creating task - ContactId: ' + contactId + ', AccountId: ' + accountId);
        
        Task followUpTask = new Task();
        followUpTask.WhoId = contactId;  // Related To Contact
        followUpTask.WhatId = accountId;  // Related To Account (shows on Account)
        followUpTask.Subject = 'Follow-up: ' + (meetingData.eventName != null ? meetingData.eventName : 'Meeting Discussion');
        followUpTask.Status = 'Not Started';
        followUpTask.Priority = 'High';
        followUpTask.ActivityDate = Date.today().addDays(7); // Due in 7 days
        
        // Build description
        String description = 'Follow-up from meeting discussion.\n\n';
        if (!meetingData.interests.isEmpty()) {
            description += 'Topics of Interest: ' + String.join(meetingData.interests, ', ') + '\n';
        }
        if (String.isNotBlank(meetingData.referralSource)) {
            description += 'Referred by: ' + meetingData.referralSource + '\n';
        }
        if (String.isNotBlank(meetingData.timeline)) {
            description += 'Timeline: ' + meetingData.timeline + '\n';
        }
        
        followUpTask.Description = description;
        
        insert followUpTask;
        
        System.debug('Task created successfully - ID: ' + followUpTask.Id + ', WhoId: ' + followUpTask.WhoId + ', WhatId: ' + followUpTask.WhatId);
        
        return followUpTask.Id;
    }
    
    /**
     * @description Create or update opportunity
     * @param contactId Contact record ID
     * @param accountId Account record ID
     * @param meetingData Parsed meeting information
     * @return Opportunity ID
     */
    private static Id createOrUpdateOpportunity(Id contactId, Id accountId, MeetingData meetingData) {
        Contact con = [SELECT Id, AccountId FROM Contact WHERE Id = :contactId LIMIT 1];
        
        // Get opportunity IDs from contact roles
        Set<Id> oppIdsFromContactRole = new Set<Id>();
        for (OpportunityContactRole ocr : [SELECT OpportunityId FROM OpportunityContactRole WHERE ContactId = :contactId]) {
            oppIdsFromContactRole.add(ocr.OpportunityId);
        }
        
        // Check if there's an existing open opportunity for this contact/account
        List<Opportunity> existingOpps = [SELECT Id, Name, StageName, CloseDate 
                                          FROM Opportunity 
                                          WHERE (AccountId = :accountId OR Id IN :oppIdsFromContactRole)
                                          AND IsClosed = false
                                          ORDER BY CreatedDate DESC
                                          LIMIT 1];
        
        Opportunity opp;
        Boolean isNewOpp = existingOpps.isEmpty();
        
        if (isNewOpp) {
            // Create new opportunity under the Account
            opp = new Opportunity();
            opp.Name = (meetingData.contactName != null ? meetingData.contactName + ' - ' : '') + 
                       (meetingData.opportunityType != null ? meetingData.opportunityType : 'New Business Opportunity');
            opp.AccountId = accountId;
            opp.StageName = 'Qualification';
            opp.CloseDate = meetingData.estimatedCloseDate != null ? meetingData.estimatedCloseDate : Date.today().addMonths(3);
            opp.Type = meetingData.opportunityType;
            
            // Add interests to description
            if (!meetingData.interests.isEmpty()) {
                opp.Description = 'Interests: ' + String.join(meetingData.interests, ', ') + '\n';
            }
            if (String.isNotBlank(meetingData.referralSource)) {
                opp.Description = (opp.Description != null ? opp.Description : '') + 'Referral: ' + meetingData.referralSource;
            }
            
            insert opp;
            
            // Create opportunity contact role
            OpportunityContactRole ocr = new OpportunityContactRole();
            ocr.OpportunityId = opp.Id;
            ocr.ContactId = contactId;
            ocr.Role = 'Decision Maker';
            ocr.IsPrimary = true;
            insert ocr;
            
        } else {
            // Update existing opportunity
            opp = existingOpps[0];
            String updateNote = '\n\n[Updated from meeting: ' + System.now().format() + ']\n';
            if (!meetingData.interests.isEmpty()) {
                updateNote += 'Additional Interests: ' + String.join(meetingData.interests, ', ');
            }
            
            opp.Description = (opp.Description != null ? opp.Description : '') + updateNote;
            if (meetingData.estimatedCloseDate != null && meetingData.estimatedCloseDate > opp.CloseDate) {
                opp.CloseDate = meetingData.estimatedCloseDate;
            }
            
            update opp;
        }
        
        return opp.Id;
    }
    
    /**
     * @description Generate AI-powered follow-up suggestions
     */
    private static String generateFollowUpSuggestions(MeetingData meetingData) {
        List<String> suggestions = new List<String>();
        
        // Generate suggestions based on interests
        if (!meetingData.interests.isEmpty()) {
            for (String interest : meetingData.interests) {
                String lowerInterest = interest.toLowerCase();
                if (lowerInterest.contains('climate tech')) {
                    suggestions.add('Send climate tech deal memo and portfolio overview');
                }
                if (lowerInterest.contains('impact investing')) {
                    suggestions.add('Share impact investing framework and case studies');
                }
            }
        }
        
        // Timeline-based suggestions
        if (String.isNotBlank(meetingData.timeline)) {
            suggestions.add('Schedule follow-up call before ' + meetingData.timeline);
        } else {
            suggestions.add('Schedule follow-up call in 2-3 weeks');
        }
        
        // Referral-based suggestions
        if (String.isNotBlank(meetingData.referralSource)) {
            suggestions.add('Send thank you note to ' + meetingData.referralSource);
        }
        
        // General suggestions
        suggestions.add('Notify investment team of new opportunity');
        suggestions.add('Add to quarterly pipeline review');
        
        return String.join(suggestions, '\n• ');
    }
}

