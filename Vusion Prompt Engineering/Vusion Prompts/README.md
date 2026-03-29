# Vusion Group Prompt Engineering - GPTfy.ai POC

## Project Overview

This repository contains prompt engineering work for **Vusion Group**'s Proof of Concept (POC) with **GPTfy.ai**. The project focuses on developing and refining two main AI-powered prompts for Salesforce integration:

1. **Account 360** - Comprehensive account intelligence dashboard
2. **Deal Coach** - Opportunity analysis and deal guidance system

## Project Status

**Current Phase:** POC (Proof of Concept)  
**Platform:** GPTfy.ai  
**Integration:** Salesforce

---

## Prompt Structure

### Account 360

The Account 360 prompt is divided into **2 parts**:

1. **Vusion Account 360 Part 1**
   - Combined Account Header & Executive Summary
   - Risk & Strength Assessment
   - Key Performance Indicators (KPIs)
   - Opportunity Pipeline Table

2. **Vusion Account 360 Part 2**
   - Revenue & Opportunity Intelligence
   - Relationship & Service Intelligence
   - Additional account insights

### Deal Coach

The Deal Coach prompt is divided into **4 parts**:

1. **Deal Health Summary & Opportunity Profile**
   - Overall deal health assessment
   - Opportunity profile and key metrics

2. **Stage Analysis & Risk Intelligence**
   - Current stage analysis
   - Risk identification and mitigation

3. **Stakeholder & Competitive Intelligence**
   - Stakeholder mapping and influence
   - Competitive landscape analysis

4. **Deal Execution & Action Plan**
   - Recommended actions
   - Execution roadmap

---

## Prompt Engineering Workflow

The iterative prompt engineering process follows this workflow:

```
1. Deploy Prompt
   ↓
2. Run on Test Record
   ↓
3. Find Newly Created Security Audit Record
   ↓
4. Check Response Quality
   ↓
5. Analyze Feedback & Identify Issues
   ↓
6. Iterate & Refine Prompt
   ↓
7. Redeploy Updated Prompt
   ↓
8. Repeat (Steps 2-7)
```

### Detailed Workflow Steps

1. **Deploy Prompt**
   - Update prompt in GPTfy.ai platform
   - Configure prompt parameters and settings
   - Save and activate prompt version

2. **Run on Test Record**
   - Select a representative Salesforce record (Account or Opportunity)
   - Execute prompt through GPTfy.ai interface
   - Trigger prompt execution

3. **Find Security Audit Record**
   - Navigate to Security Audit logs in Salesforce
   - Locate the newly created audit record for the prompt execution
   - Review execution metadata and timestamps

4. **Check Response**
   - Review generated HTML/output
   - Validate data accuracy
   - Check formatting and structure
   - Verify calculations (Pipeline Value, Revenue at Risk, etc.)
   - Test hyperlinks and functionality

5. **Iterate Prompt Engineering**
   - Document issues and feedback
   - Update prompt instructions
   - Refine calculations and logic
   - Adjust formatting requirements
   - Improve data extraction rules

6. **Redeploy**
   - Save updated prompt version
   - Deploy to GPTfy.ai platform
   - Return to step 2 for validation

---

## Customer Feedback & Required Updates

### Account 360 Feedback

#### Account Level: Revenue & Opportunity Intelligence

**Current Issues:**
- Revenue & Opportunity section does not add much value to the 360 view
- Lacks sufficient detail and actionable insights

**Required Enhancements:**

1. **Product Mix Analysis**
   - Show mix of products sold to help identify whitespace opportunities
   - Display product category breakdown
   - Highlight underpenetrated product areas

2. **Pipeline Value Enhancement**
   - Show forecast categories (Commit, Best Case, Most Likely, Pipeline)
   - Break down pipeline by forecast category
   - Display weighted pipeline value

3. **Contract Renewal Intelligence**
   - Identify contracts ending in the next 12 months
   - Prepare renewal readiness assessment
   - Highlight renewal risks and opportunities
   - Show contract value at risk

#### Account 360 View - General Issues

**Performance:**
- Loading time is too long (±1 minute)
- Need to consider pre-loading/caching strategies

**Data Integration:**
- **PowerMap/People.ai Integration Required**
  - Include influence levels from PowerMap/People.ai object
  - Map stakeholder influence and engagement
  - Display influence network visualization

**Additional Requirements:**
- **Open Invoices**
  - Include if there are any open invoices
  - Show invoice status and aging
  - Display payment terms and due dates

- **Account Team Validation**
  - If account teams are empty, raise alert
  - Prompt user to add team members
  - Display current team composition

#### Account Level: Relationship & Service Intelligence

**Performance:**
- Takes 1 minute to load (too long)
- Requires optimization and caching

**Data Integration:**
- **People.ai/MEDDICC Object Integration**
  - Include information from People.ai/MEDDICC object
  - Display stored influence levels
  - Show stakeholder engagement metrics

**Per Stakeholder Card Enhancements:**

1. **Next Actions**
   - What are the next actions for each stakeholder?
   - Display recommended engagement activities
   - Show action timeline and priority

