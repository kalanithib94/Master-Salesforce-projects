# -*- coding: utf-8 -*-
"""
Regression: invoke EVERY skill belonging to a handler (or all handlers if base changes).

Always writes a dated HTML report under api-skill-e2e-tests/reports/ with:
  - date/time
  - need for update (--reason)
  - request + response per skill

Usage:
  python regression_handler.py CaseAgenticSkillsHandler --reason "..."
  python regression_handler.py AgenticSkillsBase --all-handlers --reason "..."
  python regression_handler.py CaseAgenticSkillsHandler --skills fetch_case_details,create_case --reason "..."
"""
from __future__ import annotations

import argparse
import html as H
import json
import re
import subprocess
import sys
import time
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_main_report import publish_main_and_archive  # noqa: E402
from run_seeded_matrix import (  # noqa: E402
    apex_business_success,
    build_payload,
    parse_prompt_command,
    parse_seed,
    APEX,
)
from sf_rest import load_config, rest_json, session  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
DELIVERABLES = ROOT.parent / "Deliverables" / "force-app" / "main" / "default" / "classes"
REPORTS = ROOT / "reports"
ARCHIVE = REPORTS / "archive"
OUT = Path(__file__).resolve().parent / "results"
REPORTS.mkdir(parents=True, exist_ok=True)
ARCHIVE.mkdir(parents=True, exist_ok=True)
OUT.mkdir(parents=True, exist_ok=True)

# Prefer library source; fall back to staged package
HANDLER_DIRS = [
    DELIVERABLES,
    ROOT / "package" / "force-app" / "main" / "default" / "classes",
]


def run_shell(cmd: str) -> tuple[int, str]:
    p = subprocess.run(
        cmd, shell=True, capture_output=True, text=True, encoding="utf-8", errors="replace"
    )
    return p.returncode, (p.stdout or "") + (p.stderr or "")


def find_handler_file(class_name: str) -> Path | None:
    for d in HANDLER_DIRS:
        p = d / f"{class_name}.cls"
        if p.exists():
            return p
    return None


def discover_skills_in_handler(class_name: str) -> list[str]:
    path = find_handler_file(class_name)
    if not path:
        return []
    text = path.read_text(encoding="utf-8", errors="replace")
    # when 'skill_name' {
    skills = re.findall(r"when\s+'([a-z0-9_]+)'\s*\{", text, flags=re.I)
    # de-dupe preserve order
    seen = set()
    out = []
    for s in skills:
        if s not in seen and s not in ("else",):
            seen.add(s)
            out.append(s)
    return out


def list_all_handlers() -> list[str]:
    names = []
    for d in HANDLER_DIRS:
        if not d.exists():
            continue
        for p in sorted(d.glob("*AgenticSkillsHandler.cls")):
            if p.stem not in names:
                names.append(p.stem)
        break  # first existing dir wins list
    for d in HANDLER_DIRS:
        if (d / "AgenticSkillsBase.cls").exists() and "AgenticSkillsBase" not in names:
            # base is not a handler; used only as trigger for --all-handlers
            pass
    return [n for n in names if n != "AgenticSkillsBase"]


def slug(s: str) -> str:
    s = re.sub(r"[^a-zA-Z0-9_-]+", "-", s.strip()).strip("-").lower()
    return (s[:48] or "update")


def pretty_response(resp: dict | None) -> str:
    """Full request-path response: unwrap Apex data JSON, keep full body readable."""
    if not resp:
        return "(no response)"
    if not isinstance(resp, dict):
        return str(resp)
    out = dict(resp)
    data = out.get("data")
    if isinstance(data, str):
        try:
            parsed = json.loads(data)
            # Prefer clean HTML-free message + preserve structure
            if isinstance(parsed, dict) and isinstance(parsed.get("message"), str):
                msg = parsed["message"]
                plain = re.sub(r"<[^>]+>", " ", msg)
                plain = re.sub(r"\s+", " ", plain).strip()
                parsed = {**parsed, "message": plain, "messageHtml": msg if plain != msg else None}
                if parsed.get("messageHtml") is None:
                    parsed.pop("messageHtml", None)
            out["data"] = parsed
        except json.JSONDecodeError:
            plain = re.sub(r"<[^>]+>", " ", data)
            out["data"] = re.sub(r"\s+", " ", plain).strip()
    return json.dumps(out, ensure_ascii=False, indent=2)


