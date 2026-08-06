/**
 * After skills create core CRM with fixed names, resolve Ids + attach required children
 * that skills either don't cover or need deterministic prep (OCR, OLI, campaign member, open lead).
 */
String ACC_NAME = 'E2E Skill Test Account';
String PARTNER_NAME = 'E2E Partner Account';
String CONTACT_NAME_LN = 'E2EContact';
String CONTACT_B_LN = 'E2EContactB';
String LEAD_LN = 'E2ELead';
String LEAD_OPEN_LN = 'E2ELeadOpen';
String CAMP_NAME = 'E2E Skill Test Campaign';
String OPP_NAME = 'E2E Skill Test Opp';
String CASE_SUBJ = 'E2E Skill Test Case';
String TASK_SUBJ = 'E2E Skill Test Task';
String EVENT_SUBJ = 'E2E Skill Test Event';
String ASSET_NAME = 'E2E Skill Test Asset';
String TAG = 'E2E_SKILL_TEST';

Account acc = [SELECT Id, Name FROM Account WHERE Name = :ACC_NAME LIMIT 1];
Account partnerAcc;
List<Account> pAccs = [SELECT Id, Name FROM Account WHERE Name = :PARTNER_NAME LIMIT 1];
if (pAccs.isEmpty()) {
    partnerAcc = new Account(Name = PARTNER_NAME, Type = 'Partner Reseller', Description = TAG);
    insert partnerAcc;
} else {
    partnerAcc = pAccs[0];
}

Contact con = [
    SELECT Id, FirstName, LastName, Email FROM Contact
    WHERE LastName = :CONTACT_NAME_LN AND AccountId = :acc.Id
    ORDER BY CreatedDate DESC LIMIT 1
];
Contact con2;
List<Contact> cons2 = [
    SELECT Id FROM Contact WHERE LastName = :CONTACT_B_LN AND AccountId = :acc.Id LIMIT 1
];
if (cons2.isEmpty()) {
    con2 = new Contact(
        FirstName = 'Sam', LastName = CONTACT_B_LN, AccountId = acc.Id,
        Email = 'e2e.b@example.com', Description = TAG
    );
    insert con2;
} else {
    con2 = cons2[0];
}

Lead ld;
List<Lead> leads = [
    SELECT Id, IsConverted FROM Lead WHERE LastName = :LEAD_LN ORDER BY CreatedDate DESC LIMIT 1
];
if (leads.isEmpty() || leads[0].IsConverted) {
    ld = new Lead(
        FirstName = 'E2E', LastName = LEAD_LN, Company = ACC_NAME,
        Email = 'e2e.lead.' + String.valueOf(DateTime.now().getTime()) + '@example.com',
        Status = 'Open - Not Contacted', Description = TAG
    );
    insert ld;
} else {
    ld = leads[0];
}

Lead ldOpen;
List<Lead> leadsOpen = [SELECT Id FROM Lead WHERE LastName = :LEAD_OPEN_LN LIMIT 1];
if (leadsOpen.isEmpty()) {
    ldOpen = new Lead(
        FirstName = 'Open', LastName = LEAD_OPEN_LN, Company = ACC_NAME,
        Email = 'e2e.lead.open@example.com', Status = 'Open - Not Contacted', Description = TAG
    );
    insert ldOpen;
} else {
    ldOpen = leadsOpen[0];
}

Campaign camp = [SELECT Id FROM Campaign WHERE Name = :CAMP_NAME LIMIT 1];
List<CampaignMember> cms = [
    SELECT Id, Status FROM CampaignMember WHERE CampaignId = :camp.Id AND ContactId = :con.Id LIMIT 1
];
CampaignMember cm;
if (cms.isEmpty()) {
    cm = new CampaignMember(CampaignId = camp.Id, ContactId = con.Id, Status = 'Sent');
    insert cm;
} else {
    cm = cms[0];
}
// Keep ContactB free for add_campaign_member
List<CampaignMember> cmsB = [
    SELECT Id FROM CampaignMember WHERE CampaignId = :camp.Id AND ContactId = :con2.Id
];
if (!cmsB.isEmpty()) delete cmsB;

Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Name = :OPP_NAME LIMIT 1];
List<OpportunityContactRole> ocrs = [
    SELECT Id FROM OpportunityContactRole WHERE OpportunityId = :opp.Id AND ContactId = :con.Id LIMIT 1
];
OpportunityContactRole ocr;
if (ocrs.isEmpty()) {
    ocr = new OpportunityContactRole(
        OpportunityId = opp.Id, ContactId = con.Id, Role = 'Decision Maker', IsPrimary = true
    );
    insert ocr;
} else {
    ocr = ocrs[0];
}

