"""Final pass: replace every remaining non-ASCII character with a safe ASCII equivalent."""

with open(r'c:\CC\Project_SFDC\Snowflake\generate_pdf.py', 'rb') as f:
    raw = f.read()

# Strip BOM if present
if raw.startswith(b'\xef\xbb\xbf'):
    raw = raw[3:]

# Decode with latin-1 so every byte is preserved faithfully as a code point
text = raw.decode('latin-1')

# -------------------------------------------------------------------
# Map every non-ASCII sequence to a clean ASCII replacement.
# Order matters — longest sequences first.
# -------------------------------------------------------------------
subs = [
    # box-drawing / horizontal rules used in section comments
    ('\xe2\x94\x80', '-'),    # ─  (U+2500)
    ('\xe2\x86\x92', '->'),   # →
    ('\xe2\x86\x90', '<-'),   # ←
    ('\xe2\x86\x94', '<->'),  # ↔
    ('\xe2\x80\x94', ' - '),  # em dash  —
    ('\xe2\x80\x93', ' - '),  # en dash  –
    ('\xe2\x80\xa2', '-'),    # bullet   •
    ('\xe2\x84\x93', 'l'),    # script l
    ('\xe2\x9c\x93', 'V'),    # ✓
    ('\xe2\x9c\x95', 'X'),    # ✕
    ('\xe2\x9d\x84', '*'),    # ❄  snowflake
    ('\xe2\x80\x98', "'"),    # left single quote
    ('\xe2\x80\x99', "'"),    # right single quote
    ('\xe2\x80\x9c', '"'),    # left double quote
    ('\xe2\x80\x9d', '"'),    # right double quote
    ('\xe2\x80\xa6', '...'),  # ellipsis
    ('\xe2\x80\x8b', ''),     # zero-width space
    ('\xc3\x97', 'x'),        # ×
    ('\xc3\xa9', 'e'),        # é
    ('\xef\xbb\xbf', ''),     # BOM
    # leftover single-byte high chars
    ('\x80', ''),  # euro sign remnant
    ('\x94', '-'), # right double quote (cp1252)
    ('\x93', '-'), # left double quote (cp1252)
    ('\x96', '-'), # en dash (cp1252)
    ('\x97', '-'), # em dash (cp1252)
    ('\x95', '-'), # bullet (cp1252)
    ('\xa0', ' '), # non-breaking space
    ('\x99', 'TM'),# trademark
    ('\x85', '...'),# ellipsis (cp1252)
    ('\xb6', ''),  # pilcrow
    ('\xa9', '(c)'),# copyright
    ('\xae', '(R)'),# registered
]

for bad, good in subs:
    text = text.replace(bad, good)

# Final sweep: replace any remaining non-ASCII with '?'
clean = ''.join(c if ord(c) < 128 else '?' for c in text)

# Count replacements
changed = sum(1 for a, b in zip(text, clean) if a != b)
print(f"Replaced {changed} remaining non-ASCII chars with '?'")

with open(r'c:\CC\Project_SFDC\Snowflake\generate_pdf.py', 'w', encoding='utf-8') as f:
    f.write(clean)

print("Done. File is now pure ASCII.")