def write_html(report: dict, path: Path) -> None:
    """Detailed transcript report — request + full response primary; no scoreboard spam."""
    results = sorted(report.get("results") or [], key=lambda r: r.get("skill") or "")

    def pill_cls(c: str) -> str:
        return {
            "pass": "ok",
            "fail_business": "bad",
            "fail_api": "bad",
            "fail_data": "warn",
            "fail_missing_feature": "mute",
            "fail_missing_class": "mute",
        }.get(c, "mute")

    cards = []
    for r in results:
        c = r.get("category") or "unknown"
        req = H.escape(json.dumps(r.get("request") or {}, indent=2, ensure_ascii=False))
        resp = H.escape(r.get("responseFull") or r.get("responseText") or r.get("errorSnippet") or "")
        cards.append(
            f'<article class="card {pill_cls(c)}" id="{H.escape(r.get("skill") or "")}">'
            f'<header><h2><code>{H.escape(r.get("skill") or "")}</code></h2>'
            f'<span class="pill {pill_cls(c)}">{H.escape(c)}</span></header>'
            f'<p class="meta">handler <code>{H.escape(r.get("handler") or "")}</code></p>'
            f'<div class="pair">'
            f'<div class="col"><h3>Request</h3><pre>{req}</pre></div>'
            f'<div class="col"><h3>Response</h3><pre>{resp}</pre></div>'
            f"</div></article>"
        )

    need = report.get("needForUpdate") or ""
    need_html = "".join(
        f"<li>{H.escape(line.strip('- ').strip())}</li>"
        for line in need.splitlines()
        if line.strip()
    )
    if not need_html:
        need_html = f"<li>{H.escape(need or '—')}</li>"

    changed = report.get("whatChanged") or []
    changed_html = "".join(f"<li><code>{H.escape(x)}</code></li>" for x in changed) or "<li>—</li>"

    # TOC of skill names only (links to detail cards — still not number dump)
    toc = "".join(
        f'<li><a href="#{H.escape(r.get("skill") or "")}">'
        f'{H.escape(r.get("skill") or "")}</a> '
        f'<span class="pill {pill_cls(r.get("category") or "")}">'
        f'{H.escape(r.get("category") or "")}</span></li>'
        for r in results
    )

    doc = f"""<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>{H.escape(report.get("title") or "Skill detail report")}</title>
<style>
body{{font-family:Segoe UI,system-ui,sans-serif;background:#0f1419;color:#e7eef8;margin:0;padding:1.25rem 1.5rem 3rem;line-height:1.45}}
.wrap{{max-width:1200px;margin:0 auto}}
.hero{{background:linear-gradient(145deg,#1a2332,#15202e);border:1px solid #2e3f56;border-radius:14px;padding:1.2rem 1.35rem;margin-bottom:1rem}}
h1{{margin:0 0 .4rem;font-size:1.4rem;font-weight:650}}
.muted{{color:#9db0c9;font-size:.92rem}}
section.intro,article.card{{background:#1a2332;border:1px solid #2e3f56;border-radius:12px;padding:1rem 1.15rem;margin:.85rem 0;border-left:4px solid #2e3f56}}
article.card.ok{{border-left-color:#3dd68c}} article.card.warn{{border-left-color:#f0b429}}
article.card.bad{{border-left-color:#f07178}} article.card.mute{{border-left-color:#6b7c93}}
.pair{{display:grid;grid-template-columns:1fr 1fr;gap:.75rem}}
@media(max-width:900px){{.pair{{grid-template-columns:1fr}}}}
.col h3{{margin:.1rem 0 .4rem;font-size:.95rem;color:#c5d4e8;font-weight:600}}
pre{{background:#0d1218;padding:.75rem .85rem;border-radius:8px;white-space:pre-wrap;word-break:break-word;
  font-size:.8rem;line-height:1.4;max-height:none;overflow:auto;border:1px solid #243044;margin:0}}
.pill{{font-size:.72rem;font-weight:700;padding:.12rem .5rem;border-radius:999px;vertical-align:middle}}
.pill.ok{{background:#14352a;color:#3dd68c}}.pill.warn{{background:#3a2e0e;color:#f0b429}}
.pill.bad{{background:#3a1518;color:#f07178}}.pill.mute{{background:#2a3340;color:#9db0c9}}
code{{color:#b8e0ff}} header{{display:flex;flex-wrap:wrap;align-items:center;gap:.5rem;margin-bottom:.15rem}}
header h2{{font-size:1.1rem;margin:0;font-weight:650}} .meta{{color:#9db0c9;font-size:.84rem;margin:.15rem 0 .65rem}}
ul{{margin:.35rem 0 .2rem 1.15rem;padding:0}} li{{margin:.28rem 0}}
.toc a{{color:#5eb1ff;text-decoration:none}} .toc a:hover{{text-decoration:underline}}
.toc{{columns:2}} @media(max-width:700px){{.toc{{columns:1}}}}
.toc li{{break-inside:avoid}}
</style></head><body><div class="wrap">
<header class="hero">
  <h1>{H.escape(report.get("title") or "Skill request / response detail")}</h1>
  <p class="muted">{H.escape(report.get("localTime") or "")} · {H.escape(report.get("utcTime") or "")}</p>
  <p class="muted">Org <b>{H.escape(report.get("org") or "")}</b> · Agent <code>{H.escape(report.get("agent") or "")}</code></p>
  <p class="muted">Handler / target: <code>{H.escape(report.get("targetLabel") or "")}</code></p>
</header>

<section class="intro">
  <h2 style="margin:0 0 .5rem;font-size:1rem">Why we updated this</h2>
  <ul>{need_html}</ul>
  <h2 style="margin:1rem 0 .5rem;font-size:1rem">What changed</h2>
  <ul>{changed_html}</ul>
  <h2 style="margin:1rem 0 .5rem;font-size:1rem">Skills in this report</h2>
  <ul class="toc">{toc or "<li>—</li>"}</ul>
</section>

{"".join(cards)}

<footer class="muted" style="margin-top:1.5rem;font-size:.84rem">
  Each card is the full invoke request payload and the full API/Apex response for that skill.
</footer>
</div></body></html>
"""
    path.write_text(doc, encoding="utf-8")


