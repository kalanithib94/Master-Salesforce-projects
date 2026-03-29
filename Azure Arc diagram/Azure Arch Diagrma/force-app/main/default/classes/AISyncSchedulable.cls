public class AISyncSchedulable implements Schedulable, Database.AllowsCallouts {
    
    
    public String schedulerId;
    public AISyncSchedulable(String schedulerId){
        this.schedulerId = schedulerId;
    }
    
    public void execute(SchedulableContext sc) {
        String jobId = sc != null ? sc.getTriggerId() : null;
        processRequest(schedulerId, jobId);
    }
    
    
    @future(callout=true)
    public static void processRequest(String schedulerId, String jobId){
        List<AI_RAG_Sync__c> lst = [SELECT Id, Name, Cron_Expression__c,
                                          Where_Clause__c, File_Format__c,
                                          Object__c, Fields__c, File_Name__c,
                                          AI_Model_File_Upload__c, External_Id__c,
                                          AI_Model_File_Upload__r.Additional_Parameters__c, 
                                          AI_Model_File_Upload__r.Named_Credential__c, 
                                          AI_Model_File_Upload__r.Model__c,
                                          AI_Model_File_Upload__r.Connector_Class__c,
                                          AI_Model_Datastore_Import__c, 
                                          AI_Model_Datastore_Import__r.Additional_Parameters__c, 
                                          AI_Model_Datastore_Import__r.Named_Credential__c, 
                                          AI_Model_Datastore_Import__r.Model__c,
                                          AI_Model_Datastore_Import__r.Connector_Class__c,
                                          (SELECT Id, Response__c FROM AI_RAG_Sync_Jobs__r 
                                           ORDER BY CreatedDate DESC LIMIT 1)
                                          FROM AI_RAG_Sync__c 
                                          WHERE Id =:schedulerId
                                          AND AI_Model_File_Upload__c != NULL
                                          LIMIT 1];
        
        if(lst != null && !lst.isEmpty()){
            AI_RAG_Sync__c scheduler = lst.get(0);

            AI_RAG_Sync_Job__c job = new AI_RAG_Sync_Job__c(
                Start_Date_Time__c = System.now(),
                AI_RAG_Sync__c = schedulerId,
                Apex_Job_Id__c = jobId,
                Status__c = AIConstants.SYNC_JOB_STATUS_IN_PROGRESS
            );
            
            String query = 'SELECT ' + AISyncSchedulable.getFieldAPIs(scheduler)+' FROM '+String.escapeSingleQuotes(scheduler.Object__c);
            if(String.isNotBlank(scheduler.Where_Clause__c)){
                query += ' WHERE '+scheduler.Where_Clause__c;
            }
            
            Map<String, Object> responseMap;
            List<SObject> records = Database.query(query);
            if(records != null && !records.isEmpty()){
                String fileContent = AISyncSchedulable.generateFile(records, scheduler);
                try{
                    if(String.isNotBlank(scheduler.External_Id__c)){
                        deleteFile(scheduler);
                    }
                    
                    responseMap = AISyncSchedulable.pushToAI(fileContent, scheduler);
                    job.Status__c = AIConstants.SYNC_JOB_STATUS_COMPLETE;
                    if(responseMap != NULL){
                        job.Response__c = JSON.serialize(responseMap); 
                    }
                }catch (Exception e) {
                    System.debug('e: '+e.getMessage());
                    job.Status__c = AIConstants.SYNC_JOB_STATUS_ERRORED;
                    job.Message__c = e.getMessage()+' \n\n '+e.getStackTraceString();
                }
                job.End_Date_Time__c = System.Now();
                List<sObject> insertedJob = FLSCheck.getInstance().insertDML(new List<AI_RAG_Sync_Job__c>{job});
                if(insertedJob != null && !insertedJob.isEmpty()){
                    AISyncSchedulable.saveFile(String.valueOf(insertedJob.get(0).get('Id')), scheduler.File_Name__c, fileContent);
                }
                
                if(responseMap != NULL && String.isBlank(scheduler.External_Id__c)){
                    scheduler.External_Id__c = String.valueOf(responseMap.get('externalId'));
                    FLSCheck.getInstance().updateDML(new List<AI_RAG_Sync__c>{scheduler});
                }
            }
        }
    }
    
    private static String getFieldAPIs(AI_RAG_Sync__c scheduler) {
        Map<String, Object> fieldMap = (Map<String, Object>) JSON.deserializeUntyped(scheduler.Fields__c);
        return String.join(new List<String>(fieldMap.keySet()), ',');
    }
    
    private static String generateFile(List<SObject> records, AI_RAG_Sync__c scheduler) {
        Map<String, Object> fieldMap = (Map<String, Object>) JSON.deserializeUntyped(scheduler.Fields__c);
        if(String.isNotBlank(scheduler.File_Format__c) && scheduler.File_Format__c.equalsIgnoreCase('csv')){
            return generateCSV(records, fieldMap);
        }else{
            return generateJSON(records, fieldMap);
        }
    }
    
    public static String generateCSV(List<SObject> records, Map<String, Object> fieldMap){
        List<String> headers = new List<String>();
        for(Object header : fieldMap.values()){
            headers.add('"' + String.valueOf(header).replaceAll('"', '""') + '"');
        }
        String csvContentBuilder = String.join(headers, ',') + '\n';
        for(SObject record : records){
            List<String> values = new List<String>();
            for (String fieldAPI : fieldMap.keySet()) {
                String value = record.get(fieldAPI) != null ? String.valueOf(record.get(fieldAPI)) : '';
                if(String.isNotBlank(value)) {
                    value = value.unescapeHtml3().unescapeHtml4();
                    value = '"' + value.replaceAll('"', '""') + '"';
                }
                values.add(value);
            }
            csvContentBuilder += String.join(values, ',') + '\n';
        }
        return csvContentBuilder.removeEnd('\n');
    }
    
    public static String generateJSON(List<SObject> records, Map<String, Object> fieldMap){
        List<Object> returnList = new List<Object>();
        for(SObject record : records){
            Map<String, Object> recordMap = new Map<String, Object>();
            for(String fieldAPI : fieldMap.keySet()){
                String fieldLabel = String.valueOf(fieldMap.get(fieldAPI));
                String value = record.get(fieldAPI) != null ? String.valueOf(record.get(fieldAPI)) : '';
                if(String.isNotBlank(value)) {
                    value = value.unescapeHtml3().unescapeHtml4();
                    value = '"' + value.replaceAll('"', '""') + '"';
                }
                recordMap.put(fieldLabel, value);
            }
            returnList.add(recordMap);
        }
        if(!returnList.isEmpty()){
            return JSON.serialize(returnList);
        }
        return null;
    }
    
    private static Map<String, Object> pushToAI(String csvContent, AI_RAG_Sync__c scheduler) {     
        String fileUploadAddParams = scheduler.AI_Model_File_Upload__c != null ? scheduler.AI_Model_File_Upload__r.Additional_Parameters__c : null;
        String datastoreImportAddParams = scheduler.AI_Model_Datastore_Import__c != null ? scheduler.AI_Model_Datastore_Import__r.Additional_Parameters__c : null;
        
        Map<String, Object> mapOfFileUploadAdditionalParams;
        if(String.isNotBlank(fileUploadAddParams)){
            mapOfFileUploadAdditionalParams = (Map<String, Object>)JSON.deserializeUntyped(fileUploadAddParams);
        }
        
        Map<String, Object> mapOfStoreImportAdditionalParams;
        if(String.isNotBlank(datastoreImportAddParams)){
            mapOfStoreImportAdditionalParams = (Map<String, Object>)JSON.deserializeUntyped(datastoreImportAddParams);
        }
        
        Map<String, Object> responseMap = new Map<String, Object>();
        
        String fileFormat = 'application/json';
        if(String.isNotBlank(scheduler.File_Format__c) && scheduler.File_Format__c.equalsIgnoreCase('csv')){
            fileFormat = 'text/csv';
        }

        HttpResponse resp;
        if(scheduler.AI_Model_File_Upload__c != null && scheduler.AI_Model_File_Upload__r.Model__c.containsIgnoreCase(AIConstants.GCP_FILE_UPLOAD)){
            String bucketName = String.valueOf(mapOfFileUploadAdditionalParams.get('bucketName'));
            resp = doCallout(
                csvContent,
                null,
                new Map<String, String>{'Content-Type' => fileFormat}, 
                'callout:'+scheduler.AI_Model_File_Upload__r.Named_Credential__c+'/upload/storage/v1/b/'+EncodingUtil.urlEncode(bucketName, 'UTF-8')+'/o?name='+EncodingUtil.urlEncode(scheduler.File_Name__c, 'UTF-8'),
                'POST'
            );
        }else{
            String boundary = 'boundary_' + DateTime.now().getTime();
            String bodyBlob = buildMultipartBodyBlob(scheduler.File_Name__c, boundary);
            String footerHex = EncodingUtil.convertToHex(Blob.valueOf('\r\n--' + boundary + '--\r\n'));
            Blob bodyData = EncodingUtil.convertFromHex(bodyBlob + EncodingUtil.convertToHex(Blob.valueOf(csvContent)) + footerHex);
            
            resp = doCallout(
                null,
                bodyData,
                new Map<String, String>{'Content-Type' => 'multipart/form-data; boundary=' + boundary}, 
                'callout:'+scheduler.AI_Model_File_Upload__r.Named_Credential__c+'/v1/files',
                'POST'
            );
        }
        
        if(resp.getStatusCode() > 210){
            throw new ChatGPTUtills.ApplicationException('Failed to upload file: '+resp.getBody());
        }else{
            String respBody = resp.getBody();
            if (String.isNotBlank(respBody)) {
                try{
                    Map<String, Object> dataMap = (Map<String, Object>)JSON.deserializeUntyped(respBody);
                    if(dataMap != null && dataMap.containsKey('id')) {
                        responseMap.put('fileId', dataMap.get('id'));
                    }
                }catch (Exception jsonEx){
                    throw new ChatGPTUtills.ApplicationException('Failed to upload file: '+jsonEx.getMessage());
                }
            }
        }
        
        // Import the CSV file to datastore
        if(scheduler.AI_Model_Datastore_Import__c != null && scheduler.AI_Model_Datastore_Import__r.Model__c.containsIgnoreCase(AIConstants.GCP_DISCOVERY_ENGINE)){
            String bucketName = String.valueOf(mapOfStoreImportAdditionalParams.get('bucketName'));
            String projectId = String.valueOf(mapOfStoreImportAdditionalParams.get('projectId'));
            String dataStoreId = String.valueOf(mapOfStoreImportAdditionalParams.get('dataStoreId'));
            Boolean isStructured = Boolean.valueOf(mapOfStoreImportAdditionalParams.get('isStructured'));
            
            String dataSchemaFormat = isStructured ? 'csv' : 'content-with-faq-csv';
            Map<String, Object> reqBody = new Map<String, Object>{
            	'reconciliationMode' => 'FULL',
                'autoGenerateIds' => true,
                'gcsSource' => new Map<String, Object>{
                    'inputUris' => new List<String>{'gs://'+bucketName+'/'+scheduler.File_Name__c},
                    'dataSchema' => dataSchemaFormat
                }
        	};
            
            resp = doCallout(
                JSON.serialize(reqBody), 
                null,
                new Map<String, String>{'Content-Type' => 'application/json'}, 
                'callout:'+scheduler.AI_Model_Datastore_Import__r.Named_Credential__c+'/v1/projects/'+ EncodingUtil.urlEncode(projectId, 'UTF-8')+'/locations/global/dataStores/' + EncodingUtil.urlEncode(dataStoreId, 'UTF-8') + '/branches/default_branch/documents:import',
                'POST'
            );
        }else{
            if(responseMap == null || !responseMap.containsKey('fileId')){
                throw new ChatGPTUtills.ApplicationException('No uploaded file IDs available for vector store creation');
            }
            
            Map<String, Object> reqBody = new Map<String, Object>{
                'name' => String.valueOf(DateTime.now().getTime()),
                'file_ids' => new List<String>{String.valueOf(responseMap.get('fileId'))}
            };
                
            String endPoint = 'callout:'+scheduler.AI_Model_Datastore_Import__r.Named_Credential__c+'/v1/vector_stores';
            if(String.isNotBlank(scheduler.External_Id__c)){
                endPoint += '/'+scheduler.External_Id__c+'/files';
                reqBody = new Map<String, Object>{'file_id' => String.valueOf(responseMap.get('fileId'))};
            }
            
            resp = doCallout(
                JSON.serialize(reqBody), 
                null,
                new Map<String, String>{'Content-Type' => 'application/json', 'OpenAI-Beta' => 'assistants=v2'}, 
                endPoint,
                'POST'
            );
        }

        if(resp.getStatusCode() > 210){
            throw new ChatGPTUtills.ApplicationException('Failed to import file: '+resp.getBody());
        }else{
            String respBody = resp.getBody();
            if(String.isNotBlank(respBody)){
                try{
                    Map<String, Object> dataMap = (Map<String, Object>)JSON.deserializeUntyped(respBody);
                    if (dataMap != null && dataMap.containsKey('id')) {
                        responseMap.put('externalId', dataMap.get('id'));
                    }
                }catch (Exception jsonEx) {
                    throw new ChatGPTUtills.ApplicationException('Failed to import file: '+jsonEx.getMessage());
                }
            }
        }
        return responseMap;
    }
    
    private static HttpResponse doCallout(String requestBody, Blob requestBody_blob, Map<String, String> headers, String endpoint, String method){
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPoint);
        req.setMethod(method);
        req.setTimeout(120000);
        for(String key : headers.keySet()){
            req.setHeader(key, headers.get(key));
        }
        if(String.isNotBlank(requestBody)){
            req.setBody(requestBody);
        }else if(requestBody_blob != null){
            req.setBodyAsBlob(requestBody_blob);
        }
        
        HttpResponse resp = http.send(req);
        
        //System.debug('status: '+resp.getStatus());
        //System.debug('statusCode: '+resp.getStatusCode());
        //System.debug('body: '+resp.getBody());
        
        return resp;
    }
    
    private static void saveFile(Id parentId, String fileName, String fileContent) {
        Blob bodyBlob = Blob.valueOf('\uFEFF'+fileContent);     
        ContentVersion cv = new ContentVersion(
            Title = fileName, 
            PathOnClient = fileName,
            VersionData = bodyBlob, 
            origin = 'H'
        );
        cv = (ContentVersion)FLSCheck.getInstance().insertDML(new List<ContentVersion>{cv}).get(0);
        
        cv = [SELECT Id, Title, ContentDocumentId 
              FROM ContentVersion 
              WHERE Id =:cv.Id 
              LIMIT 1];
        
        ContentDocumentLink link = new ContentDocumentLink();
        link.LinkedEntityId = parentId;
        link.contentdocumentid = cv.ContentDocumentId;
        link.ShareType = 'V';
        FLSCheck.getInstance().insertDML(new List<ContentDocumentLink>{link});
    }
    
    private static String buildMultipartBodyBlob(String fileName, String boundary) {
        // Clean filename
        fileName = fileName.replaceAll('[^a-zA-Z0-9._-]', '_');

        // Build multipart sections with proper spacing
        String purposeSection = '--' + boundary + '\r\n' +
                'Content-Disposition: form-data; name="purpose"\r\n\r\n' +
                'assistants\r\n';

        String fileHeaderSection = '--' + boundary + '\r\n' +
                    'Content-Disposition: form-data; name="file"; filename="' + fileName + '"\r\n' +
                    'Content-Type: application/octet-stream\r\n\r\n';

        // Convert to hex to avoid base64
        String purposeHex = EncodingUtil.convertToHex(Blob.valueOf(purposeSection));
        String fileHeaderHex = EncodingUtil.convertToHex(Blob.valueOf(fileHeaderSection));

        String combinedHex = purposeHex + fileHeaderHex;
        return combinedHex;
    }
    
    public static void deleteFile(AI_RAG_Sync__c sch){	
        String externalId = sch.External_Id__c;
        if(String.isNotBlank(externalId)){
            if(sch.AI_RAG_Sync_Jobs__r != null && !sch.AI_RAG_Sync_Jobs__r.isEmpty()){
                String response = sch.AI_RAG_Sync_Jobs__r.get(0).Response__c;
                if(String.isNotBlank(response)){
                    Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response);
                    if(responseMap != null && responseMap.containsKey('fileId')){
                        String fileId = String.valueOf(responseMap.get('fileId'));
                        
                        AIResponsesApiCalloutUtility.ResponseApiWrapper wrap = new AIResponsesApiCalloutUtility.ResponseApiWrapper();
                        wrap.aiModel = sch.AI_Model_File_Upload__r;
                        wrap.vectorStoreId = externalId;
                        wrap.fileId = fileId;
                        wrap = AIResponsesApiCalloutUtility.deleteFileFromVectorStore(wrap);
                    }
                }
            }
        }
    }
    
    
}