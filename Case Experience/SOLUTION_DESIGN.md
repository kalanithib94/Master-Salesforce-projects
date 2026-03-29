# Case Resolution Assistant — Solution Design

## Overview

The **Case Resolution Assistant** is an AI-powered self-service support tool built on Salesforce Experience Cloud. When a user submits a question, the system creates a Salesforce Case and immediately triggers a background AI search using GPTfy's RAG (Retrieval-Augmented Generation) engine. The AI response is surfaced back to the user in real time. The user can then confirm whether the answer resolved their issue, which determines the final state of the case.

This solution is designed for a **public-facing Experience Cloud site** (no login required) and is suitable for demo and production use.

**Live Site URL:** https://sgpt-demo-dev-ed.develop.my.site.com/gptfysupport/s/

---

## User Journey

```
┌─────────────────────────────────────────────────────────────┐
│  SCREEN 1 — Submit Form                                     │
│  User fills in: First Name, Last Name, Email, Question      │
│  Clicks: "Find a Solution"                                  │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  SCREEN 2 — Loading / Searching                             │
│  "Searching our knowledge base..."                          │
│  Spinner shown while AI processes the question              │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  SCREEN 3 — AI Recommendation                               │
│  "KNOWLEDGE ARTICLE FOUND" badge                            │
│  Question shown as article title                            │
│  GPTfy RAG response shown as article body                   │
│  "Did this article resolve your issue?"                     │
│  [ Yes, resolved ]  [ No, still need help ]                 │
└──────────┬──────────────────────────────┬───────────────────┘
           │                              │
           ▼                              ▼
┌──────────────────────┐    ┌─────────────────────────────────┐
│  SCREEN 4a — Resolved│    │  SCREEN 4b — Case Logged        │
│  Case closed         │    │  Case stays open (Status: New)  │
│  "Issue Resolved"    │    │  Case number shown              │
│  [ Submit Another ]  │    │  Email confirmed                │
│                      │    │  [ Done ] → resets to Screen 1  │
└──────────────────────┘    └─────────────────────────────────┘
```

---

## Architecture

### Component Map

```
Experience Cloud Site (public, guest user)
https://sgpt-demo-dev-ed.develop.my.site.com/gptfysupport/s/
│
└── caseResolutionAssistant  (LWC)
        │
        ├── createSupportCase()    ──► CaseResolutionController.cls
        ├── getRecommendation()    ──► CaseResolutionController.cls
        └── resolveCase()         ──► CaseResolutionController.cls
                                              │
                              ┌───────────────┴───────────────┐
                              │ Case Insert (Origin = Web)    │
                              │ triggers                      │
                              ▼                               │
                    Case_Resolution_RTF  (V2)                 │
                    (Record-Triggered Flow)                   │
                              │                               │
                    ┌─────────┴─────────┐                     │
               Run             Run                            │
            Immediately    Asynchronously                     │
               (End)             │                            │
                                 ▼                            │
                       ExecutePrompt action                   │
                       (ccai__AIPromptProcessingInvokable)    │
                                 │                            │
                                 ▼                            │
                       Update Case.Description ◄──────────────┘
                                 │
                                 ▼
                       LWC polling detects populated field
                       → shows recommendation to user
```

### Why Async?

Salesforce does not allow API callouts (HTTP requests to external systems) on a synchronous record-save transaction. The flow has two paths at the start:

- **Run Immediately** — exits immediately (no action needed in the sync transaction)
- **Run Asynchronously** — executes after the transaction commits, allowing the GPTfy external callout to proceed without restrictions

This keeps the Apex controller clean and avoids callout-in-transaction errors.

---

## Components

### 1. LWC — `caseResolutionAssistant`

| File | Purpose |
|---|---|
| `caseResolutionAssistant.html` | Template with 6 UI states, CSS-class-based visibility |
| `caseResolutionAssistant.js` | State machine, form handling, polling loop |
| `caseResolutionAssistant.css` | Full custom design matching GPTfy Support Community style |
| `caseResolutionAssistant.js-meta.xml` | Exposed to all Lightning targets including Experience Cloud |

