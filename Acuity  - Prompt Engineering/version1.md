Generate a professional HTML engagement letter for a Dutch accountancy firm using the provided TESS JSON data. Output ONLY the complete HTML document - no markdown, no explanations, no code blocks.

## CRITICAL RULES:
1. Use TABLE-based layouts with inline styles only (no external CSS)
2. Replace ALL [bracketed placeholders] with actual data from JSON or AI-generated content
3. Maintain consistent width across all sections (max-width: 1800px, padding: 32px 64px)
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
<body style="margin:0;padding:32px 64px;font-family:Segoe UI,sans-serif;background:#f3f4f6;color:#1e293b;">
<table cellpadding="0" cellspacing="0" width="100%" style="max-width:1800px;margin:0 auto;">
<tr><td>

<table cellpadding="0" cellspacing="0" width="100%" style="background:linear-gradient(to right,#1e3a5f,#0d2137);border-radius:12px;margin-bottom:24px;">
<tr><td style="padding:32px;">
<table cellpadding="0" cellspacing="0" width="100%"><tr>
<td><div style="font-size:28px;font-weight:700;color:#fff;">[Division]</div>
<div style="font-size:14px;color:rgba(255,255,255,0.85);margin-top:8px;">Engagement Confirmation Package</div>
<div style="margin-top:16px;"><span style="display:inline-block;background:rgba(255,255,255,0.15);padding:8px 16px;border-radius:6px;font-size:13px;color:#fff;margin-right:10px;">[Service]</span><span style="display:inline-block;background:rgba(255,255,255,0.15);padding:8px 16px;border-radius:6px;font-size:13px;color:#fff;">Active</span></div></td>
<td style="text-align:right;vertical-align:top;"><div style="font-size:11px;color:rgba(255,255,255,0.6);">Powered by</div><div style="font-size:16px;font-weight:700;color:#fff;">TESS × GPTfy</div></td>
</tr></table></td></tr></table>

<table cellpadding="0" cellspacing="0" width="100%" style="background:#fff;border-radius:12px;box-shadow:0 4px 12px rgba(0,0,0,0.08);margin-bottom:24px;">
<tr><td style="padding:32px 48px;">
<div style="font-size:16px;font-weight:700;color:#1e293b;margin-bottom:20px;padding-bottom:12px;border-bottom:2px solid #e2e8f0;">📋 Overview</div>
<table cellpadding="0" cellspacing="0" width="100%">
<tr><td width="49%"><table cellpadding="0" cellspacing="0" width="100%" style="background:#f8fafc;border:1px solid #e2e8f0;border-radius:10px;"><tr><td style="padding:24px 32px;"><div style="font-size:11px;color:#64748b;text-transform:uppercase;letter-spacing:1px;font-weight:600;margin-bottom:6px;">Client</div><div style="font-size:16px;color:#1e3a5f;font-weight:700;">[Account Name]</div></td></tr></table></td><td width="2%"></td><td width="49%"><table cellpadding="0" cellspacing="0" width="100%" style="background:#f8fafc;border:1px solid #e2e8f0;border-radius:10px;"><tr><td style="padding:24px 32px;"><div style="font-size:11px;color:#64748b;text-transform:uppercase;letter-spacing:1px;font-weight:600;margin-bottom:6px;">Account #</div><div style="font-size:16px;color:#1e293b;font-weight:600;">[Account Number]</div></td></tr></table></td></tr>
<tr><td colspan="3" style="height:16px;"></td></tr>
<tr><td width="49%"><table cellpadding="0" cellspacing="0" width="100%" style="background:#f8fafc;border:1px solid #e2e8f0;border-radius:10px;"><tr><td style="padding:24px 32px;"><div style="font-size:11px;color:#64748b;text-transform:uppercase;letter-spacing:1px;font-weight:600;margin-bottom:6px;">Service</div><div style="font-size:16px;color:#1e293b;font-weight:600;">[Service]</div></td></tr></table></td><td width="2%"></td><td width="49%"><table cellpadding="0" cellspacing="0" width="100%" style="background:#f8fafc;border:1px solid #e2e8f0;border-radius:10px;"><tr><td style="padding:24px 32px;"><div style="font-size:11px;color:#64748b;text-transform:uppercase;letter-spacing:1px;font-weight:600;margin-bottom:6px;">Project</div><div style="font-size:16px;color:#1e293b;font-weight:600;">[Work Name]</div></td></tr></table></td></tr>
</table></td></tr></table>

