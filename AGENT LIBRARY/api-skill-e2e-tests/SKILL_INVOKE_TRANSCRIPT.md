# Skill invoke transcript — all 110

**Org:** Master Dev  
**Agent DevName:** `IT_Helpdesk_Assistant05/08/2026, 11:47`  
**Total:** 110  
**Counts:** {'handler_error': 69, 'handler_ok': 19, 'api_fail': 22}  

Direct invokeAgentSkill: request=JSON tool params, response=Apex/GPTfy payload. Not natural-language agent chat.

## 1. `add_campaign_member`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "CampaignId": "701QH00002FoaPOYAZ"
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not add campaign member
Provide ContactId or LeadId (CampaignMember relationship fields).
```

---

## 2. `add_case_comment`  ·  **handler_ok**

### Request (parameters sent)
```json
{
  "ParentId": "500QH00000VZf8JYAT",
  "CommentBody": "E2E comment body — ignore"
}
```

### Response (API status: `Success`, HTTP 200)
```
✅ Case Comment AddedCase #: 00001000
Comment: E2E comment body &mdash; ignore

👉 View Case
```

---

## 3. `add_case_team_member`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "CaseId": "500QH00000VZf8JYAT",
  "UserId": "005QH00000AhYIQYA3"
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not add case team member
Missing parameter: case_id
```

---

## 4. `add_cpq_quote_line`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "SBQQ__Quote__c": "E2E-smoke"
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not add CPQ quote line
Salesforce CPQ is not installed or SBQQ__Quote__c / SBQQ__QuoteLine__c are not accessible in this org.
```

---

## 5. `add_opportunity_contact_role`  ·  **api_fail**

### Request (parameters sent)
```json
{
  "OpportunityId": "006QH00000KydkYYAR",
  "ContactId": "003QH00000RXZdnYAH",
  "Role": "Decision Maker"
}
```

### Response (API status: `Error`, HTTP 200)
```
(empty)
```

---

## 6. `add_opportunity_line_item`  ·  **api_fail**

### Request (parameters sent)
```json
{
  "OpportunityId": "006QH00000KydkYYAR",
  "Quantity": 1,
  "UnitPrice": 1
}
```

### Response (API status: `Error`, HTTP 200)
```
(empty)
```

---

## 7. `add_opportunity_partner`  ·  **api_fail**

### Request (parameters sent)
```json
{
  "OpportunityId": "006QH00000KydkYYAR"
}
```

### Response (API status: `Error`, HTTP 200)
```
(empty)
```

---

## 8. `add_opportunity_team_member`  ·  **api_fail**

### Request (parameters sent)
```json
{
  "OpportunityId": "006QH00000KydkYYAR",
  "UserId": "005QH00000AhYIQYA3"
}
```

### Response (API status: `Error`, HTTP 200)
```
(empty)
```

---

## 9. `add_order_item`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "OrderId": "E2E-smoke"
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not add order item
Missing parameter: OrderId
```

---

## 10. `add_quote_line_item`  ·  **api_fail**

### Request (parameters sent)
```json
{
  "QuoteId": "E2E-smoke"
}
```

### Response (API status: `Error`, HTTP 200)
```
(empty)
```

---

## 11. `assign_to_queue`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF",
  "OwnerId": "E2E-smoke"
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not assign to queue
Invalid record_id or queue_id.
```

---

## 12. `calculate_cpq_quote`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not calculate CPQ quote
Salesforce CPQ is not installed or SBQQ__Quote__c / SBQQ__QuoteLine__c are not accessible in this org.
```

---

## 13. `clone_opportunity`  ·  **api_fail**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Error`, HTTP 200)
```
(empty)
```

---

## 14. `close_case`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not close case
No case found for provided Id.
```

---

## 15. `complete_task`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not complete task
No task found for provided Id.
```

---

## 16. `convert_lead`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not convert lead
No lead found for provided Id.
```

---

## 17. `create_account`  ·  **handler_ok**

### Request (parameters sent)
```json
{
  "Name": "E2E Smoke Account DO NOT USE"
}
```

### Response (API status: `Success`, HTTP 200)
```
✅ Account CreatedName: E2E Smoke Account DO NOT USE

👉 View Account
```

---

## 18. `create_campaign`  ·  **handler_ok**

### Request (parameters sent)
```json
{
  "Name": "Edge"
}
```

### Response (API status: `Success`, HTTP 200)
```
✅ Campaign CreatedName: Edge

👉 View Campaign
```

---

## 19. `create_care_task`  ·  **handler_ok**

### Request (parameters sent)
```json
{
  "WhatId": "001QH00002FoLakYAF",
  "Subject": "E2E smoke — ignore"
}
```

### Response (API status: `Success`, HTTP 200)
```
✅ Care Task CreatedSubject: E2E smoke &mdash; ignore
WhatId: 001QH00002FoLakYAF

