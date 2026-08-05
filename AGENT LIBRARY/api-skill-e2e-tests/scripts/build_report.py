# -*- coding: utf-8 -*-
"""Build E2E_TEST_REPORT.md from results artifacts."""
from __future__ import annotations

import json
import re
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

root = Path(__file__).resolve().parent / "results"
d = json.loads((root / "matrix_report.json").read_text(encoding="utf-8"))
seed = json.loads((root / "seed_log.json").read_text(encoding="utf-8"))
dep = json.loads((root / "deploy_summary.json").read_text(encoding="utf-8"))
inv = json.loads((root / "org_inventory.json").read_text(encoding="utf-8"))

results = d["results"]
ok = sorted([e["skill"] for e in results if e["category"] == "handler_ok"])
api = [e for e in results if e["category"] == "api_fail"]
herr = [e for e in results if e["category"] == "handler_error"]


def bucket(e: dict) -> str:
    m = (e.get("errorSnippet") or "").lower()
    if "agentic function class not found" in m:
        return "A. Missing Apex class (not deployed)"
    if "unsupported skill" in m:
        return "B. Unsupported skill routing in handler"
    if "not available" in m or "not installed" in m or "cpq is not" in m:
        return "C. Cloud/feature not in org"
    if "missing required" in m or "missing parameter" in m or "is required" in m:
        return "D. Missing param / fixture / schema mismatch"
    if "no " in m and ("found" in m or "matching" in m):
        return "E. No matching data (often expected)"
    if "invalid" in m:
        return "F. Invalid Id / input"
    if "could not" in m:
        return "G. Other handler business error"
    return "H. Other / unclear"


byb: dict[str, list] = defaultdict(list)
for e in api + herr:
    byb[bucket(e)].append(e)

seed_fail = [x["skill"] for x in seed if not x.get("ok")]
seed_ok = sum(1 for x in seed if x.get("ok"))

# which of 111 prompts is not on agent
prompt_names = {p.get("Name") for p in inv.get("prompts") or []}
linked = set()
for a in inv.get("agents") or []:
    for s in a.get("skills") or []:
        linked.add(s.get("name"))
unlinked = sorted(prompt_names - linked)

lines: list[str] = []
lines.append("# Master Dev E2E Report (pre-fix)")
lines.append("")
lines.append(f"Generated: {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M UTC')}")
lines.append("")
lines.append("**Org:** Master Dev (`masterdev@gptfy.ai`)")
lines.append("**Agent:** GPTfy Master Agent")
lines.append(f"**Agent DeveloperName (API):** `{d.get('agentDeveloperName')}`")
lines.append("")
lines.append(
    "Scope: deploy Deliverables handlers + seed 111 package skills + "
    "`invokeAgentSkill` once each for every skill linked to the agent. "
    "**No product code fixes applied.**"
)
lines.append("")
lines.append("---")
lines.append("")
lines.append("## Executive summary")
lines.append("")
lines.append("| Stage | Result |")
lines.append("|-------|--------|")
lines.append("| Full Apex deploy (all handlers) | **FAILED** (68 component failures, rolled back) |")
lines.append("| Partial Apex deploy (excluded 5 broken handlers) | **SUCCESS** |")
lines.append(f"| Skill seed (111 packages) | **{seed_ok} OK / {len(seed_fail)} FAIL** |")
lines.append(f"| Prompts in org | **{len(inv.get('prompts') or [])}** |")
lines.append(f"| Skills linked to agent | **{len(linked)}** |")
lines.append(f"| Unlinked prompts | **{', '.join(f'`{x}`' for x in unlinked) or 'none'}** |")
lines.append(f"| `invokeAgentSkill` matrix | **{len(results)} invoked** |")
lines.append(f"| Handler OK | **{len(ok)}** |")
lines.append(f"| Handler error | **{len(herr)}** |")
lines.append(f"| API fail | **{len(api)}** |")
lines.append("")
lines.append("### Pass bar")
lines.append("")
lines.append("- **handler_ok** — API Success + Apex success/true")
lines.append("- **handler_error** — API Success but Apex error / no match / missing param")
lines.append("- **api_fail** — REST layer non-Success (e.g. class not found)")
lines.append("")
lines.append(
    "Many handler_errors are **fixture/schema/org data**, not definite code bugs. "
    "api_fail for Opportunity/Quote/Partner is a **deploy gate**."
)
lines.append("")
lines.append("---")
lines.append("")
lines.append("## 1. Deploy")
lines.append("")
lines.append("### 1.1 Full package")
lines.append("")
lines.append("- Deploy Id: `0AfQH00000P9St80AF`")
lines.append("- Status: Failed — all-or-nothing; full set **not** applied")
lines.append("- Root compile failures:")
lines.append("")
for r in dep["fullDeploy"]["rootHandlerCompileErrors"]:
    lines.append(f"- **`{r['class']}`**: {r['problem']}")
lines.append("")
lines.append("### 1.2 Partial deploy (used for testing)")
lines.append("")
lines.append("Excluded:")
for h in dep["partialDeploy"]["excludedHandlers"]:
    lines.append(f"- `{h}`")
lines.append("")
lines.append("Deployed / present for invoke:")
for h in dep["partialDeploy"]["deployedHandlers"]:
    lines.append(f"- `{h}`")
