# Prompt Command audit — all 111 skills

Convention:
- **Primary** record of the skill → `Id`
- **Parent / lookups** → org field API names (`CampaignId`, `OpportunityId`, `ParentId`, `AccountId`, …)
- **Standard fields** → org API (`Status`, `Quantity`, `Role`, …)

## Summary

| Verdict | Count |
|---|---|
| Total skills | 111 |
| **Must fix** — parent passed as bare `Id` | **0** |
| Soft inconsistency (XxxId for primary, etc.) | 0 |
| Create skills with spurious optional `Id` | 0 |
| Field casing (role/quantity/status) | 0 |
| Polymorphic parent as `Id` (activity) | 0 |
| OK / no parent-shape issue | 111* |

\* Remaining skills use primary `Id` correctly, correct relationship names, or are search/create with no parent Id confusion.

## 1. MUST FIX — same class of bug as `add_campaign_member`

Parent/filter object is passed as bare `Id` instead of the Salesforce relationship field.

| Skill | Should be | Org model | Current Id description |
|---|---|---|---|
| _(none)_ | | | |

Already fixed earlier: `add_campaign_member`, `fetch_campaign_members` → `CampaignId`.

## 2. Soft inconsistency — primary as `XxxId` (inverse of (1))

Skill’s **primary** record uses a typed Id name; convention prefers bare `Id`.

_None flagged._

## 3. Create skills — remove / rename spurious optional `Id`


## 4. Field API casing


## 5. Polymorphic activity parents


## 6. OK / no parent mislabel

111 skills not in must-fix (search, primary-Id fetch/update, already-correct child parents, etc.).

Notable **already correct** child/parents:
- `add_campaign_member`: parent `CampaignId` OK — CampaignMember.CampaignId
- `add_case_comment`: parent `ParentId` OK — CaseComment.ParentId (Case)
- `add_case_team_member`: parent via alias {'CaseId'} OK — CaseTeamMember.ParentId; CaseId also used in prompts
- `add_cpq_quote_line`: parent `SBQQ__Quote__c` OK — CPQ line parent (QuoteId alias ok)
- `add_opportunity_contact_role`: parent `OpportunityId` OK — OCR.OpportunityId
- `add_opportunity_line_item`: parent `OpportunityId` OK — OpportunityLineItem.OpportunityId
- `add_opportunity_partner`: parent `OpportunityId` OK — partner parent
- `add_opportunity_team_member`: parent `OpportunityId` OK — OTM.OpportunityId
- `add_order_item`: parent `OrderId` OK — OrderItem.OrderId
- `add_quote_line_item`: parent `QuoteId` OK — QuoteLineItem.QuoteId
- `fetch_campaign_members`: parent `CampaignId` OK — CampaignMember.CampaignId
- `fetch_case_entitlements`: parent `CaseId` OK — or AccountId
- `fetch_case_milestones`: parent `CaseId` OK — milestones on case
- `fetch_case_team`: parent via alias {'CaseId'} OK — or CaseId
- `fetch_opportunity_contact_roles`: parent `OpportunityId` OK — filter by opp
- `fetch_opportunity_partners`: parent `OpportunityId` OK — filter by opp
- `fetch_opportunity_team`: parent `OpportunityId` OK — filter by opp
- `link_knowledge_article_to_case`: parent `CaseId` OK — junction Case + article

## Full property dump

