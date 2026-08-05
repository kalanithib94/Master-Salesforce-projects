// Seed E2E test data for Master Dev agent skill matrix.
// Creates dedicated records tagged E2E_SKILL_TEST so runs are self-contained.
// Safe to re-run (upsert-by-external-style via name match).

String TAG = 'E2E_SKILL_TEST';
String ACC_NAME = 'E2E Skill Test Account';
String CONTACT_LN = 'E2EContact';
String LEAD_LN = 'E2ELead';
String CAMP_NAME = 'E2E Skill Test Campaign';
String OPP_NAME = 'E2E Skill Test Opp';
String ASSET_NAME = 'E2E Skill Test Asset';
String CASE_SUBJ = 'E2E Skill Test Case';
String TASK_SUBJ = 'E2E Skill Test Task';
String EVENT_SUBJ = 'E2E Skill Test Event';

// --- Account ---
List<Account> accs = [SELECT Id, Name FROM Account WHERE Name = :ACC_NAME LIMIT 1];
Account acc;
if (accs.isEmpty()) {
    acc = new Account(Name = ACC_NAME, Description = TAG, Phone = '555-0100', Website = 'https://e2e.example.com');
    insert acc;
} else {
    acc = accs[0];
}

// --- Contact ---
List<Contact> contacts = [SELECT Id, FirstName, LastName, Email FROM Contact WHERE LastName = :CONTACT_LN AND AccountId = :acc.Id LIMIT 1];
Contact con;
if (contacts.isEmpty()) {
    con = new Contact(
        FirstName = 'Rose', LastName = CONTACT_LN, AccountId = acc.Id,
        Email = 'e2e.contact@example.com', Phone = '555-0101', Description = TAG
    );
    insert con;
} else {
    con = contacts[0];
}

// --- Lead (disposable for convert; recreate if already converted) ---
List<Lead> leads = [SELECT Id, LastName, Company, Status, IsConverted FROM Lead WHERE LastName = :LEAD_LN LIMIT 1];
Lead ld;
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

// --- Campaign + Member ---
List<Campaign> camps = [SELECT Id, Name FROM Campaign WHERE Name = :CAMP_NAME LIMIT 1];
Campaign camp;
if (camps.isEmpty()) {
    camp = new Campaign(Name = CAMP_NAME, IsActive = true, Status = 'Planned', Description = TAG);
    insert camp;
} else {
    camp = camps[0];
}
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

// --- Opportunity ---
List<Opportunity> opps = [SELECT Id, Name, StageName FROM Opportunity WHERE Name = :OPP_NAME LIMIT 1];
Opportunity opp;
if (opps.isEmpty()) {
    opp = new Opportunity(
        Name = OPP_NAME, AccountId = acc.Id, StageName = 'Prospecting',
        CloseDate = Date.today().addDays(30), Description = TAG
    );
    insert opp;
} else {
    opp = opps[0];
}

// --- Opportunity Contact Role ---
List<OpportunityContactRole> ocrs = [
    SELECT Id, Role FROM OpportunityContactRole WHERE OpportunityId = :opp.Id AND ContactId = :con.Id LIMIT 1
];
OpportunityContactRole ocr;
if (ocrs.isEmpty()) {
    ocr = new OpportunityContactRole(OpportunityId = opp.Id, ContactId = con.Id, Role = 'Decision Maker', IsPrimary = true);
    insert ocr;
} else {
    ocr = ocrs[0];
}

// --- Case ---
List<Case> cases = [SELECT Id, CaseNumber, Subject, Status FROM Case WHERE Subject = :CASE_SUBJ LIMIT 1];
Case cs;
if (cases.isEmpty()) {
    cs = new Case(
        Subject = CASE_SUBJ, Status = 'New', Origin = 'Web',
        AccountId = acc.Id, ContactId = con.Id, Description = TAG
    );
    insert cs;
} else {
    cs = cases[0];
}
// Re-open case used for updates/close tests
cs = [SELECT Id, CaseNumber, Subject, Status, IsClosed FROM Case WHERE Id = :cs.Id];
if (cs.IsClosed == true || cs.Status == 'Closed') {
    cs.Status = 'New';
    update cs;
    cs = [SELECT Id, CaseNumber, Subject, Status, IsClosed FROM Case WHERE Id = :cs.Id];
}

// --- Task ---
List<Task> tasks = [SELECT Id, Subject, Status FROM Task WHERE Subject = :TASK_SUBJ LIMIT 1];
Task tsk;
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

// --- Event ---
List<Event> events = [SELECT Id, Subject FROM Event WHERE Subject = :EVENT_SUBJ LIMIT 1];
Event ev;
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

// --- Product + Asset ---
List<Product2> prods = [SELECT Id, Name FROM Product2 WHERE IsActive = true LIMIT 1];
Id productId = prods.isEmpty() ? null : prods[0].Id;

Asset ast;
List<Asset> assets = [SELECT Id, Name FROM Asset WHERE Name = :ASSET_NAME LIMIT 1];
if (assets.isEmpty()) {
    if (Schema.sObjectType.Asset.isCreateable()) {
        ast = new Asset(Name = ASSET_NAME, AccountId = acc.Id, ContactId = con.Id, Description = TAG);
        if (productId != null) ast.Product2Id = productId;
        insert ast;
    }
} else {
    ast = assets[0];
}

// --- PricebookEntry ---
Id pbeId = null;
List<PricebookEntry> pbes = [
    SELECT Id FROM PricebookEntry WHERE IsActive = true AND Pricebook2.IsStandard = true LIMIT 1
];
if (!pbes.isEmpty()) pbeId = pbes[0].Id;

