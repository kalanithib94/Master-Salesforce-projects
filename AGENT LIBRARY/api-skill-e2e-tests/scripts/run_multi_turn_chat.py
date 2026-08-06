# -*- coding: utf-8 -*-
"""
Single multi-turn chat session against GPTfy agentic API.
Reuses userContextId across turns so the agent treats it as one conversation.
"""
from __future__ import annotations

import json
import re
import sys
import time
import urllib.parse
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from sf_rest import load_config, rest_json, session  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
OUT = Path(__file__).resolve().parent / "results"
OUT.mkdir(exist_ok=True)
LIBRARY = ROOT.parent
PROMPT_FILE = LIBRARY / "Deliverables" / "docs" / "GenericCRMAssistant_SystemPrompt.txt"
MULTI_TURN_BLOCK = """
═══════════════════════════════════════════════════
RULE SESSION — MULTI-TURN CHAT (userContextId)
═══════════════════════════════════════════════════
The runtime may keep one chat session across many user messages. You will receive the same conversation / userContextId on each turn.

Session memory rules:
1. Treat every message in this chat as ONE ongoing conversation. Do NOT reset intent or re-ask for context you already learned.
2. After a successful skill that identifies a record (Account/Contact/Lead/Opportunity/Case), remember Name + CaseNumber/Stage as human labels AND the Salesforce Id for later skills. Prefer names/CaseNumber in user-facing text; pass Id or natural keys to skills as the skill schema requires.
3. Pronouns and short follow-ups ("that account", "add a case", "the same opp", "log a call on it") refer to the last confirmed records in this conversation. Resolve them without searching again unless the match is ambiguous.
4. When fetching details, related lists, opportunities, or cases, default to the account (or parent) already established in this chat.
5. Natural keys preferred for users: Account/Contact/Opportunity/Campaign by Name; Case by CaseNumber or Subject. Salesforce Ids are optional inputs when already known.
6. Multi-step work in one session is expected: e.g. fetch account → list related → create opportunity → create case → log activity. Reuse parents; do not re-discover them.
7. Read-only skills (fuzzy_search_*, fetch_*) run as soon as the user asks. Mutating skills still follow Rule 3 confirmation — once the user confirms, execute immediately and continue the thread.
8. If confirmation was already given for a specific create/update in this chat ("yes", "confirm", "go ahead", "do it"), treat that as approval for THAT pending action only, then execute and confirm with the skill result.
""".strip()


def upsert_system_prompt_block(text: str) -> str:
    marker = "RULE SESSION — MULTI-TURN CHAT"
    if marker in text:
        # replace existing block between its header and next RULE or end separator
        pattern = re.compile(
            r"═+\s*\nRULE SESSION — MULTI-TURN CHAT \(userContextId\)\s*\n═+.*?(?=\n═+\s*\nRULE |\Z)",
            re.S,
        )
        if pattern.search(text):
            return pattern.sub(MULTI_TURN_BLOCK + "\n\n", text).rstrip() + "\n"
        return text
    # Insert after RULE PRECEDENCE section (before RULE 1) if present, else append
    anchor = "═══════════════════════════════════════════════════\nRULE 1 — SKILLS ARE THE SOURCE OF TRUTH"
    if anchor in text:
        return text.replace(anchor, MULTI_TURN_BLOCK + "\n\n" + anchor, 1)
    return text.rstrip() + "\n\n" + MULTI_TURN_BLOCK + "\n"


def find_system_prompt_field(token: str, base: str) -> str | None:
    code, body = rest_json(token, base, "GET", "/services/data/v67.0/sobjects/ccai__AI_Agent__c/describe")
    if code != 200 or not isinstance(body, dict):
        return None
    candidates = []
    for f in body.get("fields") or []:
        n = f.get("name") or ""
        low = n.lower()
        if any(k in low for k in ("system", "prompt", "instruction", "persona")):
            if f.get("updateable") and f.get("type") in ("textarea", "string"):
                candidates.append(n)
    # prefer exact-ish
    for prefer in (
        "ccai__System_Prompt__c",
        "ccai__Agent_System_Prompt__c",
        "ccai__Prompt__c",
        "ccai__Instructions__c",
    ):
        if prefer in candidates:
            return prefer
    return candidates[0] if candidates else None


