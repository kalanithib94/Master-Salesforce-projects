# Account 360 Part 1 - New Sections to Add

## 1. ENHANCED CALCULATIONS (Added to existing calculation checkpoint)

### STEP 6: CALCULATE FORECAST CATEGORY BREAKDOWN

```
Process:
a) Group all OPEN opportunities by ForecastCategoryName
b) For each forecast category, sum the opportunity amounts
c) Calculate the count of opportunities per category

Your calculation workspace:
Forecast Categories:
- Omitted: [Count] opportunities, Total: €[Amount]
- Pipeline: [Count] opportunities, Total: €[Amount]  
- Best Case: [Count] opportunities, Total: €[Amount]
- Commit: [Count] opportunities, Total: €[Amount]
- Closed: [Count] opportunities, Total: €[Amount]

Note: Only show categories that have opportunities. Use "N/A" if no forecast category is set.
```

### STEP 7: ANALYZE PRODUCT MIX

```
Process:
a) From OpportunityLineItems array, group products by Product2.Family
b) Calculate total quantity and total value per product family
c) Identify top 3 product families by revenue

Your analysis workspace:
Product Families:
1. [Family Name]: [Count] items, €[Total Value], [Percentage]% of total
2. [Family Name]: [Count] items, €[Total Value], [Percentage]% of total
3. [Family Name]: [Count] items, €[Total Value], [Percentage]% of total

Whitespace Opportunities: [Families with low penetration or missing]
```

### STEP 8: IDENTIFY CONTRACT RENEWALS

```
Process:
a) Current Date: [Use from Opportunities.Currentdate__c]
b) 12-Month Cutoff Date: [Current Date + 365 days]
c) List all Contracts where EndDate is within next 12 months
d) Calculate total contract value at risk

Your workspace:
Contracts Ending in 12 Months:
- Contract #[Number]: Ends [Date] - [Days until expiration] days - Status: [Status]
- Contract #[Number]: Ends [Date] - [Days until expiration] days - Status: [Status]

Total Contracts Expiring: [Count]
```

### STEP 9: VALIDATE ACCOUNT TEAM

```
Process:
a) Count members in AccountTeamMember array
b) If count = 0, raise alert
c) List team members by role

Your workspace:
Account Team Count: [Number]
Alert Required: [YES/NO]

Team Members:
- [User.Name] - [TeamMemberRole]
- [User.Name] - [TeamMemberRole]
```

---

## 2. NEW HTML SECTIONS

### A. Product Mix Analysis (Insert after KPIs, before Opportunity Pipeline)

```html
<!-- ===== Product Mix Analysis ===== -->
<div style="background: #ffffff; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); padding: 1.5rem; margin-bottom: 1.5rem; box-sizing: border-box;">
  <h3 style="color: #1e293b; font-size: 1.25rem; font-weight: 700; margin: 0 0 1rem 0;">Product Mix & Whitespace Analysis</h3>
  
  <!-- Product Family Distribution -->
  <div style="display: flex; flex-wrap: wrap; gap: 1rem; margin-bottom: 1rem;">
    <!-- Dynamically generate for each product family -->
    <div style="flex: 1; min-width: 200px; background: #f8fafc; border-radius: 8px; padding: 1rem; border-left: 3px solid #3b82f6;">
      <div style="font-size: 0.875rem; font-weight: 600; color: #64748b; margin-bottom: 0.25rem;">[Product2.Family]</div>
      <div style="font-size: 1.5rem; font-weight: 700; color: #1e293b;">€[Total Value]</div>
      <div style="font-size: 0.8rem; color: #94a3b8;">[Count] items • [Percentage]% of revenue</div>
    </div>
  </div>
  
  <!-- Whitespace Opportunities -->
  <div style="background: #fef3c7; border-left: 4px solid #f59e0b; padding: 1rem; border-radius: 8px;">
    <div style="font-weight: 600; color: #92400e; margin-bottom: 0.5rem;">💡 Whitespace Opportunities</div>
    <div style="font-size: 0.875rem; color: #78350f;">
      [Dynamically identify product families with low penetration or suggest cross-sell opportunities based on customer profile]
    </div>
  </div>
</div>
```

