# -*- coding: utf-8 -*-
"""Deploy each AgenticSkills Apex class individually; record compile success/fail.

Does not modify product Apex — for pre-fix inventory only.
"""
from __future__ import annotations

import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_FORCE = ROOT.parent / "Deliverables" / "force-app"
OUT = Path(__file__).resolve().parent / "results"
OUT.mkdir(exist_ok=True)


def main() -> int:
    org = sys.argv[1] if len(sys.argv) > 1 else "Master Dev"
    src = DEFAULT_FORCE / "main" / "default" / "classes"
    classes = sorted(
        f.stem
        for f in src.glob("*.cls")
        if "Agentic" in f.name or f.name.startswith("GenericAgentic")
    )
    # Deploy base first
    order = []
    if "AgenticSkillsBase" in classes:
        order.append("AgenticSkillsBase")
    if "AgenticSkillsBaseTest" in classes:
        order.append("AgenticSkillsBaseTest")
    for c in classes:
        if c not in order:
            order.append(c)

    results = []
    ok = fail = 0
    for name in order:
        cls = src / f"{name}.cls"
        meta = src / f"{name}.cls-meta.xml"
        if not cls.exists():
            continue
        with tempfile.TemporaryDirectory() as td:
            tdp = Path(td)
            (tdp / "classes").mkdir()
            shutil.copy2(cls, tdp / "classes" / cls.name)
            if meta.exists():
                shutil.copy2(meta, tdp / "classes" / meta.name)
            cmd = (
                f'sf project deploy start --source-dir "{tdp}" '
                f'--target-org "{org}" --wait 15 --json'
            )
            print(f"\n=== {name} ===")
            p = subprocess.run(
                cmd,
                shell=True,
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="replace",
            )
            payload = {}
            try:
                # CLI may wrap progress; take last JSON object-looking block
                out = (p.stdout or "") + "\n" + (p.stderr or "")
                # Prefer pure stdout JSON
                try:
                    payload = json.loads(p.stdout or "{}")
                except json.JSONDecodeError:
                    m = re.findall(r"\{[\s\S]*\}", out)
                    if m:
                        payload = json.loads(m[-1])
            except Exception as e:
                payload = {"parseError": str(e), "stdout": (p.stdout or "")[:2000]}

            status = payload.get("status")
            result = payload.get("result") or {}
            success = status == 0 or result.get("success") is True
            problems = []
            for d in result.get("details", {}).get("componentFailures") or []:
                problems.append(
                    {
                        "name": d.get("fullName") or d.get("fileName"),
                        "problem": d.get("problem"),
                        "line": d.get("lineNumber"),
                    }
                )
            # Also top-level message
            if not success and not problems:
                problems.append(
                    {
                        "name": name,
                        "problem": payload.get("message")
                        or (p.stderr or p.stdout or "")[:500],
                    }
                )

            entry = {
                "class": name,
                "success": bool(success),
                "rc": p.returncode,
                "problems": problems,
            }
            results.append(entry)
            if success:
                ok += 1
                print("OK")
            else:
                fail += 1
                print("FAIL", problems[:3])

    summary = {"org": org, "ok": ok, "fail": fail, "results": results}
    path = OUT / "deploy_individual.json"
    path.write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(f"\nSummary ok={ok} fail={fail} → {path}")
    return 0 if fail == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