Case cs = [SELECT Id, CaseNumber, Subject, Status, IsClosed FROM Case WHERE Subject = :CASE_SUBJ LIMIT 1];
if (cs.IsClosed == true || cs.Status == 'Closed') {
    cs.Status = 'New';
    update cs;
    cs = [SELECT Id, CaseNumber, Subject, Status, IsClosed FROM Case WHERE Id = :cs.Id];
}
if (Schema.sObjectType.CaseTeamMember.isDeletable()) {
    List<CaseTeamMember> priorTeam = [SELECT Id FROM CaseTeamMember WHERE ParentId = :cs.Id];
    if (!priorTeam.isEmpty()) delete priorTeam;
}

Task tsk;
List<Task> tasks = [SELECT Id, Status FROM Task WHERE Subject = :TASK_SUBJ LIMIT 1];
if (tasks.isEmpty()) {
    tsk = new Task(
        Subject = TASK_SUBJ, Status = 'Not Started', Priority = 'Normal',
        WhatId = acc.Id, WhoId = con.Id, Description = TAG, ActivityDate = Date.today()
    );
    insert tsk;
} else {
    tsk = tasks[0];
    if (tsk.Status == 'Completed') {
        tsk.Status = 'Not Started';
        update tsk;
    }
}

Event ev;
List<Event> events = [SELECT Id FROM Event WHERE Subject = :EVENT_SUBJ LIMIT 1];
if (events.isEmpty()) {
    ev = new Event(
        Subject = EVENT_SUBJ, WhatId = acc.Id, WhoId = con.Id,
        StartDateTime = System.now().addHours(2), EndDateTime = System.now().addHours(3),
        Description = TAG
    );
    insert ev;
} else {
    ev = events[0];
}

// Product / PBE
Id productId = null;
Id pbeId = null;
List<Product2> prods = [SELECT Id FROM Product2 WHERE IsActive = true LIMIT 1];
if (!prods.isEmpty()) {
    productId = prods[0].Id;
    List<PricebookEntry> pbes = [
        SELECT Id FROM PricebookEntry WHERE IsActive = true AND Pricebook2.IsStandard = true LIMIT 1
    ];
    if (!pbes.isEmpty()) pbeId = pbes[0].Id;
}

Asset ast;
List<Asset> assets = [SELECT Id FROM Asset WHERE Name = :ASSET_NAME LIMIT 1];
if (assets.isEmpty() && Schema.sObjectType.Asset.isCreateable()) {
    ast = new Asset(Name = ASSET_NAME, AccountId = acc.Id, ContactId = con.Id, Description = TAG);
    if (productId != null) ast.Product2Id = productId;
    insert ast;
} else if (!assets.isEmpty()) {
    ast = assets[0];
}

Id oliId = null;
if (pbeId != null && Schema.sObjectType.OpportunityLineItem.isCreateable()) {
    List<OpportunityLineItem> olis = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opp.Id LIMIT 1];
    if (olis.isEmpty()) {
        try {
            Id pbId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;
            update new Opportunity(Id = opp.Id, Pricebook2Id = pbId);
            OpportunityLineItem oli = new OpportunityLineItem(
                OpportunityId = opp.Id, PricebookEntryId = pbeId, Quantity = 1, UnitPrice = 100
            );
            insert oli;
            oliId = oli.Id;
        } catch (Exception e) {
            System.debug('OLI: ' + e.getMessage());
        }
    } else {
        oliId = olis[0].Id;
    }
}

Id contractId = null;
if (Schema.sObjectType.Contract.isCreateable()) {
    List<Contract> contracts = [SELECT Id FROM Contract WHERE AccountId = :acc.Id LIMIT 1];
    if (contracts.isEmpty()) {
        try {
            Contract c = new Contract(AccountId = acc.Id, Status = 'Draft', StartDate = Date.today(), ContractTerm = 12);
            insert c;
            contractId = c.Id;
        } catch (Exception e) {
            System.debug('Contract: ' + e.getMessage());
        }
    } else {
        contractId = contracts[0].Id;
    }
}

