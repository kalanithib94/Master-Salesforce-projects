@IsTest
private class ClearRelatedFilesControllerTest {
    @IsTest
    static void clearFiles_removesLinkedFiles() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        ContentVersion cv = new ContentVersion(
            Title = 'TestFile',
            PathOnClient = 'TestFile.txt',
            VersionData = Blob.valueOf('Hello')
        );
        insert cv;

        ContentDocument createdDocument = [
            SELECT Id
            FROM ContentDocument
            WHERE Id IN (
                SELECT ContentDocumentId
                FROM ContentVersion
                WHERE Id = :cv.Id
            )
            LIMIT 1
        ];

        insert new ContentDocumentLink(
            ContentDocumentId = createdDocument.Id,
            LinkedEntityId = testAccount.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );

        Test.startTest();
        Integer removedCount = ClearRelatedFilesController.clearFiles(testAccount.Id);
        Test.stopTest();

        System.assertEquals(1, removedCount);
        Integer remaining = [
            SELECT COUNT()
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :testAccount.Id
        ];
        System.assertEquals(0, remaining);
    }
}
