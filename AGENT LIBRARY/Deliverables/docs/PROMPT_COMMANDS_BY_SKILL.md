# Prompt Commands by skill

Total skills: **111**

Auto-generated from `Deliverables/kb-catalog/packages/<skill>/seed.apex` (`ccai__Prompt_Command__c`). Do not hand-edit skill sections — re-run `python scripts/extract_prompt_commands.py` after package changes.

Related: [PROMPT_COMMANDS_INDEX.md](PROMPT_COMMANDS_INDEX.md) · [PROMPT_COMMANDS_BY_SKILL.json](PROMPT_COMMANDS_BY_SKILL.json) · [PROMPT_COMMANDS_AUDIT.md](PROMPT_COMMANDS_AUDIT.md)

## Naming convention

| Kind | Param style | Examples |
|------|-------------|----------|
| Primary record of the skill | `Id` | `fetch_account_details.Id`, `update_case_fields.Id`, `clone_opportunity.Id` |
| Parent / relationship field | Salesforce field API name | `CampaignId`, `OpportunityId`, `AccountId`, `ParentId`, `OrderId`, `QuoteId`, `SBQQ__Quote__c` |
| Polymorphic activity parent | `WhatId` / `WhoId` | `log_activity`, `create_care_task` (`WhatId`) |
| Standard fields | Org API case | `Status`, `Quantity`, `UnitPrice`, `Role`, `Subject`, `Reason` |

**Do not** pass a parent campaign / opportunity / order as bare `Id` when creating or listing children (e.g. `add_campaign_member` takes `CampaignId`, not CampaignMember/`Id`).

---

## `add_campaign_member`

- **required:** `["CampaignId"]`
- **properties:**
  - `CampaignId` (`string`) - Parent Campaign Id (CampaignMember.CampaignId). Create a CampaignMember under this campaign - do NOT pass CampaignMember Id.
  - `ContactId` (`string`) - Contact to enroll (CampaignMember.ContactId). Use ContactId OR LeadId, not both.
  - `LeadId` (`string`) - Lead to enroll (CampaignMember.LeadId). Use LeadId OR ContactId, not both.
  - `Status` (`string`) - Optional CampaignMember.Status picklist API value (e.g. Sent, Responded).

## `add_case_comment`

- **required:** `["ParentId", "CommentBody"]`
- **properties:**
  - `ParentId` (`string`) - Case Id to comment on (CaseComment.ParentId). Not the CaseComment Id.
  - `CommentBody` (`string`) - Text of the public case comment - must be confirmed with the user.
  - `IsPublished` (`boolean`) - Optional. Defaults true (visible to customer portal when applicable).

## `add_case_team_member`

- **required:** `["CaseId", "UserId"]`
- **properties:**
  - `CaseId` (`string`) - Salesforce case id.
  - `UserId` (`string`)
  - `TeamRole` (`string`)

## `add_cpq_quote_line`

- **required:** `["SBQQ__Quote__c"]`
- **properties:**
  - `SBQQ__Quote__c` (`string`) - Parent CPQ Quote Id (SBQQ__QuoteLine__c.SBQQ__Quote__c). Not the quote-line Id.

## `add_opportunity_contact_role`

- **required:** `["OpportunityId", "ContactId", "Role"]`
- **properties:**
  - `OpportunityId` (`string`) - Opportunity Id (OpportunityContactRole.OpportunityId).
  - `ContactId` (`string`) - Contact Id (OpportunityContactRole.ContactId).
  - `Role` (`string`) - OCR Role picklist API value (e.g. Decision Maker).
  - `IsPrimary` (`boolean`) - Optional. OpportunityContactRole.IsPrimary.

## `add_opportunity_line_item`

