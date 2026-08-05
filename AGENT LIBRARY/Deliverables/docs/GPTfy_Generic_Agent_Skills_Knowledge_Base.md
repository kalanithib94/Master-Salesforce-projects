# GPTfy Generic Agent Skills — Knowledge Base

**Audience:** Salesforce Admins & business users who interact with the GPTfy AI Agent
**Library:** `GenericAgenticSkillsHandler`
**Version:** 1.0 — May 2026
**Jira Reference:** V2-8418

---

## 1. What is this Agent?

The GPTfy Generic CRM Assistant is an AI-powered agent built on top of the GPTfy framework. It exposes **37 production-ready skills** that allow business users to perform everyday Salesforce operations through natural language — search, create, update, log activities, run AI prompts, and bulk-update records — across the most-used standard objects (Account, Contact, Lead, Opportunity, Case, Task, Event).

Every action the agent performs is grounded in a **skill call**. Skills are deterministic Apex methods — the agent never invents data; it can only return what the skills give it.

### Key Properties

| Property | Value |
|----------|-------|
| Apex Class | `GenericAgenticSkillsHandler` |
| Test Class | `GenericAgenticSkillsHandlerTest` |
| Implements | `ccai.AIAgenticInterface` |
| Salesforce API Version | 66.0 |
| Total Skills | 37 |
| Action Skills (return HTML) | 20 |
| Data Skills (return JSON) | 17 |
| Bulk-update support | ✅ (Text / Number / Picklist / Dependent Picklist / Boolean) |
| Mixed Operation support | ✅ (`run_internal_prompt` invokes a GPTfy AI Prompt against a record) |
| Confirmation flow | Required before every CREATE / UPDATE / CONVERT / CLOSE / COMPLETE / log activity |
| Data Context Mapping | ✅ Every `ccai__AI_Prompt__c` record is wired to a single `ccai__AI_Data_Extraction_Mapping__c` lookup (default Id used in this org: **`a04J9000002y7ShIAI`**) |

---

## 2. How the Agent works (in 30 seconds)

```
USER ───────────► AI AGENT ───────────► SKILL HANDLER ───────────► SALESFORCE
   (chat)            (LLM)              (Apex class)              (DML / SOQL)
                       │                       │
                       │   ┌── JSON ◄──────────┘  (data skills)
                       │   │
                       │   └── HTML ◄──────────┘  (action skills)
                       │
                       ▼
                  Response (rendered verbatim in chat UI)
```

1. The user types a request in plain English.
2. The LLM picks the right skill from the 37 available, extracts the parameters, and calls it.
3. The Apex handler executes the operation under Salesforce sharing rules and FLS, then returns either JSON (data) or HTML (action confirmation card).
4. The agent renders the response back to the user — never inventing data.

### Page context (record-page-aware behaviour)

When the chat is opened from a Salesforce record page, the runtime injects the **page-context record Id** (e.g. `001JX0000018s4R`) and **object type** (e.g. `Account`) into the LLM's context. This Id IS the confirmed record — the agent must use it directly instead of asking "Which record?" or running `fuzzy_search_*` on a paraphrase of the user's message.

**Object Id prefixes** (so the agent can recognise the page-context Id format):

| Object | Id prefix | Detail-fetch skill | Page-context parameter |
|---|---|---|---|
| Account | `001…` | `fetch_account_details` | `account_id` |
| Contact | `003…` | `fetch_contact_details` | `contact_id` |
| Lead | `00Q…` | `fetch_lead_details` | `lead_id` |
| Opportunity | `006…` | `fetch_opportunity_details` | `opportunity_id` |
| Case | `500…` | `fetch_case_details` | `case_id` |

**Page-context fast paths** (apply BEFORE name-based resolution):

- *"Provide the [object] details" / "Show me this record" / "Summarise this account"* → call `fetch_<object>_details` immediately with `<object>_id = <page record Id>`. Do NOT call `fuzzy_search_*`. Do NOT ask the user to name the record.
- *"Update this [field]" / "Change [field] to X"* → call `update_<object>_fields` with `<object>_id = <page record Id>`. Skip the name-resolution step. (The Rule 3 update-confirmation flow still applies.)
- *"Log a call / activity"* → call the matching `log_*_activity` skill with `<object>_id = <page record Id>`. (The Rule 6 ACTIVITY confirmation flow still applies.)

