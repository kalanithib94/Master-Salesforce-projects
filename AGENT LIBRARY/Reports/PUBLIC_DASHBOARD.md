# Public E2E dashboard (share the link — not the git repo)

## Links (viewers)

- **Dashboard (run history):** https://kalanithib94.github.io/Master-Salesforce-projects/gptfy-agent-skills-e2e/dashboard.html  
- **Latest skill detail:** https://kalanithib94.github.io/Master-Salesforce-projects/gptfy-agent-skills-e2e/  

Hosting is a static public URL only. Stakeholders open HTTPS — they do not need GitHub accounts or the monorepo.

## Auto-update on every test

When you publish MAIN (matrix / retry), history updates automatically:

1. `retry_failed_skills.py` or full matrix → `publish_main_and_archive`
2. Appends a row to `AGENT LIBRARY/Reports/runs_history.json`
3. Rebuilds `AGENT LIBRARY/Reports/DASHBOARD.html`
4. Copies to `docs/gptfy-agent-skills-e2e/dashboard.html`

Then push (or your Pages/deploy job) so the public URL refreshes.

Manual rebuild of history from all archives:

```text
cd "AGENT LIBRARY/api-skill-e2e-tests/scripts"
python build_public_dashboard.py --rebuild-from-archives
```

## Local files

| File | Role |
|------|------|
| `Reports/DASHBOARD.html` | Shareable multi-run dashboard |
| `Reports/runs_history.json` | Source of truth for run counts |
| `Reports/MAIN_REPORT.html` | Latest full request/response |
| `Reports/archive/*.html` | Immutable per-run snapshots |
