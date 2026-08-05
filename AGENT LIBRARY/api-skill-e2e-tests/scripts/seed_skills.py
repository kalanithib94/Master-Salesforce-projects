# -*- coding: utf-8 -*-
"""
Bulk-seed skills from kb-catalog package seeds into the target org and link to agent.

Requires config.local.json with dataMappingId + aiModelId (from inventory_org.py).
Processes package seed.apex files; patches DATA_MAPPING / AI_MODEL / AGENT_NAME;
runs via `sf apex run`.
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(Path(__file__).resolve().parent))
from sf_rest import load_config  # noqa: E402

DEFAULT_PACKAGES = ROOT.parent / "Deliverables" / "kb-catalog" / "packages"
OUT = Path(__file__).resolve().parent / "results"
OUT.mkdir(exist_ok=True)


def run_apex(org: str, apex_path: Path) -> tuple[int, str]:
    cmd = f'sf apex run --file "{apex_path}" --target-org "{org}"'
    print("+", cmd)
    p = subprocess.run(
        cmd,
        shell=True,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    out = (p.stdout or "") + (p.stderr or "")
    # surface final lines
    lines = [ln for ln in out.splitlines() if ln.strip()]
    for ln in lines[-12:]:
        print(ln)
    return p.returncode, out[-4000:]


def patch_seed(text: str, agent: str, mapping: str, model: str) -> str:
    text = re.sub(
        r"final String AGENT_NAME = '[^']*';",
        f"final String AGENT_NAME = '{agent}';",
        text,
        count=1,
    )
    text = re.sub(
        r"final String DATA_MAPPING = '[^']*';",
        f"final String DATA_MAPPING = '{mapping}';",
        text,
        count=1,
    )
    text = re.sub(
        r"final String AI_MODEL = '[^']*';",
        f"final String AI_MODEL = '{model}';",
        text,
        count=1,
    )
    return text


def main() -> int:
    cfg = load_config()
    org = sys.argv[1] if len(sys.argv) > 1 else cfg.get("targetOrg", "Master Dev")
    only = sys.argv[2] if len(sys.argv) > 2 else None  # optional single skill folder

    mapping = cfg.get("dataMappingId") or ""
    model = cfg.get("aiModelId") or ""
    agent = cfg.get("agentName") or "GPTfy Agent"

    if not mapping or not model or mapping.startswith("REPLACE") or model.startswith("REPLACE"):
        print("Set dataMappingId and aiModelId in config.local.json (from inventory_org.py).")
        print("Example: dataMapping a08…, aiModel a04… Agentic Model")
        return 1

    packages = Path(cfg.get("packagesPath") or DEFAULT_PACKAGES)
    if not packages.is_absolute():
        packages = (ROOT / packages).resolve()
    if not packages.exists():
        print("packages path missing:", packages)
        return 1

    folders = sorted([p for p in packages.iterdir() if p.is_dir() and (p / "seed.apex").exists()])
    if only:
        folders = [p for p in folders if p.name == only]
    print(f"Seeding {len(folders)} skills -> org={org} agent={agent!r}")

    ok, fail = 0, 0
    log = []
    for folder in folders:
        seed = (folder / "seed.apex").read_text(encoding="utf-8")
        patched = patch_seed(seed, agent, mapping, model)
        with tempfile.NamedTemporaryFile(
            "w", suffix=".apex", delete=False, encoding="utf-8"
        ) as tf:
            tf.write(patched)
            tmp = Path(tf.name)
        print(f"\n--- {folder.name} ---")
        rc, tail = run_apex(org, tmp)
        tmp.unlink(missing_ok=True)
        # Detect apex execution errors even when CLI exit is 0
        failed_exec = rc != 0 or re.search(
            r"Error:|EXCEPTION|System\.\w+Exception", tail or "", re.I
        )
        entry = {"skill": folder.name, "rc": rc, "ok": not failed_exec, "tail": (tail or "")[-800:]}
        log.append(entry)
        if not failed_exec:
            ok += 1
        else:
            fail += 1
            print("FAILED", folder.name)

    (OUT / "seed_log.json").write_text(json.dumps(log, indent=2), encoding="utf-8")
    print(f"\nDone ok={ok} fail={fail} -> {OUT / 'seed_log.json'}")
    print("Re-run inventory_org.py and list_skills_api.py to verify agent links.")
    return 0 if fail == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
