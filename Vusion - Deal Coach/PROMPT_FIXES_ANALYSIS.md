# Deal Coach Prompt - Issues and Required Fixes

## Critical Issues Found in Current Response

### 1. **Stage Duration Calculation is Completely Wrong**
**Problem**: All stages show "0 days" except the last one showing "2263 days"
**Root Cause**: The calculation logic in SECTION 3 is incorrect

**Current (WRONG) Logic:**
```
Duration 1 = CreatedDate - 1st stage date
Duration of stage 2 = 1st stage date - 2nd stage date
```

**Correct Logic Should Be:**
- **Initial Stage (Stage 1)**: Duration = First History CreatedDate - Opportunity CreatedDate
- **Stage 2**: Duration = Second History CreatedDate - First History CreatedDate  
- **Stage 3**: Duration = Third History CreatedDate - Second History CreatedDate
- **Last Stage (Current)**: Duration = CurrentDate__c - Last History CreatedDate

### 2. **Initial Stage Extraction is Wrong**
**Problem**: The prompt says to use first record's `NewValue` as stage 1, but it should use `OldValue` as the initial stage name.

**Current (WRONG):**
```
The {{{Histories.NewValue}}} of the first record would be {{stage 1}}
```

**Should Be:**
```
The {{{Histories.OldValue}}} of the first record is the initial stage name (e.g., "Interest")
The duration of this initial stage = First History CreatedDate - Opportunity CreatedDate
```

### 3. **Current Stage Duration Calculation**
**Problem**: Shows 2263 days (entire opportunity age) instead of time in current stage
**Should Be**: CurrentDate__c - Last History CreatedDate (when current stage started)

### 4. **Total Stages Count**
**Problem**: Shows "5" but should be: 1 (initial stage) + number of transitions
**Correct**: If there are 5 history records, there are 6 total stages (including initial)

### 5. **Missing Critical Alerts Summary Section**
**Problem**: The response shows stages over 60 days but doesn't include the Critical Alerts Summary section
**Required**: Should include this section when any stage exceeds 60 days

### 6. **Date Formatting Issues**
**Problem**: Some dates may not be formatted as "MMM DD, YYYY" consistently
**Required**: All dates must use this format

### 7. **Stage Health Colors Not Applied Correctly**
**Problem**: All stages show same color scheme, not based on duration thresholds
**Required**: 
- GREEN (0-30 days): bgColor="#d4edda", borderColor="#28a745", textColor="#155724"
- YELLOW (31-60 days): bgColor="#fff3cd", borderColor="#ffc107", textColor="#856404"  
- RED (60+ days): bgColor="#ffcccc", borderColor="#c23934", textColor="#c23934"

### 8. **Current Stage Indicator Missing**
**Problem**: No ⭐ indicator on the current/last stage
**Required**: Add "⭐ CURRENT STAGE" indicator to the last stage block

## Required Prompt Command Changes

### SECTION 3: STAGE DURATION ANALYSIS - CORRECTED VERSION

```
**SECTION 3: STAGE DURATION ANALYSIS**

CALCULATION FOR STAGE BY STAGE BREAKDOWN:

STEP 1: FILTER AND SORT
- FILTER Histories array where Field = "StageName"
- SORT filtered records by CreatedDate in ASCENDING order (oldest first)
- STORE as stageTransitionRecords

STEP 2: IDENTIFY INITIAL STAGE
- The initial stage name is the OldValue of the FIRST record in stageTransitionRecords
- The initial stage START DATE is the Opportunity CreatedDate
- The initial stage END DATE is the CreatedDate of the FIRST record in stageTransitionRecords
- CALCULATE initial stage duration = END DATE - START DATE (in days, as integer)
- STORE as: initialStageName, initialStageStartDate, initialStageEndDate, initialStageDuration

STEP 3: CALCULATE SUBSEQUENT STAGES
- FOR EACH record in stageTransitionRecords (starting from index 0):
  - Stage Name = NewValue of current record
  - Stage Start Date = CreatedDate of current record
  - Stage End Date = CreatedDate of NEXT record (if exists), OR CurrentDate__c (if last record)
  - Stage Duration = Stage End Date - Stage Start Date (in days, as integer)
  - STORE each stage in allStages array

STEP 4: BUILD COMPLETE STAGES ARRAY
- CREATE allStages array
- ADD initial stage: { name: initialStageName, startDate: initialStageStartDate, endDate: initialStageEndDate, durationDays: initialStageDuration }
- FOR EACH transition record, ADD: { name: NewValue, startDate: CreatedDate, endDate: nextCreatedDate or CurrentDate__c, durationDays: calculatedDuration }

STEP 5: CALCULATE METRICS
- totalStagesCount = 1 + stageTransitionRecords.length
- currentStageDurationDays = CurrentDate__c - Last History CreatedDate
- opportunityAgeDays = CurrentDate__c - CreatedDate
- formattedCreatedDate = format CreatedDate as "MMM DD, YYYY"

STEP 6: ASSIGN HEALTH COLORS FOR EACH STAGE
- FOR EACH stage in allStages:
  - IF durationDays <= 30: bgColor="#d4edda", borderColor="#28a745", textColor="#155724"
  - ELSE IF durationDays <= 60: bgColor="#fff3cd", borderColor="#ffc107", textColor="#856404"
  - ELSE: bgColor="#ffcccc", borderColor="#c23934", textColor="#c23934"
  - IF this is the LAST stage: add isCurrent=true

STEP 7: CALCULATE PERCENTAGES
- FOR EACH stage: percentage = (durationDays / opportunityAgeDays) * 100
- FORMAT as 1 decimal place with % symbol

STEP 8: VERIFY CALCULATIONS
- Sum of all stage durations should equal opportunityAgeDays (±1 day tolerance)
- All durations must be integers (no decimals)
- All dates formatted as "MMM DD, YYYY"
```

