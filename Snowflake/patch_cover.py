import re

with open(r'c:\CC\Project_SFDC\Snowflake\generate_pdf.py', 'r', encoding='utf-8', errors='replace') as f:
    src = f.read()

# Find start and end of the block to replace
start_marker = '    # Snowflake accent line set'
end_marker   = '    canvas.restoreState()\n'

start = src.find(start_marker)
end   = src.find(end_marker, start) + len(end_marker)

if start == -1:
    # Try the corrupted version
    start_marker = '    # Snow icon'
    start = src.find(start_marker)
    end   = src.find(end_marker, start) + len(end_marker)

print(f"Block found at chars {start}–{end}")
print("First 120 chars of block:", repr(src[start:start+120]))

new_block = '''\
    # GPTfy logo — prominent top-centre on a solid white card
    logo_h = 22 * mm
    logo_w = logo_h * 3.6
    logo_x = (w - logo_w) / 2
    logo_y = h * 0.60
    card_pad = 10
    card_x = logo_x - card_pad
    card_y = logo_y - card_pad
    card_w = logo_w + card_pad * 2
    card_h = logo_h + card_pad * 2
    # Solid white card so purple logo is fully visible on dark background
    canvas.setFillColor(C["white"])
    canvas.roundRect(card_x, card_y, card_w, card_h, 8, fill=1, stroke=0)
    canvas.setStrokeColor(C["snow"])
    canvas.setLineWidth(1.5)
    canvas.roundRect(card_x, card_y, card_w, card_h, 8, fill=0, stroke=1)
    if os.path.exists(IMG_GPTFY):
        canvas.drawImage(IMG_GPTFY, logo_x, logo_y,
                         width=logo_w, height=logo_h,
                         mask="auto", preserveAspectRatio=True)
    canvas.setFillColor(C["grey_mid"])
    canvas.setFont("Arial", 7.5)
    canvas.drawCentredString(w/2, card_y + card_h + 5, "Powered by")
    # Main title block
    canvas.setFillColor(C["white"])
    canvas.setFont("Calibri-Bold", 30)
    canvas.drawCentredString(w/2, h * 0.49, "Snowflake  x  Salesforce")
    canvas.setFont("Calibri-Bold", 20)
    canvas.setFillColor(C["blue_light"])
    canvas.drawCentredString(w/2, h * 0.44, "Integration Guide")
    # Accent lines
    canvas.setStrokeColor(C["snow"])
    canvas.setLineWidth(1.5)
    canvas.line(LM, h * 0.38, w - RM, h * 0.38)
    canvas.setStrokeColor(C["sf"])
    canvas.setLineWidth(0.7)
    canvas.line(LM, h * 0.38 - 5, w - RM, h * 0.38 - 5)
    # Subtitle bar
    canvas.setFillColor(colors.Color(0, 0, 0, alpha=0.25))
    canvas.roundRect(LM, h * 0.38 + 12, w - LM - RM, 42, 5, fill=1, stroke=0)
    canvas.setFillColor(C["white"])
    canvas.setFont("Arial", 10)
    canvas.drawCentredString(w/2, h * 0.38 + 36, "Connecting Snowflake with Salesforce via")
    canvas.setFont("Arial-Bold", 10)
    canvas.drawCentredString(w/2, h * 0.38 + 22, "External Data Source  &  GPTfy API Data Source")
    # Bottom meta
    canvas.setFillColor(C["grey_mid"])
    canvas.setFont("Arial", 8)
    canvas.drawCentredString(w/2, 28*mm, "March 2026  -  Internal Technical Documentation  -  Confidential")
    # Bottom accent bar
    canvas.setFillColor(C["snow"])
    canvas.rect(0, 0, w, 6, fill=1, stroke=0)
    canvas.restoreState()
'''

patched = src[:start] + new_block + src[end:]

with open(r'c:\CC\Project_SFDC\Snowflake\generate_pdf.py', 'w', encoding='utf-8') as f:
    f.write(patched)

print("Done. Wrote patched file.")
