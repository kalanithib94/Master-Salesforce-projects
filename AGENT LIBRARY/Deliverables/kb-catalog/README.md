# GPTfy Skills — KB Catalog (local HTML)

Open `index.html` in a browser (double-click or serve the folder).

Each skill card downloads a zip with:
- `package.xml` + Apex (`AgenticSkillsBase` + handler + smoke tests)
- `seed.apex` → creates `ccai__AI_Prompt__c` + agent link
- `sample-system-prompt.txt`, `version.json`, `PRODUCTION_NOTES.txt`
- `README.txt`
- Catalog download also adds `install.ps1` / `install.sh` (`-RunTests` for prod)

Rebuild:
```bash
python kb-catalog/build_kb_catalog.py
```

Serve locally (recommended so downloads work cleanly):
```bash
cd kb-catalog
python -m http.server 8765
```
Then open http://localhost:8765/