2. **LinkedIn Integration**
   - Link to LinkedIn profile for each stakeholder
   - Display LinkedIn activity and updates

3. **News Integration**
   - Link to news related to this person
   - Show recent news mentions
   - Display industry updates relevant to stakeholder

4. **Stakeholder Display Logic**
   - Clarify: What happens if you have 10+ contacts?
   - Will you show only 3? Or all with pagination?
   - Define display rules and limits

### Deal Coach Feedback

**Status:** Feedback to be provided later

---

## Update Requirements by Prompt Part

### Account 360 Part 1 - Required Updates

**New Sections/Features:**
1. ✅ **Product Mix Analysis** (in Revenue & Opportunity section)
   - Product category breakdown
   - Whitespace identification
   - Cross-sell/upsell opportunities

2. ✅ **Enhanced Pipeline Value Display**
   - Forecast category breakdown
   - Weighted pipeline calculation
   - Category-wise pipeline distribution

3. ✅ **Contract Renewal Section**
   - Contracts ending in next 12 months
   - Renewal readiness score
   - Contract value at risk

4. ✅ **Open Invoices Section**
   - Invoice status table
   - Aging analysis
   - Payment terms display

5. ✅ **Account Team Validation**
   - Team member count
   - Alert if team is empty
   - Team role distribution

### Account 360 Part 2 - Required Updates

**New Sections/Features:**
1. ✅ **PowerMap/People.ai Integration**
   - Influence level mapping
   - Stakeholder influence network
   - Engagement scoring

2. ✅ **Enhanced Stakeholder Cards**
   - Next actions per stakeholder
   - LinkedIn profile links
   - News article links
   - Stakeholder display logic (10+ contacts handling)

3. ✅ **Performance Optimization**
   - Caching strategy
   - Pre-loading recommendations
   - Load time reduction (<30 seconds target)

4. ✅ **MEDDICC Object Integration**
   - MEDDICC scoring display
   - Influence level indicators
   - Stakeholder qualification metrics

### Deal Coach Part 1 - Deal Health Summary & Opportunity Profile

**Status:** Awaiting customer feedback

### Deal Coach Part 2 - Stage Analysis & Risk Intelligence

**Status:** Awaiting customer feedback

### Deal Coach Part 3 - Stakeholder & Competitive Intelligence

**Status:** Awaiting customer feedback

### Deal Coach Part 4 - Deal Execution & Action Plan

**Status:** Awaiting customer feedback

---

## Technical Notes

### Current Prompt Implementation (Account 360 Part 1)

The current Account 360 Part 1 prompt includes:

- **Mandatory Calculation Checkpoint** - Ensures accurate Pipeline Value and Revenue at Risk calculations
- **HTML Output Format** - Single continuous HTML string without line breaks
- **Dynamic Data Extraction** - All content generated from JSON data
- **Hyperlink Support** - Functional links to Salesforce records
- **Conditional Formatting** - Overdue opportunities highlighted, large amounts bolded

### Key Calculation Requirements

1. **Pipeline Value**
   - Must sum ALL open opportunities (not just one)
   - Exclude: "Closed Won", "Closed Lost", "Closed" stages
   - Display total in currency format

2. **Revenue at Risk**
   - Opportunities closing within 30 days
   - Calculate from current date + 30 days
   - Sum all qualifying opportunity amounts

3. **Active Opportunities Count**
   - Count opportunities not in closed stages

4. **Critical Cases Count**
   - Count cases where Priority = 'Critical' AND IsClosed = false

5. **Key Stakeholders Count**
   - Count unique ContactId values in OpportunityContactRoles

---

## Next Steps

1. **Immediate Actions:**
   - [ ] Update Account 360 Part 1 with Revenue & Opportunity enhancements
   - [ ] Add Product Mix Analysis section
   - [ ] Implement Forecast Category display
   - [ ] Add Contract Renewal section
   - [ ] Include Open Invoices section
   - [ ] Add Account Team validation

2. **Account 360 Part 2 Updates:**
   - [ ] Integrate PowerMap/People.ai object
   - [ ] Enhance stakeholder cards with next actions
   - [ ] Add LinkedIn and News links
   - [ ] Define stakeholder display logic (10+ contacts)
   - [ ] Optimize performance (reduce load time)

3. **Deal Coach Updates:**
   - [ ] Await customer feedback
   - [ ] Document feedback when received
   - [ ] Plan updates for each of the 4 parts

4. **Testing & Validation:**
   - [ ] Test each updated prompt on sample records
   - [ ] Validate calculations and data accuracy
   - [ ] Check Security Audit records
   - [ ] Verify response quality and formatting

---

## Resources

- **GPTfy.ai Platform:** [Platform URL]
- **Salesforce Org:** [Org URL]
- **Documentation:** [Internal docs link]
- **Contact:** [Project contact information]

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2025-01-XX | Initial README creation | [Name] |

---

## Notes

- All prompts must output clean HTML without markdown formatting
- Calculations must be verified before HTML generation
- All data must be dynamically extracted from JSON (no hardcoded values)
- Performance optimization is critical for user experience
- Integration with PowerMap/People.ai and MEDDICC objects is required
