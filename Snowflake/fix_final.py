"""
Final targeted fix:
  1. Normalise all line endings to LF
  2. Fix the broken SectionBanner f-string (corrupted em-dash bytes)
  3. Fix any other f-string lines where corruption introduced a stray quote
  4. Ensure the file is clean UTF-8 / ASCII
"""
import re

with open(r'c:\CC\Project_SFDC\Snowflake\generate_pdf.py', 'rb') as f:
    raw = f.read()

# Step 1: strip BOM, normalise CR/LF
raw = raw.replace(b'\xef\xbb\xbf', b'')   # BOM
raw = raw.replace(b'\r\n', b'\n')
raw = raw.replace(b'\r', b'\n')

text = raw.decode('utf-8', errors='replace')

# Step 2: replace any remaining Unicode replacement char (U+FFFD) sequences
text = text.replace('\ufffd', '?')

# Step 3: targeted string fixes — corrupted f-string in SectionBanner
# The original was:  f"Section {self.number}  ---  {self.title}"
# Corruption made it: f"Section {self.number}  ?????"  {self.title}")
# Fix: restore to clean ASCII
text = re.sub(
    r'f"Section \{self\.number\}[^"]*"[^"]*\{self\.title\}"\)',
    'f"Section {self.number}  -  {self.title}")',
    text
)

# Step 4: fix the TOC section separator lines — replace any residual
# corruption in string literals that contain only question marks
# Pattern: a string that is all ? chars (length >= 2)
text = re.sub(r'"[?]{2,}"', '" - "', text)

# Step 5: fix the bottom meta line if it has mojibake bullets
text = re.sub(
    r'drawCentredString\(w/2, 28\*mm,[^)]+\)',
    'drawCentredString(w/2, 28*mm, "March 2026  -  Internal Technical Documentation  -  Confidential")',
    text
)

# Step 6: replace any remaining non-ASCII outside of string literals
# (safe: comment lines and section header strings)
def clean_line(line):
    # If it's a comment line, just replace non-ASCII
    stripped = line.lstrip()
    if stripped.startswith('#'):
        return ''.join(c if ord(c) < 128 else '-' for c in line)
    return line

lines = text.split('\n')
lines = [clean_line(l) for l in lines]
text = '\n'.join(lines)

# Final sweep: replace any still-remaining non-ASCII
# BUT protect string contents — only strip from comments and raw code
# (Simple approach: just replace all remaining non-ASCII with ?)
clean = ''.join(c if ord(c) < 128 else '?' for c in text)

# Verify the SectionBanner line is now clean
for i, line in enumerate(clean.split('\n'), 1):
    if 'drawString' in line and 'self.number' in line:
        print(f"Line {i}: {repr(line)}")

with open(r'c:\CC\Project_SFDC\Snowflake\generate_pdf.py', 'w', encoding='utf-8', newline='\n') as f:
    f.write(clean)

print("Done.")
