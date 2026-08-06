/**
 * Remove all E2E / skill-matrix test CRM data from the org.
 * Filter only on filterable fields (no long-text Description WHERE).
 * Order: children → parents.
 */

Set<Id> accIds = new Set<Id>();
for (Account a : [
    SELECT Id FROM Account
    WHERE Name LIKE '%E2E%' OR Website = 'https://e2e.example.com'
    LIMIT 500
]) accIds.add(a.Id);
System.debug('AccIds=' + accIds.size());

// Case team (by subject)
if (Schema.sObjectType.CaseTeamMember.isAccessible() && Schema.sObjectType.CaseTeamMember.isDeletable()) {
    List<CaseTeamMember> ctms = [
        SELECT Id FROM CaseTeamMember
        WHERE ParentId IN (SELECT Id FROM Case WHERE Subject LIKE '%E2E%')
    ];
    if (!ctms.isEmpty()) {
        delete ctms;
        System.debug('Deleted CaseTeamMember=' + ctms.size());
    }
}

// Case comments
if (Schema.sObjectType.CaseComment.isAccessible() && Schema.sObjectType.CaseComment.isDeletable()) {
    List<CaseComment> comments = [
        SELECT Id FROM CaseComment
        WHERE ParentId IN (SELECT Id FROM Case WHERE Subject LIKE '%E2E%')
    ];
    if (!comments.isEmpty()) {
        delete comments;
        System.debug('Deleted CaseComment=' + comments.size());
    }
}

// Cases
List<Case> cases = [SELECT Id FROM Case WHERE Subject LIKE '%E2E%'];
if (!cases.isEmpty()) {
    delete cases;
    System.debug('Deleted Case=' + cases.size());
}

// Campaign members then campaigns
List<Campaign> camps = [SELECT Id FROM Campaign WHERE Name LIKE '%E2E%'];
if (!camps.isEmpty()) {
    List<CampaignMember> cms = [SELECT Id FROM CampaignMember WHERE CampaignId IN :camps];
    if (!cms.isEmpty()) {
        delete cms;
        System.debug('Deleted CampaignMember=' + cms.size());
    }
    delete camps;
    System.debug('Deleted Campaign=' + camps.size());
}

// Opp children
if (Schema.getGlobalDescribe().containsKey('OpportunityTeamMember')) {
    try {
        List<SObject> otm = Database.query(
            'SELECT Id FROM OpportunityTeamMember WHERE OpportunityId IN (SELECT Id FROM Opportunity WHERE Name LIKE \'%E2E%\')'
        );
        if (!otm.isEmpty()) delete otm;
    } catch (Exception e) {
        System.debug('OTM skip ' + e.getMessage());
    }
}
if (Schema.getGlobalDescribe().containsKey('Partner')) {
    try {
        List<SObject> pr = Database.query(
            'SELECT Id FROM Partner WHERE OpportunityId IN (SELECT Id FROM Opportunity WHERE Name LIKE \'%E2E%\')'
        );
        if (!pr.isEmpty()) delete pr;
    } catch (Exception e) {
        System.debug('Partner skip');
    }
}
List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE Name LIKE '%E2E%'];
if (!opps.isEmpty()) {
    List<OpportunityContactRole> ocrs = [SELECT Id FROM OpportunityContactRole WHERE OpportunityId IN :opps];
    if (!ocrs.isEmpty()) delete ocrs;
    List<OpportunityLineItem> olis = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId IN :opps];
    if (!olis.isEmpty()) delete olis;
    delete opps;
    System.debug('Deleted Opportunity=' + opps.size());
}

// Tasks / Events
List<Task> tasks = [SELECT Id FROM Task WHERE Subject LIKE '%E2E%'];
if (!tasks.isEmpty()) {
    delete tasks;
    System.debug('Deleted Task=' + tasks.size());
}
List<Event> events = [SELECT Id FROM Event WHERE Subject LIKE '%E2E%'];
if (!events.isEmpty()) {
    delete events;
    System.debug('Deleted Event=' + events.size());
}

// Orders / OrderItems
List<Order> orders = new List<Order>();
if (!accIds.isEmpty()) {
    orders = [SELECT Id FROM Order WHERE AccountId IN :accIds LIMIT 200];
}
if (orders.isEmpty()) {
    orders = [SELECT Id FROM Order WHERE Account.Name LIKE '%E2E%' LIMIT 200];
}
if (!orders.isEmpty()) {
    List<OrderItem> ois = [SELECT Id FROM OrderItem WHERE OrderId IN :orders];
    if (!ois.isEmpty()) delete ois;
    delete orders;
    System.debug('Deleted Order=' + orders.size());
}

// Contracts
if (!accIds.isEmpty()) {
    List<Contract> contracts = [SELECT Id FROM Contract WHERE AccountId IN :accIds];
    if (!contracts.isEmpty()) {
        try {
            delete contracts;
            System.debug('Deleted Contract=' + contracts.size());
        } catch (Exception e) {
            System.debug('Contract delete skip: ' + e.getMessage());
        }
    }
}

// WorkOrders
if (Schema.getGlobalDescribe().containsKey('WorkOrder')) {
    try {
        List<SObject> wos = Database.query('SELECT Id FROM WorkOrder WHERE Subject LIKE \'%E2E%\'');
        if (!wos.isEmpty()) {
            delete wos;
            System.debug('Deleted WorkOrder=' + wos.size());
        }
    } catch (Exception e) {
        System.debug('WO ' + e.getMessage());
    }
}

// Assets
if (Schema.sObjectType.Asset.isAccessible()) {
    List<Asset> assets = [
        SELECT Id FROM Asset WHERE Name LIKE '%E2E%' OR AccountId IN :accIds
    ];
    if (!assets.isEmpty()) {
        delete assets;
        System.debug('Deleted Asset=' + assets.size());
    }
}

// Contacts / Leads
List<Contact> cons = [
    SELECT Id FROM Contact
    WHERE LastName LIKE '%E2E%' OR FirstName LIKE '%E2E%' OR Email LIKE '%e2e%'
       OR AccountId IN :accIds
];
if (!cons.isEmpty()) {
    delete cons;
    System.debug('Deleted Contact=' + cons.size());
}

List<Lead> leads = [
    SELECT Id, IsConverted FROM Lead
    WHERE LastName LIKE '%E2E%' OR Company LIKE '%E2E%' OR Email LIKE '%e2e%'
];
List<Lead> delLeads = new List<Lead>();
for (Lead l : leads) {
    if (!l.IsConverted) delLeads.add(l);
}
if (!delLeads.isEmpty()) {
    delete delLeads;
    System.debug('Deleted Lead=' + delLeads.size());
}

// Accounts last
List<Account> accs = [
    SELECT Id FROM Account
    WHERE Name LIKE '%E2E%' OR Website = 'https://e2e.example.com'
];
if (!accs.isEmpty()) {
    delete accs;
    System.debug('Deleted Account=' + accs.size());
}

// CaseTeamRole is not deletable via DML in many orgs — leave alone

System.debug('CLEANUP_DONE=true');
