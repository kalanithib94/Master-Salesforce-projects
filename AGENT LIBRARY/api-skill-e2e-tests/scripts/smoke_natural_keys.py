# -*- coding: utf-8 -*-
"""Smoke: fetch case by CaseNumber/Subject; create case by Account name."""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from invoke_skill import resolve_prompt_id  # noqa: E402
from sf_rest import load_config, rest_json, session  # noqa: E402


def soql(q: str) -> dict:
    r = subprocess.run(
        f'sf data query -q "{q}" -o "Master Dev" --json',
        shell=True,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    return json.loads(r.stdout or "{}")


def invoke(token, base, prompt_id: str, payload: dict) -> tuple[int, dict]:
    return rest_json(
        token,
        base,
        "POST",
        "/services/apexrest/ccai/v1/invokeAgentSkill/",
        {"promptId": prompt_id, "data": payload},
        timeout=180,
    )


def main() -> int:
    cfg = load_config()
    org = cfg.get("targetOrg", "Master Dev")
    token, base = session(org)
    agent = cfg.get("agentDeveloperName") or cfg.get("agentName")
    inv = Path(__file__).resolve().parent / "results" / "org_inventory.json"
    if inv.exists():
        data = json.loads(inv.read_text(encoding="utf-8"))
        if data.get("agents"):
            agent = data["agents"][0].get("DeveloperName") or data["agents"][0].get("Name")

    recs = soql(
        "SELECT CaseNumber, Subject FROM Case WHERE Subject = 'E2E Skill Test Case' LIMIT 1"
    ).get("result", {}).get("records") or []
    if not recs:
        print("No E2E case found")
        return 1
    cn = recs[0]["CaseNumber"]
    print(f"Seed case CaseNumber={cn}")

    pid = resolve_prompt_id(token, base, agent, "fetch_case_details")
    if not pid:
        print("fetch_case_details not linked")
        return 2

    for label, payload in [
        ("CaseNumber only", {"CaseNumber": cn}),
        ("Subject only", {"Subject": "E2E Skill Test Case"}),
        ("Id as CaseNumber text", {"Id": cn}),
    ]:
        code, body = invoke(token, base, pid, payload)
        apex = body.get("response") or body.get("result") or body
        # handler may nest JSON string
        raw = body
        print(f"\n=== {label} HTTP {code} status={body.get('status')} ===")
        print(json.dumps(body, indent=2)[:900])

    # create_case with AccountName (no Account Id)
    pid2 = resolve_prompt_id(token, base, agent, "create_case")
    if pid2:
        code, body = invoke(
            token,
            base,
            pid2,
            {
                "Subject": "E2E Natural Key Case Smoke",
                "AccountName": "E2E Skill Test Account",
                "ContactName": "Rose E2EContact",
                "Origin": "Web",
            },
        )
        print(f"\n=== create_case by name HTTP {code} status={body.get('status')} ===")
        print(json.dumps(body, indent=2)[:1200])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
