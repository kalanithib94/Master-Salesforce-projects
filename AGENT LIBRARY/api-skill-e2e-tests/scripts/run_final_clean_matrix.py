# -*- coding: utf-8 -*-
"""
Final clean Master Dev run:
  1) Delete all prior E2E CRM test data
  2) Deploy Agentic handlers from Deliverables
  3) Infra-only seed (product/PBE/queue/role/user)
  4) Bootstrap core CRM via skills (create → capture Ids/names)
  5) Resolve children / Ids by fixed names
  6) Full strict matrix + MAIN/archive report

Usage:
  python run_final_clean_matrix.py ["Master Dev"]
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_main_report import publish_main_and_archive  # noqa: E402
from run_seeded_matrix import (  # noqa: E402
    apex_business_success,
    build_payload,
    parse_prompt_command,
    parse_seed,
)
from sf_rest import load_config, rest_json, session  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = Path(__file__).resolve().parent
OUT = SCRIPTS / "results"
OUT.mkdir(exist_ok=True)

# Deterministic names used in skill create → fetch chain
NAMES = {
    "account": "E2E Skill Test Account",
    "partner": "E2E Partner Account",
    "contact_fn": "Rose",
    "contact_ln": "E2EContact",
    "contact_b_fn": "Sam",
    "contact_b_ln": "E2EContactB",
    "lead_fn": "E2E",
    "lead_ln": "E2ELead",
    "lead_open_ln": "E2ELeadOpen",
    "campaign": "E2E Skill Test Campaign",
    "opportunity": "E2E Skill Test Opp",
    "case_subject": "E2E Skill Test Case",
    "task": "E2E Skill Test Task",
    "event": "E2E Skill Test Event",
    "asset": "E2E Skill Test Asset",
    "work_order": "E2E Skill Test Work Order",
}


def run(cmd: str) -> tuple[int, str]:
    p = subprocess.run(
        cmd,
        shell=True,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    return p.returncode, (p.stdout or "") + (p.stderr or "")


def invoke_skill(token, base, skills_by_name: dict, skill: str, payload: dict) -> dict:
    s = skills_by_name.get(skill)
    if not s:
        return {
            "ok": False,
            "category": "fail_missing_class",
            "error": f"skill not linked: {skill}",
            "http": 0,
            "body": None,
            "apex": {},
            "skill": skill,
            "request": payload,
        }
    http, body = rest_json(
        token,
        base,
        "POST",
        "/services/apexrest/ccai/v1/invokeAgentSkill/",
        {"promptId": s["promptId"], "data": payload},
        timeout=180,
    )
    cat, snip = apex_business_success(body, http)
    apex = None
    if body and isinstance(body.get("data"), str):
        try:
            apex = json.loads(body["data"])
        except json.JSONDecodeError:
            apex = body.get("data")
    elif body:
        apex = body.get("data")
    return {
        "ok": cat == "pass",
        "category": cat,
        "error": snip,
        "http": http,
        "body": body,
        "apex": apex if isinstance(apex, dict) else {},
        "skill": skill,
        "request": payload,
    }


def apex_id(apex: dict | None) -> str | None:
    if not isinstance(apex, dict):
        return None
    for k in ("recordId", "Id", "id"):
        v = apex.get(k)
        if v:
            return str(v)
    return None


def link_all_agentic_skills(org: str) -> None:
    apex = """
