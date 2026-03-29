"""Find ALL lines with embedded quote corruption in string literals."""
with open(r'c:\CC\Project_SFDC\Snowflake\generate_pdf.py', 'rb') as f:
    lines = f.read().split(b'\n')

broken = []
for i, line in enumerate(lines, 1):
    decoded = line.decode('utf-8', errors='replace')
    # Look for lines that have an f-string or string with ? chars near quotes
    import re
    # Pattern: string literal that gets broken by a mid-string "
    # e.g.  "some text ???"  more text")
    if re.search(r'"[^"]*\?+"\s+[^"]*"', decoded):
        broken.append((i, decoded.strip()))

print(f"Found {len(broken)} broken lines:")
for lineno, content in broken:
    print(f"  Line {lineno}: {repr(content[:100])}")