- **required:** `["OpportunityId", "Quantity", "UnitPrice"]`
- **properties:**
  - `OpportunityId` (`string`) - Parent Opportunity Id (OpportunityLineItem.OpportunityId). Not the line-item Id.
  - `PricebookEntryId` (`string`) - Optional. PricebookEntry Id. Use when already known.
  - `Name` (`string`) - Optional. Product name resolved to an active PricebookEntry on the Opportunity price book.
  - `Quantity` (`number`) - Quantity of the product (must be > 0). OpportunityLineItem.Quantity.
  - `UnitPrice` (`number`) - Unit price for the line item (OpportunityLineItem.UnitPrice).

## `add_opportunity_partner`

- **required:** `["OpportunityId"]`
- **properties:**
  - `OpportunityId` (`string`) - Salesforce opportunity id.
  - `AccountId` (`string`)
  - `Role` (`string`) - Partner role for the opportunity-account relationship.

## `add_opportunity_team_member`

- **required:** `["OpportunityId", "UserId"]`
- **properties:**
  - `OpportunityId` (`string`) - Salesforce opportunity id.
  - `UserId` (`string`)
  - `TeamRole` (`string`)

## `add_order_item`

- **required:** `["OrderId"]`
- **properties:**
  - `OrderId` (`string`) - Parent Order Id (OrderItem.OrderId). Not the OrderItem Id.

## `add_quote_line_item`

- **required:** `["QuoteId"]`
- **properties:**
  - `QuoteId` (`string`) - Parent Quote Id (QuoteLineItem.QuoteId). Not the line-item Id.

## `assign_to_queue`

- **required:** `["Id", "OwnerId"]`
- **properties:**
  - `Id` (`string`) - Salesforce record id.
  - `OwnerId` (`string`)

## `calculate_cpq_quote`

- **required:** `["Id"]`
- **properties:**
  - `Id` (`string`) - Salesforce cpq quote id.

## `clone_opportunity`

- **required:** `["Id"]`
- **properties:**
  - `Id` (`string`) - Opportunity Id to clone (primary Id of the source Opportunity).
  - `Name` (`string`) - Optional name for the clone (defaults to source Name + Copy).

## `close_case`

- **required:** `["Id"]`
- **properties:**
  - `Id` (`string`) - Case Id to close (primary Id of Case).
  - `Status` (`string`) - Optional. Case.Status picklist closed value (default Closed). Use org closed values such as Closed, Resolved.
  - `Reason` (`string`) - Optional. Case.Reason picklist API value at closure (e.g. User error, Other).
  - `Comments` (`string`) - Optional. Public CaseComment.CommentBody to post at closure.

## `complete_task`

- **required:** `["Id"]`
- **properties:**
  - `Id` (`string`) - ONLY the Salesforce Id of the Task to mark Completed.

## `convert_lead`

- **required:** `["Id"]`
- **properties:**
  - `Id` (`string`) - ONLY the Salesforce Id of the Lead to convert.
  - `AccountId` (`string`) - Optional. The Salesforce Id of an EXISTING Account to merge the Lead into.
  - `opportunityName` (`string`) - Optional. Name for the Opportunity that will be created.
  - `doNotCreateOpportunity` (`boolean`) - Optional. If true, no Opportunity is created during conversion. Default false.

## `create_account`

- **required:** `["Name"]`
- **additionalProperties:** `true`
- **properties:**
  - `Name` (`string`) - REQUIRED. The Account Name (e.g. "Acme Corporation"). This is the only mandatory parameter for creating an Account - do not invoke this skill without it.
  - `fields` (`object`) - Optional. Map of additional Account field API names to their values - Industry, Type, AnnualRevenue, NumberOfEmployees, Phone, Website, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Description, Rating, custom fields, etc. Do NOT put "Name" here - pass it at the top level. Numbers as numbers, booleans as true/false, picklist values as the exact API value.

## `create_campaign`

