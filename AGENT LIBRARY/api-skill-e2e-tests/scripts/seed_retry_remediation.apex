// Prepare Master Dev for retry of fixable skill failures.
// Safe for E2E seed Case / Account tagged in seed ids.

// --- Case team: free user so add_case_team_member is not DUPLICATE ---
Id caseId;
List<Case> cases = [
    SELECT Id, CaseNumber, Status, IsClosed, OwnerId, AccountId
    FROM Case
    WHERE Subject = 'E2E Skill Test Case'
    LIMIT 1
];
if (!cases.isEmpty()) {
    caseId = cases[0].Id;
    // Remove existing team so re-add succeeds for the first free non-owner active user
    List<CaseTeamMember> existing = [
        SELECT Id, MemberId FROM CaseTeamMember WHERE ParentId = :caseId
    ];
    if (!existing.isEmpty()) {
        delete existing;
        System.debug('Deleted CaseTeamMembers=' + existing.size());
    }
    // Ensure role
    List<CaseTeamRole> roles = [SELECT Id, Name FROM CaseTeamRole LIMIT 5];
    System.debug('CaseTeamRoleId=' + (roles.isEmpty() ? null : roles[0].Id));
} else {
    System.debug('No E2E case');
}

// Open a dedicated open case for close_case / team ops if primary is closed
List<Case> openOnes = [
    SELECT Id, CaseNumber, Status FROM Case
    WHERE Subject = 'E2E Skill Test Case Open' LIMIT 1
];
Case openCase;
if (openOnes.isEmpty()) {
    openCase = new Case(
        Subject = 'E2E Skill Test Case Open',
        Status = 'New',
        Origin = 'Web',
        Description = 'E2E_SKILL_TEST_OPEN',
        AccountId = cases.isEmpty() ? null : cases[0].AccountId
    );
    insert openCase;
} else {
    openCase = openOnes[0];
    if (openCase.Status == 'Closed') {
        openCase.Status = 'New';
        update openCase;
    }
}
openCase = [SELECT Id, CaseNumber, Status FROM Case WHERE Id = :openCase.Id];
System.debug('OpenCaseId=' + openCase.Id);
System.debug('OpenCaseNumber=' + openCase.CaseNumber);

// --- Transfer owner: Account owned by current user; find other active user ---
Id me = UserInfo.getUserId();
List<User> others = [
    SELECT Id, Name, Username, UserType FROM User
    WHERE IsActive = true AND Id != :me
    LIMIT 10
];
// Prefer a real Standard peer if any; else any other active (except pure Integration if avoidable)
Id otherUser = null;
for (User u : others) {
    if (u.UserType == 'Standard') { otherUser = u.Id; break; }
}
if (otherUser == null) {
    for (User u : others) {
        if (u.UserType != 'CloudIntegrationUser') { otherUser = u.Id; break; }
    }
}
if (otherUser == null && !others.isEmpty()) otherUser = others[0].Id;
System.debug('UserId=' + me);
System.debug('OtherUserId=' + otherUser);
System.debug('OtherUserCount=' + others.size());

List<Account> accs = [SELECT Id, OwnerId FROM Account WHERE Name = 'E2E Skill Test Account' LIMIT 1];
if (!accs.isEmpty() && otherUser != null) {
    // Ensure run user currently owns so transfer TO other is meaningful
    if (accs[0].OwnerId != me) {
        accs[0].OwnerId = me;
        update accs[0];
    }
    System.debug('AccountId=' + accs[0].Id);
    System.debug('AccountOwnerId=' + me);
}

// Optional: clear OCR duplicates noise is not needed

System.debug('RetryPrepDone=true');