👉 View Task
```

---

## 20. `create_case`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "fields": {
    "Description": "E2E smoke field"
  }
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not create case
Subject is required.
```

---

## 21. `create_contact`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "fields": {
    "Description": "E2E smoke field"
  }
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not create contact
LastName is required.
```

---

## 22. `create_contract`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "AccountId": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not create contract
Status is required.
```

---

## 23. `create_cpq_quote`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "OpportunityId": "006QH00000KydkYYAR"
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not create CPQ quote
Salesforce CPQ is not installed or SBQQ__Quote__c / SBQQ__QuoteLine__c are not accessible in this org.
```

---

## 24. `create_event`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "fields": {
    "Description": "E2E smoke field"
  }
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not create event
Subject is required.
```

---

## 25. `create_lead`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "fields": {
    "Description": "E2E smoke field"
  }
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not create lead
LastName is required.
```

---

## 26. `create_opportunity`  ·  **api_fail**

### Request (parameters sent)
```json
{
  "fields": {
    "Description": "E2E smoke field"
  }
}
```

### Response (API status: `Error`, HTTP 200)
```
(empty)
```

---

## 27. `create_order`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "AccountId": "001QH00002FoLakYAF",
  "Status": "Closed",
  "EffectiveDate": "E2E-smoke"
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not create order
Insert failed. First exception on row 0; first error: INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST, Status: bad value for restricted picklist field: Closed: [Status]
```

---

## 28. `create_quote`  ·  **api_fail**

### Request (parameters sent)
```json
{
  "Name": "Edge",
  "OpportunityId": "006QH00000KydkYYAR"
}
```

### Response (API status: `Error`, HTTP 200)
```
(empty)
```

---

## 29. `create_task`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "fields": {
    "Description": "E2E smoke field"
  }
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not create task
Subject is required.
```

---

## 30. `create_work_order`  ·  **handler_error**

### Request (parameters sent)
```json
{}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not create work order
Subject is required.
```

---

## 31. `fetch_account_plan`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
Account Plan is not available in this org.
```

---

## 32. `fetch_account_related_lists`  ·  **handler_ok**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
{
  "success": true,
  "cases": [
    {
      "attributes": {
        "type": "Case",
        "url": "/services/data/v67.0/sobjects/Case/500QH00000VZf8JYAT"
      },
      "Id": "500QH00000VZf8JYAT",
      "CaseNumber": "00001000",
      "Subject": "Starting generator after electrical failure",
      "Status": "Closed",
      "Priority": "High"
    },
    {
      "attributes": {
        "type": "Case",
        "url": "/services/data/v67.0/sobjects/Case/500QH00000VZf8ZYAT"
      },
      "Id": "500QH00000VZf8ZYAT",
      "CaseNumber": "00001018",
      "Subject": "Cannot start generator after electrical failure",
      "Status": "Closed",
      "Priority": "Medium"
    },
    {
      "attributes": {
        "type": "Case",
        "url": "/services/data/v67.0/sobjects/Case/500QH00000VZf8bYAD"
      },
      "Id": "500QH00000VZf8bYAD",
      "CaseNumber": "00001017",
      "Subject": "Shutting down of generator",
      "Status": "Closed",
      "Priority": "Medium"
    }
  ],
  "opportunities": [
    {
      "attributes": {
        "type": "Opportunity",
        "url": "/services/data/v67.0/sobjects/Opportunity/006QH00000KydkYYAR"
      },
      "Id": "006QH00000KydkYYAR",
      "Name": "Edge SLA",
      "StageName": "Closed Won",
      "Amount": 60000.0,
      "CloseDate": "2024-07-14"
    },
    {
      "attributes": {
        "type": "Opportunity",
        "url": "/services/data/v67.0/sobjects/Opportunity/006QH00000KydkvYAB"
      },
      "Id": "006QH00000KydkvYAB",
      "Name": "Edge Emergency Generator",
      "StageName": "Closed Won",
      "Amount": 75000.0,
      "CloseDate": "2024-07-14"
    },
    {
      "attributes": {
        "type": "Opportunity",
        "url": "/services/data/v67.0/sobjects/Opportunity/006QH00000KydkwYAB"
      },
      "Id": "006QH00000KydkwYAB",
      "Name": "Edge Emergency Generator",
      "StageName": "Id. Decision Makers",
      "Amount": 35000.0,
      "CloseDate": "2024-07-14"
    },
    {
      "attributes": {
        "type": "Opportunity",
        "url": "/services/data/v67.0/sobjects/Opportunity/006QH00000KydkyYAB"
      },
      "Id": "006QH00000KydkyYAB",
      "Name": "Edge Installation",
      "StageName": "Closed Won",
      "Amount": 50000.0,
      "CloseDate": "2024-07-14"
    }
  ],
  "contacts": [
    {
      "attributes": {
        "type": "Contact",
        "url": "/services/data/v67.0/sobjects/Contact/003QH00000RXZdnYAH"
      },
      "Id": "003QH00000RXZdnYAH",
      "Name": "Rose Gonzalez",
      "Email": "rose@edge.com",
      "Phone": "(512) 757-6000",
      "Title": "SVP, Procurement"
    },
    {
      "attributes": {
        "type": "Contact",
        "url": "/services/data/v67.0/sobjects/Contact/003QH00000RXZdoYAH"
      },
      "Id": "003QH00000RXZdoYAH",
      "Name": "Sean Forbes",
      "Email": "sean@edge.com",
      "Phone": "(512) 757-6000",
      "Title": "CFO"
    }
  ],
  "Name": "Edge Communications",
  "Id": "001QH00002FoLakYAF"
}
```

---

## 33. `fetch_asset_details`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
Unsupported skill: fetch_asset_details
```

