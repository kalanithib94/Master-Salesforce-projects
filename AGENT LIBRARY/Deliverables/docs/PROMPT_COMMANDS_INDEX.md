# Prompt params index (quick scan)

Full detail: [PROMPT_COMMANDS_BY_SKILL.md](PROMPT_COMMANDS_BY_SKILL.md) | [PROMPT_COMMANDS_BY_SKILL.json](PROMPT_COMMANDS_BY_SKILL.json)

| Skill | required | properties |
|-------|----------|------------|
| `add_campaign_member` | `["CampaignId"]` | `CampaignId`, `ContactId`, `LeadId`, `Status` |
| `add_case_comment` | `["ParentId", "CommentBody"]` | `ParentId`, `CommentBody`, `IsPublished` |
| `add_case_team_member` | `["CaseId", "UserId"]` | `CaseId`, `UserId`, `TeamRole` |
| `add_cpq_quote_line` | `["SBQQ__Quote__c"]` | `SBQQ__Quote__c` |
| `add_opportunity_contact_role` | `["OpportunityId", "ContactId", "Role"]` | `OpportunityId`, `ContactId`, `Role`, `IsPrimary` |
| `add_opportunity_line_item` | `["OpportunityId", "Quantity", "UnitPrice"]` | `OpportunityId`, `PricebookEntryId`, `Name`, `Quantity`, `UnitPrice` |
| `add_opportunity_partner` | `["OpportunityId"]` | `OpportunityId`, `AccountId`, `Role` |
| `add_opportunity_team_member` | `["OpportunityId", "UserId"]` | `OpportunityId`, `UserId`, `TeamRole` |
| `add_order_item` | `["OrderId"]` | `OrderId` |
| `add_quote_line_item` | `["QuoteId"]` | `QuoteId` |
| `assign_to_queue` | `["Id", "OwnerId"]` | `Id`, `OwnerId` |
| `calculate_cpq_quote` | `["Id"]` | `Id` |
| `clone_opportunity` | `["Id"]` | `Id`, `Name` |
| `close_case` | `["Id"]` | `Id`, `Status`, `Reason`, `Comments` |
| `complete_task` | `["Id"]` | `Id` |
| `convert_lead` | `["Id"]` | `Id`, `AccountId`, `opportunityName`, `doNotCreateOpportunity` |
| `create_account` | `["Name"]` | `Name`, `fields` |
| `create_campaign` | `["Name"]` | `Name`, `Status`, `Type`, `StartDate`, `EndDate` |
| `create_care_task` | `["WhatId", "Subject"]` | `WhatId`, `Subject`, `Status`, `Priority`, `Description`, `ActivityDate` |
| `create_case` | `["fields"]` | `fields` |
| `create_contact` | `[]` | `LastName`, `FirstName`, `Email`, `Phone`, `Title`, `AccountId`, `accountName` |
| `create_contract` | `["AccountId"]` | `AccountId`, `Status`, `StartDate`, `ContractTerm`, `Description` |
| `create_cpq_quote` | `["OpportunityId"]` | `OpportunityId`, `Name` |
| `create_event` | `["fields"]` | `fields` |
| `create_lead` | `["fields"]` | `fields` |
| `create_opportunity` | `["fields"]` | `fields` |
| `create_order` | `["AccountId", "Status", "EffectiveDate"]` | `AccountId`, `Status`, `EffectiveDate`, `OpportunityId`, `Pricebook2Id` |
| `create_quote` | `["Name", "OpportunityId"]` | `Name`, `OpportunityId`, `ExpirationDate`, `Status` |
| `create_task` | `["fields"]` | `fields` |
| `create_work_order` | `[]` | `AccountId`, `Name` |
| `fetch_account_details` | `[]` | `Id`, `Name`, `userContextId` |
| `fetch_account_plan` | `["Id"]` | `Id` |
| `fetch_account_related_lists` | `["Id"]` | `Id`, `related` |
| `fetch_asset_details` | `["Id"]` | `Id` |
| `fetch_campaign_details` | `["Id"]` | `Id` |
| `fetch_campaign_members` | `["CampaignId"]` | `CampaignId` |
| `fetch_care_plan` | `["Id"]` | `Id` |
| `fetch_case_details` | `["Id"]` | `Id` |
| `fetch_case_entitlements` | `["CaseId"]` | `CaseId` |
| `fetch_case_milestones` | `["CaseId"]` | `CaseId` |
| `fetch_case_team` | `["CaseId"]` | `CaseId` |
| `fetch_contact_details` | `["Id"]` | `Id` |
| `fetch_contact_engagement_history` | `["Id"]` | `Id`, `daysBack`, `limit` |
| `fetch_contract_details` | `["Id"]` | `Id` |
| `fetch_cpq_quote_details` | `["Id"]` | `Id` |
| `fetch_financial_account` | `["Id"]` | `Id` |
| `fetch_knowledge_article` | `["Id"]` | `Id` |
| `fetch_lead_details` | `["Id"]` | `Id` |
| `fetch_my_open_opportunities` | `[]` | `limit` |
| `fetch_my_open_tasks` | `[]` | `limit` |
| `fetch_opportunity_contact_roles` | `["OpportunityId"]` | `OpportunityId` |
| `fetch_opportunity_details` | `["Id"]` | `Id` |
| `fetch_opportunity_partners` | `["OpportunityId"]` | `OpportunityId` |
| `fetch_opportunity_team` | `["OpportunityId"]` | `OpportunityId` |
| `fetch_order_details` | `["Id"]` | `Id` |
| `fetch_partner_account` | `["Id"]` | `Id` |
| `fetch_picklist_values` | `["objectApiName", "fieldApiName"]` | `objectApiName`, `fieldApiName`, `controllerValue` |
| `fetch_pricebook_entries` | `[]` | `Pricebook2Id`, `Id`, `limit` |
| `fetch_product_details` | `["Id"]` | `Id` |
| `fetch_queue_cases` | `["OwnerId"]` | `OwnerId`, `limit` |
| `fetch_quote_details` | `["Id"]` | `Id` |
| `fetch_record_approvals` | `["Id"]` | `Id` |
| `fetch_renewal_opportunities` | `[]` | `AccountId` |
| `fetch_service_appointment` | `["Id"]` | `Id` |
| `fetch_service_resource_availability` | `["Id"]` | `Id`, `StartDate`, `EndDate` |
| `fetch_session_context` | `[]` | `Id` |
| `fetch_stale_opportunities` | `[]` | `daysStale` |
| `fetch_subscription_details` | `["Id"]` | `Id` |
| `fetch_upcoming_renewals` | `[]` | `daysAhead`, `AccountId`, `OwnerId`, `limit` |
| `fetch_work_order_details` | `["Id"]` | `Id` |
| `fuzzy_search_accounts` | `["searchTerm"]` | `searchTerm` |
| `fuzzy_search_assets` | `["searchTerm"]` | `searchTerm` |
| `fuzzy_search_campaigns` | `["searchTerm"]` | `searchTerm` |
| `fuzzy_search_cases` | `["searchTerm"]` | `searchTerm` |
| `fuzzy_search_contacts` | `["searchTerm"]` | `searchTerm` |
| `fuzzy_search_leads` | `["searchTerm"]` | `searchTerm` |
| `fuzzy_search_opportunities` | `["searchTerm"]` | `searchTerm` |
| `fuzzy_search_partners` | `["searchTerm"]` | `searchTerm` |
| `fuzzy_search_products` | `["searchTerm"]` | `searchTerm` |
| `fuzzy_search_quotes` | `["searchTerm"]` | `searchTerm` |
| `link_knowledge_article_to_case` | `["CaseId", "KnowledgeArticleId"]` | `CaseId`, `KnowledgeArticleId` |
| `log_activity` | `["Subject"]` | `WhatId`, `WhoId`, `Subject`, `Description` |
| `remove_campaign_member` | `["Id"]` | `Id` |
| `run_internal_prompt` | `["promptRequestId", "Id"]` | `promptRequestId`, `Id` |
| `schedule_service_appointment` | `["Id"]` | `Id`, `StartDateTime`, `EndDateTime` |
| `search_knowledge_articles` | `["searchTerm"]` | `searchTerm` |
| `transfer_record_owner` | `["Id", "OwnerId"]` | `Id`, `OwnerId` |
| `update_account_fields` | `["Id"]` | `Id`, `Name`, `Industry`, `Type`, `AnnualRevenue`, `Phone`, `Website`, `Description` |
| `update_asset_fields` | `["Id"]` | `Id` |
| `update_campaign_fields` | `["Id"]` | `Id` |
| `update_campaign_member_status` | `["Id", "Status"]` | `Id`, `Status` |
| `update_care_plan_fields` | `["Id"]` | `Id` |
| `update_case_fields` | `["Id", "fields"]` | `Id`, `fields` |
| `update_contact_fields` | `["Id", "fields"]` | `Id`, `fields` |
| `update_contract_fields` | `["Id"]` | `Id` |
| `update_cpq_quote_fields` | `["Id"]` | `Id` |
| `update_cpq_quote_line` | `["Id"]` | `Id` |
| `update_event` | `["Id"]` | `Id`, `Subject`, `StartDateTime`, `EndDateTime`, `Location`, `Description` |
| `update_financial_account_fields` | `["Id"]` | `Id` |
| `update_lead_fields` | `["Id", "fields"]` | `Id`, `fields` |
| `update_opportunity_contact_role` | `["Id"]` | `Id` |
| `update_opportunity_fields` | `["Id", "fields"]` | `Id`, `fields` |
| `update_opportunity_line_item` | `["Id"]` | `Id`, `Quantity`, `UnitPrice`, `Discount` |
| `update_order_fields` | `["Id"]` | `Id` |
| `update_order_item` | `["Id"]` | `Id` |
| `update_quote_fields` | `["Id"]` | `Id` |
| `update_quote_line_item` | `["Id"]` | `Id` |
| `update_service_appointment` | `["Id"]` | `Id` |
| `update_subscription_fields` | `["Id"]` | `Id` |
| `update_task` | `["Id"]` | `Id`, `Subject`, `Status`, `Priority`, `ActivityDate`, `Description` |
| `update_work_order_fields` | `["Id"]` | `Id` |
