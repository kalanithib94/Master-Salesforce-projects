// Static SOQL - will fail at compile time if the fields truly don't exist
try {
    List<Verification_Code__c> recs = [
        SELECT Id, User__c, Code_Hash__c, Expiry_Time__c, Attempt_Count__c, Is_Used__c
        FROM Verification_Code__c
        LIMIT 1
    ];
    System.debug('Field query OK. Record count: ' + recs.size());
} catch (Exception e) {
    System.debug('ERROR: ' + e.getMessage());
}
