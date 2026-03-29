# Email Sync – Consolidated Testing Instructions by Category

Instructions are grouped by Profile | Service provider | Inbox/Sent items | Sync type so you can paste the relevant block into each table cell.

How to use with your table: For each row in your Email Sync table (Profile × Service provider × Inbox/Sent items × Sync type), copy the corresponding section below (the numbered list only) into the Testing instructions column. Large emails, HTML emails, thread emails, and forwarded emails are covered in the scenarios below.

---

## System admin | Outlook | Inbox | Quick Match

1. Single email to one Contact one Account after match EmailMessage created and linked correctly
2. More than 1 email up to 20 all matched counts match
3. More than 20 emails manual match throws error only up to 20 can be matched at once
4. Max 10 emails import works counts match
5. 50 emails import works counts match
6. Duplicate 50 emails no duplicate EmailMessage created counts reflect unique
7. Already synced email cannot be selected for manual match verify not selectable or disabled in UI
8. Already synced email after deleting logs or staging EmailMessage stays in Salesforce rerun no duplicates
9. Email without matching Contact or Lead stays unmatched unmatched count updated no record creation
10. Contact has no direct Account stays unmatched or per rule no incorrect Account creation
11. Contact with related Accounts deterministic Account chosen stable on rerun
12. Same Contact in multiple Accounts with Opportunities single email only selected targets get EmailMessage no spillover
13. Same Contact in multiple Accounts with Opportunities forwarded thread only selected targets get EmailMessage no spillover
14. Multiple Contacts multiple Accounts with Opportunities selecting multiple Contacts only selected Contacts and intended objects updated
15. Same Contact single Account multiple Opportunities single email only selected Opportunity linked or per rule
16. Sync under Opportunity rolls up to Account no duplicate association created
17. Manual selection Contact only create only on Contact
18. Manual selection Account only create only on Account if that is the design
19. Manual selection Opportunity only create on Opportunity and roll up to Account
20. Thread more than 2 back and forth all messages imported linked consistently no split
21. Thread forward to different person then reply all messages imported correct matching
22. Contact 1 asks Contact 2 replies same Account both directions imported linked to correct Contacts
23. Email to 2 Contacts in To both Contacts matched logged under both
24. Email to 1 Contact in To and 1 Contact in CC both Contacts matched logged under both
25. To 1 User CC 1 or more Users single import only no duplicates visibility correct
26. From 1 Contact to 2 Users two different inboxes first importer imports second cannot import again no duplicates
27. Exclude Confidential enabled confidential emails skipped excluded count and summary correct
28. Exclude Marketing enabled marketing emails skipped excluded count and summary correct
29. Exclude Internal enabled internal handling correct internal not used for matching excluded count correct
30. Exclude Public domains enabled public domain emails skipped excluded count correct
31. Cross user exclude internal user 1 matches verify user 2 not pulled in unintentionally
32. Account with website no Contact email from matching domain match Account only if rule exists otherwise stays unmatched no record creation
33. Send email from another email address same domain as a Contact verify exact email matching only and stays unmatched if no exact match
34. Email with attachments import succeeds has files filter works attachments accessible
35. Large email body truncation html and text truncated per limits import succeeds
36. No subject email import succeeds subject handled as blank
37. Very long subject import succeeds subject truncated per limits
38. Special characters non latin emoji import succeeds content stored correctly
39. Email ordering latest first inbox shows newest first after import and rerun
40. Badge attached to matched emails badge correct
41. Notification received and content matches matched unmatched excluded counts
42. Failure case token expired or permission error shows error not success no partial masked

---

## System admin | Outlook | Inbox | Run now

