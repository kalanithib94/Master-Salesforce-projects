# GPTfy Agent Library — Master Skill List (LOCKED)

**Version:** 2.0 master catalog  
**Status:** 🔒 Locked — add/rename skills only with doc + `MasterSkills.apex` + catalog rebuild  
**Total action skills:** 111  
**Insight lane:** 360, summaries, meeting prep, drafts → **`run_internal_prompt`** only (not counted)  
**Forever out of scope:** `delete_*`, `bulk_update_*`, setup/metadata changes

---

## Handler map (planned)

| Handler | Skills |
|---------|--------|
| `AccountAgenticSkillsHandler` | #1–5, #110 |
| `ContactAgenticSkillsHandler` | #6–9, #111 |
| `LeadAgenticSkillsHandler` | #10–14 |
| `OpportunityAgenticSkillsHandler` | #15–19, #34, #54–58, #61, #100 |
| `CaseAgenticSkillsHandler` | #20–23, #35–36, #65–66, #69 |
| `ActivityAgenticSkillsHandler` | #24–30 |
| `UtilityAgenticSkillsHandler` | #31–33, #40, #59–60, #67–68, #72–73, #104–105, #109 |
| `CampaignAgenticSkillsHandler` | #41–47, #106 |
| `ProductAgenticSkillsHandler` | #37–39 |
| `QuoteAgenticSkillsHandler` | #48–53 |
| `ContractAgenticSkillsHandler` | #62–64 |
| `ServiceAgenticSkillsHandler` | #70–71, #74–76 |
| `FieldServiceAgenticSkillsHandler` | #77–83 |
| `CpqAgenticSkillsHandler` | #84–89 |
| `OrderAgenticSkillsHandler` | #90–96 |
| `PartnerAgenticSkillsHandler` | #97–99 |
| `IndustryAgenticSkillsHandler` | #101–103, #107–108 |

---

## Persona index (parallel)

| Persona | Primary skill #s |
|---------|------------------|
| **SDR / BDR** | 6, 10–14, 24–25, 41–42, 45–47 + prompt |
| **AE** | 1–5, 6–9, 15–19, 34, 37–39, 49–54, 55–57, 62–65 + prompt |
| **Sales manager** | 1, 15–17, 34, 40, 58–61 + prompt |
| **CSM** | 1–5, 20–23, 24–28, 63, 65, 97–98 + prompt |
| **Support agent** | 20–23, 35–36, 66–73, 76–78 + prompt |
| **Support lead** | 35, 68, 74–75 + prompt |
| **Dispatcher / FSL** | 76–85 + prompt |
| **Rev ops / CPQ** | 37–39, 86–98 + prompt |
| **Marketing ops** | 41–47 + prompt |
| **Partner manager** | 12, 99–102 + prompt |
| **Industry user** | 103–105 + prompt |
| **Any record page** | 31, fetch by Id, 24, 33 |

---

## Wave 1 — Core CRM ✅ built (33)

| # | Skill | Handler | Out |
|---|-------|---------|-----|
| 1 | `fuzzy_search_accounts` | Account | JSON |
| 2 | `fetch_account_details` | Account | JSON |
| 3 | `create_account` | Account | HTML |
| 4 | `update_account_fields` | Account | HTML |
| 5 | `fetch_account_related_lists` | Account | JSON |
| 6 | `fuzzy_search_contacts` | Contact | JSON |
| 7 | `fetch_contact_details` | Contact | JSON |
| 8 | `create_contact` | Contact | HTML |
| 9 | `update_contact_fields` | Contact | HTML |
| 10 | `fuzzy_search_leads` | Lead | JSON |
| 11 | `fetch_lead_details` | Lead | JSON |
| 12 | `create_lead` | Lead | HTML |
| 13 | `update_lead_fields` | Lead | HTML |
| 14 | `convert_lead` | Lead | HTML |
| 15 | `fetch_opportunity_details` | Opportunity | JSON |
| 16 | `create_opportunity` | Opportunity | HTML |
| 17 | `update_opportunity_fields` | Opportunity | HTML |
| 18 | `add_opportunity_line_item` | Opportunity | HTML |
| 19 | `update_opportunity_line_item` | Opportunity | HTML |
| 20 | `fetch_case_details` | Case | JSON |
| 21 | `create_case` | Case | HTML |
| 22 | `update_case_fields` | Case | HTML |
| 23 | `close_case` | Case | HTML |
| 24 | `log_activity` | Activity | HTML |
| 25 | `create_task` | Activity | HTML |
| 26 | `update_task` | Activity | HTML |
| 27 | `create_event` | Activity | HTML |
| 28 | `update_event` | Activity | HTML |
| 29 | `fetch_my_open_tasks` | Activity | JSON |
| 30 | `complete_task` | Activity | HTML |
| 31 | `fetch_session_context` | Utility | JSON |
| 32 | `fetch_picklist_values` | Utility | JSON |
| 33 | `run_internal_prompt` | Utility | JSON |

