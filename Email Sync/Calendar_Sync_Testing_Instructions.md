# Calendar Sync – Testing Instructions by Category

Instructions are grouped by Profile | Service provider | Sync type so you can paste the relevant block into your Calendar Sync table.

How to use: For each row (Profile × Service provider × Sync type), copy the numbered list into the Testing instructions column. The scenarios below are the approved calendar sync scenarios.

---

## Approved scenarios (Quick Match – base list)

1. Single event – One calendar meeting. After you match it, the event is created in Salesforce and linked to the correct Contact, Account, or Opportunity.
2. Multiple events (up to 20) – Select several events and match them. All selected events are created and linked; counts are correct.
3. More than 20 events for manual match – If you try to match more than 20 events at once, the system shows an error. Only up to 20 events can be matched in one go.
4. Already synced event – An event that was synced before cannot be selected for manual match again. It is either hidden or disabled in the list.
5. Event with no matching Contact or Lead – The meeting attendee email does not match any Contact or Lead. The event stays unmatched; no record is created in Salesforce.
6. Event with one attendee who is a Contact – The attendee’s email matches a Contact. After match, the event is linked to that Contact (and Account if applicable).
7. Event with multiple attendees (all Contacts) – Several attendees; each email matches a Contact. After match, the event is linked to all those Contacts (or only the ones you select, per design).
8. Event with attendee who is a Lead – Attendee email matches a Lead. Event links to the Lead record after match.
9. Manual selection: Contact only – When you choose only a Contact in the match popup, the event is created and linked only to that Contact. No link to Account or Opportunity unless you select them.
10. Manual selection: Account only – When you choose only an Account, the event is linked only to that Account (if your product supports this).
11. Manual selection: Opportunity only – When you choose an Opportunity, the event is linked to that Opportunity and rolls up to the Account correctly. No duplicate link on the Account.
12. Same Contact in multiple Accounts – The attendee is a Contact linked to more than one Account. Only the Account (and Contact) you select get the event. No link to the other Accounts.
13. Same Contact, one Account, multiple Opportunities – You select one Opportunity. The event links only to that Opportunity and rolls up to that Account. No link to other Opportunities.
14. Events that have been synced show the correct pill in the UI. On clicking the matched pill, the corresponding record will open in new tab. Different object record’s specific pills will be in specific colours to differentiate.
15. After sync, events are shown with the most recent first.

---

## System admin | Outlook | Quick Match

Use the approved scenarios 1–15 above.

---

## System admin | Outlook | Run now

1. Single event – Run now fetches and matches one calendar event. The event is created in Salesforce and linked to the correct Contact, Account, or Opportunity.
2. Multiple events (up to 20) – Run now processes several events. All that have matching Contacts or Leads are created and linked; counts are correct.
3. More than 20 events – Run now processes events in batches. Sync completes without timeout; counts are correct.
4. Already synced event – Running sync again does not create a second copy of the same event. No duplicates.
5. Event with no matching Contact or Lead – The event stays unmatched; no record is created in Salesforce. Unmatched count updated.
6. Event with one attendee who is a Contact – The event is linked to that Contact (and Account if applicable).
7. Event with multiple attendees (all Contacts) – The event is linked to those Contacts (or only the ones per rule/design). Counts correct.
8. Event with attendee who is a Lead – Event links to the Lead record.
9. Manual selection / deterministic: Contact only – Event is linked only to the Contact. No link to Account or Opportunity unless selected by rule.
10. Manual selection / deterministic: Account only – Event is linked only to that Account (if supported).
11. Manual selection / deterministic: Opportunity only – Event is linked to that Opportunity and rolls up to the Account correctly. No duplicate link on the Account.
12. Same Contact in multiple Accounts – Only the Account (and Contact) selected by rule get the event. No link to the other Accounts.
13. Same Contact, one Account, multiple Opportunities – Event links only to that Opportunity and the Account. No link to other Opportunities.
14. Events that have been synced show the correct pill in the UI. On clicking the matched pill, the corresponding record will open in new tab. Different object record’s specific pills will be in specific colours to differentiate.
15. After sync, events are shown with the most recent first.

