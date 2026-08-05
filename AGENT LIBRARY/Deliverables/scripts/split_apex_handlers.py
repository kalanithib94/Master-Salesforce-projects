#!/usr/bin/env python3
"""Split GenericAgenticSkillsHandler into per-object handler classes + AgenticSkillsBase."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "force-app/main/default/classes/GenericAgenticSkillsHandler.cls"
OUT = ROOT / "force-app/main/default/classes"

HELPER_METHODS = {
    "toText", "escapeHtml", "orgUrl", "recordUrl", "actionHtmlResponse",
    "successHtml", "errorHtml", "errorJson", "successJson", "firstNonNull",
    "buildFuzzySearchCandidates", "coerceFieldValue", "applyFieldsToSObject",
    "hexToInt", "parseToDate", "buildDiffBody", "fuzzyQuery", "fuzzyQueryMulti",
    "applyTopNAndCount", "viewRecordAnchor", "buildAddress", "buildFieldMap",
    "performGenericUpdate",
}

HELPER_FIELDS = {"FUZZY_HARD_CAP", "FUZZY_DISPLAY_LIMIT", "bypassPromptForUnitTest"}

HANDLERS: dict[str, dict] = {
    "AccountAgenticSkillsHandler": {
        "object": "Account",
        "skills": [
            "fuzzy_search_accounts", "fetch_account_details", "create_account",
            "update_account_fields", "fetch_account_related_lists",
        ],
        "start_marker": "// ACCOUNT SKILLS",
        "end_marker": "// CONTACT SKILLS",
    },
    "ContactAgenticSkillsHandler": {
        "object": "Contact",
        "skills": [
            "fuzzy_search_contacts", "fetch_contact_details", "create_contact",
            "update_contact_fields", "log_contact_activity",
        ],
        "start_marker": "// CONTACT SKILLS",
        "end_marker": "// LEAD SKILLS",
    },
    "LeadAgenticSkillsHandler": {
        "object": "Lead",
        "skills": [
            "fuzzy_search_leads", "fetch_lead_details", "create_lead",
            "update_lead_fields", "convert_lead", "log_lead_activity",
        ],
        "start_marker": "// LEAD SKILLS",
        "end_marker": "// OPPORTUNITY SKILLS",
    },
    "OpportunityAgenticSkillsHandler": {
        "object": "Opportunity",
        "skills": [
            "fuzzy_search_opportunities", "fetch_opportunity_details", "create_opportunity",
            "update_opportunity_fields", "log_opportunity_activity",
            "add_opportunity_line_item", "fetch_opportunity_recent_changes",
        ],
        "start_marker": "// OPPORTUNITY SKILLS",
        "end_marker": "// CASE SKILLS",
    },
    "CaseAgenticSkillsHandler": {
        "object": "Case",
        "skills": [
            "fuzzy_search_cases", "fetch_case_details", "create_case",
            "update_case_fields", "close_case",
        ],
        "start_marker": "// CASE SKILLS",
        "end_marker": "// ACTIVITY SKILLS",
    },
    "ActivityAgenticSkillsHandler": {
        "object": "Activity",
        "skills": [
            "create_task", "create_event", "fetch_my_open_tasks", "complete_task",
        ],
        "start_marker": "// ACTIVITY SKILLS",
        "end_marker": "// UTILITY SKILLS",
    },
    "UtilityAgenticSkillsHandler": {
        "object": "Utility",
        "skills": [
            "bulk_update_records", "fetch_record_history", "fetch_user_info",
            "run_internal_prompt", "fetch_picklist_values", "fetch_session_context",
        ],
        "start_marker": "// UTILITY SKILLS",
        "end_marker": None,
    },
}

META = """<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>66.0</apiVersion>
    <status>Active</status>
