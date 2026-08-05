# -*- coding: utf-8 -*-
"""Invoke one agent skill via REST and print Apex/handler response."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from sf_rest import load_config, rest_json, session  # noqa: E402

OUT = Path(__file__).resolve().parent / "results"
OUT.mkdir(exist_ok=True)


def resolve_prompt_id(token, base, agent: str, skill: str) -> str | None:
    code, body = rest_json(
        token, base, "POST", "/services/apexrest/ccai/v1/getAgentSkills/", {"agentName": agent}
    )
    if code != 200 or (body or {}).get("status") != "Success":
        print("getAgentSkills failed", code, body)
        return None
    for s in body.get("skills") or []:
        if (s.get("name") or "").strip() == skill:
            return s.get("promptId")
    return None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("org", nargs="?", default=None)
    ap.add_argument("skill", help="Skill / prompt API name, e.g. fuzzy_search_contacts")
    ap.add_argument("--data", default="{}", help="JSON object for skill parameters")
    ap.add_argument(
        "--data-file",
        default=None,
        help="Path to JSON file of parameters (preferred on Windows/PowerShell)",
    )
    ap.add_argument("--prompt-id", default=None, help="Skip lookup; use this prompt Id")
    ap.add_argument("--agent", default=None)
    args = ap.parse_args()

    cfg = load_config()
    org = args.org or cfg.get("targetOrg", "Master Dev")
    agent = args.agent or cfg.get("agentDeveloperName") or cfg.get("agentName")
    inv = OUT / "org_inventory.json"
    if inv.exists() and not args.agent:
        data = json.loads(inv.read_text(encoding="utf-8"))
        if data.get("agents"):
            agent = data["agents"][0].get("DeveloperName") or data["agents"][0].get("Name")

    try:
        if args.data_file:
            payload = json.loads(Path(args.data_file).read_text(encoding="utf-8-sig"))
        else:
            payload = json.loads(args.data)
    except (json.JSONDecodeError, OSError) as e:
        print("Invalid --data / --data-file:", e)
        return 1

    token, base = session(org)
    prompt_id = args.prompt_id
    if not prompt_id:
        prompt_id = resolve_prompt_id(token, base, agent, args.skill)
    if not prompt_id:
        print(f"Skill not linked to agent (or wrong name): {args.skill}")
        print("Tip: run list_skills_api.py; skill must be on agent.")
        return 2

    print(f"invokeAgentSkill skill={args.skill} promptId={prompt_id}")
    print(f"data={json.dumps(payload)}")
    code, body = rest_json(
        token,
        base,
        "POST",
        "/services/apexrest/ccai/v1/invokeAgentSkill/",
        {"promptId": prompt_id, "data": payload},
        timeout=180,
    )
    print(f"HTTP {code}")
    print(json.dumps(body, indent=2)[:8000])

    out = OUT / f"invoke_{args.skill}.json"
    out.write_text(
        json.dumps(
            {
                "skill": args.skill,
                "promptId": prompt_id,
                "data": payload,
                "http": code,
                "body": body,
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    print("Wrote", out)
    status = (body or {}).get("status")
    return 0 if status == "Success" else 1


if __name__ == "__main__":
    raise SystemExit(main())