def patch_agent_system_prompt(token: str, base: str, agent_name: str, prompt_text: str) -> dict:
    field = find_system_prompt_field(token, base)
    if not field:
        return {"ok": False, "error": "No updateable system-prompt field on AI_Agent"}
    soql = (
        "SELECT Id, Name FROM ccai__AI_Agent__c WHERE Name = '"
        + agent_name.replace("'", "\\'")
        + "' LIMIT 1"
    )
    code, body = rest_json(
        token, base, "GET", "/services/data/v67.0/query?q=" + urllib.parse.quote(soql)
    )
    rows = (body or {}).get("records") or []
    if not rows:
        return {"ok": False, "error": "Agent not found", "field": field}
    aid = rows[0]["Id"]
    # long text may truncate via REST; send full
    code2, body2 = rest_json(
        token,
        base,
        "PATCH",
        f"/services/data/v67.0/sobjects/ccai__AI_Agent__c/{aid}",
        {field: prompt_text},
        timeout=180,
    )
    # PATCH often returns 204
    ok = code2 in (200, 204) or (isinstance(body2, dict) and not body2.get("errorCode"))
    return {
        "ok": ok,
        "http": code2,
        "field": field,
        "agentId": aid,
        "chars": len(prompt_text),
        "body": body2,
    }


def chat_turn(
    token: str,
    base: str,
    agent: str,
    user_message: str,
    user_context_id: str | None,
    *,
    record_id: str | None = None,
    timeout: int = 300,
) -> dict:
    payload: dict = {
        "agentName": agent,
        "userMessage": user_message,
        "userAgent": "E2E-MultiTurn-Chat",
    }
    if user_context_id:
        payload["userContextId"] = user_context_id
    if record_id:
        payload["recordId"] = record_id
    http, body = rest_json(
        token,
        base,
        "POST",
        "/services/apexrest/ccai/v1/agentic/",
        payload,
        timeout=timeout,
    )
    return {
        "http": http,
        "request": payload,
        "response": body,
    }


def turn_ok(body: dict | None) -> tuple[bool, str]:
    if not isinstance(body, dict):
        return False, "non-dict response"
    msg = body.get("message")
    if msg:
        return False, str(msg)[:400]
    # success: message empty; responseBody present
    rb = body.get("responseBody")
    if rb is None and body.get("status") == "Error":
        return False, str(body)[:400]
    return True, ""


