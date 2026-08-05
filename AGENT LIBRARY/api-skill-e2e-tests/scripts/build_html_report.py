# -*- coding: utf-8 -*-
"""Generate self-contained HTML E2E report with next steps + org deps + effort."""
from __future__ import annotations

import html
import json
import re
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

root = Path(__file__).resolve().parent / "results"
out_dir = root.parents[1]  # api-skill-e2e-tests

d = json.loads((root / "matrix_report.json").read_text(encoding="utf-8"))
seed = json.loads((root / "seed_log.json").read_text(encoding="utf-8"))
dep = json.loads((root / "deploy_summary.json").read_text(encoding="utf-8"))
inv = json.loads((root / "org_inventory.json").read_text(encoding="utf-8"))

results = d["results"]
ok = sorted([e for e in results if e["category"] == "handler_ok"], key=lambda x: x["skill"])
api = [e for e in results if e["category"] == "api_fail"]
herr = [e for e in results if e["category"] == "handler_error"]
seed_fail = [x["skill"] for x in seed if not x.get("ok")]
seed_ok = sum(1 for x in seed if x.get("ok"))

prompt_names = {p.get("Name") for p in inv.get("prompts") or []}
linked = set()
for a in inv.get("agents") or []:
    for s in a.get("skills") or []:
        linked.add(s.get("name"))
unlinked = sorted(prompt_names - linked)


def clean_err(e: dict) -> str:
    err = e.get("errorSnippet") or ""
    err = re.sub(r"<[^>]+>", " ", err)
    err = re.sub(r"\s+", " ", err).strip()
    return err[:180]


def bucket(e: dict) -> str:
    m = (e.get("errorSnippet") or "").lower()
    if "agentic function class not found" in m:
        return "A. Missing Apex class"
    if "unsupported skill" in m:
        return "B. Unsupported skill routing"
    if "not available" in m or "not installed" in m or "cpq is not" in m:
        return "C. Cloud / feature not in org"
    if "missing required" in m or "missing parameter" in m or "is required" in m:
        return "D. Param / fixture / schema"
    if "no " in m and ("found" in m or "matching" in m):
        return "E. No matching data"
    if "invalid" in m:
        return "F. Invalid Id / input"
    if "could not" in m:
        return "G. Handler business error"
    return "H. Other"


byb = defaultdict(list)
for e in api + herr:
    byb[bucket(e)].append(e)

