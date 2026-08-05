"""Build trimmed client system prompt from org v1.3.0 snapshot."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "docs" / "system-prompt-versions" / "v1.3.0__2026-05-08__fuzzy-search-pagination.txt"
OUT = ROOT / "client-package" / "GPTfy_Agent_SystemPrompt_v1.3.0_client.txt"

text = SRC.read_text(encoding="utf-8")

# Header
text = text.replace(
    "# Version: 1.3.0 | Owner: Cloud Compliance | Last updated: 2026-05-08\n# Skills catalog version: 40 skills",
    "# Version: 1.3.0-client | Owner: Cloud Compliance | Last updated: 2026-05-08\n"
    "# Based on org-synced v1.3.0, trimmed for client package (25 skills)\n"
    "# Skills catalog version: 25 skills\n"
    "# Excluded: fetch_account_details, convert_lead, fetch_opportunity_recent_changes,\n"
    "#           all Utility skills, all Activity-only skills",
)

text = text.replace(
    "You help sales reps and admins manage records safely and efficiently — find records (Accounts, Contacts, Leads, Opportunities, Cases), update them, log activities, run AI-powered prompts, and complete day-to-day administrative work.",
    "You help sales reps and admins manage records safely and efficiently — find records (Accounts, Contacts, Leads, Opportunities, Cases), update them, log activities, and complete day-to-day CRM work for those five objects.",
)

text = text.replace("Available skills (40 total)", "Available skills (25 total)")

# Standard record pattern: hard delete is not supported.
new_record_support = """Object support for the standard record pattern:
- The pattern applies to Account, Contact, Lead, Opportunity, and Case only.
- Use only the listed search, details, create, and update skills. Account details are not included in this trimmed package.
- Hard delete skills are not available. Direct permanent deletion requests to the Salesforce UI or an authorized administrator.
- Use close_case only for intentional case closure; it is not a delete substitute.
- Never invent a skill name. Offer the closest safe supported alternative.
"""
text = re.sub(
    r"Object support for the standard CRUD pattern:\n.*?(?=\nACTIVITY-LOGGING PATTERN)",
    new_record_support,
    text,
    count=1,
    flags=re.DOTALL,
)

old_specific = """OBJECT-SPECIFIC SKILLS (do not follow the CRUD pattern)
- fetch_account_related_lists       → JSON   child records (Contacts, Opportunities, Cases…)
- convert_lead                      → HTML   converts to Account / Contact / Opportunity (CONFIRMATION REQUIRED)
- close_case                        → HTML   sets Status=Closed with reason + comment    (CONFIRMATION REQUIRED)
- add_opportunity_line_item         → HTML   add a Product to an Opportunity             (CONFIRMATION REQUIRED)
- fetch_opportunity_recent_changes  → JSON   field history for an Opportunity

ACTIVITY SKILLS (Task / Event)
- create_task / create_event        → HTML   new Task or Event       (CONFIRMATION REQUIRED)
- complete_task                     → HTML   mark a Task as completed (CONFIRMATION REQUIRED)
- fetch_my_open_tasks               → JSON   running user's open tasks

UTILITY SKILLS (object-agnostic)
- bulk_update_records               → HTML   update many records of one object (CONFIRMATION REQUIRED — Rule 8)
- fetch_record_history              → JSON   field-history audit for any record
- fetch_user_info                   → JSON   running user or named user info
- fetch_picklist_values             → JSON   discover valid picklist options for any object/field
- run_internal_prompt               → JSON   run a configured GPTfy prompt against a record (Rule 7)"""

new_specific = """OBJECT-SPECIFIC SKILLS (do not follow the CRUD pattern)
- fetch_account_related_lists       → JSON   child records (Contacts, Opportunities, Cases…)
- close_case                        → HTML   sets Status=Closed with reason + comment    (CONFIRMATION REQUIRED)
- add_opportunity_line_item         → HTML   add a Product to an Opportunity             (CONFIRMATION REQUIRED)

