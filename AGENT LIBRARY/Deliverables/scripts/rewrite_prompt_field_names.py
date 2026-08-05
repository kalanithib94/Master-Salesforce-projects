# -*- coding: utf-8 -*-
"""
Rewrite Part*.apex Prompt Command keys to org-style names:
  - Primary record on the skill's object → Id
  - Relationship fields → Salesforce API names (AccountId, OwnerId, …)
  - Non-field helpers → camelCase (searchTerm)

Run from Deliverables:
  python scripts/rewrite_prompt_field_names.py
"""
from __future__ import annotations

import re
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parent

CLASS_PRIMARY: dict[str, str] = {
    "AccountAgenticSkillsHandler": "Account",
    "ContactAgenticSkillsHandler": "Contact",
    "LeadAgenticSkillsHandler": "Lead",
    "OpportunityAgenticSkillsHandler": "Opportunity",
    "CaseAgenticSkillsHandler": "Case",
    "ActivityAgenticSkillsHandler": "Activity",  # Task/Event mixed
    "ProductAgenticSkillsHandler": "Product2",
    "CampaignAgenticSkillsHandler": "Campaign",
    "QuoteAgenticSkillsHandler": "Quote",
    "CpqAgenticSkillsHandler": "SBQQ__Quote__c",
    "ContractAgenticSkillsHandler": "Contract",
    "OrderAgenticSkillsHandler": "Order",
    "ServiceAgenticSkillsHandler": "Case",
    "FieldServiceAgenticSkillsHandler": "WorkOrder",
    "PartnerAgenticSkillsHandler": "Account",
    "IndustryAgenticSkillsHandler": "Account",
    "UtilityAgenticSkillsHandler": "Utility",
}

# When skill primary is this object, this snake key means Id (not the relationship)
PRIMARY_SNAKE: dict[str, str] = {
    "Account": "account_id",
    "Contact": "contact_id",
    "Lead": "lead_id",
    "Opportunity": "opportunity_id",
    "Case": "case_id",
    "Campaign": "campaign_id",
    "Product2": "product_id",
    "Quote": "quote_id",
    "Contract": "contract_id",
    "Order": "order_id",
    "WorkOrder": "work_order_id",
    "SBQQ__Quote__c": "cpq_quote_id",
}

# Always map to Salesforce relationship / field API names (after primary rewrite)
RELATIONSHIP: list[tuple[str, str]] = [
    # order matters: longest first
    ("partner_account_id", "AccountId"),
    ("financial_account_id", "Id"),  # treated as primary of FSC FA when alone
    ("service_appointment_id", "Id"),
    ("service_resource_id", "ServiceResourceId"),
    ("pricebook_entry_id", "PricebookEntryId"),
    ("opportunity_line_item_id", "Id"),
    ("campaign_member_id", "Id"),
    ("contact_role_id", "Id"),
    ("order_item_id", "Id"),
    ("care_plan_id", "Id"),
    ("subscription_id", "Id"),
    ("work_order_id", "Id"),
    ("cpq_quote_id", "Id"),
    ("article_id", "KnowledgeArticleId"),
    ("line_item_id", "Id"),
    ("line_id", "Id"),
    ("asset_id", "Id"),
    ("queue_id", "OwnerId"),  # queue as owner
    ("new_owner_id", "OwnerId"),
    ("owner_id", "OwnerId"),
    ("user_id", "UserId"),
    ("account_id", "AccountId"),
    ("contact_id", "ContactId"),
    ("opportunity_id", "OpportunityId"),
    ("lead_id", "LeadId"),
    ("case_id", "CaseId"),
    ("campaign_id", "CampaignId"),
    ("product_id", "Product2Id"),
    ("quote_id", "QuoteId"),
    ("contract_id", "ContractId"),
    ("order_id", "OrderId"),
    ("task_id", "Id"),
    ("event_id", "Id"),
    ("record_id", "Id"),
    ("pricebook_id", "Pricebook2Id"),
]