List<ccai__AI_Agent__c> agents = [SELECT Id FROM ccai__AI_Agent__c WHERE Name = 'GPTfy Master Agent' LIMIT 1];
if (agents.isEmpty()) { System.debug('no agent'); } else {
  Id aid = agents[0].Id;
  for (ccai__AI_Prompt__c p : [SELECT Id, Name FROM ccai__AI_Prompt__c WHERE ccai__Type__c = 'Agentic']) {
    List<ccai__AI_Agent_Skill__c> ex = [
      SELECT Id FROM ccai__AI_Agent_Skill__c WHERE ccai__AI_Agent__c = :aid AND ccai__AI_Prompt__c = :p.Id LIMIT 1
    ];
    if (ex.isEmpty()) {
      insert new ccai__AI_Agent_Skill__c(ccai__AI_Agent__c = aid, ccai__AI_Prompt__c = p.Id);
      System.debug('Linked ' + p.Name);
    }
  }
}
"""
    tmp = OUT / "_link_skills.apex"
    tmp.write_text(apex, encoding="utf-8")
    run(f'sf apex run --file "{tmp}" --target-org "{org}"')


def skill_bootstrap(token, base, skills_by_name: dict, seed: dict) -> list[dict]:
    """Create required CRM in sequence via skills; return bootstrap result cards."""
    chain: list[dict] = []
    acc = NAMES["account"]
    partner = NAMES["partner"]

    steps = [
        (
            "create_account",
            {
                "Name": acc,
                "Description": "E2E_SKILL_TEST",
                "Phone": "555-0100",
                "Website": "https://e2e.example.com",
            },
        ),
        (
            "create_account",
            {"Name": partner, "Description": "E2E_SKILL_TEST", "Type": "Partner Reseller"},
        ),
        (
            "create_contact",
            {
                "FirstName": NAMES["contact_fn"],
                "LastName": NAMES["contact_ln"],
                "AccountName": acc,
                "Email": "e2e.contact@example.com",
                "Phone": "555-0101",
                "Description": "E2E_SKILL_TEST",
            },
        ),
        (
            "create_contact",
            {
                "FirstName": NAMES["contact_b_fn"],
                "LastName": NAMES["contact_b_ln"],
                "AccountName": acc,
                "Email": "e2e.b@example.com",
                "Description": "E2E_SKILL_TEST",
            },
        ),
        (
            "create_lead",
            {
                "FirstName": NAMES["lead_fn"],
                "LastName": NAMES["lead_ln"],
                "Company": acc,
                "Email": f"e2e.lead.{int(time.time())}@example.com",
                "Status": "Open - Not Contacted",
                "Description": "E2E_SKILL_TEST",
            },
        ),
        (
            "create_lead",
            {
                "FirstName": "Open",
                "LastName": NAMES["lead_open_ln"],
                "Company": acc,
                "Email": "e2e.lead.open@example.com",
                "Status": "Open - Not Contacted",
                "Description": "E2E_SKILL_TEST",
            },
        ),
        (
            "create_campaign",
            {
                "Name": NAMES["campaign"],
                "IsActive": True,
                "Status": "Planned",
                "Description": "E2E_SKILL_TEST",
            },
        ),
        (
            "create_opportunity",
            {
                "Name": NAMES["opportunity"],
                "AccountName": acc,
                "AccountId": acc,
                "StageName": "Prospecting",
                "CloseDate": "2026-09-15",
                "Description": "E2E_SKILL_TEST",
            },
        ),
        (
            "create_case",
            {
                "Subject": NAMES["case_subject"],
                "Status": "New",
                "Origin": "Web",
                "AccountName": acc,
                "ContactName": f"{NAMES['contact_fn']} {NAMES['contact_ln']}",
                "Description": "E2E_SKILL_TEST",
                "fields": {
                    "Subject": NAMES["case_subject"],
                    "Status": "New",
                    "Origin": "Web",
                    "Description": "E2E_SKILL_TEST",
                },
            },
        ),
        (
            "create_task",
            {
                "Subject": NAMES["task"],
                "WhatId": acc,
                "WhoId": f"{NAMES['contact_fn']} {NAMES['contact_ln']}",
                "Status": "Not Started",
                "Description": "E2E_SKILL_TEST",
            },
        ),
        (
            "create_event",
            {
                "Subject": NAMES["event"],
                "WhatId": acc,
                "StartDateTime": "2026-08-10T10:00:00.000Z",
                "EndDateTime": "2026-08-10T11:00:00.000Z",
                "Description": "E2E_SKILL_TEST",
            },
        ),
        (
            "create_work_order",
            {
                "Subject": NAMES["work_order"],
                "AccountName": acc,
                "AccountId": acc,
            },
        ),
        (
            "create_contract",
            {
                "AccountName": acc,
                "AccountId": acc,
                "Status": "Draft",
                "StartDate": "2026-08-05",
                "ContractTerm": 12,
            },
        ),
        # verify chain: natural-key fetch after creates (only skills linked on agent)
        ("fetch_account_related_lists", {"Name": acc, "AccountName": acc}),
        (
            "fetch_contact_details",
            {"Name": f"{NAMES['contact_fn']} {NAMES['contact_ln']}"},
        ),
        ("fetch_campaign_details", {"Name": NAMES["campaign"]}),
        ("fetch_opportunity_details", {"Name": NAMES["opportunity"]}),
        ("fetch_case_details", {"Subject": NAMES["case_subject"]}),
    ]

    for skill, payload in steps:
        print(f"  bootstrap {skill} ...", end=" ", flush=True)
        if skill not in skills_by_name:
            # tolerate slight key mismatches / missing optional skills
            print(f"skip (not linked)")
            chain.append({
                "ok": False, "category": "fail_missing_class", "error": f"not linked: {skill}",
                "http": 0, "apex": {}, "skill": skill, "request": payload,
            })
            continue
        r = invoke_skill(token, base, skills_by_name, skill, payload)
        print(r["category"], f"http={r['http']}")
        chain.append(r)
        rid = apex_id(r.get("apex") or {})
        apex = r.get("apex") or {}
        if skill == "create_account" and payload.get("Name") == acc and rid:
            seed["AccountId"] = rid
        if skill == "create_account" and payload.get("Name") == partner and rid:
            seed["PartnerAccountId"] = rid
        if skill == "create_contact" and payload.get("LastName") == NAMES["contact_ln"] and rid:
            seed["ContactId"] = rid
        if skill == "create_contact" and payload.get("LastName") == NAMES["contact_b_ln"] and rid:
            seed["ContactIdB"] = rid
        if skill == "create_lead" and payload.get("LastName") == NAMES["lead_ln"] and rid:
            seed["LeadId"] = rid
        if skill == "create_lead" and payload.get("LastName") == NAMES["lead_open_ln"] and rid:
            seed["LeadIdOpen"] = rid
        if skill == "create_campaign" and rid:
            seed["CampaignId"] = rid
        if skill == "create_opportunity" and rid:
            seed["OpportunityId"] = rid
        if skill == "create_case" and rid:
            seed["CaseId"] = rid
            if apex.get("CaseNumber"):
                seed["CaseNumber"] = str(apex["CaseNumber"])
        if skill == "create_task" and rid:
            seed["TaskId"] = rid
        if skill == "create_event" and rid:
            seed["EventId"] = rid
        if skill == "create_work_order" and rid:
            seed["WorkOrderId"] = rid
        if skill == "create_contract" and rid:
            seed["ContractId"] = rid
        if skill == "fetch_case_details" and isinstance(apex, dict):
            if apex.get("CaseNumber"):
                seed["CaseNumber"] = str(apex["CaseNumber"])
            if apex.get("Id"):
                seed["CaseId"] = str(apex["Id"])
        time.sleep(0.15)

    seed["SearchAccount"] = acc
    seed["SearchPartner"] = partner
    seed["SearchContact"] = f"{NAMES['contact_fn']} {NAMES['contact_ln']}"
    return chain


def main() -> int:
    cfg = load_config()
    org = sys.argv[1] if len(sys.argv) > 1 else cfg.get("targetOrg", "Master Dev")
    agent_dev = cfg.get("agentDeveloperName") or "IT_Helpdesk_Assistant05/08/2026, 11:47"

    print("=== 0) Deploy handlers ===")
    rc = subprocess.run(
        [sys.executable, str(SCRIPTS / "deploy_handlers.py"), org],
        cwd=str(SCRIPTS),
    ).returncode
    if rc != 0:
        print("WARN: deploy returned", rc, "— continuing if classes already present")

    print("=== 0b) Patch Prompt Commands (create chain, natural keys) ===")
    rc, out = run(
        f'sf apex run --file "{SCRIPTS / "patch_prompt_commands_chain.apex"}" --target-org "{org}"'
    )
    print(out[-1200:] if len(out) > 1200 else out)

    print("=== 1) Cleanup prior E2E CRM data ===")
    rc, out = run(f'sf apex run --file "{SCRIPTS / "cleanup_e2e_data.apex"}" --target-org "{org}"')
    print(out[-2000:] if len(out) > 2000 else out)
    if "CLEANUP_DONE=true" not in out and rc != 0:
        print("FATAL: cleanup failed")
        return 1

    print("=== 2) Infra-only seed ===")
    rc, out = run(f'sf apex run --file "{SCRIPTS / "seed_infra_only.apex"}" --target-org "{org}"')
    seed = parse_seed(out)
    print("Infra:", json.dumps(seed, indent=2))

    token, base = session(org)
    inv_path = OUT / "org_inventory.json"
    if inv_path.exists():
        inv = json.loads(inv_path.read_text(encoding="utf-8"))
        if inv.get("agents"):
            agent_dev = inv["agents"][0].get("DeveloperName") or agent_dev

    print("=== 3) Link agentic skills ===")
    link_all_agentic_skills(org)
    code, body = rest_json(
        token, base, "POST", "/services/apexrest/ccai/v1/getAgentSkills/", {"agentName": agent_dev}
    )
    skills = body.get("skills") if code == 200 and (body or {}).get("status") == "Success" else []
    skills_by_name = {(s.get("name") or "").strip(): s for s in (skills or []) if s.get("name")}
    print(f"Skills linked: {len(skills_by_name)}")
    if not skills_by_name:
        print("FATAL: no skills from getAgentSkills")
        return 1

    print("=== 4) Skill-sequenced bootstrap (create → fetch) ===")
    bootstrap = skill_bootstrap(token, base, skills_by_name, seed)
    (OUT / "bootstrap_chain.json").write_text(json.dumps(bootstrap, indent=2, default=str), encoding="utf-8")

    print("=== 5) Resolve children Ids by names ===")
    rc, out = run(f'sf apex run --file "{SCRIPTS / "seed_resolve_by_names.apex"}" --target-org "{org}"')
    print(out[-1800:] if len(out) > 1800 else out)
    resolved = parse_seed(out)
    seed.update({k: v for k, v in resolved.items() if v})
    (OUT / "e2e_seed_ids.json").write_text(json.dumps(seed, indent=2), encoding="utf-8")
    print("Seed Ids:", json.dumps(seed, indent=2))
    if not seed.get("AccountId"):
        print("FATAL: no AccountId after bootstrap/resolve")
        return 1

    print("=== 6) Full strict matrix ===")
    report = {
        "org": org,
        "agentDeveloperName": agent_dev,
        "seed": seed,
        "bootstrapSummary": {
            "steps": len(bootstrap),
            "pass": sum(1 for b in bootstrap if b.get("ok")),
            "fail": sum(1 for b in bootstrap if not b.get("ok")),
        },
        "strictPassRule": "Apex business success only (not mere HTTP Success)",
        "runMode": "final_clean_skill_sequenced",
        "counts": {},
        "results": [],
    }
    tallies: dict[str, int] = {}

    for i, s in enumerate(skills or [], 1):
        name = (s.get("name") or "").strip()
        pid = s.get("promptId")
        live = parse_prompt_command(s.get("promptCommand"))
        payload = build_payload(name, live, seed)
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
        cat, snip = apex_business_success(resp, http)
        tallies[cat] = tallies.get(cat, 0) + 1
        apex_data = None
        if resp and isinstance(resp.get("data"), str):
            try:
                apex_data = json.loads(resp["data"])
            except json.JSONDecodeError:
                apex_data = resp.get("data")
        elif resp:
            apex_data = resp.get("data")
        report["results"].append(
            {
                "skill": name,
                "promptId": pid,
                "request": payload,
                "category": cat,
                "http": http,
                "apiStatus": (resp or {}).get("status"),
                "elapsedSec": elapsed,
                "errorSnippet": snip,
                "apexData": apex_data
                if not isinstance(apex_data, str) or len(apex_data) < 2500
                else apex_data[:2500],
            }
        )
        print(cat, f"({elapsed}s)")
        time.sleep(0.12)

    report["counts"] = tallies
    (OUT / "matrix_report_seeded.json").write_text(json.dumps(report, indent=2), encoding="utf-8")

    detail_rows = []
    for r in report["results"]:
        ad = r.get("apexData")
        if isinstance(ad, dict):
            resp_txt = ad.get("message") or ad.get("error") or json.dumps(ad, ensure_ascii=False, indent=2)
        else:
            resp_txt = str(ad or r.get("errorSnippet") or "")
        detail_rows.append(
            {
                "category": r.get("category") or "unknown",
                "skill": r.get("skill") or "",
                "request": json.dumps(r.get("request") or {}, indent=2, ensure_ascii=False),
                "response": resp_txt if isinstance(resp_txt, str) else json.dumps(resp_txt, ensure_ascii=False),
                "errorSnippet": r.get("errorSnippet"),
            }
        )

    print("=== 7) MAIN + archive report ===")
    need = (
        "FINAL CLEAN retest — wipe prior E2E data; skill-sequenced create→fetch bootstrap; "
        "only required fixtures; natural-key payloads; strict Apex business pass. "
        f"Bootstrap {report['bootstrapSummary']['pass']}/{report['bootstrapSummary']['steps']} pass. "
        f"Counts: {json.dumps(tallies)}"
    )
    main_p, arch_p = publish_main_and_archive(
        detail_rows,
        need=need,
        org=org,
        agent=str(agent_dev),
        slug="final-clean-skill-matrix",
    )
    print("MAIN:", main_p)
    print("ARCHIVE:", arch_p)
    print("COUNTS", tallies)
    return 0 if tallies.get("pass", 0) > 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
