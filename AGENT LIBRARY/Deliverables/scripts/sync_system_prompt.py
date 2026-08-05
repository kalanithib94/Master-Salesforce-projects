"""
sync_system_prompt.py
=====================

Pushes `Deliverables/docs/GenericCRMAssistant_SystemPrompt.txt` (the canonical
v1.3.x system prompt) to the All-in-One AI Agent record's
`ccai__System_Prompt__c` field via the REST API. We can't use Bulk API CSV
because the prompt contains plenty of high-codepoint glyphs (box drawing,
arrows, warning sign) that the bulk loader's cp1252 default mangles, and we
can't use anonymous Apex because the prompt is bigger than the 32 KB script
cap. PATCHing the JSON body keeps every codepoint intact.

Usage:
    python scripts/sync_system_prompt.py
    python scripts/sync_system_prompt.py --agent-id a0sJ9000001BSF5IAO
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CANONICAL = ROOT / "docs" / "GenericCRMAssistant_SystemPrompt.txt"
DEFAULT_AGENT_ID = "a0sJ9000001BSF5IAO"
API_VERSION = "v66.0"


def run_sf(*args: str, capture_bytes: bool = False) -> dict | str:
    cmd = " ".join(["sf"] + [f'"{a}"' if " " in a else a for a in args])
    proc = subprocess.run(cmd, capture_output=True, shell=True, cwd=ROOT, check=False)
    raw = proc.stdout.decode("utf-8", errors="replace")
    if capture_bytes:
        return raw
    idx = raw.find("{")
    if idx == -1:
        sys.stderr.write("STDOUT:\n" + raw + "\nSTDERR:\n" + proc.stderr.decode("utf-8", errors="replace"))
        raise RuntimeError(f"`sf {' '.join(args)}` produced no JSON output")
    return json.loads(raw[idx:])


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--agent-id", default=DEFAULT_AGENT_ID)
    parser.add_argument(
        "--source",
        default=str(CANONICAL.relative_to(ROOT)),
        help="Path (relative to project root) to the canonical system prompt file.",
    )
    args = parser.parse_args()

    source = (ROOT / args.source).resolve()
    text = source.read_text(encoding="utf-8")
    text = text.replace("\r\n", "\n")  # Salesforce stores LF, comparing later is simpler
    sys.stdout.write(f"Loaded {source.relative_to(ROOT)} ({len(text)} chars)\n")

    body_path = ROOT / "scripts" / "sysprompt_body.json"
    body_path.parent.mkdir(parents=True, exist_ok=True)
    body_path.write_text(
        json.dumps({"ccai__System_Prompt__c": text}, ensure_ascii=False),
        encoding="utf-8",
    )

    endpoint = f"/services/data/{API_VERSION}/sobjects/ccai__AI_Agent__c/{args.agent_id}"
    sys.stdout.write(f"PATCH {endpoint}\n")
    raw = run_sf(
        "api", "request", "rest",
        "--method", "PATCH",
        endpoint,
        "--body", f"@{body_path.as_posix()}",
        "--header", "Content-Type: application/json",
        "--json",
        capture_bytes=True,
    )
    sys.stdout.write(raw + "\n")
    return 0 if "error" not in raw.lower() else 1


if __name__ == "__main__":
    raise SystemExit(main())
