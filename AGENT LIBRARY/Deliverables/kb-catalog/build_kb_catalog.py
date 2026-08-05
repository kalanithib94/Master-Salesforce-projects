# -*- coding: utf-8 -*-
"""
Build a Knowledge-Base style HTML catalog + per-skill download zips.

Each skill zip contains:
  - package.xml + force-app (AgenticSkillsBase + handler + smoke tests)
  - seed.apex, sample-system-prompt.txt, version.json, PRODUCTION_NOTES.txt
  - README.txt
  Catalog download adds install.ps1/sh (optional -RunTests) and package-config.json

Usage (from Deliverables):
  python kb-catalog/build_kb_catalog.py
"""
from __future__ import annotations

import json
import re
import shutil
import sys
import zipfile
from html import escape
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from skill_descriptions import SKILL_DESCRIPTIONS  # noqa: E402
from skill_catalog import (  # noqa: E402
    CATALOG_SECTIONS,
    FEATURED_SKILL_ORDER,
    FEATURED_SKILL_TAGS,
    FEATURED_SKILLS,
    SECTION_SKILL_ORDER,
    SKILL_SECTION,
    catalog_section_for,
    display_name_for,
    sort_skills_in_section,
)
OUT = Path(__file__).resolve().parent
PACKAGES = OUT / "packages"
ZIPS = OUT / "zips"
CLASSES = ROOT / "force-app" / "main" / "default" / "classes"
SYSTEM_PROMPT = ROOT / "docs" / "GenericCRMAssistant_SystemPrompt.txt"
CREATE_PROMPTS = ROOT / "scripts" / "CreateAgenticPrompts.apex"
SESSION_CTX = ROOT / "scripts" / "AddFetchSessionContextToAgent1.apex"

PARTS = [
    (ROOT / "scripts" / "Part1_Account.apex", "Account"),
    (ROOT / "scripts" / "Part2_Contact.apex", "Contact"),
    (ROOT / "scripts" / "Part3_Lead.apex", "Lead"),
    (ROOT / "scripts" / "Part4_Opportunity.apex", "Opportunity"),
    (ROOT / "scripts" / "Part5_Case.apex", "Case"),
    (ROOT / "scripts" / "Part6_Activity.apex", "Activity"),
    (ROOT / "scripts" / "Part7_Utility.apex", "Utility"),
    (ROOT / "scripts" / "Part8_Product.apex", "Product"),
    (ROOT / "scripts" / "Part9_Campaign.apex", "Campaign"),
    (ROOT / "scripts" / "Part10_Quote.apex", "Quote"),
    (ROOT / "scripts" / "Part11_DealTeam.apex", "DealTeam"),
    (ROOT / "scripts" / "Part12_Service.apex", "ServiceCloud"),
    (ROOT / "scripts" / "Part13_FieldService.apex", "FieldService"),
    (ROOT / "scripts" / "Part14_Cpq.apex", "Cpq"),
    (ROOT / "scripts" / "Part15_Order.apex", "Order"),
    (ROOT / "scripts" / "Part16_PartnerIndustry.apex", "PartnerIndustry"),
    (ROOT / "scripts" / "Part17_Wave13.apex", "Wave13"),
]

HANDLER_BY_CATEGORY = {
    "Account": "AccountAgenticSkillsHandler",
    "Contact": "ContactAgenticSkillsHandler",
    "Lead": "LeadAgenticSkillsHandler",
    "Opportunity": "OpportunityAgenticSkillsHandler",
    "Case": "CaseAgenticSkillsHandler",
    "Activity": "ActivityAgenticSkillsHandler",
    "Utility": "UtilityAgenticSkillsHandler",
    "Product": "ProductAgenticSkillsHandler",
    "Campaign": "CampaignAgenticSkillsHandler",
    "Quote": "QuoteAgenticSkillsHandler",
    "DealTeam": "OpportunityAgenticSkillsHandler",
    "ServiceCloud": "CaseAgenticSkillsHandler",
    "FieldService": "FieldServiceAgenticSkillsHandler",
    "Cpq": "CpqAgenticSkillsHandler",
    "Order": "OrderAgenticSkillsHandler",
    "PartnerIndustry": "PartnerAgenticSkillsHandler",
    "Wave13": "UtilityAgenticSkillsHandler",
}

HANDLER_TO_CATEGORY = {
    "AccountAgenticSkillsHandler": "Account",
    "ContactAgenticSkillsHandler": "Contact",
    "LeadAgenticSkillsHandler": "Lead",
    "OpportunityAgenticSkillsHandler": "Opportunity",
    "CaseAgenticSkillsHandler": "Case",
    "ActivityAgenticSkillsHandler": "Activity",
    "UtilityAgenticSkillsHandler": "Utility",
    "ProductAgenticSkillsHandler": "Product",
    "CampaignAgenticSkillsHandler": "Campaign",
    "QuoteAgenticSkillsHandler": "Quote",
    "ContractAgenticSkillsHandler": "Contract",
    "ServiceAgenticSkillsHandler": "Service",
    "FieldServiceAgenticSkillsHandler": "Field Service",
    "CpqAgenticSkillsHandler": "CPQ",
    "OrderAgenticSkillsHandler": "Order",
    "PartnerAgenticSkillsHandler": "Partner",
    "IndustryAgenticSkillsHandler": "Industry",
}

MASTER_SKILLS_PATH = ROOT / "scripts" / "MasterSkills.apex"
SKILL_NAME_RE = re.compile(r"'([a-z][a-z0-9_]*)'")


def load_master_skills() -> frozenset[str]:
    text = MASTER_SKILLS_PATH.read_text(encoding="utf-8")
    m = re.search(r"MASTER_SKILLS = new List<String>\{(.*?)\};", text, re.DOTALL)
    if not m:
        raise RuntimeError("Could not parse MasterSkills.apex")
    return frozenset(SKILL_NAME_RE.findall(m.group(1)))


IMPLEMENTED_SKILLS = load_master_skills()

PROMPT_RE = re.compile(
    r"prompts\.add\(new ccai__AI_Prompt__c\(\s*"
    r"Name = '([^']+)',"
    r"(.*?)"
    r"\)\s*\);",
    re.DOTALL,
)

DESC_RE = re.compile(
    r"Name = '([^']+)',.*?ccai__Description__c = '((?:\\'|[^'])*)'",
    re.DOTALL,
)


def load_descriptions() -> dict[str, str]:
    return dict(SKILL_DESCRIPTIONS)


def v1_extra_skills(descriptions: dict[str, str]) -> list[dict]:
    """Prompt blocks for v1 skills not present in Part*.apex seed scripts."""
    extras = [
        (
            "log_activity",
            "Activity",
            "ActivityAgenticSkillsHandler",
            "Logs a completed Task (call, email, meeting note) on any CRM record. Pass record_id — WhoId is set for Contact/Lead; WhatId for Account/Opportunity/Case and others. Subject is required.",
            """prompts.add(new ccai__AI_Prompt__c(
    Name = 'log_activity',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'DESCRIPTION',
    ccai__Agentic_Function_Class__c = 'ActivityAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'record_id', 'activity_subject' },
        'properties' => new Map<String, Object>{
            'record_id' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Salesforce Id of the parent record (Account, Contact, Lead, Opportunity, Case, etc.).'
            },
            'activity_subject' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Subject of the completed activity — must be confirmed with the user.'
            },
            'activity_description' => new Map<String, Object>{
                'type' => 'string',
                'description' => 'Optional notes or summary of the activity.'
            }
        }
    })
));""",
        ),
        (
            "update_task",
            "Activity",
            "ActivityAgenticSkillsHandler",
            "Updates an existing Task — Subject, Status, Priority, ActivityDate, OwnerId, Description, etc.",
            """prompts.add(new ccai__AI_Prompt__c(
    Name = 'update_task',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'DESCRIPTION',
    ccai__Agentic_Function_Class__c = 'ActivityAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'task_id' },
        'properties' => new Map<String, Object>{
            'task_id' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce Task Id.' },
            'Subject' => new Map<String, Object>{ 'type' => 'string' },
            'Status' => new Map<String, Object>{ 'type' => 'string' },
            'Priority' => new Map<String, Object>{ 'type' => 'string' },
            'ActivityDate' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Due date yyyy-MM-dd.' },
            'Description' => new Map<String, Object>{ 'type' => 'string' }
        },
        'additionalProperties' => true
    })
));""",
        ),
        (
            "update_event",
            "Activity",
            "ActivityAgenticSkillsHandler",
            "Updates an existing Event — Subject, StartDateTime, EndDateTime, Location, Description, etc.",
            """prompts.add(new ccai__AI_Prompt__c(
    Name = 'update_event',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'DESCRIPTION',
    ccai__Agentic_Function_Class__c = 'ActivityAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'event_id' },
        'properties' => new Map<String, Object>{
            'event_id' => new Map<String, Object>{ 'type' => 'string', 'description' => 'Salesforce Event Id.' },
            'Subject' => new Map<String, Object>{ 'type' => 'string' },
            'StartDateTime' => new Map<String, Object>{ 'type' => 'string' },
            'EndDateTime' => new Map<String, Object>{ 'type' => 'string' },
            'Location' => new Map<String, Object>{ 'type' => 'string' },
            'Description' => new Map<String, Object>{ 'type' => 'string' }
        },
        'additionalProperties' => true
    })
));""",
        ),
        (
            "update_opportunity_line_item",
            "Opportunity",
            "OpportunityAgenticSkillsHandler",
            "Updates an OpportunityLineItem — Quantity, UnitPrice, Discount, etc.",
            """prompts.add(new ccai__AI_Prompt__c(
    Name = 'update_opportunity_line_item',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = 'DESCRIPTION',
    ccai__Agentic_Function_Class__c = 'OpportunityAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{
        'type' => 'object',
        'required' => new List<String>{ 'line_item_id' },
        'properties' => new Map<String, Object>{
            'line_item_id' => new Map<String, Object>{ 'type' => 'string', 'description' => 'OpportunityLineItem Id.' },
            'Quantity' => new Map<String, Object>{ 'type' => 'number' },
            'UnitPrice' => new Map<String, Object>{ 'type' => 'number' },
            'Discount' => new Map<String, Object>{ 'type' => 'number' }
        },
        'additionalProperties' => true
    })
));""",
        ),
    ]
    out: list[dict] = []
    for name, category, handler, _desc, tmpl in extras:
        desc = descriptions.get(name, _desc)
        block = tmpl.replace("DESCRIPTION", desc.replace("'", "\\'"))
        out.append(
            {
                "name": name,
                "display_name": display_name_for(name),
                "category": catalog_section_for(name),
                "handler": handler,
                "prompt_block": block,
                "description": desc,
            }
        )
    return out


def extract_skills() -> list[dict]:
    descriptions = load_descriptions()
    skills: list[dict] = []
    seen: set[str] = set()

    for path, category in PARTS:
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8")
        default_handler = HANDLER_BY_CATEGORY.get(category, "")
        for m in PROMPT_RE.finditer(text):
            name = m.group(1)
            if name not in IMPLEMENTED_SKILLS:
                continue
            if name in seen:
                continue
            seen.add(name)
            block = m.group(0)
            hm = re.search(
                r"ccai__Agentic_Function_Class__c = '([^']+)'", block
            )
            handler = hm.group(1) if hm else default_handler
            cat = catalog_section_for(name)
            desc = descriptions.get(name, f"GPTfy skill: {name}.")
            block = block.replace("CLASS_NAME", f"'{handler}'")
            block = block.replace(f"''{handler}''", f"'{handler}'")
            block = re.sub(
                r"ccai__AI_Data_Extraction_Mapping__c = '[^']+'",
                "ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING",
                block,
            )
            block = re.sub(
                r"\s*ccai__Description__c\s*=\s*'(?:[^'\\]|\\.)*'\s*,\r?\n",
                "\n",
                block,
            )
            if "ccai__Description__c" not in block:
                block = block.replace(
                    "ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,",
                    "ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,\n"
                    f"    ccai__Description__c = '{desc.replace(chr(39), chr(92)+chr(39))}',",
                    1,
                )
            skills.append(
                {
                    "name": name,
                    "display_name": display_name_for(name),
                    "category": cat,
                    "handler": handler,
                    "prompt_block": block,
                    "description": desc,
                }
            )

    # fetch_session_context (not in Part7 historically)
    if "fetch_session_context" not in seen and SESSION_CTX.exists():
        sc = SESSION_CTX.read_text(encoding="utf-8")
        desc = descriptions.get(
            "fetch_session_context",
            "Returns userContextId and related WhoId/WhatId for the session.",
        )
        block = f"""prompts.add(new ccai__AI_Prompt__c(
    Name = 'fetch_session_context',
    ccai__Type__c = AGENTIC, ccai__Status__c = ACTIVE,
    ccai__Description__c = '{desc.replace(chr(39), chr(92)+chr(39))}',
    ccai__Agentic_Function_Class__c = 'UtilityAgenticSkillsHandler',
    ccai__AI_Data_Extraction_Mapping__c = DATA_MAPPING,
    ccai__Prompt_Command__c = JSON.serializePretty(new Map<String, Object>{{
        'type' => 'object',
        'properties' => new Map<String, Object>{{
            'userContextId' => new Map<String, Object>{{
                'type' => 'string',
                'description' => 'Optional. Session/thread Id injected by GPTfy runtime.'
            }}
        }}
    }})
));"""
        skills.append(
            {
                "name": "fetch_session_context",
                "display_name": display_name_for("fetch_session_context"),
                "category": catalog_section_for("fetch_session_context"),
                "handler": "UtilityAgenticSkillsHandler",
                "prompt_block": block,
                "description": desc,
            }
        )

    for extra in v1_extra_skills(descriptions):
        if extra["name"] not in seen:
            skills.append(extra)
            seen.add(extra["name"])

    section_rank = {sid: i for i, (sid, _) in enumerate(CATALOG_SECTIONS)}

    def global_sort_key(s: dict) -> tuple:
        sid = SKILL_SECTION.get(s["name"], "")
        order = SECTION_SKILL_ORDER.get(sid, [])
        try:
            pri = order.index(s["name"])
        except ValueError:
            pri = 999
        return (section_rank.get(sid, 999), pri, s["display_name"].lower())

    skills.sort(key=global_sort_key)
    return skills