- **required:** `["Name"]`
- **additionalProperties:** `true`
- **properties:**
  - `Name` (`string`) - REQUIRED. Campaign Name (org field).
  - `Status` (`string`) - Campaign Status picklist API value.
  - `Type` (`string`) - Campaign Type picklist API value.
  - `StartDate` (`string`) - Campaign StartDate (yyyy-MM-dd).
  - `EndDate` (`string`) - Campaign EndDate (yyyy-MM-dd).

## `create_care_task`

- **required:** `["WhatId", "Subject"]`
- **additionalProperties:** `true`
- **properties:**
  - `WhatId` (`string`) - Care Plan (or related) record Id for Task.WhatId - parent, not the task Id.
  - `Subject` (`string`) - Task.Subject (required).
  - `Status` (`string`) - Optional Task.Status (default Not Started).
  - `Priority` (`string`) - Optional Task.Priority (default Normal).
  - `Description` (`string`) - Optional Task.Description.
  - `ActivityDate` (`string`) - Optional Task.ActivityDate (yyyy-MM-dd).

## `create_case`

- **required:** `["fields"]`
- **additionalProperties:** `true`
- **properties:**
  - `fields` (`object`) - Map of Case field API names to values. MUST include "Subject". May include Description, Status, Priority, Type, Origin, Reason, AccountId, ContactId, OwnerId and custom fields.

## `create_contact`

- **required:** `[]`
- **additionalProperties:** `true`
- **properties:**
  - `LastName` (`string`) - REQUIRED. Contact LastName (org field API name).
  - `FirstName` (`string`) - Contact FirstName.
  - `Email` (`string`) - Contact Email.
  - `Phone` (`string`) - Contact Phone.
  - `Title` (`string`) - Contact Title.
  - `AccountId` (`string`) - Parent Account Id (org relationship field AccountId). Prefer over accountName when known.
  - `accountName` (`string`) - Optional. Parent Account Name when AccountId is unknown - skill resolves to AccountId.

## `create_contract`

- **required:** `["AccountId"]`
- **additionalProperties:** `true`
- **properties:**
  - `AccountId` (`string`) - Parent Account Id (Contract.AccountId). Required.
  - `Status` (`string`) - Contract.Status picklist API value.
  - `StartDate` (`string`) - Contract.StartDate (yyyy-MM-dd).
  - `ContractTerm` (`integer`) - Contract.ContractTerm (months).
  - `Description` (`string`) - Contract.Description.

## `create_cpq_quote`

- **required:** `["OpportunityId"]`
- **additionalProperties:** `true`
- **properties:**
  - `OpportunityId` (`string`) - Parent Opportunity Id (SBQQ__Quote__c.SBQQ__Opportunity2__c or equivalent).
  - `Name` (`string`) - Optional CPQ quote Name.

## `create_event`

- **required:** `["fields"]`
- **additionalProperties:** `true`
- **properties:**
  - `fields` (`object`) - Map of Event field API names to values. MUST include "Subject" AND "StartDateTime" (ISO 8601, e.g. "2026-05-31T14:30:00Z"). Provide EITHER "EndDateTime" OR "DurationInMinutes". May also include "Description", "Location", "WhatId" (record like Account/Opportunity), "WhoId" (Contact/Lead), "IsAllDayEvent" and custom fields.

## `create_lead`

- **required:** `["fields"]`
- **additionalProperties:** `true`
- **properties:**
  - `fields` (`object`) - Map of Lead field API names to values. MUST include "LastName" AND "Company". May include FirstName, Title, Email, Phone, MobilePhone, Status, LeadSource, Industry, Rating, AnnualRevenue, NumberOfEmployees and custom fields.

## `create_opportunity`

- **required:** `["fields"]`
- **additionalProperties:** `true`
- **properties:**
  - `fields` (`object`) - Map of Opportunity field API names to values. MUST include "Name", "StageName", AND "CloseDate" (yyyy-MM-dd). May include AccountId, Amount, Probability, Type, LeadSource, NextStep, Description, Pricebook2Id and custom fields.

## `create_order`

