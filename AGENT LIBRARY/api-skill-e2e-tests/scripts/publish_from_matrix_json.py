# -*- coding: utf-8 -*-
import json
import sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_main_report import publish_main_and_archive  # noqa: E402

OUT = Path(__file__).resolve().parent / "results"
data = json.loads((OUT / "matrix_report_seeded.json").read_text(encoding="utf-8"))
rows = []
for r in data["results"]:
    ad = r.get("apexData")
    if isinstance(ad, dict):
        resp = ad.get("message") or ad.get("error") or json.dumps(ad, ensure_ascii=False, indent=2)
    else:
        resp = str(ad or r.get("errorSnippet") or "")
    rows.append(
        {
            "category": r.get("category") or "unknown",
            "skill": r.get("skill") or "",
            "request": json.dumps(r.get("request") or {}, indent=2, ensure_ascii=False),
            "response": resp if isinstance(resp, str) else json.dumps(resp),
            "errorSnippet": r.get("errorSnippet"),
        }
    )
counts = Counter(r["category"] for r in rows)
print("COUNTS", dict(counts))
boot = data.get("bootstrapSummary") or {}
need = (
    "FINAL CLEAN retest — wipe prior E2E data; skill-sequenced create→fetch bootstrap; "
    "only required fixtures; natural-key payloads; strict Apex business pass. "
    f"Bootstrap {boot}. Counts: {json.dumps(dict(counts))}"
)
main_p, arch_p = publish_main_and_archive(
    rows,
    need=need,
    org=data.get("org") or "Master Dev",
    agent=str(data.get("agentDeveloperName") or ""),
    slug="final-clean-skill-matrix",
)
print("MAIN", main_p)
print("ARCHIVE", arch_p)
for cat in ("fail_business", "fail_data", "fail_api"):
    sk = [r["skill"] for r in rows if r["category"] == cat]
    if sk:
        print(cat + ":", ", ".join(sk))
print("pass", counts.get("pass", 0), "/", sum(counts.values()))
