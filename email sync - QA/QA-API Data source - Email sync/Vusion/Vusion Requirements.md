# Vusion Project - Requirements Specification

This is the source-of-truth requirements document for the **Vusion project**.  
Treat Vusion as a separate project with its own rules, prompt contract, and Apex enrichment behavior.

  ## Requirements (quick list)

  - One Contact can be linked to multiple Accounts (primary + related accounts) and all must be considered for matching.
  - Domain-based Account confidence must be applied only when WhoId is a Contact, using Contact email domain and staging address domains against Account website host.
  - Only OPEN Opportunities are eligible for selection; closed opportunities must be excluded.
  - Opportunity match has priority over Account match when content indicates an opportunity.
  - If no clear opportunity match, perform Account fallback using content + domain signals.
  - If the email is clearly actionable but `RelatedToId` is ambiguous/unavailable, keep `IsRelevant=true` and leave `RelatedToId=""` (do not reject just due to linking).
  - `RelatedToId` can only be selected from: `opportunities[].id`, `contacts[].account.id`, `contacts[].relatedAccounts[].account.id`.
  - When `vusionStructuredContext` is present, AI should prefer `candidateIndexes.allowedRelatedToIds` and account-opportunity nesting under `accountCandidates[]` for deterministic mapping.
  - `RelatedToId` must never use Contact/Lead IDs and must never be invented.
  - `EmailSummary` must include only relevant actionable excerpts from original email text; no paraphrasing/rewording.
  - Irrelevant details must be excluded from `EmailSummary` (greetings, signatures, personal chatter, footer noise).
  - Output must strictly follow schema keys: `IsRelevant`, `RelatedToId`, `EmailSummary`, `RejectionReason`.
  - Rejection reasons are restricted to: `Unable to determine RelatedToId`, `No actionable business intent`, `Closure or acknowledgement only`, `Automated or informational noise`, `Ambiguous relevance`, `Formatting constraints could not be satisfied`.
  - Provider rules:
    - Tasks (`MICROSOFT_TASKS`, `GOOGLE_TASKS`) -> relevance based on provider rule.
    - Calendar (`MICROSOFT_CALENDAR`, `GOOGLE_CALENDAR`) -> opportunity first, then account, else reject.
  - Differentiate normal email vs calendar-invite generated email; invite emails must not be auto-marked `Not relevant` only due to short/system template content.
  - If WhoId-contact has no account and no open opportunity candidates, keep `IsRelevant=true` (when content is relevant) with empty `RelatedToId`.
  - If WhoId is Lead and email intent is relevant, keep `IsRelevant=true` with empty `RelatedToId`.
  - If WhoId is Lead but content is not relevant, keep `IsRelevant=false` (Lead context must not auto-mark relevance).
  - If account/opportunity candidates exist but content is not relevant, `IsRelevant` must be `false`.
  - Thread handling: treat each email in a thread as an independent record; closure/thank-you/ack-only emails are `Not relevant` unless the new message includes clear business action.

## At-a-glance rule checklist

- Relevancy is based on actionable business intent (request, follow-up, status, commitment/ETA, scheduling, decision).
- Closure/ack-only emails are not relevant unless new actionable intent exists.
- Thread emails are evaluated independently; prioritize newly added content over quoted history.
- Invite-generated calendar emails must be distinguished from normal emails and not auto-rejected for system-like format.
- Lead/Contact context does not auto-mark relevance; content intent is still required.
- If email is actionable but linking is ambiguous/unavailable, keep `IsRelevant=true` and allow `RelatedToId=""`.
- `RelatedToId` can only come from allowed IDs in payload (or `vusionStructuredContext.candidateIndexes.allowedRelatedToIds`).
- Opportunity match is preferred over account match when clearly indicated.
- Only OPEN opportunities are eligible for selection.
- Use detailed rejection reasons (not just generic not relevant).
- Preserve strict output contract: keys, JSON format, summary limits, and fail-safe behavior.
- Prefer `vusionStructuredContext` (relationship-first) for deterministic account-opportunity linkage; keep flat fields as fallback.
- Use a clean AI-first payload shape (staging, email, whoContext, accountCandidates, candidateIndexes, signals, policyHints) to avoid duplicate/noisy fields.

When this file changes, update both:
- `Vusion/Vusion Prompt Command.md`
- `Vusion/VusionStagingProcessingPolicyCheck.cls` (and any deployed copy used by the org)

---

## 1) Project objective

Build an AI policy-check flow for staging records that decides:
- whether the record is relevant for activity creation
- which `RelatedToId` should be used (WhatId context)