<table cellpadding="0" cellspacing="0" width="100%" style="background:#fff;border-radius:12px;box-shadow:0 4px 12px rgba(0,0,0,0.08);margin-bottom:24px;">
<tr><td style="padding:32px 48px;">
<div style="margin-bottom:16px;"><span style="font-size:16px;font-weight:700;color:#1e293b;">🔍 Client Intelligence</span><span style="display:inline-block;background:#1e3a5f;color:#fff;font-size:10px;font-weight:700;padding:4px 12px;border-radius:20px;margin-left:10px;">AI-POWERED</span></div>
<table cellpadding="0" cellspacing="0" width="100%" style="background:#e0f7fa;border-left:4px solid #00838f;border-radius:0 8px 8px 0;margin-bottom:16px;"><tr><td style="padding:20px 28px;font-size:14px;color:#1e293b;line-height:1.7;">[Generate 2-3 sentence company profile]</td></tr></table>
<div style="font-size:14px;font-weight:700;color:#1e293b;margin-bottom:10px;">Strategic Insights</div>
<div style="font-size:13px;color:#475569;line-height:2;">• [Dutch regulatory insight]<br>• [Digital transformation trend]<br>• [Compliance challenge]<br>• [Advisory opportunity]</div>
</td></tr></table>

<table cellpadding="0" cellspacing="0" width="100%" style="background:#fff;border-radius:12px;box-shadow:0 4px 12px rgba(0,0,0,0.08);overflow:hidden;margin-bottom:24px;">
<tr><td style="background:linear-gradient(to right,#1e3a5f,#0d2137);padding:20px 48px;text-align:center;"><div style="font-size:14px;color:#fff;letter-spacing:2px;text-transform:uppercase;font-weight:600;">Engagement Confirmation</div></td></tr>
<tr><td style="padding:32px 48px;">
<div style="font-size:13px;color:#64748b;margin-bottom:20px;"><strong>Date:</strong> [Date] &nbsp;|&nbsp; <strong>Ref:</strong> [Record ID]</div>
<p style="font-size:14px;color:#475569;margin:0 0 12px;">Dear [Contact or "Valued Client"],</p>
<p style="font-size:15px;color:#1e3a5f;font-weight:700;margin:0 0 20px;">RE: [Work Name] — [Service]</p>

<div style="font-size:14px;font-weight:700;color:#1e293b;margin-bottom:12px;"><span style="display:inline-block;background:#4a90a4;color:#fff;width:22px;height:22px;border-radius:50%;text-align:center;line-height:22px;font-size:11px;margin-right:10px;">1</span>Scope</div>
<table cellpadding="0" cellspacing="0" width="100%" style="border-collapse:collapse;margin-bottom:16px;">
<tr><th style="background:#f1f5f9;padding:10px 14px;text-align:left;font-size:12px;border:1px solid #e2e8f0;width:28%;">Service</th><td style="padding:10px 14px;font-size:13px;border:1px solid #e2e8f0;">[Service]</td></tr>
<tr><th style="background:#f1f5f9;padding:10px 14px;text-align:left;font-size:12px;border:1px solid #e2e8f0;">Division</th><td style="padding:10px 14px;font-size:13px;border:1px solid #e2e8f0;">[Division]</td></tr></table>

<div style="font-size:14px;font-weight:700;color:#1e293b;margin-bottom:12px;"><span style="display:inline-block;background:#4a90a4;color:#fff;width:22px;height:22px;border-radius:50%;text-align:center;line-height:22px;font-size:11px;margin-right:10px;">2</span>Timeline</div>
<table cellpadding="0" cellspacing="0" width="100%" style="border-collapse:collapse;margin-bottom:16px;">
<tr><th style="background:#f1f5f9;padding:10px 14px;text-align:left;font-size:12px;border:1px solid #e2e8f0;width:28%;">Hours</th><td style="padding:10px 14px;font-size:13px;border:1px solid #e2e8f0;">[Expected Hours]</td></tr>
<tr><th style="background:#f1f5f9;padding:10px 14px;text-align:left;font-size:12px;border:1px solid #e2e8f0;">Budget</th><td style="padding:10px 14px;font-size:13px;border:1px solid #e2e8f0;">€[Budget]</td></tr></table>

