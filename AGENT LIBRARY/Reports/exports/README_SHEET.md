# Skill library sheets (update here)

| Sheet | URL |
|-------|-----|
| Full values (E2E + field guide + **Org enablement** steps) | https://docs.google.com/spreadsheets/d/1LsHePYKTJ5rn3OYQpyud3lX02MJ2SijRH3cZcCpo9vI/edit |
| Index | https://docs.google.com/spreadsheets/d/1LHw46KlgmFam2cX5sMBPSIxEYNrEUqx7E22ihp-9K5E/edit |

Tab **Org enablement** = feature + How (self/partner) + skills + **Steps to do it**.

Rebuild from MAIN + prompt JSON:

```text
cd "AGENT LIBRARY/api-skill-e2e-tests/scripts"
python export_skill_library_sheet.py
```

Then re-upload `Reports/exports/GPTfy_Skill_Library_E2E.xlsx` (convert to Google Sheet) onto the **Full values** spreadsheet (or replace file content).
