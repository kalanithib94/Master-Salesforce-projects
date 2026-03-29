Generate a professional HTML Fiscal Advisory Brief for a Dutch accountancy firm using TESS JSON data. Output ONLY the HTML body element with inline styles - no DOCTYPE, no html/head tags, no markdown.

## CRITICAL RULES:
1. Start directly with <body style="..."> tag (NO DOCTYPE, NO <html>, NO <head>)
2. Use responsive layout with inline styles only (no external CSS)
3. Replace ALL [bracketed placeholders] with actual data from JSON or AI-generated content
4. Use max-width: 1400px, rem-based typography for scalability
5. NEVER leave any placeholder brackets [] in the final output

## DATA MAPPING (JSON → HTML Placeholders):
Use these exact mappings from the provided JSON data:
- [Division] → tess__DivisionText__c OR tess__Division__c
- [Account Name] → tess__AccountName__c
- [Account Number] → tess__AccountNumber__c
- [Year] → tess__Year__c
- [Work Name] → Name OR tess__CalculatedName__c
- [Items] → tess__OpenItems__c
- [Todos] → tess__OpenTodos__c
- [Hours] → tess__ActualHours__c OR tess__EstimatedHours__c
- [Date] → CreatedDate (format: DD Month YYYY)

## AI-GENERATED CONTENT REQUIREMENTS:

### 🔍 Fiscal Intelligence Profile:
Generate a professional 2-3 sentence fiscal profile based on:
- Company name (tess__AccountName__c)
- Fiscal year (tess__Year__c)
- Division (tess__Division__c)
Include: business context, fiscal position, and key considerations for the year.
Example: "Acuity B.V. enters fiscal year 2025 with a strong financial foundation. The company's focus on digital transformation and service expansion presents unique tax optimization opportunities. Strategic fiscal planning will be critical for maximizing efficiency and compliance."

### Key Insights (4 bullet points):
Generate 4 specific fiscal insights for Dutch tax context:
1. **VPB (Corporate Tax) insight** - Reference to tax rate changes, depreciation rules, or profit optimization
2. **BTW (VAT) insight** - Reference to VAT compliance, reporting requirements, or e-invoicing mandates
3. **Payroll Tax insight** - Reference to wage tax obligations, employee benefits taxation, or WKR regulations
4. **Strategic opportunity** - Tax credit opportunities (WBSO, innovation box), deduction strategies, or fiscal structuring

Make these professional, specific to NL tax law, and actionable.

### 🇳🇱 Tax Updates 2025:
For the year [tess__Year__c], generate realistic Dutch tax changes:
- **VPB**: Corporate tax rate adjustments, profit thresholds, depreciation changes
- **BTW**: VAT rate changes (general/reduced rates), compliance updates
- **LH (Wage Tax)**: Payroll tax rates, deduction limits, pension contribution caps

Format each as: [Rate/Rule] → [Impact statement]
Example: "25.8% rate maintained → Stable for profit planning"

### 💡 Opportunities (3 items):
Based on the data, generate 3 concrete tax optimization opportunities:
- If tess__Year__c >= 2025: "Leverage 2025 WBSO innovation tax credits for R&D activities"
- If tess__Budget__c = 0: "Establish formal budget planning to enable tax provision optimization"
- Always include: "Review fiscal reserves and asset depreciation strategies for [Year]"
- Consider: Investment deductions, sustainability tax incentives, international tax planning

### 📅 Deadlines:
Generate realistic NL tax deadlines for fiscal year [tess__Year__c]:
- **Q1**: VAT returns (monthly/quarterly), Wage tax declarations
- **Q2**: Corporate income tax provisional assessment
- **Q3**: Annual income tax return filing
- **Q4**: Year-end VAT adjustments, Wage tax annual reconciliation

Use actual Dutch tax calendar dates when possible.

### Next Steps (3 tasks):
Generate 3 specific action items:
- If tess__OpenItems__c > 0: "Complete [X] outstanding documentation items for tax file"
- If tess__OpenTodos__c > 0: "Address [X] pending fiscal tasks by end of Q[current quarter]"
- Always include: "Schedule fiscal year [Year] planning session within 2 weeks"
- Always include: "Review and update tax provision estimates for Q[next quarter]"

## FORMATTING STANDARDS:
- Currency: EUR format (e.g., "€1,250.00")
- Tax rates: Percentage with 1-2 decimals (e.g., "25.8%", "21%")
- Hours: 2 decimals (e.g., "15.00")
- Dates: Dutch format (e.g., "18 November 2025", "Q1 2025")
- Year: 4 digits (e.g., "2025")

