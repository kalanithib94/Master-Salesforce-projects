# GPTfy Generic Agent — User Request Samples (Test Pack)

**Purpose:** This document is a **manual QA / regression test pack** for the GPTfy Generic CRM Assistant. For every one of the 37 skills defined in `GPTfy_Agent_Prompt_Commands.md`, this file gives you **at least 5 natural-language user requests** that a tester can type into the agent's chat surface to verify the LLM dispatches the correct skill with the correct arguments.

**How to use:**

1. Open the agent (Lightning Utility Bar / Embedded Service Chat / `aiAgentChat` LWC).
2. Pick a skill section and paste any sample request as the user message.
3. Verify (a) the agent calls the **expected skill name**, (b) the arguments produced match the user's intent, and (c) the response narrative is grounded in the returned record data (no hallucinated Ids/values).
4. For destructive skills (`close_case`, `convert_lead`, `bulk_update_records`) confirm the agent **asks for confirmation** before invoking — and that a "no" cancels cleanly.

> **Tip:** Replace bracketed placeholders like `[Account Name]`, `[Contact Email]`, `[Opportunity Id]` with actual values from your sandbox before running. Sample names below assume a typical demo dataset (Acme, United Health, GenePoint, Express Logistics, Edge Communications, Burlington Textiles, etc.) — substitute as needed.

---

## Table of Contents