The output must be deterministic, schema-safe, and aligned with Vusion business logic.

---

## 2) Response contract (AI output schema)

AI response must be a **single JSON object** with exactly:

```json
{
  "IsRelevant": true,
  "RelatedToId": "Salesforce Id or empty string",
  "EmailSummary": "string <= 400 chars",
  "RejectionReason": "string"
}
```

Rules:
- `IsRelevant` is boolean (`true`/`false`)
- `RelatedToId` is a Salesforce Id or `""`
- `EmailSummary` must be empty when `IsRelevant=false`
- `RejectionReason` must be empty when `IsRelevant=true`
- no extra keys allowed

Allowed rejection reasons:
- `Unable to determine RelatedToId`
- `No actionable business intent`
- `Closure or acknowledgement only`
- `Automated or informational noise`
- `Ambiguous relevance`
- `Formatting constraints could not be satisfied`

---

## 3) Core data model assumptions

Input payload should be a clean structured model:
- `staging`
- `email`
- `whoContext`
- `accountCandidates[]` (each with nested `opportunities[]`)
- `candidateIndexes` (`allowedRelatedToIds`, `whoScopedAccountIds`, `whoScopedOpportunityIds`)
- `signals`
- `policyHints`

---

## 4) Functional requirements

### FR-1: Multi-account support for Contact

A Contact can map to many accounts (primary + related).  
Selection logic must consider:
- `contacts[].account.id`
- `contacts[].relatedAccounts[].account.id`

### FR-2: Domain matching (Contact WhoId only)

Apply domain logic only when WhoId corresponds to **Contact**.

Domain sources:
- Contact email domain (`contacts[].email`)
- staging recipient domain(s) from `toAddresses` (and optional sender domain context)

Domain target:
- compare domain against Account website host (`account.website`) across primary and related accounts.

Expected behavior:
- if domain confidently matches one account, increase confidence for that account.
- if multiple domain matches are equivalent, keep ambiguous unless other signals break tie.

### FR-3: Opportunity precedence on related account

If email content indicates an opportunity and a matching opportunity exists in `opportunities[]`,
set `RelatedToId` to that opportunity Id.

Opportunity list is expected to be scoped from accounts related to contact context.
Only open opportunities are eligible for selection.
Closed opportunities must be ignored during matching and ranking.

### FR-4: Required processing behavior

The Vusion implementation must always do all of the following:
- include entity context for contacts, leads, accounts, and opportunities from input payload
- enforce safety by selecting `RelatedToId` only from allowed IDs present in payload
- apply strict output formatting and schema constraints for deterministic responses
- preserve security-safe data sourcing and avoid inventing any entity/identifier

---

## 5) Matching and ranking rules

### 5.1 Candidate pool for `RelatedToId`

Allowed candidates only:
- `opportunities[].id`
- `contacts[].account.id`
- `contacts[].relatedAccounts[].account.id`

Never use:
- `contacts[].id`
- `leads[].id`

### 5.2 Opportunity matching

Use subject/body text and compare with opportunity names:
- exact match first
- fuzzy match second (threshold >= 80%)
- case-insensitive and spacing/typo tolerant

If one clear winner exists: choose it.  
If ambiguous: leave `RelatedToId=""` (do not reject relevancy for actionable business intent).

### 5.3 Account matching fallback

If no opportunity winner:
- evaluate account matches using:
  - content similarity (subject/body)
  - domain match signals (when applicable)
  - relationship relevance from contact context

Pick only when one account is clearly strongest.
If tie/unclear/conflicting signals: leave `RelatedToId=""` (do not reject relevancy for actionable business intent).

---

## 6) Relevancy rules

Set `IsRelevant=true` when there is clear business actionability, such as:
- request for follow-up/action
- product/service inquiry
- meeting/demo scheduling
- deal/process continuation
- approval/decision request
- commitment / ETA / promise of follow-up (e.g., "I will get back to you in 4 days", "we will share an update by Friday")
- status update on an ongoing business item (e.g., "case status", "ticket update", "next steps")

Set `IsRelevant=false` when:
- no actionable business intent
- spam / irrelevant / personal-only
- automated noise without action needed

Thread handling rules:
- evaluate each imported email independently, even when from the same conversation thread
- use current-message intent as primary signal
- when trailing/quoted previous-thread text exists, prioritize newly added text
- closure/thanks/acknowledgement-only emails should be marked not relevant unless they include new actionable business intent

Special note (WhoId-contact no-candidate case):
- If `vusionWhoIdIsContact=true` and there is no account and no open opportunity candidate for that contact, then:
  - keep `IsRelevant=true` when message intent is relevant
  - set `RelatedToId=""`
  - keep `RejectionReason=""`
  - keep actionable `EmailSummary`

