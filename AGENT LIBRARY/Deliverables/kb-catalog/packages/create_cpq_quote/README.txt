GPTfy Skill Package: Create CPQ Quote
================================

API name : create_cpq_quote
Category : CPQ
Apex     : CpqAgenticSkillsHandler + AgenticSkillsBase (+ smoke tests)
Prompt   : ccai__AI_Prompt__c Name = create_cpq_quote

WHAT IS IN THIS ZIP
-------------------
1. package.xml + force-app/     Apex + smoke tests
2. seed.apex                    Creates AI Prompt + agent skill link
3. sample-system-prompt.txt     Composed / sample agent system prompt
4. version.json                 Package metadata (classes, tests)
5. PRODUCTION_NOTES.txt         Deploy / verify cheat sheet
6. install.ps1 / install.sh     Deploy + register (optional -RunTests)
7. README.txt                   This file

PREREQUISITES
-------------
- GPTfy managed package (ccai) installed
- Salesforce CLI (sf) authenticated to the target org
- A Data Extraction Mapping Id and an AI Connection (model) Id in THIS org

IMPORT STEPS
------------
1) seed.apex Ids are prefilled when downloaded from the catalog.

2) Deploy Apex (from the unzipped folder):

   sf project deploy start --manifest package.xml --target-org <alias>

   Production (run package tests):

   .\install.ps1 -RunTests
   or
   sf project deploy start --manifest package.xml --test-level RunSpecifiedTests --tests AgenticSkillsBaseTest --tests CpqAgenticSkillsHandlerTest --target-org <alias>

3) Register skill (seed):

   sf apex run --file seed.apex --target-org <alias>

   Or use .\install.ps1 (deploy + seed; -RunTests for tests).

4) Optional: system prompt via sample-system-prompt.txt / catalog toggle.

NOTES
-----
- Apex is shared per object. Deploying CpqAgenticSkillsHandler installs all methods in that class;
  this seed still creates ONLY the "create_cpq_quote" prompt record.
- Re-running seed.apex is safe: existing prompt Names are skipped; missing links are added.
- Mapping / Model Ids do not transfer between orgs.
- See PRODUCTION_NOTES.txt for verify steps.

Skill summary
-------------
Start a CPQ quote from an opportunity for guided selling.
