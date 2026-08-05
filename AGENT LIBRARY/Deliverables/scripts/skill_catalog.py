# -*- coding: utf-8 -*-
"""Catalog section headers and professional display names for KB UI."""

from __future__ import annotations

# (section_id, section header shown in catalog)
CATALOG_SECTIONS: list[tuple[str, str]] = [
    ("accounts", "Accounts"),
    ("contacts", "Contacts"),
    ("leads", "Leads"),
    ("opportunities", "Opportunities"),
    ("cases", "Cases"),
    ("activities", "Activities & Scheduling"),
    ("products", "Products & Price Books"),
    ("campaigns", "Campaigns"),
    ("quotes", "Quotes"),
    ("cpq", "CPQ"),
    ("contracts", "Contracts"),
    ("orders", "Orders & Subscriptions"),
    ("renewals", "Renewals"),
    ("service", "Service Cloud"),
    ("field_service", "Field Service"),
    ("partners", "Partner Management"),
    ("industry", "Industry Clouds"),
    ("platform", "Platform & Insights"),
]

SECTION_ORDER = {sid: idx for idx, (sid, _) in enumerate(CATALOG_SECTIONS)}
SECTION_TITLE = {sid: title for sid, title in CATALOG_SECTIONS}

SKILL_SECTION: dict[str, str] = {
    # Accounts
    "fuzzy_search_accounts": "accounts",
    "fetch_account_details": "accounts",
    "create_account": "accounts",
    "update_account_fields": "accounts",
    "fetch_account_related_lists": "accounts",
    "fetch_account_plan": "accounts",
    # Contacts
    "fuzzy_search_contacts": "contacts",
    "fetch_contact_details": "contacts",
    "create_contact": "contacts",
    "update_contact_fields": "contacts",
    "fetch_contact_engagement_history": "contacts",
    # Leads
    "fuzzy_search_leads": "leads",
    "fetch_lead_details": "leads",
    "create_lead": "leads",
    "update_lead_fields": "leads",
    "convert_lead": "leads",
    # Opportunities
    "fetch_opportunity_details": "opportunities",
    "create_opportunity": "opportunities",
    "update_opportunity_fields": "opportunities",
    "add_opportunity_line_item": "opportunities",
    "update_opportunity_line_item": "opportunities",
    "fuzzy_search_opportunities": "opportunities",
    "fetch_opportunity_contact_roles": "opportunities",
    "add_opportunity_contact_role": "opportunities",
    "update_opportunity_contact_role": "opportunities",
    "fetch_opportunity_team": "opportunities",
    "add_opportunity_team_member": "opportunities",
    "fetch_my_open_opportunities": "opportunities",
    "fetch_stale_opportunities": "opportunities",
    "clone_opportunity": "opportunities",
    "fetch_opportunity_partners": "opportunities",
    "add_opportunity_partner": "opportunities",
    # Cases
    "fetch_case_details": "cases",
    "create_case": "cases",
    "update_case_fields": "cases",
    "close_case": "cases",
    "fuzzy_search_cases": "cases",
    "add_case_comment": "cases",
    "fetch_case_team": "cases",
    "add_case_team_member": "cases",
    "link_knowledge_article_to_case": "cases",
    # Activities
    "log_activity": "activities",
    "create_task": "activities",
    "update_task": "activities",
    "create_event": "activities",
    "update_event": "activities",
    "fetch_my_open_tasks": "activities",
    "complete_task": "activities",
    # Products
    "fuzzy_search_products": "products",
    "fetch_product_details": "products",
    "fetch_pricebook_entries": "products",
    # Campaigns
    "fuzzy_search_campaigns": "campaigns",
    "fetch_campaign_details": "campaigns",
    "create_campaign": "campaigns",
    "update_campaign_fields": "campaigns",
    "fetch_campaign_members": "campaigns",
    "add_campaign_member": "campaigns",
    "update_campaign_member_status": "campaigns",
    "remove_campaign_member": "campaigns",
    # Quotes
    "fuzzy_search_quotes": "quotes",
    "fetch_quote_details": "quotes",
    "create_quote": "quotes",
    "update_quote_fields": "quotes",
    "add_quote_line_item": "quotes",
    "update_quote_line_item": "quotes",
    # CPQ
    "fetch_cpq_quote_details": "cpq",
    "create_cpq_quote": "cpq",
    "update_cpq_quote_fields": "cpq",
    "add_cpq_quote_line": "cpq",
    "update_cpq_quote_line": "cpq",
    "calculate_cpq_quote": "cpq",
    # Contracts
    "fetch_contract_details": "contracts",
    "create_contract": "contracts",
    "update_contract_fields": "contracts",
    # Orders
    "fetch_order_details": "orders",
    "create_order": "orders",
    "update_order_fields": "orders",
    "add_order_item": "orders",
    "update_order_item": "orders",
    "fetch_subscription_details": "orders",
    "update_subscription_fields": "orders",
    # Renewals
    "fetch_renewal_opportunities": "renewals",
    "fetch_upcoming_renewals": "renewals",
    # Service Cloud
    "search_knowledge_articles": "service",
    "fetch_knowledge_article": "service",
    "fetch_case_milestones": "service",
    "fetch_case_entitlements": "service",
    "assign_to_queue": "service",
    "fetch_queue_cases": "service",
    "fuzzy_search_assets": "service",
    "fetch_asset_details": "service",
    "update_asset_fields": "service",
    # Field Service
    "fetch_work_order_details": "field_service",
    "create_work_order": "field_service",
    "update_work_order_fields": "field_service",
    "fetch_service_appointment": "field_service",
    "schedule_service_appointment": "field_service",
    "update_service_appointment": "field_service",
    "fetch_service_resource_availability": "field_service",
    # Partners
    "fuzzy_search_partners": "partners",
    "fetch_partner_account": "partners",
    # Industry
    "fetch_financial_account": "industry",
    "update_financial_account_fields": "industry",
    "fetch_care_plan": "industry",
    "create_care_task": "industry",
    "update_care_plan_fields": "industry",
    # Platform
    "fetch_session_context": "platform",
    "fetch_picklist_values": "platform",
    "run_internal_prompt": "platform",
    "transfer_record_owner": "platform",
    "fetch_record_approvals": "platform",
}