lines.append("")
lines.append(f"Inventory Apex *Agentic* classes: **{len(inv.get('apex') or [])}**")
lines.append("")
lines.append("---")
lines.append("")
lines.append("## 2. Seed skills")
lines.append("")
lines.append(f"- Processed: **111**")
lines.append(f"- Succeeded: **{seed_ok}**")
lines.append(f"- Failed: **{len(seed_fail)}**")
lines.append("- Agent Name: `GPTfy Master Agent`")
lines.append("- Mapping / model: `a08QH00000S2zVZYAZ` / `a04QH000007PsM9YAK`")
lines.append("")
lines.append("### Failed seeds (legacy 8 prompts)")
lines.append("")
lines.append(
    "All failed with: `FIELD_CUSTOM_VALIDATION_EXCEPTION: "
    "Data Extraction mapping cannot be changed on Prompt once it has been created.`"
)
lines.append("")
for s in seed_fail:
    lines.append(f"- `{s}`")
lines.append("")
lines.append(
    "**Impact:** those prompts still use **old** Prompt Command schemas "
    "(e.g. `search_term`, `contact_id`). The other **103** skills seeded with current schema."
)
lines.append("")
lines.append("---")
lines.append("")
lines.append("## 3. Invoke matrix")
lines.append("")
lines.append(f"Sample Ids: stored in `sample_ids.json` / matrix `sampleIds`.")
lines.append("")
lines.append(f"### 3.1 handler_ok ({len(ok)})")
lines.append("")
for s in ok:
    lines.append(f"- `{s}`")
lines.append("")
lines.append("### 3.2 Failures by bucket")
lines.append("")

for k in sorted(byb.keys()):
    items = sorted(byb[k], key=lambda x: x["skill"])
    lines.append(f"#### {k} ({len(items)})")
    lines.append("")
    lines.append("| Skill | Error (snip) |")
    lines.append("|-------|----------------|")
    for e in items:
        err = e.get("errorSnippet") or ""
        err = re.sub(r"<[^>]+>", " ", err)
        err = re.sub(r"\s+", " ", err).replace("|", "/").strip()[:140]
        lines.append(f"| `{e['skill']}` | {err} |")
    lines.append("")

lines.append("---")
lines.append("")
lines.append("## 4. Interpretation (fix phase later — not applied)")
lines.append("")
lines.append("### Must-fix (code / deploy)")
lines.append("")
lines.append(
    "1. **ActivityAgenticSkillsHandler** — `PicklistEntry.isClosed()` at ~L124 "
    "(blocks Activity + Generic)"
)
lines.append(
    "2. **OpportunityAgenticSkillsHandler** — `OpportunityTeamMember` when team selling disabled"
)
lines.append("3. **QuoteAgenticSkillsHandler** — Quotes not enabled (`Quote` type missing)")
lines.append("4. **PartnerAgenticSkillsHandler** — Invalid bind type vs Id ~L133")
lines.append(
    "5. Asset skills **Unsupported** — "
    "`fetch_asset_details`, `update_asset_fields`, `fuzzy_search_assets`"
)
lines.append("")
lines.append("### Seed / config")
lines.append("")
lines.append(
    "6. Update legacy 8 Prompt Commands **without** changing Data Extraction Mapping"
)
lines.append(f"7. Link unlinked prompts: {', '.join(f'`{x}`' for x in unlinked) or 'n/a'}")
lines.append(
    "8. Treat CPQ / FSL / FinServ / Industry plan / subscription skills as **N/A** on this org "
    "unless packages present"
)
lines.append("")
lines.append("### Harness noise")
lines.append("")
lines.append(
    "9. Bucket D fixtures need per-skill live `promptCommand` values "
    "(esp. nested `fields.LastName`, Contract Id key, empty update maps)"
)
lines.append("10. Bucket E may mix true empty results with wrong Id keys")
lines.append("")
lines.append("### Side effects on Master Dev")
lines.append("")
lines.append(
    "- `create_account` created **E2E Smoke Account DO NOT USE**"
)
lines.append(
    "- Other create/update/log skills may have mutated sample records "
    "(campaign, care task, case comment, account/contact description, activity)"
)
lines.append("")
lines.append("---")
lines.append("")
lines.append("## 5. Artifacts")
lines.append("")
lines.append("`api-skill-e2e-tests/scripts/results/`")
lines.append("")
lines.append("- `deploy_summary.json`, `deploy_full_report.json`")
lines.append("- `seed_log.json`, `seed_console.txt`")
lines.append("- `org_inventory.json`")
lines.append("- `matrix_report.json`, `matrix_report.md`, `matrix_console.txt`")
lines.append("- `sample_ids.json`")
lines.append("- `E2E_TEST_REPORT.md` (this file)")
lines.append("")
lines.append("---")
lines.append("")
lines.append("## 6. Recommended fix order (waiting for your go-ahead)")
lines.append("")
lines.append("1. Fix four compile blockers + redeploy full handler set")
lines.append("2. Fix asset skill routing")
lines.append("3. Seed: refresh Prompt Command only + link missing skill")
lines.append("4. Improve fixtures; re-run matrix; classify N/A vs defect")
lines.append("5. Fix remaining handler business errors one by one")
lines.append("")

out = root / "E2E_TEST_REPORT.md"
out.write_text("\n".join(lines), encoding="utf-8")
print("Wrote", out)
print("handler_ok", len(ok), "handler_error", len(herr), "api_fail", len(api))
print("unlinked", unlinked)