# Org capability matrix
ORG_CAPS = [
    {
        "name": "Core Sales Cloud CRM",
        "status": "present",
        "needed_for": "Account, Contact, Lead, Opportunity (logic), Campaign, Activity",
        "skills_n": "majority of library",
        "notes": "Master Dev has data. Opportunity/Activity Apex still blocked by compile issues.",
    },
    {
        "name": "Service Cloud",
        "status": "partial",
        "needed_for": "Case, CaseComment, Case Team, Knowledge link, Entitlements, Milestones",
        "skills_n": "~12–15",
        "notes": "Cases exist. Entitlements/Milestones/CaseArticle may need entitlements & Knowledge enabled.",
    },
    {
        "name": "Knowledge",
        "status": "partial",
        "needed_for": "search_knowledge_articles, fetch_knowledge_article, link_knowledge_article_to_case",
        "skills_n": "3",
        "notes": "fetch_knowledge_article returned OK; full coverage needs Lightning Knowledge + articles.",
    },
    {
        "name": "Quotes (Sales Cloud Quotes)",
        "status": "missing",
        "needed_for": "create_quote, fetch_quote_details, add/update quote line, fuzzy_search_quotes",
        "skills_n": "6",
        "notes": "Compile blocker: Quote / QuoteLineItem types absent. Enable Quotes + Price Books.",
    },
    {
        "name": "Team Selling (Opportunity Teams)",
        "status": "missing",
        "needed_for": "fetch/add opportunity team member skills",
        "skills_n": "2+",
        "notes": "OpportunityTeamMember invalid at compile-time in Master Dev.",
    },
    {
        "name": "Salesforce CPQ (SBQQ)",
        "status": "missing",
        "needed_for": "create/calculate/fetch/update CPQ quote & lines",
        "skills_n": "6",
        "notes": "Runtime degrade: SBQQ__Quote__c not accessible.",
    },
    {
        "name": "Field Service (FSL)",
        "status": "partial",
        "needed_for": "WorkOrder, ServiceAppointment, ServiceResource availability",
        "skills_n": "6–7",
        "notes": "WorkOrder may exist without full FSL; ServiceAppointment/Resource missing/not updateable.",
    },
    {
        "name": "Orders",
        "status": "partial",
        "needed_for": "create_order, fetch/update order & items",
        "skills_n": "4–5",
        "notes": "Order object available; sample data limited; Status picklist issues in smoke create.",
    },
    {
        "name": "Contracts / Subscriptions",
        "status": "partial",
        "needed_for": "Contract skills; Subscription (Revenue Cloud / billing)",
        "skills_n": "Contract 3–4; Sub 2",
        "notes": "Contract object present (no Name field). Subscription object not available.",
    },
    {
        "name": "Financial Services Cloud (FSC)",
        "status": "missing",
        "needed_for": "fetch_financial_account, update_financial_account_fields",
        "skills_n": "2",
        "notes": "Requires FinServ package (FinServ__FinancialAccount__c). Not on Master Dev.",
    },
    {
        "name": "Health Cloud (Care Plan)",
        "status": "missing",
        "needed_for": "fetch_care_plan, update_care_plan_fields, create_care_task (partial)",
        "skills_n": "2–3",
        "notes": "Care Plan object unavailable. create_care_task may use Task/Work-style objects and OK'd once.",
    },
    {
        "name": "Sales / Industry Account Plan",
        "status": "missing",
        "needed_for": "fetch_account_plan",
        "skills_n": "1",
        "notes": "AccountPlan (or industry cloud variant) not available. Not HEDA/EduCloud.",
    },
    {
        "name": "Partners (PRM / Partner Account)",
        "status": "blocked",
        "needed_for": "partner fetch/search + opportunity partners",
        "skills_n": "4",
        "notes": "PartnerAgenticSkillsHandler failed compile (bind type). Needs Partner features + code fix.",
    },
    {
        "name": "HEDA / Education Cloud",
        "status": "not_required",
        "needed_for": "— none in current 111-skill library —",
        "skills_n": "0",
        "notes": "No skills map to HEDA/EDA objects (Contact Language, Program Enrollment, Course Offing, etc.). "
        "Do not install HEDA for this matrix unless you add Education-specific skills later.",
    },
    {
        "name": "Assets",
        "status": "code_gap",
        "needed_for": "fetch/update/fuzzy asset skills",
        "skills_n": "3",
        "notes": "Runtime: Unsupported skill — routing gap, not an install gap (Asset is standard).",
    },
]

NEXT_STEPS = [
    {
        "phase": "1",
        "title": "Fix Apex compile blockers",
        "effort": "1–2 days",
        "owner": "Dev",
        "items": [
            "Activity: fix PicklistEntry.isClosed() (~L124) → redeploy Activity + Generic",
            "Opportunity: guard OpportunityTeamMember with describe / dynamic query when team selling off",
            "Quote: soft-dependency on Quote types OR enable Quotes then deploy",
            "Partner: fix Invalid bind APEX_OBJECT vs Id (~L133)",
        ],
        "outcome": "Full handler set deploys; unlocks ~22 api_fail skills",
    },
    {
        "phase": "2",
        "title": "Fix skill routing (assets + WorkOrder fields)",
        "effort": "0.5–1 day",
        "owner": "Dev",
        "items": [
            "Wire fetch_asset_details / fuzzy_search_assets / update_asset_fields into handler switch",
            "fetch_work_order_details: only select ServiceTerritoryId when field exists (describe-safe)",
        ],
        "outcome": "+3 asset skills + hardier FSL WO fetch",
    },
    {
        "phase": "3",
        "title": "Seed / agent config on Master Dev",
        "effort": "0.5 day",
        "owner": "Dev / Admin",
        "items": [
            "Update legacy 8 Prompt Commands without changing Data Extraction Mapping",
            "Link fetch_account_details to agent",
            "Optional: delete or archive E2E smoke records (E2E Smoke Account DO NOT USE)",
        ],
        "outcome": "Schemas aligned with library; 111 linked",
    },
    {
        "phase": "4",
        "title": "Harness fixtures + re-run matrix",
        "effort": "1 day",
        "owner": "QA / Dev",
        "items": [
            "Generate payloads from live promptCommand (nested fields.LastName, searchTerm, Case Id keys)",
            "Load real Account/Contact/Case/Lead/Campaign/Product Ids from org",
            "Tag outcomes: PASS / EXPECTED_EMPTY / N/A_FEATURE / DEFECT",
            "Prefer read-only first; write skills on disposable sandbox",
        ],
        "outcome": "Clean signal — removes ~25–40 fixture false fails",
    },
    {
        "phase": "5",
        "title": "Org enablement (feature matrix)",
        "effort": "1–3 days (admin / licenses)",
        "owner": "Admin + Product",
        "items": [
            "Sales Quotes + Team Selling if product wants those skills live",
            "Install only clouds you sell: CPQ · FSL · FSC · Health Cloud · Revenue Subscriptions",
            "Do not install HEDA unless Education skills are added",
            "Knowledge + Entitlements if Service skills are in scope",
        ],
        "outcome": "Feature-gated skills move from N/A → testable",
    },
    {
        "phase": "6",
        "title": "Remaining handler defects",
        "effort": "2–4 days",
        "owner": "Dev",
        "items": [
            "Triage post-rerun DEFECT bucket only",
            "Param aliasing (case_id vs CaseId) wherever handlers lag schema",
            "Order Status picklist, queue assignment Ids",
            "Regression: re-run full matrix on sandbox",
        ],
        "outcome": "Core CRM skill set production-ready on capable orgs",
    },
]

