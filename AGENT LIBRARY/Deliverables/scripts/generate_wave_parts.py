# -*- coding: utf-8 -*-
"""Generate Part9–Part16 seed scripts for waves 3–12."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "scripts"

HANDLER_CLASS = {
    "Campaign": "CampaignAgenticSkillsHandler",
    "Quote": "QuoteAgenticSkillsHandler",
    "Opportunity": "OpportunityAgenticSkillsHandler",
    "Contract": "ContractAgenticSkillsHandler",
    "Case": "CaseAgenticSkillsHandler",
    "Utility": "UtilityAgenticSkillsHandler",
    "Service": "ServiceAgenticSkillsHandler",
    "FieldService": "FieldServiceAgenticSkillsHandler",
    "Cpq": "CpqAgenticSkillsHandler",
    "Order": "OrderAgenticSkillsHandler",
    "Partner": "PartnerAgenticSkillsHandler",
    "Industry": "IndustryAgenticSkillsHandler",
}

# (filename, comment, handler_key, skills)
PARTS = [
    (
        "Part9_Campaign.apex",
        "CAMPAIGN SKILLS (7) — Wave 3",
        "Campaign",
        [
            "fuzzy_search_campaigns",
            "fetch_campaign_details",
            "create_campaign",
            "update_campaign_fields",
            "fetch_campaign_members",
            "add_campaign_member",
            "update_campaign_member_status",
        ],
    ),
    (
        "Part10_Quote.apex",
        "QUOTE SKILLS (6) — Wave 4",
        "Quote",
        [
            "fuzzy_search_quotes",
            "fetch_quote_details",
            "create_quote",
            "update_quote_fields",
            "add_quote_line_item",
            "update_quote_line_item",
        ],
    ),
    (
        "Part11_DealTeam.apex",
        "DEAL TEAM & PIPELINE (11) — Wave 5",
        None,
        [
            ("fetch_opportunity_contact_roles", "Opportunity"),
            ("add_opportunity_contact_role", "Opportunity"),
            ("update_opportunity_contact_role", "Opportunity"),
            ("fetch_opportunity_team", "Opportunity"),
            ("add_opportunity_team_member", "Opportunity"),
            ("fetch_my_open_opportunities", "Utility"),
            ("fetch_stale_opportunities", "Utility"),
            ("clone_opportunity", "Opportunity"),
            ("fetch_contract_details", "Contract"),
            ("create_contract", "Contract"),
            ("update_contract_fields", "Contract"),
        ],
    ),
    (
        "Part12_Service.apex",
        "SERVICE CLOUD (9) — Wave 6",
        None,
        [
            ("fetch_case_team", "Case"),
            ("add_case_team_member", "Case"),
            ("search_knowledge_articles", "Utility"),
            ("fetch_knowledge_article", "Utility"),
            ("link_knowledge_article_to_case", "Case"),
            ("fetch_case_milestones", "Service"),
            ("fetch_case_entitlements", "Service"),
            ("assign_to_queue", "Utility"),
            ("fetch_queue_cases", "Utility"),
        ],
    ),
    (
        "Part13_FieldService.apex",
        "ASSET & FIELD SERVICE (10) — Wave 7",
        None,
        [
            ("fuzzy_search_assets", "Service"),
            ("fetch_asset_details", "Service"),
            ("update_asset_fields", "Service"),
            ("fetch_work_order_details", "FieldService"),
            ("create_work_order", "FieldService"),
            ("update_work_order_fields", "FieldService"),
            ("fetch_service_appointment", "FieldService"),
            ("schedule_service_appointment", "FieldService"),
            ("update_service_appointment", "FieldService"),
            ("fetch_service_resource_availability", "FieldService"),
        ],
    ),
    (
        "Part14_Cpq.apex",
        "CPQ SKILLS (6) — Wave 8",
        "Cpq",
        [
            "fetch_cpq_quote_details",
            "create_cpq_quote",
            "update_cpq_quote_fields",
            "add_cpq_quote_line",
            "update_cpq_quote_line",
            "calculate_cpq_quote",
        ],
    ),
    (
        "Part15_Order.apex",
        "ORDERS & SUBSCRIPTIONS (7) — Wave 9",
        "Order",
        [
            "fetch_order_details",
            "create_order",
            "update_order_fields",
            "add_order_item",
            "update_order_item",
            "fetch_subscription_details",
            "update_subscription_fields",
        ],
    ),
    (
        "Part16_PartnerIndustry.apex",
        "PARTNER, INDUSTRY & PLATFORM (12) — Waves 10–12",
        None,
        [
            ("fuzzy_search_partners", "Partner"),
            ("fetch_partner_account", "Partner"),
            ("add_opportunity_partner", "Partner"),
            ("fetch_opportunity_partners", "Opportunity"),
            ("fetch_financial_account", "Industry"),
            ("update_financial_account_fields", "Industry"),
            ("fetch_care_plan", "Industry"),
            ("fetch_record_approvals", "Utility"),
            ("fetch_renewal_opportunities", "Utility"),
            ("remove_campaign_member", "Campaign"),
            ("create_care_task", "Industry"),
            ("update_care_plan_fields", "Industry"),
        ],
    ),
]

ID_ALIASES = {
    "campaign": "campaign_id",
    "quote": "quote_id",
    "contract": "contract_id",
    "case": "case_id",
    "asset": "asset_id",
    "work_order": "work_order_id",
    "service_appointment": "service_appointment_id",
    "cpq_quote": "cpq_quote_id",
    "order": "order_id",
    "subscription": "subscription_id",
    "partner": "partner_account_id",
    "financial_account": "financial_account_id",
    "care_plan": "care_plan_id",
    "opportunity": "opportunity_id",
    "record": "record_id",
    "queue": "queue_id",
    "article": "article_id",
    "knowledge_article": "article_id",
    "campaign_member": "campaign_member_id",
    "quote_line_item": "line_item_id",
    "order_item": "order_item_id",
    "cpq_quote_line": "line_id",
    "care_task": "care_task_id",
}


def _id_param(skill: str) -> str:
    if skill.startswith("fetch_") and skill.endswith("_details"):
        core = skill[6:-8]
        return ID_ALIASES.get(core, core.replace("_", " ") + "_id").replace(" ", "_")
    if skill.startswith("update_") and skill.endswith("_fields"):
        core = skill[7:-7]
        return ID_ALIASES.get(core, core + "_id")
    if skill == "clone_opportunity":
        return "opportunity_id"
    if skill == "fetch_opportunity_partners":
        return "opportunity_id"
    if skill == "fetch_case_team":
        return "case_id"
    if skill == "fetch_case_milestones":
        return "case_id"
    if skill == "fetch_case_entitlements":
        return "case_id"
    if skill == "fetch_campaign_members":
        return "campaign_id"
    if skill == "add_opportunity_contact_role":
        return "opportunity_id"
    if skill == "update_opportunity_contact_role":
        return "contact_role_id"
    if skill == "add_opportunity_team_member":
        return "opportunity_id"
    if skill == "add_case_team_member":
        return "case_id"
    if skill == "link_knowledge_article_to_case":
        return "case_id"
    if skill == "add_opportunity_partner":
        return "opportunity_id"
    if skill == "add_campaign_member":
        return "campaign_id"
    if skill == "update_campaign_member_status":
        return "campaign_member_id"
    if skill == "remove_campaign_member":
        return "campaign_member_id"
    if skill == "add_quote_line_item":
        return "quote_id"
    if skill == "update_quote_line_item":
        return "line_item_id"
    if skill == "add_order_item":
        return "order_id"
    if skill == "update_order_item":
        return "order_item_id"
    if skill == "add_cpq_quote_line":
        return "cpq_quote_id"
    if skill == "update_cpq_quote_line":
        return "line_id"
    if skill == "calculate_cpq_quote":
        return "cpq_quote_id"
    if skill == "schedule_service_appointment":
        return "service_appointment_id"
    if skill == "update_service_appointment":
        return "service_appointment_id"
    if skill == "create_work_order":
        return "account_id"
    if skill == "assign_to_queue":
        return "record_id"
    if skill == "fetch_record_approvals":
        return "record_id"
    if skill == "fetch_queue_cases":
        return "queue_id"
    if skill == "fetch_knowledge_article":
        return "article_id"
    if skill == "fetch_partner_account":
        return "partner_account_id"
    if skill == "create_care_task":
        return "care_plan_id"
    return "record_id"


def _extra_props(skill: str) -> dict[str, dict]:
    props: dict[str, dict] = {}
    if skill.startswith("fuzzy_search_"):
        return {}
    if skill.startswith("create_"):
        props["Name"] = {"type": "string", "description": "Record name (required for most objects)."}
    if skill == "add_campaign_member":
        props["contact_id"] = {"type": "string", "description": "Contact Id (or lead_id)."}
        props["lead_id"] = {"type": "string", "description": "Lead Id (or contact_id)."}
        props["status"] = {"type": "string", "description": "Optional member status."}
    if skill == "update_campaign_member_status":
        props["status"] = {"type": "string", "description": "New campaign member status."}
    if skill == "add_opportunity_contact_role":
        props["contact_id"] = {"type": "string"}
        props["role"] = {"type": "string"}
        props["is_primary"] = {"type": "boolean"}
    if skill == "add_opportunity_team_member":
        props["user_id"] = {"type": "string"}
        props["team_role"] = {"type": "string"}
    if skill == "add_case_team_member":
        props["user_id"] = {"type": "string"}
        props["team_role"] = {"type": "string"}
    if skill == "link_knowledge_article_to_case":
        props["article_id"] = {"type": "string"}
    if skill == "search_knowledge_articles":
        props["search_term"] = {"type": "string", "description": "Keywords to search Knowledge."}
    if skill == "assign_to_queue":
        props["queue_id"] = {"type": "string"}
    if skill == "schedule_service_appointment":
        props["start_datetime"] = {"type": "string"}
        props["end_datetime"] = {"type": "string"}
    if skill == "fetch_service_resource_availability":
        props["service_resource_id"] = {"type": "string"}
        props["start_date"] = {"type": "string"}
        props["end_date"] = {"type": "string"}
    if skill == "fetch_stale_opportunities":
        props["days_stale"] = {"type": "integer", "description": "Days since last activity (default 30)."}
    if skill == "fetch_my_open_opportunities":
        props["limit"] = {"type": "integer"}
    if skill == "fetch_queue_cases":
        props["limit"] = {"type": "integer"}
    if skill == "fetch_renewal_opportunities":
        props["account_id"] = {"type": "string", "description": "Optional Account filter."}
    if skill == "add_opportunity_partner":
        props["partner_account_id"] = {"type": "string"}
        props["role"] = {"type": "string"}
    if skill == "create_quote":
        props["opportunity_id"] = {"type": "string"}
    if skill == "create_order":
        props["account_id"] = {"type": "string"}
    if skill == "create_contract":
        props["account_id"] = {"type": "string"}
    if skill == "create_cpq_quote":
        props["opportunity_id"] = {"type": "string"}
    return props


def _required(skill: str, id_param: str) -> list[str]:
    if skill.startswith("fuzzy_search_"):
        return ["search_term"]
    if skill == "search_knowledge_articles":
        return ["search_term"]
    if skill.startswith("fetch_my_open"):
        return []
    if skill == "fetch_stale_opportunities":
        return []
    if skill == "fetch_renewal_opportunities":
        return []
    if skill == "fetch_service_resource_availability":
        return ["service_resource_id"]
    if skill.startswith("create_"):
        return []
    if skill == "add_campaign_member":
        return ["campaign_id"]
    if skill == "update_campaign_member_status":
        return ["campaign_member_id", "status"]
    if skill == "add_opportunity_contact_role":
        return ["opportunity_id", "contact_id", "role"]
    if skill == "add_opportunity_team_member":
        return ["opportunity_id", "user_id"]
    if skill == "add_case_team_member":
        return ["case_id", "user_id"]
    if skill == "link_knowledge_article_to_case":
        return ["case_id", "article_id"]
    if skill == "assign_to_queue":
        return ["record_id", "queue_id"]
    if skill.startswith("update_") and skill.endswith("_fields"):
        return [id_param]
    if skill.startswith("add_") or skill.startswith("update_"):
        return [id_param]
    if skill.startswith("fetch_") or skill.startswith("calculate_"):
        return [id_param]
    if skill == "clone_opportunity":
        return ["opportunity_id"]
    return [id_param] if id_param else []


def schema_block(skill: str) -> str:
    id_param = _id_param(skill)
    required = _required(skill, id_param)
    props: dict[str, dict] = {}

    if skill.startswith("fuzzy_search_"):
        props["search_term"] = {
            "type": "string",
            "description": "Partial name or keyword to search.",
        }
    elif id_param and id_param not in _extra_props(skill):
        label = id_param.replace("_", " ")
        props[id_param] = {"type": "string", "description": f"Salesforce {label}."}

    for k, v in _extra_props(skill).items():
        props[k] = v

    if skill.startswith("update_") and skill.endswith("_fields"):
        props["additionalProperties"] = True  # type: ignore[assignment]

    lines = ["        'type' => 'object',"]
    if required:
        req = ", ".join(f"'{r}'" for r in required)
        lines.append(f"        'required' => new List<String>{{ {req} }},")
    else:
        lines.append("        'required' => new List<String>(),")

    lines.append("        'properties' => new Map<String, Object>{")
    prop_lines = []
    for key, meta in props.items():
        if key == "additionalProperties":
            continue
        desc = meta.get("description", "")
        if desc:
            prop_lines.append(
                f"            '{key}' => new Map<String, Object>{{ "
                f"'type' => '{meta['type']}', 'description' => '{desc}' }}"
            )
        else:
            prop_lines.append(
                f"            '{key}' => new Map<String, Object>{{ 'type' => '{meta['type']}' }}"
            )
    lines.append(",\n".join(prop_lines))
    lines.append("        }")

    if skill.startswith("update_") and skill.endswith("_fields"):
        lines.append("        ,'additionalProperties' => true")
    elif skill.startswith("create_"):
        lines.append("        ,'additionalProperties' => true")

    return "\n".join(lines)


def prompt_block(skill: str, handler: str) -> str:
    from skill_descriptions import SKILL_DESCRIPTIONS, apex_escape

    schema = schema_block(skill)
    desc = apex_escape(SKILL_DESCRIPTIONS[skill])
    return f"""prompts.add(new ccai__AI_Prompt__c(
    Name = '{skill}',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = '{desc}',
    ccai__Agentic_Function_Class__c = '{handler}',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{{
{schema}
    }})
));"""


def render_part(filename: str, comment: str, handler_key: str | None, skills: list) -> str:
    blocks: list[str] = []
    for item in skills:
        if isinstance(item, tuple):
            skill, hk = item
            handler = HANDLER_CLASS[hk]
        else:
            skill = item
            handler = HANDLER_CLASS[handler_key]
        blocks.append(prompt_block(skill, handler))

    class_line = ""
    if handler_key:
        class_line = f"final String CLASS_NAME = '{HANDLER_CLASS[handler_key]}';\n"

    body = "\n\n".join(blocks)
    return f"""// Part — {comment}
{class_line}final String AGENTIC = 'Agentic';
final String ACTIVE = 'Active';
final String DATA_MAPPING = 'a04J9000002y7ShIAI';

