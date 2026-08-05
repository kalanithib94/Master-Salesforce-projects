# -*- coding: utf-8 -*-
"""Build full request/response transcript for all matrix skills."""
from __future__ import annotations

import html as H
import json
import re
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
src = ROOT / "scripts" / "results" / "matrix_report.json"
d = json.loads(src.read_text(encoding="utf-8"))
results = sorted(d["results"], key=lambda e: e.get("skill") or "")


def strip_html(s: str) -> str:
    s = re.sub(r"<br\s*/?>", "\n", s or "", flags=re.I)
    s = re.sub(r"</li>", "\n", s)
    s = re.sub(r"<[^>]+>", "", s)
    s = (
        s.replace("&nbsp;", " ")
        .replace("&lt;", "<")
        .replace("&gt;", ">")
        .replace("&amp;", "&")
        .replace("&quot;", '"')
    )
    s = re.sub(r"\n{3,}", "\n\n", s)
    return s.strip()


def flat_answer(e: dict) -> str:
    ad = e.get("apexData")
    sn = e.get("errorSnippet")
    if isinstance(ad, dict):
        msg = ad.get("message") or ad.get("error")
        if isinstance(msg, str) and msg.strip():
            return msg
        return json.dumps(ad, ensure_ascii=False, indent=2)
    if ad is not None:
        return str(ad)
    if sn:
        return sn
    return json.dumps(
        {"apiStatus": e.get("apiStatus"), "http": e.get("http"), "message": "empty body"},
        ensure_ascii=False,
    )


rows = []
for i, e in enumerate(results, 1):
    answer_raw = flat_answer(e)
    answer_plain = strip_html(answer_raw if isinstance(answer_raw, str) else json.dumps(answer_raw))
    rows.append(
        {
            "n": i,
            "skill": e.get("skill"),
            "promptId": e.get("promptId"),
            "category": e.get("category"),
            "apiStatus": e.get("apiStatus"),
            "http": e.get("http"),
            "elapsedSec": e.get("elapsedSec"),
            "request": e.get("payload") or {},
            "response_plain": answer_plain[:5000],
            "apexData": e.get("apexData"),
        }
    )

counts = d.get("counts") or {}
note = (
    "Direct invokeAgentSkill: request=JSON tool params, response=Apex/GPTfy payload. "
    "Not natural-language agent chat."
)

# JSON
(ROOT / "scripts" / "results" / "skill_invoke_transcript.json").write_text(
    json.dumps(
        {
            "org": d.get("org"),
            "agentDeveloperName": d.get("agentDeveloperName"),
            "generated": datetime.now(timezone.utc).isoformat(),
            "note": note,
            "total": len(rows),
            "counts": counts,
            "skills": rows,
        },
        indent=2,
        ensure_ascii=False,
    ),
    encoding="utf-8",
)

# Markdown
md = [
    "# Skill invoke transcript — all 110",
    "",
    f"**Org:** {d.get('org')}  ",
    f"**Agent DevName:** `{d.get('agentDeveloperName')}`  ",
    f"**Total:** {len(rows)}  ",
    f"**Counts:** {counts}  ",
    "",
    note,
    "",
]
for r in rows:
    md.append(f"## {r['n']}. `{r['skill']}`  ·  **{r['category']}**")
    md.append("")
    md.append("### Request (parameters sent)")
    md.append("```json")
    md.append(json.dumps(r["request"], indent=2, ensure_ascii=False))
    md.append("```")
    md.append("")
    md.append(f"### Response (API status: `{r['apiStatus']}`, HTTP {r['http']})")
    md.append("```")
    md.append(r["response_plain"][:3500] or "(empty)")
    md.append("```")
    md.append("")
    md.append("---")
    md.append("")

(ROOT / "SKILL_INVOKE_TRANSCRIPT.md").write_text("\n".join(md), encoding="utf-8")


def cat_class(c: str) -> str:
    return {"handler_ok": "ok", "handler_error": "warn", "api_fail": "bad"}.get(c, "mute")


cards = []
for r in rows:
    req = H.escape(json.dumps(r["request"], indent=2, ensure_ascii=False))
    resp = H.escape(r["response_plain"][:5000] or "(empty)")
    sk = H.escape(r["skill"] or "")
    cards.append(
        f"""
    <article class="card {cat_class(r['category'])}" data-cat="{H.escape(r['category'])}" id="{sk}">
      <header>
        <span class="n">#{r['n']}</span>
        <h2><code>{sk}</code></h2>
        <span class="pill {cat_class(r['category'])}">{H.escape(r['category'])}</span>
        <span class="meta">HTTP {r['http']} · API {H.escape(str(r['apiStatus']))} · {r.get('elapsedSec')}s · promptId {H.escape(str(r.get('promptId') or ''))}</span>
      </header>
      <div class="pair">
        <div>
          <h3>Request (JSON params sent)</h3>
          <pre>{req}</pre>
        </div>
        <div>
          <h3>Response (what came back)</h3>
          <pre>{resp}</pre>
        </div>
      </div>
    </article>"""
    )

toc = "\n".join(
    f'<li><a href="#{H.escape(r["skill"] or "")}"><code>{H.escape(r["skill"] or "")}</code></a>'
    f' · {H.escape(r["category"])}</li>'
    for r in rows
)

