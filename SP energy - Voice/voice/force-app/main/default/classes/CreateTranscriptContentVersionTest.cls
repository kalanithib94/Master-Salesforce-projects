@IsTest
private class CreateTranscriptContentVersionTest {

    @IsTest
    static void testCreateContentVersion_withVoiceConfig() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create a minimal AI Voice Configuration
        ccai_qa__AI_Voice_Configuration__c config = new ccai_qa__AI_Voice_Configuration__c();
        insert config;

        // Create a prompt with a Prompt_Request_Id__c
        ccai_qa__AI_Prompt__c prompt = new ccai_qa__AI_Prompt__c(
            Name                           = 'Test Prompt',
            ccai_qa__Status__c             = 'Active',
            ccai_qa__Object__c             = 'Account',
            ccai_qa__Prompt_Request_Id__c  = 'test-prompt-request-id-001'
        );
        insert prompt;

        // Profile__c stores profile Name, not ID
        String profileName = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1].Name;

        // Create a Voice Config Detail matching current user profile + Account object
        ccai_qa__AI_Voice_Configuration_Detail__c detail = new ccai_qa__AI_Voice_Configuration_Detail__c(
            ccai_qa__AI_Voice_Configuration__c = config.Id,
            ccai_qa__Profile__c                = profileName,
            ccai_qa__Related_To_Object__c      = 'Account',
            ccai_qa__AI_Prompt__c              = prompt.Id
        );
        insert detail;

        CreateTranscriptContentVersion.Request req = new CreateTranscriptContentVersion.Request();
        req.recordId      = acc.Id;
        req.transcriptText = 'My electricity bill has increased significantly over the past three months.';

        Test.startTest();
        CreateTranscriptContentVersion.createContentVersion(
            new List<CreateTranscriptContentVersion.Request>{ req }
        );
        Test.stopTest();

        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :acc.Id
        ];
        Assert.areEqual(1, links.size(), 'Expected one ContentDocumentLink for the account');

        ContentVersion cv = [
            SELECT ccai_qa__Transcript__c, Title
            FROM ContentVersion
            WHERE ContentDocumentId = :links[0].ContentDocumentId
        ];
        Assert.areEqual(req.transcriptText, cv.ccai_qa__Transcript__c, 'Transcript field should match input text');
        Assert.isTrue(cv.Title.startsWith('Transcript -'), 'Title should start with Transcript -');
    }

    @IsTest
    static void testCreateContentVersion_catchAllProfile() {
        // Detail with blank Profile__c should apply to all profiles
        Account acc = new Account(Name = 'Test Account Catch-All');
        insert acc;

        ccai_qa__AI_Voice_Configuration__c config = new ccai_qa__AI_Voice_Configuration__c();
        insert config;

        ccai_qa__AI_Prompt__c prompt = new ccai_qa__AI_Prompt__c(
            Name                           = 'Test Prompt Catch-All',
            ccai_qa__Status__c             = 'Active',
            ccai_qa__Object__c             = 'Account',
            ccai_qa__Prompt_Request_Id__c  = 'test-prompt-request-id-002'
        );
        insert prompt;

        // Blank profile = catch-all
        ccai_qa__AI_Voice_Configuration_Detail__c detail = new ccai_qa__AI_Voice_Configuration_Detail__c(
            ccai_qa__AI_Voice_Configuration__c = config.Id,
            ccai_qa__Profile__c                = null,
            ccai_qa__Related_To_Object__c      = 'Account',
            ccai_qa__AI_Prompt__c              = prompt.Id
        );
        insert detail;

        CreateTranscriptContentVersion.Request req = new CreateTranscriptContentVersion.Request();
        req.recordId       = acc.Id;
        req.transcriptText = 'Catch-all profile test transcript.';

        Test.startTest();
        CreateTranscriptContentVersion.createContentVersion(
            new List<CreateTranscriptContentVersion.Request>{ req }
        );
        Test.stopTest();

        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :acc.Id
        ];
        Assert.areEqual(1, links.size(), 'ContentVersion should be created for catch-all profile config');
    }

    @IsTest
    static void testCreateContentVersion_noVoiceConfig() {
        // No Voice Config in org — ContentVersion should still be created without error
        Account acc = new Account(Name = 'Test Account No Config');
        insert acc;

        CreateTranscriptContentVersion.Request req = new CreateTranscriptContentVersion.Request();
        req.recordId      = acc.Id;
        req.transcriptText = 'Test transcript with no voice config.';

        Test.startTest();
        CreateTranscriptContentVersion.createContentVersion(
            new List<CreateTranscriptContentVersion.Request>{ req }
        );
        Test.stopTest();

        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :acc.Id
        ];
        Assert.areEqual(1, links.size(), 'ContentVersion should still be created even with no voice config');
    }

    @IsTest
    static void testCreateContentVersion_nullText() {
        Account acc = new Account(Name = 'Test Account Null Text');
        insert acc;

        CreateTranscriptContentVersion.Request req = new CreateTranscriptContentVersion.Request();
        req.recordId      = acc.Id;
        req.transcriptText = null;

        Test.startTest();
        CreateTranscriptContentVersion.createContentVersion(
            new List<CreateTranscriptContentVersion.Request>{ req }
        );
        Test.stopTest();

        List<ContentDocumentLink> links = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :acc.Id
        ];
        Assert.areEqual(1, links.size(), 'ContentVersion should be created even with null transcript text');
    }
}