**UI States**

| State constant | Visible when |
|---|---|
| `INPUT` | Page loads; after reset / Done |
| `LOADING` | Case creation complete, polling in progress |
| `RECOMMENDATION` | AI response received |
| `RESOLVING` | "Yes" clicked, closing case |
| `RESOLVED` | Case successfully closed |
| `CASE_CREATED` | "No" clicked, case stays open |

**Polling Logic**

After case creation, the LWC calls `getRecommendation()` every **2.5 seconds** for up to **12 attempts (30 seconds total)**. Once `Case.Description` is non-blank, polling stops and the recommendation is displayed. If the timeout is reached with no response, a graceful fallback message is shown and the user is still presented with the Yes/No choice.

```
createSupportCase() → caseId
    └─► poll every 2.5s:
            getRecommendation(caseId)
                → null?  → keep polling
                → text?  → show recommendation
                → 30s?   → show fallback message
```

**Visibility approach**

All six state containers are always present in the DOM. Visibility is controlled by toggling `cra-state` vs `cra-state--hidden` CSS classes via computed getters. This ensures reliable rendering inside both the Experience Builder canvas and the published site.

---

### 2. Apex Controller — `CaseResolutionController`

`without sharing` — required to allow Experience Cloud guest users to perform DML on Case.

| Method | Called by | Description |
|---|---|---|
| `createSupportCase()` | LWC on form submit | Inserts Case with `Origin='Web'`, `Status='New'`. Returns `caseId` and `caseNumber`. |
| `getRecommendation()` | LWC polling loop | Reads `Case.Description`. Returns `null` if blank (still processing), returns text when ready. |
| `resolveCase()` | LWC on "Yes" click | Updates `Case.Status = 'Closed'`. |

**Case fields set on creation**

| Field | Value |
|---|---|
| `Subject` | User's question (max 255 chars) |
| `SuppliedName` | First Name + Last Name |
| `SuppliedEmail` | Email from form |
| `Status` | New |
| `Origin` | Web |
| `Priority` | Medium |

---

### 3. Flow — `Case_Resolution_RTF` (V2)

**Type:** Record-Triggered Flow (After Save, Create only)  
**Trigger filter:** `Origin = Web`  
**Active version:** V2 (configured and debug-verified in Flow Builder)

#### Flow Structure

```
Start (Record-Triggered)
    │
    ├── Run Immediately ──► End
    │
    └── Run Asynchronously (AsyncAfterCommit)
              │
              ▼
        Call GPTfy RAG Action
        (ExecutePrompt — ccai__AIPromptProcessingInvokable)
              │
              ▼
        Update Case Description
              │
              ▼
             End
```

#### GPTfy Action Inputs (as configured in Flow Builder)

| Input | Value | Source |
|---|---|---|
| `EventUUID` | Running Flow Interview → InterviewGuid | Flow system variable |
| `promptRequestId` | `9cf7e95aacf31f5730a118c90c6fda4676843` | Hardcoded in flow assignment |
| `recordId` | Triggering Case → Case ID | Record trigger context |
| `customPromptCommand` | Case Subject | Triggering Case → Subject |

> **Note:** `EventUUID` uses the Flow's built-in `InterviewGuid` (unique per flow execution) rather than the Case ID, which is the recommended approach for GPTfy event tracking.

#### Flow Output

The `responseBody` returned by GPTfy is written to `Case.Description`. This is the field the LWC polls to detect when the AI response is ready.

**Prompt configuration:** The `promptRequestId` (`9cf7e95aacf31f5730a118c90c6fda4676843`) references the GPTfy Prompt record in this org. To change the prompt behaviour in future, update this value in the flow's assignment element — no code changes required.

---

## Data Flow Diagram

