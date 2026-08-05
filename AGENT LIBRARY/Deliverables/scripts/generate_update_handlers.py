# -*- coding: utf-8 -*-
"""Regenerate UpdatePromptHandlerClasses.apex from GenericAgenticSkillsHandler."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FACADE = ROOT / "force-app" / "main" / "default" / "classes" / "GenericAgenticSkillsHandler.cls"
OUT = ROOT / "scripts" / "UpdatePromptHandlerClasses.apex"

HANDLERS = {
    "ACCOUNT_HANDLER": "AccountAgenticSkillsHandler",
    "CONTACT_HANDLER": "ContactAgenticSkillsHandler",
    "LEAD_HANDLER": "LeadAgenticSkillsHandler",
    "OPPORTUNITY_HANDLER": "OpportunityAgenticSkillsHandler",
    "CASE_HANDLER": "CaseAgenticSkillsHandler",
    "ACTIVITY_HANDLER": "ActivityAgenticSkillsHandler",
    "UTILITY_HANDLER": "UtilityAgenticSkillsHandler",
    "PRODUCT_HANDLER": "ProductAgenticSkillsHandler",
    "CAMPAIGN_HANDLER": "CampaignAgenticSkillsHandler",
    "QUOTE_HANDLER": "QuoteAgenticSkillsHandler",
    "CONTRACT_HANDLER": "ContractAgenticSkillsHandler",
    "SERVICE_HANDLER": "ServiceAgenticSkillsHandler",
    "FIELD_SERVICE_HANDLER": "FieldServiceAgenticSkillsHandler",
    "CPQ_HANDLER": "CpqAgenticSkillsHandler",
    "ORDER_HANDLER": "OrderAgenticSkillsHandler",
    "PARTNER_HANDLER": "PartnerAgenticSkillsHandler",
    "INDUSTRY_HANDLER": "IndustryAgenticSkillsHandler",
}

text = FACADE.read_text(encoding="utf-8")
mapping: dict[str, str] = {}
for line in text.splitlines():
    m = re.search(r"when '([^']+)'\s+\{ return ([A-Z_]+)_HANDLER", line)
    if m:
        mapping[m.group(1)] = HANDLERS[m.group(2) + "_HANDLER"]

lines = [
    "// Updates ccai__AI_Prompt__c Agentic_Function_Class__c — all 108 skills.",
    "Map<String, String> skillToClass = new Map<String, String>();",
]
for skill in sorted(mapping):
    lines.append(f"skillToClass.put('{skill}', '{mapping[skill]}');")
lines += [
    "",
    "Set<String> skillNames = skillToClass.keySet();",
    "List<ccai__AI_Prompt__c> prompts = [",
    "    SELECT Id, Name, ccai__Agentic_Function_Class__c",
    "    FROM ccai__AI_Prompt__c",
    "    WHERE Name IN :skillNames",
    "];",
    "Integer updated = 0;",
    "for (ccai__AI_Prompt__c p : prompts) {",
    "    String target = skillToClass.get(p.Name);",
    "    if (p.ccai__Agentic_Function_Class__c != target) {",
    "        p.ccai__Agentic_Function_Class__c = target;",
    "        updated++;",
    "    }",
    "}",
    "if (!prompts.isEmpty()) {",
    "    update prompts;",
    "}",
    "System.debug('Updated ' + updated + ' prompt(s) to per-object handler classes.');",
]
OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(f"Wrote {len(mapping)} skills -> {OUT.name}")
