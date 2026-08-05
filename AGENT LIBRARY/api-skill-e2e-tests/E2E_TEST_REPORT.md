# Master Dev E2E Report (pre-fix)

Generated: 2026-08-05 14:25 UTC

**Org:** Master Dev (`masterdev@gptfy.ai`)
**Agent:** GPTfy Master Agent
**Agent DeveloperName (API):** `IT_Helpdesk_Assistant05/08/2026, 11:47`

Scope: deploy Deliverables handlers + seed 111 package skills + `invokeAgentSkill` once each for every skill linked to the agent. **No product code fixes applied.**

---

## Executive summary

| Stage | Result |
|-------|--------|
| Full Apex deploy (all handlers) | **FAILED** (68 component failures, rolled back) |
| Partial Apex deploy (excluded 5 broken handlers) | **SUCCESS** |
| Skill seed (111 packages) | **103 OK / 8 FAIL** |
| Prompts in org | **111** |
| Skills linked to agent | **110** |
| Unlinked prompts | **`fetch_account_details`** |
| `invokeAgentSkill` matrix | **110 invoked** |
| Handler OK | **19** |
| Handler error | **69** |
| API fail | **22** |

### Pass bar

- **handler_ok** — API Success + Apex success/true
- **handler_error** — API Success but Apex error / no match / missing param
- **api_fail** — REST layer non-Success (e.g. class not found)

Many handler_errors are **fixture/schema/org data**, not definite code bugs. api_fail for Opportunity/Quote/Partner is a **deploy gate**.

---

## 1. Deploy

### 1.1 Full package

- Deploy Id: `0AfQH00000P9St80AF`
- Status: Failed — all-or-nothing; full set **not** applied
- Root compile failures:

- **`ActivityAgenticSkillsHandler`**: Method does not exist or incorrect signature: void isClosed() from the type Schema.PicklistEntry (124:41)
- **`OpportunityAgenticSkillsHandler`**: OpportunityTeamMember invalid (feature/type not available) — Schema.sObjectType.OpportunityTeamMember
- **`PartnerAgenticSkillsHandler`**: Invalid bind expression type of APEX_OBJECT for column of type Id (133:39)
- **`QuoteAgenticSkillsHandler`**: Quote / QuoteLineItem types not available (Quotes not enabled or not in org)
- **`GenericAgenticSkillsHandler`**: Dependent on ActivityAgenticSkillsHandler invalid compile

### 1.2 Partial deploy (used for testing)

Excluded:
- `ActivityAgenticSkillsHandler`
- `OpportunityAgenticSkillsHandler`
- `PartnerAgenticSkillsHandler`
- `QuoteAgenticSkillsHandler`
- `GenericAgenticSkillsHandler`

Deployed / present for invoke:
- `AgenticSkillsBase`
- `AccountAgenticSkillsHandler`
- `CampaignAgenticSkillsHandler`
- `CaseAgenticSkillsHandler`
- `ContactAgenticSkillsHandler`
- `ContractAgenticSkillsHandler`
- `CpqAgenticSkillsHandler`
- `FieldServiceAgenticSkillsHandler`
- `IndustryAgenticSkillsHandler`
- `LeadAgenticSkillsHandler`
- `OrderAgenticSkillsHandler`
- `ProductAgenticSkillsHandler`
- `ServiceAgenticSkillsHandler`
- `UtilityAgenticSkillsHandler`

Inventory Apex *Agentic* classes: **30**

---

## 2. Seed skills

- Processed: **111**
- Succeeded: **103**
- Failed: **8**
- Agent Name: `GPTfy Master Agent`
- Mapping / model: `a08QH00000S2zVZYAZ` / `a04QH000007PsM9YAK`

### Failed seeds (legacy 8 prompts)

All failed with: `FIELD_CUSTOM_VALIDATION_EXCEPTION: Data Extraction mapping cannot be changed on Prompt once it has been created.`

