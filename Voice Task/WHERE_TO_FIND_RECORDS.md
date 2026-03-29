# Where to Find Created Records

## 📍 Location of All Created Records

---

## 1️⃣ **Contact Record**

### Option A: From the Event
1. Go to your **Event** record (the one created from voice recording)
2. Look at **Related To** section
3. Click on the **Contact Name** (e.g., "Sarah Chen")
4. This opens the Contact record

### Option B: From Contacts Tab
1. Click **App Launcher** (9 dots) in top left
2. Search for **"Contacts"**
3. Click **Contacts** tab
4. Search for the contact name
5. Click to open

### Option C: Global Search
1. Click the **Search** bar at the top
2. Type the contact name (e.g., "Sarah Chen")
3. Results will show under **Contacts**
4. Click to open

### What You'll See on Contact:
```
Contact: Sarah Chen
├─ Account: Chen Family Office (auto-created)
├─ Related Items:
│   ├─ Events (1) - Your voice meeting event
│   ├─ Tasks (1) - Follow-up task
│   └─ Opportunities (via Account)
└─ Description: "Auto-created from voice meeting transcript..."
```

---

## 2️⃣ **Opportunity Record**

### Option A: From the Contact
1. Open the **Contact** record (Sarah Chen)
2. Scroll down to **Related** section
3. Click **Related** tab
4. Look for **Opportunities** section
5. Click the Opportunity name (e.g., "Sarah Chen - Direct deal exploration")

### Option B: From the Account
1. Open the **Contact** record
2. Click on the **Account** name (e.g., "Chen Family Office")
3. Scroll down to **Related** section
4. Look for **Opportunities** section
5. Click the Opportunity name

### Option C: From Opportunities Tab
1. Click **App Launcher** (9 dots)
2. Search for **"Opportunities"**
3. Click **Opportunities** tab
4. Sort by **Created Date** (most recent first)
5. Look for opportunity with the contact name
6. Click to open

### Option D: Global Search
1. Use **Search** bar at top
2. Type contact name + "opportunity"
3. Results will show under **Opportunities**

### What You'll See on Opportunity:
```
Opportunity: Sarah Chen - Direct deal exploration
├─ Account: Chen Family Office
├─ Stage: Qualification
├─ Close Date: June 30, 2026 (from Q2 2026)
├─ Type: Direct deal exploration
├─ Description: 
│   Interests: Impact Investing, Climate Tech
│   Referral: Paul Chew
└─ Contact Roles:
    └─ Sarah Chen (Decision Maker) ⭐
```

---

## 3️⃣ **Task Record**

### Option A: From the Contact
1. Open the **Contact** record
2. Scroll to **Activity** section
3. Look under **Open Activities** or **Upcoming & Overdue**
4. Click task: "Follow-up: Family Office Summit"

### Option B: From Your Home
1. Go to **Home** tab
2. Look at **My Tasks** widget
3. Find the follow-up task
4. Click to open

### Option C: From Tasks Tab
1. Click **App Launcher** (9 dots)
2. Search for **"Tasks"**
3. Click **Tasks** tab
4. Filter by **Status = Not Started**
5. Sort by **Due Date**

### What You'll See on Task:
```
Task: Follow-up: Family Office Summit
├─ Assigned To: You
├─ Related To: Contact (Sarah Chen)
├─ Status: Not Started
├─ Priority: High
├─ Due Date: [7 days from today]
└─ Description:
    Follow-up from meeting discussion.
    
    Topics of Interest: Impact Investing, Climate Tech
    Referred by: Paul Chew
    Timeline: Q2 2026
```

---

## 4️⃣ **Account Record** (Auto-Created)

### How to Find:
1. Open the **Contact** record
2. Click on **Account** name (e.g., "Chen Family Office")
3. OR use Global Search: Search for "[LastName] Family Office"

### What You'll See on Account:
```
Account: Chen Family Office
├─ Contacts (1):
│   └─ Sarah Chen
└─ Opportunities (1):
    └─ Sarah Chen - Direct deal exploration
```