- **required:** `["AccountId", "Status", "EffectiveDate"]`
- **additionalProperties:** `true`
- **properties:**
  - `AccountId` (`string`) - Parent Account Id (Order.AccountId).
  - `Status` (`string`) - Order.Status picklist API value (e.g. Draft).
  - `EffectiveDate` (`string`) - Order.EffectiveDate (yyyy-MM-dd).
  - `OpportunityId` (`string`) - Optional Order.OpportunityId.
  - `Pricebook2Id` (`string`) - Optional Order.Pricebook2Id.

## `create_quote`

- **required:** `["Name", "OpportunityId"]`
- **additionalProperties:** `true`
- **properties:**
  - `Name` (`string`) - Quote.Name (required).
  - `OpportunityId` (`string`) - Parent Opportunity Id (Quote.OpportunityId).
  - `ExpirationDate` (`string`) - Optional Quote.ExpirationDate (yyyy-MM-dd).
  - `Status` (`string`) - Optional Quote.Status picklist API value.

## `create_task`

- **required:** `["fields"]`
- **additionalProperties:** `true`
- **properties:**
  - `fields` (`object`) - Map of Task field API names to values. MUST include "Subject". Set "WhatId" to the Account/Opportunity/Case Id OR "WhoId" to the Contact/Lead Id. May also include Description, Status, Priority, ActivityDate (yyyy-MM-dd), OwnerId and custom fields.

## `create_work_order`

- **required:** `[]`
- **additionalProperties:** `true`
- **properties:**
  - `AccountId` (`string`) - Salesforce account id.
  - `Name` (`string`) - Record name (required for most objects).

## `fetch_account_details`

- **required:** `[]`
- **properties:**
  - `Id` (`string`) - Account Id (001…). Prefer when known (page context / prior skill).
  - `Name` (`string`) - Account Name for lookup when Id is unknown. Fuzzy match on Name.
  - `userContextId` (`string`) - Session / page context id when chatting on an Account record page.

## `fetch_account_plan`

- **required:** `["Id"]`
- **properties:**
  - `Id` (`string`) - Account Id (primary Id of Account whose plan to load).

## `fetch_account_related_lists`

- **required:** `["Id"]`
- **properties:**
  - `Id` (`string`) - ONLY the Salesforce Id of the Account whose related lists should be fetched.
  - `related` (`array`) - Optional. Which related lists to fetch. Allowed values: "contacts", "opportunities", "cases". If omitted, all three are returned.

## `fetch_asset_details`

- **required:** `["Id"]`
- **properties:**
  - `Id` (`string`) - Salesforce asset id.

## `fetch_campaign_details`

- **required:** `["Id"]`
- **properties:**
  - `Id` (`string`) - Campaign Id (primary Id of Campaign, prefix 701…).

## `fetch_campaign_members`

- **required:** `["CampaignId"]`
- **properties:**
  - `CampaignId` (`string`) - Campaign Id (CampaignMember.CampaignId relationship). Not the CampaignMember Id.

## `fetch_care_plan`

- **required:** `["Id"]`
- **properties:**
  - `Id` (`string`) - Salesforce record id.

## `fetch_case_details`

- **required:** `["Id"]`
- **properties:**
  - `Id` (`string`) - Either the Salesforce Id of the Case (starts with "500") OR the human-readable CaseNumber (e.g. "00001234").

## `fetch_case_entitlements`

- **required:** `["CaseId"]`
- **properties:**
  - `CaseId` (`string`) - Salesforce case id.

## `fetch_case_milestones`

- **required:** `["CaseId"]`
- **properties:**
  - `CaseId` (`string`) - Salesforce case id.

## `fetch_case_team`

- **required:** `["CaseId"]`
- **properties:**
  - `CaseId` (`string`) - Salesforce case id.

## `fetch_contact_details`

- **required:** `["Id"]`
- **properties:**
  - `Id` (`string`) - ONLY the Salesforce Id of the Contact whose details should be fetched.

