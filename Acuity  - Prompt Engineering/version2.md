Generate a professional HTML engagement letter for a Dutch accountancy firm using the provided TESS JSON data. Output ONLY the complete HTML document - no markdown, no explanations, no code blocks.

## CRITICAL RULES:
1. Use TABLE-based layouts with inline styles only (no external CSS)
2. Replace ALL [bracketed placeholders] with actual data from JSON or AI-generated content
3. Use responsive layout: max-width: 1400px on body, padding: 2rem, rem-based typography for scalability
4. Ensure professional Dutch accountancy standards and terminology
5. NEVER leave any placeholder brackets [] in the final output

## DATA MAPPING (JSON → HTML Placeholders):
Use these exact mappings from the provided JSON data:
- [Division] → tess__Division__c OR tess__DivisionText__c
- [Account Name] → tess__AccountName__c
- [Account Number] → tess__AccountNumber__c
- [Service] → Name (Work name)
- [Work Name] → Name OR tess__CalculatedName__c
- [Expected Hours] → tess__EstimatedHours__c (format: "X.XX hours")
- [Budget] → tess__Budget__c (format as EUR amount)
- [Date] → CreatedDate (format: DD Month YYYY, e.g., "18 November 2025")
- [Record ID] → Id (last 6-8 characters)
- [Contact or "Valued Client"] → Use "Valued Client" if no contact provided
- [Items] → tess__OpenItems__c
- [Todos] → tess__OpenTodos__c
- [Balance] → tess__BalanceExpectedHours__c (format: "X.XX")

## AI-GENERATED CONTENT REQUIREMENTS:

### 🔍 Client Intelligence Section:
Generate a professional 2-3 sentence company profile based on:
- Company name (tess__AccountName__c)
- Account type (tess__AccountType__c)
- Division context (tess__Division__c)
Include: industry sector, size indication (if derivable), and primary business activity.
Example: "Acuity B.V. is a leading Dutch accountancy firm specializing in comprehensive financial services, tax advisory, and business consulting for SMEs and corporate clients across the Netherlands. With a focus on digital transformation, the firm serves clients in technology, retail, and professional services sectors."

### Strategic Insights (4 bullet points):
Generate 4 specific, actionable insights relevant to Dutch accountancy:
1. **Dutch regulatory insight** - Reference to WTA (Wet toezicht accountantsorganisaties), GDPR, or relevant Dutch tax law
2. **Digital transformation trend** - E-invoicing (mandatory in NL), automated bookkeeping, AI in accounting
3. **Compliance challenge** - Specific to the work type/division (e.g., VAT reporting, annual accounts filing)
4. **Advisory opportunity** - Value-added service suggestion (e.g., financial forecasting, sustainability reporting, succession planning)

Make these professional, specific, and relevant to the current engagement context.

### 📊 Team Notes - Risk Assessment:
Analyze the provided data and generate a concise risk statement based on:
- If tess__OpenItems__c > 0: "Outstanding documentation required - follow up on [X] open items"
- If tess__OpenTodos__c > 3: "High task volume - prioritize critical deliverables"
- If tess__Budget__c = 0 OR tess__EstimatedHours__c = 0: "Scope and budget finalization needed - schedule scoping meeting"
- If tess__BalanceExpectedHours__c < 0: "Over-budget risk - review scope with client"
- Default: "Standard engagement - proceed with regular monitoring"

### Actions (3 specific items):
Generate 3 concrete action items based on the engagement data:
- If tess__OpenItems__c > 0: "Review and complete [X] outstanding documentation items by [date+7 days]"
- If tess__OpenTodos__c > 0: "Address [X] pending tasks - assign ownership by [date+3 days]"
- If tess__EstimatedHours__c = 0: "Schedule scoping call to define hours estimate and deliverables"
- If tess__DoInvoice__c = "No": "Clarify invoicing terms and payment schedule with client"
- Always include: "Schedule kick-off meeting within 5 business days"
- Always include: "Confirm client contact person and communication preferences"

## FORMATTING STANDARDS:
- Currency: Always use EUR format (e.g., "€1,250.00")
- Hours: Always show 2 decimals (e.g., "15.00" not "15")
- Dates: Dutch long format (e.g., "18 November 2025")
- Zero values: Display as "€0.00" or "0.00 hours" (never hide)
- Account numbers: Display as-is without formatting

## VALIDATION CHECKLIST (Ensure before output):
✓ All [bracketed placeholders] replaced with real data or generated content
✓ No "undefined" or "null" values visible
✓ Client Intelligence section has meaningful company description
✓ Strategic Insights contains 4 specific, relevant points
✓ Risk Assessment provides actionable guidance
✓ Actions section lists 3 concrete, dated tasks
✓ All currency values formatted with EUR symbol
✓ Professional Dutch accountancy tone maintained throughout

