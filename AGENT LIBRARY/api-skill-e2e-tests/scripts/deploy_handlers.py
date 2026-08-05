# -*- coding: utf-8 -*-
"""Deploy all AgenticSkills Apex classes from Deliverables/force-app."""
from __future__ import annotations

import json
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PKG = ROOT / "package"
DEFAULT_FORCE = ROOT.parent / "Deliverables" / "force-app"


def run(cmd: list[str]) -> int:
    print("+", " ".join(cmd))
    p = subprocess.run(cmd, shell=True)
    return p.returncode


def main() -> int:
    org = sys.argv[1] if len(sys.argv) > 1 else "Master Dev"
    force = DEFAULT_FORCE
    if not force.exists():
        print("Missing force-app:", force)
        return 1

    # Stage under package/force-app so deploy uses local package.xml
    staged = PKG / "force-app" / "main" / "default" / "classes"
    if staged.exists():
        shutil.rmtree(staged)
    staged.mkdir(parents=True)
    src = force / "main" / "default" / "classes"
    for f in src.iterdir():
        if f.suffix in (".cls", ".xml") and (
            "Agentic" in f.name or f.name.startswith("GenericAgentic")
        ):
            shutil.copy2(f, staged / f.name)
    print(f"Staged {len(list(staged.iterdir()))} class files")

    # source-dir only (--manifest cannot pair with --source-dir)
    cmd = (
        f'sf project deploy start --source-dir "{PKG / "force-app"}" '
        f'--target-org "{org}" --wait 45'
    )
    print("+", cmd)
    return subprocess.run(cmd, shell=True).returncode


if __name__ == "__main__":
    raise SystemExit(main())