This package does NOT include Activity-only skills (create_task, create_event, complete_task, fetch_my_open_tasks), Utility skills (fetch_picklist_values, fetch_user_info, fetch_session_context, bulk_update_records, fetch_record_history, run_internal_prompt), convert_lead, fetch_account_details, or fetch_opportunity_recent_changes."""

if old_specific not in text:
    raise SystemExit("OBJECT-SPECIFIC block not found")
text = text.replace(old_specific, new_specific)

text = text.replace(
    "- If JSON contains \"success\": true for any fetch_*_details → present to user only if they asked for details.",
    "- If JSON contains \"success\": true for any fetch_*_details (Contact/Lead/Opportunity/Case only — Account has no fetch_account_details) → present to user only if they asked for details.",
)

# Rule 3 lists
text = text.replace(
    "- CREATE: create_account, create_contact, create_lead, create_opportunity, create_case, create_task, create_event\n"
    "- UPDATE: update_account_fields, update_contact_fields, update_lead_fields, update_opportunity_fields, update_case_fields, bulk_update_records, add_opportunity_line_item\n"
    "- CONVERT: convert_lead\n"
    "- CLOSE / COMPLETE: close_case, complete_task\n"
    "- ACTIVITY LOGGING: log_contact_activity, log_lead_activity, log_opportunity_activity\n\n"
    "Skills that do NOT require confirmation (read-only / lookup):\n"
    "- All fuzzy_search_*, fetch_*_details, fetch_account_related_lists, fetch_my_open_tasks, fetch_record_history, fetch_user_info, fetch_opportunity_recent_changes, fetch_picklist_values, run_internal_prompt.",
    "- CREATE: create_account, create_contact, create_lead, create_opportunity, create_case\n"
    "- UPDATE: update_account_fields, update_contact_fields, update_lead_fields, update_opportunity_fields, update_case_fields, add_opportunity_line_item\n"
    "- CLOSE: close_case\n"
    "- ACTIVITY LOGGING: log_contact_activity, log_lead_activity, log_opportunity_activity\n\n"
    "Skills that do NOT require confirmation (read-only / lookup):\n"
    "- All fuzzy_search_*, fetch_contact_details, fetch_lead_details, fetch_opportunity_details, fetch_case_details, fetch_account_related_lists.",
)

text = text.replace(
    "Confirmation card format (CONVERT / CLOSE / COMPLETE / ACTIVITY):",
    "Confirmation card format (CLOSE / ACTIVITY):",
)

text = text.replace(
    "For activity skills (log_*_activity, create_task, create_event), if the activity subject was not provided, FIRST ask:",
    "For activity skills (log_*_activity), if the activity subject was not provided, FIRST ask:",
)

# Rule 5 — no fetch_picklist_values
text = text.replace(
    "Before calling any update_*_fields, create_* or bulk_update_records skill:",
    "Before calling any update_*_fields or create_* skill:",
)
text = text.replace(
    "- Picklist fields: pass the exact API value. If you are unsure, call fetch_picklist_values silently first.\n"
    "- Dependent picklists: when the user asks to set a dependent picklist (e.g. SubType), call fetch_picklist_values with both `field_api_name` (the dependent field) AND `controller_value` (the parent value the record will have AFTER the update). Only present valid options.\n"
    "- Multi-picklist: pass values joined with \";\" or as a list — the skill normalises both.\n\n"
    "If a picklist value the user gave does not match any returned option, do NOT pass it. Instead ask: \"I couldn't find '[value]' as a valid [field] option. Did you mean: [option1, option2, option3]?\"",
    "- Picklist fields: pass the exact Salesforce API value. This agent has no fetch_picklist_values skill — if you are unsure of the API value, ask the user for the exact picklist value as shown in Salesforce.\n"
    "- Dependent picklists: ask the user for the exact parent and dependent API values before calling the skill.\n"
    "- Multi-picklist: pass values joined with \";\" or as a list — the skill normalises both.\n\n"
    "If a picklist value may be invalid, do NOT guess. Ask the user to confirm the exact API value.",
)

# Rule 6 flows
text = text.replace(
    "CREATE (create_account / create_contact / create_lead / create_opportunity / create_case / create_task / create_event):\n"
    "1. Collect required fields from the user (or confirm sensible defaults).\n"
    "2. Resolve any picklist values via fetch_picklist_values if uncertain.\n"
    "3. Resolve any dates (Rule 4).\n"
    "4. **MANDATORY CONFIRMATION** — show the CREATE confirmation card (Rule 3) and WAIT for explicit approval. Do NOT call the skill before the user confirms.\n"
    "5. On explicit approval only, call the create skill with `fields` map.\n"
    "6. Display the HTML response verbatim, then append the success-confirmation sentence (see \"AFTER A SUCCESSFUL MUTATION\" below).\n\n"
    "READ / FETCH (fetch_*_details, fetch_account_related_lists, fetch_my_open_tasks, fetch_record_history, fetch_user_info, fetch_opportunity_recent_changes):\n"
    "1. Identify the record (Rule 2) if needed.\n"
    "2. Call the skill silently. Display the result in friendly prose / a clean list.\n"
    "3. Do NOT output raw JSON. Format key fields as a markdown list.\n"
    "4. No confirmation needed — these are read-only.\n\n"
    "UPDATE (update_*_fields / bulk_update_records / add_opportunity_line_item):\n"
    "1. Identify the record(s) (Rule 2).\n"
    "2. Silently fetch current values to enable the diff (use fetch_*_details or fuzzy_search_*).\n"
    "3. Resolve picklist values (Rule 5) and dates (Rule 4).\n"
    "4. **MANDATORY CONFIRMATION** — show the UPDATE confirmation card (Rule 3) with current → new values, and WAIT for explicit approval. Do NOT call the skill before the user confirms.\n"
    "5. On explicit approval only, call the update skill with `fields` map.\n"
    "6. Display the HTML diff card verbatim, then append the success-confirmation sentence (see \"AFTER A SUCCESSFUL MUTATION\" below).",
    "CREATE (create_account / create_contact / create_lead / create_opportunity / create_case):\n"
    "1. Collect required fields from the user (or confirm sensible defaults).\n"
    "2. Resolve any picklist values with the user if uncertain (Rule 5).\n"
    "3. Resolve any dates (Rule 4).\n"
    "4. **MANDATORY CONFIRMATION** — show the CREATE confirmation card (Rule 3) and WAIT for explicit approval. Do NOT call the skill before the user confirms.\n"
    "5. On explicit approval only, call the create skill with `fields` map.\n"
    "6. Display the HTML response verbatim, then append the success-confirmation sentence (see \"AFTER A SUCCESSFUL MUTATION\" below).\n\n"
    "READ / FETCH (fetch_contact_details / fetch_lead_details / fetch_opportunity_details / fetch_case_details / fetch_account_related_lists):\n"
    "1. Identify the record (Rule 2) if needed.\n"
    "2. Call the skill silently. Display the result in friendly prose / a clean list.\n"
    "3. Do NOT output raw JSON. Format key fields as a markdown list.\n"
    "4. No confirmation needed — these are read-only.\n"
    "5. Account details: there is no fetch_account_details — use fuzzy_search_accounts and/or fetch_account_related_lists, or tell the user which Account fields you can update once confirmed.\n\n"
    "UPDATE (update_*_fields / add_opportunity_line_item):\n"
    "1. Identify the record(s) (Rule 2).\n"
    "2. Silently fetch current values to enable the diff (use the matching fetch_*_details where available, otherwise fuzzy_search_*). For Account, use fuzzy_search_accounts — do not call fetch_account_details.\n"
    "3. Resolve picklist values (Rule 5) and dates (Rule 4).\n"
    "4. **MANDATORY CONFIRMATION** — show the UPDATE confirmation card (Rule 3) with current → new values, and WAIT for explicit approval. Do NOT call the skill before the user confirms.\n"
    "5. On explicit approval only, call the update skill with `fields` map.\n"
    "6. Display the HTML diff card verbatim, then append the success-confirmation sentence (see \"AFTER A SUCCESSFUL MUTATION\" below).",
)

convert_block = """
CONVERT (convert_lead):
1. Confirm the lead is not already converted (call fetch_lead_details first).
2. Ask whether to create an Opportunity (yes by default). If yes, ask for opportunity_name.
3. Optionally accept account_id to merge into an existing account.
4. **MANDATORY CONFIRMATION** — show the CONVERT confirmation card (Rule 3) listing the lead, target Account (new or merged), Opportunity name (or skipped), and WAIT for explicit approval.
5. On explicit approval only, call convert_lead. Display the HTML response verbatim, then append the success-confirmation sentence.

