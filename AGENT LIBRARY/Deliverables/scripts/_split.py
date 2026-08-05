"""Splits the big CreateAgenticPrompts.apex into 7 per-family scripts."""
import re, os

src = open('CreateAgenticPrompts.apex', encoding='utf-8').read()

HEADER = """final String CLASS_NAME = 'GenericAgenticSkillsHandler';
final String AGENTIC = 'Agentic';
final String ACTIVE = 'Active';

List<ccai__AI_Prompt__c> prompts = new List<ccai__AI_Prompt__c>();

"""

FOOTER = """
Set<String> proposedNames = new Set<String>();
for (ccai__AI_Prompt__c p : prompts) proposedNames.add(p.Name);
Set<String> existingNames = new Set<String>();
for (ccai__AI_Prompt__c p : [SELECT Name FROM ccai__AI_Prompt__c WHERE Name IN :proposedNames]) {
    existingNames.add(p.Name);
}
List<ccai__AI_Prompt__c> toInsert = new List<ccai__AI_Prompt__c>();
List<String> skipped = new List<String>();
for (ccai__AI_Prompt__c p : prompts) {
    if (existingNames.contains(p.Name)) skipped.add(p.Name);
    else toInsert.add(p);
}
if (!toInsert.isEmpty()) insert toInsert;
System.debug('Inserted ' + toInsert.size() + ' / Skipped ' + skipped.size() + ' -> ' + skipped);
for (ccai__AI_Prompt__c p : toInsert) System.debug('  + ' + p.Name + ' -> ' + p.Id);
"""

# Split by section header pattern
sections = re.split(r'// ═{40,}\r?\n// (\d+)\. ([^\r\n]+?)\r?\n// ═{40,}', src)
# sections[0] = header (everything before first section)
# Then triplets: (number, title, content)
print(f"Found {(len(sections)-1)//3} sections")

family_files = {
    '1': 'Part1_Account.apex',
    '2': 'Part2_Contact.apex',
    '3': 'Part3_Lead.apex',
    '4': 'Part4_Opportunity.apex',
    '5': 'Part5_Case.apex',
    '6': 'Part6_Activity.apex',
    '7': 'Part7_Utility.apex',
}

for i in range(1, len(sections), 3):
    num = sections[i].strip()
    title = sections[i+1].strip()
    content = sections[i+2]
    if num == '7':
        # Strip the trailing dispatcher block from utility section
        content = re.split(r'// ═{40,}\r?\n// SKIP-BY-NAME', content)[0]
    if num not in family_files:
        continue
    out = f"// Part {num} — {title}\n" + HEADER + content.rstrip() + '\n' + FOOTER
    fname = family_files[num]
    with open(fname, 'w', encoding='utf-8') as f:
        f.write(out)
    print(f"  {fname}: {len(out)} bytes")

print("Done.")