| Skill | required | properties | Verdict |
|---|---|---|---|
| `add_campaign_member` | `CampaignId` | `CampaignId`, `ContactId`, `LeadId`, `Status` | ok |
| `add_case_comment` | `ParentId`, `CommentBody` | `ParentId`, `CommentBody`, `IsPublished` | ok |
| `add_case_team_member` | `CaseId`, `UserId` | `CaseId`, `UserId`, `TeamRole` | ok |
| `add_cpq_quote_line` | `SBQQ__Quote__c` | `SBQQ__Quote__c` | ok |
| `add_opportunity_contact_role` | `OpportunityId`, `ContactId`, `Role` | `OpportunityId`, `ContactId`, `Role`, `IsPrimary` | ok |
| `add_opportunity_line_item` | `OpportunityId`, `Quantity`, `UnitPrice` | `OpportunityId`, `PricebookEntryId`, `Name`, `Quantity`, `UnitPrice` | ok |
| `add_opportunity_partner` | `OpportunityId` | `OpportunityId`, `AccountId`, `Role` | ok |
| `add_opportunity_team_member` | `OpportunityId`, `UserId` | `OpportunityId`, `UserId`, `TeamRole` | ok |
| `add_order_item` | `OrderId` | `OrderId` | ok |
| `add_quote_line_item` | `QuoteId` | `QuoteId` | ok |
| `assign_to_queue` | `Id`, `OwnerId` | `Id`, `OwnerId` | ok |
| `calculate_cpq_quote` | `Id` | `Id` | ok |
| `clone_opportunity` | `Id` | `Id`, `Name` | ok |
| `close_case` | `Id` | `Id`, `Reason`, `comments` | ok |
| `complete_task` | `Id` | `Id` | ok |
| `convert_lead` | `Id` | `Id`, `AccountId`, `opportunityName`, `doNotCreateOpportunity` | ok |
| `create_account` | `Name` | `Name`, `fields` | ok |
| `create_campaign` | `Name` | `Name`, `Status`, `Type`, `StartDate`, `EndDate` | ok |
| `create_care_task` | `WhatId`, `Subject` | `WhatId`, `Subject`, `Status`, `Priority`, `Description`, `ActivityDate` | ok |
| `create_case` | `fields` | `fields` | ok |
| `create_contact` | — | `LastName`, `FirstName`, `Email`, `Phone`, `Title`, `AccountId`, `accountName` | ok |
| `create_contract` | `AccountId` | `AccountId`, `Status`, `StartDate`, `ContractTerm`, `Description` | ok |
| `create_cpq_quote` | `OpportunityId` | `OpportunityId`, `Name` | ok |
| `create_event` | `fields` | `fields` | ok |
| `create_lead` | `fields` | `fields` | ok |
| `create_opportunity` | `fields` | `fields` | ok |
| `create_order` | `AccountId`, `Status`, `EffectiveDate` | `AccountId`, `Status`, `EffectiveDate`, `OpportunityId`, `Pricebook2Id` | ok |
| `create_quote` | `Name`, `OpportunityId` | `Name`, `OpportunityId`, `ExpirationDate`, `Status` | ok |
| `create_task` | `fields` | `fields` | ok |
| `create_work_order` | — | `AccountId`, `Name` | ok |
| `fetch_account_details` | — | `Id`, `Name`, `userContextId` | ok |
| `fetch_account_plan` | `Id` | `Id` | ok |
| `fetch_account_related_lists` | `Id` | `Id`, `related` | ok |
| `fetch_asset_details` | `Id` | `Id` | ok |
| `fetch_campaign_details` | `Id` | `Id` | ok |
| `fetch_campaign_members` | `CampaignId` | `CampaignId` | ok |
| `fetch_care_plan` | `Id` | `Id` | ok |
| `fetch_case_details` | `Id` | `Id` | ok |
| `fetch_case_entitlements` | `CaseId` | `CaseId` | ok |
| `fetch_case_milestones` | `CaseId` | `CaseId` | ok |
| `fetch_case_team` | `CaseId` | `CaseId` | ok |
| `fetch_contact_details` | `Id` | `Id` | ok |
| `fetch_contact_engagement_history` | `Id` | `Id`, `daysBack`, `limit` | ok |
| `fetch_contract_details` | `Id` | `Id` | ok |
| `fetch_cpq_quote_details` | `Id` | `Id` | ok |
| `fetch_financial_account` | `Id` | `Id` | ok |
| `fetch_knowledge_article` | `Id` | `Id` | ok |
| `fetch_lead_details` | `Id` | `Id` | ok |
| `fetch_my_open_opportunities` | — | `limit` | ok |
| `fetch_my_open_tasks` | — | `limit` | ok |
| `fetch_opportunity_contact_roles` | `OpportunityId` | `OpportunityId` | ok |
| `fetch_opportunity_details` | `Id` | `Id` | ok |
| `fetch_opportunity_partners` | `OpportunityId` | `OpportunityId` | ok |
| `fetch_opportunity_team` | `OpportunityId` | `OpportunityId` | ok |
| `fetch_order_details` | `Id` | `Id` | ok |
| `fetch_partner_account` | `Id` | `Id` | ok |
| `fetch_picklist_values` | `objectApiName`, `fieldApiName` | `objectApiName`, `fieldApiName`, `controllerValue` | ok |
| `fetch_pricebook_entries` | — | `Pricebook2Id`, `Id`, `limit` | ok |
| `fetch_product_details` | `Id` | `Id` | ok |
| `fetch_queue_cases` | `OwnerId` | `OwnerId`, `limit` | ok |
| `fetch_quote_details` | `Id` | `Id` | ok |
| `fetch_record_approvals` | `Id` | `Id` | ok |
| `fetch_renewal_opportunities` | — | `AccountId` | ok |
| `fetch_service_appointment` | `Id` | `Id` | ok |
| `fetch_service_resource_availability` | `Id` | `Id`, `StartDate`, `EndDate` | ok |
| `fetch_session_context` | — | `Id` | ok |
| `fetch_stale_opportunities` | — | `daysStale` | ok |
| `fetch_subscription_details` | `Id` | `Id` | ok |
| `fetch_upcoming_renewals` | — | `daysAhead`, `AccountId`, `OwnerId`, `limit` | ok |
| `fetch_work_order_details` | `Id` | `Id` | ok |
| `fuzzy_search_accounts` | `searchTerm` | `searchTerm` | ok |
| `fuzzy_search_assets` | `searchTerm` | `searchTerm` | ok |
| `fuzzy_search_campaigns` | `searchTerm` | `searchTerm` | ok |
| `fuzzy_search_cases` | `searchTerm` | `searchTerm` | ok |
| `fuzzy_search_contacts` | `searchTerm` | `searchTerm` | ok |
| `fuzzy_search_leads` | `searchTerm` | `searchTerm` | ok |
| `fuzzy_search_opportunities` | `searchTerm` | `searchTerm` | ok |
| `fuzzy_search_partners` | `searchTerm` | `searchTerm` | ok |
| `fuzzy_search_products` | `searchTerm` | `searchTerm` | ok |
| `fuzzy_search_quotes` | `searchTerm` | `searchTerm` | ok |
| `link_knowledge_article_to_case` | `CaseId`, `KnowledgeArticleId` | `CaseId`, `KnowledgeArticleId` | ok |
| `log_activity` | `Subject` | `WhatId`, `WhoId`, `Subject`, `Description` | ok |
| `remove_campaign_member` | `Id` | `Id` | ok |
| `run_internal_prompt` | `promptRequestId`, `Id` | `promptRequestId`, `Id` | ok |
| `schedule_service_appointment` | `Id` | `Id`, `StartDateTime`, `EndDateTime` | ok |
| `search_knowledge_articles` | `searchTerm` | `searchTerm` | ok |
| `transfer_record_owner` | `Id`, `OwnerId` | `Id`, `OwnerId` | ok |
| `update_account_fields` | `Id` | `Id`, `Name`, `Industry`, `Type`, `AnnualRevenue`, `Phone`, `Website`, `Description` | ok |
| `update_asset_fields` | `Id` | `Id` | ok |
| `update_campaign_fields` | `Id` | `Id` | ok |
| `update_campaign_member_status` | `Id`, `Status` | `Id`, `Status` | ok |
| `update_care_plan_fields` | `Id` | `Id` | ok |
| `update_case_fields` | `Id`, `fields` | `Id`, `fields` | ok |
| `update_contact_fields` | `Id`, `fields` | `Id`, `fields` | ok |
| `update_contract_fields` | `Id` | `Id` | ok |
| `update_cpq_quote_fields` | `Id` | `Id` | ok |
| `update_cpq_quote_line` | `Id` | `Id` | ok |
| `update_event` | `Id` | `Id`, `Subject`, `StartDateTime`, `EndDateTime`, `Location`, `Description` | ok |
| `update_financial_account_fields` | `Id` | `Id` | ok |
| `update_lead_fields` | `Id`, `fields` | `Id`, `fields` | ok |
| `update_opportunity_contact_role` | `Id` | `Id` | ok |
| `update_opportunity_fields` | `Id`, `fields` | `Id`, `fields` | ok |
| `update_opportunity_line_item` | `Id` | `Id`, `Quantity`, `UnitPrice`, `Discount` | ok |
| `update_order_fields` | `Id` | `Id` | ok |
| `update_order_item` | `Id` | `Id` | ok |
| `update_quote_fields` | `Id` | `Id` | ok |
| `update_quote_line_item` | `Id` | `Id` | ok |
| `update_service_appointment` | `Id` | `Id` | ok |
| `update_subscription_fields` | `Id` | `Id` | ok |
| `update_task` | `Id` | `Id`, `Subject`, `Status`, `Priority`, `ActivityDate`, `Description` | ok |
| `update_work_order_fields` | `Id` | `Id` | ok |