1. [Account Skills (6)](#1-account-skills-6)
2. [Contact Skills (6)](#2-contact-skills-6)
3. [Lead Skills (6)](#3-lead-skills-6)
4. [Opportunity Skills (8)](#4-opportunity-skills-8)
5. [Case Skills (5)](#5-case-skills-5)
6. [Activity Skills (4)](#6-activity-skills-4)
7. [Utility / Other-Object Skills (5)](#7-utility--other-object-skills-5)
8. [End-to-End / Multi-Skill Scenarios](#8-end-to-end--multi-skill-scenarios)

---

## 1. ACCOUNT SKILLS (5)

### 1.1 — `fuzzy_search_accounts`

Expected: agent calls `fuzzy_search_accounts` with `search_term`.

1. Find the Acme account for me.
2. Look up any account that has "United" in the name.
3. I'm searching for a company called Edge Communications — do we have it?
4. List me all accounts with the word "logistics" in their name.
5. Can you check if we have an account named Burlington Textiles?
6. Search accounts for "power grid".
7. Pull up the Genepoint account please.

---

### 1.2 — `fetch_account_details`

Expected: agent first resolves the name (silent `fuzzy_search_accounts` if ambiguous) then calls `fetch_account_details`.

1. Show me the full details of Acme Corporation.
2. What's the annual revenue and industry of United Health?
3. Give me a summary of the Edge Communications account — owner, phone, billing address, everything.
4. I need the full record for Burlington Textiles.
5. What rating and number of employees does Genepoint have?
6. Open up the Acme account and show me everything you have on it.
7. Pull the description and website for the Express Logistics account.

---

### 1.3 — `create_account`

Expected: agent calls `create_account` with `fields` containing `Name` plus any extras the user provided.

1. Create a new account named "Globex Corporation".
2. Add a new account: Name is "Initech", Industry is Technology, Phone is 408-555-0199.
3. Register a new company called "Stark Industries" — type Customer, annual revenue 50000000, billing city San Francisco.
4. I want to set up an account for "Wayne Enterprises" with website www.wayne.com and rating Hot.
5. Please create an account named "Nakatomi Trading" in the Manufacturing industry, headquartered in Los Angeles, CA.
6. New account: "Vandelay Imports", phone (212) 555-0123, type Prospect.
7. Add a customer account called "Pied Piper" with description "Compression startup, signed NDA on May 1".

---

### 1.4 — `update_account_fields`

Expected: agent confirms the change first (current value → new value) then calls `update_account_fields` with `account_id` + `fields`.

1. Change Acme's industry to Manufacturing.
2. Update the phone number on United Health to 415-555-0144.
3. Set the annual revenue on Edge Communications to 25 million.
4. Mark the Burlington Textiles account as a Customer (type = Customer).
5. Change Genepoint's rating to Warm and set the number of employees to 350.
6. Update the billing state on the Acme account to California and country to USA.
7. On Express Logistics, change the website to www.expresslogistics.com and the description to "Top tier logistics partner — renewed Q2".

---

### 1.5 — `fetch_account_related_lists`

Expected: agent calls `fetch_account_related_lists` with `account_id`, optionally with `related` filter.

1. Show me all the contacts on the Acme account.
2. What opportunities are open on United Health?
3. List the cases logged against Edge Communications.
4. Give me the contacts AND opportunities on Burlington Textiles.
5. Pull every related record (contacts, opps, cases) for Genepoint.
6. How many open cases does Express Logistics have?
7. I want to see the contacts on Acme, just the contacts.

---

## 2. CONTACT SKILLS (5)

### 2.1 — `fuzzy_search_contacts`

Expected: agent calls `fuzzy_search_contacts` with `search_term` (name or email).

1. Find a contact named John Smith.
2. Do we have a contact with the email john@acme.com?
3. Look up any contact whose last name is Khan.
4. Search contacts for "Priya".
5. I'm looking for a contact named Elena Rodriguez.
6. Pull up the contact with email rajesh.kumar@gmail.com.
7. Find any contact whose name contains "Patel".

---

### 2.2 — `fetch_contact_details`

Expected: agent has a confirmed Contact Id (either page-context or via prior search), then calls `fetch_contact_details`.

1. Show me the full details for the contact I just found.
2. Give me the title, department and mailing address for John Smith (contact Id 0035g00000ABC123).
3. What's the mobile number and email for Priya Khan?
4. Open up Elena Rodriguez's contact record.
5. Pull every field on contact 0035g00000XYZ987.
6. Show me the owner and account for the Rajesh Kumar contact.
7. I need the mailing city and state for John Smith — fetch the contact details.

---

### 2.3 — `create_contact`

Expected: agent calls `create_contact` with `LastName` (the only required field) plus any other Contact field API names the user supplied (`FirstName`, `Email`, `Phone`, `MobilePhone`, `Title`, `Department`, `AccountId`, `Mailing*`) as flat top-level parameters; resolves account via `account_name` if the user gave a name and not an Id. Never prompts for optional fields.

1. Add a new contact: First Name John, Last Name Smith, email john@acme.com, on the Acme account.
2. Create a contact named Priya Khan, title "VP Engineering", phone 408-555-0177, on United Health.
3. New contact for Burlington Textiles: Last Name Rodriguez, First Name Elena, email elena@burlington.com.
4. Add Mr. Rajesh Kumar as a contact on Edge Communications, mobile 9876543210, department Procurement.
5. Register a contact called Sarah Johnson at Genepoint with title "Director of Operations".
6. Create a contact: Last Name Patel, First Name Anita, email anita@vandelay.com, mailing city Mumbai.
7. Add a new contact named Tom Hardy on the Express Logistics account, title "Head of Sales".

---

### 2.4 — `update_contact_fields`

Expected: agent confirms, then calls `update_contact_fields` with `contact_id` + `fields`.

1. Update John Smith's title to "Chief Technology Officer".
2. Change Priya Khan's email to priya.khan@united-health.com.
3. Set Elena Rodriguez's phone number to 415-555-0188.
4. Update the mailing address on contact Rajesh Kumar — street is 24 Park Avenue, city Bangalore.
5. Change Tom Hardy's department to "Strategic Accounts".
6. Update the mobile and email for Anita Patel — mobile 9123456789, email anita.patel@gmail.com.
7. Set Sarah Johnson's title to "VP Operations" and her department to Operations.

---

### 2.5 — `log_contact_activity`

Expected: agent calls `log_contact_activity` with `contact_id` + a meaningful `activity_subject` (never a placeholder).

1. Log a call I just made to John Smith — discussed Q3 renewal pricing.
2. Record an activity on Priya Khan's record: "Demo follow-up", notes "She wants the security deck by Friday".
3. Log that I emailed Elena Rodriguez about contract redlines today.
4. Capture a meeting note on Rajesh Kumar — "Onsite kickoff — agreed to Phase 1 scope".
5. Log a follow-up on Tom Hardy's contact: subject "Pricing follow-up", description "Sent revised SOW".
6. Add an activity log on Anita Patel: discovery call done, she's the technical decision maker.
7. Track a touchpoint on Sarah Johnson — quarterly business review on May 7.

---

## 3. LEAD SKILLS (6)

### 3.1 — `fuzzy_search_leads`

Expected: agent calls `fuzzy_search_leads` with `search_term` (name, company, or email).

1. Find a lead named Jane Doe.
2. Search leads for the company "Acme Industries".
3. Do we have any leads from "@globex.com"?
4. Look up the lead Riya Mehta.
5. Pull any lead whose company is Initech.
6. List leads with email jane@acme.com.
7. Search for a lead named Carlos Mendez.

---

### 3.2 — `fetch_lead_details`

Expected: agent calls `fetch_lead_details` with `lead_id`.

1. Show me the full details on the Jane Doe lead.
2. What's the status, source and rating of lead Riya Mehta?
3. Open up the lead record for Carlos Mendez.
4. Give me the company, title and email of lead 00Q5g00000ABC123.
5. Is the Jane Doe lead converted? Show me everything on it.
6. Pull the industry and annual revenue on the Riya Mehta lead.
7. Fetch all fields on lead Id 00Q5g00000XYZ987.

---

### 3.3 — `create_lead`

Expected: agent calls `create_lead` with `fields` containing both `LastName` AND `Company`.

1. Create a new lead: First Name Jane, Last Name Doe, Company Acme Industries, email jane@acme.com.
2. Capture a lead — Last Name Mehta, First Name Riya, Company Globex, phone 9988776655, source Web.
3. New lead: Carlos Mendez at Initech, title "Director of IT", status Open - Not Contacted.
4. Add a lead called Sarah Wilson from "Stark Solutions", email sarah@stark.com.
5. Register a lead named John Park, Company Pied Piper, industry Technology, rating Hot.
6. Create a lead: Last Name Johnson, First Name Mike, Company Burlington Northern, lead source Trade Show.
7. New lead from the webform — Last Name Patel, First Name Anita, Company Vandelay Imports, email anita@vandelay.com.

---

### 3.4 — `update_lead_fields`

Expected: agent confirms, then calls `update_lead_fields` (refuses if lead is already converted).

1. Change Jane Doe's lead status to "Working - Contacted".
2. Update the rating on Riya Mehta's lead to Warm.
3. Set Carlos Mendez's title to "VP Engineering" on the lead.
4. Change the lead source on Sarah Wilson to "Partner Referral".
5. Update the annual revenue on lead John Park to 5 million.
6. Set the industry on Mike Johnson's lead to "Transportation".
7. Update the phone number on Anita Patel's lead to 9123456789.

---

### 3.5 — `convert_lead`

Expected: agent demands explicit confirmation, then calls `convert_lead`. Honours "do not create opportunity" and "merge into existing account".

1. Convert the Jane Doe lead — create a new opportunity called "Acme — Initial Deal".
2. Convert lead Riya Mehta but DO NOT create an opportunity.
3. Convert Carlos Mendez and merge into the existing Initech account.
4. Please convert the John Park lead, opportunity name "Pied Piper - Compression POC".
5. Convert Sarah Wilson's lead — use the existing Stark Industries account, no opportunity.
6. Convert lead 00Q5g00000ABC123 with default opportunity.
7. Convert the Mike Johnson lead and merge into the Burlington Northern account, opportunity name "Burlington — Logistics Renewal".

---

### 3.6 — `log_lead_activity`

Expected: agent calls `log_lead_activity` with `lead_id` + meaningful `activity_subject`.

1. Log a discovery call on the Jane Doe lead — discussed pain points around inventory.
2. Capture an activity on Riya Mehta: "Demo scheduled", notes "She wants the analytics module deep-dive".
3. Record a touchpoint on Carlos Mendez — "Pricing email sent", description "Sent the bronze/silver/gold tiers".
4. Log a meeting note on lead John Park: "Onsite intro", notes "Toured the facility, met the engineering team".
5. Track a follow-up on Sarah Wilson — left voicemail today.
6. Add an activity log on Mike Johnson: "Trade show booth visit", description "Picked up brochure, showed strong interest".
7. Log that I emailed Anita Patel the case study for Vandelay-similar customers.

---

## 4. OPPORTUNITY SKILLS (7)

### 4.1 — `fuzzy_search_opportunities`

Expected: agent calls `fuzzy_search_opportunities` with `search_term` (name or 006-prefixed Id).

1. Find the "Acme Big Deal" opportunity.
2. Search opportunities for "Renewal Q3".
3. Do we have any opportunity named "Globex Expansion"?
4. Pull up opportunity 006A0000005Tx9X.
5. List me deals with the word "Phase 2" in the name.
6. Look up "Burlington — Logistics Renewal".
7. Search for any opportunity matching "POC".

---

### 4.2 — `fetch_opportunity_details`

Expected: agent calls `fetch_opportunity_details` with `opportunity_id`.

1. Show me everything on the Acme Big Deal opportunity.
2. What's the stage, amount and close date for "Globex Expansion"?
3. Open opportunity 006A0000005Tx9X and give me the full record.
4. Give me the owner, forecast category and probability for "Renewal Q3".
5. Pull all details on the "Burlington — Logistics Renewal" deal.
6. What's the next step on the Edge Communications - SLA Renewal opportunity?
7. Fetch the description and lead source for opportunity Id 006A00000099XYZ.

---

### 4.3 — `create_opportunity`

Expected: agent calls `create_opportunity` with `fields` containing `Name`, `StageName`, AND `CloseDate`. Relative dates ("end of next month") MUST be resolved to yyyy-MM-dd before calling.

1. Create a new opportunity called "Acme - Q3 Expansion", stage Prospecting, close date end of this month, amount 250000.
2. Add an opportunity: Name "Globex - Renewal 2026", stage Negotiation, close date 2026-06-30, on the Globex account.
3. New deal — "Burlington Logistics POC", stage Qualification, close 2026-09-15, amount 75000, type New Customer.
4. Create opportunity "Edge Communications — SLA Tier 2", stage Proposal/Price Quote, close date 30 days from today, amount 120000.
5. Open a new opportunity for Pied Piper called "Pied Piper Compression POC" — stage Prospecting, close 2026-07-31.
6. Add deal "Initech ERP Replacement", stage Needs Analysis, close 2026-08-15, probability 30, lead source Partner Referral.
7. Create an opportunity named "Vandelay Imports — Year 1", stage Closed Won, close date today, amount 95000.

---

### 4.4 — `update_opportunity_fields`

Expected: agent confirms (current → new), then calls `update_opportunity_fields`. Dates must be `yyyy-MM-dd`.

1. Move the "Acme Big Deal" opportunity to stage Negotiation/Review.
2. Update the amount on "Globex Expansion" to 350000.
3. Push the close date on "Renewal Q3" to end of next quarter.
4. Set the probability on "Burlington Logistics POC" to 60%.
5. Change the next step on "Edge Communications — SLA Tier 2" to "Get legal sign-off on MSA".
6. Update the forecast category on opportunity 006A0000005Tx9X to Commit.
7. Set the description on the "Pied Piper Compression POC" deal — "Customer running production POC, decision expected end of June".

---

### 4.5 — `log_opportunity_activity`

Expected: agent calls `log_opportunity_activity` with `opportunity_id` + meaningful subject.

1. Log a meeting note on the Acme Big Deal — "Pricing committee approval received".
2. Record a demo activity on "Globex Expansion": subject "Product demo — analytics", notes "Walked through dashboards and ROI calc".
3. Capture a call note on Burlington Logistics POC: "Weekly status call", notes "On track, no blockers".
4. Log that I sent the redlined MSA to Edge Communications for the SLA Tier 2 deal.
5. Track a touchpoint on the Pied Piper POC opportunity — "Technical deep-dive done with their CTO".
6. Add an activity log on Initech ERP Replacement: "Stakeholder mapping session done".
7. Log on Vandelay Imports — Year 1: "Contract signed, transferring to onboarding".

---

### 4.6 — `add_opportunity_line_item`

Expected: agent calls `add_opportunity_line_item` with `opportunity_id`, EITHER `pricebook_entry_id` OR `product_name` (not both), plus `quantity` and `unit_price`.

1. Add product "GenWatt Diesel 200kW" to the Acme Big Deal — quantity 2, unit price 50000.
2. On the Globex Expansion opportunity, add 5 units of "Pro Subscription" at 1200 each.
3. Put product "Installation Services" on Burlington Logistics POC — quantity 1, unit price 15000.
4. Add the SKU "Premium Support — Annual" to Edge Communications - SLA Tier 2, quantity 1, price 25000.
5. Add 10 licences of "Compression Engine Enterprise" to Pied Piper POC at 8000 per licence.
6. Put product "Implementation Package — Tier 3" on Initech ERP Replacement, quantity 1, unit price 80000.
7. Add the line item with PricebookEntry Id 01u5g00000ABCDE to opportunity 006A0000005Tx9X — qty 3, unit price 22500.

---

### 4.7 — `fetch_opportunity_recent_changes`

Expected: agent calls `fetch_opportunity_recent_changes` with `opportunity_id`, optionally `days`.

1. What changed on the Acme Big Deal opportunity in the last 7 days?
2. Show me the audit history for "Globex Expansion" — last 30 days.
3. Who edited the Burlington Logistics POC deal recently?
4. Pull the field history on opportunity 006A0000005Tx9X for the past 90 days.
5. What recent changes are there on the Edge Communications - SLA Tier 2 opportunity?
6. Did anyone change the close date on the Pied Piper POC in the last two weeks?
7. Audit trail for "Renewal Q3" please — last 60 days.

---

## 5. CASE SKILLS (5)

### 5.1 — `fuzzy_search_cases`

Expected: agent calls `fuzzy_search_cases` with `search_term` (CaseNumber or Subject keyword).

1. Find case 00001234.
2. Search cases for the word "login".
3. List any cases with "crash" in the subject.
4. Pull case number 00005678.
5. Look up cases about "password reset".
6. Find cases related to "data export".
7. Show me cases where the subject mentions "billing".

---

### 5.2 — `fetch_case_details`

Expected: agent calls `fetch_case_details` with either a 500-prefixed Id OR a CaseNumber.

1. Show me the full details on case 00001234.
2. Open case 5005g00000ABC123.
3. What's the priority, status and account on case 00005678?
4. Give me everything on the "Login fails after SSO upgrade" case.
5. Pull the description and contact for case number 00009999.
6. What's the closure status and reason on case 5005g00000XYZ987?
7. Fetch full case details for case 00012345.

---

### 5.3 — `create_case`

Expected: agent calls `create_case` with `fields` containing at least `Subject`.

1. Open a new case: Subject "Login failing after SSO change", priority High, on the Acme account.
2. Create a case for United Health — subject "Data export timeout", description "Exports >10k rows fail", origin Email.
3. Log a case: subject "Billing discrepancy on May invoice", priority Medium, contact John Smith.
4. Raise a P1 case for Edge Communications — subject "Production outage on prod-api", type Problem.
5. Open a case for Burlington Textiles: subject "Need help with bulk import", origin Phone, priority Low.
6. Create case — subject "Renewal contract not received", reason "Customer Feedback", on Genepoint.
7. Log a new case: Subject "Mobile app crash on Android 14", origin Web, priority High.

---

### 5.4 — `update_case_fields`

Expected: agent confirms, then calls `update_case_fields` with `case_id` + `fields`.

1. Update case 00001234 — set priority to Critical.
2. Change the status of case 5005g00000ABC123 to "Working".
3. Update the subject on case 00005678 to "Login fails after SAML upgrade — escalated".
4. Set the type on case 00009999 to "Problem" and origin to Email.
5. Update the description on case number 00012345 — "Customer confirmed issue resolved on their side, awaiting our root-cause write-up".
6. Change the owner of case 5005g00000XYZ987 to user 0055g00000QWERT.
7. Update case 00001234 — set reason to "Instructions not clear" and status to "Awaiting Customer".

---

### 5.5 — `close_case`

Expected: agent calls `close_case` with `case_id`, optionally `reason` + `comments`. Refuses if case already closed.

1. Close case 00001234 — reason "User error", comment "Walked customer through the correct flow".
2. Mark case 5005g00000ABC123 as resolved.
3. Close case number 00005678 — reason "Other", comment "Duplicate of case 00005670".
4. Resolve case 00009999, reason "Instructions not clear", comment "Updated KB article".
5. Please close case 00012345 — fix shipped in release 24.5.
6. Mark case 5005g00000XYZ987 closed, reason "User error", no comment needed.
7. Close case 00001111 — comment "Customer confirmed working as expected".

---

## 6. ACTIVITY SKILLS (4)

### 6.1 — `create_task`

Expected: agent calls `create_task` with `fields` (must include `Subject`). Uses `WhatId` for non-people records, `WhoId` for Contacts/Leads.

1. Create a task "Send SOW to legal" on the Acme Big Deal opportunity, due tomorrow, priority High.
2. Add a to-do for me: "Follow up with John Smith re. pricing" — link it to John Smith's contact, due May 15.
3. Make a task "Prepare QBR deck" on the Acme account, status In Progress, due end of next week.
4. Create a task on case 00001234 — subject "Get logs from customer", priority High.
5. Add a task tied to the Jane Doe lead: "Send intro email", due today.
6. New task: "Review redlined MSA", on Edge Communications - SLA Tier 2, due 2026-05-20, priority High.
7. Create a follow-up task on contact Priya Khan — subject "Send security whitepaper", description "Per her ask on the demo call".

---

### 6.2 — `create_event`

Expected: agent calls `create_event` with `fields` containing `Subject` AND `StartDateTime`. Provide either `EndDateTime` or `DurationInMinutes` (defaults to 30 if neither).

1. Schedule a meeting "Acme — Pricing review" on May 15 at 2pm IST, duration 60 minutes, on the Acme Big Deal opportunity.
2. Set up a demo with Priya Khan — May 20, 10am, 45 minutes, link it to her contact.
3. Book a kickoff call: subject "Burlington Logistics — Project kickoff", start tomorrow 4pm, end 5pm, on the Burlington Logistics POC opportunity.
4. Create an event "Quarterly Business Review with United Health" on June 3rd, 11am to 12:30pm, at "United Health HQ".
5. Schedule a 30-min discovery call with Carlos Mendez next Wednesday at 9am.
6. Block 2 hours on May 18 starting 1pm for "Onsite at Edge Communications" — link to the Edge Communications account.
7. Set up an all-day event "Annual customer summit" on June 10 — link to the GenePoint account.

---

### 6.3 — `fetch_my_open_tasks`

Expected: agent calls `fetch_my_open_tasks` (no args, or `limit`).

1. What's on my plate today?
2. Show me my open tasks.
3. List my to-dos.
4. Pull my open tasks — top 10.
5. What tasks do I have outstanding?
6. Give me everything I haven't completed.
7. Show me my next 50 open tasks please.

---

### 6.4 — `complete_task`

Expected: agent calls `complete_task` with `task_id`.

1. Mark that "Send SOW to legal" task as done.
2. Complete task 00T5g00000ABC123.
3. The "Follow up with John Smith re. pricing" task — mark it complete.
4. Close out the QBR deck preparation task.
5. Mark "Send intro email" as completed for the Jane Doe lead.
6. Finish task Id 00T5g00000XYZ987.
7. The redlined MSA review task is done — mark complete.

---

## 7. UTILITY / OTHER-OBJECT SKILLS (5)

These skills are **object-agnostic** — they work against Account, Contact, Lead, Opportunity, Case, AND any custom object you have. The samples below cover all of them so you can verify cross-object behaviour.

### 7.1 — `bulk_update_records`

Expected: agent shows a summary of the changes, asks for confirmation, then calls `bulk_update_records` with `object_api_name` + `records` array.

**Account samples**
1. Update the industry to "Technology" on Acme, Globex and Initech in one go.
2. Set type = "Customer" on these three accounts: 0015g00000A, 0015g00000B, 0015g00000C.

**Contact samples**
3. On contacts John Smith, Priya Khan and Elena Rodriguez — set department to "Strategic Accounts".

**Opportunity samples**
4. Push the close date to 2026-09-30 on every opportunity I'm about to send you: 006...A, 006...B, 006...C.
5. Set stage = "Closed Lost" and probability = 0 on opportunities 006...X, 006...Y, 006...Z.

**Case samples**
6. Mark cases 00001234, 00005678 and 00009999 as priority Low — bulk update.

**Custom-object sample**
7. On these three Project__c records — 0a25g000001, 0a25g000002, 0a25g000003 — set Status__c to "On Hold" and Owner__c to user 0055g00000QWERT.

> **Negative test:** "Actually let's not do this." → agent must abort the bulk update.

---

### 7.2 — `fetch_record_history`

Expected: agent calls `fetch_record_history` with `record_id`, `object_api_name`, optionally `days`.

1. What changed on the Acme account over the last 30 days?
2. Show me the audit trail for contact 0035g00000ABC123 — past 60 days.
3. Pull the field history on lead 00Q5g00000XYZ987.
4. What edits happened on case 5005g00000ABC123 in the last 14 days?
5. Audit history for the Project__c record 0a25g000001 — past 90 days.
6. Who changed fields on opportunity 006A0000005Tx9X recently?
7. Field history on Asset record 02i5g000001 — last 7 days.

---

### 7.3 — `fetch_user_info`

Expected: agent calls `fetch_user_info` with no parameters. Often used silently as a date anchor.

1. Who am I logged in as?
2. What's my profile and role?
3. What time zone am I on?
4. Tell me my user details.
5. What's today's date according to Salesforce?
6. Confirm my username and email.
7. Show me my locale and language settings.

---

### 7.4 — `run_internal_prompt`

Expected: agent calls `run_internal_prompt` with `prompt_request_id` (must be a real configured Id — never invented) + `record_id`.

> Replace `<PROMPT_REQUEST_ID>` below with an actual Prompt Request Id from your org (e.g. an "Account Overview" prompt, "Deal Overview" prompt, "Stakeholder Map" prompt, etc.).

1. Generate a deal overview for the Acme Big Deal opportunity using prompt `<PROMPT_REQUEST_ID>`.
2. Run the stakeholder map prompt against the United Health account.
3. Give me an executive summary of opportunity 006A0000005Tx9X — use the configured Deal Overview prompt.
4. Generate meeting prep notes for my 2pm with Priya Khan — run the contact-prep prompt on her record.
5. Run the renewal-risk analysis prompt against the Edge Communications account.
6. Build a case-resolution summary for case 00001234 using the configured prompt.
7. Generate the QBR narrative for the Burlington Textiles account.

> **Negative test:** "Generate a deal overview for Acme Big Deal." (no prompt_request_id given) → agent must ask for or look up the configured prompt id, never invent one.

---

### 7.5 — `fetch_picklist_values`

Expected: agent calls `fetch_picklist_values` with `object_api_name` + `field_api_name`. For dependent picklists, also `controller_value`. Often invoked **silently** before a `create_*` or `update_*_fields` skill when a user-supplied picklist value is uncertain.

**Single-level picklist samples**
1. What are the valid values for Account Industry?
2. List the Opportunity StageName options.
3. Show me all the Lead Status picklist values.
4. What case priorities are available?
5. List the Type values on Account.

**Dependent picklist samples**
6. Show me valid Sub-Industry values when Industry is "Technology" — on the Account object.
7. What Sub-Status values are valid when Case Status is "Working"?
8. For Opportunity, list the valid ForecastCategoryName values when StageName is "Negotiation/Review".

**Custom-object picklist sample**
9. List picklist values for the field Region__c on the Project__c custom object.

> **Implicit / silent test:** "Update the Acme account industry to Tek." → agent should silently call `fetch_picklist_values` for `Account.Industry`, see "Tek" is invalid, and ask the user "Did you mean 'Technology'?" before invoking `update_account_fields`.

---

## 8. END-TO-END / MULTI-SKILL SCENARIOS

These flows exercise **multiple skills back-to-back** in a single conversation. They are the most realistic regression tests — verify the agent maintains context across turns and dispatches each skill correctly.

### 8.1 — Full Account Lifecycle

1. "Find the Acme account." → `fuzzy_search_accounts`
2. "Show me the full details." → `fetch_account_details`
3. "What contacts and open opportunities do they have?" → `fetch_account_related_lists`
4. "Update the industry to Manufacturing." → `update_account_fields` (after confirmation)
5. "What changed on this account in the last 30 days?" → `fetch_record_history`

### 8.2 — Lead-to-Opportunity Flow

1. "Find the Jane Doe lead." → `fuzzy_search_leads`
2. "Open the lead." → `fetch_lead_details`
3. "Update her status to Working - Contacted." → `update_lead_fields`
4. "Log that I had a discovery call with her today." → `log_lead_activity`
5. "Convert the lead — opportunity name 'Acme — Initial Deal'." → `convert_lead`

### 8.3 — Opportunity Close-Out

1. "Search opportunities for 'Acme Big Deal'." → `fuzzy_search_opportunities`
2. "Show me the full details." → `fetch_opportunity_details`
3. "What stages are valid?" → `fetch_picklist_values` (silent or explicit)
4. "Move it to Closed Won, amount 250000, close date today." → `update_opportunity_fields`
5. "Add product 'Installation Services' — qty 1, unit price 15000." → `add_opportunity_line_item`
6. "Log a note: 'Contract countersigned, handed off to onboarding'." → `log_opportunity_activity`
7. "Generate the deal overview narrative using prompt `<PROMPT_REQUEST_ID>`." → `run_internal_prompt`

### 8.4 — Case Triage and Close

1. "Find case 00001234." → `fuzzy_search_cases`
2. "Show me the full case." → `fetch_case_details`
3. "Set the priority to Critical and status to Working." → `update_case_fields`
4. "Create a follow-up task — 'Get logs from customer', due tomorrow." → `create_task`
5. "Close the case — reason User error, comment 'Walked customer through the correct flow'." → `close_case`

### 8.5 — Daily Productivity Loop

1. "Who am I logged in as?" → `fetch_user_info`
2. "What's on my plate today?" → `fetch_my_open_tasks`
3. "Mark the QBR deck task as done." → `complete_task`
4. "Schedule a 30-minute call with Priya Khan tomorrow at 10am." → `create_event`
5. "Create a task 'Send security whitepaper' on Priya's contact, due Friday." → `create_task`

### 8.6 — Bulk Cleanup

1. "Find any account with 'Test' in the name." → `fuzzy_search_accounts`
2. "Show me what changed on each of these in the last 90 days." → `fetch_record_history` (multi-record loop)
3. "Set type = 'Other' and rating = 'Cold' on all three." → `bulk_update_records`

---

## Test-Run Checklist

For each sample you run, capture:

- [ ] **Skill dispatched** matches the **Expected** skill name above
- [ ] **Arguments** the LLM produced are correct (Ids resolved from names; dates in `yyyy-MM-dd`; picklists are exact API values)
- [ ] **Confirmation** is requested for destructive / write skills (`update_*`, `convert_lead`, `close_case`, `bulk_update_records`)
- [ ] **Response narrative** is grounded in actual record data (no hallucinated Ids, names or values)
- [ ] **Error handling**: a "no" / "cancel" mid-flow aborts cleanly without partial DML

> When a sample fails, log it against the skill name and the sample number above (e.g. "1.4 — sample 6 failed: agent did not confirm before update").

---

**Document version:** 1.0.0 — 2026-05-08
