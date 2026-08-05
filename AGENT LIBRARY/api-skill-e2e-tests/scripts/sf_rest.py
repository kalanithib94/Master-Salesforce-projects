# -*- coding: utf-8 -*-
"""Shared helpers for CLI org auth + REST."""
from __future__ import annotations

import json
import subprocess
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]


def load_config() -> dict:
    local = ROOT / "config.local.json"
    example = ROOT / "config.example.json"
    path = local if local.exists() else example
    return json.loads(path.read_text(encoding="utf-8"))


def sf_org_display(org: str) -> dict:
    p = subprocess.run(
        f'sf org display -o "{org}" --json',
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        shell=True,
    )
    return json.loads(p.stdout or p.stderr or "{}")


def session(org: str) -> tuple[str, str]:
    d = sf_org_display(org)
    if d.get("status") != 0:
        raise RuntimeError(d.get("message") or str(d))
    r = d["result"]
    return r["accessToken"], r["instanceUrl"].rstrip("/")


def rest_json(
    token: str, base: str, method: str, path: str, body: Any = None, timeout: int = 120
) -> tuple[int, Any]:
    data = None if body is None else json.dumps(body).encode("utf-8")
    req = urllib.request.Request(
        base + path,
        data=data,
        headers={
            "Authorization": "Bearer " + token,
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        method=method,
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            raw = resp.read().decode("utf-8", errors="replace")
            return resp.status, json.loads(raw) if raw else None
    except urllib.error.HTTPError as e:
        raw = e.read().decode("utf-8", errors="replace")
        try:
            return e.code, json.loads(raw)
        except Exception:
            return e.code, {"raw": raw[:4000]}
