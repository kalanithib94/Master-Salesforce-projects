/**
 * @description Test class for MeetingTranscriptProcessor
 * @author Brown Advisory
 * @date 2025
 */
@isTest
private class MeetingTranscriptProcessorTest {
    
    /**
     * @description Setup test data
     */
    @testSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(Name = 'Test Family Office');
        insert testAccount;
        
        // Create test contact
        Contact testContact = new Contact(
            FirstName = 'Sarah',
            LastName = 'Chen',
            AccountId = testAccount.Id,
            Email = 'sarah.chen@test.com'
        );
        insert testContact;
        
        // Create referral contact
        Contact referralContact = new Contact(
            FirstName = 'Paul',
            LastName = 'Chew',
            AccountId = testAccount.Id,
            Email = 'paul.chew@test.com'
        );
        insert referralContact;
    }
    
    /**
     * @description Test successful processing with manual parsing
     */
    @isTest
    static void testSuccessfulProcessing_ManualParsing() {
        // Get test contact
        Contact testContact = [SELECT Id FROM Contact WHERE LastName = 'Chen' LIMIT 1];
        
        // Prepare test transcript
        String testTranscript = 'Met with Sarah Chen at the Family Office Summit. ' +
                               'She\'s interested in impact investing, particularly in climate tech. ' +
                               'Potential liquidity event in Q2 2026. ' +
                               'Wants to explore direct deals. ' +
                               'Referred by Paul Chew.';
        
        // Create test event with transcript in Description
        Event testEvent = new Event(
            Subject = 'Business Development Meeting',
            StartDateTime = System.now(),
            EndDateTime = System.now().addHours(1),
            Description = testTranscript
        );
        insert testEvent;
        
        // Prepare request
        MeetingTranscriptProcessor.ProcessRequest request = new MeetingTranscriptProcessor.ProcessRequest();
        request.eventId = testEvent.Id;
        
        Test.startTest();
        List<MeetingTranscriptProcessor.ProcessResult> results = 
            MeetingTranscriptProcessor.processMeetingTranscript(new List<MeetingTranscriptProcessor.ProcessRequest>{request});
        Test.stopTest();
        
        // Assertions
        System.assertEquals(1, results.size(), 'Should return one result');
        MeetingTranscriptProcessor.ProcessResult result = results[0];
        
        System.assertEquals(true, result.isSuccess, 'Processing should be successful');
        System.assertEquals(testContact.Id, result.contactId, 'Should identify correct contact');
        System.assertNotEquals(null, result.taskId, 'Should create a task');
        System.assertNotEquals(null, result.opportunityId, 'Should create an opportunity');
        System.assertNotEquals(null, result.followUpSuggestions, 'Should generate follow-up suggestions');
        
        // Verify Event is linked to Contact
        Event updatedEvent = [SELECT WhoId FROM Event WHERE Id = :testEvent.Id];
        System.assertEquals(testContact.Id, updatedEvent.WhoId, 'Event should be linked to contact');
        
        // Verify Task was created
        List<Task> tasks = [SELECT Id, WhoId, Subject, Description FROM Task WHERE Id = :result.taskId];
        System.assertEquals(1, tasks.size(), 'Should create one task');
        System.assertEquals(testContact.Id, tasks[0].WhoId, 'Task should be linked to contact');
        System.assert(tasks[0].Description.contains('Impact Investing'), 'Task should include interests');
        
        // Verify Opportunity was created
        List<Opportunity> opps = [SELECT Id, Name, StageName, CloseDate, Description FROM Opportunity WHERE Id = :result.opportunityId];
        System.assertEquals(1, opps.size(), 'Should create one opportunity');
        System.assert(opps[0].Description.contains('Climate Tech'), 'Opportunity should include interests');
        System.assertEquals(Date.newInstance(2026, 6, 30), opps[0].CloseDate, 'Should set correct close date for Q2 2026');
        
        // Verify Opportunity Contact Role was created
        List<OpportunityContactRole> ocrs = [SELECT Id, ContactId, OpportunityId FROM OpportunityContactRole WHERE OpportunityId = :result.opportunityId];
        System.assertEquals(1, ocrs.size(), 'Should create opportunity contact role');
        System.assertEquals(testContact.Id, ocrs[0].ContactId, 'OCR should link to correct contact');
    }
    
    /**
     * @description Test successful processing with LLM parsed data
     */
    @isTest
    static void testSuccessfulProcessing_LLMParsedData() {
        // Get test contact
        Contact testContact = [SELECT Id FROM Contact WHERE LastName = 'Chen' LIMIT 1];
        
        // Prepare LLM parsed data
        Map<String, Object> parsedData = new Map<String, Object>{
            'contactName' => 'Sarah Chen',
            'eventName' => 'Family Office Summit',
            'interests' => new List<String>{'Impact Investing', 'Climate Tech'},
            'timeline' => 'Q2 2026',
            'estimatedCloseDate' => '2026-06-30',
            'referralSource' => 'Paul Chew',
            'opportunityType' => 'Direct deal exploration',
            'meetingContext' => 'Discussion about impact investing opportunities'
        };
        String llmJson = JSON.serialize(parsedData);
        
        // Create test event with transcript in Description
        Event testEvent = new Event(
            Subject = 'Business Development Meeting',
            StartDateTime = System.now(),
            EndDateTime = System.now().addHours(1),
            Description = 'Met with Sarah Chen at the Family Office Summit discussing climate tech.'
        );
        insert testEvent;
        
        // Prepare request
        MeetingTranscriptProcessor.ProcessRequest request = new MeetingTranscriptProcessor.ProcessRequest();
        request.eventId = testEvent.Id;
        request.llmParsedData = llmJson;
        
        Test.startTest();
        List<MeetingTranscriptProcessor.ProcessResult> results = 
            MeetingTranscriptProcessor.processMeetingTranscript(new List<MeetingTranscriptProcessor.ProcessRequest>{request});
        Test.stopTest();
        
        // Assertions
        System.assertEquals(1, results.size(), 'Should return one result');
        MeetingTranscriptProcessor.ProcessResult result = results[0];
        
        System.assertEquals(true, result.isSuccess, 'Processing should be successful');
        System.assertEquals(testContact.Id, result.contactId, 'Should identify correct contact');
        System.assertNotEquals(null, result.taskId, 'Should create a task');
        System.assertNotEquals(null, result.opportunityId, 'Should create an opportunity');
    }
    
    /**
     * @description Test processing when contact already linked to event
     */
    @isTest
    static void testProcessing_ContactAlreadyLinked() {
        // Get test contact
        Contact testContact = [SELECT Id FROM Contact WHERE LastName = 'Chen' LIMIT 1];
        
        // Create test event with contact already linked and transcript in Description
        Event testEvent = new Event(
            Subject = 'Business Development Meeting',
            StartDateTime = System.now(),
            EndDateTime = System.now().addHours(1),
            Description = 'Discussion about climate tech investments.',
            WhoId = testContact.Id
        );
        insert testEvent;
        
        // Prepare request
        MeetingTranscriptProcessor.ProcessRequest request = new MeetingTranscriptProcessor.ProcessRequest();
        request.eventId = testEvent.Id;
        
        Test.startTest();
        List<MeetingTranscriptProcessor.ProcessResult> results = 
            MeetingTranscriptProcessor.processMeetingTranscript(new List<MeetingTranscriptProcessor.ProcessRequest>{request});
        Test.stopTest();
        
        // Assertions
        MeetingTranscriptProcessor.ProcessResult result = results[0];
        System.assertEquals(true, result.isSuccess, 'Should process successfully using linked contact');
        System.assertEquals(testContact.Id, result.contactId, 'Should use contact already linked to event');
    }
    
    /**
     * @description Test updating existing opportunity
     */
    @isTest
    static void testUpdateExistingOpportunity() {
        // Get test contact and account
        Contact testContact = [SELECT Id, AccountId FROM Contact WHERE LastName = 'Chen' LIMIT 1];
        
        // Create existing opportunity
        Opportunity existingOpp = new Opportunity(
            Name = 'Existing Opportunity',
            AccountId = testContact.AccountId,
            StageName = 'Prospecting',
            CloseDate = Date.today().addMonths(3),
            Description = 'Initial discussion'
        );
        insert existingOpp;
        
        // Link contact to opportunity
        OpportunityContactRole ocr = new OpportunityContactRole(
            OpportunityId = existingOpp.Id,
            ContactId = testContact.Id,
            Role = 'Decision Maker'
        );
        insert ocr;
        
        // Create test event with transcript in Description
        Event testEvent = new Event(
            Subject = 'Follow-up Meeting',
            StartDateTime = System.now(),
            EndDateTime = System.now().addHours(1),
            Description = 'Met with Sarah Chen. Discussed impact investing and climate tech in Q2 2026.'
        );
        insert testEvent;
        
        // Prepare request
        MeetingTranscriptProcessor.ProcessRequest request = new MeetingTranscriptProcessor.ProcessRequest();
        request.eventId = testEvent.Id;
        
        Test.startTest();
        List<MeetingTranscriptProcessor.ProcessResult> results = 
            MeetingTranscriptProcessor.processMeetingTranscript(new List<MeetingTranscriptProcessor.ProcessRequest>{request});
        Test.stopTest();
        
        // Assertions
        MeetingTranscriptProcessor.ProcessResult result = results[0];
        System.assertEquals(true, result.isSuccess, 'Should process successfully');
        System.assertEquals(existingOpp.Id, result.opportunityId, 'Should update existing opportunity');
        
        // Verify opportunity was updated
        Opportunity updatedOpp = [SELECT Description FROM Opportunity WHERE Id = :existingOpp.Id];
        System.assert(updatedOpp.Description.contains('Climate Tech'), 'Should add new interests to description');
    }
    
    /**
     * @description Test contact not found scenario
     */
    @isTest
    static void testContactNotFound() {
        // Create test event with transcript in Description (non-existent contact)
        Event testEvent = new Event(
            Subject = 'Business Development Meeting',
            StartDateTime = System.now(),
            EndDateTime = System.now().addHours(1),
            Description = 'Met with John Doe at the conference.'
        );
        insert testEvent;
        
        // Prepare request
        MeetingTranscriptProcessor.ProcessRequest request = new MeetingTranscriptProcessor.ProcessRequest();
        request.eventId = testEvent.Id;
        
        Test.startTest();
        List<MeetingTranscriptProcessor.ProcessResult> results = 
            MeetingTranscriptProcessor.processMeetingTranscript(new List<MeetingTranscriptProcessor.ProcessRequest>{request});
        Test.stopTest();
        
        // Assertions
        MeetingTranscriptProcessor.ProcessResult result = results[0];
        System.assertEquals(false, result.isSuccess, 'Should fail when contact not found');
        System.assert(result.errorMessage.contains('Could not identify contact'), 'Should have appropriate error message');
    }
    
    /**
     * @description Test empty transcript handling
     */
    @isTest
    static void testEmptyTranscript() {
        // Create test event with empty Description
        Event testEvent = new Event(
            Subject = 'Business Development Meeting',
            StartDateTime = System.now(),
            EndDateTime = System.now().addHours(1),
            Description = ''
        );
        insert testEvent;
        
        // Prepare request
        MeetingTranscriptProcessor.ProcessRequest request = new MeetingTranscriptProcessor.ProcessRequest();
        request.eventId = testEvent.Id;
        
        Test.startTest();
        List<MeetingTranscriptProcessor.ProcessResult> results = 
            MeetingTranscriptProcessor.processMeetingTranscript(new List<MeetingTranscriptProcessor.ProcessRequest>{request});
        Test.stopTest();
        
        // Assertions
        MeetingTranscriptProcessor.ProcessResult result = results[0];
        System.assertEquals(false, result.isSuccess, 'Should fail with empty transcript');
        System.assert(result.errorMessage.contains('Description'), 'Should have appropriate error message about Description');
    }
    
    /**
     * @description Test follow-up suggestions generation
     */
    @isTest
    static void testFollowUpSuggestions() {
        // Get test contact
        Contact testContact = [SELECT Id FROM Contact WHERE LastName = 'Chen' LIMIT 1];
        
        // Create test event with transcript in Description
        Event testEvent = new Event(
            Subject = 'Business Development Meeting',
            StartDateTime = System.now(),
            EndDateTime = System.now().addHours(1),
            Description = 'Met with Sarah Chen. Interested in climate tech and impact investing. Timeline Q2 2026. Referred by Paul Chew.',
            WhoId = testContact.Id
        );
        insert testEvent;
        
        // Prepare request
        MeetingTranscriptProcessor.ProcessRequest request = new MeetingTranscriptProcessor.ProcessRequest();
        request.eventId = testEvent.Id;
        
        Test.startTest();
        List<MeetingTranscriptProcessor.ProcessResult> results = 
            MeetingTranscriptProcessor.processMeetingTranscript(new List<MeetingTranscriptProcessor.ProcessRequest>{request});
        Test.stopTest();
        
        // Assertions
        MeetingTranscriptProcessor.ProcessResult result = results[0];
        System.assertNotEquals(null, result.followUpSuggestions, 'Should generate follow-up suggestions');
        System.assert(result.followUpSuggestions.contains('climate tech'), 'Should include climate tech suggestion');
        System.assert(result.followUpSuggestions.contains('Paul Chew'), 'Should include thank you note for referral');
    }
    
    /**
     * @description Test auto-creation of new contact when not found
     */
    @isTest
    static void testAutoCreateContact() {
        // Create test event with transcript containing non-existent contact
        Event testEvent = new Event(
            Subject = 'Business Development Meeting',
            StartDateTime = System.now(),
            EndDateTime = System.now().addHours(1),
            Description = 'Met with Michael Johnson at the Investment Summit. Interested in ESG investing. Timeline Q3 2026.'
        );
        insert testEvent;
        
        // Prepare request
        MeetingTranscriptProcessor.ProcessRequest request = new MeetingTranscriptProcessor.ProcessRequest();
        request.eventId = testEvent.Id;
        
        Test.startTest();
        List<MeetingTranscriptProcessor.ProcessResult> results = 
            MeetingTranscriptProcessor.processMeetingTranscript(new List<MeetingTranscriptProcessor.ProcessRequest>{request});
        Test.stopTest();
        
        // Assertions
        MeetingTranscriptProcessor.ProcessResult result = results[0];
        System.assertEquals(true, result.isSuccess, 'Should successfully create new contact. Error: ' + result.errorMessage);
        System.assertNotEquals(null, result.contactId, 'Should create and return new contact ID');
        System.assertNotEquals(null, result.taskId, 'Should create a task');
        System.assertNotEquals(null, result.opportunityId, 'Should create an opportunity');
        
        // Verify new Contact was created
        List<Contact> newContacts = [SELECT Id, FirstName, LastName, AccountId FROM Contact WHERE Id = :result.contactId];
        System.assertEquals(1, newContacts.size(), 'Should create one new contact');
        System.assertEquals('Michael', newContacts[0].FirstName, 'Should set correct first name');
        System.assertEquals('Johnson', newContacts[0].LastName, 'Should set correct last name');
        System.assertNotEquals(null, newContacts[0].AccountId, 'Should create and link account');
        
        // Verify Account was created
        List<Account> newAccounts = [SELECT Id, Name FROM Account WHERE Id = :newContacts[0].AccountId];
        System.assertEquals(1, newAccounts.size(), 'Should create one new account');
        System.assert(newAccounts[0].Name.contains('Johnson'), 'Account name should contain last name');
        
        // Verify Event is linked to new Contact
        Event updatedEvent = [SELECT WhoId FROM Event WHERE Id = :testEvent.Id];
        System.assertEquals(result.contactId, updatedEvent.WhoId, 'Event should be linked to new contact');
        
        // Verify Opportunity was created for new contact
        List<Opportunity> opps = [SELECT Id, AccountId FROM Opportunity WHERE Id = :result.opportunityId];
        System.assertEquals(1, opps.size(), 'Should create opportunity');
        System.assertEquals(newContacts[0].AccountId, opps[0].AccountId, 'Opportunity should be linked to new account');
    }
    
    /**
     * @description Test bulk processing
     */
    @isTest
    static void testBulkProcessing() {
        // Get test contact
        Contact testContact = [SELECT Id FROM Contact WHERE LastName = 'Chen' LIMIT 1];
        
        // Create multiple events with transcript in Description
        List<Event> events = new List<Event>();
        for (Integer i = 0; i < 5; i++) {
            events.add(new Event(
                Subject = 'Meeting ' + i,
                StartDateTime = System.now(),
                EndDateTime = System.now().addHours(1),
                Description = 'Met with Sarah Chen about climate tech.',
                WhoId = testContact.Id
            ));
        }
        insert events;
        
        // Prepare multiple requests
        List<MeetingTranscriptProcessor.ProcessRequest> requests = new List<MeetingTranscriptProcessor.ProcessRequest>();
        for (Event evt : events) {
            MeetingTranscriptProcessor.ProcessRequest request = new MeetingTranscriptProcessor.ProcessRequest();
            request.eventId = evt.Id;
            requests.add(request);
        }
        
        Test.startTest();
        List<MeetingTranscriptProcessor.ProcessResult> results = 
            MeetingTranscriptProcessor.processMeetingTranscript(requests);
        Test.stopTest();
        
        // Assertions
        System.assertEquals(5, results.size(), 'Should process all 5 requests');
        for (MeetingTranscriptProcessor.ProcessResult result : results) {
            System.assertEquals(true, result.isSuccess, 'All processing should be successful');
        }
    }
}