def main() -> int:
    ap = argparse.ArgumentParser(description="Regression-test all skills on a handler + HTML report")
    ap.add_argument("target", help="Handler class name, e.g. CaseAgenticSkillsHandler (or AgenticSkillsBase)")
    ap.add_argument(
        "--reason",
        required=True,
        help="Why this update is needed (shows in HTML as Need for update). Use | for multiple bullets.",
    )
    ap.add_argument("--org", default=None)
    ap.add_argument("--all-handlers", action="store_true", help="With AgenticSkillsBase / global: every *AgenticSkillsHandler")
    ap.add_argument("--skills", default=None, help="Optional comma list to restrict (still report which were skipped)")
    ap.add_argument("--changed", default="", help="Comma-separated files changed (listed in report)")
    ap.add_argument("--skip-seed", action="store_true", help="Reuse last e2e_seed_ids.json")
    ap.add_argument("--deploy", action="store_true", help="Deploy staged package force-app first")
    args = ap.parse_args()

    cfg = load_config()
    org = args.org or cfg.get("targetOrg", "Master Dev")
    agent = cfg.get("agentDeveloperName") or cfg.get("agentName")

    # scope handlers
    target = args.target.strip()
    if target == "AgenticSkillsBase" or args.all_handlers:
        handlers = list_all_handlers()
        target_label = f"{target} → all handlers ({len(handlers)})"
    else:
        handlers = [target]
        target_label = target

    planned: list[tuple[str, str]] = []  # (handler, skill)
    for h in handlers:
        skills = discover_skills_in_handler(h)
        if not skills:
            print(f"WARN: no when 'skill' found for {h}")
        for sk in skills:
            planned.append((h, sk))

    if args.skills:
        allow = {x.strip() for x in args.skills.split(",") if x.strip()}
        planned = [(h, s) for h, s in planned if s in allow]

    skill_names = sorted({s for _, s in planned})
    if not skill_names:
        print("No skills to run")
        return 2

    if args.deploy:
        pkg = ROOT / "package" / "force-app"
        print("Deploying", pkg)
        rc, out = run_shell(
            f'sf project deploy start --source-dir "{pkg}" --target-org "{org}" --wait 20'
        )
        print(out[-1500:])
        if rc != 0 and "Succeeded" not in out:
            print("Deploy may have failed; continuing only if already in org")

    # seed
    seed_path = OUT / "e2e_seed_ids.json"
    if args.skip_seed and seed_path.exists():
        seed = json.loads(seed_path.read_text(encoding="utf-8"))
        print("Reusing seed", seed_path)
    else:
        print("Seeding CRM data…")
        rc, out = run_shell(f'sf apex run --file "{APEX}" --target-org "{org}"')
        seed = parse_seed(out)
        seed_path.write_text(json.dumps(seed, indent=2), encoding="utf-8")
        if not seed.get("AccountId"):
            print("FATAL: seed missing AccountId")
            print(out[-2000:])
            return 1

    token, base = session(org)
    inv = OUT / "org_inventory.json"
    if inv.exists():
        data = json.loads(inv.read_text(encoding="utf-8"))
        if data.get("agents"):
            agent = data["agents"][0].get("DeveloperName") or agent

    code, body = rest_json(
        token, base, "POST", "/services/apexrest/ccai/v1/getAgentSkills/", {"agentName": agent}
    )
    api_skills = {}
    if code == 200 and (body or {}).get("status") == "Success":
        for s in body.get("skills") or []:
            api_skills[(s.get("name") or "").strip()] = s
    print(f"Agent skills available: {len(api_skills)}")

    now_local = datetime.now().astimezone()
    try:
        local_disp = now_local.strftime("%Y-%m-%d %H:%M:%S %Z")
    except Exception:
        local_disp = now_local.isoformat(timespec="seconds")
    utc_disp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    reason_lines = args.reason.replace("|", "\n")

    tallies: dict[str, int] = defaultdict(int)
    results = []

    # order by skill name but keep handler
    for handler, name in sorted(planned, key=lambda x: x[1]):
        meta = api_skills.get(name)
        if not meta:
            tallies["fail_missing_class"] += 1
            results.append(
                {
                    "handler": handler,
                    "skill": name,
                    "category": "fail_missing_class",
                    "http": None,
                    "apiStatus": "NotLinked",
                    "elapsedSec": 0,
                    "request": {},
                    "responseFull": json.dumps(
                        {"error": "Skill not linked to agent / not returned by getAgentSkills"},
                        indent=2,
                    ),
                    "responseText": "Skill not linked",
                    "errorSnippet": "not linked",
                }
            )
            print(f"  {name}: not linked")
            continue

        live = parse_prompt_command(meta.get("promptCommand"))
        payload = build_payload(name, live, seed)
        pid = meta.get("promptId")
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
        tallies[cat] += 1
        full = pretty_response(resp if isinstance(resp, dict) else {"data": resp})
        results.append(
            {
                "handler": handler,
                "skill": name,
                "promptId": pid,
                "request": payload,
                "category": cat,
                "http": http,
                "apiStatus": (resp or {}).get("status") if isinstance(resp, dict) else None,
                "elapsedSec": elapsed,
                "errorSnippet": snip,
                "responseFull": full,
                "responseText": full,
                "raw": resp,
            }
        )
        print(f"  [{handler}] {name}: {cat} ({elapsed}s)")
        time.sleep(0.1)

    changed = [x.strip() for x in args.changed.split(",") if x.strip()]
    if not changed:
        changed = [f"{h}.cls" for h in handlers]

    report = {
        "title": f"Handler regression — {target_label}",
        "target": target,
        "targetLabel": target_label,
        "handlers": handlers,
        "skillsPlanned": skill_names,
        "needForUpdate": reason_lines,
        "whatChanged": changed,
        "org": org,
        "agent": agent,
        "localTime": local_disp,
        "utcTime": utc_disp,
        "counts": dict(tallies),
        "results": results,
        "seed": {k: seed.get(k) for k in ("AccountId", "CaseId", "CaseNumber", "ContactId") if seed.get(k)},
    }

    # Detail rows for dual MAIN + dated archive
    detail_rows = []
    for r in results:
        detail_rows.append(
            {
                "category": r.get("category") or "unknown",
                "skill": r.get("skill") or "",
                "request": json.dumps(r.get("request") or {}, indent=2, ensure_ascii=False),
                "response": r.get("responseFull") or r.get("responseText") or "",
            }
        )

    main_p, arch_p = publish_main_and_archive(
        detail_rows,
        need=reason_lines + f"\nScope: {target_label}",
        org=org,
        agent=str(agent or ""),
        slug=f"{slug(target)}_{slug(args.reason.split('|')[0][:40])}",
    )

    slim = {
        **report,
        "results": [{k: v for k, v in r.items() if k != "raw"} for r in results],
        "mainReport": str(main_p),
        "archiveReport": str(arch_p),
    }
    json_path = ARCHIVE / (arch_p.stem + ".json")
    json_path.write_text(json.dumps(slim, indent=2, ensure_ascii=False), encoding="utf-8")

    print("\n=== DONE ===")
    print("MAIN (always latest):", main_p)
    print("ARCHIVE (this update):", arch_p)
    print("JSON:", json_path)
    return 0 if tallies.get("fail_business", 0) + tallies.get("fail_api", 0) == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