def package_xml(handler: str) -> str:
    members = [
        "AgenticSkillsBase",
        "AgenticSkillsBaseTest",
        handler,
        f"{handler}Test",
    ]
    member_xml = "\n".join(f"        <members>{m}</members>" for m in members)
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
{member_xml}
        <name>ApexClass</name>
    </types>
    <version>66.0</version>
</Package>
"""


def package_version_json(skill: dict) -> str:
    handler = skill["handler"]
    payload = {
        "packageVersion": "1.1.0",
        "sourceApiVersion": "66.0",
        "skill": skill["name"],
        "handler": handler,
        "classes": ["AgenticSkillsBase", handler],
        "tests": ["AgenticSkillsBaseTest", f"{handler}Test"],
        "requires": ["GPTfy (ccai) managed package"],
    }
    return json.dumps(payload, indent=2) + "\n"


def production_notes() -> str:
    return """PRODUCTION NOTES (short)
========================
- Deploy Apex with tests when promoting to prod:
    .\\install.ps1 -RunTests
  or:
    sf project deploy start --manifest package.xml --test-level RunSpecifiedTests \\
      --tests AgenticSkillsBaseTest --tests <Handler>Test --target-org <alias>
- Sharing: handlers are with sharing; user of the agent is the run-as context.
- Mutating skills expect the agent / system prompt to collect confirmation first.
- Mapping Id + Connection Id must be from THIS org (filled at download).
- Re-run seed is safe (existing skill Names skipped; missing agent links added).
- Apex re-deploy updates classes by name (does not create duplicate Apex types).
- Optional: apply system prompt only if toggle was on at download.

Verify after install:
1) Apex classes present (Setup → Apex Classes)
2) ccai AI Prompts for installed skill Names
3) Skills linked on the agent in GPTfy
4) Smoke chat on a sandbox record page
"""


def readme_for(skill: dict) -> str:
    name = skill["name"]
    title = skill.get("display_name", display_name_for(name))
    handler = skill["handler"]
    return f"""GPTfy Skill Package: {title}
================================

API name : {name}
Category : {skill["category"]}
Apex     : {handler} + AgenticSkillsBase (+ smoke tests)
Prompt   : ccai__AI_Prompt__c Name = {name}

WHAT IS IN THIS ZIP
-------------------
1. package.xml + force-app/     Apex + smoke tests
2. seed.apex                    Creates AI Prompt + agent skill link
3. sample-system-prompt.txt     Composed / sample agent system prompt
4. version.json                 Package metadata (classes, tests)
5. PRODUCTION_NOTES.txt         Deploy / verify cheat sheet
6. install.ps1 / install.sh     Deploy + register (optional -RunTests)
7. README.txt                   This file

PREREQUISITES
-------------
- GPTfy managed package (ccai) installed
- Salesforce CLI (sf) authenticated to the target org
- A Data Extraction Mapping Id and an AI Connection (model) Id in THIS org

IMPORT STEPS
------------
1) seed.apex Ids are prefilled when downloaded from the catalog.

2) Deploy Apex (from the unzipped folder):

   sf project deploy start --manifest package.xml --target-org <alias>

   Production (run package tests):

   .\\install.ps1 -RunTests
   or
   sf project deploy start --manifest package.xml --test-level RunSpecifiedTests --tests AgenticSkillsBaseTest --tests {handler}Test --target-org <alias>

3) Register skill (seed):

   sf apex run --file seed.apex --target-org <alias>

   Or use .\\install.ps1 (deploy + seed; -RunTests for tests).

4) Optional: system prompt via sample-system-prompt.txt / catalog toggle.

NOTES
-----
- Apex is shared per object. Deploying {handler} installs all methods in that class;
  this seed still creates ONLY the "{name}" prompt record.
- Re-running seed.apex is safe: existing prompt Names are skipped; missing links are added.
- Mapping / Model Ids do not transfer between orgs.
- See PRODUCTION_NOTES.txt for verify steps.

Skill summary
-------------
{skill["description"]}
"""


def seed_apex(skill: dict) -> str:
    return f"""// =============================================================================
// seed.apex — single skill: {skill["name"]}
// Creates/reuses agent "GPTfy Agent", inserts this prompt, links it.
// BEFORE RUNNING: set DATA_MAPPING and AI_MODEL for THIS org.
// =============================================================================

final String AGENT_NAME = 'GPTfy Agent';
final String AGENTIC = 'Agentic';
final String ACTIVE = 'Active';
// TODO: replace with THIS org's Ids
final String DATA_MAPPING = 'REPLACE_WITH_DATA_EXTRACTION_MAPPING_ID';
final String AI_MODEL = 'REPLACE_WITH_AI_CONNECTION_ID';

