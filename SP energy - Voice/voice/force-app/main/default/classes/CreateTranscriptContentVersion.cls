public with sharing class CreateTranscriptContentVersion {

    public class Request {
        @InvocableVariable(label='Record ID' required=true)
        public String recordId;

        @InvocableVariable(label='Transcript Text' required=false)
        public String transcriptText;
    }

    // Queueable inner class — runs the API callout asynchronously
    public class PromptExecutionJob implements Queueable, Database.AllowsCallouts {
        private String promptRequestId;
        private String contentVersionId;
        private String transcriptText;
        private String eventUUID;

        public PromptExecutionJob(String promptRequestId, String contentVersionId, String transcriptText, String eventUUID) {
            this.promptRequestId  = promptRequestId;
            this.contentVersionId = contentVersionId;
            this.transcriptText   = transcriptText;
            this.eventUUID        = eventUUID;
        }

        public void execute(QueueableContext ctx) {
            System.debug('PromptExecutionJob: starting async prompt execution for contentVersionId=' + contentVersionId + ', promptRequestId=' + promptRequestId);

            ccai_qa.AIPromptProcessingInvokable.RequestWrapper pmtReq = new ccai_qa.AIPromptProcessingInvokable.RequestWrapper();
            pmtReq.promptRequestId    = promptRequestId;
            pmtReq.recordId           = contentVersionId;
            pmtReq.eventUUID          = eventUUID;
            pmtReq.customPromptCommand = transcriptText;

            List<ccai_qa.AIPromptProcessingInvokable.ResponseWrapper> responses =
                ccai_qa.AIPromptProcessingInvokable.processRequest(
                    new List<ccai_qa.AIPromptProcessingInvokable.RequestWrapper>{ pmtReq }
                );

            if (responses != null && !responses.isEmpty()) {
                ccai_qa.AIPromptProcessingInvokable.ResponseWrapper resp = responses[0];
                System.debug('PromptExecutionJob: status=' + resp.status + ', message=' + resp.message + ', responseId=' + resp.responseId);
            }
        }
    }

    @InvocableMethod(
        label='Create Transcript Content Version'
        description='Creates a ContentVersion with transcript text linked to the given record, then asynchronously executes the matching AI prompt from Voice Configuration.'
    )
    public static void createContentVersion(List<Request> requests) {
        for (Request req : requests) {
            processRequest(req);
        }
    }

    private static void processRequest(Request req) {
        String text = String.isBlank(req.transcriptText) ? '(no content)' : req.transcriptText;

        // Step 1: Create ContentVersion with transcript field populated
        ContentVersion cv = new ContentVersion();
        cv.Title                  = 'Transcript - ' + System.now().format('yyyy-MM-dd HH:mm:ss');
        cv.PathOnClient           = 'transcript.txt';
        cv.VersionData            = Blob.valueOf(text);
        cv.ccai_qa__Transcript__c = req.transcriptText;
        insert cv;
        System.debug('CreateTranscriptContentVersion: ContentVersion created - Id=' + cv.Id);

        // Step 2: Re-query to get ContentDocumentId, then link to the record
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = cv.ContentDocumentId;
        cdl.LinkedEntityId    = req.recordId;
        cdl.ShareType         = 'V';
        insert cdl;
        System.debug('CreateTranscriptContentVersion: ContentDocumentLink created - linked to recordId=' + req.recordId);

        // Step 3: Resolve object name and current user profile name
        String objectName = '';
        try {
            objectName = Id.valueOf(req.recordId).getSObjectType().getDescribe().getName();
        } catch (Exception e) {
            System.debug('CreateTranscriptContentVersion: could not resolve object name - ' + e.getMessage());
        }

        if (String.isBlank(objectName)) {
            System.debug('CreateTranscriptContentVersion: objectName is blank, skipping prompt execution.');
            return;
        }

        // Profile__c stores profile Name (confirmed from AIPromptController.getProfileOptions where wrap.value = p.Name)
        String profileName = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1].Name;
        System.debug('CreateTranscriptContentVersion: profileName=' + profileName + ', objectName=' + objectName);

        // Step 4: Find the AI Voice Configuration (mirrors AIVoiceConfigurationController pattern)
        List<ccai_qa__AI_Voice_Configuration__c> configs = [
            SELECT Id
            FROM ccai_qa__AI_Voice_Configuration__c
            LIMIT 1
        ];
        if (configs.isEmpty()) {
            System.debug('CreateTranscriptContentVersion: no AI Voice Configuration record found.');
            return;
        }
        System.debug('CreateTranscriptContentVersion: using Voice Config Id=' + configs[0].Id);

        // Step 5: Fetch ALL detail records — no profile/object filter in SOQL (mirrors AIVoiceConfigurationController).
        //         Match in Apex: profile-specific wins over blank profile (catch-all for all profiles).
        List<ccai_qa__AI_Voice_Configuration_Detail__c> allDetails = [
            SELECT Id,
                   ccai_qa__Profile__c,
                   ccai_qa__Related_To_Object__c,
                   ccai_qa__AI_Prompt__c,
                   ccai_qa__AI_Prompt__r.ccai_qa__Prompt_Request_Id__c
            FROM ccai_qa__AI_Voice_Configuration_Detail__c
            WHERE ccai_qa__AI_Voice_Configuration__c = :configs[0].Id
        ];
        System.debug('CreateTranscriptContentVersion: total detail records on config = ' + allDetails.size());

        ccai_qa__AI_Voice_Configuration_Detail__c matchedDetail = null;
        for (ccai_qa__AI_Voice_Configuration_Detail__c d : allDetails) {
            System.debug('CreateTranscriptContentVersion: evaluating detail Id=' + d.Id + ' profile=' + d.ccai_qa__Profile__c + ' object=' + d.ccai_qa__Related_To_Object__c);
            if (d.ccai_qa__Related_To_Object__c != objectName) {
                continue;
            }
            if (d.ccai_qa__Profile__c == profileName) {
                matchedDetail = d;
                System.debug('CreateTranscriptContentVersion: matched profile-specific detail Id=' + d.Id);
                break;
            } else if (String.isBlank(d.ccai_qa__Profile__c) && matchedDetail == null) {
                matchedDetail = d;
                System.debug('CreateTranscriptContentVersion: matched catch-all (blank profile) detail Id=' + d.Id);
            }
        }

        if (matchedDetail == null) {
            System.debug('CreateTranscriptContentVersion: no matching Voice Config Detail for profile=' + profileName + ' / object=' + objectName);
            return;
        }

        String promptRequestId = matchedDetail.ccai_qa__AI_Prompt__r.ccai_qa__Prompt_Request_Id__c;
        System.debug('CreateTranscriptContentVersion: promptRequestId=' + promptRequestId + ', promptId=' + matchedDetail.ccai_qa__AI_Prompt__c);

        if (String.isBlank(promptRequestId)) {
            System.debug('CreateTranscriptContentVersion: AI Prompt has no Prompt_Request_Id__c set.');
            return;
        }

        // Step 6: Enqueue the prompt execution asynchronously — required because AIPromptProcessingInvokable makes HTTP callouts
        System.debug('CreateTranscriptContentVersion: enqueueing PromptExecutionJob for contentVersionId=' + cv.Id);
        System.enqueueJob(new PromptExecutionJob(promptRequestId, cv.Id, req.transcriptText, UserInfo.getSessionId()));
    }
}
