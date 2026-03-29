"""
Iteratively fix all syntax errors caused by stray quote characters
that were introduced when em/en dashes were corrupted.
Pattern: inside a string,  word - "word  ->  word - word
"""
import re, py_compile, ast

def get_syntax_error_line(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            source = f.read()
        compile(source, filepath, 'exec')
        return None, None, source
    except SyntaxError as e:
        return e.lineno, e.text, source

def fix_broken_line(line):
    """
    Fix a line that has a stray " in the middle of a string.
    e.g.: ("foo",  "bar baz - "qux")   =>  ("foo",  "bar baz - qux")
    """
    # Pattern A: word_or_digit  -  "word  (en/em dash replacement broke here)
    # Replace:   - "X  with  - X   when X is a word char or digit
    line = re.sub(r'(\s-\s)"([0-9A-Za-z(])', r'\1\2', line)
    
    # Pattern B:  text, "  more text"  where "  opens wrongly
    # (already handled by fix_emdash mostly, but for edge cases)
    # If there's a  "  immediately followed by a word in the middle of a string
    line = re.sub(r'(\w)\s+"([A-Za-z(])', r'\1 \2', line)
    
    # Pattern C: -  "word  (no spaces around dash)
    line = re.sub(r'(-\s)"([A-Za-z0-9])', r'\1\2', line)
    
    return line

MAX_ITERS = 100
for iteration in range(MAX_ITERS):
    lineno, errtext, source = get_syntax_error_line(r'c:\CC\Project_SFDC\Snowflake\generate_pdf.py')
    if lineno is None:
        print(f"SUCCESS after {iteration} iterations - file compiles cleanly!")
        break
    
    print(f"Iter {iteration+1}: fixing line {lineno}: {repr(errtext[:80] if errtext else '')}")
    
    lines = source.split('\n')
    if lineno - 1 < len(lines):
        original = lines[lineno - 1]
        fixed = fix_broken_line(original)
        if fixed == original:
            # Can't auto-fix; show the line and break
            print(f"Cannot auto-fix line {lineno}: {repr(original[:120])}")
            break
        lines[lineno - 1] = fixed
        new_source = '\n'.join(lines)
        with open(r'c:\CC\Project_SFDC\Snowflake\generate_pdf.py', 'w', encoding='utf-8', newline='\n') as f:
            f.write(new_source)
    else:
        print(f"Line {lineno} out of range ({len(lines)} lines total)")
        break
else:
    print(f"Reached max iterations ({MAX_ITERS}) - check file manually")