If the runtime did NOT supply a page record Id (the user is not on a record page, or the chat embed isn't passing `recordId`), the agent falls back to name-based resolution: for **Account detail/read** requests you may call `fetch_account_details` with `account_name` (see Skill 2); for other objects or when browsing many matches, use `fuzzy_search_*` then a confirmed Id. The agent NEVER fabricates an Id and NEVER paraphrases "the current record" / "this account" as a `search_term`.

> The system prompt operationalises this in **Rule 2 — KNOW WHICH RECORD** (see the "CRITICAL — Using the record Id from page context" sub-section and **Example 4** in `docs/GenericCRMAssistant_SystemPrompt.txt` v1.3.2+).

---

## 3. Skill Catalogue (37 skills)

Skills are grouped into 7 functional families. Each skill below shows its **purpose**, **inputs**, and **what to ask the agent**.

> **Notation**:
> - `obj_id` = Salesforce 15- or 18-character record Id
> - All CREATE / UPDATE skills accept Salesforce field API names as **flat top-level parameters** (e.g. `LastName`, `StageName`, `AnnualRevenue`). There is no nested `fields` wrapper — the legacy `{ "fields": { … } }` shape is still accepted by the Apex for backward compatibility but is no longer used in the JSON prompt commands.
> - HTML = response is a confirmation card rendered as-is
> - JSON = response is structured data the agent uses to compose its reply

> **Fuzzy-search response envelope (shared by `fuzzy_search_accounts`, `fuzzy_search_contacts`, `fuzzy_search_leads`, `fuzzy_search_opportunities`, `fuzzy_search_cases`)**
>
> Every fuzzy_search_* skill fetches **all** matching records from the database (capped at 200 for governor safety), orders them by `LastModifiedDate DESC`, and returns the **latest 5** to the agent in the `records` array — never more. The JSON envelope additionally carries:
> - `totalFound` — total matches in the database (may exceed 5).
> - `displayed` — number of rows actually present in `records` (always ≤ 5).
> - `remaining` — `totalFound − displayed`. The system prompt requires the agent to append "{remaining} more not shown — refine your search" whenever this is greater than zero.
>
> Each row carries `Id` and `recordUrl` (for follow-up calls) and a pre-built `viewRecord` HTML anchor (`<a href="..." target="_blank">View Record</a>`). The remaining columns (Name / Type / Subject / etc.) vary per skill — see each skill's entry below.

---

### 3.1 Account Skills (5)

#### Skill 1 — `fuzzy_search_accounts`
- **Purpose:** Find Accounts by partial / fuzzy Name match. Handles spaces, hyphens, casing and filler words ("the", "a").
- **Inputs:** `search_term` (string)
- **Output:** JSON envelope — fetches ALL matching Accounts (capped at 200) ordered by `LastModifiedDate DESC`, returns the **latest 5** in `records` plus three counters at the top level so the agent can display "X more not shown":
    - `records[]` — at most 5 rows. Each row carries `Id`, `Name`, `Type`, `Industry`, `Website`, `recordUrl`, and a pre-built `viewRecord` HTML anchor (`<a href="..." target="_blank">View Record</a>`).
    - `totalFound` — total number of matching Accounts in the database.
    - `displayed` — number of rows actually present in `records` (≤ 5).
    - `remaining` — `totalFound − displayed` (the agent surfaces this as "M more not shown").
- **Per-record display schema (what the agent shows the user):** Name | Type | Industry | Website | View Record (clickable hyperlink to the Account's Lightning record page).
- **Ask the agent:** *"Find accounts named power grid"*, *"Look up the Acme account"*

#### Skill 2 — `fetch_account_details`
- **Purpose:** Return full detail for one Account by **Salesforce Id** or by **Account Name** (fuzzy Name match, same engine as `fuzzy_search_accounts`).
- **Inputs:** Exactly one of:
    - **`account_id`** — preferred on an Account record page (`001…`) or whenever a confirmed Id exists. Direct detail SOQL; ignores `account_name` if both are sent.
    - **`account_name`** — use when the user named the Account and you have no Id. Resolution outcomes:
        - **0 matches** — `success: false`, user-facing not-found message.
        - **1 match** — `success: true` with the standard detail payload (Id, Name, Industry, Type, AnnualRevenue, NumberOfEmployees, Phone, Website, Owner, BillingAddress, Description, recordUrl).
        - **2–5 matches** — `success: false`, `errorCode: AMBIGUOUS_ACCOUNT_NAME`, `records[]` picker rows (Id, Name, Type, Industry, Website, recordUrl, viewRecord) — agent shows inline picker, then re-calls with `account_id`.
        - **6+ matches** — `success: false`, `errorCode: TOO_MANY_ACCOUNT_MATCHES`, `totalFound` — agent asks refinement questions; must not list every row.
- **Output:** Success payload as above. **Rating** is not queried or returned (orgs may omit the field).
- **Ask the agent:** *"What's the annual revenue and industry of Acme Power Grid?"* (off-page → `account_name`), *"Provide this account's details"* (on Account page → `account_id`).

#### Skill 3 — `create_account`
- **Purpose:** Create a new Account.
- **Inputs:** `Name` (required) + each additional Account field (`Industry`, `Type`, `AnnualRevenue`, `Phone`, `Website`, `Billing*`, `Description`, `Rating`, custom `__c` fields, …) as a flat top-level key.
- **Output:** HTML success card with link to created Account.
- **Ask the agent:** *"Create a new account named 'Plumcloud Labs' in the Technology industry"*

#### Skill 4 — `update_account_fields`
- **Purpose:** Bulk multi-field update of an Account. Supports Text, Number, Picklist, Dependent Picklist, Boolean.
- **Inputs:** `account_id` (required) + each Account field to update as a flat top-level key (e.g. `Industry`, `AnnualRevenue`, `Type`, custom `__c` fields). No nested `fields` object.
- **Output:** HTML diff card showing old → new values.
- **Ask the agent:** *"Update Acme Power Grid — set industry to Energy, type to Customer - Channel, annual revenue to 7.5M"*

#### Skill 5 — `fetch_account_related_lists`
- **Purpose:** Fetch related Contacts, Opportunities and Cases for an Account.
- **Inputs:** `account_id`, optional `related` (list — `"contacts"`, `"opportunities"`, `"cases"`).
- **Output:** JSON arrays.
- **Ask the agent:** *"Show me all opportunities and contacts on Acme Power Grid"*

---

### 3.2 Contact Skills (5)

| # | Skill | Purpose | Required inputs | Output |
|---|-------|---------|-----------------|--------|
| 6 | `fuzzy_search_contacts` | Search by Name or Email | `search_term` | JSON |
| 7 | `fetch_contact_details` | Full details | `contact_id` | JSON |
| 8 | `create_contact` | Create Contact (auto-resolves Account from `account_name`) | `LastName` (required); optional flat fields (`FirstName`, `Email`, `Phone`, `MobilePhone`, `Title`, `Department`, `AccountId`, `Mailing*`); optional `account_name` | HTML |
| 9 | `update_contact_fields` | Bulk multi-field update | `contact_id` (required) + each Contact field to change as a flat top-level key | HTML diff |
| 10 | `log_contact_activity` | Log a Task on the Contact | `contact_id`, `activity_subject`, optional `activity_description` | HTML |

**Sample chats:**
- *"Find John Smith"* → Skill 6
- *"Create contact Sarah Khan with email sarah@plumcloud.com on Acme Power Grid"* → Skill 8
- *"Log a call with John Smith — discussed renewal"* → Skill 10

---

### 3.3 Lead Skills (6)

| # | Skill | Purpose | Required inputs | Output |
|---|-------|---------|-----------------|--------|
| 11 | `fuzzy_search_leads` | Search by Name / Company / Email | `search_term` | JSON |
| 12 | `fetch_lead_details` | Full details | `lead_id` | JSON |
| 13 | `create_lead` | Create Lead | `LastName` + `Company` (required) + each additional Lead field as a flat top-level key | HTML |
| 14 | `update_lead_fields` | Bulk multi-field update | `lead_id` (required) + each Lead field to change as a flat top-level key | HTML diff |
| 15 | `convert_lead` | Convert Lead → Account / Contact / Opportunity | `lead_id`, optional `account_id`, `opportunity_name`, `do_not_create_opportunity` | HTML |
| 16 | `log_lead_activity` | Log Task on Lead | `lead_id`, `activity_subject` | HTML |

**Sample chats:**
- *"Convert Jane Doe — merge into Acme Power Grid, opportunity name 'Acme Renewal Q3'"* → Skill 15
- *"Update Jane Doe — set status to Working, rating to Hot"* → Skill 14

---

### 3.4 Opportunity Skills (7)

| # | Skill | Purpose | Required inputs | Output |
|---|-------|---------|-----------------|--------|
| 17 | `fuzzy_search_opportunities` | Search by Name (or Id) | `search_term` | JSON |
| 18 | `fetch_opportunity_details` | Full details + `currentdate__c` | `opportunity_id` | JSON |
| 19 | `create_opportunity` | Create Opportunity | `Name` + `StageName` + `CloseDate` (required) + each additional Opportunity field as a flat top-level key | HTML |
| 20 | `update_opportunity_fields` | Bulk multi-field update (incl. dependent picklists) | `opportunity_id` (required) + each Opportunity field to change as a flat top-level key | HTML diff |
| 21 | `log_opportunity_activity` | Log Task | `opportunity_id`, `activity_subject` | HTML |
| 22 | `add_opportunity_line_item` | Add a Product to the Opportunity | `opportunity_id`, `pricebook_entry_id` OR `product_name`, `quantity`, `unit_price` | HTML |
| 23 | `fetch_opportunity_recent_changes` | Field-history snapshot | `opportunity_id`, optional `days` (1-365) | JSON |

**Sample chats:**
- *"Move Acme Big Deal to Negotiation/Review and push close date to next month"* → Skill 20 (date resolved by system prompt to yyyy-MM-dd)
- *"Add 5 units of 'Annual Subscription' at $1200 to the Acme Big Deal opportunity"* → Skill 22
- *"What changed on Acme Big Deal in the last 14 days?"* → Skill 23

---

### 3.5 Case Skills (5)

| # | Skill | Purpose | Required inputs | Output |
|---|-------|---------|-----------------|--------|
| 24 | `fuzzy_search_cases` | Search by CaseNumber / Subject | `search_term` | JSON |
| 25 | `fetch_case_details` | Full details (accepts Id or CaseNumber) | `case_id` | JSON |
| 26 | `create_case` | Create Case | `Subject` (required) + each additional Case field as a flat top-level key | HTML |
| 27 | `update_case_fields` | Bulk multi-field update | `case_id` (required) + each Case field to change as a flat top-level key | HTML diff |
| 28 | `close_case` | Close Case + add comment | `case_id`, `reason`, optional `comments` | HTML |

**Sample chats:**
- *"Open a high-priority case on Acme Power Grid: 'Login screen crash on Safari'"* → Skill 26
- *"Close case 00001234 with reason 'Other' — note: resolved during call"* → Skill 28

---

### 3.6 Activity Skills (4)

| # | Skill | Purpose | Required inputs | Output |
|---|-------|---------|-----------------|--------|
| 29 | `create_task` | Create Task on any record (`WhatId` / `WhoId`) | `Subject` (required) + each additional Task field as a flat top-level key | HTML |
| 30 | `create_event` | Create Event on any record | `Subject` + `StartDateTime` (required) + each additional Event field as a flat top-level key (defaults DurationInMinutes to 30 if no end / duration) | HTML |
| 31 | `fetch_my_open_tasks` | Running user's open tasks | optional `limit` | JSON |
| 32 | `complete_task` | Mark Task = Completed | `task_id` | HTML |

**Sample chats:**
- *"Schedule a 1-hour demo with Acme Power Grid next Tuesday at 2 PM"* → Skill 30
- *"What's on my plate this week?"* → Skill 31
- *"Mark my 'Follow-up call' task done"* → Skill 32

---

### 3.7 Utility Skills (5) — object-agnostic

#### Skill 30 — `bulk_update_records`
- **Purpose:** Generic, multi-record / multi-field / multi-type bulk update for ANY standard or custom object. **This is the core "bulk update" skill mentioned in the JIRA.**
- **Inputs:**
  ```json
  {
    "object_api_name": "Opportunity",
    "records": [
      { "Id": "006...", "StageName": "Closed Won", "Amount": 50000 },
      { "Id": "006...", "StageName": "Closed Lost", "IsActive__c": false }
    ]
  }
  ```
- **Output:** HTML summary card with success / failure / skipped counts + first 3 errors.
- **Ask the agent:** *"Mark these three opportunities as Closed Won"*, *"Set these contacts' MailingCountry to 'United States'"*

#### Skill 31 — `fetch_record_history`
- **Purpose:** Read field-history audit for any object that has Field History Tracking enabled (works for both standard and `__c` custom objects).
- **Inputs:** `record_id`, `object_api_name`, optional `days` (default 30, max 365)
- **Output:** JSON list of `{ field, oldValue, newValue, changedAt }`

#### Skill 32 — `fetch_user_info`
- **Purpose:** Get the running user's profile, role, locale, time zone and `currentdate__c` (today's date anchor).
- **Inputs:** none
- **Output:** JSON

#### Skill 33 — `run_internal_prompt`  ⭐ Mixed Operation
- **Purpose:** The "Mixed Operation" requested in the JIRA — combines DML (the record context) with an internal GPTfy AI Prompt to produce LLM-formatted prose (Deal Overview / Stakeholder Map / Meeting Prep / etc.).
- **Inputs:** `prompt_request_id` (the GPTfy Prompt Request Id), `record_id`
- **Output:** JSON `{ success: true, message: "<llm-text>" }` — agent renders the message verbatim.
- **Implementation note:** Mirrors the `runOpportunityPrompt` pattern from your `SP_CI_Agent` reference handler. Use this skill any time the user asks for a free-form summary against a specific record.

#### Skill 34 — `fetch_picklist_values`
- **Purpose:** Returns the valid picklist (or multi-picklist) values for any field. **Supports dependent picklists** when `controller_value` is supplied — only valid options for that controller are returned.
- **Inputs:** `object_api_name`, `field_api_name`, optional `controller_value`
- **Output:** JSON list of `{ label, value, active, default }`

---

## 4. End-to-end Sample Conversations

### 4.1 Update an Opportunity (UPDATE flow with confirmation)

> **User:** Move Acme Big Deal to Negotiation and push close date to end of month
>
> **Agent (silent):** Calls `fuzzy_search_opportunities` with `search_term: "Acme Big Deal"` → resolves Id + current StageName + CloseDate.
>
> **Agent:**
> > **Acme Big Deal**
> > **Stage:** Prospecting → **Negotiation/Review**
> > **Close Date:** 2026-06-15 → **2026-05-31**
> > Shall I proceed?
>
> **User:** Yes
>
> **Agent (silent):** Calls `update_opportunity_fields` with `{ opportunity_id, fields: { StageName, CloseDate } }`
>
> **Agent (renders HTML verbatim):**
> > ✅ **Opportunity Updated: Acme Big Deal**
> > - **Stage:** Prospecting → **Negotiation/Review**
> > - **Close Date:** 2026-06-15 → **2026-05-31**
> >
> > 👉 **[View Opportunity](#)**

### 4.2 Bulk update multiple records (BULK flow)

> **User:** Set the industry to "Energy" on these 3 accounts: Acme, Beta, Gamma
>
> **Agent (silent):** Calls `fuzzy_search_accounts` for each name → collects Ids.
>
> **Agent:**
> > I'll update **3 accounts** — set Industry = **Energy**.
> > - Acme Power Grid
> > - Beta Industries
> > - Gamma Holdings
> > Shall I proceed?
>
> **User:** Go ahead
>
> **Agent (silent):** Calls `bulk_update_records` with `object_api_name: "Account"` + 3-record list.
>
> **Agent (renders HTML verbatim):**
> > ✅ **Bulk Update Complete**
> > - **Object:** Account
> > - **Succeeded:** 3
> > - **Failed:** 0
> > - **Skipped:** 0

### 4.3 Run an Internal Prompt (Mixed Operation)

> **User:** Give me a deal overview for Acme Big Deal
>
> **Agent (silent):**
> 1. Resolve opportunity via `fuzzy_search_opportunities`.
> 2. Look up the configured `prompt_request_id` for "Deal Overview".
> 3. Call `run_internal_prompt` with the prompt id + record id.
>
> **Agent (renders the LLM message verbatim):**
> > **Acme Big Deal — Deal Overview**
> > Stage: Negotiation/Review · Amount: $25,000 · Owner: …
> > **Risks:** …
> > **Next steps:** …

### 4.4 Convert a Lead

> **User:** Convert Jane Doe and create an opportunity called "Lead Co Renewal"
>
> **Agent:**
> > I'll convert **Jane Doe (Lead Co)**:
> > - Create / link Account: **Lead Co**
> > - Create Contact: **Jane Doe**
> > - Create Opportunity: **Lead Co Renewal**
> > Shall I proceed?
>
> **User:** Yes
>
> **Agent (silent):** Calls `convert_lead`
>
> **Agent (renders HTML verbatim):**
> > ✅ **Lead Converted**
> > - **Account Id:** 001…
> > - **Contact Id:** 003…
> > - **Opportunity Id:** 006…

### 4.5 Field-history audit

> **User:** What changed on Acme Big Deal in the last 14 days?
>
> **Agent (silent):** `fetch_opportunity_recent_changes` with `days: 14`.
>
> **Agent:**
> > Acme Big Deal — 4 changes in the last 14 days:
> > | Field | Old | New | When |
> > |-------|-----|-----|------|
> > | StageName | Prospecting | Negotiation/Review | 2026-05-02 |
> > | Amount | 25,000 | 30,000 | 2026-05-04 |
> > …

---

## 5. Field-Type Coercion Reference

The handler coerces every value to the field's expected Apex type before DML. The agent only needs to send raw values — **no special quoting**.

| Salesforce Field Type | Pass to skill as | Example |
|-----------------------|------------------|---------|
| Text / Long Text Area | string | `"Customer - Direct"` |
| Integer | number or numeric string | `5` or `"5"` |
| Currency / Number / Percent | number | `25000` or `"25,000"` (commas are stripped) |
| Boolean / Checkbox | `true` / `false` (or `"true"` / `"yes"` / `"1"`) | `true` |
| Picklist | string with the API value | `"Negotiation/Review"` |
| Multi-picklist | `"A;B;C"` OR `["A","B","C"]` | both accepted |
| Dependent Picklist | string — Salesforce validates at DML | `"Premium"` |
| Date | `"yyyy-MM-dd"` | `"2026-05-31"` |
| Datetime | ISO 8601 / `"yyyy-MM-dd HH:mm:ss"` | `"2026-05-31T14:30:00Z"` |
| Reference (Id) | 15- or 18-char Id string | `"001A0000005Tx9X"` |

---

## 6. Error Handling

Every skill returns one of two shapes:

### Data skills (JSON)
```json
{ "success": false, "error": "Friendly message here" }
```
The agent surfaces `error` as a friendly chat message and stops.

### Action skills (HTML)
On error the skill returns:
```html
<div>⚠️ <b>Could not update opportunity</b><br/>Reason text</div>
```
The agent renders it verbatim — no JSON ever leaks to the user.

### Common error messages and what they mean

| Error message | Meaning | What the user should do |
|---------------|---------|--------------------------|
| `Missing required parameter: X` | The agent didn't extract a value the skill needed. | Retry with more specific phrasing. |
| `Object is not accessible / updateable / deletable` | The running user lacks the right object permission. | Contact the Salesforce admin. |
| `Field not updateable: X` | FLS denies updating that field for the running user. | Ask the admin to grant edit access. |
| `Unknown field "X" on Y` | The agent guessed an API name that doesn't exist. | Reword — the agent can call `fetch_picklist_values` first. |
| `Could not parse the close date "..."` | A relative phrase ("next monday") wasn't resolved. | Should not happen — system prompt handles it. |
| `No record found for provided Id` | Record was deleted or the user doesn't have access. | Re-search by name. |
| `Lead is already converted` | Lead already converted earlier. | Use the converted Account/Contact/Opportunity instead. |

---

## 7. Confirmation Flow (always required)

The agent MUST ask before any **create / update / convert / close** action. Confirmation cards always show:

1. The record name at the top
2. Each field as `[Current value] → [New value]` (in bold)
3. The question "Shall I proceed?"

The agent only proceeds on an explicit yes / confirm / go ahead. On decline:

> "No changes made. Let me know if you'd like to update anything else."


---

## 8. Setup & Configuration Checklist

Before going live the admin should:

1. ✅ Deploy `GenericAgenticSkillsHandler.cls` and `GenericAgenticSkillsHandlerTest.cls` (both with their `cls-meta.xml`).
2. ✅ Run all tests — confirm coverage > 75 %.
3. ✅ Create an `AI_Agent__c` record (Status = Active) and link the **System Prompt** (provided as `GenericCRMAssistant_SystemPrompt.txt`).
4. ✅ Create / confirm a **Data Extraction Mapping** record (`ccai__AI_Data_Extraction_Mapping__c`) that defines the data-context contract for the agent. Capture its Id — every prompt will reference it. (In this org we use **`a04J9000002y7ShIAI`**.)
5. ✅ Create one `ccai__AI_Prompt__c` record per skill with the following fields populated:
    - `Type__c` = `Agentic`
    - `Status__c` = `Active`
    - `Agentic_Function_Class__c` = `GenericAgenticSkillsHandler`
    - `AI_Data_Extraction_Mapping__c` = the Id from step 4 (e.g. `a04J9000002y7ShIAI`)
    - `Name` = the exact skill name (e.g. `fuzzy_search_accounts`)
    - `Prompt_Command__c` = OpenAPI-compatible JSON schema (see Sample API Schemas below)

    ➡️ Use the bundled scripts to create all 37 prompts in one go:
    - `scripts/Part1_Account.apex` (6) — includes `create_account`
    - `scripts/Part2_Contact.apex` (6)
    - `scripts/Part3_Lead.apex` (6)
    - `scripts/Part4_Opportunity.apex` (8)
    - `scripts/Part5_Case.apex` (5)
    - `scripts/Part6_Activity.apex` (4)
    - `scripts/Part7_Utility.apex` (5)
    - `scripts/Part0_DeleteAll.apex` — optional safety wipe (deletes by Name only) before re-running the inserts.
    - `scripts/CreateAgenticPrompts.apex` — single combined script (use only on orgs that allow large anonymous Apex; otherwise prefer the Part files above).

    Each script reads the data-context mapping Id from a `DATA_MAPPING` constant near the top — change it once if you want to point the prompts to a different mapping record.
6. ✅ Link all 37 prompts to the agent via `AI_Agent_Skill__c`.
7. ✅ Enable Field History Tracking on Opportunity (or any object you want `fetch_record_history` / `fetch_opportunity_recent_changes` to work for).
8. ✅ For `run_internal_prompt`, pre-create the GPTfy Prompt Requests (Deal Overview, Stakeholders, etc.) and capture their Ids.
9. ✅ Assign the GPTfy permission set to all end-users.

### Verification query (run after deploying the prompts)

```sql
SELECT Name, ccai__Type__c, ccai__Status__c,
       ccai__Agentic_Function_Class__c, ccai__AI_Data_Extraction_Mapping__c
FROM   ccai__AI_Prompt__c
WHERE  ccai__Agentic_Function_Class__c = 'GenericAgenticSkillsHandler'
ORDER BY Name
```

You should get **37 rows**, each with `Type = Agentic`, `Status = Active` and `AI_Data_Extraction_Mapping__c` populated.

---

## 9. Sample API Schemas (excerpts)

Each skill's `Prompt_Command__c` should be a JSON Schema. Examples below.

### fuzzy_search_accounts
```json
{
  "type": "object",
  "properties": {
    "search_term": { "type": "string", "description": "Account name or partial name to search for" }
  },
  "required": ["search_term"]
}
```

### update_account_fields

Field updates are passed as flat top-level keys (NOT nested under a `fields` object). Common Account fields are declared explicitly for LLM steering; any other standard or custom field (including `__c` fields) is allowed via `additionalProperties: true` and is picked up by the Apex.

```json
{
  "type": "object",
  "required": ["account_id"],
  "properties": {
    "account_id":    { "type": "string", "description": "ONLY the Salesforce Id of the Account to update." },
    "Name":          { "type": "string", "description": "Account Name." },
    "Industry":      { "type": "string", "description": "Industry picklist API value (call fetch_picklist_values first if unsure)." },
    "Type":          { "type": "string", "description": "Type picklist API value (call fetch_picklist_values first if unsure)." },
    "AnnualRevenue": { "type": "number", "description": "Annual revenue as a plain number, no currency symbol or commas." },
    "Phone":         { "type": "string", "description": "Account phone number." },
    "Website":       { "type": "string", "description": "Account website URL." },
    "Description":   { "type": "string", "description": "Long-text description of the Account." }
  },
  "additionalProperties": true
}
```

### bulk_update_records
```json
{
  "type": "object",
  "properties": {
    "object_api_name": { "type": "string" },
    "records": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": { "Id": { "type": "string" } },
        "required": ["Id"],
        "additionalProperties": true
      }
    }
  },
  "required": ["object_api_name", "records"]
}
```

### fetch_picklist_values
```json
{
  "type": "object",
  "properties": {
    "object_api_name": { "type": "string" },
    "field_api_name": { "type": "string" },
    "controller_value": { "type": "string", "description": "Required only for dependent picklists" }
  },
  "required": ["object_api_name", "field_api_name"]
}
```

> Schemas for the remaining 36 skills follow the same pattern — name + description + parameter object.

---

## 10. Security & Compliance

- All SOQL queries use `WITH USER_MODE` — sharing rules and FLS are enforced for every read.
- Every DML is preceded by `Schema.sObjectType.<Object>.isCreateable / isUpdateable / isDeletable` checks.
- Field-level coercion is gated by `DescribeFieldResult.isCreateable / isUpdateable`.
- The agent never returns Id-only references unless the user explicitly asks; record links use `Url.getOrgDomainUrl().toExternalForm()`.
- Action skills wrap the user's text via `escapeHtml4()` before embedding in HTML — no XSS surface.
- All exceptions are caught and surfaced as user-friendly messages; raw stack traces never leak.

---

## 11. FAQ

**Q: Can I add a 41st skill later?**
Yes — add a new branch in `executeMethod`'s `switch on m`, write the private handler, and wire a new `AI_Prompt__c` record to the agent.

**Q: Does the bulk update support records of different objects?**
No — `bulk_update_records` is single-object by design (matches Salesforce DML limits and reduces hallucination risk). Call it once per object.

**Q: What if a picklist value is misspelled?**
The handler will throw "Field not updateable / invalid value" and surface it as a friendly card. The system prompt mitigates this by calling `fetch_picklist_values` first when the AI is uncertain.

**Q: How does the agent get "today's date"?**
Every fetch / search response includes `currentdate__c` (today). The system prompt anchors all relative date resolution to this value before calling any DML skill.

**Q: Can I disable a skill for a particular user?**
Yes — the GPTfy framework checks `AI_Prompt__c.Profiles__c` and `AI_Prompt__c.Permission_Sets__c` for each skill before exposing it to the agent for that user.

---

## 12. Deliverables Inventory

| File | Purpose |
|------|---------|
| `force-app/main/default/classes/GenericAgenticSkillsHandler.cls` + `.cls-meta.xml` | The 37-skill handler |
| `force-app/main/default/classes/GenericAgenticSkillsHandlerTest.cls` + `.cls-meta.xml` | Comprehensive test class, > 75 % coverage |
| `docs/GenericCRMAssistant_SystemPrompt.txt` | System prompt for the agent |
| `docs/GPTfy_Agent_Prompt_Commands.md` | Reference doc — every skill's `Prompt_Command__c` JSON schema + description |
| `docs/GPTfy_Generic_Agent_Skills_Knowledge_Base.md` | This document |
| `scripts/CreateAgenticPrompts.apex` | Master anonymous-Apex script (37 prompts in one shot) |
| `scripts/Part0_DeleteAll.apex` | Safety wipe — deletes the 37 named prompts before re-creating them |
| `scripts/Part1_Account.apex` … `scripts/Part7_Utility.apex` | Split anonymous-Apex scripts for orgs that hit the 32 KB limit |
| `sfdx-project.json` | SFDX project root file (so `sf` CLI commands work from this directory) |

---

*End of document.*