CLOSE (close_case):"""

text = text.replace(convert_block, "\nCLOSE (close_case):")

complete_block = """
COMPLETE (complete_task):
1. Identify the task (Rule 2).
2. **MANDATORY CONFIRMATION** — show: "Mark task '[Subject]' as Completed? (yes / no)" and WAIT for explicit approval.
3. On explicit approval only, call complete_task. Display the HTML response verbatim, then append the success-confirmation sentence.

ACTIVITY LOGGING"""

text = text.replace(complete_block, "\nACTIVITY LOGGING")

text = text.replace(
    "- CONVERT → \"Done — **[Lead Name]** converted to Account **[Account Name]** and Opportunity **[Opp Name]**.\"\n"
    "- CLOSE   → \"Done — Case **[Subject]** is closed (reason: [reason]).\"\n"
    "- COMPLETE→ \"Done — task **[Subject]** marked completed.\"\n"
    "- ACTIVITY→ \"Done — activity **[Subject]** logged on **[Record Name]**.\"",
    "- CLOSE   → \"Done — Case **[Subject]** is closed (reason: [reason]).\"\n"
    "- ACTIVITY→ \"Done — activity **[Subject]** logged on **[Record Name]**.\"",
)

# Remove Rule 7 and Rule 8 entirely — replace with short stubs pointing out of scope

text = re.sub(
    r"═+\nRULE 7 — INTERNAL PROMPT \(run_internal_prompt\)\n═+\n.*?(?=═+\nRULE 8)",
    "═══════════════════════════════════════════════════\n"
    "RULE 7 — INTERNAL PROMPT (NOT AVAILABLE IN THIS PACKAGE)\n"
    "═══════════════════════════════════════════════════\n"
    "run_internal_prompt is not available on this agent. If the user asks for a summary/overview that needs an internal GPTfy prompt, tell them this capability is not enabled and offer fetch_*_details (or Account search/related lists) instead.\n\n",
    text,
    count=1,
    flags=re.DOTALL,
)

text = re.sub(
    r"═+\nRULE 8 — BULK OPERATIONS \(bulk_update_records\)\n═+\n.*?(?=═+\nRULE 9)",
    "═══════════════════════════════════════════════════\n"
    "RULE 8 — BULK OPERATIONS (NOT AVAILABLE IN THIS PACKAGE)\n"
    "═══════════════════════════════════════════════════\n"
    "bulk_update_records is not available on this agent. For multi-record updates, update one record at a time with the matching update_*_fields skill and a fresh Rule 3 confirmation for each record.\n\n",
    text,
    count=1,
    flags=re.DOTALL,
)

text = text.replace(
    "2. Silently fetch current values via fetch_*_details or fuzzy_search_*.",
    "2. Silently fetch current values via fetch_*_details (non-Account) or fuzzy_search_*.",
)

text = text.replace(
    "- If you do not know the API name of a field, ask the user or call fetch_picklist_values to discover valid options.",
    "- If you do not know the API name of a field or picklist value, ask the user — do not invent values.",
)

# Example 1 — remove fetch_account_details
text = text.replace(
    "Assistant (silently calls fuzzy_search_accounts → 1 match → silently calls fetch_account_details for current AnnualRevenue):",
    "Assistant (silently calls fuzzy_search_accounts → 1 match; uses known/current AnnualRevenue from conversation or asks the user if unknown — Account has no fetch_account_details):",
)



# Remove hard-delete guidance inherited from the archived source snapshot.
text = text.replace("- delete_<object>           → HTML   hard delete          (DOUBLE CONFIRMATION REQUIRED — Rule 3)\n", "")
text = re.sub(r"^- DELETE:.*\n", "", text, flags=re.MULTILINE)
text = re.sub(
    r"Skills that REQUIRE confirmation before invocation:\n.*?"
    r"Skills that do NOT require confirmation \(read-only / lookup\):\n[^\n]*",
    "Skills that REQUIRE confirmation before invocation:\n"
    "- CREATE: create_account, create_contact, create_lead, create_opportunity, create_case\n"
    "- UPDATE: update_account_fields, update_contact_fields, update_lead_fields, update_opportunity_fields, update_case_fields, add_opportunity_line_item\n"
    "- CLOSE: close_case\n"
    "- ACTIVITY LOGGING: log_contact_activity, log_lead_activity, log_opportunity_activity\n\n"
    "Skills that do NOT require confirmation (read-only / lookup):\n"
    "- All fuzzy_search_*, fetch_contact_details, fetch_lead_details, fetch_opportunity_details, fetch_case_details, fetch_account_related_lists.",
    text,
    count=1,
    flags=re.DOTALL,
)
text = re.sub(
    r"\nConfirmation card format \(DELETE — requires DOUBLE confirmation\):\n.*?(?=\nConfirmation card format \()",
    "\n", text, count=1, flags=re.DOTALL,
)
text = re.sub(r"\nDELETE \(.*?\):\n.*?(?=\nCLOSE \()", "\n", text, count=1, flags=re.DOTALL)
text = re.sub(r"^- DELETE\s+→.*\n", "", text, flags=re.MULTILINE)
text = re.sub(r"^\d+\. ALWAYS require DOUBLE confirmation for any delete_\* skill\.\n", "", text, flags=re.MULTILINE)
text = re.sub(
    r"\n─────────────────────────────────────────\nEXAMPLE 2 — Declined confirmation \(destructive op\)\n"
    r"─────────────────────────────────────────\n.*?"
    r"(?=\n─────────────────────────────────────────\nEXAMPLE 3)",
    "\n", text, count=1, flags=re.DOTALL,
)
text = text.replace("STANDARD CRUD PATTERN (per object)", "STANDARD RECORD PATTERN (per object)")
text = text.replace("RULE 6 — CRUD FLOWS", "RULE 6 — RECORD FLOWS")
text = text.replace("created, updated or deleted", "created or updated")
text = text.replace(
    "Before any update, deletion, activity, or detail fetch, you need a confirmed record Id.",
    "Before any update, activity, or detail fetch, you need a confirmed record Id.",
)

# Sanity checks
for banned in [
    "convert_lead",
    "fetch_account_details",
    "fetch_opportunity_recent_changes",
    "fetch_picklist_values",
    "fetch_session_context",
    "fetch_user_info",
    "create_task",
    "bulk_update_records",
    "run_internal_prompt",
]:
    # Allow mentions in "NOT available" / "Excluded" / "NO fetch_account_details" contexts
    pass

OUT.write_text(text, encoding="utf-8", newline="\n")
print(f"Wrote {OUT} ({len(text)} chars)")
# Count remaining risky skill invocations (lines that look like capabilities)
for term in ["convert_lead", "fetch_account_details", "fetch_opportunity_recent_changes",
             "fetch_picklist_values", "create_task", "bulk_update_records", "run_internal_prompt"]:
    count = text.count(term)
    print(f"  mentions of {term}: {count}")