TOTAL_LOW = "5"
TOTAL_HIGH = "11.5"

gen = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
agent_dev = html.escape(d.get("agentDeveloperName") or "")

rows_ok = "\n".join(f"<li><code>{html.escape(e['skill'])}</code></li>" for e in ok)

bucket_html = []
for k in sorted(byb.keys()):
    items = sorted(byb[k], key=lambda x: x["skill"])
    trs = []
    for e in items:
        trs.append(
            "<tr><td><code>{}</code></td><td>{}</td><td>{}</td></tr>".format(
                html.escape(e["skill"]),
                html.escape(e["category"]),
                html.escape(clean_err(e)),
            )
        )
    bucket_html.append(
        f'<details open class="bucket"><summary><strong>{html.escape(k)}</strong> '
        f'<span class="badge">{len(items)}</span></summary>'
        f'<table><thead><tr><th>Skill</th><th>Category</th><th>Error</th></tr></thead>'
        f'<tbody>{"".join(trs)}</tbody></table></details>'
    )

cap_rows = []
status_class = {
    "present": "ok",
    "partial": "warn",
    "missing": "bad",
    "blocked": "bad",
    "code_gap": "warn",
    "not_required": "mute",
}
for c in ORG_CAPS:
    sc = status_class.get(c["status"], "mute")
    cap_rows.append(
        "<tr>"
        f"<td><strong>{html.escape(c['name'])}</strong></td>"
        f"<td><span class='pill {sc}'>{html.escape(c['status'])}</span></td>"
        f"<td>{html.escape(c['needed_for'])}</td>"
        f"<td>{html.escape(c['skills_n'])}</td>"
        f"<td>{html.escape(c['notes'])}</td>"
        "</tr>"
    )

step_html = []
for s in NEXT_STEPS:
    lis = "".join(f"<li>{html.escape(i)}</li>" for i in s["items"])
    step_html.append(
        f"""
        <article class="step">
          <header>
            <span class="phase">Phase {s['phase']}</span>
            <h3>{html.escape(s['title'])}</h3>
            <div class="meta">
              <span>Effort: <strong>{html.escape(s['effort'])}</strong></span>
              <span>Owner: {html.escape(s['owner'])}</span>
            </div>
          </header>
          <ul>{lis}</ul>
          <p class="outcome"><strong>Outcome:</strong> {html.escape(s['outcome'])}</p>
        </article>
        """
    )

compile_lis = "".join(
    f"<li><code>{html.escape(r['class'])}</code> — {html.escape(r['problem'])}</li>"
    for r in dep["fullDeploy"]["rootHandlerCompileErrors"]
)
seed_fail_lis = "".join(f"<li><code>{html.escape(s)}</code></li>" for s in seed_fail)
deployed = "".join(
    f"<li><code>{html.escape(h)}</code></li>" for h in dep["partialDeploy"]["deployedHandlers"]
)
excluded = "".join(
    f"<li><code>{html.escape(h)}</code></li>" for h in dep["partialDeploy"]["excludedHandlers"]
)