- `create_account`
- `create_contact`
- `fetch_account_details`
- `fuzzy_search_contacts`
- `log_activity`
- `run_internal_prompt`
- `update_account_fields`
- `update_contact_fields`

**Impact:** those prompts still use **old** Prompt Command schemas (e.g. `search_term`, `contact_id`). The other **103** skills seeded with current schema.

---

## 3. Invoke matrix

Sample Ids: stored in `sample_ids.json` / matrix `sampleIds`.

### 3.1 handler_ok (19)

- `add_case_comment`
- `create_account`
- `create_campaign`
- `create_care_task`
- `fetch_account_related_lists`
- `fetch_campaign_members`
- `fetch_knowledge_article`
- `fetch_my_open_opportunities`
- `fetch_my_open_tasks`
- `fetch_pricebook_entries`
- `fetch_record_approvals`
- `fetch_renewal_opportunities`
- `fetch_session_context`
- `fetch_stale_opportunities`
- `fetch_upcoming_renewals`
- `log_activity`
- `run_internal_prompt`
- `update_account_fields`
- `update_contact_fields`

### 3.2 Failures by bucket

#### A. Missing Apex class (not deployed) (22)

| Skill | Error (snip) |
|-------|----------------|
| `add_opportunity_contact_role` | Agentic function class not found |
| `add_opportunity_line_item` | Agentic function class not found |
| `add_opportunity_partner` | Agentic function class not found |
| `add_opportunity_team_member` | Agentic function class not found |
| `add_quote_line_item` | Agentic function class not found |
| `clone_opportunity` | Agentic function class not found |
| `create_opportunity` | Agentic function class not found |
| `create_quote` | Agentic function class not found |
| `fetch_opportunity_contact_roles` | Agentic function class not found |
| `fetch_opportunity_details` | Agentic function class not found |
| `fetch_opportunity_partners` | Agentic function class not found |
| `fetch_opportunity_team` | Agentic function class not found |
| `fetch_partner_account` | Agentic function class not found |
| `fetch_quote_details` | Agentic function class not found |
| `fuzzy_search_opportunities` | Agentic function class not found |
| `fuzzy_search_partners` | Agentic function class not found |
| `fuzzy_search_quotes` | Agentic function class not found |
| `update_opportunity_contact_role` | Agentic function class not found |
| `update_opportunity_fields` | Agentic function class not found |
| `update_opportunity_line_item` | Agentic function class not found |
| `update_quote_fields` | Agentic function class not found |
| `update_quote_line_item` | Agentic function class not found |

#### B. Unsupported skill routing in handler (3)

| Skill | Error (snip) |
|-------|----------------|
| `fetch_asset_details` | Unsupported skill: fetch_asset_details |
| `fuzzy_search_assets` | Unsupported skill: fuzzy_search_assets |
| `update_asset_fields` | Unsupported skill: update_asset_fields |

#### C. Cloud/feature not in org (16)

