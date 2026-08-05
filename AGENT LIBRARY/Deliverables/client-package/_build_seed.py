"""Build client SeedClientSkills.apex from Part1-5 scripts (filtered)."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "client-package" / "SeedClientSkills.apex"
EXCLUDE = {
    "fetch_account_details",
    "convert_lead",
    "fetch_opportunity_recent_changes",
}
PARTS = [
    ROOT / "scripts" / "Part1_Account.apex",
    ROOT / "scripts" / "Part2_Contact.apex",
    ROOT / "scripts" / "Part3_Lead.apex",
    ROOT / "scripts" / "Part4_Opportunity.apex",
    ROOT / "scripts" / "Part5_Case.apex",
]

PROMPT_RE = re.compile(
    r"prompts\.add\(new ccai__AI_Prompt__c\(\s*"
    r"Name = '([^']+)',"
    r".*?"
    r"\)\s*\);",
    re.DOTALL,
)


def main() -> None:
    blocks: list[tuple[str, str]] = []
    for path in PARTS:
        text = path.read_text(encoding="utf-8")
        for m in PROMPT_RE.finditer(text):
            name = m.group(1)
            if name in EXCLUDE:
                continue
            block = m.group(0)
            # Normalize class / constants references already use CLASS_NAME in parts -
            # each part sets CLASS_NAME separately. Rewrite to use handler map.
            blocks.append((name, block))

    names = [n for n, _ in blocks]
    assert len(blocks) == 25, f"Expected 25 skills, got {len(blocks)}: {names}"

    # Map skill name -> handler class
    handler_by_skill = {}
    for path in PARTS:
        text = path.read_text(encoding="utf-8")
        cls = re.search(r"CLASS_NAME = '([^']+)'", text).group(1)
        for m in PROMPT_RE.finditer(text):
            handler_by_skill[m.group(1)] = cls

    prompt_adds = []
    for name, block in blocks:
        cls = handler_by_skill[name]
        # Replace CLASS_NAME with literal class string for single-file seed
        fixed = block.replace("CLASS_NAME", f"'{cls}'")
        # Fix double-quoting if CLASS_NAME was already inside quotes: ''Class'' -> 'Class'
        fixed = fixed.replace(f"''{cls}''", f"'{cls}'")
        prompt_adds.append(fixed)

    header = '''\
// =============================================================================
// SeedClientSkills.apex
// Creates agent "GPTfy Agent", inserts 25 CRM object skills, and links them.
// Prerequisites: GPTfy (ccai) installed + Apex handlers deployed via package.xml
//
// BEFORE RUNNING: set DATA_MAPPING to this org's
//   ccai__AI_Data_Extraction_Mapping__c Id (Ids do not transfer between orgs).
//
// Usage:
//   sf apex run --file client-package/SeedClientSkills.apex --target-org <alias>
// =============================================================================

final String AGENT_NAME = 'GPTfy Agent';
final String AGENTIC = 'Agentic';
final String ACTIVE = 'Active';
// TODO: replace with THIS org's Data Extraction Mapping Id
final String DATA_MAPPING = 'REPLACE_WITH_DATA_EXTRACTION_MAPPING_ID';

if (DATA_MAPPING == null || DATA_MAPPING.startsWith('REPLACE_')) {
    System.debug(LoggingLevel.ERROR,
        'Stop: set DATA_MAPPING to a valid ccai__AI_Data_Extraction_Mapping__c Id before running.');
} else {

// --- Agent -------------------------------------------------------------------
List<ccai__AI_Agent__c> agents = [
    SELECT Id, Name, ccai__Status__c
    FROM ccai__AI_Agent__c
    WHERE Name = :AGENT_NAME
    LIMIT 1
];
ccai__AI_Agent__c agent;
if (agents.isEmpty()) {
    agent = new ccai__AI_Agent__c(
        Name = AGENT_NAME,
        ccai__Status__c = ACTIVE
    );
    insert agent;
    System.debug('Created agent: ' + agent.Id + ' (' + AGENT_NAME + ')');
} else {
    agent = agents[0];
    if (agent.ccai__Status__c != ACTIVE) {
        agent.ccai__Status__c = ACTIVE;
        update agent;
    }
    System.debug('Using existing agent: ' + agent.Id + ' (' + AGENT_NAME + ')');
}

// --- Prompts (25 skills) -----------------------------------------------------
List<ccai__AI_Prompt__c> prompts = new List<ccai__AI_Prompt__c>();

'''

    footer = '''
Set<String> proposedNames = new Set<String>();
for (ccai__AI_Prompt__c p : prompts) proposedNames.add(p.Name);

Map<String, Id> existingByName = new Map<String, Id>();
for (ccai__AI_Prompt__c p : [
    SELECT Id, Name FROM ccai__AI_Prompt__c WHERE Name IN :proposedNames
]) {
    existingByName.put(p.Name, p.Id);
}

List<ccai__AI_Prompt__c> toInsert = new List<ccai__AI_Prompt__c>();
List<String> skipped = new List<String>();
for (ccai__AI_Prompt__c p : prompts) {
    if (existingByName.containsKey(p.Name)) skipped.add(p.Name);
    else toInsert.add(p);
}
if (!toInsert.isEmpty()) insert toInsert;
System.debug('Prompts inserted ' + toInsert.size() + ' / skipped ' + skipped.size() + ' -> ' + skipped);

// Refresh Id map with newly inserted rows
for (ccai__AI_Prompt__c p : toInsert) existingByName.put(p.Name, p.Id);
for (ccai__AI_Prompt__c p : [
    SELECT Id, Name FROM ccai__AI_Prompt__c WHERE Name IN :proposedNames
]) {
    existingByName.put(p.Name, p.Id);
}

// --- Link skills to GPTfy Agent ---------------------------------------------
Set<Id> promptIds = new Set<Id>(existingByName.values());
Set<Id> alreadyLinked = new Set<Id>();
for (ccai__AI_Agent_Skill__c link : [
    SELECT ccai__AI_Prompt__c
    FROM ccai__AI_Agent_Skill__c
    WHERE ccai__AI_Agent__c = :agent.Id
      AND ccai__AI_Prompt__c IN :promptIds
]) {
    alreadyLinked.add(link.ccai__AI_Prompt__c);
}

List<ccai__AI_Agent_Skill__c> newLinks = new List<ccai__AI_Agent_Skill__c>();
for (String skillName : proposedNames) {
    Id pid = existingByName.get(skillName);
    if (pid == null) continue;
    if (alreadyLinked.contains(pid)) continue;
    newLinks.add(new ccai__AI_Agent_Skill__c(
        ccai__AI_Agent__c = agent.Id,
        ccai__AI_Prompt__c = pid
    ));
}
if (!newLinks.isEmpty()) insert newLinks;
System.debug('Agent skill links created: ' + newLinks.size());
System.debug('Done. Agent Id=' + agent.Id + ' Name=' + AGENT_NAME
    + ' Skills expected=' + proposedNames.size());
} // end DATA_MAPPING guard
'''

    OUT.parent.mkdir(parents=True, exist_ok=True)
    body = header + "\n\n".join(prompt_adds) + "\n" + footer
    OUT.write_text(body, encoding="utf-8", newline="\n")
    print(f"Wrote {OUT} with {len(blocks)} prompts:")
    for n in names:
        print(" ", n)


if __name__ == "__main__":
    main()