---

## Wave 2 — Discovery & routing ✅ built (7)

| # | Skill | Handler | Out | Status |
|---|-------|---------|-----|--------|
| 34 | `fuzzy_search_opportunities` | Opportunity | JSON | ✅ |
| 35 | `fuzzy_search_cases` | Case | JSON | ✅ |
| 36 | `add_case_comment` | Case | HTML | ✅ |
| 37 | `fuzzy_search_products` | Product | JSON | ✅ |
| 38 | `fetch_product_details` | Product | JSON | ✅ |
| 39 | `fetch_pricebook_entries` | Product | JSON | ✅ |
| 40 | `transfer_record_owner` | Utility | HTML | ✅ |

---

## Wave 3 — Campaign ✅ built (7)

| # | Skill | Handler | Out |
|---|-------|---------|-----|
| 41 | `fuzzy_search_campaigns` | Campaign | JSON |
| 42 | `fetch_campaign_details` | Campaign | JSON |
| 43 | `create_campaign` | Campaign | HTML |
| 44 | `update_campaign_fields` | Campaign | HTML |
| 45 | `fetch_campaign_members` | Campaign | JSON |
| 46 | `add_campaign_member` | Campaign | HTML |
| 47 | `update_campaign_member_status` | Campaign | HTML |

---

## Wave 4 — Quote standard ✅ built (6)

| # | Skill | Handler | Out |
|---|-------|---------|-----|
| 48 | `fuzzy_search_quotes` | Quote | JSON |
| 49 | `fetch_quote_details` | Quote | JSON |
| 50 | `create_quote` | Quote | HTML |
| 51 | `update_quote_fields` | Quote | HTML |
| 52 | `add_quote_line_item` | Quote | HTML |
| 53 | `update_quote_line_item` | Quote | HTML |

---

## Wave 5 — Deal team, pipeline, contract ✅ built (11)

| # | Skill | Handler | Out |
|---|-------|---------|-----|
| 54 | `fetch_opportunity_contact_roles` | Opportunity | JSON |
| 55 | `add_opportunity_contact_role` | Opportunity | HTML |
| 56 | `update_opportunity_contact_role` | Opportunity | HTML |
| 57 | `fetch_opportunity_team` | Opportunity | JSON |
| 58 | `add_opportunity_team_member` | Opportunity | HTML |
| 59 | `fetch_my_open_opportunities` | Utility | JSON |
| 60 | `fetch_stale_opportunities` | Utility | JSON |
| 61 | `clone_opportunity` | Opportunity | HTML |
| 62 | `fetch_contract_details` | Contract | JSON |
| 63 | `create_contract` | Contract | HTML |
| 64 | `update_contract_fields` | Contract | HTML |

---

## Wave 6 — Service Cloud ✅ built (9)

| # | Skill | Handler | Out |
|---|-------|---------|-----|
| 65 | `fetch_case_team` | Case | JSON |
| 66 | `add_case_team_member` | Case | HTML |
| 67 | `search_knowledge_articles` | Utility | JSON |
| 68 | `fetch_knowledge_article` | Utility | JSON |
| 69 | `link_knowledge_article_to_case` | Case | HTML |
| 70 | `fetch_case_milestones` | Service | JSON |
| 71 | `fetch_case_entitlements` | Service | JSON |
| 72 | `assign_to_queue` | Utility | HTML |
| 73 | `fetch_queue_cases` | Utility | JSON |

---

## Wave 7 — Asset & Field Service ✅ built (10)

| # | Skill | Handler | Out |
|---|-------|---------|-----|
| 74 | `fuzzy_search_assets` | Service | JSON |
| 75 | `fetch_asset_details` | Service | JSON |
| 76 | `update_asset_fields` | Service | HTML |
| 77 | `fetch_work_order_details` | FieldService | JSON |
| 78 | `create_work_order` | FieldService | HTML |
| 79 | `update_work_order_fields` | FieldService | HTML |
| 80 | `fetch_service_appointment` | FieldService | JSON |
| 81 | `schedule_service_appointment` | FieldService | HTML |
| 82 | `update_service_appointment` | FieldService | HTML |
| 83 | `fetch_service_resource_availability` | FieldService | JSON |

---

