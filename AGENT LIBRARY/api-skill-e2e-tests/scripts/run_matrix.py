# -*- coding: utf-8 -*-
"""
Run invokeAgentSkill for every skill linked to the agent (or all agentic prompts).
Builds payloads from fixtures + PROMPT_COMMANDS_BY_SKILL required fields + org sample Ids.
Writes matrix report JSON. Does not modify product code.
"""
from __future__ import annotations

import json
import re
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from sf_rest import load_config, rest_json, session  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
OUT = Path(__file__).resolve().parent / "results"
OUT.mkdir(exist_ok=True)

# Prefer schema required names; fall back to these when still empty.
PLACEHOLDERS = {
    "searchTerm": "Rose",
    "search_term": "Rose",
    "Name": "Edge",
    "Subject": "E2E smoke — ignore",
    "CommentBody": "E2E comment body — ignore",
    "Description": "E2E description — ignore",
    "Status": "Closed",
    "Role": "Decision Maker",
    "TeamRole": "Customer Contact",
    "Quantity": 1,
    "fields": {"Description": "E2E smoke field"},
}


def soql(token, base, q):
    from urllib.parse import quote

    path = f"/services/data/v67.0/query?q={quote(q)}"
    code, body = rest_json(token, base, "GET", path)
    if code != 200:
        return []
    return body.get("records") or []


def load_sample_ids(token, base) -> dict:
    ids = {}
    pairs = [
        ("AccountId", "SELECT Id FROM Account LIMIT 1"),
        ("ContactId", "SELECT Id FROM Contact LIMIT 1"),
        ("OpportunityId", "SELECT Id FROM Opportunity LIMIT 1"),
        ("CaseId", "SELECT Id FROM Case LIMIT 1"),
        ("LeadId", "SELECT Id FROM Lead LIMIT 1"),
        ("CampaignId", "SELECT Id FROM Campaign LIMIT 1"),
        ("Product2Id", "SELECT Id FROM Product2 LIMIT 1"),
        ("TaskId", "SELECT Id FROM Task LIMIT 1"),
        ("UserId", "SELECT Id FROM User WHERE IsActive = true LIMIT 1"),
        ("ContractId", "SELECT Id FROM Contract LIMIT 1"),
        ("OrderId", "SELECT Id FROM Order LIMIT 1"),
        ("Pricebook2Id", "SELECT Id FROM Pricebook2 WHERE IsActive = true LIMIT 1"),
    ]
    for key, q in pairs:
        try:
            rows = soql(token, base, q)
            if rows:
                ids[key] = rows[0]["Id"]
        except Exception:
            pass
    # Aliases used in various skill schemas
    if ids.get("AccountId"):
        ids["Id"] = ids["AccountId"]  # only default for pure Account skills — overridden per skill below
        ids["WhatId"] = ids["AccountId"]
        ids["account_id"] = ids["AccountId"]
        ids["record_id"] = ids["AccountId"]
        ids["ParentId"] = ids.get("CaseId") or ids["AccountId"]
    if ids.get("ContactId"):
        ids["WhoId"] = ids["ContactId"]
        ids["contact_id"] = ids["ContactId"]
    return ids


def build_payload(skill: str, schema: dict | None, samples: dict, fixtures: dict) -> dict:
    if skill in fixtures and isinstance(fixtures[skill], dict):
        base = dict(fixtures[skill])
    else:
        base = {}
    required = (schema or {}).get("required") or []
    props = {p["name"]: p for p in (schema or {}).get("properties") or []}

    # Per-skill Id preference
    id_for_skill = None
    for needle, key in [
        ("contact", "ContactId"),
        ("account", "AccountId"),
        ("opportunit", "OpportunityId"),
        ("case", "CaseId"),
        ("lead", "LeadId"),
        ("campaign", "CampaignId"),
        ("product", "Product2Id"),
        ("task", "TaskId"),
        ("contract", "ContractId"),
        ("order", "OrderId"),
        ("quote", "OpportunityId"),
        ("partner", "AccountId"),
        ("asset", "AccountId"),
        ("work_order", "CaseId"),
        ("service", "CaseId"),
    ]:
        if needle in skill:
            id_for_skill = samples.get(key)
            break
    if not id_for_skill:
        id_for_skill = samples.get("AccountId")

    for req in required:
        if req in base and base[req] not in (None, "", "REPLACE_ACCOUNT_ID"):
            continue
        if req in samples:
            base[req] = samples[req]
        elif req in ("Id", "record_id", "account_id"):
            base[req] = id_for_skill
        elif req.endswith("Id") and req in samples:
            base[req] = samples[req]
        elif req in PLACEHOLDERS:
            base[req] = PLACEHOLDERS[req]
        elif props.get(req, {}).get("type") == "boolean":
            base[req] = True
        elif props.get(req, {}).get("type") == "number":
            base[req] = 1
        elif props.get(req, {}).get("type") == "object":
            base[req] = {"Description": "E2E smoke"}
        else:
            base[req] = "E2E-smoke"

    # Fill common optional Id-like keys that show up often
    for k, v in list(base.items()):
        if v == "REPLACE_ACCOUNT_ID":
            base[k] = samples.get("AccountId")
    return base


def classify(body: dict | None, http: int) -> str:
    if http != 200:
        return "http_error"
    if not body:
        return "empty"
    st = body.get("status")
    if st != "Success":
        return "api_fail"
    data = body.get("data")
    if isinstance(data, str):
        try:
            data = json.loads(data)
        except json.JSONDecodeError:
            return "success_opaque"
    if isinstance(data, dict):
        if data.get("success") is False or data.get("error"):
            return "handler_error"
        if data.get("success") is True:
            return "handler_ok"
    return "success_opaque"


