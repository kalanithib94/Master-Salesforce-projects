# -*- coding: utf-8 -*-
"""One-off generator: Skills/*.md + Global_System_Prompt_Instructions.md"""
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
WORKSPACE = ROOT.parent
CLS = WORKSPACE / "Deliverables/force-app/main/default/classes/GenericAgenticSkillsHandler.cls"
CMD_MD = WORKSPACE / "Deliverables/docs/GPTfy_Agent_Prompt_Commands.md"
SP_TXT = WORKSPACE / "Deliverables/docs/GenericCRMAssistant_SystemPrompt.txt"

# Handler start line (1-based) -> skill name (same order as switch / grep)
HANDLER_STARTS: list[tuple[int, str]] = [
    (451, "fuzzy_search_accounts"),
    (485, "fetch_account_details"),
    (527, "create_account"),
    (556, "update_account_fields"),
    (590, "fetch_account_related_lists"),
    (666, "fuzzy_search_contacts"),
    (703, "fetch_contact_details"),
    (730, "create_contact"),
    (760, "update_contact_fields"),
    (794, "log_contact_activity"),
    (822, "fuzzy_search_leads"),
    (859, "fetch_lead_details"),
    (893, "create_lead"),
    (918, "update_lead_fields"),
    (933, "convert_lead"),
    (968, "log_lead_activity"),
    (998, "fuzzy_search_opportunities"),
    (1057, "fetch_opportunity_details"),
    (1084, "create_opportunity"),
    (1110, "update_opportunity_fields"),
    (1144, "log_opportunity_activity"),
    (1164, "add_opportunity_line_item"),
    (1208, "fetch_opportunity_recent_changes"),
    (1264, "fuzzy_search_cases"),
    (1301, "fetch_case_details"),
    (1326, "create_case"),
    (1350, "update_case_fields"),
    (1365, "close_case"),
    (1399, "create_task"),
    (1421, "create_event"),
    (1449, "fetch_my_open_tasks"),
    (1478, "complete_task"),
    (1504, "bulk_update_records"),
    (1554, "fetch_record_history"),
    (1600, "fetch_user_info"),
    (1626, "run_internal_prompt"),
    (1657, "fetch_picklist_values"),
]


def lines_slice(sp: list[str], start_line: int, end_line: int) -> str:
    """1-based inclusive line numbers."""
    return "\n".join(sp[start_line - 1 : end_line])


def parse_prompt_commands(md_text: str) -> dict[str, str]:
    """Skill name -> JSON string (pretty-printed)."""
    out: dict[str, str] = {}
    # Split by ### headings that contain backtick skill name
    pattern = re.compile(
        r"###[^\n]*?`([a-z0-9_]+)`\s*\n.*?\*\*Prompt Command\*\*\s*\n```json\s*\n(.*?)```",
        re.DOTALL | re.IGNORECASE,
    )
    for m in pattern.finditer(md_text):
        name = m.group(1)
        raw_json = m.group(2).strip()
        try:
            obj = json.loads(raw_json)
            out[name] = json.dumps(obj, indent=2)
        except json.JSONDecodeError as e:
            raise RuntimeError(f"Bad JSON for skill {name}: {e}") from e
    return out


def extract_switch_line(cls_lines: list[str], skill: str) -> str:
    for ln in cls_lines:
        if f"when '{skill}'" in ln:
            return ln.strip()
    return f"// when '{skill}' not found"


def find_handler_end_line(cls_lines: list[str], sig_line_1based: int) -> int:
    """1-based line index of the closing `}` for `private String handle...` (brace-balanced, strings-aware)."""
    idx = sig_line_1based - 1
    depth = 0
    started = False
    in_squote = in_dquote = False
    escape = False
    while idx < len(cls_lines):
        line = cls_lines[idx]
        i = 0
        while i < len(line):
            c = line[i]
            if escape:
                escape = False
                i += 1
                continue
            if in_dquote:
                if c == "\\":
                    escape = True
                elif c == '"':
                    in_dquote = False
                i += 1
                continue
            if in_squote:
                if c == "\\":
                    escape = True
                elif c == "'":
                    in_squote = False
                i += 1
                continue
            if c == '"':
                in_dquote = True
            elif c == "'":
                in_squote = True
            elif c == "{":
                depth += 1
                started = True
            elif c == "}" and started:
                depth -= 1
                if depth == 0:
                    return idx + 1
            i += 1
        idx += 1
    raise RuntimeError(f"No closing brace for handler starting line {sig_line_1based}")


def extract_handler_body(cls_lines: list[str], start_line: int) -> str:
    end_line = find_handler_end_line(cls_lines, start_line)
    return "\n".join(cls_lines[start_line - 1 : end_line])


