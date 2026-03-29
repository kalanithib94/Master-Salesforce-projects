# Prompt Command Version Comparison

## Overview
- **Version 1**: Original prompt command (with calculation errors)
- **Version 2**: Corrected prompt command (all fixes applied)

## Key Differences Between Version 1 and Version 2

### 1. Stage Duration Calculation Logic (CRITICAL FIX)

**Version 1 (WRONG):**
```
Duration 1 = CreatedDate - 1st stage date
Duration of stage 2 = 1st stage date - 2nd stage date
```

**Version 2 (CORRECT):**
```
Initial Stage Duration = First History CreatedDate - Opportunity CreatedDate
Stage 2 Duration = Second History CreatedDate - First History CreatedDate
Stage 3 Duration = Third History CreatedDate - Second History CreatedDate
...
Last Stage Duration = CurrentDate__c - Last History CreatedDate
```

### 2. Initial Stage Extraction

**Version 1 (WRONG):**
- Uses `NewValue` of first record as initial stage

**Version 2 (CORRECT):**
- Uses `OldValue` of first record as initial stage name
- Calculates duration from Opportunity CreatedDate to first history CreatedDate

### 3. Current Stage Duration

**Version 1 (WRONG):**
- Shows entire opportunity age (2263 days in example)

**Version 2 (CORRECT):**
- Calculates separately: CurrentDate__c - Last History CreatedDate
- Displays actual time spent in current stage

### 4. Total Stages Count

**Version 1 (WRONG):**
- Shows count of history records only (5 in example)

**Version 2 (CORRECT):**
- Calculates: 1 (initial stage) + number of transitions
- Example: 5 history records = 6 total stages

### 5. Stage-by-Stage Breakdown Generation

**Version 1 (WRONG):**
- Unclear instructions on how to generate blocks
- All stages showed 0 days except last

**Version 2 (CORRECT):**
- Clear loop instructions: FOR EACH stage in allStages
- Proper duration calculation for each stage
- Includes isCurrent flag for last stage

### 6. Health Colors Assignment

**Version 1 (WRONG):**
- Not clearly defined per stage
- All stages showed same colors

**Version 2 (CORRECT):**
- Explicit color assignment based on duration thresholds:
  - GREEN (0-30 days): #d4edda, #28a745, #155724
  - YELLOW (31-60 days): #fff3cd, #ffc107, #856404
  - RED (60+ days): #ffcccc, #c23934, #c23934

### 7. Current Stage Indicator

**Version 1:**
- Missing ⭐ CURRENT STAGE indicator

**Version 2:**
- Added ⭐ CURRENT STAGE indicator for last stage (isCurrent = true)
- White text color for current stage when background is red

### 8. Critical Alerts Summary Section

**Version 1:**
- Mentioned but not properly implemented
- Missing from output

**Version 2:**
- Proper conditional logic: hasCriticalStages flag
- Only includes section if ANY stage exceeds 60 days
- Includes individual alerts and overall recommendation

### 9. Date Warning Logic

**Version 1:**
- Simple check: if date >= 60 days from today

**Version 2:**
- Enhanced logic: if date >= 60 days OR date < 0 (past dates)
- Proper date formatting: "MMM DD, YYYY"
- Applied to both Installation Date and Close Date

### 10. Date Formatting

**Version 1:**
- Inconsistent date formatting

**Version 2:**
- All dates formatted as "MMM DD, YYYY" consistently
- startDateFormatted for each stage
- formattedCreatedDate for opportunity

### 11. Critical Delay Boxes

**Version 1:**
- Not included in stage blocks

**Version 2:**
- Conditional inclusion: IF stage.durationDays > 60
- Includes criticalDelayReason
- Styled with red border

### 12. Verification Checklist

**Version 1:**
- Basic checklist

**Version 2:**
- Enhanced checklist with specific calculations
- Includes verification of sum of durations
- Ensures all durations are integers

## Expected Output Differences

### Example: Your Sample Data

**Version 1 Output Issues:**
- Initial stage: 0 days (WRONG)
- Budget approved: 0 days (WRONG)
- Quote Sent: 0 days (WRONG)
- Verbal agreement: 0 days (WRONG)
- Closed: 2263 days (WRONG - this is opportunity age, not stage duration)
- Total Stages: 5 (WRONG - should be 6)

**Version 2 Expected Output:**
- Interest: ~5 days (Jul 26 - Jul 31, 2019) ✅
- Budget approved: ~43 days (Jul 31 - Sep 12, 2019) ✅
- Quote Sent: ~18 days (Sep 12 - Sep 30, 2019) ✅
- Verbal agreement: ~56 days (Sep 30 - Nov 25, 2019) ✅
- Budget approved (again): ~108 days (Nov 25, 2019 - Mar 13, 2020) ✅
- Closed: ~2075 days (Mar 13, 2020 - Nov 17, 2025) ✅
- Total Stages: 6 ✅
- Current Stage Duration: ~2075 days (not 2263) ✅

## When to Use Each Version

**Use Version 1:**
- ❌ Do NOT use - contains calculation errors
- Only for reference to understand what was wrong

**Use Version 2:**
- ✅ Use for all new implementations
- ✅ Correct calculations
- ✅ Proper stage duration tracking
- ✅ Accurate health scoring

## Migration Guide

If you're currently using Version 1:

1. Replace the entire SECTION 3 with Version 2's SECTION 3
2. Update HTML template sections for:
   - Date warning logic
   - Current stage duration display
   - Stage block generation
   - Critical alerts summary
3. Test with sample data to verify calculations
4. Ensure all durations are integers
5. Verify sum of stage durations equals opportunity age

## Testing Checklist

After implementing Version 2, verify:

- [ ] Initial stage uses OldValue of first history record
- [ ] Initial stage duration = First History CreatedDate - Opportunity CreatedDate
- [ ] Each subsequent stage duration = Next History CreatedDate - Current History CreatedDate
- [ ] Last stage duration = CurrentDate__c - Last History CreatedDate
- [ ] Sum of all stage durations = Opportunity Age (±1 day)
- [ ] Total stages count = 1 + number of history records
- [ ] Health colors assigned correctly (GREEN/YELLOW/RED)
- [ ] ⭐ CURRENT STAGE indicator on last stage
- [ ] Critical delay boxes only for stages > 60 days
- [ ] Critical Alerts Summary only if any stage > 60 days
- [ ] All dates formatted as "MMM DD, YYYY"
- [ ] All durations are integers (no decimals)

