# Detailed skill reports

Each HTML file is a **request / response transcript** for every skill on a handler after a change.

## What you will see

1. Date and time
2. Why we updated (need)
3. What files changed
4. Per skill: full **Request** JSON and full **Response** JSON/text side by side

No big scoreboard — the detail is the point.

## Generate

```bash
cd ../scripts
python regression_handler.py CaseAgenticSkillsHandler --reason "Describe why this update was needed"
```