def main() -> int:
    cfg = load_config()
    org = cfg.get("targetOrg", "Master Dev")
    agent = cfg.get("agentDeveloperName") or cfg.get("agentName")
    agent_label = cfg.get("agentName") or "GPTfy Master Agent"
    seed_path = OUT / "e2e_seed_ids.json"
    seed = json.loads(seed_path.read_text(encoding="utf-8")) if seed_path.exists() else {}
    acc_name = seed.get("SearchAccount") or "E2E Skill Test Account"
    contact = seed.get("SearchContact") or "Rose E2EContact"
    case_num = seed.get("CaseNumber") or seed.get("OpenCaseNumber") or ""
    account_id = seed.get("AccountId")

    print("=== 1) Update system prompt (file + org agent) ===")
    raw = PROMPT_FILE.read_text(encoding="utf-8") if PROMPT_FILE.exists() else ""
    # bump version line
    raw = re.sub(
        r"# Version: [^\n]+",
        "# Version: 1.5.0 | Owner: Cloud Compliance | Last updated: 2026-08-06",
        raw,
        count=1,
    )
    updated = upsert_system_prompt_block(raw)
    PROMPT_FILE.write_text(updated, encoding="utf-8")
    print("Wrote", PROMPT_FILE, "chars", len(updated))

    token, base = session(org)
    patch = patch_agent_system_prompt(token, base, agent_label, updated)
    print("Org patch:", json.dumps({k: v for k, v in patch.items() if k != "body"}, indent=2))
    if patch.get("body"):
        print("Body snippet:", str(patch["body"])[:400])

    # Prefer Developer Name for agentic API
    print("Agent:", agent, "Org:", org)
    print("Seed account:", acc_name, account_id)

    turns_plan = [
        {
            "id": "T1_fetch_account",
            "message": (
                f"Look up the account named \"{acc_name}\" and give me a concise summary "
                f"(type, phone, website, owner if available)."
            ),
            "recordId": None,
        },
        {
            "id": "T2_related",
            "message": (
                "Using that same account from this chat, list its related contacts, "
                "opportunities, and cases. Highlight any open opportunities or open cases."
            ),
            "recordId": None,
        },
        {
            "id": "T3_create_opp_confirm",
            "message": (
                f"On the same account \"{acc_name}\", create a new opportunity named "
                f"\"E2E Chat Session Opp\", Stage Prospecting, Close Date 2026-09-30, "
                f"Amount 15000. Prepare the confirmation."
            ),
            "recordId": None,
        },
        {
            "id": "T4_confirm_opp",
            "message": "Yes, confirm and create that opportunity now.",
            "recordId": None,
        },
        {
            "id": "T5_create_case_confirm",
            "message": (
                f"Also create a Case on the same account for contact \"{contact}\" with subject "
                f"\"E2E Chat Session Case\", Status New, Origin Web, Priority Medium. "
                f"Show confirmation before creating."
            ),
            "recordId": None,
        },
        {
            "id": "T6_confirm_case",
            "message": "Yes, create the case.",
            "recordId": None,
        },
        {
            "id": "T7_fetch_case_or_context",
            "message": (
                "Fetch details for the case you just created in this chat "
                "(use CaseNumber if you have it). Summarize status and subject."
            ),
            "recordId": None,
        },
        {
            "id": "T8_log_activity_confirm",
            "message": (
                f"Log a completed activity on account \"{acc_name}\" with subject "
                f"\"E2E chat session follow-up call\". Confirm first if required."
            ),
            "recordId": None,
        },
        {
            "id": "T9_confirm_activity",
            "message": "Yes, log that activity.",
            "recordId": None,
        },
        {
            "id": "T10_session_summary",
            "message": (
                "Summarize what we accomplished in this conversation: which account we used, "
                "what opportunity/case/activity were created or viewed, and any remaining open items. "
                "Do not invent records — only what skills confirmed."
            ),
            "recordId": None,
        },
    ]
    # if we have a known open case number, insert a mid-turn probe
    if case_num:
        turns_plan.insert(
            7,
            {
                "id": "T7b_existing_case",
                "message": f"Also fetch case number {case_num} details (subject, status).",
                "recordId": None,
            },
        )

    user_context_id: str | None = None
    results = []
    print("=== 2) Multi-turn agentic chat (same userContextId) ===")
    for i, t in enumerate(turns_plan, 1):
        print(f"\n--- Turn {i}/{len(turns_plan)} {t['id']} ---")
        print("USER:", t["message"][:200])
        print("userContextId sent:", user_context_id or "(none — new session)")
        t0 = time.time()
        # Retry once on transport/empty
        rid = t.get("recordId")
        if rid is None and i == 1 and account_id:
            rid = account_id
        res = chat_turn(
            token,
            base,
            agent,
            t["message"],
            user_context_id,
            record_id=rid,
        )
        elapsed = round(time.time() - t0, 2)
        body = res.get("response") if isinstance(res.get("response"), dict) else {}
        ok, err = turn_ok(body)
        new_ctx = body.get("userContextId") if isinstance(body, dict) else None
        if new_ctx:
            # Prefer continuous session: keep first non-null if stable, else newest per guide
            if user_context_id is None:
                user_context_id = new_ctx
            elif new_ctx != user_context_id:
                # Guide: can change mid-conversation — adopt newest so skills keep working
                print(f"  note: userContextId changed {user_context_id} → {new_ctx}")
                user_context_id = new_ctx

        rb = ""
        if isinstance(body, dict):
            rb = body.get("responseBody") or ""
            if isinstance(rb, str):
                rb_plain = re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", rb)).strip()
            else:
                rb_plain = str(rb)[:800]
        else:
            rb_plain = str(body)[:800]

        print(f"  http={res['http']} ok={ok} elapsed={elapsed}s")
        print(f"  userContextId resp={new_ctx}")
        print(f"  response: {rb_plain[:500]}")
        if err:
            print(f"  error: {err}")

        # continuation loop if agent needs another hop
        cont_hops = 0
        while (
            isinstance(body, dict)
            and body.get("requiresContinuation")
            and cont_hops < 3
            and body.get("pendingFunctionOutputs")
        ):
            cont_hops += 1
            print(f"  continuation hop {cont_hops}...")
            cont_payload = {
                "agentName": agent,
                "userMessage": t["message"],
                "userContextId": user_context_id,
                "isContinuation": True,
                "pendingFunctionOutputs": body.get("pendingFunctionOutputs"),
                "userAgent": "E2E-MultiTurn-Chat",
            }
            http2, body2 = rest_json(
                token,
                base,
                "POST",
                "/services/apexrest/ccai/v1/agentic/",
                cont_payload,
                timeout=300,
            )
            body = body2 if isinstance(body2, dict) else {}
            ok, err = turn_ok(body)
            if body.get("userContextId"):
                user_context_id = body["userContextId"]
            rb_plain = re.sub(
                r"\s+",
                " ",
                re.sub(r"<[^>]+>", " ", str(body.get("responseBody") or "")),
            ).strip()
            print(f"  cont http={http2} ok={ok}: {rb_plain[:400]}")

        results.append(
            {
                "turn": i,
                "id": t["id"],
                "userMessage": t["message"],
                "userContextIdSent": res["request"].get("userContextId"),
                "userContextIdReturned": new_ctx,
                "http": res["http"],
                "ok": ok,
                "error": err,
                "elapsedSec": elapsed,
                "requiresContinuation": (body or {}).get("requiresContinuation")
                if isinstance(body, dict)
                else None,
                "responseBodyPlain": rb_plain[:3000],
                "raw": body,
            }
        )
        time.sleep(0.8)

    passed = sum(1 for r in results if r["ok"])
    report = {
        "org": org,
        "agentDeveloperName": agent,
        "agentName": agent_label,
        "systemPromptPatch": {k: v for k, v in patch.items() if k != "body"},
        "finalUserContextId": user_context_id,
        "turnCount": len(results),
        "turnsOk": passed,
        "turnsFailed": len(results) - passed,
        "account": acc_name,
        "utc": datetime.now(timezone.utc).isoformat(),
        "turns": results,
    }
    out_json = OUT / "multi_turn_chat_session.json"
    out_json.write_text(json.dumps(report, indent=2, default=str), encoding="utf-8")

    # Simple HTML transcript
    cards = []
    for r in results:
        cls = "ok" if r["ok"] else "bad"
        cards.append(
            f'<article class="{cls}"><h2>#{r["turn"]} {r["id"]}</h2>'
            f'<p><b>userContextId sent:</b> {r.get("userContextIdSent") or "(none)"} '
            f'→ <b>returned:</b> {r.get("userContextIdReturned")}</p>'
            f'<pre class="u">USER\n{r["userMessage"]}</pre>'
            f'<pre class="a">AGENT\n{r.get("responseBodyPlain") or r.get("error")}</pre></article>'
        )
    html = f"""<!DOCTYPE html>
<html><head><meta charset="utf-8"/><title>Multi-turn agent chat</title>
<style>
body{{font-family:Segoe UI,sans-serif;background:#0f1419;color:#e7eef8;padding:1.2rem}}
article{{background:#1a2332;border:1px solid #2e3f56;border-radius:12px;padding:1rem;margin:.8rem 0;border-left:4px solid #6b7c93}}
article.ok{{border-left-color:#3dd68c}} article.bad{{border-left-color:#f07178}}
pre{{white-space:pre-wrap;background:#0d1218;padding:.7rem;border-radius:8px;font-size:.85rem}}
.u{{color:#b8e0ff}}.a{{color:#d4f0d4}}
</style></head><body>
<h1>Multi-turn chat session (same userContextId)</h1>
<p>Org {org} · Agent {agent} · Context <code>{user_context_id}</code></p>
<p>Turns OK: <b>{passed}/{len(results)}</b> · Account: {acc_name}</p>
{''.join(cards)}
</body></html>"""
    out_html = LIBRARY / "Reports" / "MULTI_TURN_CHAT_SESSION.html"
    out_html.parent.mkdir(parents=True, exist_ok=True)
    out_html.write_text(html, encoding="utf-8")
    print("\n=== DONE ===")
    print("OK turns:", passed, "/", len(results))
    print("userContextId final:", user_context_id)
    print("JSON:", out_json)
    print("HTML:", out_html)
    return 0 if passed == len(results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
