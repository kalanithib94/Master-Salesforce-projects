# Corrected Prompt Command - SECTION 3: STAGE DURATION ANALYSIS

## REPLACE YOUR CURRENT SECTION 3 WITH THIS:

**SECTION 3: STAGE DURATION ANALYSIS**

**CALCULATION FOR STAGE BY STAGE BREAKDOWN:**

**STEP 1: FILTER AND SORT STAGE TRANSITIONS**
- FILTER the Histories array to only include records where Field = "StageName"
- SORT the filtered records by CreatedDate in ASCENDING order (oldest first)
- STORE the result as stageTransitionRecords
- COUNT the number of records and store as stageTransitionCount

**STEP 2: IDENTIFY AND CALCULATE INITIAL STAGE**
- The initial stage name is the OldValue of the FIRST record in stageTransitionRecords
- The initial stage START DATE is the Opportunity CreatedDate
- The initial stage END DATE is the CreatedDate of the FIRST record in stageTransitionRecords
- CALCULATE initial stage duration in days: END DATE - START DATE (convert to integer, no decimals)
- STORE as: initialStageName, initialStageStartDate, initialStageEndDate, initialStageDurationDays

**STEP 3: CALCULATE SUBSEQUENT STAGES**
- CREATE an empty array called allStages
- ADD the initial stage to allStages:
  {
    name: initialStageName,
    startDate: initialStageStartDate,
    endDate: initialStageEndDate,
    durationDays: initialStageDurationDays,
    isCurrent: false
  }

- FOR EACH record in stageTransitionRecords (loop through each one):
  - Current record index = i
  - Stage Name = NewValue of current record
  - Stage Start Date = CreatedDate of current record
  - IF this is NOT the last record:
    - Stage End Date = CreatedDate of the NEXT record (index i+1)
  - ELSE (this IS the last record):
    - Stage End Date = CurrentDate__c
    - Set isCurrent = true
  - CALCULATE Stage Duration = Stage End Date - Stage Start Date (in days, as integer)
  - ADD to allStages:
    {
      name: Stage Name,
      startDate: Stage Start Date,
      endDate: Stage End Date,
      durationDays: Stage Duration,
      isCurrent: isCurrent value
    }

**STEP 4: CALCULATE SUMMARY METRICS**
- totalStagesCount = 1 + stageTransitionCount
- currentStageDurationDays = CurrentDate__c - Last History CreatedDate (the CreatedDate of the last record in stageTransitionRecords)
- opportunityAgeDays = CurrentDate__c - CreatedDate (in days, as integer)
- formattedCreatedDate = format CreatedDate as "MMM DD, YYYY" (e.g., "Jul 26, 2019")

**STEP 5: ASSIGN HEALTH COLORS AND FORMATTING FOR EACH STAGE**
- FOR EACH stage in allStages:
  - IF durationDays <= 30:
    - bgColor = "#d4edda"
    - borderColor = "#28a745"
    - textColor = "#155724"
    - healthStatus = "GREEN"
  - ELSE IF durationDays <= 60:
    - bgColor = "#fff3cd"
    - borderColor = "#ffc107"
    - textColor = "#856404"
    - healthStatus = "YELLOW"
  - ELSE (durationDays > 60):
    - bgColor = "#ffcccc"
    - borderColor = "#c23934"
    - textColor = "#c23934"
    - healthStatus = "RED"
    - criticalDelayReason = "Stage exceeded 60-day threshold - requires immediate attention"
  
  - FORMAT startDate as "MMM DD, YYYY" and store as startDateFormatted
  - CALCULATE percentage = (durationDays / opportunityAgeDays) * 100, format to 1 decimal place with % symbol

**STEP 6: VERIFY CALCULATIONS**
- Sum all durationDays from allStages
- Verify sum equals opportunityAgeDays (±1 day tolerance is acceptable)
- Ensure all durations are integers (no decimals)
- Ensure all dates are formatted as "MMM DD, YYYY"

**STEP 7: DETERMINE IF CRITICAL ALERTS SECTION IS NEEDED**
- hasCriticalStages = false
- FOR EACH stage in allStages:
  - IF stage.durationDays > 60:
    - Set hasCriticalStages = true
    - BREAK loop
- IF hasCriticalStages = true:
  - INCLUDE Critical Alerts Summary section in HTML output
- ELSE:
  - OMIT Critical Alerts Summary section

---

## ADDITIONAL FIXES FOR HTML TEMPLATE:

### Fix 1: Executive Summary - Date Warnings
Replace the date display logic with:

```
<li><strong>Requested Delivery date:</strong> [CALCULATE: daysDiff = (DateInstallationSouhaitee__c - CurrentDate__c) in days. IF daysDiff >= 60 OR daysDiff < 0, show: <span style="color: #d32f2f; font-weight: 700;">⚠️ [FORMAT DateInstallationSouhaitee__c as "MMM DD, YYYY"]</span>, ELSE show: [FORMAT DateInstallationSouhaitee__c as "MMM DD, YYYY"]]</li>
<li><strong>Expected Close:</strong> [CALCULATE: daysDiff = (CloseDate - CurrentDate__c) in days. IF daysDiff >= 60 OR daysDiff < 0, show: <span style="color: #d32f2f; font-weight: 700;">⚠️ [FORMAT CloseDate as "MMM DD, YYYY"]</span>, ELSE show: [FORMAT CloseDate as "MMM DD, YYYY"]]</li>
```

