"""
Fix mojibake caused by Set-Content writing the file as Windows-1252
when it should have been UTF-8. All multi-byte sequences get replaced
with clean ASCII/Latin equivalents so the PDF never breaks again.
"""

with open(r'c:\CC\Project_SFDC\Snowflake\generate_pdf.py', 'rb') as f:
    raw = f.read()

# Decode treating the file as latin-1 (which preserves every byte as-is)
# then fix the common mojibake sequences back to the intended characters
text = raw.decode('utf-8', errors='replace')

replacements = [
    # mojibake      -> intended char -> safe replacement
    ('\u00e2\u0080\u0094', '—', ' - '),   # em dash
    ('\u00e2\u0080\u0093', '–', ' - '),   # en dash
    ('\u00e2\u0080\u00a2', '•', '-'),     # bullet
    ('\u00c3\u00b7',       '×', 'x'),     # multiplication sign
    ('\u00e2\u0084\u0093', 'l', 'l'),     # script l
    ('\u00e2\u0086\u0092', '->', '->'),   # right arrow
    # Also handle the already-corrupted latin-1 mojibake strings
    ('â\x80\x94',  '—',  ' - '),
    ('â€"',         '—',  ' - '),
    ('â€"',         '—',  ' - '),
    ('â€¢',         '•',  '-'),
    ('Ã—',          '×',  'x'),
    ('â„',          '❄', '* '),
    ('\u00e2\u0084\x93', '', ''),
    # straight replacements for anything still lurking
    ('\u2014', '—', ' - '),
    ('\u2013', '–', ' - '),
    ('\u2022', '•', '-'),
    ('\u00d7', '×', 'x'),
    ('\u2192', '->', '->'),
    ('\u2714', 'checkmark', 'V'),
]

for mojibake, intended, safe in replacements:
    text = text.replace(mojibake, safe)

# Also do a direct Unicode replace pass for any remaining special chars
# that survived the above (written correctly as Unicode)
direct = [
    ('\u2014', ' - '),   # em dash
    ('\u2013', ' - '),   # en dash
    ('\u2022', '-'),     # bullet
    ('\u00d7', 'x'),     # ×
    ('\u2192', '->'),    # →
    ('\u2190', '<-'),    # ←
    ('\u2714', 'V'),     # ✔
    ('\u274c', 'X'),     # ❌
    ('\u2193', 'v'),     # ↓
    ('\u00b7', '.'),     # ·
    ('\u2018', "'"),     # left single quote
    ('\u2019', "'"),     # right single quote
    ('\u201c', '"'),     # left double quote
    ('\u201d', '"'),     # right double quote
    ('\u2026', '...'),   # ellipsis
    ('\u00e2\u009c\u0093', 'V'),   # check mark bytes
    ('\u00e2\u009c\u0095', 'X'),   # cross mark bytes
    # snowflake glyph
    ('\u2744', '*'),
    ('\u274b', '*'),
    ('\u00e2\u009d\x84', '*'),
    ('\u00e2\u009c\u0095', 'X'),
]
for bad, good in direct:
    text = text.replace(bad, good)

with open(r'c:\CC\Project_SFDC\Snowflake\generate_pdf.py', 'w', encoding='utf-8') as f:
    f.write(text)

# Quick sanity check
problem_chars = [c for c in text if ord(c) > 127 and c not in 'àáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞß']
if problem_chars:
    unique = set(problem_chars)
    print(f"Remaining non-ASCII chars ({len(unique)}): {[hex(ord(c)) for c in list(unique)[:20]]}")
else:
    print("Clean — no unexpected non-ASCII characters remain.")
print("File written successfully.")