1. Single email import and match works
2. More than 1 email up to 20 works counts match
3. More than 20 emails batching works
4. Max 10 emails works
5. 50 emails works
6. Duplicate 50 emails no duplicates
7. Already synced email rerun no duplicate
8. Email without matching Contact or Lead stays unmatched unmatched count updated no record creation
9. Contact with related Accounts deterministic Account chosen stable
10. Contact no Account unmatched or per rule
11. Same Contact multiple Accounts multiple Opportunities deterministic target only no spillover
12. Same Contact single Account multiple Opportunities Opportunity tie breaker consistent or left blank per rule
13. Thread more than 2 back and forth linked consistently
14. Thread forward then reply linked consistently
15. Contact 1 asks Contact 2 replies same Account both directions imported
16. Exclude Confidential enabled excluded count correct
17. Exclude Marketing enabled excluded count correct
18. Exclude Internal enabled excluded count correct internal not used for matching
19. Exclude Public domains enabled excluded count correct
20. Cross user first importer wins second cannot import again
21. Cross user exclude internal user 1 matches verify user 2 not pulled in
22. Sync under Opportunity rolls up to Account no duplicates
23. Boundary sync window end time email included next run counts correct
24. Boundary matched email not duplicated
25. Boundary unmatched counted in unmatched
26. Mixed matched and unmatched boundary counts both correct
27. Email with attachments has files filter works
28. Large email body truncation works
29. Partial outcome some succeed some fail status Partial counts reflect succeeded and failed
30. Provider specific status outlook partial gmail success shown correctly per provider
31. Ordering latest first works
32. Badge attached correctly
33. Notification correct

---

## System admin | Outlook | Inbox | Scheduler

1. Scheduler runs for this user workspace log created
2. Scheduler runs for all authorized users logs per user no cross user mixing
3. Auto sync disabled user excluded
4. Schedule sync with 10 emails records exist count increases matched increases
5. Schedule sync with 10 emails no records count not effected per requirement unmatched counts updated
6. More than 20 emails batching works counts match
7. More than 1000 emails batching works counts match no timeout
8. Duplicate 50 emails no duplicates
9. Already synced email in scheduler rerun no duplicate
10. Contact with related Accounts deterministic Account chosen stable across cycles
11. Contact no Account unmatched or per rule
12. Same Contact multiple Accounts multiple Opportunities deterministic target no spillover
13. Same Contact single Account multiple Opportunities Opportunity tie breaker consistent or left blank per rule
14. Thread more than 2 back and forth imported linked consistently
15. Thread forward then reply linked consistently
16. Contact 1 asks Contact 2 replies same Account both directions imported
17. Exclude Confidential excluded summary and count correct
18. Exclude Marketing excluded summary and count correct
19. Exclude Internal excluded summary and count correct internal not used for matching
20. Exclude Public domains excluded summary and count correct
21. Cross user first importer wins second cannot import again when scheduler runs per user
22. Cross user exclude internal user 1 matches verify user 2 not pulled in
23. Provider inactive UI not visible and scheduler does not run for that provider
24. Boundary sync window end time email included next run counts correct
25. Boundary matched email not duplicated
26. Boundary unmatched counted in unmatched
27. Mixed boundary counts correct
28. Email with attachments has files filter works
29. Large email body truncation works
30. Partial outcome status Partial when some fail
31. Ordering latest first works
32. Badge attached correctly
33. Notification correct

---

## System admin | Outlook | Sent items | Quick Match

1. Sent to 1 Contact 1 Account 1 Opportunity appears recent EmailMessage linked correctly
2. Sent to 2 Contacts in To both matched logged under both
3. Sent to 1 Contact in To and 1 Contact in CC both matched logged under both
4. Sent to 2 Contacts in To and internal User in CC sync by CC user both Contacts matched sender visibility correct
5. Sent to 2 Contacts one Account multiple Opportunities opportunity association per rule
6. One Contact multiple Accounts deterministic Account selection no spillover
7. One Contact multiple Accounts multiple Opportunities deterministic selection no spillover
8. Sent items manual match contacts not picked regression verify fixed
9. Sent items already synced rerun no duplicate
10. Sent items attachments import and has files filter works
11. Sent items large body truncation works
12. Sent items ordering latest first works
13. Sent items badges attached correctly
14. Notification correct

---

## System admin | Outlook | Sent items | Run now

1. Sent to 1 Contact 1 Account linked correctly
2. Sent to 2 Contacts in To both matched
3. Sent to 1 Contact in To and 1 Contact in CC both matched
4. Sent to 2 Contacts in To and internal User in CC both matched sender visibility correct
5. One Contact multiple Accounts deterministic selection
6. Sent items already synced rerun no duplicate
7. Sent items attachments has files filter works
8. Sent items large body truncation works
9. Boundary window for sent items counts correct and no duplicates
10. Partial outcome status Partial when some fail
11. Ordering latest first works
12. Badge attached correctly
13. Notification correct

