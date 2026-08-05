# GPTfy Agent Skills — E2E Reports

Reports only (not the test harness).

## Layout

| Path | Purpose |
|------|---------|
| `MAIN_REPORT.html` | Always latest request/response report |
| `archive/YYYY-MM-DD_HHMMSS_*.html` | One dated snapshot per update |

## Public

https://kalanithib94.github.io/Master-Salesforce-projects/gptfy-agent-skills-e2e/

## Fixable failures (any of: data / Prompt / Apex)

```bash
cd "../api-skill-e2e-tests/scripts"

# Org data fix + retry
python retry_failed_skills.py --from-main --org "Master Dev"

# After you fixed handlers under Deliverables/.../classes/
python retry_failed_skills.py --skills add_case_team_member --deploy-handlers \
  --reason "Apex: treat team add paths"

# After you fixed Prompt Command packages, re-seed skill packages then:
python retry_failed_skills.py --skills fetch_case_details \
  --reason "Prompt: CaseNumber/Subject preferred"
```

Handlers change → also retest full handler:

```bash
python regression_handler.py CaseAgenticSkillsHandler --reason "..." --deploy
```