---

## 5️⃣ **Event Record** (Your Original)

### How to Find:
1. Click **App Launcher** → **Calendar**
2. Find your meeting on the calendar
3. Click to open
4. OR go to **Events** tab and search

### What You'll See:
```
Event: Business Development Meeting
├─ Related To (WhoId): Sarah Chen (Contact)
├─ Description: [Full transcript]
└─ Tasks (Related):
    └─ Follow-up: Family Office Summit
```

---

## 🗂️ **Complete Record Hierarchy**

```
📁 Account: Chen Family Office
   │
   ├─ 👤 Contact: Sarah Chen
   │    │
   │    ├─ 📅 Event: Business Development Meeting
   │    │    └─ Description: [Transcript]
   │    │
   │    └─ ✅ Task: Follow-up: Family Office Summit
   │         └─ Due: [+7 days]
   │
   └─ 💼 Opportunity: Sarah Chen - Direct deal exploration
        ├─ Stage: Qualification
        ├─ Close Date: June 30, 2026
        ├─ Contact Role: Sarah Chen (Decision Maker)
        └─ Description: Interests, Referral info
```

---

## 🔍 **Quick Search Method (Easiest)**

### After Running Your Flow:

1. **Click Search bar** (top of screen)
2. **Type the contact name** from your transcript
3. You'll see results grouped by object:

```
🔍 Results for "Sarah Chen":

👤 Contacts
   Sarah Chen - Chen Family Office

💼 Opportunities  
   Sarah Chen - Direct deal exploration

📅 Events
   Business Development Meeting

✅ Tasks
   Follow-up: Family Office Summit
```

4. **Click any result** to open that record

---

## 📊 **Verification Checklist**

After your Flow runs, verify these were created:

```
✅ Account exists: [LastName] Family Office
✅ Contact exists: [First Last]
✅ Contact is linked to Account
✅ Event is linked to Contact (WhoId populated)
✅ Task exists under Contact (Status: Not Started, Due: +7 days)
✅ Opportunity exists for Account
✅ Opportunity has Contact Role for the Contact
```

---

## 🎯 **From Your Flow - Get Record IDs**

Your Flow receives these IDs as outputs:

```
Apex Action Output Variables:
├─ contactId → Use to navigate: /[contactId]
├─ taskId → Use to navigate: /[taskId]
├─ opportunityId → Use to navigate: /[opportunityId]
└─ isSuccess → Check if all created successfully
```

### Display IDs in Flow (For Testing):
Add a Screen element after the Apex action:
```
Screen: "Records Created Successfully!"
├─ Display Text: "Contact ID: {!contactId}"
├─ Display Text: "Task ID: {!taskId}"  
├─ Display Text: "Opportunity ID: {!opportunityId}"
└─ Button: "View Contact" 
    → Navigate to: /[contactId]
```

---

## 🔗 **Direct URL Navigation**

If you have the IDs, you can directly navigate:

```
Contact: https://[your-instance].lightning.force.com/lightning/r/Contact/[contactId]/view

Opportunity: https://[your-instance].lightning.force.com/lightning/r/Opportunity/[opportunityId]/view

Task: https://[your-instance].lightning.force.com/lightning/r/Task/[taskId]/view

Event: https://[your-instance].lightning.force.com/lightning/r/Event/[eventId]/view
```

---

## 📱 **In Salesforce Mobile App**

1. Open **Salesforce Mobile App**
2. Tap **Search** icon
3. Type contact name
4. Tap to open Contact
5. Swipe to **Related** tab to see Tasks, Opportunities, Events

---

## 💡 **Pro Tip: Create a Quick Action**

Add a button on the Event to quickly see all related records:

1. **Setup** → **Object Manager** → **Event**
2. **Buttons, Links, and Actions** → **New Action**
3. **Action Type**: Quick Action
4. **Target Object**: Event
5. Create button: "View All Related Records"

Or just use the standard **Related** tab on the Event! ✨

---

Need help finding a specific record? Let me know! 🔍

