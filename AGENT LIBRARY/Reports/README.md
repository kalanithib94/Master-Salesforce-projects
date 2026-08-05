# GPTfy Agent Skills — E2E Reports

This folder is **only** for skill test reports (separate from the harness in `api-skill-e2e-tests/`).

## Layout

| Path | Purpose |
|------|---------|
| `MAIN_REPORT.html` | Always latest full request/response report (share this) |
| `archive/YYYY-MM-DD_HHMMSS_*.html` | Immutable snapshot for each update |
| `archive/*.json` | Optional machine detail for a dated run |

## Public share

GitHub Pages copy (synced on each build):

https://kalanithib94.github.io/Master-Salesforce-projects/gptfy-agent-skills-e2e/

Repo file:

`docs/gptfy-agent-skills-e2e/index.html`

## How reports are generated

```bash
cd "api-skill-e2e-tests/scripts"
python build_main_report.py
# or after a handler change:
python regression_handler.py CaseAgenticSkillsHandler --reason "Why we changed this"
```
