# -*- coding: utf-8 -*-
"""
Public multi-run E2E dashboard (share one HTML link — no git clone).

- Appends each MAIN publish into Reports/runs_history.json
- Rebuilds Reports/DASHBOARD.html (self-contained; history embedded)
- Copies to Project_SFDC/docs/gptfy-agent-skills-e2e/dashboard.html for public host

Run alone:
  python build_public_dashboard.py
  python build_public_dashboard.py --rebuild-from-archives
"""
from __future__ import annotations

import argparse
import html as H
import json
import re
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

from build_main_report import ARCHIVE, MAIN_PATH, PUBLIC_DOCS, parse_seeded_html  # noqa: E402

REPORTS = MAIN_PATH.parent
HISTORY = REPORTS / "runs_history.json"
DASHBOARD = REPORTS / "DASHBOARD.html"


def counts_from_rows(rows: list[dict]) -> dict[str, int]:
    c = Counter((r.get("category") or "unknown") for r in rows)
    total = sum(c.values())
    return {
        "total": total,
        "pass": int(c.get("pass", 0)),
        "fail_data": int(c.get("fail_data", 0)),
        "fail_business": int(c.get("fail_business", 0)),
        "fail_api": int(c.get("fail_api", 0)),
        "fail_missing_feature": int(c.get("fail_missing_feature", 0)),
        "fail_missing_class": int(c.get("fail_missing_class", 0)),
        "other": int(total - sum(c.get(k, 0) for k in (
            "pass", "fail_data", "fail_business", "fail_api",
            "fail_missing_feature", "fail_missing_class",
        ))),
    }


def load_history() -> list[dict]:
    if not HISTORY.exists():
        return []
    try:
        data = json.loads(HISTORY.read_text(encoding="utf-8"))
        return list(data.get("runs") or [])
    except json.JSONDecodeError:
        return []


