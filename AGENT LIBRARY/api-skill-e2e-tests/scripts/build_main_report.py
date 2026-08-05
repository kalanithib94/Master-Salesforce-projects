# -*- coding: utf-8 -*-
"""
Build MAIN_REPORT.html (always latest, public share) + dated archive copy.

Lives in AGENT LIBRARY/Reports/ (separate from api-skill-e2e-tests harness).
Detail-first: every skill Request + Response. Minimal header (no scoreboards).
"""
from __future__ import annotations

import html as H
import json
import re
import shutil
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]  # api-skill-e2e-tests
LIBRARY = ROOT.parent  # AGENT LIBRARY
# Dedicated reports folder (not under the e2e harness)
REPORTS = LIBRARY / "Reports"
ARCHIVE = REPORTS / "archive"
# Project_SFDC/docs/gptfy-agent-skills-e2e → GitHub Pages public URL
PUBLIC_DOCS = LIBRARY.parent / "docs" / "gptfy-agent-skills-e2e"

MAIN_NAME = "MAIN_REPORT.html"
MAIN_PATH = REPORTS / MAIN_NAME
SEEDED_JSON = Path(__file__).resolve().parent / "results" / "matrix_report_seeded.json"
SEEDED_HTML = ROOT / "SKILL_INVOKE_TRANSCRIPT_SEEDED.html"


def pill_cls(c: str) -> str:
    return {
        "pass": "ok",
        "fail_business": "bad",
        "fail_api": "bad",
        "fail_data": "warn",
        "fail_missing_feature": "mute",
        "fail_missing_class": "mute",
    }.get(c, "mute")


def parse_seeded_html(path: Path) -> list[dict]:
    if not path.exists():
        return []
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
                "category": cat,
                "skill": skill,
                "request": _unescape(req),
                "response": _unescape(resp),
            }
        )
    return rows


def parse_seeded_json(path: Path) -> list[dict]:
    if not path.exists():
        return []
    data = json.loads(path.read_text(encoding="utf-8"))
    rows = []
    for r in data.get("results") or []:
        ad = r.get("apexData")
        if isinstance(ad, dict):
            resp = ad.get("message") or ad.get("error") or json.dumps(ad, ensure_ascii=False, indent=2)
        else:
            resp = str(ad or r.get("errorSnippet") or "")
        resp = re.sub(r"<[^>]+>", " ", str(resp))
        resp = re.sub(r"\s+", " ", resp).strip()
        # prefer pretty request
        req = r.get("request") or {}
        rows.append(
            {
                "category": r.get("category") or "unknown",
                "skill": r.get("skill") or "",
                "request": json.dumps(req, indent=2, ensure_ascii=False),
                "response": resp if not isinstance(ad, dict) else json.dumps(
                    {
                        **({k: v for k, v in ad.items() if k != "message"}),
                        "message": re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", str(ad.get("message") or ""))).strip()
                        if ad.get("message")
                        else ad.get("error"),
                    }
                    if isinstance(ad, dict) and "success" in ad
                    else (ad if isinstance(ad, dict) else {"text": resp}),
                    indent=2,
                    ensure_ascii=False,
                ),
            }
        )
    return rows


def _unescape(s: str) -> str:
    return (
        s.replace("&quot;", '"')
        .replace("&lt;", "<")
        .replace("&gt;", ">")
        .replace("&#39;", "'")
        .replace("&amp;", "&")
        .strip()
    )