---

## 34. `fetch_campaign_details`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
No campaign found for provided Id.
```

---

## 35. `fetch_campaign_members`  ·  **handler_ok**

### Request (parameters sent)
```json
{
  "CampaignId": "701QH00002FoaPOYAZ"
}
```

### Response (API status: `Success`, HTTP 200)
```
{
  "success": true,
  "members": [],
  "count": 0,
  "CampaignId": "701QH00002FoaPOYAZ"
}
```

---

## 36. `fetch_care_plan`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
Care Plan object is not available in this org.
```

---

## 37. `fetch_case_details`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
No case found for provided Id/Number.
```

---

## 38. `fetch_case_entitlements`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "CaseId": "500QH00000VZf8JYAT"
}
```

### Response (API status: `Success`, HTTP 200)
```
Missing required parameter: case_id
```

---

## 39. `fetch_case_milestones`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "CaseId": "500QH00000VZf8JYAT"
}
```

### Response (API status: `Success`, HTTP 200)
```
Missing required parameter: case_id
```

---

## 40. `fetch_case_team`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "CaseId": "500QH00000VZf8JYAT"
}
```

### Response (API status: `Success`, HTTP 200)
```
Missing required parameter: case_id
```

---

## 41. `fetch_contact_details`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
Missing required parameter: Id (Contact Id).
```

---

## 42. `fetch_contact_engagement_history`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
No contact found for provided Id.
```

---

## 43. `fetch_contract_details`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
Missing required parameter: Id (Contract Id).
```

---

## 44. `fetch_cpq_quote_details`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
Salesforce CPQ is not installed or SBQQ__Quote__c / SBQQ__QuoteLine__c are not accessible in this org.
```

---

## 45. `fetch_financial_account`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
Financial Account object (FinServ__FinancialAccount__c) is not available in this org.
```

---

## 46. `fetch_knowledge_article`  ·  **handler_ok**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
Knowledge is not enabled in this org.
```

---

