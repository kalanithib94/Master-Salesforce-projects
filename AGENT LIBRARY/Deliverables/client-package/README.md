# GPTfy Agent — Client Package

Hand this folder (plus the Apex under `../force-app`) to clients so they can stand up **GPTfy Agent** with 25 Account / Contact / Lead / Case / Opportunity skills.

## Contents

| File | Purpose |
|------|---------|
| `package.xml` | Metadata manifest — 10 Apex classes |
| `SeedClientSkills.apex` | Creates agent **GPTfy Agent**, inserts 25 skill prompts, links them |
| `GPTfy_Agent_SystemPrompt_v1.3.0_client.txt` | Trimmed org **v1.3.0** system prompt for this skill set |
| `SyncSystemPromptToGPTfyAgent.ps1` | Writes the system prompt onto **GPTfy Agent** |
| `_build_seed.py` / `_build_prompt.py` | Regenerators (maintainers only) |

## Prerequisites (client org)

1. GPTfy managed package (`ccai`) installed  
2. Salesforce CLI (`sf`) authenticated to the org  
3. A **Data Extraction Mapping** record — get its Id:

```bash
sf data query --query "SELECT Id, Name FROM ccai__AI_Data_Extraction_Mapping__c LIMIT 20" --target-org <ClientOrg>
```

## Install steps

Run from the **Deliverables** folder (parent of `client-package` and `force-app`).

### 1. Deploy Apex

```bash
sf project deploy start --manifest client-package/package.xml --target-org <ClientOrg>
```

### 2. Edit and run the skill seed file

Open `client-package/SeedClientSkills.apex` and set:

```apex
final String DATA_MAPPING = 'a0xxxxxxxxxxxxxxx';  // THIS org's mapping Id
```

Then:

```bash
sf apex run --file client-package/SeedClientSkills.apex --target-org <ClientOrg>
```

This:

- Creates (or reuses) agent named **GPTfy Agent** (`Status = Active`)
- Inserts 25 `ccai__AI_Prompt__c` skills (skips names that already exist)
- Links them via `ccai__AI_Agent_Skill__c`

**UI alternative:** Developer Console → Debug → Open Execute Anonymous Window → paste the file → Execute.

### 3. Sync the system prompt

```powershell
powershell -ExecutionPolicy Bypass -File client-package\SyncSystemPromptToGPTfyAgent.ps1 -TargetOrg <ClientOrg>
```

### 4. Verify in GPTfy

- Agent **GPTfy Agent** is Active  
- 25 skills linked  
- Smoke-test e.g. “Find accounts named Acme”

## Skills included (25)

**Account (4):** `fuzzy_search_accounts`, `create_account`, `update_account_fields`, `fetch_account_related_lists`  

**Contact (5):** `fuzzy_search_contacts`, `fetch_contact_details`, `create_contact`, `update_contact_fields`, `log_contact_activity`  

**Lead (5):** `fuzzy_search_leads`, `fetch_lead_details`, `create_lead`, `update_lead_fields`, `log_lead_activity`  

**Opportunity (6):** `fuzzy_search_opportunities`, `fetch_opportunity_details`, `create_opportunity`, `update_opportunity_fields`, `log_opportunity_activity`, `add_opportunity_line_item`  

**Case (5):** `fuzzy_search_cases`, `fetch_case_details`, `create_case`, `update_case_fields`, `close_case`

## Explicitly excluded

- `fetch_account_details`
- `convert_lead`
- `fetch_opportunity_recent_changes`
- All Utility skills (`fetch_picklist_values`, `fetch_user_info`, `fetch_session_context`, …)
- All Activity-only skills (`create_task`, `create_event`, `complete_task`, `fetch_my_open_tasks`)

`UtilityAgenticSkillsHandler` and `ActivityAgenticSkillsHandler` are still **deployed** (compile/facade dependency) but no Utility/Activity skills are seeded.

## Notes

- Skills are **data records**, not Metadata — they cannot live inside `package.xml` alone.  
- Mapping Ids and Agent Ids are **org-specific**; do not reuse production Ids in another org.  
- Re-running `SeedClientSkills.apex` is safe: existing prompt Names are skipped; missing agent–skill links are added.