doc = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>GPTfy Skills E2E Report — Master Dev</title>
<style>
  :root {{
    --bg: #0f1419;
    --panel: #1a2332;
    --panel2: #243044;
    --text: #e7eef8;
    --muted: #9db0c9;
    --ok: #3dd68c;
    --warn: #f0b429;
    --bad: #f07178;
    --accent: #5eb1ff;
    --border: #2e3f56;
    --font: "Segoe UI", system-ui, -apple-system, sans-serif;
  }}
  * {{ box-sizing: border-box; }}
  body {{
    margin: 0; font-family: var(--font); background:
      radial-gradient(1200px 600px at 10% -10%, #1a3a5c 0%, transparent 55%),
      radial-gradient(900px 500px at 100% 0%, #1e2d22 0%, transparent 50%),
      var(--bg);
    color: var(--text); line-height: 1.5;
  }}
  .wrap {{ max-width: 1100px; margin: 0 auto; padding: 2rem 1.25rem 4rem; }}
  header.hero {{
    border: 1px solid var(--border); background: linear-gradient(145deg, var(--panel), #15202e);
    border-radius: 16px; padding: 1.75rem 1.75rem 1.5rem; margin-bottom: 1.5rem;
  }}
  header.hero h1 {{ margin: 0 0 .35rem; font-size: 1.65rem; letter-spacing: -0.02em; }}
  header.hero p {{ margin: .25rem 0; color: var(--muted); }}
  .chips {{ display: flex; flex-wrap: wrap; gap: .5rem; margin-top: 1rem; }}
  .chip {{
    background: var(--panel2); border: 1px solid var(--border); border-radius: 999px;
    padding: .35rem .75rem; font-size: .85rem;
  }}
  .chip strong {{ color: var(--accent); }}
  h2 {{
    margin: 2rem 0 .75rem; font-size: 1.2rem; border-bottom: 1px solid var(--border);
    padding-bottom: .4rem;
  }}
  h3 {{ margin: 0 0 .35rem; font-size: 1.05rem; }}
  .grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(140px, 1fr)); gap: .75rem; }}
  .stat {{
    background: var(--panel); border: 1px solid var(--border); border-radius: 12px;
    padding: .9rem 1rem;
  }}
  .stat .n {{ font-size: 1.6rem; font-weight: 700; line-height: 1.1; }}
  .stat .l {{ color: var(--muted); font-size: .8rem; margin-top: .25rem; }}
  .stat.ok .n {{ color: var(--ok); }}
  .stat.warn .n {{ color: var(--warn); }}
  .stat.bad .n {{ color: var(--bad); }}
  section.card {{
    background: var(--panel); border: 1px solid var(--border); border-radius: 12px;
    padding: 1.1rem 1.25rem; margin-bottom: 1rem;
  }}
  table {{ width: 100%; border-collapse: collapse; font-size: .88rem; }}
  th, td {{ text-align: left; padding: .55rem .5rem; border-bottom: 1px solid var(--border); vertical-align: top; }}
  th {{ color: var(--muted); font-weight: 600; font-size: .78rem; text-transform: uppercase; letter-spacing: .04em; }}
  code {{ font-family: ui-monospace, Consolas, monospace; font-size: .84em; color: #b8e0ff; }}
  ul {{ margin: .4rem 0 .4rem 1.1rem; padding: 0; }}
  li {{ margin: .25rem 0; }}
  .pill {{
    display: inline-block; padding: .15rem .5rem; border-radius: 999px; font-size: .75rem;
    font-weight: 600; text-transform: uppercase; letter-spacing: .03em;
  }}
  .pill.ok {{ background: #14352a; color: var(--ok); }}
  .pill.warn {{ background: #3a2e0e; color: var(--warn); }}
  .pill.bad {{ background: #3a1518; color: var(--bad); }}
  .pill.mute {{ background: #2a3340; color: var(--muted); }}
  .badge {{
    background: var(--panel2); border: 1px solid var(--border); border-radius: 8px;
    padding: .1rem .45rem; font-size: .8rem; color: var(--muted); margin-left: .35rem;
  }}
  details.bucket {{ margin: .6rem 0; }}
  details.bucket summary {{ cursor: pointer; padding: .4rem 0; }}
  .step {{
    border-left: 3px solid var(--accent); background: var(--panel); border-radius: 0 12px 12px 0;
    padding: 1rem 1.15rem; margin-bottom: .85rem; border: 1px solid var(--border); border-left-width: 3px;
  }}
  .step .phase {{
    color: var(--accent); font-size: .75rem; font-weight: 700; text-transform: uppercase;
    letter-spacing: .06em;
  }}
  .step .meta {{ display: flex; flex-wrap: wrap; gap: 1rem; color: var(--muted); font-size: .88rem; margin: .35rem 0 .5rem; }}
  .step .outcome {{ color: var(--muted); margin: .5rem 0 0; font-size: .9rem; }}
  .effort-box {{
    background: linear-gradient(120deg, #1a2f4a, #1a3328); border: 1px solid var(--border);
    border-radius: 12px; padding: 1.15rem 1.35rem; margin: 1rem 0 1.5rem;
  }}
  .effort-box strong {{ color: var(--ok); font-size: 1.25rem; }}
  .note {{ color: var(--muted); font-size: .9rem; }}
  a {{ color: var(--accent); }}
  footer {{ margin-top: 2rem; color: var(--muted); font-size: .85rem; }}
  .two {{ display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }}
  @media (max-width: 800px) {{ .two {{ grid-template-columns: 1fr; }} }}
</style>
</head>
<body>
<div class="wrap">
  <header class="hero">
    <h1>GPTfy Agentic Skills — E2E Report</h1>
    <p>Pre-fix baseline on <strong>Master Dev</strong> · Generated {html.escape(gen)}</p>
    <p>Agent: <strong>GPTfy Master Agent</strong> · API DevName: <code>{agent_dev}</code></p>
    <p class="note">Deploy + seed 111 skills + invokeAgentSkill × 110. No product Apex fixes applied in this run.</p>
    <div class="chips">
      <span class="chip">Org: <strong>masterdev@gptfy.ai</strong></span>
      <span class="chip">Prompts: <strong>{len(inv.get('prompts') or [])}</strong></span>
      <span class="chip">Linked: <strong>{len(linked)}</strong></span>
      <span class="chip">Unlinked: <strong>{html.escape(', '.join(unlinked) or 'none')}</strong></span>
    </div>
  </header>

  <h2>Executive summary</h2>
  <div class="grid">
    <div class="stat ok"><div class="n">{len(ok)}</div><div class="l">Handler OK</div></div>
    <div class="stat warn"><div class="n">{len(herr)}</div><div class="l">Handler error</div></div>
    <div class="stat bad"><div class="n">{len(api)}</div><div class="l">API fail (class missing)</div></div>
    <div class="stat"><div class="n">{seed_ok}/{len(seed)}</div><div class="l">Seeds OK</div></div>
    <div class="stat bad"><div class="n">Full deploy</div><div class="l">FAILED (partial used)</div></div>
    <div class="stat ok"><div class="n">{TOTAL_LOW}–{TOTAL_HIGH}d</div><div class="l">Est. effort to green path</div></div>
  </div>

  <div class="effort-box">
    <div><strong>Recommended total effort:</strong> about <strong>{TOTAL_LOW}–{TOTAL_HIGH} person-days</strong>
      (1 developer + part-time admin for cloud installs).</div>
    <p class="note" style="margin:.5rem 0 0">
      Core CRM path (~half the library) can be “green enough” after Phases 1–4 (~3–4.5 days)
      without installing FSC / Health / CPQ / FSL. Cloud install time is license- and package-driven,
      not coding effort.
    </p>
  </div>

  <h2>Org capabilities you need</h2>
  <section class="card">
    <p class="note">
      Master Dev is a <strong>core CRM</strong> sandbox. Industry skills correctly returned “not available”
      when packages are missing. Install only what product scope requires.
    </p>
    <table>
      <thead>
        <tr>
          <th>Capability</th>
          <th>Master Dev</th>
          <th>Needed for</th>
          <th>Skills</th>
          <th>Notes</th>
        </tr>
      </thead>
      <tbody>
        {"".join(cap_rows)}
      </tbody>
    </table>
  </section>

  <section class="card">
    <h3>FSC vs HEDA vs others (plain English)</h3>
    <ul>
      <li><strong>FSC (Financial Services Cloud)</strong> — required for Financial Account skills
        (<code>fetch_financial_account</code>, <code>update_financial_account_fields</code>. Not on Master Dev.</li>
      <li><strong>HEDA / Education Cloud</strong> — <strong>not required</strong> for the current 111-skill library.
        No HEDA objects are referenced. Skip unless you plan Education-specific skills later.</li>
      <li><strong>Health Cloud</strong> — Care Plan objects for care plan skills (not FSC, not HEDA).</li>
      <li><strong>CPQ (SBQQ)</strong> — Advanced quoting skills (separate from standard Sales Quotes).</li>
      <li><strong>Field Service (FSL)</strong> — Service Appointment / Service Resource / full WO scheduling.</li>
      <li><strong>Sales Quotes + Team Selling</strong> — standard Quote types &amp; OpportunityTeamMember (compile today).</li>
    </ul>
  </section>

  <h2>Next steps &amp; effort</h2>
  {"".join(step_html)}

  <section class="card">
    <h3>Suggested sequencing</h3>
    <ol>
      <li>Do <strong>Phases 1–3</strong> on Master Dev immediately (code + seed). Unblocks deploy &amp; 22 class-not-found skills.</li>
      <li>Do <strong>Phase 4</strong> retest with better fixtures → honest residual defect list.</li>
      <li>Decide product scope for clouds → <strong>Phase 5</strong> install only needed packages on a <em>feature sandbox</em>.</li>
      <li><strong>Phase 6</strong> only after fixtures stop drowning real bugs.</li>
    </ol>
  </section>

  <h2>Deploy detail</h2>
  <div class="two">
    <section class="card">
      <h3>Full deploy (failed)</h3>
      <p class="note">Id <code>0AfQH00000P9St80AF</code> · 68 component failures · rolled back</p>
      <ul>{compile_lis}</ul>
    </section>
    <section class="card">
      <h3>Partial deploy (used for tests)</h3>
      <p><strong>Excluded</strong></p>
      <ul>{excluded}</ul>
      <p><strong>Deployed handlers</strong></p>
      <ul>{deployed}</ul>
    </section>
  </div>

  <h2>Seed detail</h2>
  <section class="card">
    <p><strong>{seed_ok}</strong> of <strong>{len(seed)}</strong> package seeds succeeded.
    Eight legacy prompts failed because Data Extraction Mapping cannot be changed after create:</p>
    <ul>{seed_fail_lis}</ul>
    <p class="note">Impact: those skills keep old Prompt Command schemas until refreshed without remapping.</p>
  </section>

  <h2>Invoke matrix — handler OK ({len(ok)})</h2>
  <section class="card">
    <ul style="columns:2; gap:1.5rem">{rows_ok}</ul>
  </section>

  <h2>Invoke matrix — failures by bucket</h2>
  <section class="card">
    {"".join(bucket_html)}
  </section>

  <h2>Pass bar used</h2>
  <section class="card">
    <ul>
      <li><strong>handler_ok</strong> — HTTP 200, API Success, Apex success/true</li>
      <li><strong>handler_error</strong> — API Success, Apex error / empty / missing param</li>
      <li><strong>api_fail</strong> — REST non-Success (e.g. Agentic function class not found)</li>
    </ul>
    <p class="note">Bucket D/E contain harness noise; Bucket C is expected N/A without packages; Bucket A is deploy-gated.</p>
  </section>

  <h2>Side effects on Master Dev</h2>
  <section class="card">
    <ul>
      <li>Created account: <code>E2E Smoke Account DO NOT USE</code></li>
      <li>Possible mutations: campaign create, care task, case comment, activity log, account/contact description updates</li>
    </ul>
  </section>

  <h2>Artifacts</h2>
  <section class="card">
    <ul>
      <li><code>api-skill-e2e-tests/E2E_TEST_REPORT.html</code> (this file)</li>
      <li><code>api-skill-e2e-tests/E2E_TEST_REPORT.md</code></li>
      <li><code>api-skill-e2e-tests/scripts/results/matrix_report.json</code></li>
      <li><code>api-skill-e2e-tests/scripts/results/seed_log.json</code></li>
      <li><code>api-skill-e2e-tests/scripts/results/deploy_summary.json</code></li>
    </ul>
  </section>

  <footer>
    GPTfy Agent Skills Library · E2E harness · Report is a snapshot of Master Dev prior to code fixes.
  </footer>
</div>
</body>
</html>
"""

out_path = out_dir / "E2E_TEST_REPORT.html"
out_path.write_text(doc, encoding="utf-8")
# also under results
(root / "E2E_TEST_REPORT.html").write_text(doc, encoding="utf-8")
print("Wrote", out_path)