if (DATA_MAPPING == null || DATA_MAPPING.startsWith('REPLACE_')
    || AI_MODEL == null || AI_MODEL.startsWith('REPLACE_')) {{
    System.debug(LoggingLevel.ERROR,
        'Stop: set DATA_MAPPING and AI_MODEL to valid org Ids before running.');
}} else {{

List<ccai__AI_Agent__c> agents = [
    SELECT Id, Name, ccai__Status__c, ccai__AI_Model__c
    FROM ccai__AI_Agent__c
    WHERE Name = :AGENT_NAME
    LIMIT 1
];
ccai__AI_Agent__c agent;
if (agents.isEmpty()) {{
    agent = new ccai__AI_Agent__c(
        Name = AGENT_NAME,
        ccai__Status__c = ACTIVE,
        ccai__AI_Model__c = AI_MODEL
    );
    insert agent;
    System.debug('Created agent: ' + agent.Id);
}} else {{
    agent = agents[0];
    Boolean dirty = false;
    if (agent.ccai__Status__c != ACTIVE) {{ agent.ccai__Status__c = ACTIVE; dirty = true; }}
    if (agent.ccai__AI_Model__c == null) {{ agent.ccai__AI_Model__c = AI_MODEL; dirty = true; }}
    if (dirty) update agent;
    System.debug('Using existing agent: ' + agent.Id);
}}

List<ccai__AI_Prompt__c> prompts = new List<ccai__AI_Prompt__c>();

{skill["prompt_block"]}

Set<String> proposedNames = new Set<String>();
for (ccai__AI_Prompt__c p : prompts) proposedNames.add(p.Name);

Map<String, Id> existingByName = new Map<String, Id>();
for (ccai__AI_Prompt__c p : [
    SELECT Id, Name FROM ccai__AI_Prompt__c WHERE Name IN :proposedNames
]) {{
    existingByName.put(p.Name, p.Id);
}}

List<ccai__AI_Prompt__c> toInsert = new List<ccai__AI_Prompt__c>();
List<ccai__AI_Prompt__c> toUpdate = new List<ccai__AI_Prompt__c>();
for (ccai__AI_Prompt__c p : prompts) {{
    if (!existingByName.containsKey(p.Name)) {{
        toInsert.add(p);
    }} else {{
        // Refresh schema + class so reinstall picks up Prompt Command fixes
        p.Id = existingByName.get(p.Name);
        toUpdate.add(p);
    }}
}}
if (!toInsert.isEmpty()) insert toInsert;
if (!toUpdate.isEmpty()) update toUpdate;
for (ccai__AI_Prompt__c p : toInsert) existingByName.put(p.Name, p.Id);
for (ccai__AI_Prompt__c p : [
    SELECT Id, Name FROM ccai__AI_Prompt__c WHERE Name IN :proposedNames
]) {{
    existingByName.put(p.Name, p.Id);
}}

Set<Id> promptIds = new Set<Id>(existingByName.values());
Set<Id> alreadyLinked = new Set<Id>();
for (ccai__AI_Agent_Skill__c link : [
    SELECT ccai__AI_Prompt__c FROM ccai__AI_Agent_Skill__c
    WHERE ccai__AI_Agent__c = :agent.Id AND ccai__AI_Prompt__c IN :promptIds
]) {{
    alreadyLinked.add(link.ccai__AI_Prompt__c);
}}

List<ccai__AI_Agent_Skill__c> newLinks = new List<ccai__AI_Agent_Skill__c>();
for (String skillName : proposedNames) {{
    Id pid = existingByName.get(skillName);
    if (pid == null || alreadyLinked.contains(pid)) continue;
    newLinks.add(new ccai__AI_Agent_Skill__c(
        ccai__AI_Agent__c = agent.Id,
        ccai__AI_Prompt__c = pid
    ));
}}
if (!newLinks.isEmpty()) insert newLinks;
System.debug('Done. Skill={skill["name"]} Agent=' + agent.Id
    + ' PromptId=' + existingByName.get('{skill["name"]}')
    + ' NewLinks=' + newLinks.size());
}}
"""


def copy_apex(dest_classes: Path, handler: str) -> None:
    dest_classes.mkdir(parents=True, exist_ok=True)
    for base in ("AgenticSkillsBase", "AgenticSkillsBaseTest", handler, f"{handler}Test"):
        for ext in (".cls", ".cls-meta.xml"):
            src = CLASSES / f"{base}{ext}"
            if not src.exists():
                raise FileNotFoundError(src)
            shutil.copy2(src, dest_classes / f"{base}{ext}")


def write_skill_package(skill: dict, system_prompt: str) -> Path:
    name = skill["name"]
    pkg_dir = PACKAGES / name
    if pkg_dir.exists():
        shutil.rmtree(pkg_dir)
    classes_dir = pkg_dir / "force-app" / "main" / "default" / "classes"
    copy_apex(classes_dir, skill["handler"])
    (pkg_dir / "package.xml").write_text(package_xml(skill["handler"]), encoding="utf-8")
    (pkg_dir / "seed.apex").write_text(seed_apex(skill), encoding="utf-8")
    (pkg_dir / "sample-system-prompt.txt").write_text(system_prompt, encoding="utf-8")
    (pkg_dir / "README.txt").write_text(readme_for(skill), encoding="utf-8")
    (pkg_dir / "version.json").write_text(package_version_json(skill), encoding="utf-8")
    (pkg_dir / "PRODUCTION_NOTES.txt").write_text(production_notes(), encoding="utf-8")
    # sfdx-project.json so sf deploy works from unzipped folder
    (pkg_dir / "sfdx-project.json").write_text(
        '{\n  "packageDirectories": [{ "path": "force-app", "default": true }],\n'
        '  "name": "gptfy-skill-' + name + '",\n'
        '  "sourceApiVersion": "66.0"\n}\n',
        encoding="utf-8",
    )
    return pkg_dir


def zip_dir(src: Path, zip_path: Path) -> None:
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        for f in src.rglob("*"):
            if f.is_file():
                zf.write(f, arcname=f"{src.name}/{f.relative_to(src).as_posix()}")


def short_desc(text: str, limit: int = 72) -> str:
    """One short line for the card."""
    t = (text or "").strip().replace("\n", " ")
    # Prefer first sentence if short enough
    for sep in (". ", "? ", "! "):
        if sep in t:
            first = t.split(sep, 1)[0].strip()
            if first and len(first) <= limit:
                return first + ("." if not first.endswith(".") else "")
            break
    if len(t) <= limit:
        return t
    cut = t[: limit - 1].rsplit(" ", 1)[0]
    return cut + "…"


def is_mutating_skill(name: str) -> bool:
    prefixes = (
        "create_",
        "update_",
        "add_",
        "remove_",
        "convert_",
        "close_",
        "complete_",
        "log_",
        "schedule_",
        "calculate_",
        "transfer_",
        "link_",
        "assign_",
        "clone_",
    )
    return name.startswith(prefixes)


def skill_meta_json(skills: list[dict]) -> str:
    """Browser-side catalog for composing system prompts from selected skills."""
    meta: dict[str, dict] = {}
    for s in skills:
        name = s["name"]
        desc = SKILL_DESCRIPTIONS.get(name) or s.get("description") or name
        meta[name] = {
            "d": desc,
            "m": is_mutating_skill(name),
            "sec": s.get("category") or "",
            "h": s.get("handler") or "",
        }
    return json.dumps(meta, ensure_ascii=False, separators=(",", ":"))


def render_html(skills: list[dict]) -> str:
    def skill_card(s: dict, section: str, *, featured: bool = False) -> str:
        desc = escape(s.get("description") or "")
        api = escape(s["name"])
        display = escape(s.get("display_name") or s["name"])
        search = escape(
            f"{s.get('display_name') or ''} {s['name']} {s.get('description') or ''} recommended core".lower()
            if featured
            else f"{s.get('display_name') or ''} {s['name']} {s.get('description') or ''}".lower()
        )
        if s["name"] == "run_internal_prompt":
            badge = (
                '<span class="core-badge" title="Recommended for every agent">Core</span>'
            )
        elif featured:
            tag = FEATURED_SKILL_TAGS.get(s["name"], "Pick")
            badge = (
                f'<span class="rec-badge" title="GPTfy recommendation">{escape(tag)}</span>'
            )
        else:
            badge = ""
        feat_cls = " skill-featured" if featured else ""
        return f"""      <label class="skill{feat_cls}" data-name="{api}" data-display="{display}" data-section="{escape(section)}" data-search="{search}">
        <input type="checkbox" class="skill-check" value="{api}" />
        <span class="skill-body">
          <span class="skill-top"><span class="skill-title">{display}</span>{badge}</span>
          <span class="desc">{desc}</span>
        </span>
      </label>"""

    by_name = {s["name"]: s for s in skills}
    featured_skills = [
        by_name[n] for n in FEATURED_SKILL_ORDER if n in by_name
    ]
    by_section: dict[str, list[dict]] = {}
    for s in skills:
        # Top Picks also remain in their home categories (no duplicate counting in JS)
        by_section.setdefault(s["category"], []).append(s)

    recommended = ""
    if featured_skills:
        cards = [skill_card(s, "Top Picks", featured=True) for s in featured_skills]
        recommended = f"""    <details class="sec-panel featured" data-section="Top Picks" id="sec-recommended" open>
      <summary class="sec-summary">
        <span class="sec-title">Top Picks <span class="sec-sub">· GPTfy recommendations</span></span>
        <span class="sec-meta">
          <span class="chev" aria-hidden="true"></span>
        </span>
      </summary>
      <div class="sec-body">
{chr(10).join(cards)}
      </div>
    </details>"""

    panels: list[str] = []
    for _sid, section in CATALOG_SECTIONS:
        items = by_section.get(section, [])
        if not items:
            continue
        cards = [skill_card(s, section) for s in items]
        slug = re.sub(r"[^a-z0-9]+", "-", section.lower()).strip("-")
        panels.append(
            f"""    <div class="sec-tile" data-section="{escape(section)}" id="sec-{slug}">
      <button type="button" class="sec-open" aria-haspopup="dialog">
        <span class="sec-title">{escape(section)}</span>
        <span class="sec-meta">
          <span class="sec-selected" hidden>0 selected</span>
          <span class="sec-count" title="Skills in category">{len(cards)}</span>
        </span>
      </button>
      <div class="sec-store" hidden>
{chr(10).join(cards)}
      </div>
    </div>"""
        )

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>GPTfy Agentic Skills</title>
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:ital,wght@0,400;0,500;0,600;0,700;0,800;1,400&display=swap" rel="stylesheet" />
  <script src="https://cdnjs.cloudflare.com/ajax/libs/jszip/3.10.1/jszip.min.js"></script>
  <style>
    :root {{
      /* GPTfy.ai brand tokens */
      --bg: #ffffff;
      --panel: #ffffff;
      --ink: #1a1a2e;
      --muted: #6b7280;
      --line: #e7e0f6;
      --brand: #7c3aed;
      --brand-soft: #ede9fe;
      --brand-lighter: #f5f3ff;
      --brand-dark: #5b21b6;
      --brand-deep: #4c1d95;
      --brand-purple: #6b21a8;
      --accent: #f59e0b;
      --accent-light: #fef3c7;
      --accent-dark: #d97706;
      --radius: 12px;
      --shadow: 0 1px 2px rgba(26,26,46,.04), 0 8px 20px rgba(124,58,237,.08);
      --font: "Plus Jakarta Sans", "Segoe UI", system-ui, sans-serif;
    }}
    * {{ box-sizing: border-box; }}
    body {{
      margin: 0;
      font-family: var(--font);
      font-feature-settings: "ss01" on, "cv11" on;
      color: var(--ink);
      background: #ffffff;
      line-height: 1.5;
      -webkit-font-smoothing: antialiased;
      text-rendering: optimizeLegibility;
    }}
    .alert-modal,
    .alert-modal input,
    .alert-modal button,
    .alert-modal pre {{
      font-family: var(--font);
    }}
    .alert-shell h2 {{
      letter-spacing: -0.03em;
      font-weight: 750;
    }}
    .config-form input {{
      font-variant-numeric: tabular-nums;
      letter-spacing: 0.01em;
    }}
    .wrap {{ max-width: 1180px; margin: 0 auto; padding: 16px 16px 12px; }}
    .topbar {{
      display: flex; flex-wrap: wrap; align-items: center; justify-content: space-between;
      gap: 8px 16px; margin-bottom: 10px;
    }}
    .brand {{
      display: flex; align-items: baseline; gap: 8px; flex-wrap: wrap; min-width: 0;
    }}
    .brand h1 {{
      margin: 0; font-size: 1.15rem; font-weight: 750; letter-spacing: -.02em; color: var(--ink);
    }}
    .brand h1 span {{ color: var(--brand); }}
    .brand .meta {{ font-size: .8rem; color: var(--muted); }}
    .toolbar {{
      display: flex; flex-wrap: wrap; gap: 8px; align-items: center;
      background: rgba(255,255,255,.94); border: 1px solid var(--line); border-radius: var(--radius);
      padding: 8px 10px; box-shadow: var(--shadow); position: sticky; top: 8px; z-index: 20; margin-bottom: 12px;
      backdrop-filter: blur(8px);
    }}
    .search {{
      flex: 1 1 240px; min-width: 180px; border: 1px solid var(--line); border-radius: 9px;
      padding: 8px 11px; font: inherit; font-size: .9rem; background: #fff;
    }}
    .search:focus {{ outline: 2px solid #c4b5fd; border-color: var(--brand); }}
    .btn {{
      appearance: none; border: 1px solid var(--line); background: #fff; color: var(--ink);
      border-radius: 9px; padding: 8px 11px; font: inherit; font-size: .85rem; font-weight: 650; cursor: pointer;
    }}
    .btn:hover {{ background: #f8fafc; }}
    .btn.primary {{ background: var(--brand); border-color: var(--brand); color: #fff; }}
    .btn.primary:hover {{ filter: brightness(1.05); }}
    .btn:disabled {{ opacity: .45; cursor: not-allowed; }}
    .count-pill {{
      font-size: .82rem; color: var(--muted); background: #f8fafc; border: 1px solid var(--line);
      border-radius: 999px; padding: 6px 10px; white-space: nowrap;
    }}
    .status {{ font-size: .82rem; color: var(--muted); min-height: 1.2em; }}

    .featured-band {{ margin: 0 0 10px; }}
    .sec-panel {{
      background: var(--panel);
      border: 1px solid var(--line);
      border-radius: 12px;
      box-shadow: var(--shadow);
      overflow: hidden;
    }}
    .sec-panel[hidden] {{ display: none !important; }}
    .sec-panel.featured {{
      display: block;
      width: 100%;
      margin: 0;
      border-color: #ddd6fe;
      background: #fff;
      box-shadow: var(--shadow);
      border-radius: 10px;
    }}
    .sec-panel.featured > .sec-summary {{
      background: linear-gradient(135deg, #6b21a8 0%, #7c3aed 55%, #5b21b6 100%);
      color: #fff;
      padding: 8px 12px;
    }}
    .sec-panel.featured > .sec-summary:hover {{
      filter: brightness(1.03);
      background: linear-gradient(135deg, #6b21a8 0%, #7c3aed 55%, #5b21b6 100%);
    }}
    .sec-panel.featured[open] > .sec-summary {{ border-bottom-color: rgba(255,255,255,.2); }}
    .sec-panel.featured .sec-title {{ color: #fff; font-size: .88rem; }}
    .sec-panel.featured .sec-sub {{ font-weight: 500; opacity: .85; font-size: .78rem; }}
    .sec-panel.featured .chev {{ border-color: rgba(255,255,255,.85); }}
    .sec-panel.featured .sec-body {{
      grid-template-columns: repeat(4, minmax(0, 1fr));
      gap: 6px;
      padding: 8px;
      background: #faf8ff;
    }}
    .skill-featured {{
      border-color: #e7e0f6;
      background: #fff;
      padding: 7px 8px 7px 6px;
      gap: 6px;
      border-radius: 8px;
      height: auto;
    }}
    .skill-featured .skill-title {{ font-size: .82rem; color: var(--brand-purple); }}
    .skill-featured .desc {{
      font-size: .74rem; line-height: 1.3;
      display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;
    }}
    .skill-featured .skill-check {{ width: 13px; height: 13px; margin-top: 1px; }}
    .rec-badge {{
      display: inline-flex; align-items: center; font-size: .6rem; font-weight: 800; letter-spacing: .03em;
      text-transform: uppercase; color: var(--accent-dark); background: var(--accent-light); border: 1px solid #fde68a;
      border-radius: 999px; padding: 0 5px;
    }}
    .skill-featured .core-badge {{ font-size: .6rem; padding: 0 5px; }}
    @media (max-width: 980px) {{
      .sec-panel.featured .sec-body {{ grid-template-columns: repeat(2, minmax(0, 1fr)); }}
    }}
    @media (max-width: 640px) {{
      .sec-panel.featured .sec-body {{ grid-template-columns: 1fr; }}
    }}

    /* Category tiles — click opens popup (keeps 3-col grid stable) */
    .catalog-grid {{
      column-count: 3;
      column-gap: 12px;
    }}
    .sec-tile {{
      break-inside: avoid;
      display: inline-block;
      width: 100%;
      margin: 0 0 10px;
      vertical-align: top;
    }}
    .sec-tile[hidden] {{ display: none !important; }}
    .sec-open {{
      width: 100%;
      appearance: none;
      border: 1px solid var(--line);
      border-radius: 12px;
      background: var(--panel);
      box-shadow: var(--shadow);
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 8px;
      padding: 13px 14px;
      text-align: left;
      font: inherit;
      color: var(--ink);
      transition: border-color .15s ease, background .15s ease, box-shadow .15s ease;
    }}
    .sec-open:hover {{
      border-color: #c4b5fd;
      background: var(--brand-lighter);
      box-shadow: 0 2px 12px rgba(124,58,237,.12);
    }}
    .sec-open:focus-visible {{ outline: 2px solid #c4b5fd; outline-offset: 2px; }}
    .sec-title {{
      font-size: .92rem;
      font-weight: 750;
      letter-spacing: -.01em;
    }}
    .sec-meta {{ display: inline-flex; align-items: center; gap: 8px; flex-shrink: 0; }}
    .sec-count {{
      font-size: .72rem; font-weight: 700; color: var(--brand);
      background: #fff; border: 1px solid #ddd6fe; border-radius: 999px;
      min-width: 1.5rem; height: 1.5rem; display: inline-flex; align-items: center; justify-content: center;
      padding: 0 5px;
    }}
    .sec-selected {{
      font-size: .68rem; font-weight: 750; color: #fff;
      background: var(--brand); border-radius: 999px;
      padding: 3px 8px; white-space: nowrap;
    }}
    .sec-selected[hidden] {{ display: none !important; }}
    .sec-tile.has-selection .sec-open {{
      border-color: #c4b5fd;
      background: var(--brand-soft);
    }}
    .chev {{
      width: 7px; height: 7px; border-right: 2px solid var(--muted); border-bottom: 2px solid var(--muted);
      transform: rotate(45deg); transition: transform .15s ease; margin-top: -2px;
    }}
    .sec-panel[open] .chev,
    .guide-box[open] .chev,
    .request-box[open] .chev {{ transform: rotate(225deg); margin-top: 2px; }}
    .sec-panel .sec-summary {{
      list-style: none; cursor: pointer; display: flex; align-items: center; justify-content: space-between;
      gap: 8px; padding: 12px 14px; user-select: none;
    }}
    .sec-panel .sec-summary::-webkit-details-marker {{ display: none; }}
    .sec-tools {{
      display: flex; justify-content: flex-end; padding: 6px 12px 0; background: var(--brand-lighter);
    }}
    .linkish {{
      appearance: none; border: 0; background: none; color: var(--brand); font: inherit;
      font-size: .78rem; font-weight: 650; cursor: pointer; padding: 2px 0;
    }}
    .linkish:hover {{ text-decoration: underline; }}
    .sec-body {{
      padding: 8px 10px 10px;
      display: grid;
      gap: 8px;
      background: var(--brand-lighter);
    }}

    .modal {{
      border: 0; padding: 0; border-radius: 16px; width: min(760px, calc(100vw - 24px));
      max-height: min(82vh, 720px); box-shadow: 0 24px 60px rgba(26,26,46,.28);
      background: #fff; color: var(--ink);
    }}
    .modal::backdrop {{ background: rgba(26,26,46,.45); backdrop-filter: blur(2px); }}
    .modal-shell {{ display: flex; flex-direction: column; max-height: min(82vh, 720px); }}
    .modal-head {{
      display: flex; align-items: center; justify-content: space-between; gap: 10px;
      padding: 14px 16px; border-bottom: 1px solid var(--line);
      background: linear-gradient(135deg, #6b21a8 0%, #7c3aed 55%, #5b21b6 100%);
      color: #fff;
    }}
    .modal-head h2 {{ margin: 0; font-size: 1.05rem; font-weight: 750; }}
    .modal-x {{
      appearance: none; border: 0; background: rgba(255,255,255,.16); color: #fff;
      width: 32px; height: 32px; border-radius: 8px; cursor: pointer; font-size: 1.1rem; line-height: 1;
    }}
    .modal-x:hover {{ background: rgba(255,255,255,.28); }}
    .modal-tools {{
      display: flex; justify-content: space-between; align-items: center; gap: 8px;
      padding: 8px 16px; border-bottom: 1px solid var(--line); background: var(--brand-lighter);
    }}
    .modal-tools .hintish {{ font-size: .78rem; color: var(--muted); }}
    .modal-body {{
      padding: 12px 14px; overflow: auto; display: grid; gap: 8px;
      grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
      background: #faf8ff;
    }}
    .modal-foot {{
      display: flex; justify-content: flex-end; gap: 8px; padding: 12px 16px;
      border-top: 1px solid var(--line); background: #fff;
    }}
    .alert-modal {{
      border: 0; padding: 0; border-radius: 14px; width: min(420px, calc(100vw - 24px));
      box-shadow: 0 24px 60px rgba(26,26,46,.28); background: #fff; color: var(--ink);
    }}
    .alert-modal.config-modal,
    .alert-modal.success-modal {{ width: min(560px, calc(100vw - 24px)); }}
    .alert-modal::backdrop {{ background: rgba(26,26,46,.4); }}
    .alert-shell {{ padding: 18px 18px 14px; display: grid; gap: 10px; }}
    .alert-shell h2 {{ margin: 0; font-size: 1.02rem; font-weight: 750; color: var(--brand-purple); }}
    .alert-shell p {{ margin: 0; font-size: .9rem; color: #4b5563; line-height: 1.45; }}
    .alert-actions {{ display: flex; justify-content: flex-end; gap: 8px; margin-top: 4px; }}
    .config-form {{ display: grid; gap: 10px; }}
    .config-form label {{ display: grid; gap: 4px; font-size: .78rem; font-weight: 650; color: #344054; }}
    .config-form input {{
      font: inherit; font-size: .88rem; border: 1px solid var(--line); border-radius: 8px;
      padding: 8px 10px; background: #fff; color: var(--ink);
    }}
    .config-form input:focus {{ outline: 2px solid #c4b5fd; border-color: var(--brand); }}
    .config-form .hint {{ font-size: .75rem; font-weight: 500; color: var(--muted); }}
    .config-form .check-row {{
      display: flex; align-items: flex-start; gap: 10px;
      font-size: .84rem; font-weight: 600; color: #344054;
      border: 1px solid var(--line); border-radius: 10px; padding: 10px 12px;
      background: #faf8ff;
    }}
    .config-form .check-row input {{ width: auto; margin-top: 2px; flex-shrink: 0; }}
    .config-form .check-row .check-copy {{ display: grid; gap: 3px; }}
    .config-form .check-row .check-copy strong {{ font-size: .86rem; color: var(--brand-purple); }}
    .config-form .check-row .check-copy span {{ font-size: .75rem; font-weight: 500; color: var(--muted); line-height: 1.35; }}
    .config-error {{
      display: none; font-size: .8rem; color: #b42318; background: #fef3f2;
      border: 1px solid #fecdca; border-radius: 8px; padding: 8px 10px;
    }}
    .config-error.show {{ display: block; }}
    .cmd-box {{ display: none; grid-gap: 8px; }}
    .cmd-box.show {{ display: grid; }}
    .cmd-row {{
      border: 1px solid var(--line); border-radius: 10px; background: #f8fafc; overflow: hidden;
    }}
    .cmd-row header {{
      display: flex; align-items: center; justify-content: space-between; gap: 8px;
      padding: 6px 10px; border-bottom: 1px solid var(--line); background: #fff;
    }}
    .cmd-row header span {{ font-size: .75rem; font-weight: 700; color: #344054; }}
    .cmd-row pre {{
      margin: 0; padding: 10px; font-size: .76rem; line-height: 1.4; overflow: auto;
      white-space: pre-wrap; word-break: break-word; color: #1a1a2e;
    }}
    .copy-cmd {{
      appearance: none; border: 1px solid var(--line); background: #fff; border-radius: 7px;
      padding: 4px 8px; font: inherit; font-size: .72rem; font-weight: 650; cursor: pointer; color: var(--brand);
    }}
    .copy-cmd:hover {{ background: var(--brand-lighter); }}

    .skill {{
      border: 1px solid var(--line); border-radius: 10px; background: #fff; padding: 10px 10px 10px 8px;
      display: grid; grid-template-columns: auto 1fr; gap: 8px; align-items: start; cursor: pointer;
    }}
    .skill:hover {{ border-color: #ddd6fe; background: var(--brand-lighter); }}
    .skill:has(.skill-check:checked) {{ border-color: #c4b5fd; background: var(--brand-soft); }}
    .skill[hidden] {{ display: none !important; }}
    .skill-check {{ width: 15px; height: 15px; margin-top: 2px; accent-color: var(--brand); }}
    .skill-body {{ display: grid; gap: 4px; min-width: 0; }}
    .skill-top {{ display: flex; flex-wrap: wrap; align-items: center; gap: 6px; }}
    .skill-title {{ font-size: .9rem; font-weight: 700; letter-spacing: -.01em; line-height: 1.25; }}
    .core-badge {{
      display: inline-flex; align-items: center; font-size: .66rem; font-weight: 800; letter-spacing: .04em;
      text-transform: uppercase; color: #fff; background: var(--brand); border: 1px solid var(--brand-dark);
      border-radius: 999px; padding: 1px 6px;
    }}
    .desc {{ color: #4b5563; font-size: .82rem; line-height: 1.4; }}

    .guide-box,
    .request-box {{
      margin-top: 12px; background: var(--panel); border: 1px solid var(--line); border-radius: 12px;
      box-shadow: var(--shadow); overflow: hidden;
    }}
    .guide-box {{ margin-top: 14px; margin-bottom: 10px; border-color: #ddd6fe; }}
    .guide-box > summary,
    .request-box > summary {{
      list-style: none; cursor: pointer; display: flex; align-items: center; justify-content: space-between;
      gap: 10px; padding: 11px 14px; user-select: none; background: #f8fafc;
    }}
    .guide-box > summary {{ background: var(--brand-lighter); }}
    .guide-box > summary::-webkit-details-marker,
    .request-box > summary::-webkit-details-marker {{ display: none; }}
    .guide-box > summary:hover,
    .request-box > summary:hover {{ background: #f1f5f9; }}
    .guide-box[open] > summary,
    .request-box[open] > summary {{ border-bottom: 1px solid var(--line); background: #fff; }}
    .guide-summary-text,
    .request-summary-text {{ display: grid; gap: 2px; min-width: 0; }}
    .guide-summary-text strong,
    .request-summary-text strong {{ font-size: .92rem; font-weight: 750; }}
    .guide-summary-text span,
    .request-summary-text span {{ font-size: .8rem; color: var(--muted); }}
    .guide-body,
    .request-body {{ padding: 12px 14px 14px; }}
    .guide-body {{ display: grid; gap: 12px; }}
    .guide-steps {{
      margin: 0; padding-left: 1.15rem; display: grid; gap: 8px; font-size: .86rem; color: #374151;
    }}
    .guide-steps li {{ padding-left: 2px; }}
    .guide-steps code {{
      font-size: .78rem; background: #f3f0fa; border: 1px solid #e7e0f6; border-radius: 5px;
      padding: 1px 5px; color: var(--brand-deep);
    }}
    .guide-disclaimer {{
      border: 1px solid #fde68a; background: #fffbeb; border-radius: 10px; padding: 10px 12px;
      font-size: .82rem; color: #78350f;
    }}
    .guide-disclaimer strong {{ display: block; margin-bottom: 4px; color: #92400e; font-size: .8rem; letter-spacing: .02em; text-transform: uppercase; }}
    .guide-disclaimer ul {{ margin: 4px 0 0; padding-left: 1.1rem; display: grid; gap: 3px; }}
    .guide-note {{ font-size: .8rem; color: var(--muted); margin: 0; }}
    .request-form {{
      display: grid; grid-template-columns: 1fr 1fr; gap: 8px 10px; max-width: 820px;
    }}
    .request-form label {{ display: grid; gap: 3px; font-size: .76rem; font-weight: 650; color: #344054; }}
    .request-form .span-2 {{ grid-column: 1 / -1; }}
    .request-form input, .request-form textarea, .request-form select {{
      font: inherit; font-size: .85rem; border: 1px solid var(--line); border-radius: 8px;
      padding: 7px 9px; background: #fff; color: var(--ink);
    }}
    .request-form textarea {{ min-height: 64px; resize: vertical; }}
    .request-form input:focus, .request-form textarea:focus, .request-form select:focus {{
      outline: 2px solid #c4b5fd; border-color: var(--brand);
    }}
    .request-actions {{ display: flex; flex-wrap: wrap; gap: 8px; align-items: center; }}
    .request-note {{ font-size: .78rem; color: var(--muted); }}
    @media (max-width: 640px) {{
      .request-form {{ grid-template-columns: 1fr; }}
      .request-form .span-2 {{ grid-column: auto; }}
    }}
    .empty {{ display: none; color: var(--muted); font-size: .9rem; margin: 8px 0 14px; }}
    .empty.show {{ display: block; }}

    @media (max-width: 980px) {{
      .catalog-grid {{ column-count: 2; }}
    }}
    @media (max-width: 640px) {{
      .catalog-grid {{ column-count: 1; }}
      .toolbar {{ position: static; }}
    }}
  </style>
</head>
<body>
  <div class="wrap">
    <header class="topbar">
      <div class="brand">
        <h1><span>GPTfy</span> Agentic Skills</h1>
        <span class="meta">111 skills · pick &amp; download</span>
      </div>
    </header>

    <div class="toolbar">
      <input id="q" class="search" type="search" placeholder="Search skills, API names, or use cases…" />
      <button type="button" class="btn" id="clearSel">Clear</button>
      <span class="count-pill"><span id="selCount">0</span> selected · <span id="visCount">0</span> shown</span>
      <button type="button" class="btn primary" id="downloadSel" disabled>Download selected</button>
      <span class="status" id="status"></span>
    </div>
    <div class="empty" id="empty">No skills match your search.</div>

    <div class="featured-band">
{recommended}
    </div>

    <div class="catalog-grid" id="catalog">
{chr(10).join(panels)}
    </div>

    <dialog class="modal" id="skillModal" aria-labelledby="modalTitle">
      <div class="modal-shell">
        <div class="modal-head">
          <h2 id="modalTitle">Category</h2>
          <button type="button" class="modal-x" id="modalClose" aria-label="Close">×</button>
        </div>
        <div class="modal-tools">
          <span class="hintish">Select skills, then close — download from the toolbar</span>
          <button type="button" class="linkish" id="modalSelectAll">Select all in category</button>
        </div>
        <div class="modal-body" id="modalBody"></div>
        <div class="modal-foot">
          <button type="button" class="btn" id="modalDone">Done</button>
        </div>
      </div>
    </dialog>

    <dialog class="alert-modal success-modal" id="alertModal" aria-labelledby="alertTitle">
      <div class="alert-shell">
        <h2 id="alertTitle">Download complete</h2>
        <p id="alertMessage">Your skill package is ready.</p>
        <div class="cmd-box" id="cmdBox">
          <div class="cmd-row">
            <header>
              <span>Quick install (PowerShell) — unzip first, then run</span>
              <button type="button" class="copy-cmd" data-copy="cmdPs">Copy</button>
            </header>
            <pre id="cmdPs"></pre>
          </div>
          <div class="cmd-row">
            <header>
              <span>Or step-by-step CLI</span>
              <button type="button" class="copy-cmd" data-copy="cmdCli">Copy</button>
            </header>
            <pre id="cmdCli"></pre>
          </div>
        </div>
        <div class="alert-actions">
          <button type="button" class="btn" id="alertCancel">Cancel</button>
          <button type="button" class="btn primary" id="alertOk">OK</button>
        </div>
      </div>
    </dialog>

    <dialog class="alert-modal config-modal" id="configModal" aria-labelledby="configTitle">
      <form class="alert-shell config-form" id="configForm">
        <h2 id="configTitle">Prepare download</h2>
        <p>Enter your org’s GPTfy Ids. We’ll add them to the package and include a one-click install script plus ready-to-copy commands. Leave CLI alias blank to deploy to the org already connected in VS Code / Salesforce CLI.</p>
        <div class="config-error" id="configError"></div>
        <label>Data Extraction Mapping Id
          <input id="cfgMapping" name="mapping" required autocomplete="off" spellcheck="false"
            placeholder="15 or 18 character Salesforce Id" />
          <span class="hint">From ccai__AI_Data_Extraction_Mapping__c</span>
        </label>
        <label>AI Connection Id
          <input id="cfgConnection" name="connection" required autocomplete="off" spellcheck="false"
            placeholder="15 or 18 character Salesforce Id" />
          <span class="hint">From ccai__AI_Connection__c (model)</span>
        </label>
        <label>Agent Name
          <input id="cfgAgent" name="agent" required autocomplete="off"
            placeholder="Your existing GPTfy agent name" value="GPTfy Agent" />
          <span class="hint">Must match the agent Name in your org</span>
        </label>
        <label>CLI org alias (optional)
          <input id="cfgOrgAlias" name="orgAlias" autocomplete="off"
            placeholder="Leave blank = use default connected org" />
          <span class="hint">Blank uses the org already connected in VS Code / Salesforce CLI. Set only if you need a specific alias from <code>sf org list</code>.</span>
        </label>
        <label class="check-row">
          <input type="checkbox" id="cfgUpdatePrompt" name="updatePrompt" />
          <span class="check-copy">
            <strong>Update agent system prompt</strong>
            <span>Builds one prompt from your selected skills (base rules + only those skills) and overwrites the agent’s system prompt on install. Leave off to keep your current agent prompt.</span>
          </span>
        </label>
        <div class="alert-actions">
          <button type="button" class="btn" id="configCancel">Cancel</button>
          <button type="submit" class="btn primary" id="configContinue">Download package</button>
        </div>
      </form>
    </dialog>

    <details class="guide-box">
      <summary>
        <span class="guide-summary-text">
          <strong>After download — what to do next</strong>
          <span>Exact install steps + what gets added to your org</span>
        </span>
        <span class="chev" aria-hidden="true"></span>
      </summary>
      <div class="guide-body">
        <ol class="guide-steps">
          <li><strong>Unzip</strong> the download package.</li>
          <li><strong>Prerequisites:</strong> GPTfy installed; Salesforce CLI (<code>sf</code>) with a default org in VS Code/CLI, <em>or</em> Workbench logged into the target org.</li>
          <li><strong>Org values:</strong> enter Mapping Id, Connection Id, Agent Name in the download dialog (Ids go into the install scripts). CLI org alias is optional — leave blank to deploy to the default connected org.</li>
          <li><strong>Fastest path (CLI / VS Code):</strong> unzip, then run <code>install.ps1</code> (Windows) or <code>install.sh</code> (Mac/Linux). It uses your default org unless you pass an alias.</li>
          <li><strong>Workbench path:</strong> login to the target org in Workbench → Migration → Deploy (Apex package) → Utilities → Apex Execute (paste each install script). No CLI alias needed.</li>
          <li><strong>Manual CLI — Deploy Apex once:</strong>
            <br /><code>sf project deploy start --manifest package.xml</code>
            <br />(add <code>--target-org &lt;alias&gt;</code> only if not using the default org)
          </li>
          <li><strong>Manual CLI — Register skills</strong> (creates skill prompts and links them to your agent):
            <br />Single skill: <code>sf apex run --file seed.apex</code>
            <br />Multi-skill: run once per script under <code>skills/*/seed.apex</code>.</li>
          <li><strong>System prompt:</strong> the package always includes a <em>composed</em> <code>sample-system-prompt.txt</code> for the skills you selected. Turn on <strong>Update agent system prompt</strong> in the download dialog if you want install to overwrite the agent field automatically (replaces existing prompt).</li>
          <li><strong>Optional manual:</strong> paste <code>sample-system-prompt.txt</code> into the agent in GPTfy if you left the toggle off.</li>
        </ol>
        <div class="guide-disclaimer">
          <strong>Disclaimer — what import adds</strong>
          <ul>
            <li><strong>Mostly GPTfy configuration</strong>: skill prompt records and links to your agent.</li>
            <li>Uses the agent name you entered (creates that agent only if it does not already exist).</li>
            <li><strong>Apex classes</strong> for the skill handlers — code, not CRM business data (no Accounts, Contacts, etc.).</li>
            <li>Mapping and Connection Ids are org-specific; the download dialog fills them for <em>this</em> org.</li>
            <li>Safe to re-run: existing skills are skipped; missing agent links are added.</li>
          </ul>
        </div>
        <p class="guide-note">The package README has the same steps for offline use.</p>
      </div>
    </details>

    <details class="request-box">
      <summary>
        <span class="request-summary-text">
          <strong id="request-title">Request a new skill</strong>
          <span>Missing something? Click to send a request to GPTfy</span>
        </span>
        <span class="chev" aria-hidden="true"></span>
      </summary>
      <div class="request-body">
        <form class="request-form" id="requestForm">
          <label>Your name
            <input type="text" name="name" autocomplete="name" required placeholder="Jane Smith" />
          </label>
          <label>Work email
            <input type="email" name="email" autocomplete="email" required placeholder="jane@company.com" />
          </label>
          <label>Skill title
            <input type="text" name="title" required placeholder="e.g. Fetch contract renewal risk" />
          </label>
          <label>Object / area
            <select name="area" required>
              <option value="">Select…</option>
              <option>Account</option>
              <option>Contact</option>
              <option>Lead</option>
              <option>Opportunity</option>
              <option>Case</option>
              <option>Task / Event</option>
              <option>Campaign</option>
              <option>Utility / Cross-object</option>
              <option>Other</option>
            </select>
          </label>
          <label class="span-2">What should this skill do?
            <textarea name="details" required placeholder="Use case, inputs, and expected Salesforce outcome."></textarea>
          </label>
          <div class="request-actions span-2">
            <button type="submit" class="btn primary">Email request to GPTfy</button>
            <span class="request-note">Opens email to support@gptfy.ai</span>
          </div>
        </form>
      </div>
    </details>
  </div>
  <script>
    const SKILL_META = /*__SKILL_META__*/null;
    const q = document.getElementById('q');
    const statusEl = document.getElementById('status');
    const emptyEl = document.getElementById('empty');
    const selCount = document.getElementById('selCount');
    const visCount = document.getElementById('visCount');
    const downloadSel = document.getElementById('downloadSel');
    const modal = document.getElementById('skillModal');
    const modalTitle = document.getElementById('modalTitle');
    const modalBody = document.getElementById('modalBody');
    const alertModal = document.getElementById('alertModal');
    const alertTitle = document.getElementById('alertTitle');
    const alertMessage = document.getElementById('alertMessage');
    const tiles = [...document.querySelectorAll('.sec-tile')];
    const panels = [...document.querySelectorAll('.sec-panel')];
    let activeStore = null;

    let clearSelectionOnAlertClose = false;
    const cmdBox = document.getElementById('cmdBox');
    const cmdPs = document.getElementById('cmdPs');
    const cmdCli = document.getElementById('cmdCli');

    function showAlert(title, message, {{ clearSelection = false, commands = null }} = {{}}) {{
      statusEl.textContent = '';
      clearSelectionOnAlertClose = !!clearSelection;
      alertTitle.textContent = title;
      alertMessage.textContent = message;
      if (commands && commands.ps && commands.cli) {{
        cmdPs.textContent = commands.ps;
        cmdCli.textContent = commands.cli;
        cmdBox.classList.add('show');
      }} else {{
        cmdPs.textContent = '';
        cmdCli.textContent = '';
        cmdBox.classList.remove('show');
      }}
      if (!alertModal.open) alertModal.showModal();
    }}
    function clearAllSelections() {{
      document.querySelectorAll('.skill-check').forEach(el => {{ el.checked = false; }});
      refreshCounts();
    }}
    function closeAlert() {{
      if (alertModal.open) alertModal.close();
      statusEl.textContent = '';
      cmdBox.classList.remove('show');
      if (clearSelectionOnAlertClose) {{
        clearSelectionOnAlertClose = false;
        clearAllSelections();
      }}
    }}
    document.getElementById('alertCancel').addEventListener('click', closeAlert);
    document.getElementById('alertOk').addEventListener('click', closeAlert);
    alertModal.addEventListener('cancel', (e) => {{ e.preventDefault(); closeAlert(); }});
    alertModal.addEventListener('click', (e) => {{
      if (e.target === alertModal) closeAlert();
    }});
    document.querySelectorAll('.copy-cmd').forEach(btn => {{
      btn.addEventListener('click', async () => {{
        const id = btn.getAttribute('data-copy');
        const el = id ? document.getElementById(id) : null;
        if (!el || !el.textContent) return;
        try {{
          await navigator.clipboard.writeText(el.textContent);
          const prev = btn.textContent;
          btn.textContent = 'Copied';
          setTimeout(() => {{ btn.textContent = prev; }}, 1200);
        }} catch (_) {{
          const range = document.createRange();
          range.selectNodeContents(el);
          const sel = window.getSelection();
          sel.removeAllRanges();
          sel.addRange(range);
        }}
      }});
    }});

    function allSkills() {{
      return [...document.querySelectorAll('.skill')];
    }}

    function selectedNames() {{
      // Unique by API name — Top Picks duplicates home-category cards
      return [...new Set(
        [...document.querySelectorAll('.skill-check:checked')].map(el => el.value)
      )];
    }}

    function selectedInNodes(nodes) {{
      const names = new Set();
      nodes.forEach(card => {{
        const cb = card.querySelector('.skill-check');
        if (cb && cb.checked) names.add(cb.value);
      }});
      return names.size;
    }}

    function visibleSkillNames() {{
      const names = new Set();
      allSkills().forEach(card => {{
        if (!card.hidden && card.dataset.name) names.add(card.dataset.name);
      }});
      return names;
    }}

    function syncChecks(name, checked) {{
      document.querySelectorAll('.skill-check').forEach(cb => {{
        if (cb.value === name) cb.checked = checked;
      }});
    }}

    function refreshTileSelection(tile) {{
      const n = selectedInNodes(skillsForTile(tile));
      const badge = tile.querySelector('.sec-selected');
      if (badge) {{
        badge.textContent = n === 1 ? '1 selected' : n + ' selected';
        badge.hidden = n === 0;
      }}
      tile.classList.toggle('has-selection', n > 0);
    }}

    function refreshCounts() {{
      const selected = selectedNames().length;
      const visible = visibleSkillNames().size;
      selCount.textContent = String(selected);
      visCount.textContent = String(visible);
      downloadSel.disabled = selected === 0;
      emptyEl.classList.toggle('show', visible === 0);
      tiles.forEach(refreshTileSelection);
    }}

    function closeModal() {{
      if (activeStore) {{
        while (modalBody.firstChild) activeStore.appendChild(modalBody.firstChild);
        activeStore = null;
      }}
      if (modal.open) modal.close();
      refreshCounts();
    }}

    function openTile(tile) {{
      closeModal();
      const store = tile.querySelector('.sec-store');
      if (!store) return;
      activeStore = store;
      modalTitle.textContent = tile.dataset.section || 'Skills';
      while (store.firstChild) modalBody.appendChild(store.firstChild);
      modal.showModal();
    }}

    function skillsForTile(tile) {{
      if (activeStore && tile.querySelector('.sec-store') === activeStore) {{
        return [...modalBody.querySelectorAll('.skill')];
      }}
      return [...tile.querySelectorAll('.skill')];
    }}

    function applyFilter() {{
      const term = (q.value || '').trim().toLowerCase();
      allSkills().forEach(card => {{
        const hay = card.dataset.search || '';
        card.hidden = term !== '' && !hay.includes(term);
      }});
      tiles.forEach(tile => {{
        tile.hidden = !skillsForTile(tile).some(s => !s.hidden);
      }});
      panels.forEach(panel => {{
        panel.hidden = ![...panel.querySelectorAll('.skill')].some(s => !s.hidden);
      }});
      refreshCounts();
    }}

    q.addEventListener('input', applyFilter);
    document.addEventListener('change', (e) => {{
      if (!e.target.classList.contains('skill-check')) return;
      syncChecks(e.target.value, e.target.checked);
      refreshCounts();
    }});

    tiles.forEach(tile => {{
      tile.querySelector('.sec-open').addEventListener('click', () => openTile(tile));
    }});
    document.getElementById('modalClose').addEventListener('click', closeModal);
    document.getElementById('modalDone').addEventListener('click', closeModal);
    modal.addEventListener('cancel', (e) => {{ e.preventDefault(); closeModal(); }});
    modal.addEventListener('click', (e) => {{
      if (e.target === modal) closeModal();
    }});
    document.getElementById('modalSelectAll').addEventListener('click', () => {{
      modalBody.querySelectorAll('.skill').forEach(card => {{
        if (!card.hidden) {{
          const cb = card.querySelector('.skill-check');
          if (cb) syncChecks(cb.value, true);
        }}
      }});
      refreshCounts();
    }});

    document.getElementById('clearSel').addEventListener('click', () => {{
      document.querySelectorAll('.skill-check').forEach(el => {{ el.checked = false; }});
      refreshCounts();
    }});

    function classMembersXml(classNames) {{
      const members = [...classNames].sort().map(n => '        <members>' + n + '</members>').join('\\n');
      return [
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<Package xmlns="http://soap.sforce.com/2006/04/metadata">',
        '    <types>',
        members,
        '        <name>ApexClass</name>',
        '    </types>',
        '    <version>66.0</version>',
        '</Package>',
        ''
      ].join('\\n');
    }}

    function testsForSkills(names) {{
      const t = new Set(['AgenticSkillsBaseTest']);
      names.forEach(n => {{
        const h = SKILL_META && SKILL_META[n] && SKILL_META[n].h;
        if (h) t.add(h + 'Test');
      }});
      return [...t].sort();
    }}

    const CONFIG_KEY = 'gptfyCatalogOrgConfig';
    const configModal = document.getElementById('configModal');
    const configForm = document.getElementById('configForm');
    const configError = document.getElementById('configError');
    const cfgMapping = document.getElementById('cfgMapping');
    const cfgConnection = document.getElementById('cfgConnection');
    const cfgAgent = document.getElementById('cfgAgent');
    const cfgOrgAlias = document.getElementById('cfgOrgAlias');
    const cfgUpdatePrompt = document.getElementById('cfgUpdatePrompt');

    function isSalesforceId(value) {{
      return /^[a-zA-Z0-9]{{15}}$/.test(value) || /^[a-zA-Z0-9]{{18}}$/.test(value);
    }}

    function sanitizeOrgAlias(value) {{
      const cleaned = String(value || '').trim().replace(/[^a-zA-Z0-9._-]/g, '');
      return cleaned || '';
    }}

    function loadSavedConfig() {{
      try {{
        const raw = localStorage.getItem(CONFIG_KEY);
        if (!raw) return;
        const saved = JSON.parse(raw);
        if (saved.mapping) cfgMapping.value = saved.mapping;
        if (saved.connection) cfgConnection.value = saved.connection;
        if (saved.agent) cfgAgent.value = saved.agent;
        if (saved.orgAlias) cfgOrgAlias.value = saved.orgAlias;
        if (typeof saved.updateSystemPrompt === 'boolean') cfgUpdatePrompt.checked = saved.updateSystemPrompt;
      }} catch (_) {{}}
    }}

    function saveConfig(cfg) {{
      try {{
        localStorage.setItem(CONFIG_KEY, JSON.stringify(cfg));
      }} catch (_) {{}}
    }}

    function escapeApexString(value) {{
      return String(value).replace(/\\\\/g, '\\\\\\\\').replace(/'/g, "\\\\'");
    }}

    function patchSeed(text, cfg) {{
      let out = text;
      out = out.replace(
        /final String AGENT_NAME = '[^']*';/,
        "final String AGENT_NAME = '" + escapeApexString(cfg.agent) + "';"
      );
      out = out.replace(
        /final String DATA_MAPPING = '[^']*';/,
        "final String DATA_MAPPING = '" + escapeApexString(cfg.mapping) + "';"
      );
      out = out.replace(
        /final String AI_MODEL = '[^']*';/,
        "final String AI_MODEL = '" + escapeApexString(cfg.connection) + "';"
      );
      return out;
    }}

    function composeSystemPrompt(names) {{
      const mut = names.filter(n => SKILL_META && SKILL_META[n] && SKILL_META[n].m);
      const read = names.filter(n => !mut.includes(n));
      const lines = [];
      lines.push('You are a CRM Assistant embedded in Salesforce via GPTfy. Help users manage Salesforce records safely using only the skills listed in this prompt. Confirm every mutation before calling a mutating skill. Never invent skill names, record Ids, picklist values, or success.');
      lines.push('');
      lines.push('RESPONSE STYLE');
      lines.push('Be concise and businesslike. Summarise clearly. Always include record links after successful actions. Never claim success without skill confirmation. Never expose internal Ids unless asked. Never open with filler. Prefer short declarative sentences.');
      lines.push('');
      lines.push('Out of scope: if the request cannot use any skill listed below, say so and offer the closest supported action. Do not invent capabilities.');
      lines.push('');
      lines.push('RULE 1 - SKILLS ON THIS AGENT (source of truth)');
      lines.push('Use only these skills. Never invent a skill name that is not listed here.');
      lines.push('');
      names.forEach(n => {{
        const m = (SKILL_META && SKILL_META[n]) || {{ d: n, m: false }};
        const tag = m.m ? ' [MUTATING - confirm first]' : ' [read/lookup]';
        lines.push('- ' + n + tag + ' - ' + (m.d || n));
      }});
      lines.push('');
      lines.push('Skill response handling:');
      lines.push('- JSON success:false -> show error friendly. Stop.');
      lines.push('- Raw HTML -> display to the user as-is.');
      lines.push('- JSON success:true for searches -> use records; only show lists when user asked to find/list.');
      lines.push('- Never output raw JSON to the user.');
      lines.push('');
      lines.push('RULE 2 - KNOW WHICH RECORD');
      lines.push('Before update, activity, or detail fetch, confirm the record Id:');
      lines.push('1) Record page context Id if present - use it directly.');
      lines.push('2) Already confirmed in conversation.');
      lines.push('3) Name hint -> matching fuzzy_search_* if that skill is listed above.');
      lines.push('4) Otherwise ask for the record name.');
      lines.push('Never invent Ids. Prefer _id parameters when you have an Id.');
      lines.push('');
      lines.push('RULE 3 - CONFIRM BEFORE CHANGING DATA');
      if (mut.length) {{
        lines.push('BEFORE calling any mutating skill, show a confirmation card and wait for explicit yes/confirm/go ahead. Never assume yes.');
        lines.push('');
        lines.push('Mutating skills on this agent (require confirmation):');
        mut.forEach(n => lines.push('- ' + n));
        lines.push('');
        lines.push('Confirmation formats:');
        lines.push('UPDATE: **[Record Name]** then Field - **current** -> **new**, then Shall I proceed? (yes / no)');
        lines.push('CREATE: **Create new [Object]:** field list, then Shall I create this record? (yes / no)');
        lines.push('Other actions: **[Action] [Record]:** details, then Shall I proceed? (yes / no)');
        lines.push('');
        lines.push('Hard rules: one confirmation per mutation; ok/sure/maybe is NOT confirmation; re-confirm after interruption.');
      }} else {{
        lines.push('No mutating skills are installed on this package. Do not invent create/update/delete actions.');
      }}
      if (read.length) {{
        lines.push('');
        lines.push('Read/lookup skills (no confirmation):');
        read.forEach(n => lines.push('- ' + n));
      }}
      lines.push('');
      lines.push('RULE 4 - DATES, NUMBERS, PICKLISTS');
      lines.push('Resolve relative dates to yyyy-MM-dd before skills. Numbers without currency/commas. Booleans true/false. Datetimes ISO 8601. Picklists = exact API values; if unsure and fetch_picklist_values is listed, call it first.');
      lines.push('');
      if (names.some(n => n.startsWith('fuzzy_search_'))) {{
        lines.push('RULE 5 - FUZZY SEARCH DISPLAY');
        lines.push('Use totalFound / displayed / remaining from the skill. Show up to 5 rows. If remaining > 0, say how many more exist and suggest refining. Include View Record links when provided. Never dump raw Id columns.');
        lines.push('');
      }}
      if (names.includes('run_internal_prompt')) {{
        lines.push('RULE 6 - run_internal_prompt');
        lines.push('For summary / 360 / meeting prep / drafts tied to a record: identify record (Rule 2), use configured promptRequestId (never invent Ids), call run_internal_prompt, display message verbatim.');
        lines.push('');
      }}
      if (names.includes('log_activity') || names.some(n => n.includes('task') || n.includes('event'))) {{
        lines.push('RULE 7 - ACTIVITY');
        lines.push('For log_activity / tasks / events: parent record Id first; if subject missing, ask for it; then confirm (Rule 3) before mutating.');
        lines.push('');
      }}
      lines.push('AFTER SUCCESSFUL MUTATIONS');
      lines.push('Show skill HTML verbatim, then one short plain-language Done sentence. No raw JSON.');
      lines.push('');
      lines.push('<!-- GPTFY_SKILLS_END -->');
      lines.push('');
      return lines.join('\\n');
    }}

    function buildInstallScripts(names, orgAlias, applySystemPrompt) {{
      const alias = (orgAlias || '').replace(/"/g, '');
      const isMulti = names.length > 1;
      const applyFlag = applySystemPrompt ? '$true' : '$false';
      const applyDefault = applySystemPrompt ? '1' : '0';
      const psRegister = isMulti
        ? [
            'Get-ChildItem -Path "skills" -Directory | ForEach-Object {{',
            '  $seed = Join-Path $_.FullName "seed.apex"',
            '  Write-Host ("Registering " + $_.Name + "...")',
            '  if ($OrgArgs.Count) {{ sf apex run --file $seed @OrgArgs }} else {{ sf apex run --file $seed }}',
            '  if ($LASTEXITCODE -ne 0) {{ exit $LASTEXITCODE }}',
            '}}'
          ].join('\\n')
        : [
            'Write-Host "Registering skill..."',
            'if ($OrgArgs.Count) {{ sf apex run --file seed.apex @OrgArgs }} else {{ sf apex run --file seed.apex }}',
            'if ($LASTEXITCODE -ne 0) {{ exit $LASTEXITCODE }}'
          ].join('\\n');
      const shRegister = isMulti
        ? [
            'for seed in skills/*/seed.apex; do',
            '  echo "Registering $seed..."',
            '  sf apex run --file "$seed" "${{ORG_ARGS[@]}}"',
            'done'
          ].join('\\n')
        : 'sf apex run --file seed.apex "${{ORG_ARGS[@]}}"';

      const applyHelperPy = [
        'import json, os, shutil, subprocess, sys',
        'from pathlib import Path',
        '',
        'def find_sf():',
        '    for name in ("sf", "sf.cmd", "sf.exe"):',
        '        p = shutil.which(name)',
        '        if p:',
        '            return p',
        '    print("Salesforce CLI (sf) not found on PATH", file=sys.stderr)',
        '    raise SystemExit(1)',
        '',
        'def run_sf(sf, args):',
        '    # shell=True on Windows so .cmd shims resolve reliably',
        '    use_shell = os.name == "nt"',
        '    cmd = [sf] + args',
        '    if use_shell:',
        '        # quote for cmd.exe',
        '        line = subprocess.list2cmdline(cmd)',
        '        return subprocess.run(line, shell=True, capture_output=True, text=True, encoding="utf-8", errors="replace")',
        '    return subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")',
        '',
        'root = Path(__file__).resolve().parent',
        'cfg = json.loads((root / "package-config.json").read_text(encoding="utf-8"))',
        'if not cfg.get("applySystemPrompt"):',
        '    print("Skip system prompt update (toggle was off).")',
        '    raise SystemExit(0)',
        'prompt_path = root / "sample-system-prompt.txt"',
        'if not prompt_path.exists():',
        '    print("sample-system-prompt.txt missing", file=sys.stderr)',
        '    raise SystemExit(1)',
        'agent_name = str(cfg.get("agent") or "").strip()',
        'if not agent_name:',
        '    print("Agent name missing in package-config.json", file=sys.stderr)',
        '    raise SystemExit(1)',
        'sf = find_sf()',
        'org = (os.environ.get("SF_TARGET_ORG") or "").strip()',
        'org_args = ["--target-org", org] if org else []',
        'safe = agent_name.replace(chr(39), chr(39) + chr(39))',
        'soql = "SELECT Id FROM ccai__AI_Agent__c WHERE Name = " + chr(39) + safe + chr(39) + " LIMIT 1"',
        'q = run_sf(sf, ["data", "query", "--query", soql, "--json"] + org_args)',
        'if q.returncode != 0:',
        '    print(q.stdout or q.stderr, file=sys.stderr)',
        '    raise SystemExit(q.returncode)',
        'raw = q.stdout or ""',
        'i = raw.find(chr(123))',
        'if i < 0:',
        '    print("No JSON from sf data query", file=sys.stderr)',
        '    raise SystemExit(1)',
        'data = json.loads(raw[i:])',
        'recs = (data.get("result") or data).get("records") or []',
        'if not recs:',
        '    print("Agent not found: " + agent_name, file=sys.stderr)',
        '    raise SystemExit(1)',
        'agent_id = recs[0]["Id"]',
        'body = {{"ccai__System_Prompt__c": prompt_path.read_text(encoding="utf-8")}}',
        'body_path = root / "sysprompt_body.json"',
        'body_path.write_text(json.dumps(body, ensure_ascii=False), encoding="utf-8")',
        'endpoint = "/services/data/v66.0/sobjects/ccai__AI_Agent__c/" + agent_id',
        'patch = run_sf(sf, ["api", "request", "rest", "--method", "PATCH", endpoint,',
        '    "--body", "@" + str(body_path), "--header", "Content-Type: application/json"] + org_args)',
        'print(patch.stdout or "")',
        'if patch.returncode != 0:',
        '    print(patch.stderr or "", file=sys.stderr)',
        '    raise SystemExit(patch.returncode)',
        'print("System prompt updated for agent " + agent_name + " (" + agent_id + ")")',
        ''
      ].join('\\n');

      // Pure PowerShell path preferred on Windows (same PATH as sf deploy / apex run)
      const psApply = [
        'if ($ApplySystemPrompt -and (Test-Path (Join-Path $PSScriptRoot "sample-system-prompt.txt"))) {{',
        '  Write-Host "Updating agent system prompt..."',
        '  $cfgPath = Join-Path $PSScriptRoot "package-config.json"',
        '  if (-not (Test-Path $cfgPath)) {{ Write-Error "package-config.json missing"; exit 1 }}',
        '  $pkg = Get-Content $cfgPath -Raw -Encoding UTF8 | ConvertFrom-Json',
        '  $agentName = [string]$pkg.agent',
        '  $sq = [string][char]39',
        '  $escaped = $agentName.Replace($sq, ($sq + $sq))',
        '  $soql = "SELECT Id FROM ccai__AI_Agent__c WHERE Name = " + $sq + $escaped + $sq + " LIMIT 1"',
        '  if ($OrgArgs.Count) {{ $qjson = sf data query --query $soql --json @OrgArgs | Out-String }} else {{ $qjson = sf data query --query $soql --json | Out-String }}',
        '  if ($LASTEXITCODE -ne 0) {{ exit $LASTEXITCODE }}',
        '  $qobj = $qjson | ConvertFrom-Json',
        '  $recs = @()',
        '  if ($qobj.result -and $qobj.result.records) {{ $recs = @($qobj.result.records) }}',
        '  elseif ($qobj.records) {{ $recs = @($qobj.records) }}',
        '  if ($recs.Count -lt 1) {{ Write-Error "Agent not found: $agentName"; exit 1 }}',
        '  $agentId = $recs[0].Id',
        '  $promptText = [System.IO.File]::ReadAllText((Join-Path $PSScriptRoot "sample-system-prompt.txt"))',
        '  $bodyPath = Join-Path $PSScriptRoot "sysprompt_body.json"',
        '  $bodyObj = [ordered]@{{ ccai__System_Prompt__c = $promptText }}',
        '  $bodyJson = $bodyObj | ConvertTo-Json -Depth 5 -Compress',
        '  [System.IO.File]::WriteAllText($bodyPath, $bodyJson, [System.Text.UTF8Encoding]::new($false))',
        '  $endpoint = "/services/data/v66.0/sobjects/ccai__AI_Agent__c/$agentId"',
        '  if ($OrgArgs.Count) {{',
        '    sf api request rest --method PATCH $endpoint --body ("@" + $bodyPath) --header "Content-Type: application/json" @OrgArgs',
        '  }} else {{',
        '    sf api request rest --method PATCH $endpoint --body ("@" + $bodyPath) --header "Content-Type: application/json"',
        '  }}',
        '  if ($LASTEXITCODE -ne 0) {{ exit $LASTEXITCODE }}',
        '  Write-Host "System prompt updated for agent $agentName ($agentId)"',
        '}}'
      ].join('\\n');

      const shApply = [
        'if [[ "${{APPLY_SYSTEM_PROMPT}}" == "1" ]]; then',
        '  echo "Updating agent system prompt..."',
        '  if [[ -n "$TARGET_ORG" ]]; then export SF_TARGET_ORG="$TARGET_ORG"; else unset SF_TARGET_ORG || true; fi',
        '  python3 apply_system_prompt.py || python apply_system_prompt.py',
        'fi'
      ].join('\\n');

      const psDefault = alias ? alias : '';
      const testNames = testsForSkills(names);
      const testJoin = testNames.join(', ');
      const sfTestFlags = testNames.map(t => '--tests ' + t).join(' ');
      const ps = [
        '# GPTfy skill install - deploy Apex + register skill(s) on your agent',
        '# Omit -TargetOrg to use the default CLI / VS Code connected org.',
        '# Use -RunTests for production deploys (RunSpecifiedTests).',
        'param(',
        '  [string]$TargetOrg = "' + psDefault + '",',
        '  [bool]$ApplySystemPrompt = ' + applyFlag + ',',
        '  [switch]$RunTests',
        ')',
        '$ErrorActionPreference = "Stop"',
        'Set-Location $PSScriptRoot',
        'if ($TargetOrg) {{',
        '  $OrgArgs = @("--target-org", $TargetOrg)',
        '  Write-Host "Target org: $TargetOrg"',
        '}} else {{',
        '  $OrgArgs = @()',
        '  Write-Host "Using default CLI / VS Code connected org (no alias)..."',
        '}}',
        'Write-Host "Deploying Apex..."',
        'if ($RunTests) {{',
        '  Write-Host "Running tests: ' + testJoin + '"',
        '  if ($OrgArgs.Count) {{ sf project deploy start --manifest package.xml --test-level RunSpecifiedTests ' + sfTestFlags + ' @OrgArgs }} else {{ sf project deploy start --manifest package.xml --test-level RunSpecifiedTests ' + sfTestFlags + ' }}',
        '}} else {{',
        '  if ($OrgArgs.Count) {{ sf project deploy start --manifest package.xml @OrgArgs }} else {{ sf project deploy start --manifest package.xml }}',
        '}}',
        'if ($LASTEXITCODE -ne 0) {{ exit $LASTEXITCODE }}',
        psRegister,
        psApply,
        'Write-Host "Done. Verify the skill(s) on your agent in GPTfy."',
        ''
      ].join('\\n');

      const sh = [
        '#!/usr/bin/env bash',
        '# GPTfy skill install - deploy Apex + register skill(s) on your agent',
        '# Optional arg 1: org alias. Omit to use default CLI / VS Code org.',
        '# Optional arg 2: 1 apply system prompt, 0 skip (default baked into package).',
        '# Optional: RUN_TESTS=1 ./install.sh   (RunSpecifiedTests)',
        'set -euo pipefail',
        'cd "$(dirname "$0")"',
        'TARGET_ORG="${{1:-' + psDefault + '}}"',
        'APPLY_SYSTEM_PROMPT="${{2:-' + applyDefault + '}}"',
        'RUN_TESTS="${{RUN_TESTS:-0}}"',
        'ORG_ARGS=()',
        'if [[ -n "$TARGET_ORG" ]]; then',
        '  ORG_ARGS=(--target-org "$TARGET_ORG")',
        '  echo "Target org: $TARGET_ORG"',
        'else',
        '  echo "Using default CLI / VS Code connected org (no alias)..."',
        'fi',
        'echo "Deploying Apex..."',
        'if [[ "$RUN_TESTS" == "1" ]]; then',
        '  echo "Running tests: ' + testJoin + '"',
        '  sf project deploy start --manifest package.xml --test-level RunSpecifiedTests ' + sfTestFlags + ' "${{ORG_ARGS[@]}}"',
        'else',
        '  sf project deploy start --manifest package.xml "${{ORG_ARGS[@]}}"',
        'fi',
        'echo "Registering skill(s)..."',
        shRegister,
        shApply,
        'echo "Done. Verify the skill(s) on your agent in GPTfy."',
        ''
      ].join('\\n');

      return {{ ps, sh, applyHelperPy }};
    }}

    function buildReadyCommands(names, orgAlias, applySystemPrompt) {{
      const alias = orgAlias || '';
      const isMulti = names.length > 1;
      const folderHint = isMulti
        ? 'cd into the unzipped bundle folder'
        : 'cd into the unzipped ' + names[0] + ' folder';
      const orgFlag = alias ? (' --target-org ' + alias) : '';
      const psQuick = alias
        ? [
            '# ' + folderHint + ', then:',
            '.\\\\install.ps1 -TargetOrg ' + alias
          ].join('\\n')
        : [
            '# ' + folderHint + ', then (uses default CLI / VS Code org):',
            '.\\\\install.ps1'
          ].join('\\n');
      const cliLines = [
        'sf project deploy start --manifest package.xml' + orgFlag
      ];
      if (isMulti) {{
        names.forEach(n => {{
          cliLines.push('sf apex run --file skills/' + n + '/seed.apex' + orgFlag);
        }});
      }} else {{
        cliLines.push('sf apex run --file seed.apex' + orgFlag);
      }}
      if (applySystemPrompt) {{
        cliLines.push('# System prompt: install.ps1 will overwrite agent system prompt after skills register');
      }} else {{
        cliLines.push('# System prompt: paste sample-system-prompt.txt in GPTfy if you want composed guidance');
      }}
      if (!alias) {{
        cliLines.unshift('# Uses default connected org. Add --target-org <alias> only if needed.');
      }}
      return {{ ps: psQuick, cli: cliLines.join('\\n') }};
    }}

    function closeConfig() {{
      if (configModal.open) configModal.close();
      configError.classList.remove('show');
      configError.textContent = '';
    }}

    function openConfig() {{
      loadSavedConfig();
      if (!cfgAgent.value.trim()) cfgAgent.value = 'GPTfy Agent';
      configError.classList.remove('show');
      configError.textContent = '';
      if (!configModal.open) configModal.showModal();
      cfgMapping.focus();
    }}

    document.getElementById('configCancel').addEventListener('click', closeConfig);
    configModal.addEventListener('cancel', (e) => {{ e.preventDefault(); closeConfig(); }});
    configModal.addEventListener('click', (e) => {{
      if (e.target === configModal) closeConfig();
    }});

    async function runDownload(cfg) {{
      const names = selectedNames();
      if (!names.length) return;
      if (typeof JSZip === 'undefined') {{
        showAlert('Download failed', 'Zip library failed to load. Check network/CDN.');
        return;
      }}
      downloadSel.disabled = true;
      statusEl.textContent = 'Preparing download…';
      try {{
        const out = new JSZip();
        const seenClassFiles = new Set();
        const classNames = new Set(['AgenticSkillsBase']);
        let samplePromptAdded = false;
        const skillsFolder = names.length > 1 ? out.folder('skills') : null;
        const apexFolder = names.length > 1
          ? out.folder('force-app/main/default/classes')
          : null;
        let singleFolder = null;

        for (let i = 0; i < names.length; i++) {{
          const name = names[i];
          statusEl.textContent = 'Fetching ' + (i + 1) + '/' + names.length + '…';
          const res = await fetch('zips/' + encodeURIComponent(name) + '.zip');
          if (!res.ok) throw new Error('Failed to fetch ' + name + ' (' + res.status + ')');
          const buf = await res.arrayBuffer();
          const skillZip = await JSZip.loadAsync(buf);
          const tasks = [];

          skillZip.forEach((path, entry) => {{
            if (entry.dir) return;
            const parts = path.split('/');
            const rel = parts[0] === name ? parts.slice(1).join('/') : path;
            if (!rel) return;

            if (names.length > 1) {{
              if (rel.startsWith('force-app/main/default/classes/')) {{
                const fileName = rel.split('/').pop();
                if (!fileName || seenClassFiles.has(fileName)) return;
                seenClassFiles.add(fileName);
                if (fileName.endsWith('.cls')) classNames.add(fileName.slice(0, -4));
                tasks.push(entry.async('uint8array').then(data => apexFolder.file(fileName, data)));
                return;
              }}
              if (rel === 'seed.apex') {{
                const skillDir = skillsFolder.folder(name);
                tasks.push(entry.async('string').then(text => skillDir.file('seed.apex', patchSeed(text, cfg))));
                return;
              }}
              if (rel === 'sample-system-prompt.txt') return;
              return;
            }}

            const folder = out.folder(name);
            singleFolder = folder;
            if (rel === 'seed.apex') {{
              tasks.push(entry.async('string').then(text => folder.file('seed.apex', patchSeed(text, cfg))));
            }} else if (rel === 'sample-system-prompt.txt') {{
              return;
            }} else {{
              tasks.push(entry.async('uint8array').then(data => folder.file(rel, data)));
            }}
          }});
          await Promise.all(tasks);
        }}

        const composedPrompt = composeSystemPrompt(names);
        const scripts = buildInstallScripts(names, cfg.orgAlias, !!cfg.updateSystemPrompt);
        const pkgTests = testsForSkills(names);
        const packageConfig = JSON.stringify({{
          agent: cfg.agent,
          mapping: cfg.mapping,
          connection: cfg.connection,
          orgAlias: cfg.orgAlias || '',
          applySystemPrompt: !!cfg.updateSystemPrompt,
          skills: names,
          tests: pkgTests,
          packageVersion: '1.1.0'
        }}, null, 2) + '\\n';
        const aliasLabel = cfg.orgAlias || '';
        const installPsLine = aliasLabel
          ? '.\\\\install.ps1 -TargetOrg ' + aliasLabel
          : '.\\\\install.ps1';
        const installPsTests = aliasLabel
          ? '.\\\\install.ps1 -TargetOrg ' + aliasLabel + ' -RunTests'
          : '.\\\\install.ps1 -RunTests';
        const installShLine = aliasLabel
          ? './install.sh ' + aliasLabel
          : './install.sh';
        const deployLine = aliasLabel
          ? 'sf project deploy start --manifest package.xml --target-org ' + aliasLabel
          : 'sf project deploy start --manifest package.xml';
        const seedLine = aliasLabel
          ? 'sf apex run --file skills/<api_name>/seed.apex --target-org ' + aliasLabel
          : 'sf apex run --file skills/<api_name>/seed.apex';

        if (names.length > 1) {{
          out.file('package.xml', classMembersXml(classNames));
          out.file('sfdx-project.json', JSON.stringify({{
            packageDirectories: [{{ path: 'force-app', default: true }}],
            name: 'gptfy-skills-bundle',
            sourceApiVersion: '66.0'
          }}, null, 2) + '\\n');
          out.file('install.ps1', scripts.ps);
          out.file('install.sh', scripts.sh);
          out.file('sample-system-prompt.txt', composedPrompt);
          out.file('package-config.json', packageConfig);
          out.file('version.json', JSON.stringify({{
            packageVersion: '1.1.0',
            sourceApiVersion: '66.0',
            skills: names,
            classes: [...classNames].filter(n => !n.endsWith('Test')).sort(),
            tests: pkgTests
          }}, null, 2) + '\\n');
          out.file('PRODUCTION_NOTES.txt', [
            'PRODUCTION NOTES (short)',
            '========================',
            '- Deploy with tests:  ' + installPsTests,
            '  or: RUN_TESTS=1 ' + installShLine,
            '- Sharing: handlers use with sharing (agent user context).',
            '- Re-run seed is safe (existing skill Names skipped).',
            '- Apex re-deploy updates classes by API name.',
            '',
            'Verify: Apex classes → AI Prompts → agent skill links → smoke chat.',
            ''
          ].join('\\n'));
          out.file('apply_system_prompt.py', scripts.applyHelperPy);
          out.file('README.txt', [
            'GPTfy multi-skill bundle (Apex deduped)',
            '=====================================',
            '',
            'Selected skills (' + names.length + '):',
            ...names.map(n => '  - ' + n),
            '',
            'Pre-filled in every install script (seed.apex):',
            '  AGENT_NAME   = ' + cfg.agent,
            '  DATA_MAPPING = ' + cfg.mapping,
            '  AI_MODEL     = ' + cfg.connection,
            '',
            'LAYOUT',
            '------',
            'force-app/                 Apex + smoke tests (deduped)',
            'package.xml                Deploy manifest',
            'skills/<api_name>/seed.apex   One seed per skill',
            'install.ps1 / install.sh   Deploy + register (+ optional -RunTests)',
            'sample-system-prompt.txt   Composed prompt for selected skills',
            'package-config.json / version.json',
            'PRODUCTION_NOTES.txt',
            '',
            'INSTALL (sandbox / default)',
            '---------------------------',
            '1) Unzip and open a terminal in this folder',
            '2) Windows:  ' + installPsLine,
            '   Mac/Linux: chmod +x install.sh && ' + installShLine,
            '',
            'INSTALL (production — run package tests)',
            '----------------------------------------',
            'Windows:  ' + installPsTests,
            'Mac/Linux: RUN_TESTS=1 ' + installShLine,
            '',
            'INSTALL (manual CLI)',
            '--------------------',
            '1) ' + deployLine,
            '2) For each skill: ' + seedLine,
            '3) If applySystemPrompt was enabled, install.ps1 updates the agent system prompt.',
            '   Otherwise paste sample-system-prompt.txt in GPTfy manually.',
            '',
            'INSTALL (Workbench)',
            '-------------------',
            '1) Log into the target org in Workbench',
            '2) Migration → Deploy the Apex package (package.xml + force-app)',
            '3) Utilities → Apex Execute: paste each skills/*/seed.apex',
            '',
            'Apex handlers are shared; deploying once covers all skills that use those classes.',
            ''
          ].join('\\n'));
          out.file('SELECTED_SKILLS.txt', [
            'Selected skills (' + names.length + '):',
            ...names.map(n => '  - ' + n),
            '',
            'Agent: ' + cfg.agent,
            'Mapping: ' + cfg.mapping,
            'Connection: ' + cfg.connection,
            'CLI org alias: ' + (aliasLabel || '(default connected org)'),
            'Update system prompt: ' + (cfg.updateSystemPrompt ? 'yes' : 'no'),
            'Tests: ' + pkgTests.join(', '),
            ''
          ].join('\\n'));
        }} else if (singleFolder) {{
          singleFolder.file('install.ps1', scripts.ps);
          singleFolder.file('install.sh', scripts.sh);
          singleFolder.file('sample-system-prompt.txt', composedPrompt);
          singleFolder.file('package-config.json', packageConfig);
          singleFolder.file('apply_system_prompt.py', scripts.applyHelperPy);
        }}

        statusEl.textContent = 'Compressing…';
        const blob = await out.generateAsync({{ type: 'blob' }});
        const a = document.createElement('a');
        const url = URL.createObjectURL(blob);
        a.href = url;
        a.download = names.length === 1
          ? names[0] + '.zip'
          : 'gptfy-skills-bundle-' + names.length + '.zip';
        document.body.appendChild(a);
        a.click();
        a.remove();
        URL.revokeObjectURL(url);
        const commands = buildReadyCommands(names, cfg.orgAlias, !!cfg.updateSystemPrompt);
        const promptNote = cfg.updateSystemPrompt
          ? ' Install will also overwrite the agent system prompt with the composed package prompt.'
          : ' Package includes composed sample-system-prompt.txt (not applied unless you paste it or re-download with the toggle on).';
        showAlert(
          'Download complete',
          names.length === 1
            ? '1 skill package is ready with your org values filled in.' + promptNote + ' Unzip, then run install.ps1 / use Copy commands below.'
            : names.length + ' skills are bundled with shared Apex and your org values filled in.' + promptNote + ' Unzip, then run install.ps1 / use Copy commands below.',
          {{ clearSelection: true, commands }}
        );
      }} catch (err) {{
        console.error(err);
        showAlert('Download failed', (err && err.message) ? err.message : String(err));
      }} finally {{
        refreshCounts();
      }}
    }}

    downloadSel.addEventListener('click', () => {{
      const names = selectedNames();
      if (!names.length) return;
      openConfig();
    }});

    configForm.addEventListener('submit', async (e) => {{
      e.preventDefault();
      const cfg = {{
        mapping: cfgMapping.value.trim(),
        connection: cfgConnection.value.trim(),
        agent: cfgAgent.value.trim() || 'GPTfy Agent',
        orgAlias: sanitizeOrgAlias(cfgOrgAlias.value),
        updateSystemPrompt: !!(cfgUpdatePrompt && cfgUpdatePrompt.checked)
      }};
      if (!isSalesforceId(cfg.mapping) || !isSalesforceId(cfg.connection)) {{
        configError.textContent = 'Mapping Id and Connection Id must be valid 15 or 18 character Salesforce Ids.';
        configError.classList.add('show');
        return;
      }}
      if (!cfg.agent) {{
        configError.textContent = 'Agent Name is required.';
        configError.classList.add('show');
        return;
      }}
      saveConfig(cfg);
      closeConfig();
      await runDownload(cfg);
    }});

    document.getElementById('requestForm').addEventListener('submit', (e) => {{
      e.preventDefault();
      const fd = new FormData(e.target);
      const subject = encodeURIComponent('Skill request: ' + (fd.get('title') || ''));
      const body = encodeURIComponent(
        'Name: ' + fd.get('name') + '\\n' +
        'Email: ' + fd.get('email') + '\\n' +
        'Title: ' + fd.get('title') + '\\n' +
        'Area: ' + fd.get('area') + '\\n\\n' +
        'Details:\\n' + fd.get('details')
      );
      window.location.href = 'mailto:support@gptfy.ai?subject=' + subject + '&body=' + body;
    }});

    applyFilter();
  </script>
</body>
</html>
"""
    return html.replace("/*__SKILL_META__*/null", skill_meta_json(skills), 1)