---

## System admin | Outlook | Sent items | Scheduler

1. Sent items enabled imports sent items correctly per user
2. Sent to 2 Contacts in To both matched
3. Sent to 1 Contact in To and 1 Contact in CC both matched
4. Sent to 2 Contacts in To and internal User in CC both matched sender visibility correct
5. One Contact multiple Accounts deterministic selection stable across cycles
6. More than 20 sent emails batching works
7. Sent items already synced rerun no duplicate
8. Sent items attachments has files filter works
9. Sent items large body truncation works
10. Boundary window for sent items counts correct and no duplicates
11. Partial outcome status Partial when some fail
12. Ordering latest first works
13. Badge attached correctly
14. Notification correct

---

## System admin | Gmail | Inbox | Quick Match

1. Single email to one Contact one Account after match EmailMessage created and linked correctly
2. More than 1 email up to 20 all matched counts match
3. More than 20 emails manual match throws error only up to 20 can be matched at once
4. Max 10 emails import works counts match
5. 50 emails import works counts match
6. Duplicate 50 emails no duplicate EmailMessage created counts reflect unique
7. Already synced email cannot be selected for manual match verify not selectable or disabled in UI
8. Already synced email after deleting logs or staging EmailMessage stays in Salesforce rerun no duplicates
9. Email without matching Contact or Lead stays unmatched unmatched count updated no record creation
10. Contact has no direct Account stays unmatched or per rule no incorrect Account creation
11. Contact with related Accounts deterministic Account chosen stable on rerun
12. Same Contact in multiple Accounts with Opportunities single email only selected targets get EmailMessage no spillover
13. Same Contact in multiple Accounts with Opportunities forwarded thread only selected targets get EmailMessage no spillover
14. Multiple Contacts multiple Accounts with Opportunities selecting multiple Contacts only selected Contacts and intended objects updated
15. Same Contact single Account multiple Opportunities single email only selected Opportunity linked or per rule
16. Sync under Opportunity rolls up to Account no duplicate association created
17. Manual selection Contact only create only on Contact
18. Manual selection Account only create only on Account if that is the design
19. Manual selection Opportunity only create on Opportunity and roll up to Account
20. Thread more than 2 back and forth all messages imported linked consistently no split
21. Thread forward to different person then reply all messages imported correct matching
22. Contact 1 asks Contact 2 replies same Account both directions imported linked to correct Contacts
23. Email to 2 Contacts in To both Contacts matched logged under both
24. Email to 1 Contact in To and 1 Contact in CC both Contacts matched logged under both
25. To 1 User CC 1 or more Users single import only no duplicates visibility correct
26. From 1 Contact to 2 Users two different inboxes first importer imports second cannot import again no duplicates
27. Exclude Confidential enabled confidential emails skipped excluded count and summary correct
28. Exclude Marketing enabled marketing emails skipped excluded count and summary correct
29. Exclude Internal enabled internal handling correct internal not used for matching excluded count correct
30. Exclude Public domains enabled public domain emails skipped excluded count correct
31. Cross user exclude internal user 1 matches verify user 2 not pulled in unintentionally
32. Email with attachments import succeeds has files filter works attachments accessible
33. Large email body truncation html and text truncated per limits import succeeds
34. Ordering latest first inbox shows newest first after import and rerun
35. Badge attached correctly
36. Notification correct
37. Failure case token expired or permission error shows error not success

---

## System admin | Gmail | Inbox | Run now

1. Single email import and match works
2. More than 1 email up to 20 works counts match
3. More than 20 emails batching works
4. Max 10 emails works
5. 50 emails works
6. Duplicate 50 emails no duplicates
7. Already synced email rerun no duplicate
8. Email without matching Contact or Lead stays unmatched unmatched count updated no record creation
9. Contact with related Accounts deterministic Account chosen stable
10. Contact no Account unmatched or per rule
11. Same Contact multiple Accounts multiple Opportunities deterministic target only no spillover
12. Same Contact single Account multiple Opportunities Opportunity tie breaker consistent or left blank per rule
13. Thread more than 2 back and forth linked consistently
14. Thread forward then reply linked consistently
15. Exclude Confidential enabled excluded count correct
16. Exclude Marketing enabled excluded count correct
17. Exclude Internal enabled excluded count correct
18. Exclude Public domains enabled excluded count correct
19. Boundary sync window end time email included next run counts correct
20. Partial outcome status Partial when some fail
21. Email with attachments has files filter works
22. Large email body truncation works
23. Ordering latest first works
24. Badge attached correctly
25. Notification correct

