# API Skill E2E Tests

Dedicated harness to:

1. Inventory agents / skills / Apex on a connected CLI org  
2. Deploy all handler classes from `Deliverables/force-app`  
3. Seed skills (prompt + agent link) in batches  
4. Call `invokeAgentSkill` one skill at a time and record Apex responses  

**Not** a GitHub Pages catalog folder. Isolated from `kb-catalog/`.

## Prerequisites

- Salesforce CLI (`sf`) authenticated to a GPTfy-enabled org  
- User has GPTfy permission set  
- Connected App **not** required when using CLI access tokens  

```bash
sf org login web -a MyTestOrg
# or point scripts at an existing alias, e.g. "Master Dev"
```

## Layout

```
api-skill-e2e-tests/
  README.md
  config.example.json      # copy → config.local.json (gitignored)
  package/
    package.xml            # all AgenticSkills handlers + base (+ tests optional)
    sfdx-project.json
  scripts/
    inventory_org.py       # what’s on the org now
    deploy_handlers.py     # sf project deploy force-app handlers
    seed_skills.py         # bulk seed from package seeds + link agent
    list_skills_api.py     # getAgentSkills
    invoke_skill.py        # invokeAgentSkill one skill
    run_smoke_matrix.py    # optional batch invoke (read-only first)
  fixtures/
    smoke_payloads.json    # sample data per skill (Id placeholders)
  results/                 # inventory + invoke JSON outputs (local)
```

## Typical workflow

```powershell
cd "c:\CC\Project_SFDC\AGENT LIBRARY\api-skill-e2e-tests"

# 0) Config
copy config.example.json config.local.json
# edit: targetOrg, agentName (or Developer Name), dataMappingId, aiModelId

# 1) See current org
python scripts/inventory_org.py "Master Dev"

# 2) Deploy ALL handler Apex (once)
python scripts/deploy_handlers.py "Master Dev"

# 3) Seed all 111 skills onto agent (batches; needs mapping + model Ids from inventory)
python scripts/seed_skills.py "Master Dev"

# 4) Confirm API skill list
python scripts/list_skills_api.py "Master Dev"

# 5) Invoke one skill (prefer --data-file on Windows/PowerShell)
python scripts/invoke_skill.py "Master Dev" fuzzy_search_contacts --data-file fixtures/payload.json
# After reseed with new schema, update fixture keys (e.g. searchTerm).
```

## Important limitations

| Topic | Detail |
|--------|--------|
| Deploy handlers | **Yes** — one metadata deploy of Apex classes (depends on `ccai` package for `AIAgenticInterface`). |
| Seed 111 prompts | **Yes** — needs valid **Data Extraction Mapping** + **AI Connection** Ids; links agent ↔ prompts. |
| Publish agent | In GPTfy UI "publish" often = set **Active** + skills linked. Seed sets Status=Active. Developer Name may be auto-generated on create — prefer inventory DevName for API. |
| Test one-by-one | Prefer **`invokeAgentSkill`** (direct Apex) over chat (`agentic`) — no multi-turn AI orchestration, cheaper. |
| Write skills | Can mutate data — use a **sandbox** if possible; fixtures use safe search first. |
| Org from dry-run | Master Dev already has **partial** handlers + **8** agentic prompts; **7** linked to agent. |

## Master Dev snapshot (inventory)

See `scripts/results/org_inventory.json` after running inventory.

- Agent: `GPTfy Master Agent` (Active)  
- API name: use `ccai__Developer_Name__c` from inventory (not seed string `GPTfy Agent`)  
- Prompts present (8): see inventory  
- Apex present: Account/Activity/Case/Contact/Utility handlers + Base + tests (incomplete vs 111)  

## Manual "add skill → publish → API" loop

The automation mirrors this:

1. Deploy Apex for that skill’s handler  
2. Insert/update `ccai__AI_Prompt__c` + agent skill link  
3. Agent stays Active  
4. `getAgentSkills` → obtain `promptId`  
5. `invokeAgentSkill` with `promptId` + JSON `data` matching Prompt Command  

You can still do steps 2–5 skill-by-skill instead of bulk seed if you prefer.
