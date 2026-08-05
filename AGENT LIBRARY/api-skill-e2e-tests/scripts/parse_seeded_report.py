# -*- coding: utf-8 -*-
import re
from collections import Counter
from pathlib import Path

html = Path(__file__).resolve().parents[1].joinpath(
    "SKILL_INVOKE_TRANSCRIPT_SEEDED.html"
).read_text(encoding="utf-8")

parts = re.findall(
    r'data-cat="([^"]+)".*?<code>([^<]+)</code>.*?<span class="pill[^"]*">([^<]+)</span>'
    r".*?Response</h3><pre>(.*?)</pre>",
    html,
    re.S,
)
c = Counter()
rows = []
for cat, skill, pill, resp in parts:
    c[cat] += 1
    if cat != "pass":
        resp_clean = re.sub(
            r"\s+",
            " ",
            resp.replace("&quot;", '"')
            .replace("&lt;", "<")
            .replace("&gt;", ">")
            .replace("&#39;", "'"),
        )[:200]
        rows.append((cat, skill, resp_clean))

print("COUNTS", dict(c))
print("TOTAL", sum(c.values()))
print()
for cat in sorted(set(r[0] for r in rows)):
    print("##", cat)
    for r in rows:
        if r[0] == cat:
            print(f"- {r[1]}: {r[2]}")
    print()