### B. Forecast Category Breakdown (Insert after Product Mix)

```html
<!-- ===== Forecast Category Pipeline Breakdown ===== -->
<div style="background: #ffffff; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); padding: 1.5rem; margin-bottom: 1.5rem; box-sizing: border-box;">
  <h3 style="color: #1e293b; font-size: 1.25rem; font-weight: 700; margin: 0 0 1rem 0;">Pipeline by Forecast Category</h3>
  
  <div style="display: flex; flex-wrap: wrap; gap: 1rem;">
    <!-- Dynamically generate for each forecast category -->
    <div style="flex: 1; min-width: 180px; background: #f8fafc; border-radius: 8px; padding: 1rem; border-left: 3px solid #10b981;">
      <div style="font-size: 0.875rem; font-weight: 600; color: #64748b; margin-bottom: 0.25rem;">[ForecastCategoryName]</div>
      <div style="font-size: 1.5rem; font-weight: 700; color: #1e293b;">€[Category Total]</div>
      <div style="font-size: 0.8rem; color: #94a3b8;">[Count] opportunities</div>
    </div>
  </div>
</div>
```

### C. Contract Renewal Intelligence (Insert after Forecast Category)

```html
<!-- ===== Contract Renewal Intelligence ===== -->
<div style="background: #ffffff; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); padding: 1.5rem; margin-bottom: 1.5rem; box-sizing: border-box;">
  <h3 style="color: #1e293b; font-size: 1.25rem; font-weight: 700; margin: 0 0 1rem 0;">Contract Renewals - Next 12 Months</h3>
  
  <!-- If no contracts expiring -->
  <div style="background: #f0fdf4; border-left: 4px solid #10b981; padding: 1rem; border-radius: 8px; margin-bottom: 1rem;">
    <div style="font-size: 0.875rem; color: #166534;">✓ No contracts expiring in the next 12 months</div>
  </div>
  
  <!-- OR if contracts are expiring -->
  <div style="background: #fef2f2; border-left: 4px solid #ef4444; padding: 1rem; border-radius: 8px; margin-bottom: 1rem;">
    <div style="font-weight: 600; color: #991b1b; margin-bottom: 0.5rem;">⚠️ [Count] Contract(s) Expiring Soon</div>
    <div style="font-size: 0.875rem; color: #7f1d1d;">Proactive renewal discussions recommended</div>
  </div>
  
  <!-- Contract Details Table -->
  <table style="width: 100%; border-collapse: collapse; background: #fff; font-size: 0.875rem;">
    <thead>
      <tr style="background-color: #f1f5f9;">
        <th style="border: 1px solid #cbd5e1; padding: 0.75rem; text-align: left; font-weight: 600; color: #475569;">Contract Number</th>
        <th style="border: 1px solid #cbd5e1; padding: 0.75rem; text-align: left; font-weight: 600; color: #475569;">End Date</th>
        <th style="border: 1px solid #cbd5e1; padding: 0.75rem; text-align: left; font-weight: 600; color: #475569;">Days Until Expiration</th>
        <th style="border: 1px solid #cbd5e1; padding: 0.75rem; text-align: left; font-weight: 600; color: #475569;">Status</th>
      </tr>
    </thead>
    <tbody>
      <!-- Dynamically generate rows for each contract -->
      <tr style="background-color: #fefefe;">
        <td style="border: 1px solid #cbd5e1; padding: 0.75rem;"><a href="[ContractId]" style="color: #3b82f6; text-decoration: none;">[ContractNumber]</a></td>
        <td style="border: 1px solid #cbd5e1; padding: 0.75rem;">[EndDate formatted as Jan 1, 2000]</td>
        <td style="border: 1px solid #cbd5e1; padding: 0.75rem; font-weight: 600; color: [Red if < 90 days, Orange if < 180 days, Green otherwise];">[Days]</td>
        <td style="border: 1px solid #cbd5e1; padding: 0.75rem;">[Status]</td>
      </tr>
    </tbody>
  </table>
</div>
```