```
User (browser)
https://sgpt-demo-dev-ed.develop.my.site.com/gptfysupport/s/
    │
    │  1. Fill form → click "Find a Solution"
    ▼
LWC → Apex: createSupportCase(firstName, lastName, email, subject)
    │
    │  2. Case inserted in Salesforce (Status: New, Origin: Web)
    │     LWC receives caseId + caseNumber → starts polling
    ▼
Salesforce Platform
    │
    │  3. Case insert fires Case_Resolution_RTF V2
    │     → Run Immediately path exits (no sync action)
    │     → Run Asynchronously path queued
    ▼
Flow (AsyncAfterCommit path)
    │
    │  4. Calls ccai__AIPromptProcessingInvokable (ExecutePrompt)
    │       EventUUID       = InterviewGuid (unique per execution)
    │       promptRequestId = 9cf7e95aacf31f5730a118c90c6fda4676843
    │       recordId        = Case ID
    │       customPromptCommand = Case Subject (user's question)
    │
    │  5. GPTfy sends question to GCP RAG
    │     GCP RAG returns recommendation text
    │
    │  6. Flow writes responseBody → Case.Description
    ▼
Salesforce Case object (Description now populated)
    │
    │  (LWC polling every 2.5s via getRecommendation())
    ▼
Case.Description is non-blank → LWC stops polling
    │
    ▼
User sees AI recommendation (Screen 3)

    │  "Yes, resolved"                    │  "No, still need help"
    ▼                                      ▼
Apex: resolveCase(caseId)            LWC → CASE_CREATED state
Case.Status = 'Closed'               Case stays open (Status: New)
User sees "Issue Resolved"           User sees case number + Done button
Done → resets to Screen 1           Done → resets to Screen 1
```

---

## Security Model

| Layer | Configuration |
|---|---|
| Apex | `without sharing` — bypasses record-level sharing for guest users |
| Guest User Profile | Apex Class Access on `CaseResolutionController` |
| Guest User Profile | Create, Read, Edit on `Case` object |
| Case field access | `Description` field readable by guest profile (required for polling) |
| Site access | Experience Cloud site set to Public (no login required) |

---

## File Structure

```
force-app/main/default/
├── classes/
│   ├── CaseResolutionController.cls
│   └── CaseResolutionController.cls-meta.xml
├── flows/
│   └── Case_Resolution_RTF.flow-meta.xml
└── lwc/
    └── caseResolutionAssistant/
        ├── caseResolutionAssistant.html
        ├── caseResolutionAssistant.js
        ├── caseResolutionAssistant.css
        └── caseResolutionAssistant.js-meta.xml
```

---

## Polling Timeout Behaviour

If GPTfy does not respond within 30 seconds (12 polls × 2.5s), the LWC stops polling and displays:

> *"Our AI is still processing your request. A support agent will review your case and reach out to you shortly."*

The Case is already created at this point. The user sees the Yes/No choice with the fallback text. If they click "No", the case number is shown with the Done button.

---

## Design Decisions

| Decision | Rationale |
|---|---|
| Case created before AI call | GPTfy's `ccai__AIPromptProcessingInvokable` requires a `recordId`. Creating the case first provides this and ensures a case always exists regardless of AI outcome. |
| Async Flow path (Run Asynchronously) | Salesforce prohibits HTTP callouts in synchronous DML transactions. The async path avoids this constraint. The "Run Immediately" path exits with no action. |
| InterviewGuid for EventUUID | The Flow's built-in `InterviewGuid` is unique per execution and is the recommended identifier for GPTfy event tracking, replacing the earlier Case ID approach. |
| Polling over Platform Events | Simpler to implement for guest users on Experience Cloud. Platform Events require CometD subscriptions which are complex for unauthenticated users. |
| Case.Description for AI response | Avoids creating a custom field. Description is a standard long-text field suitable for storing the AI recommendation and readable in the polling query. |
| CSS-class visibility over `lwc:if` | Experience Builder canvas renders all `lwc:if` content simultaneously. CSS `display:none !important` ensures only the active state is visible in both canvas and published modes. |
| Prompt ID hardcoded in Flow assignment | Keeps prompt configuration change in Flow Builder only — no code deployment needed to update the GPTfy prompt in future. |