// --- Contract (optional) ---
Id contractId = null;
if (Schema.sObjectType.Contract.isCreateable()) {
    List<Contract> contracts = [SELECT Id FROM Contract WHERE AccountId = :acc.Id LIMIT 1];
    if (contracts.isEmpty()) {
        try {
            Contract c = new Contract(AccountId = acc.Id, Status = 'Draft', StartDate = Date.today(), ContractTerm = 12);
            insert c;
            contractId = c.Id;
        } catch (Exception e) {
            System.debug('Contract create skip: ' + e.getMessage());
        }
    } else {
        contractId = contracts[0].Id;
    }
}

// --- Queue (if any Group with Type=Queue) ---
Id queueId = null;
List<Group> queues = [SELECT Id, Name FROM Group WHERE Type = 'Queue' LIMIT 1];
if (!queues.isEmpty()) queueId = queues[0].Id;

// --- User ---
Id userId = UserInfo.getUserId();
Id otherUserId = null;
List<User> others = [
    SELECT Id FROM User
    WHERE IsActive = true AND Id != :userId AND UserType = 'Standard'
    LIMIT 1
];
if (!others.isEmpty()) otherUserId = others[0].Id;

// --- Second Contact (for add_campaign_member without duplicate) ---
Contact con2;
List<Contact> cons2 = [SELECT Id FROM Contact WHERE LastName = 'E2EContactB' AND AccountId = :acc.Id LIMIT 1];
if (cons2.isEmpty()) {
    con2 = new Contact(FirstName = 'Sam', LastName = 'E2EContactB', AccountId = acc.Id, Email = 'e2e.b@example.com');
    insert con2;
} else {
    con2 = cons2[0];
}

// Ensure ContactB is not already a campaign member so add_campaign_member can pass
List<CampaignMember> cmsB = [
    SELECT Id FROM CampaignMember WHERE CampaignId = :camp.Id AND ContactId = :con2.Id LIMIT 1
];
if (!cmsB.isEmpty()) {
    delete cmsB;
}

// --- Open Lead for update_lead_fields (never convert this one) ---
Lead ldOpen;
List<Lead> leadsOpen = [SELECT Id FROM Lead WHERE LastName = 'E2ELeadOpen' LIMIT 1];
if (leadsOpen.isEmpty()) {
    ldOpen = new Lead(
        FirstName = 'Open', LastName = 'E2ELeadOpen', Company = ACC_NAME,
        Email = 'e2e.lead.open@example.com', Status = 'Open - Not Contacted'
    );
    insert ldOpen;
} else {
    ldOpen = leadsOpen[0];
}

// --- Partner-style Account ---
Account partnerAcc;
List<Account> pAccs = [SELECT Id, Name FROM Account WHERE Name = 'E2E Partner Account' LIMIT 1];
if (pAccs.isEmpty()) {
    partnerAcc = new Account(Name = 'E2E Partner Account', Type = 'Partner Reseller', Description = TAG);
    insert partnerAcc;
} else {
    partnerAcc = pAccs[0];
}

// --- Opportunity Line Item ---
Id oliId = null;
if (pbeId != null && Schema.sObjectType.OpportunityLineItem.isCreateable()) {
    List<OpportunityLineItem> olis = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opp.Id LIMIT 1];
    if (olis.isEmpty()) {
        try {
            // Ensure pricebook on opp
            Opportunity ou = new Opportunity(Id = opp.Id, Pricebook2Id = [
                SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1
            ].Id);
            update ou;
            OpportunityLineItem oli = new OpportunityLineItem(
                OpportunityId = opp.Id, PricebookEntryId = pbeId, Quantity = 1, UnitPrice = 100
            );
            insert oli;
            oliId = oli.Id;
        } catch (Exception e) {
            System.debug('OLI seed skip: ' + e.getMessage());
        }
    } else {
        oliId = olis[0].Id;
    }
}

// --- Order + OrderItem ---
Id orderId = null;
Id orderItemId = null;
if (Schema.sObjectType.Order.isCreateable() && pbeId != null) {
    List<Order> ords = [SELECT Id FROM Order WHERE AccountId = :acc.Id ORDER BY CreatedDate DESC LIMIT 1];
    if (ords.isEmpty()) {
        try {
            Id pbId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;
            Order o = new Order(
                AccountId = acc.Id,
                EffectiveDate = Date.today(),
                Status = 'Draft',
                Pricebook2Id = pbId
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
            System.debug('Order seed skip: ' + e.getMessage());
        }
    } else {
        orderId = ords[0].Id;
        List<OrderItem> ois = [SELECT Id FROM OrderItem WHERE OrderId = :orderId LIMIT 1];
        if (!ois.isEmpty()) orderItemId = ois[0].Id;
    }
}

// --- Work Order ---
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
            System.debug('WO seed skip: ' + e.getMessage());
        }
    } else {
        workOrderId = (Id) wos[0].get('Id');
    }
}

// --- Case Team Role ---
Id caseTeamRoleId = null;
if (Schema.sObjectType.CaseTeamRole.isAccessible()) {
    List<CaseTeamRole> roles = [SELECT Id FROM CaseTeamRole WITH USER_MODE LIMIT 1];
    if (roles.isEmpty() && Schema.sObjectType.CaseTeamRole.isCreateable()) {
        try {
            CaseTeamRole r = new CaseTeamRole(Name = 'E2E Role', AccessLevel = 'Edit');
            insert r;
            caseTeamRoleId = r.Id;
        } catch (Exception e) {
            System.debug('CaseTeamRole seed skip: ' + e.getMessage());
        }
    } else if (!roles.isEmpty()) {
        caseTeamRoleId = roles[0].Id;
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