SKILL_DISPLAY_NAMES: dict[str, str] = {
    # Accounts
    "fuzzy_search_accounts": "Search Accounts",
    "fetch_account_details": "Get Account Details",
    "create_account": "Create Account",
    "update_account_fields": "Update Account",
    "fetch_account_related_lists": "Get Account Related Records",
    "fetch_account_plan": "Get Account Plan",
    # Contacts
    "fuzzy_search_contacts": "Search Contacts",
    "fetch_contact_details": "Get Contact Details",
    "create_contact": "Create Contact",
    "update_contact_fields": "Update Contact",
    "fetch_contact_engagement_history": "Get Contact Engagement History",
    # Leads
    "fuzzy_search_leads": "Search Leads",
    "fetch_lead_details": "Get Lead Details",
    "create_lead": "Create Lead",
    "update_lead_fields": "Update Lead",
    "convert_lead": "Convert Lead",
    # Opportunities
    "fetch_opportunity_details": "Get Opportunity Details",
    "create_opportunity": "Create Opportunity",
    "update_opportunity_fields": "Update Opportunity",
    "add_opportunity_line_item": "Add Opportunity Product",
    "update_opportunity_line_item": "Update Opportunity Product",
    "fuzzy_search_opportunities": "Search Opportunities",
    "fetch_opportunity_contact_roles": "Get Opportunity Contact Roles",
    "add_opportunity_contact_role": "Add Opportunity Contact Role",
    "update_opportunity_contact_role": "Update Opportunity Contact Role",
    "fetch_opportunity_team": "Get Opportunity Team",
    "add_opportunity_team_member": "Add Opportunity Team Member",
    "fetch_my_open_opportunities": "Get My Open Opportunities",
    "fetch_stale_opportunities": "Get Stale Opportunities",
    "clone_opportunity": "Clone Opportunity",
    "fetch_opportunity_partners": "Get Opportunity Partners",
    "add_opportunity_partner": "Add Opportunity Partner",
    # Cases
    "fetch_case_details": "Get Case Details",
    "create_case": "Create Case",
    "update_case_fields": "Update Case",
    "close_case": "Close Case",
    "fuzzy_search_cases": "Search Cases",
    "add_case_comment": "Add Case Comment",
    "fetch_case_team": "Get Case Team",
    "add_case_team_member": "Add Case Team Member",
    "link_knowledge_article_to_case": "Link Knowledge Article to Case",
    # Activities
    "log_activity": "Log Activity",
    "create_task": "Create Task",
    "update_task": "Update Task",
    "create_event": "Create Event",
    "update_event": "Update Event",
    "fetch_my_open_tasks": "Get My Open Tasks",
    "complete_task": "Complete Task",
    # Products
    "fuzzy_search_products": "Search Products",
    "fetch_product_details": "Get Product Details",
    "fetch_pricebook_entries": "Get Price Book Entries",
    # Campaigns
    "fuzzy_search_campaigns": "Search Campaigns",
    "fetch_campaign_details": "Get Campaign Details",
    "create_campaign": "Create Campaign",
    "update_campaign_fields": "Update Campaign",
    "fetch_campaign_members": "Get Campaign Members",
    "add_campaign_member": "Add Campaign Member",
    "update_campaign_member_status": "Update Campaign Member Status",
    "remove_campaign_member": "Remove Campaign Member",
    # Quotes
    "fuzzy_search_quotes": "Search Quotes",
    "fetch_quote_details": "Get Quote Details",
    "create_quote": "Create Quote",
    "update_quote_fields": "Update Quote",
    "add_quote_line_item": "Add Quote Line Item",
    "update_quote_line_item": "Update Quote Line Item",
    # CPQ
    "fetch_cpq_quote_details": "Get CPQ Quote Details",
    "create_cpq_quote": "Create CPQ Quote",
    "update_cpq_quote_fields": "Update CPQ Quote",
    "add_cpq_quote_line": "Add CPQ Quote Line",
    "update_cpq_quote_line": "Update CPQ Quote Line",
    "calculate_cpq_quote": "Calculate CPQ Quote",
    # Contracts
    "fetch_contract_details": "Get Contract Details",
    "create_contract": "Create Contract",
    "update_contract_fields": "Update Contract",
    # Orders
    "fetch_order_details": "Get Order Details",
    "create_order": "Create Order",
    "update_order_fields": "Update Order",
    "add_order_item": "Add Order Product",
    "update_order_item": "Update Order Product",
    "fetch_subscription_details": "Get Subscription Details",
    "update_subscription_fields": "Update Subscription",
    # Renewals
    "fetch_renewal_opportunities": "Get Renewal Opportunities",
    "fetch_upcoming_renewals": "Get Upcoming Renewals",
    # Service Cloud
    "search_knowledge_articles": "Search Knowledge Articles",
    "fetch_knowledge_article": "Get Knowledge Article",
    "fetch_case_milestones": "Get Case Milestones",
    "fetch_case_entitlements": "Get Case Entitlements",
    "assign_to_queue": "Assign Record to Queue",
    "fetch_queue_cases": "Get Queue Cases",
    "fuzzy_search_assets": "Search Assets",
    "fetch_asset_details": "Get Asset Details",
    "update_asset_fields": "Update Asset",
    # Field Service
    "fetch_work_order_details": "Get Work Order Details",
    "create_work_order": "Create Work Order",
    "update_work_order_fields": "Update Work Order",
    "fetch_service_appointment": "Get Service Appointment",
    "schedule_service_appointment": "Schedule Service Appointment",
    "update_service_appointment": "Update Service Appointment",
    "fetch_service_resource_availability": "Get Resource Availability",
    # Partners
    "fuzzy_search_partners": "Search Partner Accounts",
    "fetch_partner_account": "Get Partner Account Details",
    # Industry
    "fetch_financial_account": "Get Financial Account",
    "update_financial_account_fields": "Update Financial Account",
    "fetch_care_plan": "Get Care Plan",
    "create_care_task": "Create Care Task",
    "update_care_plan_fields": "Update Care Plan",
    # Platform
    "fetch_session_context": "Get Session Context",
    "fetch_picklist_values": "Get Picklist Values",
    "run_internal_prompt": "Run a GPTfy prompt",
    "transfer_record_owner": "Transfer Record Owner",
    "fetch_record_approvals": "Get Record Approvals",
}

