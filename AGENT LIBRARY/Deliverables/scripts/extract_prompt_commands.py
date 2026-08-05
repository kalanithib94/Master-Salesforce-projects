# -*- coding: utf-8 -*-
"""Extract Prompt Command property keys from package seed.apex files for review."""
from __future__ import annotations

import json
import re
from collections import OrderedDict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACKAGES = ROOT / "kb-catalog" / "packages"
OUT_MD = ROOT / "docs" / "PROMPT_COMMANDS_BY_SKILL.md"
OUT_JSON = ROOT / "docs" / "PROMPT_COMMANDS_BY_SKILL.json"


def extract_prompt_block(seed_text: str) -> str:
    """Return the Apex map literal inside JSON.serializePretty(...) for Prompt_Command."""
    marker = "ccai__Prompt_Command__c = JSON.serializePretty("
    i = seed_text.find(marker)
    if i < 0:
        return ""
    i += len(marker)
    # balance braces from "new Map..."
    start = seed_text.find("{", i)
    if start < 0:
        return ""
    depth = 0
    for j in range(start, len(seed_text)):
        c = seed_text[j]
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return seed_text[start : j + 1]
    return ""


def parse_required(block: str) -> list[str]:
    m = re.search(r"'required'\s*=>\s*new List<String>\{([^}]*)\}", block)
    if not m:
        return []
    return re.findall(r"'([^']+)'", m.group(1))


def parse_additional(block: str) -> str | None:
    if re.search(r"'additionalProperties'\s*=>\s*true", block):
        return "true"
    if re.search(r"'additionalProperties'\s*=>\s*false", block):
        return "false"
    return None


def parse_properties(block: str) -> list[dict]:
    """Extract top-level property keys under 'properties' map (best-effort)."""
    props_m = re.search(
        r"'properties'\s*=>\s*new Map<String, Object>\{",
        block,
    )
    if not props_m:
        return []
    # find matching close for properties map — simple depth from match end-1
    start = props_m.end() - 1  # at {
    depth = 0
    end = None
    for j in range(start, len(block)):
        if block[j] == "{":
            depth += 1
        elif block[j] == "}":
            depth -= 1
            if depth == 0:
                end = j
                break
    if end is None:
        return []
    inner = block[start + 1 : end]

    results: list[dict] = []
    # each prop: 'key' => new Map<String, Object>{ ... }
    for m in re.finditer(
        r"'([A-Za-z0-9_]+)'\s*=>\s*new Map<String, Object>\{",
        inner,
    ):
        key = m.group(1)
        if key in ("type", "description", "items", "enum", "properties", "required"):
            continue
        # find map body
        ms = m.end() - 1
        d = 0
        me = None
        for j in range(ms, len(inner)):
            if inner[j] == "{":
                d += 1
            elif inner[j] == "}":
                d -= 1
                if d == 0:
                    me = j
                    break
        body = inner[ms : me + 1] if me is not None else ""
        tm = re.search(r"'type'\s*=>\s*'([^']+)'", body)
        dm = re.search(r"'description'\s*=>\s*'((?:\\'|[^'])*)'", body, re.S)
        desc = ""
        if dm:
            desc = dm.group(1).replace("\\'", "'").replace("\\n", " ").strip()
        results.append(
            {
                "name": key,
                "type": tm.group(1) if tm else "",
                "description": desc,
            }
        )
    return results