## `fetch_contact_engagement_history`

- **required:** `["Id"]`
- **properties:**
  - `Id` (`string`) - Contact Id (primary Id of Contact).
  - `daysBack` (`integer`) - How far back to look (default 90 days).
  - `limit` (`integer`) - Max items (default 50).

## `fetch_contract_details`

- **required:** `["Id"]`
- **properties:**
  - `Id` (`string`) - Contract Id (primary Id of Contract).

## `fetch_cpq_quote_details`

- **required:** `["Id"]`
- **properties:**
  - `Id` (`string`) - Salesforce cpq quote id.

## `fetch_financial_account`

- **required:** `["Id"]`
- **properties:**
  - `Id` (`string`) - Salesforce record id.

## `fetch_knowledge_article`

- **required:** `["Id"]`
- **properties:**
  - `Id` (`string`) - KnowledgeArticleVersion Id or KnowledgeArticleId (primary article identity).

## `fetch_lead_details`

- **required:** `["Id"]`
- **properties:**
  - `Id` (`string`) - ONLY the Salesforce Id of the Lead whose details should be fetched.

## `fetch_my_open_opportunities`

- **required:** `[]`
- **properties:**
  - `limit` (`integer`) - Max rows (default 50).

## `fetch_my_open_tasks`

- **required:** `[]`
- **properties:**
  - `limit` (`integer`) - Optional. Maximum number of tasks to return (1-200). Defaults to 25.

## `fetch_opportunity_contact_roles`

- **required:** `["OpportunityId"]`
- **properties:**
  - `OpportunityId` (`string`) - Opportunity Id (OpportunityContactRole.OpportunityId). Not the contact-role Id.

## `fetch_opportunity_details`

- **required:** `["Id"]`
- **properties:**
  - `Id` (`string`) - ONLY the Salesforce Id of the Opportunity whose details should be fetched.

## `fetch_opportunity_partners`

- **required:** `["OpportunityId"]`
- **properties:**
  - `OpportunityId` (`string`) - Salesforce opportunity id.

## `fetch_opportunity_team`

- **required:** `["OpportunityId"]`
- **properties:**
  - `OpportunityId` (`string`) - Opportunity Id (OpportunityTeamMember.OpportunityId). Not the team-member Id.

## `fetch_order_details`

- **required:** `["Id"]`
- **properties:**
  - `Id` (`string`) - Salesforce order id.

## `fetch_partner_account`

- **required:** `["Id"]`
- **properties:**
  - `Id` (`string`) - Partner account Id (primary Id of the Account / partner record).

## `fetch_picklist_values`

- **required:** `["objectApiName", "fieldApiName"]`
- **properties:**
  - `objectApiName` (`string`) - API name of the object the field lives on. Examples: "Account", "Opportunity", "Custom_Object__c".
  - `fieldApiName` (`string`) - API name of the picklist or multi-picklist field. Examples: "Industry", "StageName", "Type__c".
  - `controllerValue` (`string`) - Required ONLY for dependent picklists. The exact API value of the controlling field that the record will have AFTER the update. The skill returns only the dependent values valid for this controller value.

## `fetch_pricebook_entries`

- **required:** `[]`
- **properties:**
  - `Pricebook2Id` (`string`) - Optional. Pricebook2 Id. Defaults to standard pricebook.
  - `Id` (`string`) - Optional. Filter entries to one Product2 Id.
  - `limit` (`integer`) - Optional. Max rows (1-200). Default 25.

## `fetch_product_details`

- **required:** `["Id"]`
- **properties:**
  - `Id` (`string`) - Salesforce Product2 Id.

## `fetch_queue_cases`

- **required:** `["OwnerId"]`
- **properties:**
  - `OwnerId` (`string`) - Salesforce queue id.
  - `limit` (`integer`)

## `fetch_quote_details`

- **required:** `["Id"]`
- **properties:**
  - `Id` (`string`) - Salesforce quote id.