## 47. `fetch_lead_details`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
No lead found for provided Id.
```

---

## 48. `fetch_my_open_opportunities`  ·  **handler_ok**

### Request (parameters sent)
```json
{}
```

### Response (API status: `Success`, HTTP 200)
```
{
  "success": true,
  "opportunities": [
    {
      "viewRecord": "View Record",
      "recordUrl": "https://masterdev4-dev-ed.develop.my.salesforce.com/lightning/r/Opportunity/006QH00000KydkZYAR/view",
      "Account": "Grand Hotels & Resorts Ltd",
      "Amount": 15000.0,
      "CloseDate": "2024-07-14",
      "StageName": "Id. Decision Makers",
      "Name": "Grand Hotels Kitchen Generator",
      "Id": "006QH00000KydkZYAR"
    },
    {
      "viewRecord": "View Record",
      "recordUrl": "https://masterdev4-dev-ed.develop.my.salesforce.com/lightning/r/Opportunity/006QH00000KydkbYAB/view",
      "Account": "Express Logistics and Transport",
      "Amount": 80000.0,
      "CloseDate": "2024-07-14",
      "StageName": "Value Proposition",
      "Name": "Express Logistics Portable Truck Generators",
      "Id": "006QH00000KydkbYAB"
    },
    {
      "viewRecord": "View Record",
      "recordUrl": "https://masterdev4-dev-ed.develop.my.salesforce.com/lightning/r/Opportunity/006QH00000KydkcYAB/view",
      "Account": "Express Logistics and Transport",
      "Amount": 120000.0,
      "CloseDate": "2024-07-14",
      "StageName": "Perception Analysis",
      "Name": "Express Logistics SLA",
      "Id": "006QH00000KydkcYAB"
    },
    {
      "viewRecord": "View Record",
      "recordUrl": "https://masterdev4-dev-ed.develop.my.salesforce.com/lightning/r/Opportunity/006QH00000KydkfYAB/view",
      "Account": "University of Arizona",
      "Amount": 100000.0,
      "CloseDate": "2024-07-14",
      "StageName": "Proposal/Price Quote",
      "Name": "University of AZ Installations",
      "Id": "006QH00000KydkfYAB"
    },
    {
      "viewRecord": "View Record",
      "recordUrl": "https://masterdev4-dev-ed.develop.my.salesforce.com/lightning/r/Opportunity/006QH00000KydkjYAB/view",
      "Account": "United Oil & Gas Corp.",
      "Amount": 270000.0,
      "CloseDate": "2024-07-14",
      "StageName": "Negotiation/Review",
      "Name": "United Oil Installations",
      "Id": "006QH00000KydkjYAB"
    },
    {
      "viewRecord": "View Record",
      "recordUrl": "https://masterdev4-dev-ed.develop.my.salesforce.com/lightning/r/Opportunity/006QH00000KydkkYAB/view",
      "Account": "United Oil & Gas Corp.",
      "Amount": 125000.0,
      "CloseDate": "2024-07-14",
      "StageName": "Negotiation/Review",
      "Name": "United Oil Office Portable Generators",
      "Id": "006QH00000KydkkYAB"
    },
    {
      "viewRecord": "View Record",
      "recordUrl": "https://masterdev4-dev-ed.develop.my.salesforce.com/lightning/r/Opportunity/006QH00000KydkpYAB/view",
      "Account": "United Oil & Gas Corp.",
      "Amount": 270000.0,
      "CloseDate": "2024-07-14",
      "StageName": "Proposal/Price Quote",
      "Name": "United Oil Refinery Generators",
      "Id": "006QH00000KydkpYAB"
    },
    {
      "viewRecord": "View Record",
      "recordUrl": "https://masterdev4-dev-ed.develop.my.salesforce.com/lightning/r/Opportunity/006QH00000KydkqYAB/view",
      "Account": "United Oil & Gas Corp.",
      "Amount": 675000.0,
      "CloseDate": "2024-07-14",
      "StageName": "Needs Analysis",
      "Name": "United Oil Plant Standby Generators",
      "Id": "006QH00000KydkqYAB"
    },
    {
      "viewRecord": "View Record",
      "recordUrl": "https://masterdev4-dev-ed.develop.my.salesforce.com/lightning/r/Opportunity/006QH00000KydktYAB/view",
      "Account": "GenePoint",
      "Amount": 60000.0,
      "CloseDate": "2024-07-14",
      "StageName": "Id. D
```

---

## 49. `fetch_my_open_tasks`  ·  **handler_ok**

### Request (parameters sent)
```json
{}
```

### Response (API status: `Success`, HTTP 200)
```
{
  "success": true,
  "tasks": [
    {
      "recordUrl": "https://masterdev4-dev-ed.develop.my.salesforce.com/lightning/r/Task/00TQH00000FPKPV2A5/view",
      "WhoId": null,
      "WhatId": "001QH00002FoLakYAF",
      "DueDate": null,
      "Priority": "Normal",
      "Status": "Not Started",
      "Subject": "E2E smoke — ignore",
      "Id": "00TQH00000FPKPV2A5"
    }
  ],
  "count": 1
}
```

---

## 50. `fetch_opportunity_contact_roles`  ·  **api_fail**

### Request (parameters sent)
```json
{
  "OpportunityId": "006QH00000KydkYYAR"
}
```

### Response (API status: `Error`, HTTP 200)
```
(empty)
```

---

## 51. `fetch_opportunity_details`  ·  **api_fail**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Error`, HTTP 200)
```
(empty)
```

---

## 52. `fetch_opportunity_partners`  ·  **api_fail**

### Request (parameters sent)
```json
{
  "OpportunityId": "006QH00000KydkYYAR"
}
```

### Response (API status: `Error`, HTTP 200)
```
(empty)
```

---

## 53. `fetch_opportunity_team`  ·  **api_fail**

### Request (parameters sent)
```json
{
  "OpportunityId": "006QH00000KydkYYAR"
}
```

### Response (API status: `Error`, HTTP 200)
```
(empty)
```

---

## 54. `fetch_order_details`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
No order found for provided Id.
```

---

## 55. `fetch_partner_account`  ·  **api_fail**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Error`, HTTP 200)
```
(empty)
```

---

## 56. `fetch_picklist_values`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "objectApiName": "E2E-smoke",
  "fieldApiName": "E2E-smoke"
}
```

### Response (API status: `Success`, HTTP 200)
```
Missing required parameter: object_api_name
```

---

## 57. `fetch_pricebook_entries`  ·  **handler_ok**

### Request (parameters sent)
```json
{}
```

### Response (API status: `Success`, HTTP 200)
```
{
  "success": true,
  "entries": [
    {
      "recordUrl": "https://masterdev4-dev-ed.develop.my.salesforce.com/lightning/r/PricebookEntry/01uQH000003sGBKYA2/view",
      "IsActive": true,
      "UnitPrice": 100000.0,
      "ProductName": "GenWatt Diesel 1000kW",
      "Product2Id": "01tQH00000Hh6GdYAJ",
      "Id": "01uQH000003sGBKYA2"
    },
    {
      "recordUrl": "https://masterdev4-dev-ed.develop.my.salesforce.com/lightning/r/PricebookEntry/01uQH000003sGBDYA2/view",
      "IsActive": true,
      "UnitPrice": 5000.0,
      "ProductName": "GenWatt Diesel 10kW",
      "Product2Id": "01tQH00000Hh6GWYAZ",
      "Id": "01uQH000003sGBDYA2"
    },
    {
      "recordUrl": "https://masterdev4-dev-ed.develop.my.salesforce.com/lightning/r/PricebookEntry/01uQH000003sGBCYA2/view",
      "IsActive": true,
      "UnitPrice": 25000.0,
      "ProductName": "GenWatt Diesel 200kW",
      "Product2Id": "01tQH00000Hh6GVYAZ",
      "Id": "01uQH000003sGBCYA2"
    },
    {
      "recordUrl": "https://masterdev4-dev-ed.develop.my.salesforce.com/lightning/r/PricebookEntry/01uQH000003sGBRYA2/view",
      "IsActive": true,
      "UnitPrice": 150000.0,
      "ProductName": "GenWatt Gasoline 2000kW",
      "Product2Id": "01tQH00000Hh6GkYAJ",
      "Id": "01uQH000003sGBRYA2"
    },
    {
      "recordUrl": "https://masterdev4-dev-ed.develop.my.salesforce.com/lightning/r/PricebookEntry/01uQH000003sGBPYA2/view",
      "IsActive": true,
      "UnitPrice": 35000.0,
      "ProductName": "GenWatt Gasoline 300kW",
      "Product2Id": "01tQH00000Hh6GiYAJ",
      "Id": "01uQH000003sGBPYA2"
    },
    {
      "recordUrl": "https://masterdev4-dev-ed.develop.my.salesforce.com/lightning/r/PricebookEntry/01uQH000003sGBMYA2/view",
      "IsActive": true,
      "UnitPrice": 75000.0,
      "ProductName": "GenWatt Gasoline 750kW",
      "Product2Id": "01tQH00000Hh6GfYAJ",
      "Id": "01uQH000003sGBMYA2"
    },
    {
      "recordUrl": "https://masterdev4-dev-ed.develop.my.salesforce.com/lightning/r/PricebookEntry/01uQH000003sGBIYA2/view",
      "IsActive": true,
      "UnitPrice": 15000.0,
      "ProductName": "GenWatt Propane 100kW",
      "Product2Id": "01tQH00000Hh6GbYAJ",
      "Id": "01uQH000003sGBIYA2"
    },
    {
      "recordUrl": "https://masterdev4-dev-ed.develop.my.salesforce.com/lightning/r/PricebookEntry/01uQH000003sGBJYA2/view",
      "IsActive": true,
      "UnitPrice": 120000.0,
      "ProductName": "GenWatt Propane 1500kW",
      "Product2Id": "01tQH00000Hh6GcYAJ",
      "Id": "01uQH000003sGBJYA2"
    },
    {
      "recordUrl": "https://masterdev4-dev-ed.develop.my.salesforce.com/lightning/r/PricebookEntry/01uQH000003sGBGYA2/view",
      "IsActive": true,
      "UnitPrice": 50000.0,
      "ProductName": "GenWatt Propane 500kW",
      "Product2Id": "01tQH00000Hh6GZYAZ",
      "Id": "01uQH000003sGBGYA2"
    },
    {
      "recordUrl": "https://masterdev4-dev-ed.develop.my.salesforce.com/lightning/r/PricebookEntry/01uQH000003sGBEYA2/view",
      "IsActive": true,
      "UnitPrice": 85000.0,
      "ProductName": "Installation: Industrial - High",
      "Product2Id": "01tQH00000Hh6GXYAZ",
      "Id": "01uQH000003sGBEYA2"
    },
    {
      "recordUrl": "https://masterdev4-dev-ed.develop.my.salesforce.com/lightning/r/PricebookEntry/01uQH000003sGBQYA2/view",
      "IsActive": true,
      "UnitPrice": 20000.0,
      "ProductName": "Installation: Industrial - Low",
      "Product2Id": "01tQH00000Hh6GjYAJ",
      "Id": "01uQH000003sGBQYA2"
    },
    {
      "recordU
```

---

## 58. `fetch_product_details`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
No product found for provided Id.
```

---

## 59. `fetch_queue_cases`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "OwnerId": "E2E-smoke"
}
```

### Response (API status: `Success`, HTTP 200)
```
Invalid queue_id.
```

---

## 60. `fetch_quote_details`  ·  **api_fail**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Error`, HTTP 200)
```
(empty)
```

---

## 61. `fetch_record_approvals`  ·  **handler_ok**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
{
  "success": true,
  "approvals": [],
  "count": 0,
  "recordId": "001QH00002FoLakYAF"
}
```

---

## 62. `fetch_renewal_opportunities`  ·  **handler_ok**

### Request (parameters sent)
```json
{}
```

### Response (API status: `Success`, HTTP 200)
```
{
  "success": true,
  "records": [],
  "ownerId": "005QH00000Ahc4IYAR",
  "count": 0
}
```

---

## 63. `fetch_service_appointment`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
ServiceAppointment object is not available in this org.
```

---

## 64. `fetch_service_resource_availability`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
ServiceResource object is not available in this org.
```

---

## 65. `fetch_session_context`  ·  **handler_ok**

### Request (parameters sent)
```json
{}
```

### Response (API status: `Success`, HTTP 200)
```
User Context Id: A-00008 | Record Id: none
```

---

## 66. `fetch_stale_opportunities`  ·  **handler_ok**

### Request (parameters sent)
```json
{}
```

### Response (API status: `Success`, HTTP 200)
```
{
  "success": true,
  "opportunities": [
    {
      "viewRecord": "View Record",
      "recordUrl": "https://masterdev4-dev-ed.develop.my.salesforce.com/lightning/r/Opportunity/006QH00000KydkZYAR/view",
      "Account": "Grand Hotels & Resorts Ltd",
      "LastModifiedDate": "2026-08-05 09:15:37",
      "Amount": 15000.0,
      "CloseDate": "2024-07-14",
      "StageName": "Id. Decision Makers",
      "Name": "Grand Hotels Kitchen Generator",
      "Id": "006QH00000KydkZYAR"
    },
    {
      "viewRecord": "View Record",
      "recordUrl": "https://masterdev4-dev-ed.develop.my.salesforce.com/lightning/r/Opportunity/006QH00000KydkbYAB/view",
      "Account": "Express Logistics and Transport",
      "LastModifiedDate": "2026-08-05 09:15:37",
      "Amount": 80000.0,
      "CloseDate": "2024-07-14",
      "StageName": "Value Proposition",
      "Name": "Express Logistics Portable Truck Generators",
      "Id": "006QH00000KydkbYAB"
    },
    {
      "viewRecord": "View Record",
      "recordUrl": "https://masterdev4-dev-ed.develop.my.salesforce.com/lightning/r/Opportunity/006QH00000KydkcYAB/view",
      "Account": "Express Logistics and Transport",
      "LastModifiedDate": "2026-08-05 09:15:37",
      "Amount": 120000.0,
      "CloseDate": "2024-07-14",
      "StageName": "Perception Analysis",
      "Name": "Express Logistics SLA",
      "Id": "006QH00000KydkcYAB"
    },
    {
      "viewRecord": "View Record",
      "recordUrl": "https://masterdev4-dev-ed.develop.my.salesforce.com/lightning/r/Opportunity/006QH00000KydkfYAB/view",
      "Account": "University of Arizona",
      "LastModifiedDate": "2026-08-05 09:15:37",
      "Amount": 100000.0,
      "CloseDate": "2024-07-14",
      "StageName": "Proposal/Price Quote",
      "Name": "University of AZ Installations",
      "Id": "006QH00000KydkfYAB"
    },
    {
      "viewRecord": "View Record",
      "recordUrl": "https://masterdev4-dev-ed.develop.my.salesforce.com/lightning/r/Opportunity/006QH00000KydkjYAB/view",
      "Account": "United Oil & Gas Corp.",
      "LastModifiedDate": "2026-08-05 09:15:37",
      "Amount": 270000.0,
      "CloseDate": "2024-07-14",
      "StageName": "Negotiation/Review",
      "Name": "United Oil Installations",
      "Id": "006QH00000KydkjYAB"
    },
    {
      "viewRecord": "View Record",
      "recordUrl": "https://masterdev4-dev-ed.develop.my.salesforce.com/lightning/r/Opportunity/006QH00000KydkkYAB/view",
      "Account": "United Oil & Gas Corp.",
      "LastModifiedDate": "2026-08-05 09:15:37",
      "Amount": 125000.0,
      "CloseDate": "2024-07-14",
      "StageName": "Negotiation/Review",
      "Name": "United Oil Office Portable Generators",
      "Id": "006QH00000KydkkYAB"
    },
    {
      "viewRecord": "View Record",
      "recordUrl": "https://masterdev4-dev-ed.develop.my.salesforce.com/lightning/r/Opportunity/006QH00000KydkpYAB/view",
      "Account": "United Oil & Gas Corp.",
      "LastModifiedDate": "2026-08-05 09:15:37",
      "Amount": 270000.0,
      "CloseDate": "2024-07-14",
      "StageName": "Proposal/Price Quote",
      "Name": "United Oil Refinery Generators",
      "Id": "006QH00000KydkpYAB"
    },
    {
      "viewRecord": "View Record",
      "recordUrl": "https://masterdev4-dev-ed.develop.my.salesforce.com/lightning/r/Opportunity/006QH00000KydkqYAB/view",
      "Account": "United Oil & Gas Corp.",
      "LastModifiedDate": "2026-08-05 09:15:37",
      "Amount": 675000.0,
      "CloseDate": "2024-07-14",
      "StageNa
```

---

## 67. `fetch_subscription_details`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
Subscription object is not available in this org.
```

---

## 68. `fetch_upcoming_renewals`  ·  **handler_ok**

### Request (parameters sent)
```json
{}
```

### Response (API status: `Success`, HTTP 200)
```
{
  "success": true,
  "records": [],
  "count": 0,
  "toDate": "2026-11-03",
  "fromDate": "2026-08-05",
  "daysAhead": 90
}
```

---

## 69. `fetch_work_order_details`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
No such column 'ServiceTerritoryId' on entity 'WorkOrder'. If you are attempting to use a custom field, be sure to append the '__c' after the custom field name. Please reference your WSDL or the describe call for the appropriate names.
```

---

## 70. `fuzzy_search_accounts`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "searchTerm": "Acme"
}
```

### Response (API status: `Success`, HTTP 200)
```
No account found matching "Acme".
```

---

## 71. `fuzzy_search_assets`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "searchTerm": "Rose"
}
```

### Response (API status: `Success`, HTTP 200)
```
Unsupported skill: fuzzy_search_assets
```

---

## 72. `fuzzy_search_campaigns`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "searchTerm": "Rose"
}
```

### Response (API status: `Success`, HTTP 200)
```
Missing required parameter: search_term
```

---

## 73. `fuzzy_search_cases`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "searchTerm": "Rose"
}
```

### Response (API status: `Success`, HTTP 200)
```
Missing required parameter: search_term
```

---

## 74. `fuzzy_search_contacts`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "search_term": "Test"
}
```

### Response (API status: `Success`, HTTP 200)
```
No contact found matching "Test".
```

---

## 75. `fuzzy_search_leads`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "searchTerm": "Rose"
}
```

### Response (API status: `Success`, HTTP 200)
```
Missing required parameter: search_term
```

---

## 76. `fuzzy_search_opportunities`  ·  **api_fail**

### Request (parameters sent)
```json
{
  "searchTerm": "Rose"
}
```

### Response (API status: `Error`, HTTP 200)
```
(empty)
```

---

## 77. `fuzzy_search_partners`  ·  **api_fail**

### Request (parameters sent)
```json
{
  "searchTerm": "Rose"
}
```

### Response (API status: `Error`, HTTP 200)
```
(empty)
```

---

## 78. `fuzzy_search_products`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "searchTerm": "Rose"
}
```

### Response (API status: `Success`, HTTP 200)
```
Missing required parameter: search_term
```

---

## 79. `fuzzy_search_quotes`  ·  **api_fail**

### Request (parameters sent)
```json
{
  "searchTerm": "Rose"
}
```

### Response (API status: `Error`, HTTP 200)
```
(empty)
```

---

## 80. `link_knowledge_article_to_case`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "CaseId": "500QH00000VZf8JYAT",
  "KnowledgeArticleId": "E2E-smoke"
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not link article
Missing parameter: case_id
```

---

## 81. `log_activity`  ·  **handler_ok**

### Request (parameters sent)
```json
{
  "Subject": "E2E smoke note — ignore",
  "WhatId": "001QH00002FoLakYAF",
  "record_id": "001QH00002FoLakYAF",
  "activity_subject": "E2E-smoke"
}
```

### Response (API status: `Success`, HTTP 200)
```
✅ Activity Logged: E2E-smokeStatus: Completed
Date: 2026-08-05

👉 View Task
```

---

## 82. `remove_campaign_member`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not remove campaign member
No campaign member found for provided Id.
```

---

## 83. `run_internal_prompt`  ·  **handler_ok**

### Request (parameters sent)
```json
{
  "prompt_request_id": "E2E-smoke",
  "record_id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
{
  "success": true,
  "recordId": "001QH00002FoLakYAF",
  "message": null,
  "status": "success"
}
```

---

## 84. `schedule_service_appointment`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not schedule appointment
ServiceAppointment is not available or creatable in this org.
```

---

## 85. `search_knowledge_articles`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "searchTerm": "Rose"
}
```

### Response (API status: `Success`, HTTP 200)
```
Missing required parameter: search_term
```

---

## 86. `transfer_record_owner`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF",
  "OwnerId": "E2E-smoke"
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not transfer owner
Invalid record_id or new_owner_id.
```

---

## 87. `update_account_fields`  ·  **handler_ok**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF",
  "Description": "e2e smoke",
  "account_id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
✅ Account Updated
Edge CommunicationsDescription: Edge, founded in 1998, is a start-up based in Austin, TX. The company designs and manufactures a device to convert music from one digital format to another. Edge sells its product through retailers and its own website. → e2e smoke

👉 View Account
```

---

## 88. `update_asset_fields`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
Unsupported skill: update_asset_fields
```

---

## 89. `update_campaign_fields`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not update campaign
Missing parameter: at least one field to update
```

---

## 90. `update_campaign_member_status`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF",
  "Status": "Closed"
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not update member status
No campaign member found for provided Id.
```

---

## 91. `update_care_plan_fields`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not update care plan
Care Plan object is not available in this org.
```

---

## 92. `update_case_fields`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF",
  "fields": {
    "Description": "E2E smoke field"
  }
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not update case
No case found for provided Id.
```

---

## 93. `update_contact_fields`  ·  **handler_ok**

### Request (parameters sent)
```json
{
  "contact_id": "003QH00000RXZdnYAH",
  "fields": {
    "Description": "E2E smoke field"
  }
}
```

### Response (API status: `Success`, HTTP 200)
```
✅ Contact Updated
Rose GonzalezDescription: (none) → E2E smoke field

👉 View Contact
```

---

## 94. `update_contract_fields`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not update contract
Missing parameter: Id (Contract Id).
```

---

## 95. `update_cpq_quote_fields`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not update CPQ quote
Salesforce CPQ is not installed or SBQQ__Quote__c / SBQQ__QuoteLine__c are not accessible in this org.
```

---

## 96. `update_cpq_quote_line`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not update CPQ quote line
Salesforce CPQ is not installed or SBQQ__Quote__c / SBQQ__QuoteLine__c are not accessible in this org.
```

---

## 97. `update_event`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not update event
Missing parameter: at least one field to update
```

---

## 98. `update_financial_account_fields`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not update financial account
FinServ__FinancialAccount__c is not available in this org.
```

---

## 99. `update_lead_fields`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF",
  "fields": {
    "Description": "E2E smoke field"
  }
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not update lead
No lead found for provided Id.
```

---

## 100. `update_opportunity_contact_role`  ·  **api_fail**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Error`, HTTP 200)
```
(empty)
```

