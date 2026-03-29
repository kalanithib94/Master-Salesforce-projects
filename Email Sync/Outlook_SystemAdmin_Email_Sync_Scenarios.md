# System admin | Outlook | Inbox & Outbox – Testing Scenarios

This file contains testing scenarios for System admin, Outlook, Inbox and Outbox, in three sync types: Quick Match, Run now, and Scheduler. Use the same context and expectations as the Quick Match list below.

---

## System admin | Outlook | Inbox & Outbox | Quick Match

1. Inbox - Email from one Contact having one Account one opportunity after match EmailMessage created and linked correctly
2. Select emails up to 20 and click import selected all email matched with contact imported and remains stays unmatched
3. Select More than 20 emails and click import selected, it should shows the error toast message "Too many emails selected".
4. Already imported emails for rerun - We are not able to select already imported emails for rerun.
5. Already imported emails after deleting logs or staging EmailMessage then it will be available for rerun
6. Inbox - Email received from non contact ( Not matching any of the Contact or Lead ) while importing the email goes unmatched. ( Means we are unable to click Associate button to import)
7. Email received from Contact and has no direct Account linked while importing Email messages imported only to contact
8. Email received from the Contact and has multiple related Accounts and multiple related opportunities- we are able to select particular account and opportunity while import
9. Inbox : Forwarded thread emails successfully imported without truncating the email body
10. Inbox : Received email and Same email id with multiple Contact , multiple Account and multiple Opportunities - we need to select the contact and associate it to log the email message
11. Email received from the Contact and has one account without opportunity - Email messages logged in contact and account while import
12. Thread emails more than 2 back and forth all messages imported linked consistently, however email messages logs separately.
13. Email received from the Contact 1 and Contact 2 same Account replies for the email both directions imported linked to correct Contacts
14. Outbox - Send Email to 2 Contacts in To address both Contacts gets matched and imported
15. Outbox - Send Email to 1 Contact in To address and 1 Contact in CC both Contacts matched gets matched and imported
16. Email received from the Contact to 2 different Users ( two different inboxes) when first user imports, cannot import again by second user ( When 2nd user open the email sync that email shows already imported status )
17. Account with website without Contact - Received email from one of the email id which is matching the domain of the account however it stays unmatched no email import.
18. Email received from non contact person of the existing account but we have some other contact in the same account , it should not look domain of the email and find the account it should always look the exact match of the email address of the Contact. In this case it should stays unmatched.
19. Email received with attachment - Click "Has file" button , the email with attachments should filter and display under the section.
20. Email with attachments import succeeds however handling the attachments not in this release.
21. A large email body should import successfully without any truncation.
22. No subject email import succeeds subject handled as blank
23. Very long subject import succeeds subject truncated per limits
24. Multiple languages ,Special characters, non latin emoji import succeeds content stored correctly without truncation.
25. Email sorting - Always should show latest email ( inbox / outbox ) first in email sync page
26. Imported badge attached to imported emails with related record pills, when you click on the pill it will redirect you to the record.
27. Notification received when completed the successful import, and when you click the notification it should take you to the email messages record.
28. Exclude Confidential enabled confidential emails skipped excluded count and summary correct
29. When Exclude Internal enabled and provided the domain for exclusion, internal emails will be excluded as per the exclusion rule and displayed toast message "1 email excluded by exclusion rules. No emails imported"
30. When Exclude Internal enabled and provided the domain for exclusion, Received email from internal team having one of the contact in To or CC address.
31. When you have multiple related accounts and multiple opportunities however we don't want to log the email messages to Account and opportunity then we need to select none option in the account. So the email messages are logged only into Contact.
32. When you have multiple related accounts and multiple opportunities however we don't want to log the email messages to the opportunity then we need to select none option in the opportunity. So the email messages are logged into Contact and account.
33. When Exclude Marketing enabled - Try to import a marketing email, it should stays excluded and displayed toast message " 1 email excluded by exclusion rules. No emails imported"
34. Send items : When we send the email with contact in BCC, while importing only contact in To address gets matched and imported however contacts in BCC are getting matched but not getting imported.
35. Inbox : When we received the email with our email id in BCC, while importing the email gets imported and email messages logged under the matching contacts.
36. Exclude Public domains enabled public domain emails skipped excluded count correct