---

## System admin | Outlook | Scheduler

1. Scheduler runs for the signed-in user – When the scheduled job runs, a workspace log is created for that user’s calendar sync.
2. Scheduler runs for all authorized users – Every user who has calendar connected and is authorized gets their calendar synced. Logs are separate per user; no mixing of data between users.
3. Auto sync turned off for a user – That user is skipped by the scheduler. No calendar sync runs for them.
4. Single event – When scheduler runs, one calendar event is matched. The event is created in Salesforce and linked to the correct Contact, Account, or Opportunity.
5. Multiple events (up to 20) – Scheduler processes several events. All that have matching Contacts or Leads are created and linked; counts are correct.
6. More than 20 events – Scheduler processes events in batches. Run completes; counts are correct.
7. Already synced event – Running the scheduler again does not create duplicate events for the same meeting.
8. Event with no matching Contact or Lead – Event stays unmatched; no record created in Salesforce. Unmatched count updated.
9. Event with one attendee who is a Contact – Event is linked to that Contact (and Account if applicable).
10. Event with multiple attendees (all Contacts) – Event is linked to those Contacts (or per design). Counts correct.
11. Event with attendee who is a Lead – Event links to the Lead record.
12. Same Contact in multiple Accounts – Only the Account (and Contact) selected by rule get the event. No link to the other Accounts.
13. Same Contact, one Account, multiple Opportunities – Event links only to that Opportunity and the Account. No link to other Opportunities.
14. Events that have been synced show the correct pill in the UI. On clicking the matched pill, the corresponding record will open in new tab. Different object record’s specific pills will be in specific colours to differentiate.
15. After sync, events are shown with the most recent first.
16. Provider inactive – If Outlook is deactivated for the org or user, the Outlook calendar option is not visible in the UI and the scheduler does not run for that provider.

---

## System admin | Outlook | Sent items (if Calendar has “sent” or outbound invites)
If your product treats “sent” calendar invites separately, use the same scenarios as above but for events created or sent by the user (outbound invites). Otherwise, ignore this section.
---

## System admin | Gmail | Quick Match

Use the approved scenarios 1–15 above.

---

## System admin | Gmail | Run now

1. Single event – Run now fetches and matches one calendar event. The event is created in Salesforce and linked to the correct Contact, Account, or Opportunity.
2. Multiple events (up to 20) – Run now processes several events. All that have matching Contacts or Leads are created and linked; counts are correct.
3. More than 20 events – Run now processes events in batches. Sync completes without timeout; counts are correct.
4. Already synced event – Running sync again does not create a second copy of the same event. No duplicates.
5. Event with no matching Contact or Lead – The event stays unmatched; no record is created in Salesforce. Unmatched count updated.
6. Event with one attendee who is a Contact – The event is linked to that Contact (and Account if applicable).
7. Event with multiple attendees (all Contacts) – The event is linked to those Contacts (or only the ones per rule/design). Counts correct.
8. Event with attendee who is a Lead – Event links to the Lead record.
9. Deterministic: Contact only – Event is linked only to the Contact. No link to Account or Opportunity unless selected by rule.
10. Deterministic: Account only – Event is linked only to that Account (if supported).
11. Deterministic: Opportunity only – Event is linked to that Opportunity and rolls up to the Account correctly. No duplicate link on the Account.
12. Same Contact in multiple Accounts – Only the Account (and Contact) selected by rule get the event. No link to the other Accounts.
13. Same Contact, one Account, multiple Opportunities – Event links only to that Opportunity and the Account. No link to other Opportunities.
14. Events that have been synced show the correct pill in the UI. On clicking the matched pill, the corresponding record will open in new tab. Different object record's specific pills will be in specific colours to differentiate.
15. After sync, events are shown with the most recent first.

---

## System admin | Gmail | Scheduler

