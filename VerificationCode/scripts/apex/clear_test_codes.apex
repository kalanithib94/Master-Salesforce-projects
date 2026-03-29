// Delete ALL Verification_Code__c records so the flow starts completely fresh.
// Safe to run during testing - the flow will generate a new code on next login.
List<Verification_Code__c> allCodes = [SELECT Id FROM Verification_Code__c LIMIT 200];
if (!allCodes.isEmpty()) {
    delete allCodes;
    System.debug('Deleted ' + allCodes.size() + ' Verification_Code__c records. Flow will start fresh.');
} else {
    System.debug('No Verification_Code__c records found. Nothing to clear.');
}