# Non-relationship helper params (not SF fields)
HELPERS: list[tuple[str, str]] = [
    ("search_term", "searchTerm"),
    ("activity_subject", "Subject"),
    ("activity_description", "Description"),
    ("prompt_request_id", "promptRequestId"),
    ("object_api_name", "objectApiName"),
    ("field_api_name", "fieldApiName"),
    ("controller_value", "controllerValue"),
    ("comment_body", "CommentBody"),
    ("is_published", "IsPublished"),
    ("team_role", "TeamRole"),
    ("team_role_id", "TeamRoleId"),
    ("unit_price", "UnitPrice"),
    ("product_name", "Name"),
    ("do_not_create_opportunity", "doNotCreateOpportunity"),
    ("opportunity_name", "opportunityName"),
    ("days_back", "daysBack"),
    ("days_stale", "daysStale"),
    ("days_ahead", "daysAhead"),
    ("start_date", "StartDate"),
    ("end_date", "EndDate"),
    ("start_datetime", "StartDateTime"),
    ("end_datetime", "EndDateTime"),
    ("account_name", "accountName"),  # name lookup helper (not Account.Name when Name is field)
    ("partner_name", "Name"),
    ("case_number", "CaseNumber"),
    ("is_primary", "IsPrimary"),
    # camel leftovers from partial pass
    ("accountId", "Id"),  # will wrong-fix relationships — handled carefully below
]


def rewrite_keys(text: str, primary: str | None) -> str:
    """Quote-aware key replace for Apex string maps: 'old' → 'new'."""
    # 1) Primary object snake → Id
    if primary and primary in PRIMARY_SNAKE:
        snake = PRIMARY_SNAKE[primary]
        text = re.sub(rf"'{re.escape(snake)}'", "'Id'", text)
        # also camel primary for Account was accountId
        camel_primary = {
            "Account": "accountId",
            "Contact": "contactId",
            "Lead": "leadId",
            "Opportunity": "opportunityId",
            "Case": "caseId",
            "Campaign": "campaignId",
            "Order": "orderId",
            "Contract": "contractId",
            "Quote": "quoteId",
            "Product2": "productId",
            "WorkOrder": "workOrderId",
            "SBQQ__Quote__c": "cpqQuoteId",
        }.get(primary)
        if camel_primary:
            text = re.sub(rf"'{re.escape(camel_primary)}'", "'Id'", text)

    # 2) Relationships (skip keys that should stay primary Id already rewritten)
    for old, new in RELATIONSHIP:
        # skip if this old is primary snake and we already rewrote
        if primary and PRIMARY_SNAKE.get(primary) == old:
            continue
        # financial / care plan etc. already mapped to Id as primary of that skill class
        text = re.sub(rf"'{re.escape(old)}'", f"'{new}'", text)

    # 3) Helpers
    for old, new in HELPERS:
        if old == "accountId":
            # only rewrite if primary Account (already done) or leave Contact's AccountId
            continue
        text = re.sub(rf"'{re.escape(old)}'", f"'{new}'", text)

    return text


def process_file(path: Path) -> tuple[int, int]:
    raw = path.read_text(encoding="utf-8")
    cm = re.search(r"CLASS_NAME\s*=\s*'([^']+)'", raw)
    class_name = cm.group(1) if cm else ""
    primary = CLASS_PRIMARY.get(class_name)

    chunks = re.split(r"(prompts\.add\(new ccai__AI_Prompt__c\()", raw)
    # chunks[0] header, then (marker, body, marker, body...)
    if len(chunks) < 2:
        return 0, 0

    out = [chunks[0]]
    changed_skills = 0
    for i in range(1, len(chunks), 2):
        marker = chunks[i]
        body = chunks[i + 1] if i + 1 < len(chunks) else ""
        new_body = rewrite_keys(body, primary)
        if new_body != body:
            changed_skills += 1
        out.append(marker)
        out.append(new_body)

    new_text = "".join(out)
    # global helpers always
    for old, new in HELPERS:
        if old == "accountId":
            continue
        new_text2 = re.sub(rf"'{re.escape(old)}'", f"'{new}'", new_text)
        new_text = new_text2

    if new_text != raw:
        path.write_text(new_text, encoding="utf-8")
        return 1, changed_skills
    return 0, 0


def main() -> None:
    files = 0
    skills = 0
    for p in sorted(SCRIPTS.glob("Part*.apex")):
        if p.name.startswith("Part0"):
            continue
        f, s = process_file(p)
        files += f
        skills += s
        print(f"  {p.name}: {'updated' if f else 'no-change'} ({s} skill blocks touched)")
    print(f"Done. files_updated={files} skill_blocks_changed={skills}")


if __name__ == "__main__":
    main()