def parse_prompt_command(raw) -> dict | None:
    if not raw:
        return None
    if isinstance(raw, dict):
        return raw
    try:
        return json.loads(raw)
    except (json.JSONDecodeError, TypeError):
        return None


def schema_from_live(skill_row: dict, schemas_lib: dict) -> dict | None:
    """Prefer live promptCommand on agent; else catalog schema."""
    live = parse_prompt_command(skill_row.get("promptCommand"))
    if live and (live.get("required") or live.get("properties")):
        props = live.get("properties") or {}
        if isinstance(props, dict):
            prop_list = [
                {"name": k, **(v if isinstance(v, dict) else {})} for k, v in props.items()
            ]
        else:
            prop_list = props
        return {"required": live.get("required") or [], "properties": prop_list}
    return schemas_lib.get(skill_row.get("name") or "")


def main() -> int:
    cfg = load_config()
    org = sys.argv[1] if len(sys.argv) > 1 else cfg.get("targetOrg", "Master Dev")
    only = sys.argv[2] if len(sys.argv) > 2 else None
    agent_dev = cfg.get("agentDeveloperName")
    inv = OUT / "org_inventory.json"
    if inv.exists():
        invd = json.loads(inv.read_text(encoding="utf-8"))
        if invd.get("agents"):
            agent_dev = invd["agents"][0].get("DeveloperName") or agent_dev

    schemas_path = ROOT / cfg.get("promptsDocPath", "../Deliverables/docs/PROMPT_COMMANDS_BY_SKILL.json")
    if not schemas_path.is_absolute():
        schemas_path = (ROOT / schemas_path).resolve()
    schemas = json.loads(schemas_path.read_text(encoding="utf-8")) if schemas_path.exists() else {}

    fixtures_path = ROOT / "fixtures" / "smoke_payloads.json"
    fixtures = json.loads(fixtures_path.read_text(encoding="utf-8")) if fixtures_path.exists() else {}
    fixtures = {k: v for k, v in fixtures.items() if not k.startswith("_")}

    token, base = session(org)
    samples = load_sample_ids(token, base)
    (OUT / "sample_ids.json").write_text(json.dumps(samples, indent=2), encoding="utf-8")

    code, body = rest_json(
        token, base, "POST", "/services/apexrest/ccai/v1/getAgentSkills/", {"agentName": agent_dev}
    )
    skills = []
    if code == 200 and (body or {}).get("status") == "Success":
        skills = body.get("skills") or []
    else:
        print("getAgentSkills failed", code, body)
        # fallback: inventory prompts
        if inv.exists():
            for p in invd.get("prompts") or []:
                skills.append(
                    {
                        "name": p.get("Name"),
                        "promptId": p.get("Id"),
                        "description": p.get("Description"),
                    }
                )

    if only:
        skills = [s for s in skills if s.get("name") == only]

    print(f"Invoking {len(skills)} skills on agent DevName={agent_dev!r}")
    report = {
        "org": org,
        "agentDeveloperName": agent_dev,
        "sampleIds": samples,
        "counts": {},
        "results": [],
    }
    tallies: dict[str, int] = {}

    for i, s in enumerate(skills, 1):
        name = (s.get("name") or "").strip()
        pid = s.get("promptId")
        schema = schema_from_live(s, schemas)
        payload = build_payload(name, schema, samples, fixtures)
        print(f"[{i}/{len(skills)}] {name} ...", end=" ", flush=True)
        t0 = time.time()
        http, resp = rest_json(
            token,
            base,
            "POST",
            "/services/apexrest/ccai/v1/invokeAgentSkill/",
            {"promptId": pid, "data": payload},
            timeout=180,
        )
        elapsed = round(time.time() - t0, 2)
        cat = classify(resp, http)
        tallies[cat] = tallies.get(cat, 0) + 1
        apex_data = None
        if resp and isinstance(resp.get("data"), str):
            try:
                apex_data = json.loads(resp["data"])
            except json.JSONDecodeError:
                apex_data = resp.get("data")
        elif resp:
            apex_data = resp.get("data")

        err_snip = None
        if isinstance(apex_data, dict):
            err_snip = apex_data.get("error") or apex_data.get("message")
        elif resp:
            err_snip = resp.get("message") or str(resp)[:300]

        entry = {
            "skill": name,
            "promptId": pid,
            "payload": payload,
            "http": http,
            "apiStatus": (resp or {}).get("status"),
            "category": cat,
            "elapsedSec": elapsed,
            "errorSnippet": (str(err_snip)[:500] if err_snip else None),
            "apexData": apex_data if not isinstance(apex_data, str) or len(apex_data) < 2000 else apex_data[:2000],
        }
        report["results"].append(entry)
        print(cat, f"({elapsed}s)")
        time.sleep(0.15)

    report["counts"] = tallies
    out = OUT / "matrix_report.json"
    out.write_text(json.dumps(report, indent=2), encoding="utf-8")

    # Markdown summary
    md = ["# E2E Skill Matrix Report", "", f"Org: `{org}`", f"Agent DevName: `{agent_dev}`", ""]
    md.append("## Counts")
    for k, v in sorted(tallies.items()):
        md.append(f"- **{k}**: {v}")
    md.append("")
    md.append("## Results")
    md.append("| Skill | Category | Error |")
    md.append("|-------|----------|-------|")
    for e in report["results"]:
        err = (e.get("errorSnippet") or "").replace("|", "\\|").replace("\n", " ")[:120]
        md.append(f"| `{e['skill']}` | {e['category']} | {err} |")
    md_path = OUT / "matrix_report.md"
    md_path.write_text("\n".join(md), encoding="utf-8")
    print(f"\nWrote {out} and {md_path}")
    print("Counts:", tallies)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