List<ccai__AI_Prompt__c> prompts = new List<ccai__AI_Prompt__c>();

{body}

Set<String> proposedNames = new Set<String>();
for (ccai__AI_Prompt__c p : prompts) proposedNames.add(p.Name);
Set<String> existingNames = new Set<String>();
for (ccai__AI_Prompt__c p : [SELECT Name FROM ccai__AI_Prompt__c WHERE Name IN :proposedNames]) {{
    existingNames.add(p.Name);
}}
List<ccai__AI_Prompt__c> toInsert = new List<ccai__AI_Prompt__c>();
List<String> skipped = new List<String>();
for (ccai__AI_Prompt__c p : prompts) {{
    if (existingNames.contains(p.Name)) skipped.add(p.Name);
    else toInsert.add(p);
}}
if (!toInsert.isEmpty()) insert toInsert;
System.debug('Inserted ' + toInsert.size() + ' / Skipped ' + skipped.size() + ' -> ' + skipped);
for (ccai__AI_Prompt__c p : toInsert) System.debug('  + ' + p.Name + ' -> ' + p.Id);
"""


def main() -> None:
    for spec in PARTS:
        path = SCRIPTS / spec[0]
        content = render_part(*spec)
        path.write_text(content, encoding="utf-8")
        print(f"Wrote {path.name}")


if __name__ == "__main__":
    main()