html_doc = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<title>110 Skill Invoke Transcript — Master Dev</title>
<style>
:root {{
  --bg:#0f1419; --panel:#1a2332; --border:#2e3f56; --text:#e7eef8; --muted:#9db0c9;
  --ok:#3dd68c; --warn:#f0b429; --bad:#f07178; --accent:#5eb1ff;
}}
* {{ box-sizing:border-box; }}
body {{ margin:0; font-family:Segoe UI,system-ui,sans-serif; background:var(--bg); color:var(--text); line-height:1.45; }}
.wrap {{ max-width:1100px; margin:0 auto; padding:1.5rem 1rem 3rem; }}
h1 {{ margin:0 0 .4rem; font-size:1.45rem; }}
.sub {{ color:var(--muted); margin:0 0 1rem; font-size:.92rem; }}
.filters {{ display:flex; flex-wrap:wrap; gap:.5rem; margin:1rem 0 1.25rem; position:sticky; top:0;
  background:rgba(15,20,25,.94); padding:.6rem 0; z-index:5; }}
.filters button {{
  background:var(--panel); border:1px solid var(--border); color:var(--text);
  border-radius:999px; padding:.4rem .85rem; cursor:pointer; font-size:.85rem;
}}
.filters button.active {{ border-color:var(--accent); color:var(--accent); }}
.card {{
  background:var(--panel); border:1px solid var(--border); border-radius:12px;
  padding:1rem 1.1rem; margin-bottom:.85rem; border-left:4px solid var(--border);
}}
.card.ok {{ border-left-color:var(--ok); }}
.card.warn {{ border-left-color:var(--warn); }}
.card.bad {{ border-left-color:var(--bad); }}
.card.hidden {{ display:none; }}
.card header {{ display:flex; flex-wrap:wrap; align-items:baseline; gap:.5rem .75rem; margin-bottom:.65rem; }}
.card h2 {{ margin:0; font-size:1.05rem; flex:1; min-width:12rem; }}
.card .n {{ color:var(--muted); font-size:.85rem; }}
.meta {{ color:var(--muted); font-size:.8rem; width:100%; }}
.pill {{ font-size:.72rem; font-weight:700; text-transform:uppercase; padding:.15rem .5rem; border-radius:999px; }}
.pill.ok {{ background:#14352a; color:var(--ok); }}
.pill.warn {{ background:#3a2e0e; color:var(--warn); }}
.pill.bad {{ background:#3a1518; color:var(--bad); }}
.pair {{ display:grid; grid-template-columns:1fr 1fr; gap:.75rem; }}
@media (max-width:800px) {{ .pair {{ grid-template-columns:1fr; }} }}
.pair h3 {{ margin:0 0 .35rem; font-size:.78rem; text-transform:uppercase; letter-spacing:.04em; color:var(--muted); }}
pre {{
  margin:0; background:#0d1218; border:1px solid var(--border); border-radius:8px;
  padding:.65rem .75rem; font-size:.78rem; white-space:pre-wrap; word-break:break-word;
  max-height:22rem; overflow:auto; font-family:ui-monospace,Consolas,monospace;
}}
code {{ color:#b8e0ff; }}
.toc {{ columns:2; font-size:.85rem; margin-bottom:1.5rem; }}
.toc a {{ color:var(--accent); text-decoration:none; }}
.toc li {{ break-inside:avoid; margin:.15rem 0; }}
</style>
</head>
<body>
<div class="wrap">
  <h1>110 Skill Invoke Transcript</h1>
  <p class="sub">
    Org: <strong>{H.escape(str(d.get("org")))}</strong> ·
    Agent: <code>{H.escape(str(d.get("agentDeveloperName")))}</code><br/>
    Method: <strong>invokeAgentSkill</strong> (JSON parameters → Apex). Not free-text chat.<br/>
    Mix: handler_ok={counts.get("handler_ok", 0)},
    handler_error={counts.get("handler_error", 0)},
    api_fail={counts.get("api_fail", 0)}.
  </p>
  <div class="filters">
    <button type="button" data-f="all" class="active">All {len(rows)}</button>
    <button type="button" data-f="handler_ok">handler_ok {counts.get("handler_ok", 0)}</button>
    <button type="button" data-f="handler_error">handler_error {counts.get("handler_error", 0)}</button>
    <button type="button" data-f="api_fail">api_fail {counts.get("api_fail", 0)}</button>
  </div>
  <details>
    <summary>Jump to skill</summary>
    <ol class="toc">{toc}</ol>
  </details>
  {"".join(cards)}
</div>
<script>
document.querySelectorAll(".filters button").forEach((btn) => {{
  btn.addEventListener("click", () => {{
    document.querySelectorAll(".filters button").forEach((b) => b.classList.remove("active"));
    btn.classList.add("active");
    const f = btn.dataset.f;
    document.querySelectorAll(".card").forEach((c) => {{
      if (f === "all") c.classList.remove("hidden");
      else c.classList.toggle("hidden", c.dataset.cat !== f);
    }});
  }});
}});
</script>
</body>
</html>
"""

(ROOT / "SKILL_INVOKE_TRANSCRIPT.html").write_text(html_doc, encoding="utf-8")
print("Wrote", ROOT / "SKILL_INVOKE_TRANSCRIPT.html")
print("Wrote", ROOT / "SKILL_INVOKE_TRANSCRIPT.md")
print("Total rows", len(rows))