### D. Account Team Validation Alert (Insert at the top, after Account Header)

```html
<!-- ===== Account Team Validation Alert ===== -->
<!-- Only show if AccountTeamMember count = 0 -->
<div style="background: #fef2f2; border-left: 4px solid #dc2626; padding: 1rem; border-radius: 8px; margin-bottom: 1.5rem;">
  <div style="font-weight: 700; color: #991b1b; margin-bottom: 0.5rem; font-size: 1rem;">⚠️ Action Required: Account Team Empty</div>
  <div style="font-size: 0.875rem; color: #7f1d1d;">This account has no team members assigned. Please add team members to ensure proper account coverage and collaboration.</div>
</div>

<!-- OR if team members exist, show summary card -->
<div style="background: #ffffff; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); padding: 1.5rem; margin-bottom: 1.5rem; box-sizing: border-box;">
  <h3 style="color: #1e293b; font-size: 1.25rem; font-weight: 700; margin: 0 0 1rem 0;">Account Team ([Count] Members)</h3>
  
  <div style="display: flex; flex-wrap: wrap; gap: 1rem;">
    <!-- Dynamically generate for each team member -->
    <div style="flex: 1; min-width: 200px; background: #f8fafc; border-radius: 8px; padding: 1rem; border-left: 3px solid #8b5cf6;">
      <div style="font-weight: 600; color: #1e293b; margin-bottom: 0.25rem;">[User.Name]</div>
      <div style="font-size: 0.875rem; color: #64748b;">[TeamMemberRole]</div>
    </div>
  </div>
</div>
```

---

## 3. SECTION ORDER IN FINAL HTML

```
1. Combined Account Header & Executive Summary
2. ⚠️ Account Team Validation Alert (if empty) OR Account Team Summary
3. Risk & Strength Assessment
4. Enhanced Key Performance Indicators (5 cards)
5. 🆕 Product Mix & Whitespace Analysis
6. 🆕 Forecast Category Pipeline Breakdown
7. 🆕 Contract Renewal Intelligence
8. Opportunity Pipeline Table
```

---

## 4. DATA REQUIREMENTS

### Required in JSON Input:

```json
{
  "Account": {
    "OpportunityLineItems": [
      {
        "Product2Id": "xxx",
        "Product2": {
          "Name": "Product Name",
          "Family": "Services" 
        },
        "Quantity": 2,
        "TotalPrice": 935
      }
    ],
    "AccountTeamMembers": [
      {
        "UserId": "xxx",
        "User": {
          "Name": "John Doe"
        },
        "TeamMemberRole": "Account Executive"
      }
    ],
    "Contracts": [
      {
        "Id": "800xxx",
        "ContractNumber": "00202975",
        "StartDate": "2024-01-01",
        "EndDate": "2025-12-31",
        "Status": "Active"
      }
    ]
  },
  "Opportunities": [
    {
      "ForecastCategoryName": "Pipeline",
      "ForecastCategory": "Pipeline",
      "OpportunityLineItems": [...]
    }
  ]
}
```

---

## 5. KEY ENHANCEMENTS

✅ **Product Mix Analysis**
- Shows revenue breakdown by product family
- Identifies whitespace opportunities
- Helps with cross-sell/upsell planning

✅ **Forecast Category Breakdown**
- Visual pipeline segmentation by forecast stage
- Better pipeline quality visibility
- Helps prioritize opportunities

✅ **Contract Renewal Intelligence**
- Proactive renewal alerts (12-month window)
- Days until expiration tracking
- Visual urgency indicators

✅ **Account Team Validation**
- Alert when no team members assigned
- Shows current team composition
- Encourages proper account coverage

---

## Review Notes:

1. All sections are **dynamically generated** from JSON data
2. **No hardcoded values** - everything uses mustache templates
3. **Conditional rendering** - sections adapt to data availability
4. **Responsive design** - flex layouts work on all screen sizes
5. **Professional styling** - consistent with existing Part 1 design

