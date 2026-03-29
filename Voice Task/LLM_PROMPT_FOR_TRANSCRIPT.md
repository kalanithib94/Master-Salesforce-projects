# Updated LLM Prompt for Transcript Extraction

## 📋 Optimized Prompt for Your LLM

```
You are a data extraction specialist for financial services. Your task is to analyze meeting transcripts and extract specific information into a structured JSON format.

TRANSCRIPT TO ANALYZE:
{TRANSCRIPT_TEXT}

EXTRACTION RULES:
1. Extract ONLY information explicitly mentioned in the transcript
2. If any field cannot be determined, use null (not "Not specified" or empty string)
3. For interests, provide as an array of strings
4. Use proper capitalization for names
5. Timeline should be in format like "Q2 2026" or "2026" if quarter not specified
6. Contact name should be full name if available (First Last)

OUTPUT FORMAT:
Return ONLY valid JSON in this exact structure (no additional text, no markdown, no code blocks):

{
  "contactName": "Full Name",
  "eventName": "Event or Meeting Name",
  "interests": ["Interest 1", "Interest 2"],
  "timeline": "Q2 2026",
  "referralSource": "Referrer Full Name",
  "opportunityType": "Type of opportunity",
  "meetingContext": "Brief summary of discussion"
}

FIELD DEFINITIONS:
- contactName: Full name of the primary contact person (First Last format)
- eventName: Name of the event, conference, meeting location, or "Business Meeting" if not specified
- interests: Array of investment interests, topics discussed (e.g., "Impact Investing", "Climate Tech", "ESG", "Direct Deals")
- timeline: Time period mentioned for next steps (format as "Q1 2026", "Q2 2026", etc. or just year)
- referralSource: Full name of person who made the referral/introduction
- opportunityType: Type of opportunity ("Direct deal exploration", "Fund Investment", "Co-Investment", "New Business", etc.)
- meetingContext: One sentence summary of the meeting (50-100 characters)

INVESTMENT TOPICS TO RECOGNIZE:
- Impact investing → "Impact Investing"
- Climate tech, climatic, climate technology → "Climate Tech"
- ESG → "ESG"
- Direct deals, direct investments → "Direct Deals"
- Private equity → "Private Equity"
- Venture capital → "Venture Capital"
- Co-investment → "Co-Investment"

OUTPUT REQUIREMENTS:
1. Return ONLY the JSON object - no explanations, no markdown formatting, no code blocks
2. All string values must be in double quotes
3. Arrays must use square brackets
4. Use null (without quotes) for missing values
5. Ensure valid JSON syntax

EXAMPLE OUTPUT:
{"contactName":"Sachin Patel","eventName":"Family Office Meeting","interests":["Impact Investing","Climate Tech"],"timeline":"Q2 2026","referralSource":"Paul Shu","opportunityType":"Direct deal exploration","meetingContext":"Discussion about impact investing and climate tech opportunities"}
```

---

## 🎯 Example with Your Data

### Input Transcript:
```
Met with Sachin at the family office. Interested in Impact investing particularly in climatic. Potential liquidity, even in due to 2026, wants to explore directories, referred by Paul shu.
```

### Expected LLM Output (JSON):
```json
{
  "contactName": "Sachin",
  "eventName": "Family Office Meeting",
  "interests": ["Impact Investing", "Climate Tech"],
  "timeline": "Q2 2026",
  "referralSource": "Paul Shu",
  "opportunityType": "Direct deal exploration",
  "meetingContext": "Discussion about impact investing and liquidity opportunities"
}
```

---

## 🔧 How to Use in Your Salesforce Flow

### Step 1: Get Transcript
```
ContentVersion Record:
  ccai_Transcript__c: "Met with Sachin at the family office..."
```

### Step 2: Call LLM with Updated Prompt
```
Send to LLM:
  - Transcript: {ccai_Transcript__c}
  - Prompt: [Use the optimized prompt above]
```

### Step 3: Create Event
```
Create Event:
  - Subject: "Meeting with Contact"
  - Description: {ccai_Transcript__c}  ← Original transcript
  - StartDateTime: Now
  - EndDateTime: Now + 1 hour
```

### Step 4: Call Apex Action
```
Action: "Process Meeting Transcript"
Inputs:
  - Event Id: {Event.Id from Step 3}
  - LLM Parsed Data: {JSON response from LLM in Step 2}
```

---

## 📊 Flow Structure

```
┌─────────────────────────┐
│ Get ContentVersion      │
│ (with transcript)       │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ Call LLM                │
│ - Input: Transcript     │
│ - Output: JSON          │
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ Create Event            │
│ Description = Transcript│
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ Apex: Process Meeting   │
│ - Event Id              │
│ - LLM Parsed Data (JSON)│
└───────────┬─────────────┘
            │
            ▼
┌─────────────────────────┐
│ Results:                │
│ ✅ Contact created      │
│ ✅ Task created         │
│ ✅ Opportunity created  │
└─────────────────────────┘
```

---

## 🎨 Alternative: Simple Text Format

If your LLM has trouble with JSON, use this simpler format:

### Prompt (Text Version):
```
Extract the following from the transcript and format EXACTLY as shown:

CONTACT: [Full Name]
EVENT: [Event Name]
INTERESTS: [Interest 1], [Interest 2], [Interest 3]
TIMELINE: [Q2 2026 or similar]
REFERRAL: [Referrer Name]
OPPORTUNITY: [Type]
CONTEXT: [One sentence summary]

Use "null" if information is not found.
```

### Example Output:
```
CONTACT: Sachin
EVENT: Family Office Meeting
INTERESTS: Impact Investing, Climate Tech
TIMELINE: Q2 2026
REFERRAL: Paul Shu
OPPORTUNITY: Direct deal exploration
CONTEXT: Discussion about impact investing and liquidity opportunities
```

---

## ✅ **Recommendation: Use JSON Format**

The JSON format is best because:
1. ✅ My Apex code already supports it
2. ✅ More reliable parsing
3. ✅ Handles special characters better
4. ✅ No ambiguity in data structure
5. ✅ Industry standard

Just pass the LLM's JSON response to the `LLM Parsed Data` input parameter in the Apex action!

---

## 🚀 Benefits

1. **Faster Processing**: LLM extracts data, Apex doesn't need to parse transcript
2. **More Accurate**: LLM understands context better than regex
3. **Handles Edge Cases**: Works even if transcript format varies
4. **Flexible**: Easy to add new fields in the future

Let me know if you need help setting up the LLM integration! 🎉

