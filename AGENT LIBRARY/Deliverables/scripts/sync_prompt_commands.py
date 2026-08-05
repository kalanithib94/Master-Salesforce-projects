"""
sync_prompt_commands.py
=======================

One-shot helper that aligns every `ccai__AI_Prompt__c` record bound to the
GenericAgenticSkillsHandler with the canonical descriptions / JSON schemas
in `Deliverables/docs/GPTfy_Agent_Prompt_Commands.md`.

Behaviour
---------
1. Parses the canonical doc, building { skill_name -> { description, prompt_command } }
   for all 40 skills.
2. Queries the org for every active GenericAgenticSkillsHandler prompt record.
3. Diffs the org snapshot against the canonical, normalising both Prompt_Command
   strings as parsed JSON so trivial formatting differences are ignored.
4. Writes a single CSV (`updates.csv`) containing only the rows that need
   patching - Id, ccai__Description__c, ccai__Prompt_Command__c, ccai__Status__c.
5. Prints a summary so the human operator can sanity-check before invoking
   `sf data update bulk`.

Usage
-----
    python scripts/sync_prompt_commands.py --build
    sf data update bulk --sobject ccai__AI_Prompt__c \
        --file scripts/updates.csv --wait 10

Why a separate script?
----------------------
Inline jq/awk parsing across CRLF + UTF-8 markdown was fragile on Windows; a
short Python tool keeps the logic readable and the transformations auditable.
"""

from __future__ import annotations

import argparse
import csv
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parent.parent
DOC = ROOT / "docs" / "GPTfy_Agent_Prompt_Commands.md"
OUT_DIR = ROOT / "scripts"
UPDATES_CSV = OUT_DIR / "updates.csv"
ORG_SNAPSHOT = OUT_DIR / "org_snapshot.json"
EXPECTED_SKILL_COUNT = 40
DESCRIPTION_MAX = 255  # ccai__Description__c is a managed-package textarea(255)


def shrink_description(text: str, limit: int = DESCRIPTION_MAX) -> str:
    """Trim a long canonical description down to <= `limit` chars while
    preserving as much skill-dispatch signal as possible.

    Strategy:
      1. Collapse internal whitespace & strip blank lines.
      2. Prefer the first paragraph; if longer than the limit, take the
         longest prefix that still ends on a sentence boundary.
      3. Fall back to a hard truncation with an ellipsis suffix.
    """
    if not text:
        return ""
    paragraphs = [p.strip() for p in text.split("\n\n") if p.strip()]
    head = paragraphs[0] if paragraphs else text.strip()
    head = re.sub(r"\s+", " ", head).strip()
    if len(head) <= limit:
        return head
    # try to keep the longest sentence-bounded prefix
    cutoff = head[: limit + 1]
    # search from limit backwards for the last full stop / question mark
    last_period = max(cutoff.rfind(". "), cutoff.rfind("? "), cutoff.rfind("! "))
    if last_period >= 80:
        return cutoff[: last_period + 1].rstrip()
    return head[: limit - 1].rstrip() + "\u2026"


SKILL_HEADING_RE = re.compile(r"^###\s+\d+\.\d+\s+\u2014\s+`([a-z_]+)`\s*$")


def parse_canonical(doc_path: Path) -> dict[str, dict[str, str]]:
    """Walks the canonical markdown line-by-line and captures, per skill:
    `description` (the first plain-fenced block under **Description**) and
    `prompt_command` (the json-fenced block under **Prompt Command**).
    """
    text = doc_path.read_text(encoding="utf-8")
    lines = text.splitlines()
    skills: dict[str, dict[str, str]] = {}

    current: str | None = None
    section: str | None = None  # "description" | "prompt_command"
    in_fence = False
    fence_lang: str | None = None
    buffer: list[str] = []

    def flush() -> None:
        nonlocal buffer, section
        if current and section and buffer:
            skills.setdefault(current, {})[section] = "\n".join(buffer).strip("\n")
        buffer = []
        section = None

    for line in lines:
        heading = SKILL_HEADING_RE.match(line)
        if heading:
            flush()
            current = heading.group(1)
            skills.setdefault(current, {})
            section = None
            continue

        if current is None:
            continue

        stripped = line.strip()
        if stripped == "**Description**":
            flush()
            section = "description"
            continue
        if stripped == "**Prompt Command**":
            flush()
            section = "prompt_command"
            continue

        if section is None:
            continue

        # fence handling
        if stripped.startswith("```"):
            if not in_fence:
                in_fence = True
                fence_lang = stripped[3:].strip() or None
                buffer = []
            else:
                in_fence = False
                # snapshot the buffer to skills now; ignore subsequent prose
                if buffer:
                    skills[current][section] = "\n".join(buffer).strip("\n")
                buffer = []
                section = None
                fence_lang = None
            continue

        if in_fence:
            buffer.append(line)

    flush()
    return skills


def normalise_json(blob: str | None) -> str | None:
    if not blob:
        return None
    try:
        return json.dumps(json.loads(blob), sort_keys=True, separators=(",", ":"))
    except json.JSONDecodeError:
        return blob.strip()