## Wave 8 — CPQ ✅ built (6)

| # | Skill | Handler | Out |
|---|-------|---------|-----|
| 84 | `fetch_cpq_quote_details` | Cpq | JSON |
| 85 | `create_cpq_quote` | Cpq | HTML |
| 86 | `update_cpq_quote_fields` | Cpq | HTML |
| 87 | `add_cpq_quote_line` | Cpq | HTML |
| 88 | `update_cpq_quote_line` | Cpq | HTML |
| 89 | `calculate_cpq_quote` | Cpq | HTML |

---

## Wave 9 — Orders & subscriptions ✅ built (7)

| # | Skill | Handler | Out |
|---|-------|---------|-----|
| 90 | `fetch_order_details` | Order | JSON |
| 91 | `create_order` | Order | HTML |
| 92 | `update_order_fields` | Order | HTML |
| 93 | `add_order_item` | Order | HTML |
| 94 | `update_order_item` | Order | HTML |
| 95 | `fetch_subscription_details` | Order | JSON |
| 96 | `update_subscription_fields` | Order | HTML |

---

## Wave 10 — Partner / PRM ✅ built (4)

| # | Skill | Handler | Out |
|---|-------|---------|-----|
| 97 | `fuzzy_search_partners` | Partner | JSON |
| 98 | `fetch_partner_account` | Partner | JSON |
| 99 | `add_opportunity_partner` | Partner | HTML |
| 100 | `fetch_opportunity_partners` | Opportunity | JSON |

---

## Wave 11 — Industry ✅ built (3)

| # | Skill | Handler | Out |
|---|-------|---------|-----|
| 101 | `fetch_financial_account` | Industry | JSON |
| 102 | `update_financial_account_fields` | Industry | HTML |
| 103 | `fetch_care_plan` | Industry | JSON |

*Future industry slots (same handler, add when needed):* `fetch_household_members`, `fetch_warranty_term`, `fetch_donation`, `fetch_application`, `update_application_status`, `create_account_plan`, `update_account_plan_fields`

---

## Wave 12 — Platform reads ✅ built (5)

| # | Skill | Handler | Out |
|---|-------|---------|-----|
| 104 | `fetch_record_approvals` | Utility | JSON |
| 105 | `fetch_renewal_opportunities` | Utility | JSON |
| 106 | `remove_campaign_member` | Campaign | HTML |
| 107 | `create_care_task` | Industry | HTML |
| 108 | `update_care_plan_fields` | Industry | HTML |

---

## Wave 13 — Renewals, account plan, engagement ✅ built (3)

| # | Skill | Handler | Out |
|---|-------|---------|-----|
| 109 | `fetch_upcoming_renewals` | Utility | JSON |
| 110 | `fetch_account_plan` | Account | JSON |
| 111 | `fetch_contact_engagement_history` | Contact | JSON |

---

## Summary

| Wave | Theme | Count | Cumulative |
|------|-------|-------|------------|
| 1 | Core CRM ✅ | 33 | 33 |
| 2 | Discovery & routing ✅ | 7 | **40** |
| 3 | Campaign ✅ | 7 | 47 |
| 4 | Quote ✅ | 6 | 53 |
| 5 | Deal team & contract ✅ | 11 | 64 |
| 6 | Service ✅ | 9 | 73 |
| 7 | Asset & FSL ✅ | 10 | 83 |
| 8 | CPQ ✅ | 6 | 89 |
| 9 | Orders & subs ✅ | 7 | 96 |
| 10 | Partner ✅ | 4 | 100 |
| 11 | Industry (core) ✅ | 3 | 103 |
| 12 | Platform + extensions ✅ | 5 | 108 |
| 13 | Renewals, account plan, engagement ✅ | 3 | **111** |

---

## Retired names (do not reintroduce)

`delete_account`, `delete_contact`, `delete_opportunity`, `bulk_update_records`, `fetch_user_info`, `fetch_record_history`, `fetch_opportunity_recent_changes`, `log_contact_activity`, `log_lead_activity`, `log_opportunity_activity`, `fetch_customer_360`

---

## Insight prompts (not skills — configure in GPTfy)

| Use case | Approach |
|----------|----------|
| Customer / account 360 | `run_internal_prompt` after #2, #5 |
| Deal review / meeting prep | `run_internal_prompt` after #15 |
| Case summary | `run_internal_prompt` after #20 |
| Pipeline narrative | `run_internal_prompt` after #59–60 |
| KB-assisted reply draft | `run_internal_prompt` after #67–68 |
| Email / outreach draft | `run_internal_prompt` on lead/contact/opp Id |