---

## System admin | Gmail | Inbox | Scheduler

1. Scheduler runs for all authorized users logs per user no cross user mixing
2. Auto sync disabled user excluded
3. Schedule sync with 10 emails records exist count increases matched increases
4. Schedule sync with 10 emails no records count not effected per requirement unmatched counts updated
5. More than 20 emails batching works
6. More than 1000 emails batching works
7. Duplicate 50 emails no duplicates
8. Already synced email rerun no duplicate
9. Contact with related Accounts deterministic stable across cycles
10. Contact no Account unmatched or per rule
11. Thread more than 2 back and forth imported linked consistently
12. Exclude Confidential excluded summary correct
13. Exclude Marketing excluded summary correct
14. Exclude Internal excluded summary correct
15. Exclude Public domains excluded summary correct
16. Boundary sync window end time email included next run counts correct
17. Partial outcome status Partial when some fail
18. Email with attachments has files filter works
19. Large email body truncation works
20. Ordering latest first works
21. Badge attached correctly
22. Notification correct

---

## System admin | Gmail | Sent items | Quick Match

1. Sent to 1 Contact 1 Account appears recent EmailMessage linked correctly
2. Sent to 2 Contacts in To both matched
3. Sent to 1 Contact in To and 1 Contact in CC both matched
4. Sent to 2 Contacts in To and internal User in CC sync by CC user both matched sender visibility correct
5. One Contact multiple Accounts deterministic selection
6. Sent items manual match contacts not picked regression verify fixed
7. Sent items already synced rerun no duplicate
8. Sent items attachments has files filter works
9. Sent items large body truncation works
10. Sent items ordering latest first works
11. Badge attached correctly
12. Notification correct

---

## System admin | Gmail | Sent items | Run now

1. Sent to 1 Contact 1 Account linked correctly
2. Sent to 2 Contacts in To both matched
3. Sent to 1 Contact in To and 1 Contact in CC both matched
4. Sent to 2 Contacts in To and internal User in CC both matched sender visibility correct
5. One Contact multiple Accounts deterministic selection
6. Sent items already synced rerun no duplicate
7. Sent items attachments has files filter works
8. Sent items large body truncation works
9. Boundary window for sent items counts correct and no duplicates
10. Partial outcome status Partial when some fail
11. Ordering latest first works
12. Badge attached correctly
13. Notification correct

---

## System admin | Gmail | Sent items | Scheduler

1. Sent items enabled imports sent items correctly per user
2. Sent to 2 Contacts in To both matched
3. Sent to 1 Contact in To and 1 Contact in CC both matched
4. Sent to 2 Contacts in To and internal User in CC both matched sender visibility correct
5. One Contact multiple Accounts deterministic selection stable across cycles
6. More than 20 sent emails batching works
7. Sent items already synced rerun no duplicate
8. Sent items attachments has files filter works
9. Sent items large body truncation works
10. Boundary window for sent items counts correct and no duplicates
11. Partial outcome status Partial when some fail
12. Ordering latest first works
13. Badge attached correctly
14. Notification correct

---

## Standard User | Outlook | Inbox | Quick Match

1. Permissions check Standard User can run sync and can view created EmailMessages based on sharing rules

---

## Standard User | Outlook | Inbox | Run now

1. Permissions check Standard User can run sync and can view created EmailMessages based on sharing rules

---

## Standard User | Outlook | Inbox | Scheduler

1. Permissions check Standard User can run sync and can view created EmailMessages based on sharing rules

---

## Standard User | Outlook | Sent items | Quick Match

1. Permissions check Standard User can run sync and can view created EmailMessages based on sharing rules

---

## Standard User | Outlook | Sent items | Run now

1. Permissions check Standard User can run sync and can view created EmailMessages based on sharing rules

---

## Standard User | Outlook | Sent items | Scheduler