---

## System admin | Outlook | Inbox & Outbox | Run now

1. Inbox - Email from one Contact having one Account one opportunity Run now imports and EmailMessage created and linked correctly
2. Run now with up to 20 emails matched with Contact all imported and unmatched remain unmatched
3. Run now with more than 20 emails should batch or process per configuration; if selection limit applies in UI it should show error toast "Too many emails selected" where applicable
4. Already imported emails for rerun - Run now again does not create duplicate EmailMessages; already imported emails not selected again
5. Already imported emails after deleting logs or staging EmailMessage then Run now makes them available for import again and does not create duplicate
6. Inbox - Email received from non contact (Not matching any Contact or Lead) Run now leaves email unmatched; no EmailMessage created
7. Email received from Contact and has no direct Account linked Run now imports Email messages only to Contact
8. Email received from Contact with multiple related Accounts and multiple related opportunities Run now allows or applies deterministic account and opportunity selection per rule and links correctly
9. Inbox : Forwarded thread emails Run now imports successfully without truncating the email body
10. Inbox : Same email id with multiple Contact, multiple Account and multiple Opportunities Run now we need to select the contact and associate to log the email message (or per rule deterministic selection)
11. Email received from Contact with one account without opportunity Run now logs Email messages in Contact and Account
12. Thread emails more than 2 back and forth Run now imports all messages linked consistently; email messages logs separately
13. Email received from Contact 1 and Contact 2 same Account replies Run now imports both directions linked to correct Contacts
14. Outbox - Send Email to 2 Contacts in To address Run now both Contacts get matched and imported
15. Outbox - Send Email to 1 Contact in To and 1 Contact in CC Run now both Contacts get matched and imported
16. Email received from Contact to 2 different Users (two different inboxes) first user Run now imports; second user cannot import again (email shows already imported status when 2nd user opens email sync)
17. Account with website without Contact - Email from address matching domain of account Run now stays unmatched no email import
18. Email received from non contact person of existing account (other contact in same account) Run now uses exact match of email address of Contact only; stays unmatched
19. Email received with attachment Run now imports; "Has file" button filters and displays emails with attachments in the section
20. Email with attachments Run now import succeeds; handling the attachments not in this release
21. Large email body Run now import succeeds without truncation
22. No subject email Run now import succeeds subject handled as blank
23. Very long subject Run now import succeeds subject truncated per limits
24. Multiple languages, Special characters, non latin emoji Run now import succeeds content stored correctly without truncation
25. Email sorting after Run now - Latest email (inbox / outbox) first in email sync page
26. Imported badge attached to imported emails with related record pills; click on pill redirects to the record
27. Notification received when Run now completes successful import; click notification takes you to the email messages record
28. Exclude Confidential enabled Run now skips confidential emails excluded count and summary correct
29. Exclude Internal enabled with domain for exclusion Run now excludes internal emails per rule and shows toast "1 email excluded by exclusion rules. No emails imported" when applicable
30. Exclude Internal enabled with domain for exclusion; email from internal team with one contact in To or CC Run now applies exclusion rule correctly
31. Multiple related accounts and multiple opportunities; select none for account so email messages logged only into Contact Run now respects selection and logs only to Contact
32. Multiple related accounts and multiple opportunities; select none for opportunity so email messages logged into Contact and Account Run now respects selection
33. Exclude Marketing enabled Run now keeps marketing email excluded and shows toast "1 email excluded by exclusion rules. No emails imported"
34. Send items : Email with contact in BCC Run now only contact in To gets matched and imported; contacts in BCC matched but not imported
35. Inbox : Email received with our email id in BCC Run now imports and email messages logged under the matching contacts
36. Exclude Public domains enabled Run now skips public domain emails excluded count correct
37. Sync window boundary - Emails at last run end time included in next Run now; matched not duplicated; unmatched count correct
38. Partial outcome when some emails fail Run now shows Partial status and counts reflect succeeded and failed

---