def save_history(runs: list[dict]) -> None:
    REPORTS.mkdir(parents=True, exist_ok=True)
    # newest last for charts; display newest first
    payload = {
        "updatedAt": datetime.now(timezone.utc).isoformat(),
        "runCount": len(runs),
        "runs": runs,
    }
    HISTORY.write_text(json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8")


def entry_from_rows(
    rows: list[dict],
    *,
    when: str,
    label: str,
    org: str,
    agent: str,
    slug: str,
    archive: str,
    need: str,
) -> dict:
    c = counts_from_rows(rows)
    return {
        "id": when + "_" + re.sub(r"[^a-zA-Z0-9_-]+", "-", slug)[:40],
        "when": when,
        "label": label or slug,
        "org": org,
        "agent": agent,
        "archive": archive,
        "note": (need or "").strip()[:500],
        **c,
        "passRate": round(100.0 * c["pass"] / c["total"], 1) if c["total"] else 0.0,
    }


def rebuild_from_archives() -> list[dict]:
    """Scan archive/*.html + MAIN into history (oldest first)."""
    runs: list[dict] = []
    files = sorted(ARCHIVE.glob("*.html")) if ARCHIVE.exists() else []
    for p in files:
        m = re.match(r"(\d{4}-\d{2}-\d{2}_\d{6})_(.+)\.html$", p.name)
        if not m:
            continue
        ts, slug = m.group(1), m.group(2)
        rows = parse_seeded_html(p)
        if not rows:
            continue
        when = (
            f"{ts[0:4]}-{ts[5:7]}-{ts[8:10]}T{ts[11:13]}:{ts[13:15]}:{ts[15:17]}"
        )
        # local-ish ISO without Z
        runs.append(
            entry_from_rows(
                rows,
                when=when,
                label=slug.replace("-", " "),
                org="Master Dev",
                agent="",
                slug=slug,
                archive=p.name,
                need="",
            )
        )
    # MAIN as tip-of-tree latest if present
    if MAIN_PATH.exists():
        rows = parse_seeded_html(MAIN_PATH)
        if rows:
            now = datetime.now().astimezone().strftime("%Y-%m-%dT%H:%M:%S")
            latest = entry_from_rows(
                rows,
                when=now,
                label="MAIN (latest)",
                org="Master Dev",
                agent="",
                slug="main-latest",
                archive=MAIN_PATH.name,
                need="Always-current MAIN_REPORT",
            )
            # de-dupe if last archive same counts as main within same minute is ok to keep both
            runs.append(latest)
    return runs


def append_run(
    rows: list[dict],
    *,
    org: str,
    agent: str,
    slug: str,
    archive_name: str,
    need: str,
) -> list[dict]:
    runs = load_history()
    when = datetime.now().astimezone().strftime("%Y-%m-%dT%H:%M:%S%z")
    # normalize +0100 → +01:00 for readability
    if len(when) >= 5 and when[-5] in "+-" and when[-3] != ":":
        when = when[:-2] + ":" + when[-2:]
    entry = entry_from_rows(
        rows,
        when=when,
        label=slug.replace("-", " "),
        org=org,
        agent=agent,
        slug=slug,
        archive=archive_name,
        need=need,
    )
    # avoid double-append if same archive name already last
    if not runs or runs[-1].get("archive") != archive_name:
        runs.append(entry)
    else:
        runs[-1] = entry
    save_history(runs)
    return runs


def render_dashboard(runs: list[dict]) -> str:
    latest = runs[-1] if runs else None
    # display newest first
    ordered = list(reversed(runs))
    data_json = json.dumps(runs, ensure_ascii=False)
    rows_html = []
    for i, r in enumerate(ordered, 1):
        n = len(runs) - i + 1  # run number oldest=1
        rows_html.append(
            f"<tr data-id=\"{H.escape(r.get('id',''))}\">"
            f"<td>{n}</td>"
            f"<td>{H.escape(r.get('when',''))}</td>"
            f"<td>{H.escape(r.get('label',''))}</td>"
            f"<td class=\"ok\"><b>{r.get('pass',0)}</b></td>"
            f"<td class=\"warn\">{r.get('fail_data',0)}</td>"
            f"<td class=\"bad\">{r.get('fail_business',0) + r.get('fail_api',0)}</td>"
            f"<td class=\"mute\">{r.get('fail_missing_feature',0)}</td>"
            f"<td>{r.get('total',0)}</td>"
            f"<td><b>{r.get('passRate',0)}%</b></td>"
            f"<td class=\"note\">{H.escape((r.get('note') or '')[:120])}</td>"
            f"</tr>"
        )
    if not rows_html:
        rows_html.append(
            "<tr><td colspan=\"10\">No runs yet. Publish a MAIN report to start history.</td></tr>"
        )

    latest_block = "<p class=\"muted\">No runs recorded yet.</p>"
    if latest:
        latest_block = f"""
        <div class="stats">
          <div class="stat total"><div class="n">{latest.get('total',0)}</div><div class="l">skills</div></div>
          <div class="stat ok"><div class="n">{latest.get('pass',0)}</div><div class="l">pass</div></div>
          <div class="stat warn"><div class="n">{latest.get('fail_data',0)}</div><div class="l">fail_data</div></div>
          <div class="stat bad"><div class="n">{(latest.get('fail_business',0) or 0)+(latest.get('fail_api',0) or 0)}</div><div class="l">fail business/api</div></div>
          <div class="stat mute"><div class="n">{latest.get('fail_missing_feature',0)}</div><div class="l">missing feature</div></div>
          <div class="stat rate"><div class="n">{latest.get('passRate',0)}%</div><div class="l">pass rate</div></div>
        </div>
        <p class="muted">Latest: <b>{H.escape(latest.get('when',''))}</b> · {H.escape(latest.get('label',''))} · Org {H.escape(latest.get('org') or '—')}</p>
        """

    # simple pass-rate bars
    bars = []
    for r in ordered[:24]:
        pr = float(r.get("passRate") or 0)
        bars.append(
            f"<div class=\"bar-row\" title=\"{H.escape(r.get('when',''))} · {pr}%\">"
            f"<span class=\"bar-label\">{H.escape((r.get('label') or '')[:28])}</span>"
            f"<div class=\"bar-track\"><div class=\"bar-fill\" style=\"width:{pr}%\"></div></div>"
            f"<span class=\"bar-pct\">{pr}%</span></div>"
        )

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<meta http-equiv="Cache-Control" content="no-cache"/>
<title>GPTfy Agent Skills — E2E Dashboard</title>
<style>
:root {{
  --bg:#0b1220; --card:#121a2b; --line:#243044; --text:#e8eef8; --muted:#93a4bb;
  --ok:#3dd68c; --warn:#f0b429; --bad:#f07178; --mute:#8b9cb3; --accent:#5eb1ff;
}}
* {{ box-sizing: border-box; }}
body {{ margin:0; font-family:Segoe UI,system-ui,sans-serif; background:var(--bg); color:var(--text); line-height:1.45; }}
.wrap {{ max-width:1100px; margin:0 auto; padding:1.25rem 1.25rem 3rem; }}
h1 {{ margin:0 0 .35rem; font-size:1.55rem; letter-spacing:-.02em; }}
.muted {{ color:var(--muted); font-size:.92rem; }}
.hero {{ background:linear-gradient(145deg,#152238,#101827); border:1px solid var(--line); border-radius:16px; padding:1.2rem 1.35rem; margin-bottom:1rem; }}
.banner {{ margin-top:.75rem; padding:.55rem .8rem; border-radius:10px; background:#14352a; border:1px solid #2a5c44; color:var(--ok); font-size:.9rem; }}
.stats {{ display:flex; flex-wrap:wrap; gap:.55rem; margin:1rem 0 .5rem; }}
.stat {{ min-width:5.5rem; padding:.55rem .75rem; border-radius:12px; background:var(--card); border:1px solid var(--line); }}
.stat .n {{ font-size:1.35rem; font-weight:700; }}
.stat .l {{ font-size:.72rem; color:var(--muted); text-transform:uppercase; letter-spacing:.04em; }}
.stat.ok .n {{ color:var(--ok); }} .stat.warn .n {{ color:var(--warn); }}
.stat.bad .n {{ color:var(--bad); }} .stat.mute .n {{ color:var(--mute); }}
.stat.rate .n {{ color:var(--accent); }}
.card {{ background:var(--card); border:1px solid var(--line); border-radius:14px; padding:1rem 1.1rem; margin:1rem 0; }}
h2 {{ margin:0 0 .75rem; font-size:1.05rem; }}
table {{ width:100%; border-collapse:collapse; font-size:.9rem; }}
th, td {{ text-align:left; padding:.5rem .45rem; border-bottom:1px solid var(--line); vertical-align:top; }}
th {{ color:var(--muted); font-weight:600; font-size:.78rem; text-transform:uppercase; letter-spacing:.03em; }}
td.ok {{ color:var(--ok); }} td.warn {{ color:var(--warn); }} td.bad {{ color:var(--bad); }} td.mute {{ color:var(--mute); }}
td.note {{ color:var(--muted); max-width:220px; font-size:.82rem; }}
.links a {{ color:var(--accent); margin-right:1rem; }}
.bar-row {{ display:grid; grid-template-columns:140px 1fr 48px; gap:.5rem; align-items:center; margin:.35rem 0; font-size:.82rem; }}
.bar-label {{ color:var(--muted); overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }}
.bar-track {{ height:8px; background:#1a2436; border-radius:99px; overflow:hidden; }}
.bar-fill {{ height:100%; background:linear-gradient(90deg,#2a5c44,var(--ok)); border-radius:99px; }}
.bar-pct {{ text-align:right; color:var(--accent); font-weight:600; }}
footer {{ margin-top:1.5rem; color:var(--muted); font-size:.82rem; }}
.kpi {{ font-size:1.8rem; font-weight:700; color:var(--accent); }}
</style>
</head>
<body>
<div class="wrap">
  <header class="hero">
    <h1>GPTfy Agent Skills — E2E Dashboard</h1>
    <p class="muted">Public run history. Share this page only — no repo access required.</p>
    <div class="banner">Auto-updates when a new matrix / retry is published (MAIN). Viewers: hard-refresh if cached.</div>
    <p class="kpi" style="margin:.85rem 0 0">{len(runs)} <span style="font-size:1rem;font-weight:600;color:var(--muted)">runs recorded</span></p>
    {latest_block}
    <p class="links" style="margin:.75rem 0 0">
      <a href="./index.html">Latest detail report (per skill)</a>
      <a href="./archive/">Archive HTML</a>
    </p>
  </header>

  <section class="card">
    <h2>Pass rate by run (newest first)</h2>
    {''.join(bars) if bars else '<p class="muted">No data yet.</p>'}
  </section>

  <section class="card">
    <h2>All runs</h2>
    <div style="overflow-x:auto">
      <table>
        <thead>
          <tr>
            <th>#</th><th>When</th><th>Label</th><th>Pass</th><th>Data</th><th>Biz/API</th><th>N/A feature</th><th>Total</th><th>Rate</th><th>Note</th>
          </tr>
        </thead>
        <tbody>
          {''.join(rows_html)}
        </tbody>
      </table>
    </div>
  </section>

  <footer>
    History file: <code>AGENT LIBRARY/Reports/runs_history.json</code>.
    Generated with embedded snapshot so hosting can be a single HTML file.
  </footer>
</div>
<script type="application/json" id="runs-data">{data_json}</script>
</body>
</html>
"""


def write_dashboard(runs: list[dict] | None = None) -> Path:
    if runs is None:
        runs = load_history()
    if not runs:
        runs = rebuild_from_archives()
        if runs:
            save_history(runs)
    DASHBOARD.write_text(render_dashboard(runs), encoding="utf-8")
    try:
        PUBLIC_DOCS.mkdir(parents=True, exist_ok=True)
        (PUBLIC_DOCS / "dashboard.html").write_text(DASHBOARD.read_text(encoding="utf-8"), encoding="utf-8")
        # keep a mirror of history for debugging
        if HISTORY.exists():
            (PUBLIC_DOCS / "runs_history.json").write_text(
                HISTORY.read_text(encoding="utf-8"), encoding="utf-8"
            )
    except Exception as e:
        print("WARN: public docs copy:", e)
    return DASHBOARD


def record_and_build(
    rows: list[dict],
    *,
    org: str,
    agent: str,
    slug: str,
    archive_name: str,
    need: str,
) -> Path:
    runs = append_run(
        rows,
        org=org,
        agent=agent,
        slug=slug,
        archive_name=archive_name,
        need=need,
    )
    return write_dashboard(runs)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--rebuild-from-archives",
        action="store_true",
        help="Rescan archive/ + MAIN into runs_history.json",
    )
    args = ap.parse_args()
    if args.rebuild_from_archives:
        runs = rebuild_from_archives()
        save_history(runs)
        path = write_dashboard(runs)
        print("Rebuilt history runs:", len(runs))
    else:
        path = write_dashboard()
        print("Dashboard from existing history")
    print("DASHBOARD:", path)
    print("Public copy:", PUBLIC_DOCS / "dashboard.html")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
