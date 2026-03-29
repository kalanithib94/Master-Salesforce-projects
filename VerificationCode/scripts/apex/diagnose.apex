// 1. Check what Verification_Code__c records exist for the current user
String userId = UserInfo.getUserId();
System.debug('Current userId: ' + userId);

List<SObject> codes = Database.query(
    'SELECT Id, Attempt_Count__c, Is_Used__c, Expiry_Time__c, CreatedDate ' +
    'FROM Verification_Code__c ' +
    'WHERE User__c = :userId ' +
    'ORDER BY CreatedDate DESC LIMIT 10'
);
System.debug('Code records for this user: ' + codes.size());
for (SObject c : codes) {
    System.debug('  Attempts=' + c.get('Attempt_Count__c') +
                 ' Used=' + c.get('Is_Used__c') +
                 ' Expiry=' + c.get('Expiry_Time__c') +
                 ' Created=' + c.get('CreatedDate'));
}

// 2. Would Check_If_Blocked flag this user right now?
DateTime cutoff = DateTime.now().addMinutes(-30);
List<SObject> blocked = Database.query(
    'SELECT Id FROM Verification_Code__c ' +
    'WHERE User__c = :userId ' +
    'AND Attempt_Count__c >= 3 ' +
    'AND Is_Used__c = true ' +
    'AND CreatedDate >= :cutoff ' +
    'LIMIT 1'
);
System.debug('isBlocked RIGHT NOW = ' + !blocked.isEmpty());
