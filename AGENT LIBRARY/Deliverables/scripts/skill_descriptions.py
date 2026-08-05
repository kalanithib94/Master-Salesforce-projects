# -*- coding: utf-8 -*-
"""Short user-facing descriptions for all 111 GPTfy skills (ccai__Description__c, max 255 chars)."""

SKILL_DESCRIPTIONS: dict[str, str] = {
    # Wave 1 — Core CRM
    "fuzzy_search_accounts": "Locate a company when the user gives a partial or spoken name.",
    "fetch_account_details": "Load key account fields plus related contact/opportunity/case counts.",
    "create_account": "Open a new company record after the user confirms the name and key fields.",
    "update_account_fields": "Change industry, address, phone, or other account data the user confirmed.",
    "fetch_account_related_lists": "See contacts, opportunities, cases, and other children on the account.",
    "fuzzy_search_contacts": "Find a person by name or email when the Salesforce Id is unknown.",
    "fetch_contact_details": "Load contact profile, title, and account link for outreach or updates.",
    "create_contact": "Add a person to Salesforce, usually under an existing account.",
    "update_contact_fields": "Correct email, phone, title, or other contact details after confirmation.",
    "fuzzy_search_leads": "Find a prospect by name or company before qualifying or converting.",
    "fetch_lead_details": "Load lead status, source, and company context for follow-up.",
    "create_lead": "Capture a new prospect when there is no matching account yet.",
    "update_lead_fields": "Update lead status, score, or contact info during qualification.",
    "convert_lead": "Turn a qualified lead into account, contact, and optional opportunity.",
    "fetch_opportunity_details": "Load stage, amount, close date, and deal context for review.",
    "create_opportunity": "Start a new deal with account, stage, and close date confirmed.",
    "update_opportunity_fields": "Move stage, change amount or close date, or edit other deal fields.",
    "add_opportunity_line_item": "Attach a priced product from the price book to the deal.",
    "update_opportunity_line_item": "Adjust quantity, price, or discount on an existing product line.",
    "fetch_case_details": "Load case status, priority, and customer context for support work.",
    "create_case": "Open a support ticket linked to the right account or contact.",
    "update_case_fields": "Change status, priority, owner, or other case fields mid-work.",
    "close_case": "Resolve and close a ticket after the customer issue is handled.",
    "log_activity": "Record a completed call, email, or note against any CRM record.",
    "create_task": "Schedule a follow-up to-do with due date and owner.",
    "update_task": "Reschedule, reassign, or edit an existing to-do.",
    "create_event": "Book a meeting on the calendar linked to a person or record.",
    "update_event": "Reschedule or edit meeting time, location, or notes.",
    "fetch_my_open_tasks": "Show the current user's incomplete to-dos for the day or week.",
    "complete_task": "Mark a follow-up done after the work is finished.",
    "fetch_session_context": "See which record and related people the chat is on, so the agent can act without asking for Ids. Use before updates, summaries, logging activity, or drafting follow-ups.",
    "fetch_picklist_values": "List valid choices for a field before setting a picklist value.",
    "run_internal_prompt": "Generate a 360, summary, meeting prep, or draft from record data.",
    # Wave 2
    "fuzzy_search_opportunities": "Find a deal by name when the user cannot provide the Id.",
    "fuzzy_search_cases": "Find a ticket by subject or case number from chat.",
    "add_case_comment": "Post an internal or public update on the case thread.",
    "fuzzy_search_products": "Find a SKU or product name before adding lines to a deal or quote.",
    "fetch_product_details": "Load product code, family, and description for configuration.",
    "fetch_pricebook_entries": "Show list prices for products in a chosen or standard price book.",
    "transfer_record_owner": "Reassign ownership of a record to another user.",
    # Wave 3 — Campaign
    "fuzzy_search_campaigns": "Find a marketing campaign by name for member or status work.",
    "fetch_campaign_details": "Load campaign dates, type, status, and response counts.",
    "create_campaign": "Set up a new marketing campaign with name and schedule.",
    "update_campaign_fields": "Change campaign status, dates, or type after launch planning.",
    "fetch_campaign_members": "List who is already on the campaign and their status.",
    "add_campaign_member": "Enroll a lead or contact into the campaign.",
    "update_campaign_member_status": "Mark someone as Sent, Responded, or another member status.",
    # Wave 4 — Quote
    "fuzzy_search_quotes": "Find a quote by name when the quote number is unknown.",
    "fetch_quote_details": "Load quote header, status, and totals for review.",
    "create_quote": "Create a standard quote for an opportunity.",
    "update_quote_fields": "Change quote status, expiration, or header fields.",
    "add_quote_line_item": "Add a priced product line to the quote.",
    "update_quote_line_item": "Change quantity or price on an existing quote line.",
    # Wave 5 — Deal team & contract
    "fetch_opportunity_contact_roles": "See who on the buying committee is linked to the deal.",
    "add_opportunity_contact_role": "Link a contact to the deal with a role such as Decision Maker.",
    "update_opportunity_contact_role": "Change role or primary flag for someone on the deal.",
    "fetch_opportunity_team": "List internal sellers and specialists on the deal team.",
    "add_opportunity_team_member": "Add a colleague to the deal with a team role.",
    "fetch_my_open_opportunities": "Pipeline view of the current user's open deals.",
    "fetch_stale_opportunities": "Surface deals with little recent activity that may need attention.",
    "clone_opportunity": "Duplicate a deal to start a related or renewal opportunity faster.",
    "fetch_contract_details": "Load contract status, term dates, and account linkage.",
    "create_contract": "Create a contract record under the customer account.",
    "update_contract_fields": "Update contract status, dates, or terms after review.",
    # Wave 6 — Service
    "fetch_case_team": "See who is collaborating on the support case.",
    "add_case_team_member": "Bring another agent or specialist onto the case team.",
    "search_knowledge_articles": "Find KB articles that may answer the customer's question.",
    "fetch_knowledge_article": "Open the full article body for use in a reply.",
    "link_knowledge_article_to_case": "Attach a helpful article to the case for audit and deflection.",
    "fetch_case_milestones": "Check SLA milestone progress and breach risk on the case.",
    "fetch_case_entitlements": "See support coverage and entitlement levels for the customer.",
    "assign_to_queue": "Route a record into a work queue for the next available agent.",
    "fetch_queue_cases": "List cases waiting in a specific support queue.",
    # Wave 7 — Asset & FSL
    "fuzzy_search_assets": "Find installed equipment by name or serial number.",
    "fetch_asset_details": "Load asset status, account, and product information.",
    "update_asset_fields": "Update asset status, location, or warranty-related fields.",
    "fetch_work_order_details": "Load field service work order status and related customer data.",
    "create_work_order": "Open a work order for on-site or remote service.",
    "update_work_order_fields": "Change work order status, priority, or schedule fields.",
    "fetch_service_appointment": "Load appointment time window and assigned resource.",
    "schedule_service_appointment": "Set or change when a technician visit is booked.",
    "update_service_appointment": "Edit appointment status, time, or assignment details.",
    "fetch_service_resource_availability": "Check when a technician or resource is free to schedule.",
    # Wave 8 — CPQ
    "fetch_cpq_quote_details": "Load Salesforce CPQ quote header and configuration context.",
    "create_cpq_quote": "Start a CPQ quote from an opportunity for guided selling.",
    "update_cpq_quote_fields": "Edit CPQ quote status or header fields before calculation.",
    "add_cpq_quote_line": "Add a CPQ product or bundle line to the quote.",
    "update_cpq_quote_line": "Change quantity, options, or pricing on a CPQ line.",
    "calculate_cpq_quote": "Run CPQ pricing so totals and discounts refresh.",
    # Wave 9 — Orders
    "fetch_order_details": "Load order status, account, and totals after win or fulfillment.",
    "create_order": "Create an order from account or opportunity context.",
    "update_order_fields": "Update order status or header fields during fulfillment.",
    "add_order_item": "Add a product line to the order.",
    "update_order_item": "Adjust quantity or price on an order line.",
    "fetch_subscription_details": "Load subscription term, quantity, and billing status.",
    "update_subscription_fields": "Change subscription quantity, term, or status fields.",
    # Wave 10 — Partner
    "fuzzy_search_partners": "Find partner accounts by name for deal registration or teaming.",
    "fetch_partner_account": "Load partner account profile and relationship details.",
    "add_opportunity_partner": "Associate a partner account with a deal and role.",
    "fetch_opportunity_partners": "List partners already tied to the opportunity.",
    # Wave 11 — Industry
    "fetch_financial_account": "Load FSC financial account balances and ownership when licensed.",
    "update_financial_account_fields": "Update financial account status or attributes in FSC orgs.",
    "fetch_care_plan": "Load a Health Cloud care plan and related goals when available.",
    # Wave 12 — Platform
    "fetch_record_approvals": "See pending approval requests and submitters on a record.",
    "fetch_renewal_opportunities": "List open renewal-type deals for pipeline or CSM review.",
    "remove_campaign_member": "Take a lead or contact off a campaign membership.",
    "create_care_task": "Add a care-plan task for clinical or care-team follow-up.",
    "update_care_plan_fields": "Update care plan status or dates in Health Cloud orgs.",
    # Wave 13
    "fetch_upcoming_renewals": "Show renewals closing within the next N days for outreach planning.",
    "fetch_account_plan": "Load strategic plan and objectives for the account when the object exists.",
    "fetch_contact_engagement_history": "Timeline of recent tasks, meetings, and emails with the contact.",
}


def apex_escape(text: str) -> str:
    return text.replace("\\", "\\\\").replace("'", "\\'")


assert len(SKILL_DESCRIPTIONS) == 111, f"Expected 111 descriptions, got {len(SKILL_DESCRIPTIONS)}"
for name, desc in SKILL_DESCRIPTIONS.items():
    if len(desc) > 255:
        raise ValueError(f"{name}: description exceeds 255 chars ({len(desc)})")
