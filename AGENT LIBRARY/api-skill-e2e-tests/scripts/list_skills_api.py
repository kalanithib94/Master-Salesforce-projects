# -*- coding: utf-8 -*-
"""POST getAgentSkills — list skills the current user can invoke."""
from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from sf_rest import load_config, rest_json, session  # noqa: E402

OUT = Path(__file__).resolve().parent / "results"
OUT.mkdir(exist_ok=True)


def main() -> int:
    cfg = load_config()
    org = sys.argv[1] if len(sys.argv) > 1 else cfg.get("targetOrg", "Master Dev")
    agent = sys.argv[2] if len(sys.argv) > 2 else (
        cfg.get("agentDeveloperName") or cfg.get("agentName")
    )
    token, base = session(org)
    # Prefer inventory DevName file if present
    inv = OUT / "org_inventory.json"
    if inv.exists() and not (len(sys.argv) > 2):
        data = json.loads(inv.read_text(encoding="utf-8"))
        if data.get("agents"):
            agent = data["agents"][0].get("DeveloperName") or data["agents"][0].get("Name")
    print(f"Org={org} agentName={agent!r}")
    code, body = rest_json(
        token, base, "POST", "/services/apexrest/ccai/v1/getAgentSkills/", {"agentName": agent}
    )
    print(f"HTTP {code}")
    print(json.dumps(body, indent=2)[:5000])
    out = OUT / "get_agent_skills.json"
    out.write_text(json.dumps({"agentName": agent, "http": code, "body": body}, indent=2), encoding="utf-8")
    print("Wrote", out)
    skills = (body or {}).get("skills") or []
    print(f"Skill count: {len(skills)}")
    for s in skills:
        print(f"  {s.get('name'):40} {s.get('promptId')}")
    return 0 if (body or {}).get("status") == "Success" else 1


if __name__ == "__main__":
    raise SystemExit(main())
