# -*- coding: utf-8 -*-
"""Build FINAL_E2E_REPORT.html from seeded transcript + known metadata."""
from __future__ import annotations

import html
import re
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TRANSCRIPT = ROOT / "SKILL_INVOKE_TRANSCRIPT_SEEDED.html"
OUT = ROOT / "FINAL_E2E_REPORT.html"


def parse_cards(path: Path) -> list[dict]:
    text = path.read_text(encoding="utf-8")
    pattern = re.compile(
        r'data-cat="([^"]+)".*?<code>([^<]+)</code>.*?<span class="pill[^"]*">([^<]+)</span>'
        r".*?Request</h3><pre>(.*?)</pre>.*?Response</h3><pre>(.*?)</pre>",
        re.S,
    )
    rows = []
    for cat, skill, pill, req, resp in pattern.findall(text):
        rows.append(
            {
                "cat": cat,
                "skill": skill,
                "pill": pill,
                "req": _clean(req),
                "resp": _clean(resp),
            }
        )
    return rows


def _clean(s: str) -> str:
    return (
        s.replace("&quot;", '"')
        .replace("&lt;", "<")
        .replace("&gt;", ">")
        .replace("&#39;", "'")
        .replace("&amp;", "&")
        .strip()
    )


def esc(s: str) -> str:
    return html.escape(s or "", quote=True)