def write_detail_html(
    rows: list[dict],
    *,
    title: str,
    need: str,
    org: str,
    agent: str,
    local_time: str,
    utc_time: str,
    report_kind: str,
    archive_note: str,
    out: Path,
) -> None:
    need_items = [ln.strip("- ").strip() for ln in need.splitlines() if ln.strip()]
    need_html = "".join(f"<li>{H.escape(x)}</li>" for x in need_items) or "<li>—</li>"

    toc = "".join(
        f'<li><a href="#{H.escape(r["skill"])}">{H.escape(r["skill"])}</a> '
        f'<span class="pill {pill_cls(r["category"])}">{H.escape(r["category"])}</span></li>'
        for r in sorted(rows, key=lambda x: x["skill"])
    )

    cards = []
    for r in sorted(rows, key=lambda x: x["skill"]):
        c = r["category"]
        req = r["request"]
        if not isinstance(req, str):
            req = json.dumps(req, indent=2, ensure_ascii=False)
        resp = r["response"] if isinstance(r["response"], str) else json.dumps(r["response"], indent=2, ensure_ascii=False)
        cards.append(
            f'<article class="card {pill_cls(c)}" id="{H.escape(r["skill"])}">'
            f'<header><h2><code>{H.escape(r["skill"])}</code></h2>'
            f'<span class="pill {pill_cls(c)}">{H.escape(c)}</span></header>'
            f'<div class="pair">'
            f'<div class="col"><h3>Request</h3><pre>{H.escape(req)}</pre></div>'
            f'<div class="col"><h3>Response</h3><pre>{H.escape(resp)}</pre></div>'
            f"</div></article>"
        )

    banner = (
        "MAIN report — always overwritten with the latest full run. "
        "Dated snapshots live under AGENT LIBRARY/Reports/archive/."
        if report_kind == "main"
        else "Archived dated run (immutable snapshot)."
    )

    doc = f"""<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>{H.escape(title)}</title>
<style>
body{{font-family:Segoe UI,system-ui,sans-serif;background:#0f1419;color:#e7eef8;margin:0;padding:1.25rem 1.5rem 3rem;line-height:1.45}}
.wrap{{max-width:1200px;margin:0 auto}}
.hero{{background:linear-gradient(145deg,#1a2332,#15202e);border:1px solid #2e3f56;border-radius:14px;padding:1.2rem 1.35rem;margin-bottom:1rem}}
.banner{{background:#1e3a2f;border:1px solid #2a5c44;color:#3dd68c;border-radius:10px;padding:.65rem .9rem;margin:.75rem 0 0;font-size:.9rem}}
h1{{margin:0 0 .35rem;font-size:1.4rem}}
.muted{{color:#9db0c9;font-size:.92rem}}
section.intro,article.card{{background:#1a2332;border:1px solid #2e3f56;border-radius:12px;padding:1rem 1.15rem;margin:.85rem 0;border-left:4px solid #2e3f56}}
article.card.ok{{border-left-color:#3dd68c}} article.card.warn{{border-left-color:#f0b429}}
article.card.bad{{border-left-color:#f07178}} article.card.mute{{border-left-color:#6b7c93}}
.pair{{display:grid;grid-template-columns:1fr 1fr;gap:.75rem}}
@media(max-width:900px){{.pair{{grid-template-columns:1fr}}}}
.col h3{{margin:.1rem 0 .4rem;font-size:.95rem;color:#c5d4e8}}
pre{{background:#0d1218;padding:.75rem .85rem;border-radius:8px;white-space:pre-wrap;word-break:break-word;
  font-size:.8rem;line-height:1.4;max-height:none;overflow:auto;border:1px solid #243044;margin:0}}
.pill{{font-size:.72rem;font-weight:700;padding:.12rem .5rem;border-radius:999px}}
.pill.ok{{background:#14352a;color:#3dd68c}}.pill.warn{{background:#3a2e0e;color:#f0b429}}
.pill.bad{{background:#3a1518;color:#f07178}}.pill.mute{{background:#2a3340;color:#9db0c9}}
code{{color:#b8e0ff}} header{{display:flex;flex-wrap:wrap;align-items:center;gap:.5rem}}
header h2{{font-size:1.1rem;margin:0}} .toc a{{color:#5eb1ff;text-decoration:none}}
.toc{{columns:2}} @media(max-width:700px){{.toc{{columns:1}}}} ul{{margin:.35rem 0 .2rem 1.15rem}}
</style></head><body><div class="wrap">
<header class="hero">
  <h1>{H.escape(title)}</h1>
  <p class="muted">{H.escape(local_time)} · {H.escape(utc_time)}</p>
  <p class="muted">Org <b>{H.escape(org)}</b> · Agent <code>{H.escape(agent)}</code></p>
  <div class="banner">{H.escape(banner)}</div>
  <p class="muted" style="margin-top:.65rem">{H.escape(archive_note)}</p>
</header>
<section class="intro">
  <h2 style="margin:0 0 .5rem;font-size:1rem">Why this update</h2>
  <ul>{need_html}</ul>
  <h2 style="margin:1rem 0 .5rem;font-size:1rem">Skills in this report</h2>
  <ul class="toc">{toc or "<li>—</li>"}</ul>
</section>
{"".join(cards)}
<footer class="muted" style="margin-top:1.5rem;font-size:.84rem">
  Each card shows the full invoke request and response.
  Main: AGENT LIBRARY/Reports/MAIN_REPORT.html (always latest).
  Archives: AGENT LIBRARY/Reports/archive/
</footer>
</div></body></html>
"""
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(doc, encoding="utf-8")