---

## 101. `update_opportunity_fields`  ·  **api_fail**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF",
  "fields": {
    "Description": "E2E smoke field"
  }
}
```

### Response (API status: `Error`, HTTP 200)
```
(empty)
```

---

## 102. `update_opportunity_line_item`  ·  **api_fail**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Error`, HTTP 200)
```
(empty)
```

---

## 103. `update_order_fields`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not update order
Missing parameter: at least one field to update
```

---

## 104. `update_order_item`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not update order item
Missing parameter: at least one field to update
```

---

## 105. `update_quote_fields`  ·  **api_fail**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Error`, HTTP 200)
```
(empty)
```

---

## 106. `update_quote_line_item`  ·  **api_fail**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Error`, HTTP 200)
```
(empty)
```

---

## 107. `update_service_appointment`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not update appointment
ServiceAppointment is not updateable in this org.
```

---

## 108. `update_subscription_fields`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not update subscription
Subscription object is not available in this org.
```

---

## 109. `update_task`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not update task
Missing parameter: at least one field to update
```

---

## 110. `update_work_order_fields`  ·  **handler_error**

### Request (parameters sent)
```json
{
  "Id": "001QH00002FoLakYAF"
}
```

### Response (API status: `Success`, HTTP 200)
```
⚠️ Could not update work order
Missing parameter: at least one field to update
```

---
