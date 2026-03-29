# Prompt Engineering Checklist
## Use This Checklist BEFORE Delivering Any Complete Prompt

---

## ✅ PRE-DEVELOPMENT CHECKLIST

### 1. Requirements Gathering
- [ ] **Read all customer feedback** for the specific prompt part
- [ ] **Identify all required new sections** from feedback
- [ ] **List all required data objects/fields** needed
- [ ] **Query Salesforce org** to verify object/field availability
- [ ] **Document data structure** (relationships, field names, API names)
- [ ] **Identify conditional logic** requirements (if/then scenarios)
- [ ] **Note any performance concerns** mentioned in feedback

### 2. Current Prompt Analysis
- [ ] **Retrieve current prompt** from Salesforce
- [ ] **Analyze existing structure** (sections, calculations, formatting)
- [ ] **Identify what stays** (existing working sections)
- [ ] **Identify what changes** (modifications to existing sections)
- [ ] **Identify what's new** (completely new sections)
- [ ] **Check prompt status** (must be Inactive for updates)

### 3. Data Model Verification
- [ ] **Verify object relationships** (Account → Opportunity → Product, etc.)
- [ ] **Check field API names** (use describe to confirm)
- [ ] **Test sample queries** to understand data structure
- [ ] **Identify missing fields** and document what's needed
- [ ] **Note any custom fields** vs standard fields
- [ ] **Verify date/time formats** in sample data

---

## ✅ DEVELOPMENT CHECKLIST

### 4. Calculation Steps
- [ ] **List all calculation steps** required (numbered STEP 1, STEP 2, etc.)
- [ ] **Each step has clear process** (a, b, c sub-steps)
- [ ] **Each step has workspace** for AI to show calculations
- [ ] **Include worked examples** for complex calculations
- [ ] **Handle null/empty values** in calculations
- [ ] **Specify date calculations** (current date, cutoffs, age)
- [ ] **Include validation checks** (e.g., "Must be sum of ALL opportunities")

### 5. HTML Section Structure
- [ ] **Define section order** (numbered list: 1, 2, 3, etc.)
- [ ] **Each section has clear header** and purpose
- [ ] **Specify layout type** (flex, table, cards, etc.)
- [ ] **Define conditional rendering** (if data exists, if count > 0, etc.)
- [ ] **Specify styling requirements** (colors, borders, spacing)
- [ ] **Include sample HTML structure** for each new section
- [ ] **Ensure responsive design** (flex-wrap, min-width, etc.)

### 6. Data Extraction Requirements
- [ ] **List all JSON paths** needed (e.g., {{{Opportunities.Name}}})
- [ ] **Specify mustache template syntax** correctly
- [ ] **Handle nested arrays** properly (OpportunityLineItems, etc.)
- [ ] **Define iteration logic** (for each opportunity, for each contact)
- [ ] **Specify data filtering** (only open opportunities, only active contracts)
- [ ] **Handle missing data** (show "N/A", skip section, etc.)

### 7. Hyperlinks & Navigation
- [ ] **All record links use correct format** (href="/{Id}")
- [ ] **Links include proper styling** (color, text-decoration)
- [ ] **Test link structure** matches Salesforce record URLs
- [ ] **External links** (LinkedIn, News) if required
- [ ] **Link text is descriptive** (not just "Click here")

### 8. Formatting & Styling
- [ ] **Consistent color scheme** (use hex codes, not color names)
- [ ] **Consistent font sizes** (use rem/px consistently)
- [ ] **Consistent spacing** (padding, margin, gap)
- [ ] **Conditional formatting rules** clearly defined
- [ ] **Date formatting** specified (e.g., "Jan 1, 2000")
- [ ] **Number formatting** specified (currency, decimals, thousands separator)
- [ ] **Age calculations** specified (days, months, years)

### 9. Conditional Logic
- [ ] **All if/then scenarios** clearly documented
- [ ] **Count-based conditions** specified (if count = 0, if count > 10)
- [ ] **Date-based conditions** specified (if overdue, if expiring soon)
- [ ] **Status-based conditions** specified (if active, if closed)
- [ ] **Priority-based conditions** specified (if critical, if high)
- [ ] **Alternative displays** for each condition

