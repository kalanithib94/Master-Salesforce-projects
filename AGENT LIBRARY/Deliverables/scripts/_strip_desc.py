"""Removes the ccai__Description__c assignment line from each Part*.apex file."""
import re, glob

for f in sorted(glob.glob('Part*.apex')):
    s = open(f, encoding='utf-8').read()
    # Match the whole line containing ccai__Description__c assignment, including trailing comma & newline
    new = re.sub(r"\s*ccai__Description__c\s*=\s*'(?:[^'\\]|\\.)*'\s*,\r?\n", '\n', s)
    removed = s.count("ccai__Description__c =") - new.count("ccai__Description__c =")
    open(f, 'w', encoding='utf-8').write(new)
    print(f"{f}: removed {removed} description assignments, new size {len(new)} bytes")

print("Done.")
