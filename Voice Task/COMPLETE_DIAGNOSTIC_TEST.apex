/**
 * COMPLETE DIAGNOSTIC TEST
 * Run this in Developer Console → Execute Anonymous
 * 
 * BEFORE RUNNING:
 * 1. Enable Debug Logs: Setup → Debug Logs → New → Your User → FINEST
 * 2. Close and reopen Developer Console to get fresh code
 */

// Your exact LLM format
String testTranscript = 'Contact: Sara\nEvent: Not specified\nInterests: Impact Investing, Climate Tech\nTimeline: Q2 2026\nReferral: Paul\nOpportunity: Direct Deals';

System.debug('========================================');
System.debug('STARTING COMPLETE DIAGNOSTIC TEST');
System.debug('========================================');

// STEP 1: Create Test Account
System.debug('\n=== STEP 1: Creating Test Account ===');
Account testAccount = new Account(Name = 'Brown Advisory Test ' + System.now().millisecond());
insert testAccount;
System.debug('✅ Account created: ' + testAccount.Id);
System.debug('   Name: ' + testAccount.Name);

// STEP 2: Create Existing Contact "Sara"
System.debug('\n=== STEP 2: Creating Existing Contact "Sara" ===');
Contact existingSara = new Contact(
    FirstName = 'Sara',
    LastName = 'Johnson',
    AccountId = testAccount.Id,
    Email = 'sara@test.com'
);
insert existingSara;
System.debug('✅ Existing Contact created: ' + existingSara.Id);
System.debug('   Name: Sara Johnson');
System.debug('   Account: ' + testAccount.Id);

// STEP 3: Create Event
System.debug('\n=== STEP 3: Creating Event ===');
Event testEvent = new Event(
    Subject = 'Test Meeting',
    StartDateTime = System.now(),
    EndDateTime = System.now().addHours(1),
    Description = testTranscript,
    WhatId = testAccount.Id
    // NOTE: NOT setting WhoId - Apex should find Sara
);
insert testEvent;
System.debug('✅ Event created: ' + testEvent.Id);
System.debug('   WhatId (Account): ' + testEvent.WhatId);
System.debug('   WhoId (Contact): ' + testEvent.WhoId + ' (should be null initially)');

// STEP 4: Call Apex Processor
System.debug('\n=== STEP 4: Calling Apex Processor ===');
MeetingTranscriptProcessor.ProcessRequest request = new MeetingTranscriptProcessor.ProcessRequest();
request.eventId = testEvent.Id;

List<MeetingTranscriptProcessor.ProcessResult> results = 
    MeetingTranscriptProcessor.processMeetingTranscript(
        new List<MeetingTranscriptProcessor.ProcessRequest>{request}
    );

// STEP 5: Check Results
System.debug('\n=== STEP 5: RESULTS ===');
System.debug('Success: ' + results[0].isSuccess);
System.debug('Error Message: ' + results[0].errorMessage);
System.debug('Contact ID: ' + results[0].contactId);
System.debug('Task ID: ' + results[0].taskId);
System.debug('Opportunity ID: ' + results[0].opportunityId);
System.debug('Suggestions: ' + results[0].followUpSuggestions);

// STEP 6: Detailed Verification
System.debug('\n=== STEP 6: VERIFICATION ===');

// 6A: Check Contact
System.debug('\n--- Contact Verification ---');
if (results[0].contactId == existingSara.Id) {
    System.debug('✅ PASSED: Found existing Contact Sara (did NOT create duplicate)');
} else if (results[0].contactId != null) {
    System.debug('❌ FAILED: Created NEW Contact instead of finding Sara');
    Contact newContact = [SELECT Id, FirstName, LastName, AccountId FROM Contact WHERE Id = :results[0].contactId];
    System.debug('   New Contact: ' + newContact.FirstName + ' ' + newContact.LastName);
    System.debug('   Expected to find: Sara Johnson (ID: ' + existingSara.Id + ')');
    
    // Count Sara contacts
    List<Contact> allSaras = [SELECT Id, Name FROM Contact 
                             WHERE AccountId = :testAccount.Id 
                             AND (FirstName LIKE '%Sara%' OR LastName LIKE '%Sara%' OR Name LIKE '%Sara%')];
    System.debug('   Total Sara contacts in account: ' + allSaras.size());
    for (Contact c : allSaras) {
        System.debug('      - ' + c.Name + ' (ID: ' + c.Id + ')');
    }
} else {
    System.debug('❌ FAILED: No Contact found or created');
}