def main() -> None:
    skills = extract_skills()
    system_prompt = SYSTEM_PROMPT.read_text(encoding="utf-8")

    if PACKAGES.exists():
        shutil.rmtree(PACKAGES)
    if ZIPS.exists():
        shutil.rmtree(ZIPS)
    PACKAGES.mkdir(parents=True)
    ZIPS.mkdir(parents=True)

    for skill in skills:
        pkg = write_skill_package(skill, system_prompt)
        zip_dir(pkg, ZIPS / f"{skill['name']}.zip")
        print(f"  OK  {skill['name']}")

    html = render_html(skills)
    (OUT / "index.html").write_text(html, encoding="utf-8")
    (OUT / "README.md").write_text(
        """# GPTfy Skills — KB Catalog (local HTML)

Open `index.html` in a browser (double-click or serve the folder).

Each skill card downloads a zip with:
- `package.xml` + Apex (`AgenticSkillsBase` + handler + smoke tests)
- `seed.apex` → creates `ccai__AI_Prompt__c` + agent link
- `sample-system-prompt.txt`, `version.json`, `PRODUCTION_NOTES.txt`
- `README.txt`
- Catalog download also adds `install.ps1` / `install.sh` (`-RunTests` for prod)

Rebuild:
```bash
python kb-catalog/build_kb_catalog.py
```

Serve locally (recommended so downloads work cleanly):
```bash
cd kb-catalog
python -m http.server 8765
```
Then open http://localhost:8765/
""",
        encoding="utf-8",
    )
    print(f"\nBuilt {len(skills)} skill packages -> {OUT}")
    print(f"Open: {OUT / 'index.html'}")


if __name__ == "__main__":
    main()