def main() -> None:
    rows = parse_cards(TRANSCRIPT)
    by_cat: dict[str, list[dict]] = defaultdict(list)
    for r in rows:
        by_cat[r["cat"]].append(r)

    pass_n = len(by_cat.get("pass", []))
    miss_n = len(by_cat.get("fail_missing_feature", []))
    data_n = len(by_cat.get("fail_data", []))
    biz_n = len(by_cat.get("fail_business", []))
    total = len(rows)
    pct = round(100 * pass_n / total, 1) if total else 0
    gen = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

    def skill_list(cat: str) -> str:
        items = sorted({r["skill"] for r in by_cat.get(cat, [])})
        if not items:
            return "<p class='note'>—</p>"
        return (
            "<div class='tags'>"
            + "".join(f"<code class='tag'>{esc(s)}</code>" for s in items)
            + "</div>"
        )

    def detail_table(cat: str) -> str:
        items = sorted(by_cat.get(cat, []), key=lambda x: x["skill"])
        if not items:
            return ""
        pills = {
            "pass": "ok",
            "fail_missing_feature": "mute",
            "fail_data": "warn",
            "fail_business": "bad",
        }
        pill_cls = pills.get(cat, "mute")
        rows_html = []
        for r in items:
            resp_short = r["resp"][:220] + ("…" if len(r["resp"]) > 220 else "")
            rows_html.append(
                f"<tr>"
                f"<td><code>{esc(r['skill'])}</code></td>"
                f"<td><span class='pill {pill_cls}'>{esc(r['pill'])}</span></td>"
                f"<td class='msg'>{esc(resp_short)}</td>"
                f"</tr>"
            )
        return (
            "<table><thead><tr><th>Skill</th><th>Status</th><th>Message</th></tr></thead>"
            f"<tbody>{''.join(rows_html)}</tbody></table>"
        )

    pass_tags = skill_list("pass")

    doc = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>GPTfy Agent Skills — Final E2E Report (Master Dev)</title>
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
    margin: 0; font-family: var(--font); color: var(--text); line-height: 1.5;
    background:
      radial-gradient(1200px 600px at 10% -10%, #1a3a5c 0%, transparent 55%),
      radial-gradient(900px 500px at 100% 0%, #1e2d22 0%, transparent 50%),
      var(--bg);
  }}
  .wrap {{ max-width: 1120px; margin: 0 auto; padding: 2rem 1.25rem 4rem; }}
  header.hero {{
    border: 1px solid var(--border);
    background: linear-gradient(145deg, var(--panel), #15202e);
    border-radius: 16px; padding: 1.75rem; margin-bottom: 1.25rem;
  }}
  header.hero h1 {{ margin: 0 0 .4rem; font-size: 1.7rem; letter-spacing: -0.02em; }}
  header.hero p {{ margin: .2rem 0; color: var(--muted); }}
  .verdict {{
    margin-top: 1rem; padding: .85rem 1rem; border-radius: 10px;
    background: #14352a; border: 1px solid #2a5c44; color: var(--ok); font-weight: 600;
  }}
  .chips {{ display: flex; flex-wrap: wrap; gap: .5rem; margin-top: 1rem; }}
  .chip {{
    background: var(--panel2); border: 1px solid var(--border); border-radius: 999px;
    padding: .35rem .75rem; font-size: .85rem;
  }}
  .chip strong {{ color: var(--accent); }}
  h2 {{
    margin: 2rem 0 .75rem; font-size: 1.18rem;
    border-bottom: 1px solid var(--border); padding-bottom: .4rem;
  }}
  h3 {{ margin: .9rem 0 .4rem; font-size: 1rem; }}
  .grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(130px, 1fr)); gap: .75rem; }}
  .stat {{
    background: var(--panel); border: 1px solid var(--border); border-radius: 12px;
    padding: .9rem 1rem;
  }}
  .stat .n {{ font-size: 1.7rem; font-weight: 700; line-height: 1.1; }}
  .stat .l {{ color: var(--muted); font-size: .78rem; margin-top: .25rem; }}
  .stat.ok .n {{ color: var(--ok); }}
  .stat.warn .n {{ color: var(--warn); }}
  .stat.bad .n {{ color: var(--bad); }}
  .stat.mute .n {{ color: var(--muted); }}
  section.card {{
    background: var(--panel); border: 1px solid var(--border); border-radius: 12px;
    padding: 1.1rem 1.25rem; margin-bottom: 1rem;
  }}
  table {{ width: 100%; border-collapse: collapse; font-size: .86rem; }}
  th, td {{ text-align: left; padding: .5rem .45rem; border-bottom: 1px solid var(--border); vertical-align: top; }}
  th {{
    color: var(--muted); font-weight: 600; font-size: .75rem;
    text-transform: uppercase; letter-spacing: .04em;
  }}
  code {{ font-family: ui-monospace, Consolas, monospace; font-size: .84em; color: #b8e0ff; }}
  .tags {{ display: flex; flex-wrap: wrap; gap: .4rem; }}
  .tag {{
    background: var(--panel2); border: 1px solid var(--border); border-radius: 6px;
    padding: .15rem .4rem; font-size: .78rem;
  }}
  .pill {{
    display: inline-block; padding: .12rem .45rem; border-radius: 999px;
    font-size: .72rem; font-weight: 700; text-transform: uppercase;
  }}
  .pill.ok {{ background: #14352a; color: var(--ok); }}
  .pill.warn {{ background: #3a2e0e; color: var(--warn); }}
  .pill.bad {{ background: #3a1518; color: var(--bad); }}
  .pill.mute {{ background: #2a3340; color: var(--muted); }}
  .note {{ color: var(--muted); font-size: .9rem; }}
  .msg {{ color: var(--muted); font-size: .82rem; }}
  a {{ color: var(--accent); }}
  ul {{ margin: .35rem 0 .35rem 1.15rem; padding: 0; }}
  li {{ margin: .22rem 0; }}
  footer {{ margin-top: 2rem; color: var(--muted); font-size: .85rem; }}
  .two {{ display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }}
  @media (max-width: 800px) {{ .two {{ grid-template-columns: 1fr; }} }}
  .bar {{
    height: 12px; border-radius: 999px; background: #243044; overflow: hidden;
    display: flex; margin: .75rem 0 0;
  }}
  .bar span {{ display: block; height: 100%; }}
  .bar .p {{ background: var(--ok); }}
  .bar .m {{ background: #6b7c93; }}
  .bar .d {{ background: var(--warn); }}
  .bar .b {{ background: var(--bad); }}
  details summary {{ cursor: pointer; color: var(--accent); margin: .5rem 0; }}
</style>
</head>
<body>
<div class="wrap">
  <header class="hero">
    <h1>GPTfy Agent Skills — Final E2E Report</h1>
    <p><strong>Org:</strong> Master Dev · <strong>Agent:</strong> GPTfy Master Agent</p>
    <p><strong>API DeveloperName:</strong> <code>IT_Helpdesk_Assistant05/08/2026, 11:47</code></p>
    <p><strong>Generated:</strong> {esc(gen)} · Method: <code>invokeAgentSkill</code> (JSON → Apex)</p>
    <div class="chips">
      <span class="chip"><strong>{total}</strong> skills invoked</span>
      <span class="chip"><strong>{pass_n}</strong> business pass ({pct}%)</span>
      <span class="chip"><strong>{miss_n}</strong> missing feature (N/A)</span>
      <span class="chip"><strong>{data_n + biz_n}</strong> residual</span>
    </div>
    <div class="verdict">
      Verdict: Core CRM skills are ready on Master Dev — {pass_n}/{total} real business passes.
      Remaining failures are almost all optional packages not installed (CPQ, Quotes, FSL, Knowledge, FinServ).
    </div>
    <div class="bar" title="pass / missing feature / data / business">
      <span class="p" style="width:{100*pass_n/total if total else 0:.1f}%"></span>
      <span class="m" style="width:{100*miss_n/total if total else 0:.1f}%"></span>
      <span class="d" style="width:{100*data_n/total if total else 0:.1f}%"></span>
      <span class="b" style="width:{100*biz_n/total if total else 0:.1f}%"></span>
    </div>
  </header>

  <h2>Scoreboard</h2>
  <div class="grid">
    <div class="stat ok"><div class="n">{pass_n}</div><div class="l">pass<br/>real Apex success</div></div>
    <div class="stat mute"><div class="n">{miss_n}</div><div class="l">fail_missing_feature<br/>org package N/A</div></div>
    <div class="stat warn"><div class="n">{data_n}</div><div class="l">fail_data<br/>Quotes not enabled</div></div>
    <div class="stat bad"><div class="n">{biz_n}</div><div class="l">fail_business<br/>transfer edge case</div></div>
    <div class="stat"><div class="n">{total}</div><div class="l">total invoked<br/>linked to agent</div></div>
  </div>

  <h2>Pass criteria</h2>
  <section class="card">
    <ul>
      <li>HTTP <strong>200</strong> + API status <strong>Success</strong></li>
      <li>Apex business <code>success: true</code> (or success HTML marker)</li>
      <li>Not counted as pass: missing param, no match, class not found, feature unavailable</li>
    </ul>
  </section>

  <h2>What was delivered</h2>
  <section class="card">
    <div class="two">
      <div>
        <h3>Deploy &amp; seed</h3>
        <ul>
          <li>Full Agentic handler package deployed to Master Dev</li>
          <li>111 package skills seeded; ~110 linked to agent</li>
          <li>CRM seed graph: Account, Contact, Lead, Campaign, Opp, Case, Task, Event, Asset, Order, WorkOrder, Partner, Queue</li>
          <li>8 legacy prompts blocked on Data Extraction Mapping update (handlers still work via API)</li>
        </ul>
      </div>
      <div>
        <h3>Natural keys (handlers live)</h3>
        <ul>
          <li>Cases: resolve by <code>CaseNumber</code> or <code>Subject</code> (Id optional)</li>
          <li>Parents: prefer <strong>Name</strong> / email over Salesforce Ids</li>
          <li>Smoke verified: fetch case by number/subject; create case with AccountName + ContactName</li>
          <li>Unique match only — no guess on multimatch</li>
        </ul>
      </div>
    </div>
  </section>

  <h2>Natural-key smoke (post matrix)</h2>
  <section class="card">
    <table>
      <thead><tr><th>Call</th><th>Params</th><th>Result</th></tr></thead>
      <tbody>
        <tr>
          <td><code>fetch_case_details</code></td>
          <td><code>CaseNumber=00001026</code></td>
          <td><span class="pill ok">pass</span></td>
        </tr>
        <tr>
          <td><code>fetch_case_details</code></td>
          <td><code>Subject=E2E Skill Test Case</code></td>
          <td><span class="pill ok">pass</span></td>
        </tr>
        <tr>
          <td><code>create_case</code></td>
          <td><code>AccountName</code> + <code>ContactName</code> (no Ids)</td>
          <td><span class="pill ok">pass</span> → case 00001030</td>
        </tr>
      </tbody>
    </table>
  </section>

  <h2>fail_missing_feature ({miss_n}) — expected N/A</h2>
  <section class="card">
    <p class="note">Package / feature not present on Master Dev. Handlers correctly return unavailable — not code defects.</p>
    {detail_table("fail_missing_feature")}
  </section>

  <h2>Residual ({data_n + biz_n})</h2>
  <section class="card">
    <h3>fail_data ({data_n})</h3>
    <p class="note">Standard Quotes not enabled → no QuoteId seed. Enable Quotes to clear.</p>
    {detail_table("fail_data")}
    <h3>fail_business ({biz_n})</h3>
    {detail_table("fail_business")}
  </section>

  <h2>Business pass skills ({pass_n})</h2>
  <section class="card">
    <p class="note">All listed below returned real Apex business success on seeded data.</p>
    {pass_tags}
    <details>
      <summary>Expand pass table with response snippet</summary>
      {detail_table("pass")}
    </details>
  </section>

  <h2>Optional next steps</h2>
  <section class="card">
    <ul>
      <li>Enable <strong>Quotes</strong> → clears 3 fail_data + quote skill family</li>
      <li>Second user / ownership change for real <code>transfer_record_owner</code> path</li>
      <li>Re-run seeded matrix with natural-key fixtures for refreshed Id-free transcript</li>
      <li>Install CPQ / FSL / Knowledge / FinServ only if those product lines are in scope</li>
    </ul>
  </section>

  <h2>Artifacts</h2>
  <section class="card">
    <table>
      <thead><tr><th>File</th><th>Description</th></tr></thead>
      <tbody>
        <tr><td><a href="SKILL_INVOKE_TRANSCRIPT_SEEDED.html">SKILL_INVOKE_TRANSCRIPT_SEEDED.html</a></td><td>Per-skill request/response (strict matrix)</td></tr>
        <tr><td><a href="FINAL_E2E_REPORT.html">FINAL_E2E_REPORT.html</a></td><td>This executive report</td></tr>
        <tr><td><a href="E2E_TEST_REPORT.html">E2E_TEST_REPORT.html</a></td><td>Earlier deploy/capability notes</td></tr>
        <tr><td><code>scripts/run_seeded_matrix.py</code></td><td>Seed CRM + strict matrix runner</td></tr>
        <tr><td><code>scripts/smoke_natural_keys.py</code></td><td>Natural-key smoke invokes</td></tr>
      </tbody>
    </table>
  </section>

  <footer>
    GPTfy Agent Library · Master Dev E2E · Pass = real Apex success only ·
    Core deployable = pass + missing-feature N/A = {pass_n + miss_n}/{total}
  </footer>
</div>
</body>
</html>
"""
    OUT.write_text(doc, encoding="utf-8")
    print(f"Wrote {OUT} ({total} skills: pass={pass_n} miss={miss_n} data={data_n} biz={biz_n})")


if __name__ == "__main__":
    main()