// 6B: Check Task
System.debug('\n--- Task Verification ---');
if (results[0].taskId != null) {
    Task t = [SELECT Id, Subject, WhoId, WhatId, Status, ActivityDate, Description FROM Task WHERE Id = :results[0].taskId];
    System.debug('Task ID: ' + t.Id);
    System.debug('Task Subject: ' + t.Subject);
    System.debug('Task WhoId (Contact): ' + t.WhoId);
    System.debug('Task WhatId (Account): ' + t.WhatId);
    System.debug('Task Status: ' + t.Status);
    System.debug('Task Due Date: ' + t.ActivityDate);
    
    if (t.WhoId == results[0].contactId) {
        System.debug('✅ PASSED: Task IS linked to Contact');
    } else {
        System.debug('❌ FAILED: Task NOT linked to Contact');
        System.debug('   Expected WhoId: ' + results[0].contactId);
        System.debug('   Actual WhoId: ' + t.WhoId);
    }
    
    if (t.WhatId == testAccount.Id) {
        System.debug('✅ PASSED: Task IS linked to Account');
    } else {
        System.debug('❌ FAILED: Task NOT linked to Account');
        System.debug('   Expected WhatId: ' + testAccount.Id);
        System.debug('   Actual WhatId: ' + t.WhatId);
    }
} else {
    System.debug('❌ FAILED: No Task created');
}

// 6C: Check Opportunity
System.debug('\n--- Opportunity Verification ---');
if (results[0].opportunityId != null) {
    Opportunity o = [SELECT Id, Name, Type, AccountId, StageName, CloseDate, Description FROM Opportunity WHERE Id = :results[0].opportunityId];
    System.debug('Opportunity ID: ' + o.Id);
    System.debug('Opportunity Name: ' + o.Name);
    System.debug('Opportunity Type: ' + o.Type);
    System.debug('Opportunity Stage: ' + o.StageName);
    System.debug('Opportunity Close Date: ' + o.CloseDate);
    System.debug('Opportunity AccountId: ' + o.AccountId);
    System.debug('Opportunity Description: ' + o.Description);
    
    if (o.AccountId == testAccount.Id) {
        System.debug('✅ PASSED: Opportunity IS under correct Account');
    } else {
        System.debug('❌ FAILED: Opportunity under wrong Account');
        System.debug('   Expected: ' + testAccount.Id);
        System.debug('   Actual: ' + o.AccountId);
    }
    
    if (o.Type == 'Direct Deals') {
        System.debug('✅ PASSED: Opportunity Type set correctly');
    } else {
        System.debug('⚠️  WARNING: Opportunity Type = "' + o.Type + '" (expected "Direct Deals")');
    }
    
    // Check Contact Role
    List<OpportunityContactRole> ocrs = [SELECT Id, ContactId, Role, IsPrimary FROM OpportunityContactRole WHERE OpportunityId = :o.Id];
    System.debug('Opportunity Contact Roles: ' + ocrs.size());
    if (!ocrs.isEmpty()) {
        System.debug('✅ PASSED: Opportunity Contact Role created');
        System.debug('   Contact: ' + ocrs[0].ContactId);
        System.debug('   Role: ' + ocrs[0].Role);
        System.debug('   Primary: ' + ocrs[0].IsPrimary);
        
        if (ocrs[0].ContactId == results[0].contactId) {
            System.debug('✅ PASSED: Contact Role linked to correct Contact');
        }
    } else {
        System.debug('❌ FAILED: No Contact Role created');
    }
} else {
    System.debug('❌ FAILED: No Opportunity created');
    System.debug('   This could mean:');
    System.debug('   - DML exception occurred');
    System.debug('   - Validation rule blocked creation');
    System.debug('   - Check errorMessage above');
}

// STEP 7: Summary
System.debug('\n========================================');
System.debug('TEST SUMMARY');
System.debug('========================================');
System.debug('Overall Success: ' + results[0].isSuccess);
if (results[0].isSuccess) {
    System.debug('✅ All records created successfully!');
    System.debug('   Contact: ' + results[0].contactId);
    System.debug('   Task: ' + results[0].taskId);
    System.debug('   Opportunity: ' + results[0].opportunityId);
} else {
    System.debug('❌ Process failed: ' + results[0].errorMessage);
}
System.debug('========================================');


