/**
 * Infra-only seed — NO CRM E2E accounts/cases/etc.
 * Prerequisites skills cannot create: product/PBE lookup, Queue, CaseTeamRole, peer User.
 */
String TAG = 'E2E_SKILL_INFRA';

// Active product + standard PBE (prefer GenWatt for search demos)
Id productId = null;
Id pbeId = null;
List<Product2> prods = [
    SELECT Id, Name FROM Product2 WHERE IsActive = true AND Name LIKE '%GenWatt%' LIMIT 1
];
if (prods.isEmpty()) {
    prods = [SELECT Id, Name FROM Product2 WHERE IsActive = true LIMIT 1];
}
if (!prods.isEmpty()) {
    productId = prods[0].Id;
    List<PricebookEntry> pbes = [
        SELECT Id FROM PricebookEntry
        WHERE Product2Id = :productId AND IsActive = true AND Pricebook2.IsStandard = true
        LIMIT 1
    ];
    if (pbes.isEmpty()) {
        pbes = [SELECT Id FROM PricebookEntry WHERE IsActive = true AND Pricebook2.IsStandard = true LIMIT 1];
    }
    if (!pbes.isEmpty()) pbeId = pbes[0].Id;
}

Id queueId = null;
List<Group> queues = [SELECT Id, Name FROM Group WHERE Type = 'Queue' LIMIT 1];
if (!queues.isEmpty()) queueId = queues[0].Id;

Id caseTeamRoleId = null;
if (Schema.sObjectType.CaseTeamRole.isAccessible()) {
    List<CaseTeamRole> roles = [SELECT Id FROM CaseTeamRole WHERE Name LIKE 'E2E%' LIMIT 1];
    if (roles.isEmpty()) {
        roles = [SELECT Id FROM CaseTeamRole LIMIT 1];
    }
    if (roles.isEmpty() && Schema.sObjectType.CaseTeamRole.isCreateable()) {
        try {
            CaseTeamRole r = new CaseTeamRole(Name = 'E2E Role', AccessLevel = 'Edit');
            insert r;
            caseTeamRoleId = r.Id;
        } catch (Exception e) {
            System.debug('CaseTeamRole: ' + e.getMessage());
        }
    } else if (!roles.isEmpty()) {
        caseTeamRoleId = roles[0].Id;
    }
}

Id userId = UserInfo.getUserId();
Id otherUserId = null;
for (User u : [SELECT Id, UserType FROM User WHERE IsActive = true AND Id != :userId LIMIT 15]) {
    if (u.UserType == 'Standard') { otherUserId = u.Id; break; }
}
if (otherUserId == null) {
    for (User u : [SELECT Id, UserType FROM User WHERE IsActive = true AND Id != :userId LIMIT 15]) {
        if (u.UserType != 'CloudIntegrationUser') { otherUserId = u.Id; break; }
    }
}

System.debug('Product2Id=' + productId);
System.debug('PricebookEntryId=' + pbeId);
System.debug('QueueId=' + queueId);
System.debug('CaseTeamRoleId=' + caseTeamRoleId);
System.debug('UserId=' + userId);
System.debug('OtherUserId=' + otherUserId);
System.debug('INFRA_DONE=true');