## System admin | Outlook | Inbox & Outbox | Scheduler

1. Scheduler runs for this user workspace log created for Outlook
2. Scheduler runs for all authorized users with Outlook; logs per user no cross user mixing
3. Auto sync disabled for a user that user excluded from scheduler; no run for them
4. Inbox - Email from one Contact having one Account one opportunity when scheduler runs EmailMessage created and linked correctly
5. Scheduler with up to 20 emails matched with Contact all imported; unmatched remain unmatched
6. Scheduler with more than 20 emails batches correctly; no timeout; counts match
7. Already imported emails scheduler rerun does not create duplicate EmailMessages
8. Already imported emails after deleting logs or staging EmailMessage then next scheduler run makes them available for import and does not create duplicate
9. Inbox - Email from non contact (Not matching any Contact or Lead) scheduler leaves unmatched; no EmailMessage created
10. Email from Contact with no direct Account scheduler imports Email messages only to Contact
11. Email from Contact with multiple related Accounts and multiple related opportunities scheduler uses deterministic account and opportunity selection per rule and links correctly
12. Inbox : Forwarded thread emails scheduler imports successfully without truncating the email body
13. Inbox : Same email id with multiple Contact, multiple Account and multiple Opportunities scheduler applies selection or deterministic rule and logs to correct contact
14. Email from Contact with one account without opportunity scheduler logs Email messages in Contact and Account
15. Thread emails more than 2 back and forth scheduler imports all messages linked consistently; email messages logs separately
16. Email from Contact 1 and Contact 2 same Account replies scheduler imports both directions linked to correct Contacts
17. Outbox - Send Email to 2 Contacts in To address scheduler both Contacts get matched and imported
18. Outbox - Send Email to 1 Contact in To and 1 Contact in CC scheduler both Contacts get matched and imported
19. Email from Contact to 2 different Users when scheduler runs per user first user imports; second user sees already imported status
20. Account with website without Contact - Email from address matching domain scheduler stays unmatched no email import
21. Email from non contact person of existing account (other contact in same account) scheduler exact match only; stays unmatched
22. Email with attachment scheduler import succeeds; "Has file" filter displays emails with attachments
23. Email with attachments scheduler import succeeds; handling the attachments not in this release
24. Large email body scheduler import succeeds without truncation
25. No subject email scheduler import succeeds subject handled as blank
26. Very long subject scheduler import succeeds subject truncated per limits
27. Multiple languages, Special characters, non latin emoji scheduler import succeeds content stored correctly without truncation
28. Email sorting after scheduler - Latest email (inbox / outbox) first in email sync page
29. Imported badge attached to imported emails with related record pills; click on pill redirects to the record
30. Notification received when scheduler completes successful import; click notification takes you to the email messages record
31. Exclude Confidential enabled scheduler skips confidential emails excluded count and summary correct
32. Exclude Internal enabled with domain scheduler excludes internal emails and shows toast "1 email excluded by exclusion rules. No emails imported" when applicable
33. Exclude Internal enabled; email from internal team with contact in To or CC scheduler applies exclusion rule correctly
34. Multiple related accounts and opportunities; select none for account scheduler logs only to Contact
35. Multiple related accounts and opportunities; select none for opportunity scheduler logs to Contact and Account
36. Exclude Marketing enabled scheduler keeps marketing email excluded and shows toast "1 email excluded by exclusion rules. No emails imported"
37. Send items : Email with contact in BCC scheduler only contact in To matched and imported; BCC contacts matched but not imported
38. Inbox : Email with our email id in BCC scheduler imports and email messages logged under the matching contacts
39. Exclude Public domains enabled scheduler skips public domain emails excluded count correct
40. Sync window boundary - Emails at last run end time included in next scheduler run; matched not duplicated; unmatched count correct
41. Provider inactive (Outlook) UI not visible and scheduler does not run for that provider
42. Scheduler runs at the configured Sync Frequency (Minutes); verify run occurs at interval

---

Use this file for System admin, Outlook, Inbox and Outbox only. For Gmail or Standard User use the main Email_Sync_Testing_Instructions.md or extend these scenarios in the same style.