## `fetch_record_approvals`

- **required:** `["Id"]`
- **properties:**
  - `Id` (`string`) - Salesforce record id.

## `fetch_renewal_opportunities`

- **required:** `[]`
- **properties:**
  - `AccountId` (`string`) - Optional Account filter (Opportunity.AccountId).

## `fetch_service_appointment`

- **required:** `["Id"]`
- **properties:**
  - `Id` (`string`) - Salesforce record id.

## `fetch_service_resource_availability`

- **required:** `["Id"]`
- **properties:**
  - `Id` (`string`) - ServiceResource Id (primary Id of the resource whose availability to check).
  - `StartDate` (`string`) - Optional window start (yyyy-MM-dd).
  - `EndDate` (`string`) - Optional window end (yyyy-MM-dd).

## `fetch_session_context`

- **required:** `[]`
- **properties:**
  - `Id` (`string`) - Optional. Salesforce Id of the page-context or related record (15 or 18 characters). Pass when you have a confirmed record Id from the record page. If omitted, the skill resolves from the session record or userContextId when applicable.

## `fetch_stale_opportunities`

- **required:** `[]`
- **properties:**
  - `daysStale` (`integer`) - Days since last activity (default 30).

## `fetch_subscription_details`

- **required:** `["Id"]`
- **properties:**
  - `Id` (`string`) - Salesforce subscription id.

## `fetch_upcoming_renewals`

- **required:** `[]`
- **properties:**
  - `daysAhead` (`integer`) - Days ahead to look (default 90).
  - `AccountId` (`string`) - Optional Account filter.
  - `OwnerId` (`string`) - Optional owner filter.
  - `limit` (`integer`) - Max rows (default 50).

## `fetch_work_order_details`

- **required:** `["Id"]`
- **properties:**
  - `Id` (`string`) - Salesforce work order id.

## `fuzzy_search_accounts`

- **required:** `["searchTerm"]`
- **properties:**
  - `searchTerm` (`string`) - The Account name (or partial name) to search for. Examples: "Acme", "power grid", "United Health".

## `fuzzy_search_assets`

- **required:** `["searchTerm"]`
- **properties:**
  - `searchTerm` (`string`) - Partial name or keyword to search.

## `fuzzy_search_campaigns`

- **required:** `["searchTerm"]`
- **properties:**
  - `searchTerm` (`string`) - Partial name or keyword to search.

## `fuzzy_search_cases`

- **required:** `["searchTerm"]`
- **properties:**
  - `searchTerm` (`string`) - Case Subject partial text or CaseNumber (e.g. 00001234).

## `fuzzy_search_contacts`

- **required:** `["searchTerm"]`
- **properties:**
  - `searchTerm` (`string`) - The Contact name OR email (or partial) to search for. Examples: "John Smith", "john@acme.com", "Khan".

## `fuzzy_search_leads`

- **required:** `["searchTerm"]`
- **properties:**
  - `searchTerm` (`string`) - Lead name, company name, or email to search for. Examples: "Jane Doe", "Acme Industries", "jane@acme.com".

## `fuzzy_search_opportunities`

- **required:** `["searchTerm"]`
- **properties:**
  - `searchTerm` (`string`) - Opportunity Name (partial) OR Salesforce Opportunity Id (006…).

## `fuzzy_search_partners`

- **required:** `["searchTerm"]`
- **properties:**
  - `searchTerm` (`string`) - Partial name or keyword to search.

## `fuzzy_search_products`

- **required:** `["searchTerm"]`
- **properties:**
  - `searchTerm` (`string`) - Product name or product code partial match.

## `fuzzy_search_quotes`

- **required:** `["searchTerm"]`
- **properties:**
  - `searchTerm` (`string`) - Partial name or keyword to search.

## `link_knowledge_article_to_case`