1. Permissions check Standard User can run sync and can view created EmailMessages based on sharing rules

---

## Standard User | Gmail | Inbox | Quick Match

1. Permissions check Standard User can run sync and can view created EmailMessages based on sharing rules

---

## Standard User | Gmail | Inbox | Run now

1. Permissions check Standard User can run sync and can view created EmailMessages based on sharing rules

---

## Standard User | Gmail | Inbox | Scheduler

1. Permissions check Standard User can run sync and can view created EmailMessages based on sharing rules

---

## Standard User | Gmail | Sent items | Quick Match

1. Permissions check Standard User can run sync and can view created EmailMessages based on sharing rules

---

## Standard User | Gmail | Sent items | Run now

1. Permissions check Standard User can run sync and can view created EmailMessages based on sharing rules

---

## Standard User | Gmail | Sent items | Scheduler

1. Permissions check Standard User can run sync and can view created EmailMessages based on sharing rules

---

## Sales perspective – additional email flow scenarios

How emails typically flow between a salesperson (Gmail/Outlook) and customers; API fetches and matches by Contact/From/To. Use these across Inbox, Sent, Quick Match, Run now, and Scheduler as applicable.
1. Initial outreach – Salesperson sends cold email to prospect (Contact); prospect replies. Sent item and reply both sync and link to same Contact and Account.
2. Meeting follow-up – After a meeting, salesperson sends thank-you or summary to Contact; Contact replies with questions. Full thread syncs and links to same Contact and Opportunity.
3. Proposal to multiple contacts – Salesperson sends proposal To: primary Contact, CC: champion (second Contact) at same Account. Both Contacts get EmailMessage; no spillover to other objects.
4. Reply-all – Salesperson emails 3 Contacts at Account; one Contact reply-alls. All 3 receive reply; sync links reply to correct Contact (From) and others per To/CC matching.
5. Sequence / drip – Multiple emails over time to same Contact (e.g. 5 over 2 weeks). All sync and link to same Contact; order latest first; no duplicates.
6. Contact A asks, Contact B replies (same Account) – Email To: Contact A; reply from Contact B (same Account). Both directions link to correct Contact; no cross-link.
7. Thread forwarded to new person – Customer forwards thread to colleague; colleague replies. If colleague is a Contact, reply matches to that Contact; if not, stays unmatched per rule.
8. Reply from wrong contact – Email was To: Contact A; Contact B (same Account) replies by mistake. Match by From address to Contact B; logged under Contact B.
9. Out of office – Contact has OOO auto-reply. Verify excluded (e.g. marketing/internal) or matched to Contact per product rule; no duplicate or wrong count.
10. Quote or pricing email – Heavy HTML, tables, long body. Sync succeeds; body truncated per limits; linked to Contact and Opportunity.
11. Contract or attachment-heavy – Email with contract PDF, multiple attachments. Import succeeds; has files filter works; linked to correct Contact.
12. Thread where Contact was CC'd – First email To: someone else, CC: Contact. Contact replies. Reply matches to Contact (From); original may match per To/CC rules.
13. BCC – Salesperson BCCs manager. Only To/CC used for matching; BCC not used; no separate record for BCC recipient.
14. Multiple opportunities same Account – Email about open Opp B; Contact also on closed Opp A. Email links to Opp B and Account only; no link to Opp A.
15. Re-engagement / old thread – New email to same Contact after long gap. New email syncs and links to Contact; sync window or date filter determines what is fetched.
16. Reply from personal email – Contact in Salesforce has work email; replies from personal email. Stays unmatched unless personal email on Contact or alternate match rule.
17. Internal + external – To: Contact, CC: internal sales manager. Exclude internal on: only Contact matched; internal not used for matching.
18. Territory or owner change – Emails from Contact sync to current owner’s workspace; visibility and sharing per Salesforce sharing rules.
19. Meeting recap – “As discussed on our call…” email to Contact. Normal sync; links to Contact and optionally Opportunity.
20. Group or alias address – Email To: group@company.com; Contact’s email is contact@company.com. Match only if exact or per rule for group/alias.

Add or map these to the relevant category (Inbox/Sent, Outlook/Gmail, Quick Match/Run now/Scheduler) when building test runs.
---