def main() -> None:
    catalog: OrderedDict[str, dict] = OrderedDict()
    for seed in sorted(PACKAGES.glob("*/seed.apex")):
        skill = seed.parent.name
        text = seed.read_text(encoding="utf-8")
        block = extract_prompt_block(text)
        if not block:
            catalog[skill] = {"error": "Prompt_Command not found"}
            continue
        catalog[skill] = {
            "required": parse_required(block),
            "additionalProperties": parse_additional(block),
            "properties": parse_properties(block),
        }

    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(json.dumps(catalog, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    lines = [
        "# Prompt Commands by skill",
        "",
        f"Total skills: **{len(catalog)}**",
        "",
        "Auto-generated from `Deliverables/kb-catalog/packages/<skill>/seed.apex` "
        "(`ccai__Prompt_Command__c`). Do not hand-edit skill sections — re-run "
        "`python scripts/extract_prompt_commands.py` after package changes.",
        "",
        "Related: [PROMPT_COMMANDS_INDEX.md](PROMPT_COMMANDS_INDEX.md) · "
        "[PROMPT_COMMANDS_BY_SKILL.json](PROMPT_COMMANDS_BY_SKILL.json) · "
        "[PROMPT_COMMANDS_AUDIT.md](PROMPT_COMMANDS_AUDIT.md)",
        "",
        "## Naming convention",
        "",
        "| Kind | Param style | Examples |",
        "|------|-------------|----------|",
        "| Primary record of the skill | `Id` | `fetch_account_details.Id`, `update_case_fields.Id`, `clone_opportunity.Id` |",
        "| Parent / relationship field | Salesforce field API name | `CampaignId`, `OpportunityId`, `AccountId`, `ParentId`, `OrderId`, `QuoteId`, `SBQQ__Quote__c` |",
        "| Polymorphic activity parent | `WhatId` / `WhoId` | `log_activity`, `create_care_task` (`WhatId`) |",
        "| Standard fields | Org API case | `Status`, `Quantity`, `UnitPrice`, `Role`, `Subject`, `Reason` |",
        "",
        "**Do not** pass a parent campaign / opportunity / order as bare `Id` when creating or listing children "
        "(e.g. `add_campaign_member` takes `CampaignId`, not CampaignMember/`Id`).",
        "",
        "---",
        "",
    ]
    index_rows = [
        "# Prompt params index (quick scan)",
        "",
        "Full detail: [PROMPT_COMMANDS_BY_SKILL.md](PROMPT_COMMANDS_BY_SKILL.md) | "
        "[PROMPT_COMMANDS_BY_SKILL.json](PROMPT_COMMANDS_BY_SKILL.json)",
        "",
        "| Skill | required | properties |",
        "|-------|----------|------------|",
    ]
    for skill, data in catalog.items():
        lines.append(f"## `{skill}`")
        lines.append("")
        if data.get("error"):
            lines.append(f"- ERROR: {data['error']}")
            lines.append("")
            index_rows.append(f"| `{skill}` | ERROR | - |")
            continue
        req = data.get("required") or []
        lines.append(f"- **required:** `{json.dumps(req)}`")
        # Only surface open field bags (true). Omit false/null — strict false is not used.
        if data.get("additionalProperties") == "true":
            lines.append("- **additionalProperties:** `true`")
        props = data.get("properties") or []
        lines.append("- **properties:**")
        if not props:
            lines.append("  - *(none parsed)*")
            prop_names = "-"
        else:
            names = []
            for p in props:
                t = p.get("type") or "?"
                d = (p.get("description") or "").replace("\u2014", "-").replace("\u2013", "-")
                if d:
                    lines.append(f"  - `{p['name']}` (`{t}`) - {d}")
                else:
                    lines.append(f"  - `{p['name']}` (`{t}`)")
                names.append(f"`{p['name']}`")
            prop_names = ", ".join(names)
        lines.append("")
        index_rows.append(
            f"| `{skill}` | `{json.dumps(req)}` | {prop_names} |"
        )

    OUT_MD.write_text("\n".join(lines), encoding="utf-8")
    index_path = OUT_MD.parent / "PROMPT_COMMANDS_INDEX.md"
    index_path.write_text("\n".join(index_rows) + "\n", encoding="utf-8")
    print(f"Wrote {OUT_MD}")
    print(f"Wrote {OUT_JSON}")
    print(f"Wrote {index_path}")
    print(f"Skills: {len(catalog)}")


if __name__ == "__main__":
    main()
