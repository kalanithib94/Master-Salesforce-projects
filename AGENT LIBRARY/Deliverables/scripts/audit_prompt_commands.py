# -*- coding: utf-8 -*-
"""Classify all 111 skills against primary-Id vs relationship-field convention."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = json.loads((ROOT / "docs" / "PROMPT_COMMANDS_BY_SKILL.json").read_text(encoding="utf-8"))
OUT = ROOT / "docs" / "PROMPT_COMMANDS_AUDIT.md"

# Child / junction skills: the object being written/listed is not the parent in the param.
# Parent must use relationship field API name (CampaignId, OpportunityId, ParentId, ...).
CHILD_PARENT_FIELD = {
    "add_campaign_member": ("CampaignId", "CampaignMember.CampaignId"),
    "fetch_campaign_members": ("CampaignId", "CampaignMember.CampaignId"),
    "add_case_comment": ("ParentId", "CaseComment.ParentId (Case)"),
    "add_case_team_member": ("ParentId", "CaseTeamMember.ParentId; CaseId also used in prompts"),
    "fetch_case_team": ("ParentId", "or CaseId"),
    "fetch_case_entitlements": ("CaseId", "or AccountId"),
    "fetch_case_milestones": ("CaseId", "milestones on case"),
    "add_opportunity_line_item": ("OpportunityId", "OpportunityLineItem.OpportunityId"),
    "add_opportunity_contact_role": ("OpportunityId", "OCR.OpportunityId"),
    "add_opportunity_partner": ("OpportunityId", "partner parent"),
    "add_opportunity_team_member": ("OpportunityId", "OTM.OpportunityId"),
    "fetch_opportunity_contact_roles": ("OpportunityId", "filter by opp"),
    "fetch_opportunity_team": ("OpportunityId", "filter by opp"),
    "fetch_opportunity_partners": ("OpportunityId", "filter by opp"),
    "add_order_item": ("OrderId", "OrderItem.OrderId"),
    "add_quote_line_item": ("QuoteId", "QuoteLineItem.QuoteId"),
    "add_cpq_quote_line": ("SBQQ__Quote__c", "CPQ line parent (QuoteId alias ok)"),
    "fetch_contact_engagement_history": ("Id", "PRIMARY Contact preferred as Id"),
    "fetch_account_plan": ("Id", "PRIMARY Account — plan is about account"),
    "fetch_partner_account": ("Id", "PRIMARY partner Account"),
    "link_knowledge_article_to_case": ("CaseId", "junction Case + article"),
    "clone_opportunity": ("Id", "PRIMARY Opportunity being cloned"),
}

# Skills where bare Id is correct (primary object of the skill).
PRIMARY_ID_OK = {
    "fetch_account_details",
    "fetch_account_related_lists",  # primary Account
    "fetch_asset_details",
    "fetch_campaign_details",
    "fetch_care_plan",
    "fetch_case_details",
    "fetch_contact_details",
    "fetch_cpq_quote_details",
    "fetch_financial_account",
    "fetch_lead_details",
    "fetch_opportunity_details",
    "fetch_order_details",
    "fetch_product_details",
    "fetch_quote_details",
    "fetch_record_approvals",
    "fetch_service_appointment",
    "fetch_subscription_details",
    "fetch_work_order_details",
    "update_account_fields",
    "update_asset_fields",
    "update_campaign_fields",
    "update_campaign_member_status",
    "update_care_plan_fields",
    "update_case_fields",
    "update_contact_fields",
    "update_cpq_quote_fields",
    "update_cpq_quote_line",
    "update_event",
    "update_financial_account_fields",
    "update_lead_fields",
    "update_opportunity_contact_role",
    "update_opportunity_fields",
    "update_opportunity_line_item",
    "update_order_fields",
    "update_order_item",
    "update_quote_fields",
    "update_quote_line_item",
    "update_service_appointment",
    "update_subscription_fields",
    "update_task",
    "update_work_order_fields",
    "remove_campaign_member",
    "close_case",
    "complete_task",
    "convert_lead",
    "assign_to_queue",
    "transfer_record_owner",
    "calculate_cpq_quote",
    "schedule_service_appointment",
    "run_internal_prompt",
    "fetch_session_context",  # optional page context Id
}

# Parent relationship naming preferred but CaseId used (acceptable aliases)
ACCEPTABLE_ALIAS = {
    "add_case_team_member": {"CaseId", "ParentId"},
    "fetch_case_team": {"CaseId", "ParentId"},
    "fetch_case_entitlements": {"CaseId"},
    "fetch_case_milestones": {"CaseId"},
}


def main() -> None:
    fix_parent = []
    primary_ok = []
    soft_inconsistent = []
    create_junk = []
    field_case = []
    polymorphic = []
    other = []

    for skill, meta in sorted(DATA.items()):
        req = set(meta.get("required") or [])
        props = {p["name"]: p for p in (meta.get("properties") or [])}
        names = set(props)

        # field case
        for n, want in (
            ("role", "Role"),
            ("quantity", "Quantity"),
            ("status", "Status"),
        ):
            if n in names:
                field_case.append((skill, n, want))

        if skill.startswith("create_") and "Id" in names and "Id" not in req:
            d = (props["Id"].get("description") or "")
            create_junk.append((skill, d))

        if skill in ("log_activity", "create_task", "create_event"):
            if "Id" in names and not names & {"WhatId", "WhoId"}:
                polymorphic.append((skill, "uses Id for parent; org model prefers WhatId/WhoId (+ aliases)"))

        # Child parent rule
        if skill in CHILD_PARENT_FIELD:
            expected, note = CHILD_PARENT_FIELD[skill]
            soft = ACCEPTABLE_ALIAS.get(skill, set())
            if expected == "Id":
                if "Id" not in names and expected not in soft:
                    # clone uses OpportunityId
                    if "OpportunityId" in names:
                        soft_inconsistent.append(
                            (skill, f"primary object should be `Id`, currently uses `OpportunityId` ({note})")
                        )
                    primary_ok.append((skill, "review"))
                else:
                    primary_ok.append((skill, note))
            else:
                has_rel = expected in names or bool(names & soft)
                if "Id" in names and expected not in names and not (names & soft):
                    d = props.get("Id", {}).get("description", "")
                    fix_parent.append((skill, expected, note, d))
                elif has_rel and expected in names:
                    primary_ok.append((skill, f"parent `{expected}` OK — {note}"))
                elif has_rel:
                    primary_ok.append((skill, f"parent via alias {names & soft} OK — {note}"))
                elif expected not in names:
                    soft_inconsistent.append((skill, f"missing expected parent `{expected}` ({note})"))
            continue

        if skill in PRIMARY_ID_OK:
            primary_ok.append((skill, "primary Id OK"))
            continue

        # Heuristic for remaining
        if skill.startswith(("fuzzy_search_", "fetch_my_", "fetch_stale", "fetch_renewal", "fetch_upcoming", "fetch_queue", "fetch_picklist", "search_")):
            other.append((skill, "search/list — no parent Id issue"))
            continue

        if skill.startswith("create_") and skill not in create_junk:
            other.append((skill, "create skill"))
            continue

        if "Id" in names and skill.startswith(("fetch_", "update_")):
            # XxxId used instead of Id for primary?
            alt = [n for n in names if n.endswith("Id") and n != "Id"]
            if "Id" not in names and alt:
                soft_inconsistent.append((skill, f"primary prefers `Id`; has {alt}"))
            else:
                primary_ok.append((skill, "likely primary Id"))
        elif any(n.endswith("Id") for n in names):
            rels = [n for n in names if n.endswith("Id")]
            if skill.startswith(("fetch_", "update_")) and "Id" not in names and len(rels) == 1:
                soft_inconsistent.append(
                    (skill, f"primary object uses relationship-style `{rels[0]}` — prefer bare `Id` for primary")
                )
            else:
                other.append((skill, f"params: {sorted(names)}"))
        else:
            other.append((skill, f"params: {sorted(names)}"))

    # Dedup create_junk that are also other
    lines = []
    lines.append("# Prompt Command audit — all 111 skills")
    lines.append("")
    lines.append("Convention:")
    lines.append("- **Primary** record of the skill → `Id`")
    lines.append("- **Parent / lookups** → org field API names (`CampaignId`, `OpportunityId`, `ParentId`, `AccountId`, …)")
    lines.append("- **Standard fields** → org API (`Status`, `Quantity`, `Role`, …)")
    lines.append("")
    lines.append("## Summary")
    lines.append("")
    lines.append(f"| Verdict | Count |")
    lines.append(f"|---|---|")
    lines.append(f"| Total skills | {len(DATA)} |")
    lines.append(f"| **Must fix** — parent passed as bare `Id` | **{len(fix_parent)}** |")
    lines.append(f"| Soft inconsistency (XxxId for primary, etc.) | {len(soft_inconsistent)} |")
    lines.append(f"| Create skills with spurious optional `Id` | {len(create_junk)} |")
    lines.append(f"| Field casing (role/quantity/status) | {len(field_case)} |")
    lines.append(f"| Polymorphic parent as `Id` (activity) | {len(polymorphic)} |")
    lines.append(f"| OK / no parent-shape issue | {len(DATA) - len(fix_parent)}* |")
    lines.append("")
    lines.append("\\* Remaining skills use primary `Id` correctly, correct relationship names, or are search/create with no parent Id confusion.")
    lines.append("")
    lines.append("## 1. MUST FIX — same class of bug as `add_campaign_member`")
    lines.append("")
    lines.append("Parent/filter object is passed as bare `Id` instead of the Salesforce relationship field.")
    lines.append("")
    lines.append("| Skill | Should be | Org model | Current Id description |")
    lines.append("|---|---|---|---|")
    for skill, exp, note, d in fix_parent:
        lines.append(f"| `{skill}` | `{exp}` | {note} | {d.replace('|', '/')} |")
    if not fix_parent:
        lines.append("| _(none)_ | | | |")
    lines.append("")
    lines.append("Already fixed earlier: `add_campaign_member`, `fetch_campaign_members` → `CampaignId`.")
    lines.append("")
    lines.append("## 2. Soft inconsistency — primary as `XxxId` (inverse of (1))")
    lines.append("")
    lines.append("Skill’s **primary** record uses a typed Id name; convention prefers bare `Id`.")
    lines.append("")
    if soft_inconsistent:
        for skill, msg in soft_inconsistent:
            lines.append(f"- `{skill}`: {msg}")
    else:
        lines.append("_None flagged._")
    lines.append("")
    lines.append("## 3. Create skills — remove / rename spurious optional `Id`")
    lines.append("")
    for skill, d in create_junk:
        lines.append(f"- `{skill}`: optional `Id` = “{d}” (should be parent lookup e.g. `AccountId` only, not free Id)")
    lines.append("")
    lines.append("## 4. Field API casing")
    lines.append("")
    for skill, n, want in field_case:
        lines.append(f"- `{skill}`: `{n}` → `{want}`")
    lines.append("")
    lines.append("## 5. Polymorphic activity parents")
    lines.append("")
    for skill, msg in polymorphic:
        lines.append(f"- `{skill}`: {msg}")
    lines.append("")
    lines.append("## 6. OK / no parent mislabel")
    lines.append("")
    lines.append(f"{len(primary_ok) + len(other)} skills not in must-fix (search, primary-Id fetch/update, already-correct child parents, etc.).")
    lines.append("")
    lines.append("Notable **already correct** child/parents:")
    for skill, note in primary_ok:
        if "CampaignId" in note or "OpportunityId" in note or "AccountId" in note or "alias" in note or "parent" in note.lower():
            lines.append(f"- `{skill}`: {note}")
    lines.append("")
    lines.append("## Full property dump")
    lines.append("")
    lines.append("| Skill | required | properties | Verdict |")
    lines.append("|---|---|---|---|")
    fix_set = {s for s, *_ in fix_parent}
    soft_set = {s for s, _ in soft_inconsistent}
    for skill, meta in sorted(DATA.items()):
        req = meta.get("required") or []
        names = [p["name"] for p in (meta.get("properties") or [])]
        if skill in fix_set:
            v = "**FIX parent Id**"
        elif skill in soft_set:
            v = "soft"
        elif skill in {s for s, _ in create_junk}:
            v = "create junk Id"
        elif any(s == skill for s, *_ in field_case):
            v = "field case"
        else:
            v = "ok"
        lines.append(
            f"| `{skill}` | {', '.join(f'`{r}`' for r in req) or '—'} | "
            f"{', '.join(f'`{n}`' for n in names) or '—'} | {v} |"
        )
    lines.append("")

    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {OUT}")
    print(f"MUST_FIX={len(fix_parent)}")
    for skill, exp, note, d in fix_parent:
        print(f"  {skill} -> {exp}")
    print(f"SOFT={len(soft_inconsistent)}")
    for skill, msg in soft_inconsistent:
        print(f"  {skill}: {msg}")
    print(f"CREATE_JUNK={len(create_junk)} FIELD_CASE={len(field_case)} POLY={len(polymorphic)}")


if __name__ == "__main__":
    main()