Id orderId = null;
Id orderItemId = null;
if (Schema.sObjectType.Order.isCreateable() && pbeId != null) {
    List<Order> ords = [SELECT Id FROM Order WHERE AccountId = :acc.Id ORDER BY CreatedDate DESC LIMIT 1];
    if (ords.isEmpty()) {
        try {
            Id pbId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;
            Order o = new Order(
                AccountId = acc.Id, EffectiveDate = Date.today(), Status = 'Draft', Pricebook2Id = pbId
            );
            insert o;
            orderId = o.Id;
            if (Schema.sObjectType.OrderItem.isCreateable()) {
                OrderItem oi = new OrderItem(
                    OrderId = o.Id, PricebookEntryId = pbeId, Quantity = 1, UnitPrice = 50
                );
                insert oi;
                orderItemId = oi.Id;
            }
        } catch (Exception e) {
            System.debug('Order: ' + e.getMessage());
        }
    } else {
        orderId = ords[0].Id;
        List<OrderItem> ois = [SELECT Id FROM OrderItem WHERE OrderId = :orderId LIMIT 1];
        if (!ois.isEmpty()) orderItemId = ois[0].Id;
    }
}

Id workOrderId = null;
if (Schema.getGlobalDescribe().containsKey('WorkOrder')
    && Schema.getGlobalDescribe().get('WorkOrder').getDescribe().isCreateable()) {
    List<SObject> wos = Database.query(
        'SELECT Id FROM WorkOrder WHERE Subject = \'E2E Skill Test Work Order\' LIMIT 1'
    );
    if (wos.isEmpty()) {
        try {
            SObject wo = Schema.getGlobalDescribe().get('WorkOrder').newSObject();
            wo.put('Subject', 'E2E Skill Test Work Order');
            wo.put('AccountId', acc.Id);
            wo.put('Status', 'New');
            insert wo;
            workOrderId = (Id) wo.get('Id');
        } catch (Exception e) {
            System.debug('WO: ' + e.getMessage());
        }
    } else {
        workOrderId = (Id) wos[0].get('Id');
    }
}

Id queueId = null;
List<Group> queues = [SELECT Id FROM Group WHERE Type = 'Queue' LIMIT 1];
if (!queues.isEmpty()) queueId = queues[0].Id;

Id caseTeamRoleId = null;
if (Schema.sObjectType.CaseTeamRole.isAccessible()) {
    List<CaseTeamRole> roles = [SELECT Id FROM CaseTeamRole LIMIT 1];
    if (!roles.isEmpty()) caseTeamRoleId = roles[0].Id;
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

System.debug('===E2E_SEED_START===');
System.debug('AccountId=' + acc.Id);
System.debug('ContactId=' + con.Id);
System.debug('ContactIdB=' + con2.Id);
System.debug('LeadId=' + ld.Id);
System.debug('LeadIdOpen=' + ldOpen.Id);
System.debug('CampaignId=' + camp.Id);
System.debug('CampaignMemberId=' + cm.Id);
System.debug('OpportunityId=' + opp.Id);
System.debug('OpportunityContactRoleId=' + ocr.Id);
System.debug('OpportunityLineItemId=' + oliId);
System.debug('CaseId=' + cs.Id);
System.debug('CaseNumber=' + cs.CaseNumber);
System.debug('CaseTeamRoleId=' + caseTeamRoleId);
System.debug('TaskId=' + tsk.Id);
System.debug('EventId=' + ev.Id);
System.debug('AssetId=' + (ast != null ? String.valueOf(ast.Id) : 'null'));
System.debug('Product2Id=' + productId);
System.debug('PricebookEntryId=' + pbeId);
System.debug('ContractId=' + contractId);
System.debug('OrderId=' + orderId);
System.debug('OrderItemId=' + orderItemId);
System.debug('WorkOrderId=' + workOrderId);
System.debug('PartnerAccountId=' + partnerAcc.Id);
System.debug('QueueId=' + queueId);
System.debug('UserId=' + userId);
System.debug('OtherUserId=' + otherUserId);
System.debug('SearchContact=' + con.FirstName + ' ' + con.LastName);
System.debug('SearchAccount=' + acc.Name);
System.debug('SearchPartner=' + partnerAcc.Name);
System.debug('===E2E_SEED_END===');
