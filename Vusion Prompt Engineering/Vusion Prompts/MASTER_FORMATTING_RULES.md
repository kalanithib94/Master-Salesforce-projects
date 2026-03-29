# MASTER HTML FORMATTING RULES
## Complete Styling Guide for Dutch Accountancy Engagement Documents

---

## 1. DOCUMENT STRUCTURE RULES

### 1.1 HTML Output Format
- **START TAG**: `<body style="...">` (NO DOCTYPE, NO `<html>`, NO `<head>`)
- **END TAG**: `</body>`
- **NO** markdown code fences (no ```)
- **NO** explanatory text before or after HTML
- Single continuous HTML string for direct injection

### 1.2 Root Body Styling
```
<body style="font-family:system-ui,-apple-system,'Segoe UI',sans-serif;width:100%;max-width:1400px;margin:0 auto;background:#f8f9fa;padding:0;">
```

**Rules:**
- Font stack: `system-ui,-apple-system,'Segoe UI',sans-serif`
- Max-width: `1400px` (CRITICAL: Always use this exact value)
- Background: `#f8f9fa` (light gray)
- Margin: `0 auto` (center alignment)
- Width: `100%`
- Padding: `0`

### 1.3 Main Container
```
<div style="padding:2rem;background:#ffffff;border-radius:8px;box-shadow:0 2px 8px rgba(0,0,0,0.1);">
```

**Rules:**
- Padding: `2rem`
- Background: `#ffffff` (pure white)
- Border-radius: `8px`
- Box-shadow: `0 2px 8px rgba(0,0,0,0.1)`

---

## 2. HEADER SECTION RULES

### 2.1 Header Container
```
<div style="background:linear-gradient(135deg,#2c3e50 0%,#34495e 100%);padding:1.5rem;border-radius:8px;margin-bottom:2rem;">
```

**Rules:**
- Background: `linear-gradient(135deg,#2c3e50 0%,#34495e 100%)` (dark blue gradient)
- Gradient angle: `135deg`
- Padding: `1.5rem`
- Border-radius: `8px`
- Margin-bottom: `2rem`

### 2.2 Header Inner Flex Container
```
<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:0.75rem;">
```

**Rules:**
- Display: `flex`
- Justify-content: `space-between`
- Align-items: `center`
- Margin-bottom: `0.75rem`

### 2.3 Division Title (Left Side)
```
<div style="font-size:1.75rem;font-weight:700;color:#ffffff;">[Division] Division</div>
```

**Rules:**
- Font-size: `1.75rem`
- Font-weight: `700` (bold)
- Color: `#ffffff` (white)

### 2.4 Powered Badge (Right Side)
```
<div style="background:linear-gradient(135deg,#f39c12 0%,#e67e22 100%);color:#ffffff;padding:0.5rem 1.25rem;border-radius:8px;font-size:0.85rem;font-weight:700;letter-spacing:0.5px;box-shadow:0 2px 4px rgba(0,0,0,0.2);">Powered by TESS × GPTfy</div>
```

**Rules:**
- Background: `linear-gradient(135deg,#f39c12 0%,#e67e22 100%)` (orange gradient)
- Gradient angle: `135deg`
- Color: `#ffffff`
- Padding: `0.5rem 1.25rem` (vertical horizontal)
- Border-radius: `8px`
- Font-size: `0.85rem`
- Font-weight: `700`
- Letter-spacing: `0.5px`
- Box-shadow: `0 2px 4px rgba(0,0,0,0.2)`
- Text: "Powered by TESS × GPTfy" (engagement) or "Powered by TESS × GPTfy.ai" (fiscal)

### 2.5 Subtitle Line
```
<div style="font-size:0.85rem;color:#e0e7ff;">Engagement Confirmation Package</div>
```
OR
```
<div style="font-size:0.85rem;color:#e0e7ff;">Fiscal Advisory Brief • [Year]</div>
```

**Rules:**
- Font-size: `0.85rem`
- Color: `#e0e7ff` (light blue/lavender)

---

## 3. OVERVIEW SECTION RULES

### 3.1 Section Title (H1)
```
<h1 style="font-weight:700;color:#16325c;font-size:1.75rem;margin-bottom:1.5rem;margin-top:0;">📋 Overview</h1>
```

**Rules:**
- Font-weight: `700`
- Color: `#16325c` (dark blue)
- Font-size: `1.75rem`
- Margin-bottom: `1.5rem`
- Margin-top: `0`
- Always include emoji: `📋`

### 3.2 Cards Grid Container
```
<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:1.25rem;margin-bottom:2rem;">
```

**Rules:**
- Display: `grid`
- Grid-template-columns: `repeat(auto-fit,minmax(250px,1fr))`
- Min card width: `250px`
- Gap: `1.25rem`
- Margin-bottom: `2rem`

### 3.3 Card Styling (3 Card Pattern)

**Card 1 - Client (Light Blue Border)**
```
<div style="background:#ffffff;padding:1.25rem;border-radius:6px;border:2px solid #bfdbfe;box-shadow:0 2px 4px rgba(0,0,0,0.08);">
```

**Card 2 - Service/Fiscal Year (Light Purple Border)**
```
<div style="background:#ffffff;padding:1.25rem;border-radius:6px;border:2px solid #e9d5ff;box-shadow:0 2px 4px rgba(0,0,0,0.08);">
```

**Card 3 - Project (Light Green Border)**
```
<div style="background:#ffffff;padding:1.25rem;border-radius:6px;border:2px solid #bbf7d0;box-shadow:0 2px 4px rgba(0,0,0,0.08);">
```

**CRITICAL RULES:**
- Background: `#ffffff` (white)
- Padding: `1.25rem`
- Border-radius: `6px`
- Border: `2px solid [pastel-color]` (MUST be 4-side border, NOT border-left)
- Box-shadow: `0 2px 4px rgba(0,0,0,0.08)`

**Border Colors (Pastel):**
- Blue: `#bfdbfe`
- Purple: `#e9d5ff`
- Green: `#bbf7d0`

### 3.4 Card Label (Uppercase)
```
<div style="font-size:0.7rem;color:#94a3b8;font-weight:600;text-transform:uppercase;letter-spacing:0.5px;margin-bottom:0.25rem;">Client</div>
```

**Rules:**
- Font-size: `0.7rem`
- Color: `#94a3b8` (slate gray)
- Font-weight: `600`
- Text-transform: `uppercase`
- Letter-spacing: `0.5px`
- Margin-bottom: `0.25rem`

### 3.5 Card Main Value
```
<div style="font-size:1rem;font-weight:600;color:#1e3a5f;margin-bottom:0.25rem;">[Account Name]</div>
```

**Rules for Main Value:**
- Font-size: `1rem`
- Font-weight: `600`
- Margin-bottom: `0.25rem`

**Color Rules by Card:**
- Client card: `#1e3a5f` (dark blue)
- Service/Fiscal Year card: `#8b5cf6` (purple)
- Project card: `#10b981` (green)

### 3.6 Card Subtitle
```
<div style="font-size:0.85rem;color:#64748b;">Account #[Account Number]</div>
```

**Rules:**
- Font-size: `0.85rem`
- Color: `#64748b` (gray)

---

## 4. INTELLIGENCE SECTION RULES

### 4.1 Section Title (H2)
```
<h2 style="font-weight:600;color:#16325c;font-size:1.5rem;margin-bottom:1rem;border-bottom:2px solid #0176d3;padding-bottom:0.5rem;">🔍 Client Intelligence</h2>
```
OR
```
<h2 style="font-weight:600;color:#16325c;font-size:1.5rem;margin-bottom:1rem;border-bottom:2px solid #0176d3;padding-bottom:0.5rem;">🔍 Fiscal Intelligence</h2>
```

**Rules:**
- Font-weight: `600`
- Color: `#16325c` (dark blue)
- Font-size: `1.5rem`
- Margin-bottom: `1rem`
- Border-bottom: `2px solid #0176d3` (blue underline)
- Padding-bottom: `0.5rem`
- Emoji: `🔍`

### 4.2 Intelligence Box
```
<div style="background:#f0f7ff;padding:1.5rem;border-radius:6px;border:2px solid #bfdbfe;margin-bottom:2rem;">
```

**CRITICAL RULES:**
- Background: `#f0f7ff` (very light blue)
- Padding: `1.5rem`
- Border-radius: `6px`
- Border: `2px solid #bfdbfe` (MUST be 4-side border, NOT border-left)
- Margin-bottom: `2rem`

### 4.3 Intelligence Text
```
<p style="color:#444;line-height:1.6;margin:0;font-size:0.95rem;">[Generate 2-3 sentence company profile]</p>
```

**Rules:**
- Color: `#444` (dark gray)
- Line-height: `1.6`
- Margin: `0`
- Font-size: `0.95rem`

### 4.4 Subsection Title (H3)
```
<h3 style="font-weight:600;color:#16325c;font-size:1.25rem;margin-bottom:1rem;">Strategic Insights</h3>
```
OR
```
<h3 style="font-weight:600;color:#16325c;font-size:1.25rem;margin-bottom:1rem;">Key Insights</h3>
```

**Rules:**
- Font-weight: `600`
- Color: `#16325c`
- Font-size: `1.25rem`
- Margin-bottom: `1rem`

### 4.5 Insights Box
```
<div style="background:#f8f9fa;padding:1.5rem;border-radius:8px;margin-bottom:2rem;">
```

**Rules:**
- Background: `#f8f9fa` (light gray)
- Padding: `1.5rem`
- Border-radius: `8px`
- Margin-bottom: `2rem`

### 4.6 Insights Text (Bullet List)
```
<div style="font-size:0.9rem;color:#475569;line-height:1.8;">• [Dutch regulatory insight]<br>• [Digital transformation trend]<br>• [Compliance challenge]<br>• [Advisory opportunity]</div>
```

**Rules:**
- Font-size: `0.9rem`
- Color: `#475569` (slate)
- Line-height: `1.8`
- Use bullet: `•` (not HTML list)
- Use `<br>` for line breaks

---

## 5. SECTION HEADER BAR RULES

### 5.1 Dark Gradient Bar (Engagement/Tax Updates)
```
<div style="background:linear-gradient(135deg,#1e3a5f 0%,#0d2137 100%);padding:1.25rem 2rem;border-radius:8px;margin-bottom:1.5rem;">
```

**Rules:**
- Background: `linear-gradient(135deg,#1e3a5f 0%,#0d2137 100%)` (dark blue gradient)
- Gradient angle: `135deg`
- Padding: `1.25rem 2rem` (vertical horizontal)
- Border-radius: `8px`
- Margin-bottom: `1.5rem`

### 5.2 Bar Text
```
<div style="font-size:1rem;color:#fff;letter-spacing:0.1rem;text-transform:uppercase;font-weight:600;text-align:center;">Engagement Confirmation</div>
```
OR
```
<div style="font-size:1rem;color:#fff;letter-spacing:0.1rem;text-transform:uppercase;font-weight:600;text-align:center;">🇳🇱 Tax Updates [Year]</div>
```

**Rules:**
- Font-size: `1rem`
- Color: `#fff`
- Letter-spacing: `0.1rem`
- Text-transform: `uppercase`
- Font-weight: `600`
- Text-align: `center`

---

## 6. CONTENT SECTION RULES (White Box)

### 6.1 White Content Box
```
<div style="background:#ffffff;border-radius:8px;box-shadow:0 2px 8px rgba(0,0,0,0.1);padding:2rem;margin-bottom:2rem;">
```

**Rules:**
- Background: `#ffffff`
- Border-radius: `8px`
- Box-shadow: `0 2px 8px rgba(0,0,0,0.1)`
- Padding: `2rem`
- Margin-bottom: `2rem`

### 6.2 Metadata Line
```
<div style="font-size:0.85rem;color:#64748b;margin-bottom:1.25rem;"><strong>Date:</strong> [Date] &nbsp;|&nbsp; <strong>Ref:</strong> [Record ID]</div>
```

**Rules:**
- Font-size: `0.85rem`
- Color: `#64748b`
- Margin-bottom: `1.25rem`
- Use `&nbsp;|&nbsp;` for separator

### 6.3 Salutation
```
<p style="font-size:0.9rem;color:#475569;margin:0 0 0.75rem;">Dear [Contact or "Valued Client"],</p>
```

**Rules:**
- Font-size: `0.9rem`
- Color: `#475569`
- Margin: `0 0 0.75rem`

### 6.4 Subject Line (RE:)
```
<p style="font-size:1rem;color:#16325c;font-weight:700;margin:0 0 1.25rem;">RE: [Work Name] — [Service]</p>
```

**Rules:**
- Font-size: `1rem`
- Color: `#16325c`
- Font-weight: `700`
- Margin: `0 0 1.25rem`
- Use em dash: `—` (not hyphen)

---

## 7. NUMBERED SECTION HEADERS

### 7.1 Section Header with Badge
```
<div style="font-size:1rem;font-weight:700;color:#16325c;margin-bottom:0.75rem;"><span style="display:inline-block;background:#0176d3;color:#fff;width:1.5rem;height:1.5rem;border-radius:50%;text-align:center;line-height:1.5rem;font-size:0.75rem;margin-right:0.5rem;">1</span>Scope</div>
```

**Rules for Container:**
- Font-size: `1rem`
- Font-weight: `700`
- Color: `#16325c`
- Margin-bottom: `0.75rem`

**Rules for Badge:**
- Display: `inline-block`
- Background: `#0176d3` (blue)
- Color: `#fff`
- Width: `1.5rem`
- Height: `1.5rem`
- Border-radius: `50%` (circle)
- Text-align: `center`
- Line-height: `1.5rem`
- Font-size: `0.75rem`
- Margin-right: `0.5rem`

---

## 8. TABLE RULES

### 8.1 Table Base Styling
```
<table cellpadding="0" cellspacing="0" width="100%" style="border-collapse:collapse;margin-bottom:1rem;">
```

**Rules:**
- Cellpadding: `0`
- Cellspacing: `0`
- Width: `100%`
- Border-collapse: `collapse`
- Margin-bottom: `1rem`

### 8.2 Table Header (TH)
```
<th style="background:#f8f9fa;padding:0.75rem 1rem;text-align:left;font-size:0.75rem;border:1px solid #e2e8f0;width:28%;color:#64748b;font-weight:600;">Service</th>
```

**Rules:**
- Background: `#f8f9fa` (light gray)
- Padding: `0.75rem 1rem`
- Text-align: `left`
- Font-size: `0.75rem`
- Border: `1px solid #e2e8f0`
- Width: `28%` (for first column, omit for others)
- Color: `#64748b`
- Font-weight: `600`

### 8.3 Table Data (TD)
```
<td style="padding:0.75rem 1rem;font-size:0.9rem;border:1px solid #e2e8f0;color:#1e293b;">[Service]</td>
```

**Rules:**
- Padding: `0.75rem 1rem`
- Font-size: `0.9rem`
- Border: `1px solid #e2e8f0`
- Color: `#1e293b`

---

## 9. SIGNATURE SECTION RULES

### 9.1 Signature Container
```
<div style="padding-top:1.5rem;border-top:2px solid #e2e8f0;margin-top:1.5rem;">
```

**Rules:**
- Padding-top: `1.5rem`
- Border-top: `2px solid #e2e8f0`
- Margin-top: `1.5rem`

### 9.2 Closing Text
```
<p style="font-size:0.9rem;color:#475569;margin:0;">Yours sincerely,<br><strong style="color:#16325c;">[Division] Division</strong></p>
```

**Rules:**
- Font-size: `0.9rem`
- Color: `#475569`
- Margin: `0`
- Strong color: `#16325c`

### 9.3 Signature Line
```
<div style="width:12.5rem;border-bottom:2px solid #1e293b;margin:2.5rem 0 0.5rem;"></div>
```

**Rules:**
- Width: `12.5rem`
- Border-bottom: `2px solid #1e293b`
- Margin: `2.5rem 0 0.5rem`

### 9.4 Signature Label
```
<div style="font-size:0.75rem;color:#64748b;">Client Signature & Date</div>
```

**Rules:**
- Font-size: `0.75rem`
- Color: `#64748b`

---

## 10. INTERNAL SECTION RULES (Yellow)

### 10.1 Internal Container
```
<div style="background:linear-gradient(135deg,#fffbeb 0%,#fef9c3 100%);border-radius:8px;padding:1.5rem;border:1px solid #fde68a;margin-bottom:2rem;">
```

**Rules:**
- Background: `linear-gradient(135deg,#fffbeb 0%,#fef9c3 100%)` (yellow gradient)
- Gradient angle: `135deg`
- Border-radius: `8px`
- Padding: `1.5rem`
- Border: `1px solid #fde68a`
- Margin-bottom: `2rem`

### 10.2 Internal Badge
```
<span style="display:inline-block;background:#b45309;color:#fff;font-size:0.7rem;font-weight:700;padding:0.35rem 0.85rem;border-radius:6px;margin-bottom:1rem;">⚠️ INTERNAL ONLY</span>
```

**Rules:**
- Display: `inline-block`
- Background: `#b45309` (orange/brown)
- Color: `#fff`
- Font-size: `0.7rem`
- Font-weight: `700`
- Padding: `0.35rem 0.85rem`
- Border-radius: `6px`
- Margin-bottom: `1rem`
- Emoji: `⚠️`

### 10.3 Internal Section Title
```
<h2 style="font-weight:600;color:#78350f;font-size:1.5rem;margin:0 0 1rem 0;">📊 Team Notes</h2>
```
OR
```
<h2 style="font-weight:600;color:#78350f;font-size:1.5rem;margin:0 0 1rem 0;">📊 Engagement Status</h2>
```

**Rules:**
- Font-weight: `600`
- Color: `#78350f` (brown)
- Font-size: `1.5rem`
- Margin: `0 0 1rem 0`
- Emoji: `📊`

### 10.4 Internal Stats Grid
```
<div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:0.75rem;margin-bottom:1.5rem;">
```

**Rules:**
- Display: `grid`
- Grid-template-columns: `repeat(auto-fit,minmax(140px,1fr))`
- Min width: `140px`
- Gap: `0.75rem`
- Margin-bottom: `1.5rem`

### 10.5 Internal Stat Card
```
<div style="background:#ffffff;padding:1rem;border-radius:6px;text-align:center;border:1px solid #fde68a;">
```

**Rules:**
- Background: `#ffffff`
- Padding: `1rem`
- Border-radius: `6px`
- Text-align: `center`
- Border: `1px solid #fde68a`

### 10.6 Stat Label
```
<div style="font-size:0.7rem;color:#92400e;text-transform:uppercase;font-weight:600;letter-spacing:0.5px;margin-bottom:0.25rem;">Open Items</div>
```

**Rules:**
- Font-size: `0.7rem`
- Color: `#92400e` (brown)
- Text-transform: `uppercase`
- Font-weight: `600`
- Letter-spacing: `0.5px`
- Margin-bottom: `0.25rem`

### 10.7 Stat Value
```
<div style="font-size:1.75rem;font-weight:700;color:#78350f;">[Items]</div>
```

**Rules:**
- Font-size: `1.75rem`
- Font-weight: `700`
- Color: `#78350f`

### 10.8 Risk Alert Box
```
<div style="background:#fef9c3;border:1px solid #fde047;border-radius:6px;padding:1rem 1.25rem;margin-bottom:1rem;">
```

**Rules:**
- Background: `#fef9c3` (light yellow)
- Border: `1px solid #fde047` (yellow)
- Border-radius: `6px`
- Padding: `1rem 1.25rem`
- Margin-bottom: `1rem`

### 10.9 Risk Indicator Dot
```
<span style="display:inline-block;width:0.625rem;height:0.625rem;background:#eab308;border-radius:50%;margin-right:0.75rem;"></span>
```

**Rules:**
- Display: `inline-block`
- Width: `0.625rem`
- Height: `0.625rem`
- Background: `#eab308` (amber)
- Border-radius: `50%`
- Margin-right: `0.75rem`

### 10.10 Risk Text
```
<span style="font-size:0.85rem;font-weight:600;color:#854d0e;">[Risk assessment]</span>
```

**Rules:**
- Font-size: `0.85rem`
- Font-weight: `600`
- Color: `#854d0e` (brown)

### 10.11 Actions Title
```
<div style="font-size:1rem;font-weight:700;color:#78350f;margin-bottom:0.75rem;">Actions</div>
```
OR
```
<div style="font-size:1rem;font-weight:700;color:#78350f;margin-bottom:0.75rem;">Next Steps</div>
```

**Rules:**
- Font-size: `1rem`
- Font-weight: `700`
- Color: `#78350f`
- Margin-bottom: `0.75rem`

### 10.12 Actions List
```
<div style="font-size:0.85rem;color:#78350f;line-height:1.8;">• [Action 1]<br>• [Action 2]<br>• [Action 3]</div>
```

**Rules:**
- Font-size: `0.85rem`
- Color: `#78350f`
- Line-height: `1.8`
- Use bullet: `•`
- Use `<br>` for line breaks

---

## 11. TAX UPDATES SECTION (Fiscal Only)

### 11.1 Opportunities Box (Green Gradient)
```
<div style="background:linear-gradient(135deg,#ecfdf5 0%,#d1fae5 100%);border-radius:8px;padding:1.5rem;border:1px solid #a7f3d0;margin-bottom:1.5rem;">
```

**Rules:**
- Background: `linear-gradient(135deg,#ecfdf5 0%,#d1fae5 100%)` (green gradient)
- Border-radius: `8px`
- Padding: `1.5rem`
- Border: `1px solid #a7f3d0` (green)
- Margin-bottom: `1.5rem`

### 11.2 Opportunities Text
```
<div style="font-size:0.9rem;color:#047857;line-height:1.8;"><strong>1.</strong> [Opportunity]<br><strong>2.</strong> [Opportunity]<br><strong>3.</strong> [Opportunity]</div>
```

**Rules:**
- Font-size: `0.9rem`
- Color: `#047857` (dark green)
- Line-height: `1.8`
- Use `<strong>` for numbers
- Use `<br>` for line breaks

---

## 12. FOOTER RULES

### 12.1 Footer Text
```
<div style="text-align:center;padding:1rem;font-size:0.75rem;color:#94a3b8;">Generated by <strong style="color:#64748b;">GPTfy.ai</strong> • <strong style="color:#64748b;">TESS</strong> • <strong style="color:#16325c;">Acuity BV</strong></div>
```

**Rules:**
- Text-align: `center`
- Padding: `1rem`
- Font-size: `0.75rem`
- Color: `#94a3b8` (light gray)
- Strong color: `#64748b` (for GPTfy.ai and TESS)
- Strong color: `#16325c` (for Acuity BV)
- Separator: `•` with spaces

**CRITICAL:**
- Always use: "GPTfy.ai" (with lowercase 'a' and 'i')
- Never use: "GPTfy AI" or "GPTfy" alone
- Always: "TESS" and "Acuity BV"

---

## 13. COMPLETE COLOR PALETTE

### 13.1 Primary Colors
- Dark Blue (Headers): `#16325c`
- Navy Blue (Text): `#1e3a5f`
- Slate: `#475569`
- Gray: `#64748b`
- Light Slate: `#94a3b8`
- Very Light Gray: `#f8f9fa`
- White: `#ffffff`

### 13.2 Accent Colors
- Blue: `#0176d3`
- Purple: `#8b5cf6`
- Green: `#10b981`
- Amber: `#eab308`
- Orange: `#f39c12`, `#e67e22`
- Brown: `#78350f`, `#854d0e`, `#92400e`, `#b45309`

### 13.3 Pastel/Border Colors
- Light Blue: `#bfdbfe`, `#e0e7ff`, `#f0f7ff`
- Light Purple: `#e9d5ff`
- Light Green: `#bbf7d0`, `#ecfdf5`, `#d1fae5`, `#a7f3d0`
- Light Yellow: `#fffbeb`, `#fef9c3`, `#fde68a`, `#fde047`
- Border Gray: `#e2e8f0`

### 13.4 Gradient Start/End Colors
- Dark Gradient: `#2c3e50` → `#34495e`
- Dark Blue Gradient: `#1e3a5f` → `#0d2137`
- Orange Gradient: `#f39c12` → `#e67e22`
- Yellow Gradient: `#fffbeb` → `#fef9c3`
- Green Gradient: `#ecfdf5` → `#d1fae5`

### 13.5 Specific Color Mapping
- Dark text: `#1e293b`, `#444`
- Shadow: `rgba(0,0,0,0.1)`, `rgba(0,0,0,0.08)`, `rgba(0,0,0,0.2)`

---

## 14. TYPOGRAPHY RULES

### 14.1 Font Sizes
- Extra Large: `1.75rem` (H1, header title)
- Large: `1.5rem` (H2)
- Medium-Large: `1.25rem` (H3)
- Medium: `1rem` (body, section headers)
- Small-Medium: `0.95rem` (intelligence text)
- Small: `0.9rem` (table, insights)
- Extra Small: `0.85rem` (metadata, badge)
- Tiny: `0.75rem` (labels, footer)
- Ultra Tiny: `0.7rem` (card labels, internal labels)

### 14.2 Font Weights
- Bold: `700`
- Semi-bold: `600`
- Normal: (default, no weight specified)

### 14.3 Line Heights
- Compact: `1.5rem` (for badges)
- Standard: `1.6` (intelligence text)
- Comfortable: `1.7`, `1.8`, `1.9` (insights, lists)

### 14.4 Letter Spacing
- Wide: `0.5px` (card labels, internal labels)
- Extra Wide: `0.1rem` (section bar headers)

---

## 15. SPACING RULES

### 15.1 Padding
- Large: `2rem` (main container, white box)
- Medium: `1.5rem` (header, intelligence box, insights box)
- Standard: `1.25rem` (cards, signature line padding)
- Small: `1rem` (internal stats, padding general)
- Tiny: `0.75rem 1rem` (table cells)
- Extra Tiny: `0.5rem 1.25rem` (badge)
- Badge specific: `0.35rem 0.85rem` (internal badge)

### 15.2 Margin
- Large: `2rem` (sections)
- Medium: `1.5rem` (bar, internal grid)
- Standard: `1rem` (subsections, tables)
- Small: `0.75rem` (section headers, actions)
- Tiny: `0.5rem` (signature line)
- Extra Tiny: `0.25rem` (card elements)

### 15.3 Gaps
- Large: `1.25rem` (overview cards)
- Small: `0.75rem` (internal stats)

---

## 16. BORDER & RADIUS RULES

### 16.1 Border Width
- Thick: `2px` (cards, intelligence box, signature top)
- Standard: `1px` (tables, internal elements)
- Underline: `2px` (section title underlines)
- Strong: `4px` (NEVER use for card borders - deprecated)

### 16.2 Border Radius
- Large: `12px` (NEVER use - deprecated in favor of 8px)
- Standard: `8px` (containers, header, bars)
- Medium: `6px` (cards, boxes, internal badges)
- Circle: `50%` (badges, dots)

### 16.3 CRITICAL BORDER RULE
**ALL overview cards and intelligence boxes MUST use:**
```
border:2px solid [color]
```
**NEVER use:**
```
border-left:4px solid [color]
```
This is a critical requirement that must never be violated.

---

## 17. SHADOW RULES

### 17.1 Box Shadows
- Standard container: `0 2px 8px rgba(0,0,0,0.1)`
- Card/small element: `0 2px 4px rgba(0,0,0,0.08)`
- Badge: `0 2px 4px rgba(0,0,0,0.2)`

---

## 18. LAYOUT PATTERNS

### 18.1 CSS Grid Usage
**Overview Cards (3-column responsive):**
```
display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:1.25rem;
```

**Internal Stats (3-column responsive):**
```
display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:0.75rem;
```

### 18.2 Flexbox Usage
**Header (space-between):**
```
display:flex;justify-content:space-between;align-items:center;
```

### 18.3 Table Layout (version2.md specific)
- Use nested tables for card-like layouts
- 49% width columns with 2% gap
- White background with borders and shadows

---

## 19. DATA FORMATTING STANDARDS

### 19.1 Currency
- Format: `€X,XXX.XX`
- Symbol: `€` (euro sign)
- Decimals: Always 2 decimals
- Example: `€1,250.00`, `€0.00`

### 19.2 Hours
- Format: `X.XX hours` or `X.XX`
- Decimals: Always 2 decimals
- Example: `15.00 hours`, `0.00`

### 19.3 Dates
- Format: `DD Month YYYY`
- Example: `18 November 2025`
- Month: Full name, not abbreviated
- Quarters: `Q1 2025`, `Q2 2025`, etc.

### 19.4 Tax Rates
- Format: `XX.X%` or `XX%`
- Decimals: 1-2 as needed
- Example: `25.8%`, `21%`

### 19.5 Account Numbers
- Display as-is, no formatting
- Example: `521521`

### 19.6 Record IDs
- Use last 6-8 characters
- Example: `a0MAP000006UEgP`

### 19.7 Zero Values
- Always display, never hide
- Currency: `€0.00`
- Hours: `0.00 hours` or `0.00`

---

## 20. CONTENT PLACEHOLDER RULES

### 20.1 Bracket Placeholders
**Always replace these with actual data:**
- `[Division]`
- `[Account Name]`
- `[Account Number]`
- `[Service]`
- `[Work Name]`
- `[Year]`
- `[Expected Hours]`
- `[Budget]`
- `[Date]`
- `[Record ID]`
- `[Contact or "Valued Client"]`
- `[Items]`
- `[Todos]`
- `[Balance]` or `[Hours]`

### 20.2 AI-Generated Content Placeholders
**Must be replaced with AI-generated content:**
- `[Generate 2-3 sentence company profile]`
- `[Generate 2-3 sentence fiscal profile]`
- `[Dutch regulatory insight]`
- `[Digital transformation trend]`
- `[Compliance challenge]`
- `[Advisory opportunity]`
- `[VPB insight]`
- `[BTW insight]`
- `[Payroll Tax insight]`
- `[Strategic opportunity]`
- `[Risk assessment]`
- `[Action 1]`, `[Action 2]`, `[Action 3]`
- `[Opportunity]`
- `[Change]`, `[Impact]`

### 20.3 CRITICAL VALIDATION
**Before output, verify:**
- ✓ NO brackets `[]` remain in output
- ✓ NO "undefined" or "null" values
- ✓ All currency formatted with `€`
- ✓ All hours show 2 decimals
- ✓ All dates in Dutch format
- ✓ All AI content is meaningful and specific

---

## 21. RESPONSIVE DESIGN RULES

### 21.1 Max-Width Strategy
- Container: `max-width:1400px;margin:0 auto;`
- Never exceed 1400px
- Always center with `margin:0 auto`

### 21.2 Grid Responsiveness
- Use `repeat(auto-fit,minmax(Xpx,1fr))`
- Overview cards: minimum 250px
- Internal stats: minimum 140px
- Automatically wraps on smaller screens

### 21.3 Rem-Based Typography
- All font-sizes use `rem` units
- Scales proportionally
- Base: `1rem` = body text size

---

## 22. SPECIAL CHARACTER RULES

### 22.1 Emojis (Always Include)
- 📋 Overview section
- 🔍 Intelligence sections
- 🇳🇱 Dutch Tax Updates (fiscal only)
- 💡 Opportunities section
- 📅 Deadlines section
- 📊 Team Notes/Engagement Status
- ⚠️ Internal Only badge

### 22.2 Special Characters
- Em dash: `—` (not hyphen)
- Bullet: `•` (not asterisk)
- Non-breaking space: `&nbsp;`
- Separator: ` • ` (bullet with spaces)
- Multiply: `×` (in "TESS × GPTfy")

---

## 23. DOCUMENT VARIANTS

### 23.1 Engagement Letter Specific
- Subtitle: "Engagement Confirmation Package"
- Badge text: "Powered by TESS × GPTfy" (or "Powered by TESS × GPTfy.ai" - both acceptable)
- Cards: Client, Service, Project
- Section: "Client Intelligence"
- Subsection: "Strategic Insights"
- Includes: Engagement Confirmation section with scope/timeline
- Internal section: "Team Notes"
- Stats: Open Items, Open Todos, Balance Hrs
- Footer: "Generated by GPTfy.ai • TESS • Acuity BV"

### 23.2 Fiscal Advisory Specific
- Subtitle: "Fiscal Advisory Brief • [Year]"
- Badge text: "Powered by TESS × GPTfy.ai"
- Cards: Client, Fiscal Year, Project
- Section: "Fiscal Intelligence"
- Subsection: "Key Insights"
- Includes: Tax Updates section with VPB/BTW/LH table
- Includes: Opportunities section (green gradient box)
- Includes: Deadlines section (table)
- Internal section: "Engagement Status"
- Stats: Open Items, Open Todos, Total Hours
- Footer: "Generated by GPTfy.ai • TESS • Acuity BV"

**IMPORTANT NOTE ON BRANDING:**
- Header badge can say "Powered by TESS × GPTfy" OR "Powered by TESS × GPTfy.ai"
- Footer MUST always say "Generated by GPTfy.ai • TESS • Acuity BV" (with .ai)

---

## 24. QUALITY STANDARDS

### 24.1 Professional Tone
- Dutch accountancy context
- Formal language
- Technical accuracy
- Actionable insights

### 24.2 Consistency Requirements
- All cards same height (auto with CSS Grid)
- All borders same width (2px for cards, 1px for tables)
- All colors from approved palette
- All spacing from defined rules

### 24.3 Testing Checklist
- ✓ Visual consistency with reference designs
- ✓ Responsive layout works at all widths
- ✓ No overflow or layout breaks
- ✓ Colors match exactly (use hex codes)
- ✓ Shadows render correctly
- ✓ Gradients display smoothly
- ✓ Borders are full 4-sides, not left-only
- ✓ Typography scales properly

---

## 25. PROHIBITED PATTERNS

### 25.1 NEVER Use These
- ❌ `border-left:4px solid` (use `border:2px solid` instead)
- ❌ `max-width:1200px` (use `1400px` instead)
- ❌ `max-width:1800px` (use `1400px` instead)
- ❌ `border-radius:12px` for cards (use `8px` or `6px`)
- ❌ DOCTYPE declaration
- ❌ `<html>` tag
- ❌ `<head>` tag
- ❌ External CSS references
- ❌ Markdown code fences
- ❌ Explanatory text outside HTML
- ❌ Placeholder brackets in final output
- ❌ "undefined" or "null" values
- ❌ HTML list elements `<ul>/<li>` (use div with bullets)
- ❌ 4-card layout (always 3 cards)

### 25.2 ALWAYS Use These
- ✅ `<body>` as opening tag
- ✅ Inline styles only
- ✅ Full 4-side borders for cards
- ✅ Pastel colors for card borders
- ✅ `max-width:1400px`
- ✅ CSS Grid for cards
- ✅ 3-card layout
- ✅ All data formatted properly
- ✅ All placeholders replaced
- ✅ All emojis included
- ✅ Professional Dutch content

---

## 26. VERSION CONTROL NOTES

### 26.1 Current Standard (v3)
- Uses: div + CSS Grid layout
- Border style: `border:2px solid [pastel]`
- Max-width: `1400px`
- Card count: 3 cards
- Border radius: `8px` main, `6px` cards
- Status: **CURRENT APPROVED STANDARD**

### 26.2 Deprecated (v2)
- Uses: table-based layout
- Border style: `border:1px solid #e2e8f0`
- Max-width: varied
- Card count: 4 cards
- Status: **DEPRECATED - DO NOT USE**

### 26.3 Deprecated (v1 old)
- Border style: `border-left:4px solid [color]`
- Status: **DEPRECATED - DO NOT USE**

---

## 27. IMPLEMENTATION PRIORITY

### 27.1 Critical (Must Never Violate)
1. Start with `<body>`, not DOCTYPE
2. Use `max-width:1400px`
3. Use `border:2px solid [pastel]` for all cards
4. Replace ALL placeholders
5. Include ALL emojis
6. Use 3-card layout
7. No external CSS
8. Professional Dutch content

### 27.2 High Priority (Very Important)
1. Exact color codes from palette
2. Exact spacing values (rem)
3. Gradient angles (135deg)
4. Typography sizing
5. Shadow values
6. Border radius values

### 27.3 Standard Priority (Important)
1. Line heights
2. Letter spacing
3. Specific margin/padding values
4. Footer format
5. Table styling details

---

## 28. FINAL VALIDATION CHECKLIST

Before delivering ANY HTML output, verify:

**Structure:**
- ✅ Starts with `<body style="...">`
- ✅ Ends with `</body>`
- ✅ No DOCTYPE, html, or head tags
- ✅ All tags properly closed
- ✅ No markdown fences

**Styling:**
- ✅ Max-width is 1400px
- ✅ All borders are 4-side (not left-only)
- ✅ All card borders use pastel colors
- ✅ All colors from approved palette
- ✅ All gradients at 135deg
- ✅ All shadows match specifications

**Content:**
- ✅ No brackets [] remaining
- ✅ No "undefined" or "null"
- ✅ All currency formatted (€X,XXX.XX)
- ✅ All hours with 2 decimals
- ✅ All dates in Dutch format
- ✅ All emojis present

**Layout:**
- ✅ 3 cards in overview (not 4)
- ✅ CSS Grid used (not tables) for cards
- ✅ Responsive design works
- ✅ All sections in correct order

**Tone:**
- ✅ Professional Dutch accountancy language
- ✅ Specific insights (not generic)
- ✅ Actionable recommendations
- ✅ Technically accurate

---

## END OF MASTER FORMATTING RULES

**Last Updated:** December 9, 2025
**Version:** 3.0 (Current Standard)
**Status:** Production Ready
**Approved For:** All future Dutch accountancy engagement documents

**CRITICAL REMINDER:** These rules are absolute. Every HTML output MUST comply with these specifications. No exceptions. No deviations. No shortcuts.