def run_sf(*args: str) -> dict[str, Any]:
    # On Windows the SF CLI is exposed as `sf.cmd`; subprocess won't resolve
    # extensionless `sf` without the shell. shell=True covers both platforms.
    # We quote each argument explicitly so SOQL strings survive the shell.
    quoted = ["sf"] + [f'"{a}"' if any(c in a for c in ' "') else a for a in args] + ["--json"]
    cmd = " ".join(quoted)
    proc = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        cwd=ROOT,
        check=False,
        shell=True,
    )
    raw = proc.stdout
    idx = raw.find("{")
    if idx == -1:
        sys.stderr.write("STDOUT:\n" + raw + "\nSTDERR:\n" + proc.stderr)
        raise RuntimeError(f"`sf {' '.join(args)}` produced no JSON output")
    payload = json.loads(raw[idx:])
    if payload.get("status") not in (0, None):
        sys.stderr.write("Non-zero status from sf CLI:\n")
        sys.stderr.write(json.dumps(payload, indent=2))
        sys.stderr.write("\n")
        raise RuntimeError("sf CLI returned a failure payload (see above).")
    return payload


def fetch_org_snapshot() -> list[dict[str, Any]]:
    soql = (
        "SELECT Id, Name, ccai__Status__c, ccai__Description__c, "
        "ccai__Prompt_Command__c FROM ccai__AI_Prompt__c "
        "WHERE ccai__Agentic_Function_Class__c = 'GenericAgenticSkillsHandler' "
        "ORDER BY Name"
    )
    payload = run_sf("data", "query", "--query", soql)
    return payload["result"]["records"]


_ASCII_FOLDS = {
    "\u2014": " - ",   # em dash
    "\u2013": " - ",   # en dash
    "\u2026": "...",   # horizontal ellipsis
    "\u2018": "'",     # left single quote
    "\u2019": "'",     # right single quote
    "\u201C": '"',      # left double quote
    "\u201D": '"',      # right double quote
    "\u00A0": " ",     # nbsp
    "\u2192": "->",    # rightwards arrow
    "\u2190": "<-",    # leftwards arrow
    "\u00B7": "*",     # middle dot
    "\u2022": "*",     # bullet
}


def ascii_fold(text: str) -> str:
    """Replace high-codepoint typographic glyphs with ASCII fallbacks so
    that the SF Bulk API's cp1252 CSV parser (Windows default) does not
    mangle them into mojibake when storing the field value."""
    if not text:
        return text
    for src, dst in _ASCII_FOLDS.items():
        if src in text:
            text = text.replace(src, dst)
    return text


def build_csv(updates: list[dict[str, Any]], path: Path) -> None:
    fieldnames = [
        "Id",
        "ccai__Description__c",
        "ccai__Prompt_Command__c",
        "ccai__Status__c",
    ]
    with path.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=fieldnames, quoting=csv.QUOTE_ALL)
        writer.writeheader()
        for row in updates:
            writer.writerow(row)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--build",
        action="store_true",
        help="Regenerate updates.csv based on canonical doc + org snapshot.",
    )
    parser.add_argument(
        "--print-canonical",
        action="store_true",
        help="Print the parsed canonical doc as JSON and exit.",
    )
    args = parser.parse_args()

    canonical = parse_canonical(DOC)
    if len(canonical) != EXPECTED_SKILL_COUNT:
        sys.stderr.write(
            f"Parsed {len(canonical)} skills from canonical doc, expected {EXPECTED_SKILL_COUNT}.\n"
        )
        return 2

    for name, payload in canonical.items():
        missing = {"description", "prompt_command"} - payload.keys()
        if missing:
            sys.stderr.write(f"Skill {name} is missing: {missing}\n")
            return 3

    if args.print_canonical:
        json.dump(canonical, sys.stdout, indent=2, ensure_ascii=False)
        return 0

    if not args.build:
        sys.stdout.write(
            f"Parsed {len(canonical)} skills from {DOC.relative_to(ROOT)}; "
            "rerun with --build to refresh updates.csv against the org.\n"
        )
        return 0

    org_records = fetch_org_snapshot()
    ORG_SNAPSHOT.write_text(
        json.dumps(org_records, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )
    org_index = {rec["Name"]: rec for rec in org_records}

    missing_in_org = sorted(set(canonical) - set(org_index))
    extra_in_org = sorted(set(org_index) - set(canonical))
    if missing_in_org or extra_in_org:
        sys.stderr.write(
            "Skill mismatch between canonical doc and org!\n"
            f"  Missing in org: {missing_in_org}\n"
            f"  Extra in org:   {extra_in_org}\n"
        )

    updates: list[dict[str, Any]] = []
    summary: list[tuple[str, list[str]]] = []
    for name, target in sorted(canonical.items()):
        record = org_index.get(name)
        if record is None:
            continue
        diffs: list[str] = []

        target_desc = ascii_fold(shrink_description(target["description"]))
        if (record.get("ccai__Description__c") or "").strip() != target_desc:
            diffs.append("description")

        target_cmd_clean = ascii_fold(target["prompt_command"])
        target_cmd_norm = normalise_json(target_cmd_clean)
        org_cmd_norm = normalise_json(record.get("ccai__Prompt_Command__c"))
        if target_cmd_norm != org_cmd_norm:
            diffs.append("prompt_command")

        desired_status = "Active"
        if (record.get("ccai__Status__c") or "") != desired_status:
            diffs.append(f"status({record.get('ccai__Status__c')}->{desired_status})")

        if diffs:
            updates.append(
                {
                    "Id": record["Id"],
                    "ccai__Description__c": target_desc,
                    "ccai__Prompt_Command__c": target_cmd_clean,
                    "ccai__Status__c": desired_status,
                }
            )
            summary.append((name, diffs))

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    build_csv(updates, UPDATES_CSV)

    sys.stdout.write(
        f"Canonical skills: {len(canonical)} | Org records: {len(org_records)}\n"
        f"Records needing update: {len(updates)}\n"
        f"CSV: {UPDATES_CSV.relative_to(ROOT)}\n\n"
    )
    for name, diffs in summary:
        sys.stdout.write(f"  - {name}: {', '.join(diffs)}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