1. Scheduler runs for all authorized users – Each user with Gmail calendar connected gets a separate sync; logs are per user.
2. Auto sync turned off for a user – That user is excluded from the scheduler run.
3. Single event – When scheduler runs, one calendar event is matched. The event is created in Salesforce and linked to the correct Contact, Account, or Opportunity.
4. Multiple events (up to 20) – Scheduler processes several events. All that have matching Contacts or Leads are created and linked; counts are correct.
5. More than 20 events – Scheduler processes events in batches. Run completes; counts are correct.
6. Already synced event – Running the scheduler again does not create duplicate events for the same meeting.
7. Event with no matching Contact or Lead – Event stays unmatched; no record created in Salesforce. Unmatched count updated.
8. Event with one attendee who is a Contact – Event is linked to that Contact (and Account if applicable).
9. Event with multiple attendees (all Contacts) – Event is linked to those Contacts (or per design). Counts correct.
10. Event with attendee who is a Lead – Event links to the Lead record.
11. Same Contact in multiple Accounts – Only the Account (and Contact) selected by rule get the event. No link to the other Accounts.
12. Same Contact, one Account, multiple Opportunities – Event links only to that Opportunity and the Account. No link to other Opportunities.
13. Events that have been synced show the correct pill in the UI. On clicking the matched pill, the corresponding record will open in new tab. Different object record's specific pills will be in specific colours to differentiate.
14. After sync, events are shown with the most recent first.
15. Provider inactive – If Gmail is deactivated, it is not visible and scheduler does not run for Gmail.

---

## Standard User | Outlook | Quick Match

1. Permissions – The Standard User can run calendar sync and can see only the events and records they are allowed to see. Created events are linked to Contacts, Accounts, or Opportunities they have access to. Visibility follows sharing rules.

---

## Standard User | Outlook | Run now

1. Permissions – The Standard User can run calendar sync. Events are created and linked only to Contacts, Accounts, or Opportunities they can access. Visibility follows sharing rules.

---

## Standard User | Outlook | Scheduler

1. Permissions – When the scheduler runs for this Standard User, only their calendar is synced and events are linked only to records they can access. Visibility follows sharing rules.

---

## Standard User | Gmail | Quick Match

1. Permissions – The Standard User can run calendar sync and can see only the events and records they are allowed to see. Created events are linked only to records they have access to. Visibility follows sharing rules.

---

## Standard User | Gmail | Run now

1. Permissions – The Standard User can run calendar sync. Events are created and linked only to records they can access. Visibility follows sharing rules.

---

## Standard User | Gmail | Scheduler

1. Permissions – When the scheduler runs for this Standard User, only their calendar is synced and events are linked only to records they can access. Visibility follows sharing rules.

---

## Calendar Sync Settings – behavior to verify

1. Calendar sync enabled – When the global calendar sync toggle is off, no calendar sync (Quick Match, Run now, Scheduler) runs. When on, sync runs per user and schedule.
2. Sync frequency – Scheduler runs at the interval set (e.g. every 60 minutes). Verify runs occur at that interval.
3. Max events per user / batching – Scheduler respects limits on how many events are processed per user and per batch. Verify no timeout and correct counts.
4. Lookback (first-time sync) – For a user who has never had calendar sync, the first run uses the lookback period (e.g. hours) to fetch past events. Later runs use the normal sync window. Verify first-time vs later behavior.
5. Auto sync per user – When a user turns off auto sync, the scheduler does not run for them. Verify that user is excluded.

---

## Quick reference – Calendar Sync table

| Profile       | Service provider | Sync type   |
|---------------|------------------|-------------|
| System admin  | Outlook          | Quick Match |
| System admin  | Outlook          | Run now     |
| System admin  | Outlook          | Scheduler   |
| System admin  | Gmail            | Quick Match |
| System admin  | Gmail            | Run now     |
| System admin  | Gmail            | Scheduler   |
| Standard User | Outlook          | Quick Match |
| Standard User | Outlook          | Run now     |
| Standard User | Outlook          | Scheduler   |
| Standard User | Gmail            | Quick Match |
| Standard User | Gmail            | Run now     |
| Standard User | Gmail            | Scheduler   |

---

Copy the numbered list for the matching row into your Calendar Sync table. Use the Calendar Sync Settings section when testing scheduler and first-time sync.