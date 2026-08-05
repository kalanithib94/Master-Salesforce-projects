# GPTfy Agent Library — V1 Skill Catalog

> **🔒 Locked master list:** [`MASTER_SKILL_LIST.md`](MASTER_SKILL_LIST.md) — **111 action skills** across 13 waves. This doc retains v1 detail + principles.

**Version:** 1.0 shipped · 2.0 master locked · **111 skills built**  
**V1 built:** 33 skills (Wave 1) · **Full library:** 111 skills (Waves 1–13)  
**Design:** No hard delete · Fuzzy where name-discovery matters · One `log_activity` · Create/update pairs · Insights via `run_internal_prompt` · Single unified library (all clouds)

---

## Library principles (your decisions)

| Principle | Rule |
|-----------|------|
| **One library** | Sales, Service, CPQ, FSC, FSL, Marketing — all skills in this catalog. Reorganize KB UI later; no separate product lines. |
| **Any org** | Agent runs in any customer org. Skills fail gracefully if object/license not present — no pre-check catalog splits. |
| **Insights = prompts** | 360, health narratives, meeting prep, deal summaries, objections → **`run_internal_prompt`** (+ fetch skills for context). No `fetch_customer_360` Apex skill. |
| **Actions = skills** | CRUD, log, comment, line items, transfer owner, etc. → dedicated Apex skills with confirmation. |
| **Fuzzy = name discovery** | Extend fuzzy to any object where users search by spoken/partial name and Id is unknown. See [Fuzzy search reasoning](#fuzzy-search-reasoning). |

---

## Fuzzy search reasoning

### Why v1 limited fuzzy to Account, Contact, Lead

| Reason | Detail |
|--------|--------|
| **Primary resolution path** | Reps say *"Acme"*, *"John Smith"*, *"Lead from Dell"* — not 18-char Ids. These three objects are the highest-volume name lookups in chat. |
| **Picker UX works** | Same envelope (5 latest matches, `totalFound`, View Record link). User confirms before any write. |
| **Lower false-match risk** | People and account names are distinct enough; opp names like *"Renewal"* or case subjects like *"Login issue"* collide more often. |
| **Page context covers many opp/case reads** | On record page, agent uses Id via `fetch_*_details` — no search needed. |

### Where to extend fuzzy (worth it)

| Object | Skill | Why extend |
|--------|-------|------------|
| **Opportunity** | `fuzzy_search_opportunities` | *"Find the Acme Q3 deal"* without page context — common AE phrase; accept Id or Name; same picker rules. |
| **Product** | `fuzzy_search_products` | Product names/SKUs are long and partial; feeds `add_opportunity_line_item` / quote lines. |
| **Campaign** | `fuzzy_search_campaigns` | SDR: *"add everyone from the webinar campaign"* — campaign names vary. |
| **Case** | `fuzzy_search_cases` (optional) | Subject/CaseNumber search for *"the outage ticket"* — noisier; keep 5-result picker + refine prompt. |
| **Asset** | `fuzzy_search_assets` | FSL: serial/name lookup before case/work order. |
| **Quote (std)** | `fuzzy_search_quotes` | By quote name when number unknown. |

### Where NOT fuzzy (use other skills)

| Need | Use instead |
|------|-------------|
| Knowledge answers | `search_knowledge_articles` (SOSL/keyword — not name fuzzy) |
| Insight / 360 / summary | `run_internal_prompt` |
| Exact Id on page | `fetch_*_details` with record Id |
| Case by number | `fetch_case_details` (CaseNumber) |
| Picklist values | `fetch_picklist_values` |

---

## V1 skills (implement now)

### Account (5)
| Skill | Type |
|-------|------|
| `fuzzy_search_accounts` | JSON |
| `fetch_account_details` | JSON |
| `create_account` | HTML |
| `update_account_fields` | HTML |
| `fetch_account_related_lists` | JSON |

### Contact (4)
| Skill | Type |
|-------|------|
| `fuzzy_search_contacts` | JSON |
| `fetch_contact_details` | JSON |
| `create_contact` | HTML |
| `update_contact_fields` | HTML |

### Lead (5)
| Skill | Type |
|-------|------|
| `fuzzy_search_leads` | JSON |
| `fetch_lead_details` | JSON |
| `create_lead` | HTML |
| `update_lead_fields` | HTML |
| `convert_lead` | HTML |

### Opportunity (5)
| Skill | Type |
|-------|------|
| `fetch_opportunity_details` | JSON |
| `create_opportunity` | HTML |
| `update_opportunity_fields` | HTML |
| `add_opportunity_line_item` | HTML |
| `update_opportunity_line_item` | HTML |

### Case (4)
| Skill | Type |
|-------|------|
| `fetch_case_details` | JSON (Id or CaseNumber) |
| `create_case` | HTML |
| `update_case_fields` | HTML |
| `close_case` | HTML |

### Activity (7)
| Skill | Type |
|-------|------|
| `log_activity` | HTML — WhoId/WhatId from `record_id` |
| `create_task` | HTML |
| `update_task` | HTML |
| `create_event` | HTML |
| `update_event` | HTML |
| `fetch_my_open_tasks` | JSON |
| `complete_task` | HTML |

### Helpers (3)
| Skill | Type |
|-------|------|
| `fetch_session_context` | JSON |
| `fetch_picklist_values` | JSON |
| `run_internal_prompt` | JSON |

---

## Removed from library (v1)

| Removed | Reason |
|---------|--------|
| `delete_account` / `delete_contact` / `delete_opportunity` | Not day-to-day CRM; compliance |
| `fuzzy_search_opportunities` / `fuzzy_search_cases` | Removed in v1 scope trim; **re-add in master library** where name discovery applies (see fuzzy reasoning) |
| `log_contact_activity` / `log_lead_activity` / `log_opportunity_activity` | → `log_activity` |
| `bulk_update_records` | Bulk edit not suitable for agent chat |
| `fetch_user_info` / `fetch_record_history` / `fetch_opportunity_recent_changes` | Trimmed utility set |

---

## Master library — full skills vision (v1 + future)

**Status key:** ✅ v1 built · 🔜 next · 📋 planned  
**Insight row:** always `run_internal_prompt` — not a separate fetch-360 skill.

### By cloud (object skills)

#### Core CRM — ✅ v1 (33 skills)
Account, Contact, Lead, Opportunity, Case, Activity, Helpers — as listed above.

#### Sales Cloud — 🔜 / 📋

| Object / area | Find | Read | Create | Update | Other |
|-------------|------|------|--------|--------|-------|
| Opportunity (extend) | `fuzzy_search_opportunities` 🔜 | `fetch_opportunity_details` ✅ | `create_opportunity` ✅ | `update_opportunity_fields` ✅ | line items ✅ |
| Campaign | `fuzzy_search_campaigns` | `fetch_campaign_details` | `create_campaign` | `update_campaign_fields` | `add_campaign_member`, `update_campaign_member`, `remove_campaign_member` |
| Campaign Member | — | `fetch_campaign_members` | — | `update_campaign_member_status` | |
| Product | `fuzzy_search_products` | `fetch_product_details` | — | — | `fetch_pricebook_entries` |
| Quote (standard) | `fuzzy_search_quotes` | `fetch_quote_details` | `create_quote` | `update_quote_fields` | `add_quote_line_item`, `update_quote_line_item` |
| Opp Contact Role | — | `fetch_opportunity_contact_roles` | `add_opportunity_contact_role` | `update_opportunity_contact_role` | |
| Opp Team | — | `fetch_opportunity_team` | `add_opportunity_team_member` | — | |
| Contract | — | `fetch_contract_details` | `create_contract` | `update_contract_fields` | |
| **Insight** | — | — | — | — | `run_internal_prompt` (deal review, pipeline narrative) |

#### Service Cloud — 📋

| Object / area | Find | Read | Create | Update | Other |
|-------------|------|------|--------|--------|-------|
| Case (extend) | `fuzzy_search_cases` | `fetch_case_details` ✅ | `create_case` ✅ | `update_case_fields` ✅ | `close_case` ✅, `add_case_comment` |
| Case Comment | — | `fetch_case_comments` | — | — | via `add_case_comment` |
| Case Team | — | `fetch_case_team` | `add_case_team_member` | — | |
| Knowledge | — | `fetch_knowledge_article` | — | — | `search_knowledge_articles` |
| Entitlement / SLA | — | `fetch_case_milestones`, `fetch_case_entitlements` | — | — | |
| Asset | `fuzzy_search_assets` | `fetch_asset_details` | — | `update_asset_fields` | |
| **Insight** | — | — | — | — | `run_internal_prompt` (case summary, resolution draft) |

#### Field Service — 📋

| Object / area | Find | Read | Create | Update | Other |
|-------------|------|------|--------|--------|-------|
| Work Order | — | `fetch_work_order_details` | `create_work_order` | `update_work_order_fields` | |
| Service Appointment | — | `fetch_service_appointment` | `schedule_service_appointment` | `update_service_appointment` | |
| Service Resource | — | `fetch_service_resource_availability` | — | — | |

#### CPQ / Revenue Cloud — 📋 (same library)

| Object / area | Find | Read | Create | Update | Other |
|-------------|------|------|--------|--------|-------|
| CPQ Quote | — | `fetch_cpq_quote_details` | `create_cpq_quote` | `update_cpq_quote_fields` | `add_cpq_quote_line`, `update_cpq_quote_line`, `calculate_cpq_quote` |
| Order | — | `fetch_order_details` | `create_order` | `update_order_fields` | `add_order_item`, `update_order_item` |
| Subscription | — | `fetch_subscription_details` | — | `update_subscription_fields` | |

#### Marketing / PRM — 📋

| Object / area | Find | Read | Create | Update | Other |
|-------------|------|------|--------|--------|-------|
| Partner | `fuzzy_search_partners` | `fetch_partner_account` | — | — | `add_opportunity_partner` |
| Lead (extend) | ✅ fuzzy | ✅ | ✅ | ✅ | ✅ convert |

#### Industry — 📋 (same library)

| Cloud | Example skills |
|-------|------------------|
| **FSC** | `fetch_financial_account`, `update_financial_account_fields`, `fetch_household_members` |
| **Health** | `fetch_care_plan`, `create_care_task`, `update_care_plan_fields` |
| **Manufacturing** | `fetch_warranty_term`, `create_warranty_claim_case` |
| **Nonprofit** | `fetch_donation`, `create_recurring_donation` |
| **Education** | `fetch_application`, `update_application_status` |

#### Platform helpers — 📋

| Skill | Purpose |
|-------|---------|
| `transfer_record_owner` | Any supported object — routing |
| `assign_to_queue` | Case/Lead queue assignment |
| `fetch_my_open_opportunities` | Scoped list (not insight — feeds prompt or display) |
| `fetch_record_approvals` | Approval status read |
| `fetch_chatter_feed` | Recent feed on record (or defer to prompt) |

---

### By persona (parallel — what the agent can do)

Each persona uses **skills for actions** + **`run_internal_prompt` for insight**.

| Persona | Find & open | Update & act | Log & schedule | Insight (prompt) |
|---------|-------------|--------------|----------------|------------------|
| **SDR / BDR** | fuzzy lead/contact/account; campaign fuzzy | create/update lead; convert; campaign member status | log_activity; create_task | lead score narrative; outreach draft |
| **AE** | fuzzy account/contact/opp; product fuzzy | opp CRUD; line items; contact role; quote create | log_activity; create_event | deal review; meeting prep; objection handling |
| **Sales manager** | fuzzy account/opp; my team's opps list skill | transfer owner; update forecast fields | create_task (coaching) | pipeline summary prompt; stale deal analysis |
| **CSM** | fetch account + related lists | update account; case create if escalation | QBR task; log_activity | account health prompt; renewal risk narrative |
| **Support agent** | fetch case (Id/number); fuzzy case optional | update case; close; add_case_comment | log_activity; callback task | case summary; KB-assisted reply draft |
| **Support lead** | fetch queue cases skill | assign_to_queue; priority update | — | queue health prompt |
| **Dispatcher (FSL)** | fuzzy asset; fetch work order | schedule/update appointment | — | technician brief prompt |
| **Rev ops / CPQ** | fetch cpq quote/order | cpq quote lines; calculate; order items | — | quote variance prompt |
| **Marketing ops** | fuzzy campaign | campaign CRUD; members | — | campaign performance prompt |
| **Partner manager** | fuzzy partner | deal reg lead; opp partner | log_activity | partner pipeline prompt |
| **Any user on record page** | fetch_*_details via session Id | update_* for that object | log_activity on record_id | any configured GPTfy prompt on record |

---

### What your agent can do (skills-based summary)

**Discover & resolve records**
- Fuzzy name search (people, companies, deals, products, campaigns, assets, quotes)
- Fetch by Id, CaseNumber, or related list
- Session/page context → WhoId/WhatId

**Read CRM state**
- Record details, related lists, open tasks, pricebook entries, team/roles, milestones, KB articles

**Write CRM state (with confirmation)**
- Create/update Account, Contact, Lead, Opp, Case, Campaign, Quote, Order, CPQ quote, Asset, Work Order, etc.
- Add/update line items (opp, quote, order, CPQ)
- Convert lead, close case, complete task
- Log completed activity on any record
- Create/update tasks and events
- Add case comments, campaign members, team members, contact roles
- Transfer owner, assign queue

**Validate before write**
- Picklist values (including dependent)
- Date resolution (system prompt Rule 4)

**AI insight (not separate Apex — prompt skill)**
- Customer/deal/account/case 360 narrative
- Meeting prep, summaries, objections, email drafts
- Pipeline/account health stories
- Any customer-configured GPTfy prompt on a record

**Explicitly out of scope**
- Hard delete, bulk mass update, setup/metadata changes

---

## Legacy v2 notes (superseded by master library above)

Separate pack catalogs and `fetch_customer_360` as Apex are **deprecated** in favor of one library + `run_internal_prompt` for insight.

---

## Agentforce positioning

| Capability | V1 library |
|------------|------------|
| Find by name (Account/Contact/Lead) | ✅ |
| Record detail & related lists | ✅ |
| Create / update core objects | ✅ |
| Log completed activity | ✅ `log_activity` |
| Tasks & events (create/update) | ✅ |
| Opp products (add/update line) | ✅ |
| Lead convert / case close | ✅ |
| Picklist validation | ✅ |
| Page context (WhoId/WhatId) | ✅ |
| AI summaries & drafts | ✅ `run_internal_prompt` |
| Hard delete | ❌ intentional |
| Bulk edit | ❌ intentional |
| CPQ / Campaign / Knowledge | V2 packs |