| Skill | Error (snip) |
|-------|----------------|
| `add_cpq_quote_line` | ⚠️ Could not add CPQ quote line Salesforce CPQ is not installed or SBQQ__Quote__c / SBQQ__QuoteLine__c are not accessible in this org. |
| `calculate_cpq_quote` | ⚠️ Could not calculate CPQ quote Salesforce CPQ is not installed or SBQQ__Quote__c / SBQQ__QuoteLine__c are not accessible in this org. |
| `create_cpq_quote` | ⚠️ Could not create CPQ quote Salesforce CPQ is not installed or SBQQ__Quote__c / SBQQ__QuoteLine__c are not accessible in this org. |
| `fetch_account_plan` | Account Plan is not available in this org. |
| `fetch_care_plan` | Care Plan object is not available in this org. |
| `fetch_cpq_quote_details` | Salesforce CPQ is not installed or SBQQ__Quote__c / SBQQ__QuoteLine__c are not accessible in this org. |
| `fetch_financial_account` | Financial Account object (FinServ__FinancialAccount__c) is not available in this org. |
| `fetch_service_appointment` | ServiceAppointment object is not available in this org. |
| `fetch_service_resource_availability` | ServiceResource object is not available in this org. |
| `fetch_subscription_details` | Subscription object is not available in this org. |
| `schedule_service_appointment` | ⚠️ Could not schedule appointment ServiceAppointment is not available or creatable in this org. |
| `update_care_plan_fields` | ⚠️ Could not update care plan Care Plan object is not available in this org. |
| `update_cpq_quote_fields` | ⚠️ Could not update CPQ quote Salesforce CPQ is not installed or SBQQ__Quote__c / SBQQ__QuoteLine__c are not accessible in this org. |
| `update_cpq_quote_line` | ⚠️ Could not update CPQ quote line Salesforce CPQ is not installed or SBQQ__Quote__c / SBQQ__QuoteLine__c are not accessible in this org. |
| `update_financial_account_fields` | ⚠️ Could not update financial account FinServ__FinancialAccount__c is not available in this org. |
| `update_subscription_fields` | ⚠️ Could not update subscription Subscription object is not available in this org. |

#### D. Missing param / fixture / schema mismatch (28)

| Skill | Error (snip) |
|-------|----------------|
| `add_case_team_member` | ⚠️ Could not add case team member Missing parameter: case_id |
| `add_order_item` | ⚠️ Could not add order item Missing parameter: OrderId |
| `create_case` | ⚠️ Could not create case Subject is required. |
| `create_contact` | ⚠️ Could not create contact LastName is required. |
| `create_contract` | ⚠️ Could not create contract Status is required. |
| `create_event` | ⚠️ Could not create event Subject is required. |
| `create_lead` | ⚠️ Could not create lead LastName is required. |
| `create_task` | ⚠️ Could not create task Subject is required. |
| `create_work_order` | ⚠️ Could not create work order Subject is required. |
| `fetch_case_entitlements` | Missing required parameter: case_id |
| `fetch_case_milestones` | Missing required parameter: case_id |
| `fetch_case_team` | Missing required parameter: case_id |
| `fetch_contact_details` | Missing required parameter: Id (Contact Id). |
| `fetch_contract_details` | Missing required parameter: Id (Contract Id). |
| `fetch_picklist_values` | Missing required parameter: object_api_name |
| `fuzzy_search_campaigns` | Missing required parameter: search_term |
| `fuzzy_search_cases` | Missing required parameter: search_term |
| `fuzzy_search_leads` | Missing required parameter: search_term |
| `fuzzy_search_products` | Missing required parameter: search_term |
| `link_knowledge_article_to_case` | ⚠️ Could not link article Missing parameter: case_id |
| `search_knowledge_articles` | Missing required parameter: search_term |
| `update_campaign_fields` | ⚠️ Could not update campaign Missing parameter: at least one field to update |
| `update_contract_fields` | ⚠️ Could not update contract Missing parameter: Id (Contract Id). |
| `update_event` | ⚠️ Could not update event Missing parameter: at least one field to update |
| `update_order_fields` | ⚠️ Could not update order Missing parameter: at least one field to update |
| `update_order_item` | ⚠️ Could not update order item Missing parameter: at least one field to update |
| `update_task` | ⚠️ Could not update task Missing parameter: at least one field to update |
| `update_work_order_fields` | ⚠️ Could not update work order Missing parameter: at least one field to update |

#### E. No matching data (often expected) (15)