### ADDITIONAL FIXES NEEDED

#### Fix 1: Current Stage Duration Display
In the HTML template, change:
```
<div style="font-size: 1.5rem; font-weight: 700; color: [INSERT: IF currentStageDurationDays <= 30 THEN #38a169, IF 31-60 THEN #856404, IF >60 THEN #c23934];">
[INSERT: currentStageDurationDays] days [INSERT: IF currentStageDurationDays > 60 THEN 🚨 ELSE empty]
</div>
```

To use the calculated `currentStageDurationDays` (not opportunityAgeDays).

#### Fix 2: Stage Block Generation
For each stage in allStages, the HTML block should be:
```
<div style="background-color: [INSERT: stage.bgColor]; padding: 1rem; border-radius: 4px; margin-bottom: 0.75rem; border-left: 4px solid [INSERT: stage.borderColor];">
<div style="display: flex; justify-content: space-between; align-items: center;">
<div style="font-size: 0.95rem; font-weight: 600; color: [INSERT: IF stage.isCurrent THEN #ffffff ELSE #16325c];">
[INSERT: stage.name] [INSERT: IF stage.isCurrent THEN ⭐ CURRENT STAGE ELSE empty]
</div>
<div style="font-size: 0.85rem; color: [INSERT: IF stage.isCurrent THEN #ffffff ELSE #666];">
[INSERT: format stage.startDate as "MMM DD, YYYY"]
</div>
<div style="font-size: 1.1rem; font-weight: 700; color: [INSERT: stage.textColor];">
[INSERT: stage.durationDays] days
</div>
</div>
[INSERT: IF stage.durationDays > 60 THEN include critical delay box ELSE empty]
</div>
```

#### Fix 3: Add Critical Alerts Summary Section
After Stage Duration Analysis section, IF any stage.durationDays > 60, add:
```
<!-- Critical Alerts Summary -->
<div style="background-color: #ffcccc; padding: 1.5rem; border-radius: 6px; border: 2px solid #c23934; margin-bottom: 2rem;">
<h2 style="font-weight: 600; color: #c23934; font-size: 1.3rem; margin-bottom: 1rem;">
🚨 Critical Stage Alerts
</h2>
[FOR EACH stage where durationDays > 60, generate alert box]
<div style="background-color: #ffffff; padding: 1rem; border-radius: 4px; margin-bottom: 0.75rem; border-left: 4px solid #c23934;">
<strong style="color: #c23934;">[Stage Name]</strong> has been active for <strong>[durationDays] days</strong> (exceeds 60-day threshold)
<div style="font-size: 0.9rem; color: #666; margin-top: 0.5rem;">
[INSERT: criticalDelayReason based on stage analysis]
</div>
</div>
<div style="background-color: #fff3cd; padding: 1rem; border-radius: 4px; margin-top: 1rem; border-left: 4px solid #ffc107;">
<strong>Overall Recommendation:</strong> [INSERT: Actionable recommendation based on all critical alerts]
</div>
</div>
```

#### Fix 4: Date Comparison Logic
For warning indicators in Executive Summary:
```
- Calculate daysFromToday_Installation = DateInstallationSouhaitee__c - CurrentDate__c (in days)
- Calculate daysFromToday_Close = CloseDate - CurrentDate__c (in days)
- IF daysFromToday_Installation >= 60: Show warning
- IF daysFromToday_Close >= 60: Show warning
```

Note: For closed deals, these warnings may not be relevant, but the logic should still work.

## Summary of Key Changes Needed

1. ✅ Fix stage duration calculation logic (subtract dates correctly)
2. ✅ Use OldValue of first record as initial stage name
3. ✅ Calculate current stage duration separately (not opportunity age)
4. ✅ Add Critical Alerts Summary section when stages exceed 60 days
5. ✅ Apply correct health colors based on duration thresholds
6. ✅ Add ⭐ CURRENT STAGE indicator to last stage
7. ✅ Format all dates consistently as "MMM DD, YYYY"
8. ✅ Verify sum of stage durations equals opportunity age
9. ✅ Ensure all durations are integers
10. ✅ Include critical delay boxes for stages > 60 days

