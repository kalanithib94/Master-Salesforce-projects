# -*- coding: utf-8 -*-
"""
Consolidate fail_data / fail_business from MAIN (or skills list),
remediate org data, then re-invoke those skills with better payloads.

Does NOT retest fail_missing_feature (package/feature N/A).

Usage:
  python retry_failed_skills.py --from-main --org "Master Dev"
  python retry_failed_skills.py --skills add_case_team_member,transfer_record_owner
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_main_report import parse_seeded_html, publish_main_and_archive  # noqa: E402
from run_seeded_matrix import apex_business_success, build_payload, parse_prompt_command  # noqa: E402
from sf_rest import load_config, rest_json, session  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
LIBRARY = ROOT.parent
REPORTS = LIBRARY / "Reports"
MAIN = REPORTS / "MAIN_REPORT.html"
SEED_JSON = Path(__file__).resolve().parent / "results" / "e2e_seed_ids.json"
REMEDY_APEX = Path(__file__).resolve().parent / "seed_retry_remediation.apex"
OUT = Path(__file__).resolve().parent / "results"


def run_shell(cmd: str) -> tuple[int, str]:
    p = subprocess.run(
        cmd, shell=True, capture_output=True, text=True, encoding="utf-8", errors="replace"
    )
    return p.returncode, (p.stdout or "") + (p.stderr or "")


def parse_seed_debug(out: str) -> dict:
    ids = {}
    for line in out.splitlines():
        if "USER_DEBUG" not in line or "|DEBUG|" not in line:
            continue
        payload = line.split("|DEBUG|", 1)[-1]
        m = re.search(
            r"(OpenCaseId|OpenCaseNumber|OtherUserId|UserId|CaseTeamRoleId|AccountId|CaseId)=(.+)$",
            payload,
        )
        if m:
            val = m.group(2).strip()
            if val.lower() not in ("null", "none", "") and "'" not in val:
                ids[m.group(1)] = val
    return ids


def load_rows_from_main() -> list[dict]:
    if not MAIN.exists():
        return []
    return parse_seeded_html(MAIN)


def pretty_response(resp: dict | None) -> str:
    if not resp:
        return "(no response)"
    out = dict(resp) if isinstance(resp, dict) else {"data": resp}
    data = out.get("data") if isinstance(out, dict) else None
    if isinstance(data, str):
        try:
            parsed = json.loads(data)
            if isinstance(parsed, dict) and isinstance(parsed.get("message"), str):
                msg = parsed["message"]
                plain = re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", msg)).strip()
                parsed = {**parsed, "message": plain}
            out["data"] = parsed
        except json.JSONDecodeError:
            out["data"] = re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", data)).strip()
    return json.dumps(out, ensure_ascii=False, indent=2)


def improved_payload(skill: str, seed: dict, remedy: dict, prior_req: dict | None) -> dict:
    """Better data for known fixable failures."""
    S = {**seed, **remedy}
    open_case = S.get("OpenCaseNumber") or S.get("CaseNumber")
    open_subj = "E2E Skill Test Case Open" if S.get("OpenCaseId") else "E2E Skill Test Case"
    other = S.get("OtherUserId") or S.get("UserId")
    me = S.get("UserId")

    hand = {
        "add_case_team_member": {
            "CaseNumber": open_case or S.get("CaseNumber"),
            "Subject": open_subj,
            "CaseId": S.get("OpenCaseId") or S.get("CaseId"),
            "UserId": other or me,
            "user_id": other or me,
            "team_role_id": S.get("CaseTeamRoleId"),
            "TeamRoleId": S.get("CaseTeamRoleId"),
        },
        "close_case": {
            "CaseNumber": S.get("OpenCaseNumber") or open_case,
            "Subject": open_subj,
            "Status": "Closed",
        },
        "transfer_record_owner": {
            "record_id": S.get("AccountId"),
            "Id": S.get("AccountId"),
            "new_owner_id": other,
            "UserId": other,
            "OwnerId": other,
        },
        "add_quote_line_item": prior_req or {},
        "update_quote_fields": prior_req or {},
        "update_quote_line_item": prior_req or {},
    }
    if skill in hand and hand[skill]:
        return hand[skill]
    # fallback to build_payload defaults if seed available
    try:
        return build_payload(skill, None, S)
    except Exception:
        return prior_req or {}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--org", default=None)
    ap.add_argument("--from-main", action="store_true", help="Pick fail_data + fail_business from MAIN_REPORT")
    ap.add_argument("--skills", default=None, help="Comma list to force retry")
    ap.add_argument("--skip-remedy", action="store_true")
    args = ap.parse_args()

    cfg = load_config()
    org = args.org or cfg.get("targetOrg", "Master Dev")
    agent = cfg.get("agentDeveloperName") or cfg.get("agentName")
    seed = json.loads(SEED_JSON.read_text(encoding="utf-8")) if SEED_JSON.exists() else {}

    target_skills: list[str] = []
    prior_by_skill: dict[str, dict] = {}
    rows_main = load_rows_from_main()
    for r in rows_main:
        prior_by_skill[r["skill"]] = r
        if args.from_main and r["category"] in ("fail_data", "fail_business"):
            target_skills.append(r["skill"])
    if args.skills:
        target_skills = [s.strip() for s in args.skills.split(",") if s.strip()]
    target_skills = sorted(set(target_skills))

    if not target_skills:
        print("No fixable failed skills to retry (fail_data / fail_business).")
        return 0

    print("Retry targets:", ", ".join(target_skills))

    remedy = {}
    if not args.skip_remedy:
        print("=== Org remediation Apex ===")
        rc, out = run_shell(f'sf apex run --file "{REMEDY_APEX}" --target-org "{org}"')
        print(out[-2500:])
        remedy = parse_seed_debug(out)
        # merge into seed file for subsequent fixtures
        seed.update(remedy)
        SEED_JSON.parent.mkdir(parents=True, exist_ok=True)
        SEED_JSON.write_text(json.dumps(seed, indent=2), encoding="utf-8")
        print("Remedy ids:", remedy)

    token, base = session(org)
    inv = OUT / "org_inventory.json"
    if inv.exists():
        data = json.loads(inv.read_text(encoding="utf-8"))
        if data.get("agents"):
            agent = data["agents"][0].get("DeveloperName") or agent

    code, body = rest_json(
        token, base, "POST", "/services/apexrest/ccai/v1/getAgentSkills/", {"agentName": agent}
    )
    api = {}
    if code == 200 and (body or {}).get("status") == "Success":
        for s in body.get("skills") or []:
            api[(s.get("name") or "").strip()] = s

    retry_results = []
    for name in target_skills:
        meta = api.get(name)
        if not meta:
            retry_results.append(
                {
                    "skill": name,
                    "category": "fail_missing_class",
                    "request": {},
                    "response": "Skill not linked",
                }
            )
            print(f"  {name}: not linked")
            continue
        prior = prior_by_skill.get(name, {})
        prior_req = {}
        try:
            prior_req = json.loads(prior.get("request") or "{}")
        except json.JSONDecodeError:
            prior_req = {}
        payload = improved_payload(name, seed, remedy, prior_req)
        live = parse_prompt_command(meta.get("promptCommand"))
        # merge live required if empty
        if not payload and live:
            payload = build_payload(name, live, seed)

        t0 = time.time()
        http, resp = rest_json(
            token,
            base,
            "POST",
            "/services/apexrest/ccai/v1/invokeAgentSkill/",
            {"promptId": meta.get("promptId"), "data": payload},
            timeout=180,
        )
        elapsed = round(time.time() - t0, 2)
        cat, snip = apex_business_success(resp, http)
        full = pretty_response(resp if isinstance(resp, dict) else {"data": resp})
        retry_results.append(
            {
                "skill": name,
                "category": cat,
                "request": json.dumps(payload, indent=2, ensure_ascii=False),
                "response": full,
                "handler": "retry_pass",
            }
        )
        print(f"  {name}: {cat} ({elapsed}s)")
        time.sleep(0.15)

    # Merge: start from MAIN rows, replace retried skills
    merged: dict[str, dict] = {}
    for r in rows_main:
        merged[r["skill"]] = {
            "skill": r["skill"],
            "category": r["category"],
            "request": r["request"] if isinstance(r["request"], str) else json.dumps(r["request"], indent=2),
            "response": r["response"] if isinstance(r["response"], str) else str(r["response"]),
        }
    for r in retry_results:
        merged[r["skill"]] = r

    rows = [merged[k] for k in sorted(merged.keys())]
    need = (
        "Retry fixable failures after org remediation\n"
        "Cleared duplicate CaseTeamMembers; seeded open case; set Account owner for transfer_record_owner\n"
        f"Retried: {', '.join(target_skills)}"
    )
    main_p, arch_p = publish_main_and_archive(
        rows,
        need=need,
        org=org,
        agent=str(agent or ""),
        slug="retry-fixable-failures",
    )
    (OUT / "retry_failed_results.json").write_text(
        json.dumps(
            {
                "targets": target_skills,
                "remedy": remedy,
                "results": retry_results,
                "when": datetime.now(timezone.utc).isoformat(),
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    print("\nMAIN:", main_p)
    print("ARCHIVE:", arch_p)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