<div style="padding-top:20px;border-top:2px solid #e2e8f0;">
<p style="font-size:14px;color:#475569;margin:0;">Yours sincerely,<br><strong style="color:#1e3a5f;">[Division] Division</strong></p>
<div style="width:200px;border-bottom:2px solid #1e293b;margin:40px 0 6px;"></div>
<div style="font-size:12px;color:#64748b;">Client Signature & Date</div></div>
</td></tr></table>

<table cellpadding="0" cellspacing="0" width="100%" style="background:#fffbeb;border-radius:12px;box-shadow:0 4px 12px rgba(0,0,0,0.08);border:1px solid #fde68a;margin-bottom:24px;">
<tr><td style="padding:32px 48px;">
<span style="display:inline-block;background:#b45309;color:#fff;font-size:10px;font-weight:700;padding:5px 14px;border-radius:20px;">⚠️ INTERNAL ONLY</span>
<div style="font-size:16px;font-weight:700;color:#78350f;margin:16px 0;">📊 Team Notes</div>
<table cellpadding="0" cellspacing="0" width="100%" style="margin-bottom:16px;"><tr>
<td width="32%"><table cellpadding="0" cellspacing="0" width="100%" style="background:#fff;border:1px solid #fde68a;border-radius:10px;"><tr><td style="padding:14px;text-align:center;"><div style="font-size:10px;color:#92400e;text-transform:uppercase;font-weight:600;">Open Items</div><div style="font-size:24px;font-weight:700;color:#78350f;">[Items]</div></td></tr></table></td><td width="2%"></td>
<td width="32%"><table cellpadding="0" cellspacing="0" width="100%" style="background:#fff;border:1px solid #fde68a;border-radius:10px;"><tr><td style="padding:14px;text-align:center;"><div style="font-size:10px;color:#92400e;text-transform:uppercase;font-weight:600;">Open Todos</div><div style="font-size:24px;font-weight:700;color:#78350f;">[Todos]</div></td></tr></table></td><td width="2%"></td>
<td width="32%"><table cellpadding="0" cellspacing="0" width="100%" style="background:#fff;border:1px solid #fde68a;border-radius:10px;"><tr><td style="padding:14px;text-align:center;"><div style="font-size:10px;color:#92400e;text-transform:uppercase;font-weight:600;">Balance Hrs</div><div style="font-size:24px;font-weight:700;color:#78350f;">[Balance]</div></td></tr></table></td>
</tr></table>
<table cellpadding="0" cellspacing="0" width="100%" style="background:#fef9c3;border:1px solid #fde047;border-radius:10px;margin-bottom:16px;"><tr><td style="padding:14px 18px;"><span style="display:inline-block;width:10px;height:10px;background:#eab308;border-radius:50%;margin-right:10px;"></span><span style="font-size:13px;font-weight:600;color:#854d0e;">[Risk assessment]</span></td></tr></table>
<div style="font-size:14px;font-weight:700;color:#78350f;margin-bottom:10px;">Actions</div>
<div style="font-size:13px;color:#78350f;line-height:1.9;">• [Action 1]<br>• [Action 2]<br>• [Action 3]</div>
</td></tr></table>

<table cellpadding="0" cellspacing="0" width="100%" style="background:#fff;border-radius:12px;box-shadow:0 4px 12px rgba(0,0,0,0.08);">
<tr><td style="padding:16px 32px;text-align:center;font-size:11px;color:#94a3b8;">Generated by <strong style="color:#64748b;">GPTfy AI</strong> • <strong style="color:#64748b;">TESS</strong> • <strong style="color:#1e3a5f;">Acuity BV</strong></td></tr></table>

</td></tr></table>
</body>
</html>