## VALIDATION CHECKLIST:
✓ All [bracketed placeholders] replaced with real data or AI content
✓ No "undefined" or "null" values visible
✓ Fiscal Intelligence has meaningful 2-3 sentence profile
✓ Key Insights contains 4 specific Dutch tax points
✓ Tax Updates table has realistic 2025 data
✓ Opportunities lists 3 concrete optimization strategies
✓ Deadlines reflect actual Dutch tax calendar
✓ Next Steps contains 3 actionable tasks with dates
✓ Professional Dutch fiscal advisory tone maintained

## OUTPUT REQUIREMENTS:
- Output ONLY starting with <body style="..."> (NO DOCTYPE)
- NO markdown code fences (no ```)
- NO explanatory text before or after HTML
- Single continuous HTML string for direct injection

<body style="font-family:system-ui,-apple-system,'Segoe UI',sans-serif;width:100%;max-width:1400px;margin:0 auto;background:#f8f9fa;padding:0;"><div style="padding:2rem;background:#ffffff;border-radius:8px;box-shadow:0 2px 8px rgba(0,0,0,0.1);"><div style="background:linear-gradient(135deg,#2c3e50 0%,#34495e 100%);padding:1.5rem;border-radius:8px;margin-bottom:2rem;"><div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:0.75rem;"><div style="font-size:1.75rem;font-weight:700;color:#ffffff;">[Division] Division</div><div style="background:linear-gradient(135deg,#f39c12 0%,#e67e22 100%);color:#ffffff;padding:0.5rem 1.25rem;border-radius:8px;font-size:0.85rem;font-weight:700;letter-spacing:0.5px;box-shadow:0 2px 4px rgba(0,0,0,0.2);">Powered by TESS × GPTfy.ai</div></div><div style="font-size:0.85rem;color:#e0e7ff;">Fiscal Advisory Brief • [Year]</div></div><h1 style="font-weight:700;color:#16325c;font-size:1.75rem;margin-bottom:1.5rem;margin-top:0;">📋 Overview</h1><div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:1.25rem;margin-bottom:2rem;"><div style="background:#ffffff;padding:1.25rem;border-radius:6px;border:2px solid #bfdbfe;box-shadow:0 2px 4px rgba(0,0,0,0.08);"><div style="font-size:0.7rem;color:#94a3b8;font-weight:600;text-transform:uppercase;letter-spacing:0.5px;margin-bottom:0.25rem;">Client</div><div style="font-size:1rem;font-weight:600;color:#1e3a5f;margin-bottom:0.25rem;">[Account Name]</div><div style="font-size:0.85rem;color:#64748b;">Account #[Account Number]</div></div><div style="background:#ffffff;padding:1.25rem;border-radius:6px;border:2px solid #e9d5ff;box-shadow:0 2px 4px rgba(0,0,0,0.08);"><div style="font-size:0.7rem;color:#94a3b8;font-weight:600;text-transform:uppercase;letter-spacing:0.5px;margin-bottom:0.25rem;">Fiscal Year</div><div style="font-size:1rem;font-weight:600;color:#8b5cf6;margin-bottom:0.25rem;">[Year]</div><div style="font-size:0.85rem;color:#64748b;">Active planning</div></div><div style="background:#ffffff;padding:1.25rem;border-radius:6px;border:2px solid #bbf7d0;box-shadow:0 2px 4px rgba(0,0,0,0.08);"><div style="font-size:0.7rem;color:#94a3b8;font-weight:600;text-transform:uppercase;letter-spacing:0.5px;margin-bottom:0.25rem;">Project</div><div style="font-size:1rem;font-weight:600;color:#10b981;margin-bottom:0.25rem;">[Work Name]</div><div style="font-size:0.85rem;color:#64748b;">In progress</div></div></div><h2 style="font-weight:600;color:#16325c;font-size:1.5rem;margin-bottom:1rem;border-bottom:2px solid #0176d3;padding-bottom:0.5rem;">🔍 Fiscal Intelligence</h2><div style="background:#f0f7ff;padding:1.5rem;border-radius:6px;border:2px solid #bfdbfe;margin-bottom:2rem;"><p style="color:#444;line-height:1.6;margin:0;font-size:0.95rem;">[Generate 2-3 sentence fiscal profile]</p></div><h3 style="font-weight:600;color:#16325c;font-size:1.25rem;margin-bottom:1rem;">Key Insights</h3><div style="background:#f8f9fa;padding:1.5rem;border-radius:8px;margin-bottom:2rem;"><div style="font-size:0.9rem;color:#475569;line-height:1.8;">• [VPB insight]<br>• [BTW insight]<br>• [Payroll Tax insight]<br>• [Strategic opportunity]</div></div>

<div style="background:linear-gradient(135deg,#1e3a5f 0%,#0d2137 100%);padding:1.25rem 2rem;border-radius:8px;margin-bottom:1.5rem;"><div style="font-size:1rem;color:#fff;letter-spacing:0.1rem;text-transform:uppercase;font-weight:600;text-align:center;">🇳🇱 Tax Updates [Year]</div></div><div style="background:#ffffff;border-radius:8px;box-shadow:0 2px 8px rgba(0,0,0,0.1);padding:2rem;margin-bottom:2rem;"><table cellpadding="0" cellspacing="0" width="100%" style="border-collapse:collapse;margin-bottom:1rem;"><tr><th style="background:#f8f9fa;padding:0.75rem 1rem;text-align:left;font-size:0.75rem;border:1px solid #e2e8f0;width:28%;color:#64748b;font-weight:600;">Tax Type</th><th style="background:#f8f9fa;padding:0.75rem 1rem;text-align:left;font-size:0.75rem;border:1px solid #e2e8f0;color:#64748b;font-weight:600;">Change</th><th style="background:#f8f9fa;padding:0.75rem 1rem;text-align:left;font-size:0.75rem;border:1px solid #e2e8f0;color:#64748b;font-weight:600;">Impact</th></tr><tr><th style="background:#f8f9fa;padding:0.75rem 1rem;text-align:left;font-size:0.75rem;border:1px solid #e2e8f0;color:#64748b;font-weight:600;">VPB</th><td style="padding:0.75rem 1rem;font-size:0.9rem;border:1px solid #e2e8f0;color:#1e293b;">[Change]</td><td style="padding:0.75rem 1rem;font-size:0.9rem;border:1px solid #e2e8f0;color:#1e293b;">[Impact]</td></tr><tr><th style="background:#f8f9fa;padding:0.75rem 1rem;text-align:left;font-size:0.75rem;border:1px solid #e2e8f0;color:#64748b;font-weight:600;">BTW</th><td style="padding:0.75rem 1rem;font-size:0.9rem;border:1px solid #e2e8f0;color:#1e293b;">[Change]</td><td style="padding:0.75rem 1rem;font-size:0.9rem;border:1px solid #e2e8f0;color:#1e293b;">[Impact]</td></tr><tr><th style="background:#f8f9fa;padding:0.75rem 1rem;text-align:left;font-size:0.75rem;border:1px solid #e2e8f0;color:#64748b;font-weight:600;">LH</th><td style="padding:0.75rem 1rem;font-size:0.9rem;border:1px solid #e2e8f0;color:#1e293b;">[Change]</td><td style="padding:0.75rem 1rem;font-size:0.9rem;border:1px solid #e2e8f0;color:#1e293b;">[Impact]</td></tr></table><h3 style="font-weight:600;color:#16325c;font-size:1.25rem;margin:1.5rem 0 1rem;">💡 Tax Optimization Opportunities</h3><div style="background:linear-gradient(135deg,#ecfdf5 0%,#d1fae5 100%);border-radius:8px;padding:1.5rem;border:1px solid #a7f3d0;margin-bottom:1.5rem;"><div style="font-size:0.9rem;color:#047857;line-height:1.8;"><strong>1.</strong> [Opportunity]<br><strong>2.</strong> [Opportunity]<br><strong>3.</strong> [Opportunity]</div></div><h3 style="font-weight:600;color:#16325c;font-size:1.25rem;margin-bottom:1rem;">📅 Key Fiscal Deadlines [Year]</h3><table cellpadding="0" cellspacing="0" width="100%" style="border-collapse:collapse;margin-bottom:1rem;"><tr><th style="background:#f8f9fa;padding:0.75rem 1rem;text-align:left;font-size:0.75rem;border:1px solid #e2e8f0;width:28%;color:#64748b;font-weight:600;">Period</th><th style="background:#f8f9fa;padding:0.75rem 1rem;text-align:left;font-size:0.75rem;border:1px solid #e2e8f0;color:#64748b;font-weight:600;">Tax Obligation</th></tr><tr><th style="background:#f8f9fa;padding:0.75rem 1rem;text-align:left;font-size:0.75rem;border:1px solid #e2e8f0;color:#64748b;font-weight:600;">Q1</th><td style="padding:0.75rem 1rem;font-size:0.9rem;border:1px solid #e2e8f0;color:#1e293b;">VAT Returns / Wage Tax Declarations</td></tr><tr><th style="background:#f8f9fa;padding:0.75rem 1rem;text-align:left;font-size:0.75rem;border:1px solid #e2e8f0;color:#64748b;font-weight:600;">Q2</th><td style="padding:0.75rem 1rem;font-size:0.9rem;border:1px solid #e2e8f0;color:#1e293b;">Corporate Tax Provisional Assessment</td></tr><tr><th style="background:#f8f9fa;padding:0.75rem 1rem;text-align:left;font-size:0.75rem;border:1px solid #e2e8f0;color:#64748b;font-weight:600;">Q3</th><td style="padding:0.75rem 1rem;font-size:0.9rem;border:1px solid #e2e8f0;color:#1e293b;">Annual Income Tax Return Filing</td></tr><tr><th style="background:#f8f9fa;padding:0.75rem 1rem;text-align:left;font-size:0.75rem;border:1px solid #e2e8f0;color:#64748b;font-weight:600;">Q4</th><td style="padding:0.75rem 1rem;font-size:0.9rem;border:1px solid #e2e8f0;color:#1e293b;">Year-end VAT Adjustments / Annual Reconciliation</td></tr></table></div><div style="background:linear-gradient(135deg,#fffbeb 0%,#fef9c3 100%);border-radius:8px;padding:1.5rem;border:1px solid #fde68a;margin-bottom:2rem;"><span style="display:inline-block;background:#b45309;color:#fff;font-size:0.7rem;font-weight:700;padding:0.35rem 0.85rem;border-radius:6px;margin-bottom:1rem;">⚠️ INTERNAL ONLY</span><h2 style="font-weight:600;color:#78350f;font-size:1.5rem;margin:0 0 1rem 0;">📊 Engagement Status</h2><div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:0.75rem;margin-bottom:1.5rem;"><div style="background:#ffffff;padding:1rem;border-radius:6px;text-align:center;border:1px solid #fde68a;"><div style="font-size:0.7rem;color:#92400e;text-transform:uppercase;font-weight:600;letter-spacing:0.5px;margin-bottom:0.25rem;">Open Items</div><div style="font-size:1.75rem;font-weight:700;color:#78350f;">[Items]</div></div><div style="background:#ffffff;padding:1rem;border-radius:6px;text-align:center;border:1px solid #fde68a;"><div style="font-size:0.7rem;color:#92400e;text-transform:uppercase;font-weight:600;letter-spacing:0.5px;margin-bottom:0.25rem;">Open Todos</div><div style="font-size:1.75rem;font-weight:700;color:#78350f;">[Todos]</div></div><div style="background:#ffffff;padding:1rem;border-radius:6px;text-align:center;border:1px solid #fde68a;"><div style="font-size:0.7rem;color:#92400e;text-transform:uppercase;font-weight:600;letter-spacing:0.5px;margin-bottom:0.25rem;">Total Hours</div><div style="font-size:1.75rem;font-weight:700;color:#78350f;">[Hours]</div></div></div><div style="background:#fef9c3;border:1px solid #fde047;border-radius:6px;padding:1rem 1.25rem;margin-bottom:1rem;"><span style="display:inline-block;width:0.625rem;height:0.625rem;background:#eab308;border-radius:50%;margin-right:0.75rem;"></span><span style="font-size:0.85rem;font-weight:600;color:#854d0e;">Risk: Review budget and scope alignment</span></div><div style="font-size:1rem;font-weight:700;color:#78350f;margin-bottom:0.75rem;">Next Steps</div><div style="font-size:0.85rem;color:#78350f;line-height:1.8;">• [Task 1]<br>• [Task 2]<br>• [Task 3]</div></div><div style="text-align:center;padding:1rem;font-size:0.75rem;color:#94a3b8;">Generated by <strong style="color:#64748b;">GPTfy.ai</strong> • <strong style="color:#64748b;">TESS</strong> • <strong style="color:#16325c;">Acuity BV</strong></div></div></body>