- **required:** `["CaseId", "KnowledgeArticleId"]`
- **properties:**
  - `CaseId` (`string`) - Salesforce case id.
  - `KnowledgeArticleId` (`string`)

## `log_activity`

- **required:** `["Subject"]`
- **properties:**
  - `WhatId` (`string`) - Related record for Task.WhatId (Account, Opportunity, Case, etc.). Use WhatId OR WhoId.
  - `WhoId` (`string`) - Person for Task.WhoId (Contact or Lead). Use WhoId OR WhatId.
  - `Subject` (`string`) - Task.Subject for the completed activity - must be confirmed with the user.
  - `Description` (`string`) - Optional Task.Description notes/summary.

## `remove_campaign_member`

- **required:** `["Id"]`
- **properties:**
  - `Id` (`string`) - CampaignMember Id (primary Id of the membership row to delete). Not CampaignId.

## `run_internal_prompt`

- **required:** `["promptRequestId", "Id"]`
- **properties:**
  - `promptRequestId` (`string`) - The pre-configured GPTfy Prompt Request Id to invoke. Example: "96a10206d7990a5fabc728ddfd83be0fbd5a9". Must exist in the org configuration - never make this up.
  - `Id` (`string`) - ONLY the Salesforce Id of the record the prompt should run against (e.g. an Opportunity Id for a Deal Overview prompt).

## `schedule_service_appointment`

- **required:** `["Id"]`
- **properties:**
  - `Id` (`string`) - Salesforce service appointment id.
  - `StartDateTime` (`string`)
  - `EndDateTime` (`string`)

## `search_knowledge_articles`

- **required:** `["searchTerm"]`
- **properties:**
  - `searchTerm` (`string`) - Keywords to search Knowledge.

## `transfer_record_owner`

- **required:** `["Id", "OwnerId"]`
- **properties:**
  - `Id` (`string`) - Salesforce Id of the record to reassign.
  - `OwnerId` (`string`) - User Id (005…) or Queue Id (00G…) for the new owner.

## `update_account_fields`

- **required:** `["Id"]`
- **additionalProperties:** `true`
- **properties:**
  - `Id` (`string`) - ONLY the Salesforce Id of the Account to update.
  - `Name` (`string`) - Account Name.
  - `Industry` (`string`) - Industry picklist API value (call fetch_picklist_values first if unsure).
  - `Type` (`string`) - Type picklist API value (call fetch_picklist_values first if unsure).
  - `AnnualRevenue` (`number`) - Annual revenue as a plain number, no currency symbol or commas.
  - `Phone` (`string`) - Account phone number.
  - `Website` (`string`) - Account website URL.
  - `Description` (`string`) - Long-text description of the Account.

## `update_asset_fields`

- **required:** `["Id"]`
- **additionalProperties:** `true`
- **properties:**
  - `Id` (`string`) - Salesforce asset id.

## `update_campaign_fields`

- **required:** `["Id"]`
- **additionalProperties:** `true`
- **properties:**
  - `Id` (`string`) - Campaign Id to update (primary Id of Campaign).

## `update_campaign_member_status`

- **required:** `["Id", "Status"]`
- **properties:**
  - `Id` (`string`) - CampaignMember Id (primary Id of the member row being updated).
  - `Status` (`string`) - New CampaignMember.Status picklist API value.

## `update_care_plan_fields`

- **required:** `["Id"]`
- **additionalProperties:** `true`
- **properties:**
  - `Id` (`string`) - Salesforce care plan id.

## `update_case_fields`

- **required:** `["Id", "fields"]`
- **additionalProperties:** `true`
- **properties:**
  - `Id` (`string`) - ONLY the Salesforce Id of the Case to update.
  - `fields` (`object`) - Map of Case field API names to NEW values. Only the fields the user wants to change.

## `update_contact_fields`

- **required:** `["Id", "fields"]`
- **additionalProperties:** `true`
- **properties:**
  - `Id` (`string`) - ONLY the Salesforce Id of the Contact to update.
  - `fields` (`object`) - Map of Contact field API names to their NEW values. Pass only the fields the user wants to change.