## OUTPUT REQUIREMENTS:
- Output ONLY the HTML document starting with <!DOCTYPE html>
- NO markdown code fences (no ```)
- NO explanatory text before or after the HTML
- Complete, valid HTML that can render immediately in a browser

<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"></head>
<body style="font-family:system-ui,-apple-system,'Segoe UI',sans-serif;width:100%;max-width:1400px;margin:0 auto;background:#f3f4f6;padding:0;">
<table cellpadding="0" cellspacing="0" width="100%" style="width:100%;">
<tr><td style="padding:2rem;">

<table cellpadding="0" cellspacing="0" width="100%" style="background:linear-gradient(135deg,#1e3a5f 0%,#0d2137 100%);border-radius:12px;margin-bottom:1.5rem;">
<tr><td style="padding:1.5rem 2rem;">
<table cellpadding="0" cellspacing="0" width="100%"><tr>
<td><div style="font-size:28px;font-weight:700;color:#fff;">[Division]</div>
<div style="font-size:14px;color:rgba(255,255,255,0.85);margin-top:8px;">Engagement Confirmation Package</div>
<div style="margin-top:16px;"><span style="display:inline-block;background:rgba(255,255,255,0.15);padding:8px 16px;border-radius:6px;font-size:13px;color:#fff;margin-right:10px;">[Service]</span><span style="display:inline-block;background:rgba(255,255,255,0.15);padding:8px 16px;border-radius:6px;font-size:13px;color:#fff;">Active</span></div></td>
<td style="text-align:right;vertical-align:top;"><div style="font-size:11px;color:rgba(255,255,255,0.6);">Powered by</div><div style="font-size:16px;font-weight:700;color:#fff;">TESS × GPTfy</div></td>
</tr></table></td></tr></table>

<table cellpadding="0" cellspacing="0" width="100%" style="background:#fff;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.1);margin-bottom:1.5rem;">
<tr><td style="padding:1.5rem 2rem;">
<div style="font-size:1.5rem;font-weight:700;color:#16325c;margin-bottom:1rem;padding-bottom:0.5rem;border-bottom:2px solid #0176d3;">📋 Overview</div>
<table cellpadding="0" cellspacing="0" width="100%">
<tr><td width="49%"><table cellpadding="0" cellspacing="0" width="100%" style="background:#fff;border:1px solid #e2e8f0;border-radius:6px;box-shadow:0 2px 4px rgba(0,0,0,0.08);"><tr><td style="padding:1.25rem;"><div style="font-size:0.7rem;color:#94a3b8;text-transform:uppercase;letter-spacing:0.5px;font-weight:600;margin-bottom:0.5rem;">Client</div><div style="font-size:1rem;color:#1e3a5f;font-weight:700;">[Account Name]</div></td></tr></table></td><td width="2%"></td><td width="49%"><table cellpadding="0" cellspacing="0" width="100%" style="background:#fff;border:1px solid #e2e8f0;border-radius:6px;box-shadow:0 2px 4px rgba(0,0,0,0.08);"><tr><td style="padding:1.25rem;"><div style="font-size:0.7rem;color:#94a3b8;text-transform:uppercase;letter-spacing:0.5px;font-weight:600;margin-bottom:0.5rem;">Account #</div><div style="font-size:1rem;color:#1e293b;font-weight:600;">[Account Number]</div></td></tr></table></td></tr>
<tr><td colspan="3" style="height:1rem;"></td></tr>
<tr><td width="49%"><table cellpadding="0" cellspacing="0" width="100%" style="background:#fff;border:1px solid #e2e8f0;border-radius:6px;box-shadow:0 2px 4px rgba(0,0,0,0.08);"><tr><td style="padding:1.25rem;"><div style="font-size:0.7rem;color:#94a3b8;text-transform:uppercase;letter-spacing:0.5px;font-weight:600;margin-bottom:0.5rem;">Service</div><div style="font-size:1rem;color:#1e293b;font-weight:600;">[Service]</div></td></tr></table></td><td width="2%"></td><td width="49%"><table cellpadding="0" cellspacing="0" width="100%" style="background:#fff;border:1px solid #e2e8f0;border-radius:6px;box-shadow:0 2px 4px rgba(0,0,0,0.08);"><tr><td style="padding:1.25rem;"><div style="font-size:0.7rem;color:#94a3b8;text-transform:uppercase;letter-spacing:0.5px;font-weight:600;margin-bottom:0.5rem;">Project</div><div style="font-size:1rem;color:#1e293b;font-weight:600;">[Work Name]</div></td></tr></table></td></tr>
</table></td></tr></table>

<table cellpadding="0" cellspacing="0" width="100%" style="background:#fff;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.1);margin-bottom:1.5rem;">
<tr><td style="padding:1.5rem 2rem;">
<div style="margin-bottom:1rem;"><span style="font-size:1.5rem;font-weight:700;color:#16325c;">🔍 Client Intelligence</span><span style="display:inline-block;background:linear-gradient(135deg,#1e3a5f 0%,#0d2137 100%);color:#fff;font-size:0.7rem;font-weight:700;padding:0.35rem 0.75rem;border-radius:6px;margin-left:0.75rem;">AI-POWERED</span></div>
<table cellpadding="0" cellspacing="0" width="100%" style="background:#f0f7ff;border:2px solid #bfdbfe;border-radius:6px;margin-bottom:1rem;"><tr><td style="padding:1.25rem 1.5rem;font-size:0.95rem;color:#444;line-height:1.6;">[Generate 2-3 sentence company profile]</td></tr></table>
<div style="font-size:1.125rem;font-weight:700;color:#16325c;margin-bottom:0.75rem;border-bottom:2px solid #0176d3;padding-bottom:0.5rem;">Strategic Insights</div>
<div style="font-size:0.9rem;color:#475569;line-height:1.8;">• [Dutch regulatory insight]<br>• [Digital transformation trend]<br>• [Compliance challenge]<br>• [Advisory opportunity]</div>
</td></tr></table>

<table cellpadding="0" cellspacing="0" width="100%" style="background:#fff;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.1);overflow:hidden;margin-bottom:1.5rem;">
<tr><td style="background:linear-gradient(135deg,#1e3a5f 0%,#0d2137 100%);padding:1.25rem 2rem;text-align:center;"><div style="font-size:1rem;color:#fff;letter-spacing:0.1rem;text-transform:uppercase;font-weight:600;">Engagement Confirmation</div></td></tr>
<tr><td style="padding:1.5rem 2rem;">
<div style="font-size:0.85rem;color:#64748b;margin-bottom:1.25rem;"><strong>Date:</strong> [Date] &nbsp;|&nbsp; <strong>Ref:</strong> [Record ID]</div>
<p style="font-size:0.9rem;color:#475569;margin:0 0 0.75rem;">Dear [Contact or "Valued Client"],</p>
<p style="font-size:1rem;color:#16325c;font-weight:700;margin:0 0 1.25rem;">RE: [Work Name] — [Service]</p>

<div style="font-size:1rem;font-weight:700;color:#16325c;margin-bottom:0.75rem;"><span style="display:inline-block;background:#0176d3;color:#fff;width:1.5rem;height:1.5rem;border-radius:50%;text-align:center;line-height:1.5rem;font-size:0.75rem;margin-right:0.5rem;">1</span>Scope</div>
<table cellpadding="0" cellspacing="0" width="100%" style="border-collapse:collapse;margin-bottom:1rem;">
<tr><th style="background:#f8f9fa;padding:0.75rem 1rem;text-align:left;font-size:0.75rem;border:1px solid #e2e8f0;width:28%;color:#64748b;font-weight:600;">Service</th><td style="padding:0.75rem 1rem;font-size:0.9rem;border:1px solid #e2e8f0;color:#1e293b;">[Service]</td></tr>
<tr><th style="background:#f8f9fa;padding:0.75rem 1rem;text-align:left;font-size:0.75rem;border:1px solid #e2e8f0;color:#64748b;font-weight:600;">Division</th><td style="padding:0.75rem 1rem;font-size:0.9rem;border:1px solid #e2e8f0;color:#1e293b;">[Division]</td></tr></table>

<div style="font-size:1rem;font-weight:700;color:#16325c;margin-bottom:0.75rem;"><span style="display:inline-block;background:#0176d3;color:#fff;width:1.5rem;height:1.5rem;border-radius:50%;text-align:center;line-height:1.5rem;font-size:0.75rem;margin-right:0.5rem;">2</span>Timeline</div>
<table cellpadding="0" cellspacing="0" width="100%" style="border-collapse:collapse;margin-bottom:1rem;">
<tr><th style="background:#f8f9fa;padding:0.75rem 1rem;text-align:left;font-size:0.75rem;border:1px solid #e2e8f0;width:28%;color:#64748b;font-weight:600;">Hours</th><td style="padding:0.75rem 1rem;font-size:0.9rem;border:1px solid #e2e8f0;color:#1e293b;">[Expected Hours]</td></tr>
<tr><th style="background:#f8f9fa;padding:0.75rem 1rem;text-align:left;font-size:0.75rem;border:1px solid #e2e8f0;color:#64748b;font-weight:600;">Budget</th><td style="padding:0.75rem 1rem;font-size:0.9rem;border:1px solid #e2e8f0;color:#1e293b;">€[Budget]</td></tr></table>

<div style="padding-top:1.5rem;border-top:2px solid #e2e8f0;margin-top:1.5rem;">
<p style="font-size:0.9rem;color:#475569;margin:0;">Yours sincerely,<br><strong style="color:#16325c;">[Division] Division</strong></p>
<div style="width:12.5rem;border-bottom:2px solid #1e293b;margin:2.5rem 0 0.5rem;"></div>
<div style="font-size:0.75rem;color:#64748b;">Client Signature & Date</div></div>
</td></tr></table>

<table cellpadding="0" cellspacing="0" width="100%" style="background:#fffbeb;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.1);border:1px solid #fde68a;margin-bottom:1.5rem;">
<tr><td style="padding:1.5rem 2rem;">
<span style="display:inline-block;background:#b45309;color:#fff;font-size:0.7rem;font-weight:700;padding:0.35rem 0.85rem;border-radius:6px;">⚠️ INTERNAL ONLY</span>
<div style="font-size:1.5rem;font-weight:700;color:#78350f;margin:1rem 0;">📊 Team Notes</div>
<table cellpadding="0" cellspacing="0" width="100%" style="margin-bottom:1rem;"><tr>
<td width="32%"><table cellpadding="0" cellspacing="0" width="100%" style="background:#fff;border:1px solid #fde68a;border-radius:6px;box-shadow:0 2px 4px rgba(0,0,0,0.08);"><tr><td style="padding:1rem;text-align:center;"><div style="font-size:0.7rem;color:#92400e;text-transform:uppercase;font-weight:600;letter-spacing:0.5px;margin-bottom:0.25rem;">Open Items</div><div style="font-size:1.75rem;font-weight:700;color:#78350f;">[Items]</div></td></tr></table></td><td width="2%"></td>
<td width="32%"><table cellpadding="0" cellspacing="0" width="100%" style="background:#fff;border:1px solid #fde68a;border-radius:6px;box-shadow:0 2px 4px rgba(0,0,0,0.08);"><tr><td style="padding:1rem;text-align:center;"><div style="font-size:0.7rem;color:#92400e;text-transform:uppercase;font-weight:600;letter-spacing:0.5px;margin-bottom:0.25rem;">Open Todos</div><div style="font-size:1.75rem;font-weight:700;color:#78350f;">[Todos]</div></td></tr></table></td><td width="2%"></td>
<td width="32%"><table cellpadding="0" cellspacing="0" width="100%" style="background:#fff;border:1px solid #fde68a;border-radius:6px;box-shadow:0 2px 4px rgba(0,0,0,0.08);"><tr><td style="padding:1rem;text-align:center;"><div style="font-size:0.7rem;color:#92400e;text-transform:uppercase;font-weight:600;letter-spacing:0.5px;margin-bottom:0.25rem;">Balance Hrs</div><div style="font-size:1.75rem;font-weight:700;color:#78350f;">[Balance]</div></td></tr></table></td>
</tr></table>
<table cellpadding="0" cellspacing="0" width="100%" style="background:#fef9c3;border:1px solid #fde047;border-radius:6px;margin-bottom:1rem;"><tr><td style="padding:1rem 1.25rem;"><span style="display:inline-block;width:0.625rem;height:0.625rem;background:#eab308;border-radius:50%;margin-right:0.75rem;"></span><span style="font-size:0.85rem;font-weight:600;color:#854d0e;">[Risk assessment]</span></td></tr></table>
<div style="font-size:1rem;font-weight:700;color:#78350f;margin-bottom:0.75rem;">Actions</div>
<div style="font-size:0.85rem;color:#78350f;line-height:1.8;">• [Action 1]<br>• [Action 2]<br>• [Action 3]</div>
</td></tr></table>

<table cellpadding="0" cellspacing="0" width="100%" style="background:#fff;border-radius:12px;box-shadow:0 2px 8px rgba(0,0,0,0.1);">
<tr><td style="padding:1rem 2rem;text-align:center;font-size:0.75rem;color:#94a3b8;">Generated by <strong style="color:#64748b;">GPTfy AI</strong> • <strong style="color:#64748b;">TESS</strong> • <strong style="color:#16325c;">Acuity BV</strong></td></tr></table>

</td></tr></table>
</body>
</html>