</ApexClass>
"""


def read_src() -> str:
    return SRC.read_text(encoding="utf-8")


def extract_between(text: str, start: str, end: str | None) -> str:
    i = text.index(start)
    if end:
        j = text.index(end, i + 1)
        return text[i:j]
    return text[i:]


def extract_helpers(text: str) -> str:
    """Core helpers (lines between class open and ACCOUNT SKILLS), plus shared update helpers."""
    core_start = text.index("    // ────────────────────────────────────────────────────────────────────────\n    // HELPERS")
    core_end = text.index("    // ════════════════════════════════════════════════════════════════════════\n    // ACCOUNT SKILLS")
    core = text[core_start:core_end]

    shared_start = text.index("    private static String buildAddress(")
    shared_end = text.index("    // ════════════════════════════════════════════════════════════════════════\n    // CONTACT SKILLS")
    shared = text[shared_start:shared_end]

    skill_exception = "    public class SkillException extends Exception {}\n\n"
    bypass = "    @TestVisible public static Boolean bypassPromptForUnitTest = false;\n\n"

    body = skill_exception + bypass + core.strip() + "\n\n" + shared.strip()
    body = re.sub(r"\bprivate static\b", "public static", body)
    body = re.sub(r"@TestVisible private static Boolean bypassPromptForUnitTest", "@TestVisible public static Boolean bypassPromptForUnitTest", body)
    return body


def prefix_helpers(body: str) -> str:
    for name in sorted(HELPER_METHODS, key=len, reverse=True):
        body = re.sub(rf"(?<![\w.]){name}\(", f"AgenticSkillsBase.{name}(", body)
    for name in sorted(HELPER_FIELDS, key=len, reverse=True):
        body = re.sub(rf"(?<![\w.]){name}\b(?!\()", f"AgenticSkillsBase.{name}", body)
    body = body.replace("AgenticSkillsBase.AgenticSkillsBase.", "AgenticSkillsBase.")
    return body


def build_switch(skills: list[str]) -> str:
    lines = []
    for s in skills:
        lines.append(f"                when '{s}' {{ return handle{skill_to_handler(s)}(parameters); }}")
    lines.append("                when else { return AgenticSkillsBase.errorJson('Unsupported skill: ' + methodName); }")
    return "\n".join(lines)


def skill_to_handler(skill: str) -> str:
    # fuzzy_search_accounts -> FuzzySearchAccounts
    parts = skill.split("_")
    return "".join(p[:1].upper() + p[1:] for p in parts)


def method_name_from_decl(line: str) -> str | None:
    m = re.search(r"private String (handle\w+)\(", line)
    return m.group(1) if m else None


def extract_handler_methods(section: str) -> str:
    """Keep private String handle* and private String fetch* helper methods; drop section banners."""
    lines = section.splitlines()
    out: list[str] = []
    skip_shared = {"buildAddress", "buildFieldMap", "performGenericUpdate"}
    for line in lines:
        if "════" in line or "SKILLS (" in line:
            continue
        if re.match(r"\s*private static String (buildAddress|buildFieldMap|performGenericUpdate)\(", line):
            continue
        out.append(line)
    return "\n".join(out).strip()


def build_handler_class(class_name: str, cfg: dict, section: str) -> str:
    obj = cfg["object"]
    switch = build_switch(cfg["skills"])
    methods = prefix_helpers(extract_handler_methods(section))
    # Rename handleX to match switch - methods already named handleFuzzySearchAccounts etc.

    return f"""/**
 * @description {obj} object skills for the GPTfy Agent Library ({len(cfg['skills'])} skills).
 *              Implements ccai.AIAgenticInterface; shared helpers live in AgenticSkillsBase.
 * @author      : Plumcloud Labs
 * @group       : GPTfy Agent Library
 * @jira        : V2-8418
 */
global with sharing class {class_name} implements ccai.AIAgenticInterface {{

    global String executeMethod(String methodName, Map<String, Object> parameters) {{
        try {{
            if (parameters == null) parameters = new Map<String, Object>();
            String m = String.isBlank(methodName) ? '' : methodName.trim();
            switch on m {{
{switch}
            }}
        }} catch (Exception ex) {{
            System.debug(LoggingLevel.ERROR, '{class_name} | ' + methodName + ' | ' + ex.getMessage());
            return AgenticSkillsBase.errorJson(ex.getMessage());
        }}
    }}

{methods}
}}
"""


def build_base(helpers: str) -> str:
    return f"""/**
 * @description Shared helpers for GPTfy Agent Library per-object skill handlers.
 * @author      : Plumcloud Labs
 * @group       : GPTfy Agent Library
 * @jira        : V2-8418
 */
