# -*- coding: utf-8 -*-
"""Inventory GPTfy agents/skills and Apex handlers on a connected org."""
from __future__ import annotations

import json
import os
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path

OUT = Path(__file__).resolve().parent / "results"
OUT.mkdir(parents=True, exist_ok=True)


def sf_json(args: list[str]) -> dict:
    # Windows CLI is typically `sf.cmd`
    cmd = ["sf"] + args + ["--json"]
    p = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        shell=True,  # resolve sf.cmd on PATH (Windows)
    )
    try:
        return json.loads(p.stdout or p.stderr or "{}")
    except json.JSONDecodeError:
        return {"status": 1, "message": p.stderr or p.stdout}


def main() -> int:
    org = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("SF_TARGET_ORG", "Master Dev")
    disp = sf_json(["org", "display", "-o", org])
    if disp.get("status") != 0:
        print("FAIL org display:", disp.get("message") or disp)
        return 1
    r = disp["result"]
    token, base = r["accessToken"], r["instanceUrl"].rstrip("/")
    print(f"Org: {r.get('username')} @ {base}")

    def rest(method: str, path: str, body=None):
        data = None if body is None else json.dumps(body).encode("utf-8")
        req = urllib.request.Request(
            base + path,
            data=data,
            headers={
                "Authorization": "Bearer " + token,
                "Content-Type": "application/json",
                "Accept": "application/json",
            },
            method=method,
        )
        try:
            with urllib.request.urlopen(req, timeout=90) as resp:
                return resp.status, json.loads(resp.read().decode())
        except urllib.error.HTTPError as e:
            raw = e.read().decode("utf-8", errors="replace")
            try:
                return e.code, json.loads(raw)
            except Exception:
                return e.code, {"raw": raw[:2000]}

    ver = "v67.0"
    report: dict = {"org": r.get("username"), "instanceUrl": base, "agents": [], "prompts": [], "apex": []}

    code, agents = rest(
        "GET",
        f"/services/data/{ver}/query?q="
        "SELECT+Id,Name,ccai__Status__c,ccai__Developer_Name__c,ccai__AI_Model__c+"
        "FROM+ccai__AI_Agent__c+ORDER+BY+CreatedDate+DESC",
    )
    print(f"\nAgents HTTP {code} total={agents.get('totalSize')}")
    for a in agents.get("records") or []:
        rec = {
            "Id": a.get("Id"),
            "Name": a.get("Name"),
            "Status": a.get("ccai__Status__c"),
            "DeveloperName": a.get("ccai__Developer_Name__c"),
            "AIModel": a.get("ccai__AI_Model__c"),
            "skills": [],
        }
        print(f"  {rec['Name']} | {rec['Status']} | DevName={rec['DeveloperName']!r}")
        for key in (rec["DeveloperName"], rec["Name"]):
            if not key:
                continue
            c2, sk = rest("POST", "/services/apexrest/ccai/v1/getAgentSkills/", {"agentName": key})
            print(f"    getAgentSkills({key!r}) HTTP {c2} status={sk.get('status')} msg={sk.get('message')!r} n={len(sk.get('skills') or [])}")
            if sk.get("status") == "Success" and sk.get("skills"):
                for s in sk["skills"]:
                    rec["skills"].append(
                        {
                            "name": s.get("name"),
                            "promptId": s.get("promptId"),
                            "description": s.get("description"),
                            "promptCommand": s.get("promptCommand"),
                        }
                    )
                    print(f"      - {s.get('name')}  {s.get('promptId')}")
                break
        report["agents"].append(rec)

    code, prompts = rest(
        "GET",
        f"/services/data/{ver}/query?q="
        "SELECT+Id,Name,ccai__Status__c,ccai__Type__c,ccai__Agentic_Function_Class__c,"
        "ccai__Description__c+FROM+ccai__AI_Prompt__c+WHERE+ccai__Type__c=%27Agentic%27+ORDER+BY+Name",
    )
    print(f"\nAgentic prompts HTTP {code} total={prompts.get('totalSize')}")
    for p in prompts.get("records") or []:
        row = {
            "Id": p.get("Id"),
            "Name": p.get("Name"),
            "Status": p.get("ccai__Status__c"),
            "Class": p.get("ccai__Agentic_Function_Class__c"),
            "Description": p.get("ccai__Description__c"),
        }
        report["prompts"].append(row)
        print(f"  {row['Name']:40} | {row['Class']}")

    code, apex = rest(
        "GET",
        f"/services/data/{ver}/tooling/query?q="
        "SELECT+Name+FROM+ApexClass+WHERE+Name+LIKE+%27%25AgenticSkills%25%27+ORDER+BY+Name",
    )
    print(f"\nApex *AgenticSkills* HTTP {code} total={apex.get('totalSize')}")
    for x in apex.get("records") or []:
        report["apex"].append(x.get("Name"))
        print(f"  {x.get('Name')}")

    # data mapping / model ids (needed for seed)
    for label, soql in (
        (
            "dataMappings",
            "SELECT+Id,Name+FROM+ccai__AI_Data_Extraction_Mapping__c+ORDER+BY+CreatedDate+DESC+LIMIT+5",
        ),
        (
            "aiModels",
            "SELECT+Id,Name+FROM+ccai__AI_Connection__c+ORDER+BY+CreatedDate+DESC+LIMIT+5",
        ),
    ):
        code, rows = rest("GET", f"/services/data/{ver}/query?q={soql}")
        print(f"\n{label} HTTP {code} total={rows.get('totalSize')}")
        report[label] = []
        for x in rows.get("records") or []:
            report[label].append({"Id": x.get("Id"), "Name": x.get("Name")})
            print(f"  {x.get('Id')}  {x.get('Name')}")

    out = OUT / "org_inventory.json"
    out.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(f"\nWrote {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
