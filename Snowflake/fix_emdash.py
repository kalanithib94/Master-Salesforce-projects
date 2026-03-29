"""
Fix all instances of the em-dash corruption pattern in the generator.
The em dash -- was corrupted to one of these patterns:
  ?????\"  (5 question marks + closing quote + space + continuation)
  ???-\"   (3 ? + hyphen + closing quote)
  ???\"    (3 ? + closing quote)
All should become: ' - '
Also fix the header/footer line and docstring.
"""
import re

with open(r'c:\CC\Project_SFDC\Snowflake\generate_pdf.py', 'r', encoding='utf-8') as f:
    text = f.read()

original_len = len(text)

# Pattern 1: "text ?????" more text"  (5 ?s + quote breaks the string)
# Replace  ?????"  with  - 
text = re.sub(r'\?{3,}"(?=\s)', ' - ', text)

# Pattern 2: ???-"  (3 ?s + hyphen + quote)
text = re.sub(r'\?{2,}-"(?=\s)', ' - ', text)

# Pattern 3: ???" immediately followed by content (no space after quote)
# e.g. ?????" Security  -> - Security
text = re.sub(r'\?{2,}"(?=[A-Za-z\s])', ' - ', text)

# Pattern 4: standalone ?????  inside strings (no trailing quote)
# e.g.  "CRITICAL ?????" The ...  -> "CRITICAL - The..."
# These were already fixed by patterns above if they had a "
# Handle remaining: just replace ??+ with a single space-dash-space
text = re.sub(r'\?{4,}', ' - ', text)

# Pattern 5: remaining ???- or ??- sequences in string context
text = re.sub(r'\?{2,}-', ' - ', text)

# Pattern 6: lonely remaining ?s (3 consecutive) from the arrow chars
text = re.sub(r'\?{3}', ' - ', text)

# Fix the docstring on line 3 (Snowflake <-> Salesforce)
text = re.sub(
    r'Snowflake\s*\?\?\S*\s*Salesforce Integration Guide',
    'Snowflake - Salesforce Integration Guide',
    text
)

# Fix header bar "Snowflake ??? Salesforce Integration Guide"
text = re.sub(
    r'"Snowflake\s+[-?]+\s+Salesforce Integration Guide"',
    '"Snowflake  -  Salesforce Integration Guide"',
    text
)

# Fix footer "Confidential ??? For Internal Use Only"
text = re.sub(
    r'"Confidential\s+[-?]+\s+For Internal Use Only"',
    '"Confidential - For Internal Use Only"',
    text
)

# Fix: ???-" Checked  -> - Checked
text = re.sub(r'"[-?]{2,}"\s+Checked', '" - Checked', text)

# Fix comment section dividers: # ???"???..."  -> # ---
text = re.sub(r'#\s*[-?\s"]{5,}\n', lambda m: '# ' + '-'*60 + '\n', text)

print(f"Characters changed: {sum(a!=b for a,b in zip(text, ' '*len(text))) }")

with open(r'c:\CC\Project_SFDC\Snowflake\generate_pdf.py', 'w', encoding='utf-8', newline='\n') as f:
    f.write(text)

# Verify: try to compile
import py_compile, sys
try:
    py_compile.compile(r'c:\CC\Project_SFDC\Snowflake\generate_pdf.py', doraise=True)
    print("Syntax OK - no errors.")
except py_compile.PyCompileError as e:
    print(f"Still has syntax error: {e}")