| Skill | Error (snip) |
|-------|----------------|
| `close_case` | ⚠️ Could not close case No case found for provided Id. |
| `complete_task` | ⚠️ Could not complete task No task found for provided Id. |
| `convert_lead` | ⚠️ Could not convert lead No lead found for provided Id. |
| `fetch_campaign_details` | No campaign found for provided Id. |
| `fetch_case_details` | No case found for provided Id/Number. |
| `fetch_contact_engagement_history` | No contact found for provided Id. |
| `fetch_lead_details` | No lead found for provided Id. |
| `fetch_order_details` | No order found for provided Id. |
| `fetch_product_details` | No product found for provided Id. |
| `fuzzy_search_accounts` | No account found matching "Acme". |
| `fuzzy_search_contacts` | No contact found matching "Test". |
| `remove_campaign_member` | ⚠️ Could not remove campaign member No campaign member found for provided Id. |
| `update_campaign_member_status` | ⚠️ Could not update member status No campaign member found for provided Id. |
| `update_case_fields` | ⚠️ Could not update case No case found for provided Id. |
| `update_lead_fields` | ⚠️ Could not update lead No lead found for provided Id. |

#### F. Invalid Id / input (4)

| Skill | Error (snip) |
|-------|----------------|
| `assign_to_queue` | ⚠️ Could not assign to queue Invalid record_id or queue_id. |
| `create_order` | ⚠️ Could not create order Insert failed. First exception on row 0; first error: INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST, Status: bad value f |
| `fetch_queue_cases` | Invalid queue_id. |
| `transfer_record_owner` | ⚠️ Could not transfer owner Invalid record_id or new_owner_id. |

#### G. Other handler business error (2)

| Skill | Error (snip) |
|-------|----------------|
| `add_campaign_member` | ⚠️ Could not add campaign member Provide ContactId or LeadId (CampaignMember relationship fields). |
| `update_service_appointment` | ⚠️ Could not update appointment ServiceAppointment is not updateable in this org. |

#### H. Other / unclear (1)

| Skill | Error (snip) |
|-------|----------------|
| `fetch_work_order_details` | No such column 'ServiceTerritoryId' on entity 'WorkOrder'. If you are attempting to use a custom field, be sure to append the '__c' after th |

---

## 4. Interpretation (fix phase later — not applied)

### Must-fix (code / deploy)

1. **ActivityAgenticSkillsHandler** — `PicklistEntry.isClosed()` at ~L124 (blocks Activity + Generic)
2. **OpportunityAgenticSkillsHandler** — `OpportunityTeamMember` when team selling disabled
3. **QuoteAgenticSkillsHandler** — Quotes not enabled (`Quote` type missing)
4. **PartnerAgenticSkillsHandler** — Invalid bind type vs Id ~L133
5. Asset skills **Unsupported** — `fetch_asset_details`, `update_asset_fields`, `fuzzy_search_assets`

### Seed / config

6. Update legacy 8 Prompt Commands **without** changing Data Extraction Mapping
7. Link unlinked prompts: `fetch_account_details`
8. Treat CPQ / FSL / FinServ / Industry plan / subscription skills as **N/A** on this org unless packages present

### Harness noise

9. Bucket D fixtures need per-skill live `promptCommand` values (esp. nested `fields.LastName`, Contract Id key, empty update maps)
10. Bucket E may mix true empty results with wrong Id keys

### Side effects on Master Dev

- `create_account` created **E2E Smoke Account DO NOT USE**
- Other create/update/log skills may have mutated sample records (campaign, care task, case comment, account/contact description, activity)

---

## 5. Artifacts

`api-skill-e2e-tests/scripts/results/`

- `deploy_summary.json`, `deploy_full_report.json`
- `seed_log.json`, `seed_console.txt`
- `org_inventory.json`
- `matrix_report.json`, `matrix_report.md`, `matrix_console.txt`
- `sample_ids.json`
- `E2E_TEST_REPORT.md` (this file)

---

## 6. Recommended fix order (waiting for your go-ahead)

1. Fix four compile blockers + redeploy full handler set
2. Fix asset skill routing
3. Seed: refresh Prompt Command only + link missing skill
4. Improve fixtures; re-run matrix; classify N/A vs defect
5. Fix remaining handler business errors one by one