def build_excerpt(sp: list[str], skill: str) -> str:
    """Verbatim slices from GenericCRMAssistant_SystemPrompt.txt (1-based line refs in comments)."""
    parts: list[str] = []

    def add(start: int, end: int):
        block = lines_slice(sp, start, end).rstrip()
        parts.append(f"<!-- Lines {start}-{end} -->\n{block}")

    if skill.startswith("fuzzy_search_"):
        add(45, 47)
        add(120, 134)
        row = {
            "fuzzy_search_accounts": (137, 138),
            "fuzzy_search_contacts": (139, 139),
            "fuzzy_search_leads": (140, 140),
            "fuzzy_search_opportunities": (141, 144),
            "fuzzy_search_cases": (142, 142),
        }[skill]
        add(row[0], row[1])
        add(363, 377)
        return "\n\n".join(parts)

    if skill in (
        "fetch_account_details",
        "fetch_contact_details",
        "fetch_lead_details",
        "fetch_opportunity_details",
        "fetch_case_details",
    ):
        add(45, 47)
        add(52, 58)
        add(100, 117)
        add(159, 160)
        add(259, 263)
        return "\n\n".join(parts)

    if skill == "fetch_account_related_lists":
        add(63, 64)
        add(104, 105)
        add(159, 160)
        add(259, 263)
        return "\n\n".join(parts)

    if skill == "fetch_opportunity_recent_changes":
        add(67, 68)
        add(108, 108)
        add(159, 160)
        add(259, 263)
        return "\n\n".join(parts)

    if skill in ("fetch_record_history", "fetch_user_info", "fetch_picklist_values"):
        add(75, 80)
        add(159, 160)
        add(259, 263)
        return "\n\n".join(parts)

    if skill == "fetch_my_open_tasks":
        add(70, 73)
        add(159, 160)
        add(259, 263)
        return "\n\n".join(parts)

    if skill == "run_internal_prompt":
        add(79, 80)
        add(159, 160)
        add(324, 336)
        return "\n\n".join(parts)

    if skill == "bulk_update_records":
        add(76, 76)
        add(151, 153)
        add(235, 235)
        add(265, 271)
        add(339, 360)
        return "\n\n".join(parts)

    if skill.startswith("create_"):
        add(45, 58)
        add(151, 177)
        add(216, 230)
        add(235, 245)
        add(251, 257)
        return (
            "\n\n".join(parts)
            + f"\n\n<!-- Skill-specific: `{skill}` follows the CREATE branch above (substitute object name). -->"
        )

    if skill.startswith("update_") and skill.endswith("_fields"):
        add(45, 58)
        add(92, 98)
        add(151, 169)
        add(216, 230)
        add(235, 245)
        add(265, 271)
        return (
            "\n\n".join(parts)
            + f"\n\n<!-- Skill-specific: `{skill}` — use the matching *_id per Rule 2. -->"
        )

    if skill.startswith("delete_"):
        add(45, 55)
        add(92, 98)
        add(151, 189)
        add(273, 278)
        return "\n\n".join(parts)

    if skill == "convert_lead":
        add(65, 65)
        add(107, 107)
        add(151, 157)
        add(280, 285)
        return "\n\n".join(parts)

    if skill == "close_case":
        add(66, 66)
        add(109, 109)
        add(151, 157)
        add(287, 291)
        return "\n\n".join(parts)

    if skill == "complete_task":
        add(72, 72)
        add(156, 157)
        add(293, 296)
        return "\n\n".join(parts)

    if skill in ("create_task", "create_event"):
        add(70, 73)
        add(151, 200)
        add(216, 230)
        add(251, 257)
        return "\n\n".join(parts)

    if skill.startswith("log_"):
        add(60, 61)
        add(104, 114)
        add(151, 157)
        add(298, 302)
        return "\n\n".join(parts)

    if skill == "add_opportunity_line_item":
        add(67, 67)
        add(108, 108)
        add(151, 153)
        add(265, 271)
        return "\n\n".join(parts)

    return f"<!-- No mapped excerpt for `{skill}`; see Global_System_Prompt_Instructions.md -->"


def main() -> None:
    cls_text = CLS.read_text(encoding="utf-8")
    cls_lines = cls_text.splitlines()
    md_text = CMD_MD.read_text(encoding="utf-8")
    sp = SP_TXT.read_text(encoding="utf-8").splitlines()

    cmds = parse_prompt_commands(md_text)
    if len(cmds) != 37:
        raise RuntimeError(f"Expected 37 prompt commands, got {len(cmds)}: {sorted(cmds.keys())}")

    meta = (
        "**Sources:** `Deliverables/force-app/main/default/classes/GenericAgenticSkillsHandler.cls`, "
        "`Deliverables/docs/GenericCRMAssistant_SystemPrompt.txt` (v1.3.1), "
        "`Deliverables/docs/GPTfy_Agent_Prompt_Commands.md`.\n\n"
    )

    for start_line, skill in HANDLER_STARTS:
        when_line = extract_switch_line(cls_lines, skill)
        body = extract_handler_body(cls_lines, start_line)
        apex_block = f"{when_line}\n\n{body}"

        excerpt = build_excerpt(sp, skill)
        pj = cmds.get(skill)
        if pj is None:
            raise RuntimeError(f"Missing JSON for {skill}")

        note = ""
        if skill == "fetch_account_details":
            note = (
                "\n> **Note:** The Prompt Command uses `anyOf` so the model supplies either `account_id` or "
                "`account_name`. Keep generated markdown in sync with "
                "`Deliverables/docs/GPTfy_Agent_Prompt_Commands.md` and deployed `ccai__AI_Prompt__c`.\n"
            )

        md = (
            f"# Skill: `{skill}`\n\n"
            f"{meta}"
            f"## Apex Code Snippet\n\n"
            f"```apex\n{apex_block}\n```\n\n"
            f"## System Prompt Excerpt\n\n"
            f"{excerpt}\n\n"
            f"## JSON Prompt Command\n\n"
            f"{note}"
            f"```json\n{pj}\n```\n"
        )
        (ROOT / f"{skill}.md").write_text(md, encoding="utf-8")

    global_md = (
        "# Global system prompt instructions\n\n"
        "Canonical file: `Deliverables/docs/GenericCRMAssistant_SystemPrompt.txt` "
        "(verbatim copy below). Per-skill files under `Skills/` contain **excerpts** only.\n\n"
        "---\n\n"
        + SP_TXT.read_text(encoding="utf-8")
    )
    (ROOT / "Global_System_Prompt_Instructions.md").write_text(global_md, encoding="utf-8")

    print("Wrote", len(HANDLER_STARTS), "skill files + Global_System_Prompt_Instructions.md")


if __name__ == "__main__":
    main()