# Explicit row order within a section (featured / priority skills first).
SECTION_SKILL_ORDER: dict[str, list[str]] = {
    "platform": [
        "run_internal_prompt",
        "fetch_session_context",
        "fetch_picklist_values",
        "transfer_record_owner",
        "fetch_record_approvals",
    ],
}

# GPTfy Recommended band (order preserved). High-value starters — good to have on every agent.
FEATURED_SKILL_ORDER: list[str] = [
    "run_internal_prompt",       # Core — insights / 360 / drafts
    "fuzzy_search_accounts",     # Find companies by spoken/partial name
    "fuzzy_search_contacts",     # Find people by spoken/partial name
    "log_activity",              # Capture the conversation outcome in CRM
]
FEATURED_SKILLS = frozenset(FEATURED_SKILL_ORDER)

# Short use-tag shown on Recommended cards
FEATURED_SKILL_TAGS: dict[str, str] = {
    "run_internal_prompt": "Insights",
    "fuzzy_search_accounts": "Find company",
    "fuzzy_search_contacts": "Find person",
    "log_activity": "Capture",
}


def sort_skills_in_section(section_id: str, items: list[dict]) -> list[dict]:
    order = SECTION_SKILL_ORDER.get(section_id)
    if not order:
        return sorted(items, key=lambda x: x["display_name"].lower())
    rank = {name: i for i, name in enumerate(order)}
    return sorted(
        items,
        key=lambda x: (rank.get(x["name"], 999), x["display_name"].lower()),
    )


def catalog_section_for(skill_name: str) -> str:
    return SECTION_TITLE.get(SKILL_SECTION.get(skill_name, ""), "Other")


def display_name_for(skill_name: str) -> str:
    return SKILL_DISPLAY_NAMES.get(
        skill_name,
        skill_name.replace("_", " ").title(),
    )


assert len(SKILL_SECTION) == 111, f"Expected 111 section mappings, got {len(SKILL_SECTION)}"
assert len(SKILL_DISPLAY_NAMES) == 111, f"Expected 111 display names, got {len(SKILL_DISPLAY_NAMES)}"
assert set(SKILL_SECTION) == set(SKILL_DISPLAY_NAMES)
