public with sharing class ClearRelatedFilesController {
    @AuraEnabled
    public static Integer clearFiles(Id recordId) {
        if (recordId == null) {
            throw new AuraHandledException('Record Id is required.');
        }

        List<ContentDocumentLink> links = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
        ];

        if (links.isEmpty()) {
            return 0;
        }

        delete links;
        return links.size();
    }
}
