import re, py_compile

with open(r'c:\CC\Project_SFDC\Snowflake\generate_pdf.py', 'r', encoding='utf-8') as f:
    text = f.read()

# Fix every string that has the broken pattern: "...word"  word..."
# specifically the header/footer/docstring lines with Snowflake <-> Salesforce
fixes = [
    # header bar in header_footer callback
    (r'"Snowflake[^"\n]{0,20}"[^"\n]{0,20}Salesforce Integration Guide"',
     '"Snowflake  -  Salesforce Integration Guide"'),
    # docstring at top of file
    (r'Snowflake[^"\n]{0,5}"[^"\n]{0,5}Salesforce Integration Guide',
     'Snowflake - Salesforce Integration Guide'),
]

for pattern, replacement in fixes:
    text = re.sub(pattern, replacement, text)

with open(r'c:\CC\Project_SFDC\Snowflake\generate_pdf.py', 'w', encoding='utf-8', newline='\n') as f:
    f.write(text)

try:
    py_compile.compile(r'c:\CC\Project_SFDC\Snowflake\generate_pdf.py', doraise=True)
    print('Syntax OK - ready to generate PDF.')
except py_compile.PyCompileError as e:
    # Show context around the error
    print(f'Syntax error: {e}')
    lineno = int(str(e).split('line ')[1].split(')')[0]) if 'line ' in str(e) else 0
    if lineno:
        lines = text.split('\n')
        for i in range(max(0, lineno-2), min(len(lines), lineno+2)):
            print(f'  {i+1}: {repr(lines[i][:120])}')