def publish_main_and_archive(
    rows: list[dict],
    *,
    need: str,
    org: str = "Master Dev",
    agent: str = "",
    slug: str = "run",
) -> tuple[Path, Path]:
    """Overwrite MAIN_REPORT.html and write dated archive. Optionally sync GitHub Pages copy."""
    ARCHIVE.mkdir(parents=True, exist_ok=True)
    now = datetime.now().astimezone()
    local_time = now.strftime("%Y-%m-%d %H:%M:%S %Z")
    utc_time = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    ts = now.strftime("%Y-%m-%d_%H%M%S")
    safe = re.sub(r"[^a-zA-Z0-9_-]+", "-", slug)[:48].strip("-") or "run"
    arch = ARCHIVE / f"{ts}_{safe}.html"

    title = "GPTfy Agent Skills — E2E request / response report"
    write_detail_html(
        rows,
        title=title,
        need=need,
        org=org,
        agent=agent,
        local_time=local_time,
        utc_time=utc_time,
        report_kind="main",
        archive_note=f"This MAIN file is overwritten on every run. Snapshot: {arch.name}",
        out=MAIN_PATH,
    )
    write_detail_html(
        rows,
        title=title + f" (archive {ts})",
        need=need,
        org=org,
        agent=agent,
        local_time=local_time,
        utc_time=utc_time,
        report_kind="archive",
        archive_note=f"Immutable archive of the run at {local_time}. MAIN_REPORT.html is the always-latest file.",
        out=arch,
    )

    # Public Pages path (repo root docs/) for boss-facing URL
    try:
        PUBLIC_DOCS.mkdir(parents=True, exist_ok=True)
        shutil.copy2(MAIN_PATH, PUBLIC_DOCS / "index.html")
        # also keep a copy of archive under pages history optional
        hist = PUBLIC_DOCS / "archive"
        hist.mkdir(exist_ok=True)
        shutil.copy2(arch, hist / arch.name)
        (PUBLIC_DOCS / "README.md").write_text(
            "# GPTfy Agent Skills E2E\n\n"
            "Public always-latest report for verification.\n\n"
            "- **Main (this page):** full request + response per skill\n"
            "- **Archive:** `archive/` dated snapshots\n",
            encoding="utf-8",
        )
    except Exception as e:
        print("WARN: could not sync docs/ pages copy:", e)

    return MAIN_PATH, arch


def main() -> int:
    rows = parse_seeded_json(SEEDED_JSON)
    if not rows:
        rows = parse_seeded_html(SEEDED_HTML)
    if not rows:
        print("No matrix results found. Run run_seeded_matrix.py first or provide a regression report.")
        return 1

    org, agent = "Master Dev", "GPTfy Master Agent"
    if SEEDED_JSON.exists():
        data = json.loads(SEEDED_JSON.read_text(encoding="utf-8"))
        org = data.get("org") or org
        agent = data.get("agentDeveloperName") or agent

    main_p, arch_p = publish_main_and_archive(
        rows,
        need=(
            "Full Master Dev seeded skill matrix — boss-facing always-latest report\n"
            "Strict pass = real Apex business success; request/response detail for every skill"
        ),
        org=org,
        agent=str(agent),
        slug="full-seeded-matrix",
    )
    print("MAIN:", main_p)
    print("ARCHIVE:", arch_p)
    print("Skills:", len(rows))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