Special note (WhoId-lead case):
- If WhoId points to Lead and message intent is relevant:
  - keep `IsRelevant=true`
  - set `RelatedToId=""`
  - keep `RejectionReason=""`
  - keep actionable `EmailSummary`
- If WhoId points to Lead but message intent is not relevant:
  - set `IsRelevant=false`
  - set `RelatedToId=""`
  - set `EmailSummary=""`
  - set `RejectionReason` to the most specific allowed reason

Special note (candidates exist but message not relevant):
- If account/opportunity candidates exist but message intent is not relevant:
  - set `IsRelevant=false`
  - set `RelatedToId=""`
  - set `EmailSummary=""`
  - set `RejectionReason` to the most specific allowed reason

---

## 7) Provider-specific rules

### Task providers
- If provider is `MICROSOFT_TASKS` or `GOOGLE_TASKS`, mark `IsRelevant=true` based on provider rule.
- For task context, do not override with unrelated email heuristics.

### Calendar/Event providers
- If provider is `MICROSOFT_CALENDAR` or `GOOGLE_CALENDAR`:
  - prefer opportunity match from subject/body
  - fallback to account match
  - if no clear match, keep `IsRelevant=true` for actionable meeting intent and leave `RelatedToId=""` (do not reject only due to linking)

### Invite-generated email differentiation
- AI must distinguish normal conversational email from invite-generated email.
- Invite-generated email can be identified via provider and invite signals (invite/update/reschedule/accept/decline/cancel patterns).
- Invite-generated emails should not be auto-rejected as irrelevant only because they are short/system-style.
- Mark invite-generated emails relevant when meeting intent exists and message is business-related.

---

## 8) Output formatting guardrails

Mandatory:
- JSON only, no markdown, no wrapper text
- no HTML/XML tags in values
- plain-text summary only
- no URLs/base64/long hashes in summary
- single-line summary, <= 400 chars
- summary must include only relevant actionable details from original email text
- summary must preserve source wording for included content (no AI reforming/paraphrase)
- do not include irrelevant details (greetings, pleasantries, personal chatter, footer/signature noise)

Fail-safe output:
```json
{"IsRelevant":false,"RelatedToId":"","EmailSummary":"","RejectionReason":"Formatting constraints could not be satisfied"}
```

---

## 9) Apex responsibilities (Vusion class)

`Vusion/VusionStagingProcessingPolicyCheck.cls` must:
- preserve base payload output
- add Vusion helper hints for model ranking
- compute Contact-only domain matching context
- expose matched account hints in a model-consumable structure

Current clean payload sections expected:
- `staging`
- `email`
- `whoContext`
- `accountCandidates`
- `candidateIndexes`
- `signals`
- `policyHints`

---

## 10) Change workflow

For every requirement change:
1. Update this file first.
2. Update `Vusion/Vusion Prompt Command.md`.
3. Update `Vusion/VusionStagingProcessingPolicyCheck.cls`.
4. Validate sample payloads (positive, ambiguous, negative).
5. Record change in changelog.

---

## 11) Open backlog

| ID | Item | Status | Notes |
|---|---|---|---|
| VUS-01 | Add deterministic tie-break scoring for multi-account matches | Planned | Score vector needed |
| VUS-02 | Add domain synonym mapping (brand domains/subdomains) | Planned | Optional config map |
| VUS-03 | Add regression test payload catalog | Planned | Include expected outputs |

---

## Changelog

| Date | Change |
|------|--------|
| 2026-03-21 | Rewritten as full standalone Vusion project requirements spec |
| 2026-03-24 | Added thread-level relevancy requirement: evaluate each email independently and reject closure/ack-only noise unless new business action exists |
| 2026-03-24 | Clarified Lead rule: WhoId=Lead does not auto-pass relevance; only content-relevant Lead emails should be imported |
| 2026-03-24 | Added invite-email differentiation: calendar-invite generated emails should be distinguished from normal emails and not auto-rejected due to system-like content |
| 2026-03-24 | Expanded rejection reason taxonomy so users can see why relevance is false instead of generic Not relevant |
| 2026-03-24 | Made RelatedToId optional for actionable emails: keep IsRelevant=true even when linking is ambiguous/unavailable |
| 2026-03-24 | Added backward-compatible relationship-first helper payload (`vusionStructuredContext`) for deterministic account-opportunity linkage |
| 2026-03-24 | Switched to clean AI-first structured payload output to reduce noise and ambiguity |