### Fix 2: Current Stage Duration Metric Box
Replace with:
```
<div style="background-color: [IF currentStageDurationDays > 60 THEN #ffcccc ELSE IF currentStageDurationDays > 30 THEN #fff3cd ELSE #f8f9fa]; padding: 1rem; border-radius: 4px; border-left: 4px solid [IF currentStageDurationDays <= 30 THEN #28a745, IF 31-60 THEN #ffc107, IF >60 THEN #c23934];">
<div style="font-size: 0.75rem; color: #666; margin-bottom: 0.25rem; text-transform: uppercase; font-weight: 600;">Current Stage Duration</div>
<div style="font-size: 1.5rem; font-weight: 700; color: [IF currentStageDurationDays <= 30 THEN #28a745, IF 31-60 THEN #856404, IF >60 THEN #c23934];">[INSERT: currentStageDurationDays] days [IF currentStageDurationDays > 60 THEN 🚨 ELSE empty]</div>
<div style="font-size: 0.8rem; color: #666; margin-top: 0.25rem;">Since: [INSERT: format last stage startDate as "MMM DD, YYYY"]</div>
</div>
```

### Fix 3: Stage-by-Stage Breakdown - Generate Blocks
Replace the placeholder with actual loop generation:

```
<!-- FOR EACH stage in allStages, GENERATE ONE COMPLETE BLOCK -->
[LOOP through allStages array]
<div style="background-color: [INSERT: stage.bgColor]; padding: 1rem; border-radius: 4px; margin-bottom: 0.75rem; border-left: 4px solid [INSERT: stage.borderColor];">
<div style="display: flex; justify-content: space-between; align-items: center;">
<div style="font-size: 0.95rem; font-weight: 600; color: [INSERT: IF stage.isCurrent THEN #ffffff ELSE #16325c];">
[INSERT: stage.name] [INSERT: IF stage.isCurrent THEN ⭐ CURRENT STAGE ELSE empty]
</div>
<div style="font-size: 0.85rem; color: [INSERT: IF stage.isCurrent THEN #ffffff ELSE #666];">
[INSERT: stage.startDateFormatted]
</div>
<div style="font-size: 1.1rem; font-weight: 700; color: [INSERT: stage.textColor];">
[INSERT: stage.durationDays] days
</div>
</div>
[IF stage.durationDays > 60, INSERT:]
<div style="background-color: #ffffff; padding: 0.75rem; border-radius: 4px; margin-top: 0.5rem; border: 1px solid #c23934;">
<div style="font-size: 0.85rem; color: #c23934; font-weight: 600;">🚨 Critical Delay</div>
<div style="font-size: 0.8rem; color: #666; margin-top: 0.25rem;">[INSERT: stage.criticalDelayReason]</div>
</div>
[END IF]
</div>
[END LOOP]
```

### Fix 4: Add Critical Alerts Summary Section
After the Stage Duration Health Legend section, IF hasCriticalStages = true, ADD:

```
<!-- Critical Alerts Summary -->
<div style="background-color: #ffcccc; padding: 1.5rem; border-radius: 6px; border: 2px solid #c23934; margin-bottom: 2rem;">
<h2 style="font-weight: 600; color: #c23934; font-size: 1.3rem; margin-bottom: 1rem;">🚨 Critical Stage Alerts</h2>
[FOR EACH stage in allStages WHERE durationDays > 60:]
<div style="background-color: #ffffff; padding: 1rem; border-radius: 4px; margin-bottom: 0.75rem; border-left: 4px solid #c23934;">
<div style="font-weight: 600; color: #c23934; margin-bottom: 0.5rem;">[INSERT: stage.name]</div>
<div style="font-size: 0.9rem; color: #333; margin-bottom: 0.25rem;">Duration: <strong>[INSERT: stage.durationDays] days</strong> (exceeds 60-day threshold)</div>
<div style="font-size: 0.85rem; color: #666; margin-top: 0.5rem;">[INSERT: stage.criticalDelayReason]</div>
</div>
[END FOR EACH]
<div style="background-color: #fff3cd; padding: 1rem; border-radius: 4px; margin-top: 1rem; border-left: 4px solid #ffc107;">
<div style="font-weight: 600; color: #856404; margin-bottom: 0.5rem;">Overall Recommendation:</div>
<div style="font-size: 0.9rem; color: #333;">[INSERT: Generate actionable recommendation based on all critical stages - e.g., "Immediate intervention required for [stage names]. Schedule executive review and develop acceleration plan."]</div>
</div>
</div>
```

---

## KEY POINTS TO REMEMBER:

1. **Duration Calculation**: Always subtract: End Date - Start Date (not the other way around)
2. **Initial Stage**: Comes from OldValue of first history record, duration from CreatedDate to first history CreatedDate
3. **Current Stage**: Is the last stage (NewValue of last history record), duration from last history CreatedDate to CurrentDate__c
4. **Total Stages**: Always 1 + number of history records
5. **All Durations**: Must be integers (use Math.floor or parseInt)
6. **Date Formatting**: Always "MMM DD, YYYY" format (e.g., "Jul 26, 2019")
7. **Health Colors**: Based on duration thresholds (0-30, 31-60, 60+)
8. **Critical Alerts**: Only include if ANY stage exceeds 60 days