public with sharing class AgenticSkillsBase {{

{helpers}
}}
"""


def build_facade() -> str:
    routes = []
    for class_name, cfg in HANDLERS.items():
        for skill in cfg["skills"]:
            routes.append(f"                when '{skill}' {{ return {class_name}.INSTANCE.executeMethod(methodName, parameters); }}")
    switch_body = "\n".join(routes)
    instance_decls = "\n".join(
        f"    private static final {name} INSTANCE = new {name}();"
        for name in HANDLERS
    )
    return f"""/**
 * @description Backward-compatible facade — delegates all 38 skills to per-object handlers.
 *              Existing ccai__AI_Prompt__c records may keep Agentic_Function_Class__c =
 *              GenericAgenticSkillsHandler; new deployments should point prompts at the
 *              object-specific handler classes directly.
 * @author      : Plumcloud Labs
 * @group       : GPTfy Agent Library
 * @jira        : V2-8418
 */
global with sharing class GenericAgenticSkillsHandler implements ccai.AIAgenticInterface {{

{instance_decls}

    global String executeMethod(String methodName, Map<String, Object> parameters) {{
        try {{
            if (parameters == null) parameters = new Map<String, Object>();
            String m = String.isBlank(methodName) ? '' : methodName.trim();
            switch on m {{
{switch_body}
                when else {{ return AgenticSkillsBase.errorJson('Unsupported skill: ' + methodName); }}
            }}
        }} catch (Exception ex) {{
            System.debug(LoggingLevel.ERROR, 'GenericAgenticSkillsHandler | ' + methodName + ' | ' + ex.getMessage());
            return AgenticSkillsBase.errorJson(ex.getMessage());
        }}
    }}
}}
"""


def main() -> None:
    text = read_src()
    helpers = extract_helpers(text)

    base_path = OUT / "AgenticSkillsBase.cls"
    base_path.write_text(build_base(helpers), encoding="utf-8")
    (OUT / "AgenticSkillsBase.cls-meta.xml").write_text(META, encoding="utf-8")
    print(f"Wrote {base_path.name}")

    for class_name, cfg in HANDLERS.items():
        section = extract_between(text, cfg["start_marker"], cfg["end_marker"])
        content = build_handler_class(class_name, cfg, section)
        path = OUT / f"{class_name}.cls"
        path.write_text(content, encoding="utf-8")
        (OUT / f"{class_name}.cls-meta.xml").write_text(META, encoding="utf-8")
        print(f"Wrote {path.name} ({len(cfg['skills'])} skills)")

    facade_path = OUT / "GenericAgenticSkillsHandler.cls"
    facade_path.write_text(build_facade(), encoding="utf-8")
    print(f"Rewrote {facade_path.name} (facade)")

    # Org migration script
    migration = """/**
 * Updates ccai__AI_Prompt__c Agentic_Function_Class__c to per-object handlers.
 * Run after deploying split handler classes. Safe to re-run.
 */
Map<String, String> skillToClass = new Map<String, String>{
"""
    for class_name, cfg in HANDLERS.items():
        for skill in cfg["skills"]:
            migration += f"    '{skill}' => '{class_name}',\n"
    migration += """};

List<ccai__AI_Prompt__c> prompts = [
    SELECT Id, Name, ccai__Agentic_Function_Class__c
    FROM ccai__AI_Prompt__c
    WHERE Name IN :skillToClass.keySet()
];
Integer updated = 0;
for (ccai__AI_Prompt__c p : prompts) {
    String target = skillToClass.get(p.Name);
    if (p.ccai__Agentic_Function_Class__c != target) {
        p.ccai__Agentic_Function_Class__c = target;
        updated++;
    }
}
if (!prompts.isEmpty()) update prompts;
System.debug('Updated ' + updated + ' prompt(s) to per-object handler classes.');
"""
    mig_path = ROOT / "scripts/UpdatePromptHandlerClasses.apex"
    mig_path.write_text(migration, encoding="utf-8")
    print(f"Wrote {mig_path.name}")


if __name__ == "__main__":
    main()
