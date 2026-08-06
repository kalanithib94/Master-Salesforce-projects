# Skill library sheet exports

## Google Sheets

| Role | URL |
|------|-----|
| **Full values (use this)** | https://docs.google.com/spreadsheets/d/1LsHePYKTJ5rn3OYQpyud3lX02MJ2SijRH3cZcCpo9vI/edit |
| Index / bookmark (your link) | https://docs.google.com/spreadsheets/d/1LHw46KlgmFam2cX5sMBPSIxEYNrEUqx7E22ihp-9K5E/edit |

Scores (Master Dev matrix): **81 pass / 110** · fail_data 3 · fail_missing_feature 26

## Tabs

1. **Summary** — totals and how to read
2. **E2E Results** — request JSON, response, what happened, next step per skill
3. **Skill Field Guide** — primary/related objects, required params, field help, user expectations

## Rebuild local files

```text
cd "AGENT LIBRARY/api-skill-e2e-tests/scripts"
python export_skill_library_sheet.py
```

Outputs under `Reports/exports/`:

- `summary.csv`
- `e2e_results.csv`
- `skill_field_guide.csv`
- `GPTfy_Skill_Library_E2E.xlsx` (upload + convert to Google Sheet to refresh the cloud copy)
- `sheet_payload.json`

Sources: `Reports/MAIN_REPORT.html` + `Deliverables/docs/PROMPT_COMMANDS_BY_SKILL.json`