## Email Sync Settings – behavior to verify

Reference: Email Sync Settings (e.g. Email Sync Enabled, Sync Frequency, Lookback Hours, Max Emails Per User, Emails Per Batch, Max Users Per Batch, Queueable Delay).
1. Auto sync toggle (per user) – Each user has an auto sync toggle. When that user disables it, any auto sync (scheduler) does not run for them; that user is excluded from scheduled sync. Verify: user with toggle off gets no scheduler run; workspace logs or runs do not include that user.
2. Scheduler frequency – Scheduler runs at the interval set by Sync Frequency (Minutes) (e.g. every 60 minutes). Verify: sync executes at the configured interval.
3. Scheduler batching – Scheduler respects Max Users Per Batch (e.g. 10) and Max Emails Per User (e.g. 1,000). Verify: no more than Max Users Per Batch processed in one batch; per-user email processing capped at Max Emails Per User.
4. Lookback hours – Used only when no email sync has happened before for that email account (first-time sync). For that account, the system looks back the number of hours set in Lookback Hours (e.g. 300) and fetches emails from that window. Verify: first-time sync for a user/account fetches emails from the last N hours; subsequent syncs use normal sync window, not lookback.
5. Emails Per Batch – Drives batch size (e.g. 20); aligns with manual match limit (manual match of more than 20 throws an error). Verify: batch behavior and manual match limit consistent with this value.
6. Email Sync Enabled (global) – When disabled, email sync (Quick Match, Run now, Scheduler) is off as designed. Verify: toggle off disables sync; toggle on allows sync per user and frequency.
7. Queueable Delay (Minutes) – When set, delay between queueable jobs. Verify: when non-zero, scheduler/jobs respect the delay; no impact when 0.

Use these when testing Scheduler and first-time vs recurring sync.
---

## Cross-cutting (UI / Config – use as needed)

- UI: Count of emails dynamic based on unread, has files, and time filters; matched and excluded counts correct where shown.
- Custom settings: All custom setting fields visible under AI Setting > Workspace.
- Sync enable checkbox: Email sync enable/disable affects Quick Match, Run now, and Scheduler as designed.
- Inactive provider: When Outlook or Gmail is inactivated, that provider is not visible in the UI.
- Same user, Gmail and Outlook: Both providers can be configured; scheduler runs per provider; no conflict.

---

## Quick reference – table row to section

| Profile       | Service provider | Inbox/Sent items | Sync type   |
|---------------|------------------|------------------|-------------|
| System admin  | Outlook          | Inbox            | Quick Match |
| System admin  | Outlook          | Inbox            | Run now     |
| System admin  | Outlook          | Inbox            | Scheduler   |
| System admin  | Outlook          | Sent items       | Quick Match |
| System admin  | Outlook          | Sent items       | Run now     |
| System admin  | Outlook          | Sent items       | Scheduler   |
| System admin  | Gmail            | Inbox            | Quick Match |
| System admin  | Gmail            | Inbox            | Run now     |
| System admin  | Gmail            | Inbox            | Scheduler   |
| System admin  | Gmail            | Sent items       | Quick Match |
| System admin  | Gmail            | Sent items       | Run now     |
| System admin  | Gmail            | Sent items       | Scheduler   |
| Standard User | Outlook          | Inbox            | Quick Match |
| Standard User | Outlook          | Inbox            | Run now     |
| Standard User | Outlook          | Inbox            | Scheduler   |
| Standard User | Outlook          | Sent items       | Quick Match |
| Standard User | Outlook          | Sent items       | Run now     |
| Standard User | Outlook          | Sent items       | Scheduler   |
| Standard User | Gmail            | Inbox            | Quick Match |
| Standard User | Gmail            | Inbox            | Run now     |
| Standard User | Gmail            | Inbox            | Scheduler   |
| Standard User | Gmail            | Sent items       | Quick Match |
| Standard User | Gmail            | Sent items       | Run now     |
| Standard User | Gmail            | Sent items       | Scheduler   |

---

For Standard User rows: use the permissions check as the last line when combining with other instructions, or use it as the sole instruction per your process. Large emails, HTML emails, thread emails, and forwarded emails are covered in the scenarios above (e.g. large body truncation, thread back-and-forth, thread forward then reply).