## `update_contract_fields`

- **required:** `["Id"]`
- **additionalProperties:** `true`
- **properties:**
  - `Id` (`string`) - Contract Id to update (primary Id of Contract).

## `update_cpq_quote_fields`

- **required:** `["Id"]`
- **additionalProperties:** `true`
- **properties:**
  - `Id` (`string`) - Salesforce cpq quote id.

## `update_cpq_quote_line`

- **required:** `["Id"]`
- **properties:**
  - `Id` (`string`) - Salesforce line id.

## `update_event`

- **required:** `["Id"]`
- **additionalProperties:** `true`
- **properties:**
  - `Id` (`string`) - Salesforce Event Id.
  - `Subject` (`string`)
  - `StartDateTime` (`string`)
  - `EndDateTime` (`string`)
  - `Location` (`string`)
  - `Description` (`string`)

## `update_financial_account_fields`

- **required:** `["Id"]`
- **additionalProperties:** `true`
- **properties:**
  - `Id` (`string`) - Salesforce financial account id.

## `update_lead_fields`

- **required:** `["Id", "fields"]`
- **additionalProperties:** `true`
- **properties:**
  - `Id` (`string`) - ONLY the Salesforce Id of the Lead to update.
  - `fields` (`object`) - Map of Lead field API names to their NEW values. Only fields the user wants to change.

## `update_opportunity_contact_role`

- **required:** `["Id"]`
- **properties:**
  - `Id` (`string`) - Salesforce contact role id.

## `update_opportunity_fields`

- **required:** `["Id", "fields"]`
- **additionalProperties:** `true`
- **properties:**
  - `Id` (`string`) - ONLY the Salesforce Id of the Opportunity to update.
  - `fields` (`object`) - Map of Opportunity field API names to NEW values. Common fields: StageName, Amount, CloseDate (yyyy-MM-dd), Probability, ForecastCategoryName, NextStep, Description and custom fields. Pass numbers as numbers, dates as "yyyy-MM-dd", booleans as true/false, picklist values as exact API values.

## `update_opportunity_line_item`

- **required:** `["Id"]`
- **additionalProperties:** `true`
- **properties:**
  - `Id` (`string`) - Salesforce Id of the OpportunityLineItem to update.
  - `Quantity` (`number`)
  - `UnitPrice` (`number`)
  - `Discount` (`number`)

## `update_order_fields`

- **required:** `["Id"]`
- **additionalProperties:** `true`
- **properties:**
  - `Id` (`string`) - Salesforce order id.

## `update_order_item`

- **required:** `["Id"]`
- **properties:**
  - `Id` (`string`) - Salesforce order item id.

## `update_quote_fields`

- **required:** `["Id"]`
- **additionalProperties:** `true`
- **properties:**
  - `Id` (`string`) - Salesforce quote id.

## `update_quote_line_item`

- **required:** `["Id"]`
- **properties:**
  - `Id` (`string`) - Salesforce line item id.

## `update_service_appointment`

- **required:** `["Id"]`
- **properties:**
  - `Id` (`string`) - Salesforce service appointment id.

## `update_subscription_fields`

- **required:** `["Id"]`
- **additionalProperties:** `true`
- **properties:**
  - `Id` (`string`) - Salesforce subscription id.

## `update_task`

- **required:** `["Id"]`
- **additionalProperties:** `true`
- **properties:**
  - `Id` (`string`) - Salesforce Task Id.
  - `Subject` (`string`)
  - `Status` (`string`)
  - `Priority` (`string`)
  - `ActivityDate` (`string`) - Due date yyyy-MM-dd.
  - `Description` (`string`)

## `update_work_order_fields`

- **required:** `["Id"]`
- **additionalProperties:** `true`
- **properties:**
  - `Id` (`string`) - Salesforce work order id.