### 10. Error Handling & Edge Cases
- [ ] **Handle empty arrays** (no opportunities, no contacts, no cases)
- [ ] **Handle null values** (null dates, null amounts, null names)
- [ ] **Handle missing fields** (field doesn't exist in data)
- [ ] **Handle zero values** (€0 amounts, 0 counts)
- [ ] **Handle very large numbers** (formatting, display)
- [ ] **Handle very long text** (word-wrap, truncation)
- [ ] **Handle special characters** (in names, descriptions)

---

## ✅ OUTPUT FORMATTING CHECKLIST

### 11. HTML Output Requirements
- [ ] **No markdown formatting** (no backticks, no markdown)
- [ ] **No escaped characters** (no \n, no \t, no \r)
- [ ] **No line breaks** in output (single continuous string)
- [ ] **No spaces between tags** ("><" not "> <")
- [ ] **Starts with <div** (not <html>, not backticks)
- [ ] **Font family specified** ('Montserrat', sans-serif)
- [ ] **All inline styles** (no external CSS)
- [ ] **Box-sizing: border-box** on all containers

### 12. Validation Protocol
- [ ] **Scan for \n characters** - remove all
- [ ] **Scan for \r characters** - remove all
- [ ] **Scan for \t characters** - remove all
- [ ] **Replace "> <" with "><"** - remove spaces
- [ ] **Verify single line** - no line breaks
- [ ] **Test in text editor** - should be one continuous line

### 13. Sample Output
- [ ] **Include complete sample HTML** structure
- [ ] **Show all sections** in correct order
- [ ] **Use placeholder format** [FieldName] for dynamic values
- [ ] **Include mustache templates** {{{FieldName}}} where needed
- [ ] **Show conditional examples** (if empty, if populated)
- [ ] **Demonstrate styling** (colors, borders, spacing)

---

## ✅ CONTENT QUALITY CHECKLIST

### 14. Dynamic Content Requirements
- [ ] **No hardcoded values** (all data from JSON)
- [ ] **No placeholder text** in final output (use actual data)
- [ ] **All calculations accurate** (sums, counts, percentages)
- [ ] **All dates formatted** consistently
- [ ] **All amounts formatted** with currency symbol
- [ ] **All percentages calculated** correctly

### 15. Business Logic
- [ ] **Calculations match business rules** (pipeline = sum of open opps)
- [ ] **Date logic correct** (30 days, 12 months, etc.)
- [ ] **Filtering logic correct** (exclude closed, include active)
- [ ] **Priority logic correct** (critical > high > medium > low)
- [ ] **Influence logic correct** (high/medium/low based on criteria)

### 16. User Experience
- [ ] **Sections flow logically** (overview → details → actions)
- [ ] **Important info prominent** (alerts, warnings, high priority)
- [ ] **Visual hierarchy clear** (headers, subheaders, body text)
- [ ] **Actionable insights** (not just data display)
- [ ] **Executive-appropriate** (C-level presentation quality)

---

## ✅ FEEDBACK ALIGNMENT CHECKLIST

### 17. Customer Feedback Compliance
- [ ] **All feedback items addressed** (check each requirement)
- [ ] **New sections match feedback** (exact requirements met)
- [ ] **Enhanced sections improved** (based on feedback)
- [ ] **Performance concerns noted** (if mentioned in feedback)
- [ ] **Missing features documented** (if not yet available)

### 18. Part-Specific Requirements
- [ ] **Part 1 requirements** (Product Mix, Forecast, Contracts, Team)
- [ ] **Part 2 requirements** (LinkedIn, News, 10+ contacts, Next Actions)
- [ ] **Deal Coach requirements** (when feedback received)
- [ ] **Cross-part consistency** (shared styling, shared logic)

---

## ✅ TECHNICAL VALIDATION CHECKLIST

### 19. Prompt Structure
- [ ] **Clear section headers** (MANDATORY, CRITICAL, REQUIRED)
- [ ] **Logical flow** (calculations → HTML generation → sections)
- [ ] **No contradictions** (instructions don't conflict)
- [ ] **Complete instructions** (no missing steps)
- [ ] **Proper emphasis** (bold, caps for critical items)

### 20. Mustache Template Syntax
- [ ] **Correct syntax** {{{Object.Field}}} for nested data
- [ ] **Array iteration** properly specified
- [ ] **Conditional mustache** if needed
- [ ] **Field paths verified** against actual data structure

### 21. Salesforce Integration
- [ ] **Record IDs correct format** (15 or 18 character)
- [ ] **URL structure correct** (/lightning/r/Object/Id/view)
- [ ] **Field API names correct** (__c for custom, no __c for standard)
- [ ] **Object relationships correct** (parent → child)

---

## ✅ FINAL REVIEW CHECKLIST

### 22. Completeness Check
- [ ] **All sections included** (no missing sections)
- [ ] **All calculations included** (no missing steps)
- [ ] **All requirements met** (feedback fully addressed)
- [ ] **Sample HTML complete** (shows full structure)
- [ ] **Instructions complete** (no gaps in logic)

### 23. Quality Assurance
- [ ] **Spell-checked** (no typos)
- [ ] **Grammar checked** (clear instructions)
- [ ] **Consistency checked** (terminology, formatting)
- [ ] **Clarity checked** (instructions are unambiguous)
- [ ] **Completeness checked** (nothing left to "figure out")

### 24. Documentation
- [ ] **Changes summary created** (what's new, what changed)
- [ ] **Data requirements documented** (what fields/objects needed)
- [ ] **Section order documented** (numbered list)
- [ ] **Calculation logic documented** (step-by-step)
- [ ] **Conditional logic documented** (if/then scenarios)

---

## ✅ DELIVERY CHECKLIST

### 25. Before Delivering to User
- [ ] **Complete prompt file created** (full text, not snippets)
- [ ] **File is readable** (proper formatting, clear structure)
- [ ] **All sections present** (nothing cut off)
- [ ] **Character count reasonable** (not truncated)
- [ ] **Ready for deployment** (can be copied directly)

### 26. User Communication
- [ ] **Summary provided** (what's new, what changed)
- [ ] **Section order listed** (numbered list)
- [ ] **Key features highlighted** (new capabilities)
- [ ] **Data requirements noted** (what fields needed)
- [ ] **Deployment instructions** (how to update in Salesforce)

### 27. Post-Delivery
- [ ] **Ready for testing** (prompt can be deployed)
- [ ] **Test account identified** (which record to use)
- [ ] **Expected results documented** (what should appear)
- [ ] **Iteration plan ready** (how to refine based on results)

---

## 📋 CHECKLIST USAGE INSTRUCTIONS

### When to Use:
- **BEFORE** creating any complete prompt
- **BEFORE** delivering prompt to user
- **AFTER** receiving feedback (to ensure all items addressed)

### How to Use:
1. Go through each section systematically
2. Check off items as you complete them
3. Don't skip sections - complete all relevant items
4. If item doesn't apply, mark as N/A with note
5. Review unchecked items before delivery

### Quality Standard:
- **Minimum 90% completion** before delivery
- **All critical items** (marked with ⚠️) must be complete
- **All feedback items** must be addressed
- **All calculations** must be included

---

## 🎯 CRITICAL ITEMS (Must Complete)

These items are **MANDATORY** and cannot be skipped:

1. ✅ **All customer feedback addressed**
2. ✅ **Complete prompt text provided** (not snippets)
3. ✅ **All calculation steps included**
4. ✅ **All HTML sections included**
5. ✅ **Sample HTML structure provided**
6. ✅ **No hardcoded values** (all dynamic)
7. ✅ **Proper mustache syntax** ({{{Object.Field}}})
8. ✅ **Output format correct** (single line, no breaks)
9. ✅ **Data requirements documented**
10. ✅ **Section order specified**

---

**Last Updated:** 2025-01-XX  
**Version:** 1.0  
**For Use With:** Account 360 Part 1, Part 2, Deal Coach (all parts)

