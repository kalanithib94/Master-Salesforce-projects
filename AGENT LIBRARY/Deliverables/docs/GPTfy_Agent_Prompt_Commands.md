# GPTfy Generic Agent — AI Prompt Commands (37 Skills)

**Purpose:** This document gives you the exact `Prompt_Command__c` JSON Schema for each of the 37 skills in `GenericAgenticSkillsHandler`. Each AI Prompt record (`AI_Prompt__c`) you create in Salesforce needs three fields populated:

| `AI_Prompt__c` field | Value |
|----------------------|-------|
| `Name` | The skill name (e.g. `fuzzy_search_accounts`) — must match exactly the `when` branch in `GenericAgenticSkillsHandler.executeMethod` |
| `Type__c` | `Agentic` |
| `Status__c` | `Active` |
| `Agentic_Function_Class__c` | `GenericAgenticSkillsHandler` |
| `Description__c` | (use the **Description** block under each skill below — the LLM uses this to decide when to call the skill) |
| `Prompt_Command__c` | (use the **Prompt Command** JSON block under each skill below — this is the OpenAI function-calling parameter schema) |

After all 37 prompt records are created, link each one to the parent `AI_Agent__c` record via the `AI_Agent_Skill__c` junction. Set `Profiles__c` and `Permission_Sets__c` on each prompt if you want to restrict who can invoke it.

> **Tip:** Description fields are read by the LLM at every turn. Keep them sharp and unambiguous — vague descriptions cause the agent to call the wrong skill.

---

## 1. ACCOUNT SKILLS (5)

---

### 1.1 — `fuzzy_search_accounts`

**Description**
```
Searches Accounts by partial Name match. Use this when the user wants to find, look up, list, or locate an Account by name. Handles spaces, hyphens, casing differences and filler words ("the", "a").

Fetches ALL matching Accounts from the database (capped at 200) ordered by LastModifiedDate DESC, and returns the LATEST 5 to the agent in `records`. The JSON envelope also carries `totalFound`, `displayed`, and `remaining` — when more than 5 Accounts match, the agent shows the latest 5 and tells the user how many more weren't shown.

Per-record fields: Id, Name, Type, Industry, Website, recordUrl, and a pre-built `viewRecord` HTML anchor for the agent to render as a clickable "View Record" link. Display schema the agent surfaces to the user: Name | Type | Industry | Website | View Record.
```

**Prompt Command**
```json
{
  "type": "object",
  "properties": {
    "search_term": {
      "type": "string",
      "description": "The Account name (or partial name) to search for. Examples: 'Acme', 'power grid', 'United Health'."
    }
  },
  "required": ["search_term"]
}
```

---

### 1.2 — `fetch_account_details`

**Description**
```
Returns the full detail record of a single Account: Industry, Type, AnnualRevenue, NumberOfEmployees, Phone, Website, Owner, BillingAddress, Description, recordUrl. (Rating is not returned — omit from answers.)

Supply exactly one of: account_id OR account_name (schema anyOf).

- Prefer account_id whenever you have a confirmed 15/18-char Account Id — especially on an Account record page (page-context Id starting with 001…). That path runs a direct detail query.

- Use account_name when the user explicitly named the Account and you have no Id. Name resolution uses the same fuzzy Name logic as fuzzy_search_accounts: exactly one match returns full details; 2–5 matches return errorCode AMBIGUOUS_ACCOUNT_NAME plus picker rows (same columns as fuzzy_search_accounts); 6+ matches return errorCode TOO_MANY_ACCOUNT_MATCHES plus totalFound — ask the user to refine; do not list every row.

Never invent an Id. Never pass a Salesforce Id as account_name.
```

**Prompt Command**
```json
{
  "type": "object",
  "properties": {
    "account_id": {
      "type": "string",
      "description": "Salesforce Account Id (15 or 18 characters). Use when you have a confirmed Id (record page, prior turn, or user pasted Id). Preferred over account_name when both could apply."
    },
    "account_name": {
      "type": "string",
      "description": "Account Name as the user stated it. Use when you have no Account Id. The skill fuzzy-matches on Name; see skill Description for single vs multi-match behaviour."
    }
  },
  "anyOf": [
    { "required": ["account_id"] },
    { "required": ["account_name"] }
  ]
}
```

---

### 1.3 — `create_account`

**Description**
```
Creates a new Account record. Use this when the user explicitly asks to create, add, or register a new Account. "Name" is the ONLY required field. Pass every Account field (Name, Industry, Type, AnnualRevenue, Phone, Website, BillingStreet/City/State/PostalCode/Country, Description, Rating, custom fields, …) as a flat top-level parameter using the exact Salesforce API name. Numbers as plain numbers, booleans as true/false, picklist values as the exact API value. Never invoke without "Name"; if the user has not provided an Account Name, ask for it first.
```

**Prompt Command**
```json
{
  "type": "object",
  "required": ["Name"],
  "properties": {
    "Name": {
      "type": "string",
      "description": "Required. The Account Name (e.g. 'Acme Corporation')."
    },
    "Industry": {
      "type": "string",
      "description": "Optional. Industry picklist API value (call fetch_picklist_values first if unsure)."
    },
    "Type": {
      "type": "string",
      "description": "Optional. Type picklist API value."
    },
    "AnnualRevenue": {
      "type": "number",
      "description": "Optional. Annual revenue as a plain number."
    },
    "NumberOfEmployees": {
      "type": "number",
      "description": "Optional. Headcount as a plain integer."
    },
    "Phone": {
      "type": "string",
      "description": "Optional. Account phone number."
    },
    "Website": {
      "type": "string",
      "description": "Optional. Account website URL."
    },
    "BillingStreet": { "type": "string", "description": "Optional. Billing street." },
    "BillingCity": { "type": "string", "description": "Optional. Billing city." },
    "BillingState": { "type": "string", "description": "Optional. Billing state/province." },
    "BillingPostalCode": { "type": "string", "description": "Optional. Billing postal/ZIP code." },
    "BillingCountry": { "type": "string", "description": "Optional. Billing country." },
    "Description": { "type": "string", "description": "Optional. Long-text description." },
    "Rating": { "type": "string", "description": "Optional. Rating picklist API value (e.g. Hot, Warm, Cold)." }
  },
  "additionalProperties": true
}
```

---

### 1.4 — `update_account_fields`

**Description**
```
Updates one or more fields on an existing Account. Use this when the user wants to change, set, modify, or correct any field on an Account. Supports Text, Number, Picklist, Dependent Picklist and Boolean fields in a single call. ALWAYS confirm the change with the user (current value → new value) before invoking this skill. Never invoke without an Account Id.
```

**Prompt Command**

Field updates are passed as flat top-level keys (NOT nested under a `fields` object). Common Account fields are declared explicitly for LLM steering; any other standard or custom field (including `__c` fields) can be passed via `additionalProperties: true` and will be picked up by the Apex.

```json
{
  "type": "object",
  "required": ["account_id"],
  "properties": {
    "account_id": {
      "type": "string",
      "description": "ONLY the Salesforce Id of the Account to update."
    },
    "Name": {
      "type": "string",
      "description": "Account Name."
    },
    "Industry": {
      "type": "string",
      "description": "Industry picklist API value (call fetch_picklist_values first if unsure)."
    },
    "Type": {
      "type": "string",
      "description": "Type picklist API value (call fetch_picklist_values first if unsure)."
    },
    "AnnualRevenue": {
      "type": "number",
      "description": "Annual revenue as a plain number, no currency symbol or commas."
    },
    "Phone": {
      "type": "string",
      "description": "Account phone number."
    },
    "Website": {
      "type": "string",
      "description": "Account website URL."
    },
    "Description": {
      "type": "string",
      "description": "Long-text description of the Account."
    }
  },
  "additionalProperties": true
}
```

---

### 1.5 — `fetch_account_related_lists`

**Description**
```
Returns the related lists for an Account — Contacts, Opportunities, and/or Cases. Use this when the user asks about an Account's related records, contacts on the account, deals on the account, or open cases on the account. If "related" is omitted, all three lists are returned.
```

**Prompt Command**
```json
{
  "type": "object",
  "properties": {
    "account_id": {
      "type": "string",
      "description": "ONLY the Salesforce Id of the Account whose related lists should be fetched."
    },
    "related": {
      "type": "array",
      "description": "Optional. Which related lists to fetch. Allowed values: 'contacts', 'opportunities', 'cases'. If omitted, all three are returned.",
      "items": { "type": "string", "enum": ["contacts", "opportunities", "cases"] }
    }
  },
  "required": ["account_id"]
}
```

---

## 2. CONTACT SKILLS (5)

---

### 2.1 — `fuzzy_search_contacts`

**Description**
```
Searches Contacts by Name OR Email (partial match). Use this when the user wants to find, look up, or locate a Contact.

Fetches ALL matching Contacts (capped at 200) ordered by LastModifiedDate DESC and returns the LATEST 5 in `records`. Envelope carries `totalFound`, `displayed`, `remaining` so the agent can append "{remaining} more not shown" when more than 5 Contacts match. Per-record fields: Id, Name, Email, Phone, Title, Account, recordUrl, viewRecord (HTML "View Record" anchor). Display schema: Name | Title | Account | Email | View Record.
```

**Prompt Command**
```json
{
  "type": "object",
  "properties": {
    "search_term": {
      "type": "string",
      "description": "The Contact name OR email (or partial) to search for. Examples: 'John Smith', 'john@acme.com', 'Khan'."
    }
  },
  "required": ["search_term"]
}
```

---

### 2.2 — `fetch_contact_details`

**Description**
```
Returns the full detail of a single Contact — FirstName, LastName, Email, Phone, MobilePhone, Title, Department, Account, Owner and MailingAddress. Use this ONLY after you have a confirmed Contact Id.
```

**Prompt Command**
```json
{
  "type": "object",
  "properties": {
    "contact_id": {
      "type": "string",
      "description": "ONLY the Salesforce Id of the Contact whose details should be fetched."
    }
  },
  "required": ["contact_id"]
}
```

---

### 2.3 — `create_contact`

**Description**
```
Creates a new Contact. Use when the user asks to create, add, or register a new Contact. "LastName" is the ONLY required field — pass it as a flat top-level parameter. Pass any other Contact field (FirstName, Email, Phone, MobilePhone, Title, Department, AccountId, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, custom fields) ONLY if the user explicitly provided it; never prompt for optional fields. If the user gives an Account name (instead of an AccountId), pass it via "account_name" — the skill will resolve it to AccountId. If you already have an AccountId, pass it directly as the "AccountId" top-level parameter.
```

**Prompt Command**
```json
{
  "type": "object",
  "properties": {
    "LastName": {
      "type": "string",
      "description": "Required. The Contact's last name. The only mandatory field to create a Contact in Salesforce."
    },
    "FirstName": {
      "type": "string",
      "description": "Optional. The Contact's first name. Only include if the user provided it."
    },
    "Email": {
      "type": "string",
      "description": "Optional. The Contact's email address. Only include if the user provided it."
    },
    "Phone": {
      "type": "string",
      "description": "Optional. The Contact's work phone. Only include if the user provided it."
    },
    "MobilePhone": {
      "type": "string",
      "description": "Optional. The Contact's mobile phone. Only include if the user provided it."
    },
    "Title": {
      "type": "string",
      "description": "Optional. The Contact's job title. Only include if the user provided it."
    },
    "Department": {
      "type": "string",
      "description": "Optional. The Contact's department. Only include if the user provided it."
    },
    "AccountId": {
      "type": "string",
      "description": "Optional. The Salesforce Id of the Account to associate this Contact with. Use this when the user supplies an Id directly; otherwise use account_name."
    },
    "MailingStreet": {
      "type": "string",
      "description": "Optional. Mailing address — street."
    },
    "MailingCity": {
      "type": "string",
      "description": "Optional. Mailing address — city."
    },
    "MailingState": {
      "type": "string",
      "description": "Optional. Mailing address — state/province."
    },
    "MailingPostalCode": {
      "type": "string",
      "description": "Optional. Mailing address — postal/ZIP code."
    },
    "MailingCountry": {
      "type": "string",
      "description": "Optional. Mailing address — country."
    },
    "account_name": {
      "type": "string",
      "description": "Optional. Account name to associate this Contact with. The skill resolves it to the AccountId. Use ONLY when the user has not supplied an AccountId directly."
    }
  },
  "required": ["LastName"]
}
```

---

### 2.4 — `update_contact_fields`

**Description**
```
Updates one or more fields on an existing Contact. Always confirm with the user before invoking. Pass "contact_id" PLUS each Contact field to change as a flat top-level parameter (e.g. { "contact_id": "003…", "Title": "CEO", "Phone": "555-1212" }). Supports Text, Number, Picklist, Dependent Picklist and Boolean fields in a single call.
```

**Prompt Command**
```json
{
  "type": "object",
  "required": ["contact_id"],
  "properties": {
    "contact_id": {
      "type": "string",
      "description": "ONLY the Salesforce Id of the Contact to update."
    },
    "FirstName": { "type": "string", "description": "Optional. New first name." },
    "LastName": { "type": "string", "description": "Optional. New last name." },
    "Email": { "type": "string", "description": "Optional. New email address." },
    "Phone": { "type": "string", "description": "Optional. New work phone." },
    "MobilePhone": { "type": "string", "description": "Optional. New mobile phone." },
    "Title": { "type": "string", "description": "Optional. New job title." },
    "Department": { "type": "string", "description": "Optional. New department." },
    "AccountId": { "type": "string", "description": "Optional. New Salesforce Account Id." }
  },
  "additionalProperties": true
}
```

---

### 2.5 — `log_contact_activity`

**Description**
```
Logs a completed Task on a Contact. Use this when the user wants to log, record, or capture a call, email, meeting note or follow-up activity tied to a Contact. ALWAYS ask for a meaningful subject if not provided — never use placeholders like "New Activity" or "Task".
```

**Prompt Command**
```json
{
  "type": "object",
  "properties": {
    "contact_id": {
      "type": "string",
      "description": "ONLY the Salesforce Id of the Contact the activity should be logged against."
    },
    "activity_subject": {
      "type": "string",
      "description": "A short, meaningful subject for the activity (e.g. 'Discovery call', 'Pricing follow-up'). MUST NOT be a placeholder like 'New Activity'."
    },
    "activity_description": {
      "type": "string",
      "description": "Optional longer-form notes captured against the activity."
    }
  },
  "required": ["contact_id", "activity_subject"]
}
```

---

## 3. LEAD SKILLS (6)

---

### 3.1 — `fuzzy_search_leads`

**Description**
```
Searches Leads by Name, Company, or Email (partial match). Use this when the user asks to find, list or look up Leads.

Fetches ALL matching Leads (capped at 200) ordered by LastModifiedDate DESC and returns the LATEST 5 in `records`. Envelope carries `totalFound`, `displayed`, `remaining` so the agent can append "{remaining} more not shown" when more than 5 Leads match. Per-record fields: Id, Name, Company, Email, Phone, Status, IsConverted, recordUrl, viewRecord (HTML "View Record" anchor). Display schema: Name | Company | Status | Email | View Record.
```

**Prompt Command**
```json
{
  "type": "object",
  "properties": {
    "search_term": {
      "type": "string",
      "description": "Lead name, company name, or email to search for. Examples: 'Jane Doe', 'Acme Industries', 'jane@acme.com'."
    }
  },
  "required": ["search_term"]
}
```

---

### 3.2 — `fetch_lead_details`

**Description**
```
Returns full detail of a single Lead — FirstName, LastName, Company, Title, Email, Phone, Status, LeadSource, Industry, Rating, AnnualRevenue, IsConverted plus the converted Account/Contact/Opportunity Ids if converted.
```

**Prompt Command**
```json
{
  "type": "object",
  "properties": {
    "lead_id": {
      "type": "string",
      "description": "ONLY the Salesforce Id of the Lead whose details should be fetched."
    }
  },
  "required": ["lead_id"]
}
```

---

### 3.3 — `create_lead`

**Description**
```
Creates a new Lead. Use when the user explicitly asks to create or capture a new Lead. Pass each Lead field (LastName, Company, FirstName, Email, Phone, Title, Status, LeadSource, Industry, …) as a flat top-level parameter using the exact Salesforce API name. Both "LastName" AND "Company" are required.
```

**Prompt Command**
```json
{
  "type": "object",
  "required": ["LastName", "Company"],
  "properties": {
    "LastName": { "type": "string", "description": "Required. The Lead's last name." },
    "Company": { "type": "string", "description": "Required. The Lead's company name." },
    "FirstName": { "type": "string", "description": "Optional. The Lead's first name." },
    "Email": { "type": "string", "description": "Optional. The Lead's email address." },
    "Phone": { "type": "string", "description": "Optional. The Lead's phone number." },
    "Title": { "type": "string", "description": "Optional. The Lead's job title." },
    "Status": { "type": "string", "description": "Optional. Lead Status picklist API value." },
    "LeadSource": { "type": "string", "description": "Optional. Lead Source picklist API value." },
    "Industry": { "type": "string", "description": "Optional. Industry picklist API value." },
    "AnnualRevenue": { "type": "number", "description": "Optional. Annual revenue as a plain number." },
    "NumberOfEmployees": { "type": "number", "description": "Optional. Headcount as a plain integer." }
  },
  "additionalProperties": true
}
```

---

### 3.4 — `update_lead_fields`

**Description**
```
Updates one or more fields on an existing Lead. Always confirm before invoking. Pass "lead_id" PLUS each Lead field to change as a flat top-level parameter (e.g. { "lead_id": "00Q…", "Title": "Director", "Status": "Working - Contacted" }). Cannot be used on a Lead that is already converted.
```

**Prompt Command**
```json
{
  "type": "object",
  "required": ["lead_id"],
  "properties": {
    "lead_id": {
      "type": "string",
      "description": "ONLY the Salesforce Id of the Lead to update."
    },
    "FirstName": { "type": "string", "description": "Optional. New first name." },
    "LastName": { "type": "string", "description": "Optional. New last name." },
    "Company": { "type": "string", "description": "Optional. New company name." },
    "Email": { "type": "string", "description": "Optional. New email address." },
    "Phone": { "type": "string", "description": "Optional. New phone number." },
    "Title": { "type": "string", "description": "Optional. New job title." },
    "Status": { "type": "string", "description": "Optional. New Lead Status picklist API value." },
    "LeadSource": { "type": "string", "description": "Optional. New Lead Source picklist API value." },
    "Industry": { "type": "string", "description": "Optional. New Industry picklist API value." }
  },
  "additionalProperties": true
}
```

---

### 3.5 — `convert_lead`

**Description**
```
Converts a Lead into Account + Contact + (optionally) Opportunity. Use ONLY when the user has explicitly asked to convert the lead and confirmed. By default an Opportunity is created — set "do_not_create_opportunity" = true to skip. Provide "account_id" to merge into an existing Account instead of creating a new one. Provide "opportunity_name" to set the Opportunity's Name (otherwise Salesforce uses a default).
```

**Prompt Command**
```json
{
  "type": "object",
  "properties": {
    "lead_id": {
      "type": "string",
      "description": "ONLY the Salesforce Id of the Lead to convert."
    },
    "account_id": {
      "type": "string",
      "description": "Optional. The Salesforce Id of an EXISTING Account to merge the Lead into. If omitted, a new Account is created based on Lead's Company."
    },
    "opportunity_name": {
      "type": "string",
      "description": "Optional. Name for the Opportunity that will be created. Ignored if 'do_not_create_opportunity' is true."
    },
    "do_not_create_opportunity": {
      "type": "boolean",
      "description": "Optional. If true, no Opportunity is created during conversion. Default false."
    }
  },
  "required": ["lead_id"]
}
```

---

### 3.6 — `log_lead_activity`

**Description**
```
Logs a completed Task on a Lead. Use when the user wants to log, record, or capture a call, email, meeting note or follow-up activity tied to a Lead. ALWAYS ask for a meaningful subject if not provided.
```

**Prompt Command**
```json
{
  "type": "object",
  "properties": {
    "lead_id": {
      "type": "string",
      "description": "ONLY the Salesforce Id of the Lead the activity should be logged against."
    },
    "activity_subject": {
      "type": "string",
      "description": "A short, meaningful subject for the activity. MUST NOT be a placeholder."
    },
    "activity_description": {
      "type": "string",
      "description": "Optional longer-form notes captured against the activity."
    }
  },
  "required": ["lead_id", "activity_subject"]
}
```

---

## 4. OPPORTUNITY SKILLS (7)

---

### 4.1 — `fuzzy_search_opportunities`

**Description**
```
Searches Opportunities by Name (partial match). Also accepts a Salesforce Opportunity Id (starts with '006') as the search_term — in which case it returns that exact opportunity and sets matchedVia='id'. Use this whenever you need to find or look up an Opportunity, OR silently fetch current Stage/CloseDate when you already have a record Id from page context.

Fetches ALL matching Opportunities (capped at 200) ordered by LastModifiedDate DESC and returns the LATEST 5 in `records`. Envelope carries `totalFound`, `displayed`, `remaining` so the agent can append "{remaining} more not shown" when more than 5 Opportunities match. Per-record fields: Id, Name, StageName, CloseDate, currentdate__c, Amount, AccountId, OwnerId, recordUrl, viewRecord (HTML "View Record" anchor). Display schema: Name | StageName | CloseDate | Amount | View Record.
```

**Prompt Command**
```json
{
  "type": "object",
  "properties": {
    "search_term": {
      "type": "string",
      "description": "The Opportunity Name (or partial name), OR a 15-/18-character Salesforce Opportunity Id starting with '006'. Examples: 'Acme Big Deal', 'Renewal Q3', '006A0000005Tx9X'."
    }
  },
  "required": ["search_term"]
}
```

---

### 4.2 — `fetch_opportunity_details`

**Description**
```
Returns full detail of a single Opportunity — Name, StageName, Amount, CloseDate, Probability, ForecastCategory, Account, Owner, Description, Type, LeadSource — plus 'currentdate__c' (today's date) for use as a date anchor.
```

**Prompt Command**
```json
{
  "type": "object",
  "properties": {
    "opportunity_id": {
      "type": "string",
      "description": "ONLY the Salesforce Id of the Opportunity whose details should be fetched."
    }
  },
  "required": ["opportunity_id"]
}
```

---

### 4.3 — `create_opportunity`

**Description**
```
Creates a new Opportunity. Use when the user explicitly asks to create or add an Opportunity. Pass each Opportunity field (Name, StageName, CloseDate, Amount, AccountId, Probability, Type, LeadSource, NextStep, Description, Pricebook2Id, …) as a flat top-level parameter using the exact Salesforce API name. "Name", "StageName" and "CloseDate" (yyyy-MM-dd) are required. Resolve any relative date expressions to yyyy-MM-dd BEFORE calling.
```

**Prompt Command**
```json
{
  "type": "object",
  "required": ["Name", "StageName", "CloseDate"],
  "properties": {
    "Name": { "type": "string", "description": "Required. Opportunity Name." },
    "StageName": { "type": "string", "description": "Required. Stage picklist API value." },
    "CloseDate": { "type": "string", "description": "Required. Close date in yyyy-MM-dd format." },
    "AccountId": { "type": "string", "description": "Optional. Salesforce Id of the related Account." },
    "Amount": { "type": "number", "description": "Optional. Amount as a plain number." },
    "Probability": { "type": "number", "description": "Optional. Probability percentage (0-100)." },
    "Type": { "type": "string", "description": "Optional. Opportunity Type picklist API value." },
    "LeadSource": { "type": "string", "description": "Optional. Lead Source picklist API value." },
    "NextStep": { "type": "string", "description": "Optional. Next-step text." },
    "Description": { "type": "string", "description": "Optional. Long-text description." },
    "Pricebook2Id": { "type": "string", "description": "Optional. Id of the Pricebook to associate." }
  },
  "additionalProperties": true
}
```

---

### 4.4 — `update_opportunity_fields`

**Description**
```
Updates one or more fields on an existing Opportunity. Pass "opportunity_id" PLUS each Opportunity field to change as a flat top-level parameter (e.g. { "opportunity_id": "006…", "StageName": "Closed Won", "Amount": 75000 }). Supports Text, Number, Picklist, Dependent Picklist and Boolean fields in a single call. Always confirm with the user (current → new) before invoking. All relative date expressions MUST be resolved to yyyy-MM-dd before being passed.
```

**Prompt Command**
```json
{
  "type": "object",
  "required": ["opportunity_id"],
  "properties": {
    "opportunity_id": {
      "type": "string",
      "description": "ONLY the Salesforce Id of the Opportunity to update."
    },
    "Name": { "type": "string", "description": "Optional. New Opportunity Name." },
    "StageName": { "type": "string", "description": "Optional. New Stage picklist API value." },
    "CloseDate": { "type": "string", "description": "Optional. New close date in yyyy-MM-dd format." },
    "Amount": { "type": "number", "description": "Optional. New amount as a plain number." },
    "Probability": { "type": "number", "description": "Optional. New probability percentage (0-100)." },
    "ForecastCategoryName": { "type": "string", "description": "Optional. New ForecastCategoryName picklist API value." },
    "NextStep": { "type": "string", "description": "Optional. New next-step text." },
    "Description": { "type": "string", "description": "Optional. New long-text description." }
  },
  "additionalProperties": true
}
```

---

### 4.5 — `log_opportunity_activity`

**Description**
```
Logs a completed Task on an Opportunity. Use when the user wants to record a call, email, demo, meeting note, or follow-up tied to an Opportunity. ALWAYS ask for a meaningful subject if not provided.
```

**Prompt Command**
```json
{
  "type": "object",
  "properties": {
    "opportunity_id": {
      "type": "string",
      "description": "ONLY the Salesforce Id of the Opportunity the activity should be logged against."
    },
    "activity_subject": {
      "type": "string",
      "description": "A short, meaningful subject for the activity. MUST NOT be a placeholder."
    },
    "activity_description": {
      "type": "string",
      "description": "Optional longer-form notes captured against the activity."
    }
  },
  "required": ["opportunity_id", "activity_subject"]
}
```

---

### 4.6 — `add_opportunity_line_item`

**Description**
```
Adds a Product (OpportunityLineItem) to an Opportunity. Use when the user asks to add a product, line item or SKU to a deal. EITHER "pricebook_entry_id" OR "product_name" must be supplied — never both. "quantity" and "unit_price" are mandatory.
```

**Prompt Command**
```json
{
  "type": "object",
  "properties": {
    "opportunity_id": {
      "type": "string",
      "description": "ONLY the Salesforce Id of the Opportunity to add the line item to."
    },
    "pricebook_entry_id": {
      "type": "string",
      "description": "Optional. The Salesforce Id of the PricebookEntry to add. Use this if you already know the PricebookEntry Id."
    },
    "product_name": {
      "type": "string",
      "description": "Optional. Name of the Product. The skill will resolve it to an active PricebookEntry on the Opportunity's Pricebook. Use this when the user gave a product name instead of a PricebookEntry Id."
    },
    "quantity": {
      "type": "number",
      "description": "Quantity of the product (must be > 0)."
    },
    "unit_price": {
      "type": "number",
      "description": "Unit price for the line item."
    }
  },
  "required": ["opportunity_id", "quantity", "unit_price"]
}
```

---

### 4.7 — `fetch_opportunity_recent_changes`

**Description**
```
Returns the field-history audit for an Opportunity over the last N days. Use when the user asks "what changed", "recent changes", "audit history", or wants to investigate edits to an Opportunity. Requires Field History Tracking to be enabled on the Opportunity object.
```

**Prompt Command**
```json
{
  "type": "object",
  "properties": {
    "opportunity_id": {
      "type": "string",
      "description": "ONLY the Salesforce Id of the Opportunity whose recent changes should be fetched."
    },
    "days": {
      "type": "integer",
      "description": "Optional. Lookback window in days (1-365). Defaults to 30."
    }
  },
  "required": ["opportunity_id"]
}
```

---

## 5. CASE SKILLS (5)

---

### 5.1 — `fuzzy_search_cases`

**Description**
```
Searches Cases by CaseNumber or Subject (partial match). Use when the user wants to find, look up or list Cases.

Fetches ALL matching Cases (capped at 200) ordered by LastModifiedDate DESC and returns the LATEST 5 in `records`. Envelope carries `totalFound`, `displayed`, `remaining` so the agent can append "{remaining} more not shown" when more than 5 Cases match. Per-record fields: Id, CaseNumber, Subject, Status, Priority, AccountId, recordUrl, viewRecord (HTML "View Record" anchor). Display schema: CaseNumber | Subject | Status | Priority | View Record.
```

**Prompt Command**
```json
{
  "type": "object",
  "properties": {
    "search_term": {
      "type": "string",
      "description": "CaseNumber (e.g. '00001234') or part of the Case Subject. Examples: 'login', '00001234', 'crash'."
    }
  },
  "required": ["search_term"]
}
```

---

### 5.2 — `fetch_case_details`

**Description**
```
Returns the full detail of a single Case — Subject, Description, Status, Priority, Type, Origin, Reason, Account, Contact, IsClosed. Accepts EITHER a Salesforce Case Id OR a CaseNumber as input.
```

**Prompt Command**
```json
{
  "type": "object",
  "properties": {
    "case_id": {
      "type": "string",
      "description": "Either the Salesforce Id of the Case (starts with '500') OR the human-readable CaseNumber (e.g. '00001234')."
    }
  },
  "required": ["case_id"]
}
```

---

### 5.3 — `create_case`

**Description**
```
Creates a new Case. Use when the user explicitly asks to open, create, log or raise a Case. Pass each Case field (Subject, Description, Status, Priority, Type, Origin, Reason, AccountId, ContactId, OwnerId, …) as a flat top-level parameter using the exact Salesforce API name. "Subject" is required.
```

**Prompt Command**
```json
{
  "type": "object",
  "required": ["Subject"],
  "properties": {
    "Subject": { "type": "string", "description": "Required. Short summary of the Case." },
    "Description": { "type": "string", "description": "Optional. Long-text description of the Case." },
    "Status": { "type": "string", "description": "Optional. Status picklist API value." },
    "Priority": { "type": "string", "description": "Optional. Priority picklist API value." },
    "Type": { "type": "string", "description": "Optional. Type picklist API value." },
    "Origin": { "type": "string", "description": "Optional. Origin picklist API value." },
    "Reason": { "type": "string", "description": "Optional. Reason picklist API value." },
    "AccountId": { "type": "string", "description": "Optional. Salesforce Id of the related Account." },
    "ContactId": { "type": "string", "description": "Optional. Salesforce Id of the related Contact." },
    "OwnerId": { "type": "string", "description": "Optional. Salesforce Id of the Case owner (User or Queue)." }
  },
  "additionalProperties": true
}
```

---

### 5.4 — `update_case_fields`

**Description**
```
Updates one or more fields on an existing Case. Always confirm with the user before invoking. Pass "case_id" PLUS each Case field to change as a flat top-level parameter (e.g. { "case_id": "500…", "Status": "Working", "Priority": "Low" }).
```

**Prompt Command**
```json
{
  "type": "object",
  "required": ["case_id"],
  "properties": {
    "case_id": {
      "type": "string",
      "description": "ONLY the Salesforce Id of the Case to update."
    },
    "Subject": { "type": "string", "description": "Optional. New subject." },
    "Description": { "type": "string", "description": "Optional. New long-text description." },
    "Status": { "type": "string", "description": "Optional. New Status picklist API value." },
    "Priority": { "type": "string", "description": "Optional. New Priority picklist API value." },
    "Type": { "type": "string", "description": "Optional. New Type picklist API value." },
    "Origin": { "type": "string", "description": "Optional. New Origin picklist API value." },
    "Reason": { "type": "string", "description": "Optional. New Reason picklist API value." },
    "OwnerId": { "type": "string", "description": "Optional. New owner Id (User or Queue)." }
  },
  "additionalProperties": true
}
```

---

### 5.5 — `close_case`

**Description**
```
Closes a Case (sets Status = 'Closed'). Optionally accepts a reason and a public comment that is added to the Case. Use ONLY when the user has explicitly asked to close, resolve, or mark a Case as Closed. Cannot be used on an already-closed Case.
```

**Prompt Command**
```json
{
  "type": "object",
  "properties": {
    "case_id": {
      "type": "string",
      "description": "ONLY the Salesforce Id of the Case to close."
    },
    "reason": {
      "type": "string",
      "description": "Optional. Closure reason — must be a valid Case Reason picklist value. Examples: 'User error', 'Other', 'Instructions not clear'."
    },
    "comments": {
      "type": "string",
      "description": "Optional. Public comment to add to the Case at closure."
    }
  },
  "required": ["case_id"]
}
```

---

## 6. ACTIVITY SKILLS (4)

---

### 6.1 — `create_task`

**Description**
```
Creates a Task on any record. Use when the user asks to create a task or to-do tied to ANY record (Account, Contact, Opportunity, Lead, Case, custom object). Pass each Task field (Subject, Status, Priority, ActivityDate, WhatId, WhoId, Description, OwnerId, …) as a flat top-level parameter using the exact Salesforce API name. "Subject" is required. Use "WhatId" for non-people records (Account, Opportunity, Case, custom object) and "WhoId" for people (Contact, Lead).
```

**Prompt Command**
```json
{
  "type": "object",
  "required": ["Subject"],
  "properties": {
    "Subject": { "type": "string", "description": "Required. Short subject of the Task." },
    "Description": { "type": "string", "description": "Optional. Long-text description / comments." },
    "Status": { "type": "string", "description": "Optional. Status picklist API value." },
    "Priority": { "type": "string", "description": "Optional. Priority picklist API value." },
    "ActivityDate": { "type": "string", "description": "Optional. Due date in yyyy-MM-dd format." },
    "WhatId": { "type": "string", "description": "Optional. Salesforce Id of the related Account / Opportunity / Case (NOT a Contact or Lead)." },
    "WhoId": { "type": "string", "description": "Optional. Salesforce Id of the related Contact or Lead." },
    "OwnerId": { "type": "string", "description": "Optional. Salesforce Id of the Task owner (User or Queue)." }
  },
  "additionalProperties": true
}
```

---

### 6.2 — `create_event`

**Description**
```
Creates an Event (calendar entry) on any record. Use when the user asks to schedule a meeting, demo, call or appointment. Pass each Event field (Subject, StartDateTime, EndDateTime, DurationInMinutes, Description, Location, WhatId, WhoId, IsAllDayEvent, …) as a flat top-level parameter using the exact Salesforce API name. "Subject" AND "StartDateTime" are required. If neither EndDateTime nor DurationInMinutes is provided, the skill defaults DurationInMinutes to 30.
```

**Prompt Command**
```json
{
  "type": "object",
  "required": ["Subject", "StartDateTime"],
  "properties": {
    "Subject": { "type": "string", "description": "Required. Short subject of the Event." },
    "StartDateTime": { "type": "string", "description": "Required. Event start in ISO 8601 (e.g. '2026-05-31T14:30:00Z')." },
    "EndDateTime": { "type": "string", "description": "Optional. Event end in ISO 8601. Provide either EndDateTime or DurationInMinutes (DurationInMinutes defaults to 30 when both are omitted)." },
    "DurationInMinutes": { "type": "number", "description": "Optional. Event length in minutes. Provide either EndDateTime or DurationInMinutes (defaults to 30 when both are omitted)." },
    "Description": { "type": "string", "description": "Optional. Long-text description / agenda." },
    "Location": { "type": "string", "description": "Optional. Event location." },
    "WhatId": { "type": "string", "description": "Optional. Salesforce Id of the related Account / Opportunity / Case (NOT a Contact or Lead)." },
    "WhoId": { "type": "string", "description": "Optional. Salesforce Id of the related Contact or Lead." },
    "IsAllDayEvent": { "type": "boolean", "description": "Optional. true when the Event spans the entire day." }
  },
  "additionalProperties": true
}
```

---

### 6.3 — `fetch_my_open_tasks`

**Description**
```
Returns the running user's open Tasks (IsClosed = false), sorted by ActivityDate ascending. Use when the user asks "what's on my plate", "show my open tasks", "my to-dos", or similar.
```

**Prompt Command**
```json
{
  "type": "object",
  "properties": {
    "limit": {
      "type": "integer",
      "description": "Optional. Maximum number of tasks to return (1-200). Defaults to 25."
    }
  },
  "required": []
}
```

---

### 6.4 — `complete_task`

**Description**
```
Marks a Task as Status = 'Completed'. Use when the user explicitly asks to mark a task as done, complete, or finished.
```

**Prompt Command**
```json
{
  "type": "object",
  "properties": {
    "task_id": {
      "type": "string",
      "description": "ONLY the Salesforce Id of the Task to mark Completed."
    }
  },
  "required": ["task_id"]
}
```

---

## 7. UTILITY SKILLS (5) — object-agnostic

---

### 7.1 — `bulk_update_records`

**Description**
```
Generic bulk multi-record / multi-field / multi-type update for ANY standard or custom Salesforce object. Use when the user asks to update multiple records of the SAME object in a single action. Each row in 'records' must contain 'Id' plus the fields to update. Continues on per-row errors and returns counts of succeeded / failed / skipped. Always show the user a summary of what will change BEFORE invoking.
```

**Prompt Command**
```json
{
  "type": "object",
  "properties": {
    "object_api_name": {
      "type": "string",
      "description": "API name of the Salesforce object the records belong to. Examples: 'Account', 'Opportunity', 'Custom_Object__c'. ALL records in 'records' must belong to this object."
    },
    "records": {
      "type": "array",
      "description": "List of record-update objects. Each MUST contain 'Id' plus any updateable fields with their new values.",
      "items": {
        "type": "object",
        "properties": {
          "Id": { "type": "string", "description": "Salesforce record Id of the row to update." }
        },
        "required": ["Id"],
        "additionalProperties": true
      }
    }
  },
  "required": ["object_api_name", "records"]
}
```

---

### 7.2 — `fetch_record_history`

**Description**
```
Returns field-history audit for any record on any object that has Field History Tracking enabled. Works for both standard objects (e.g. Account → AccountHistory) and custom objects (e.g. Project__c → Project__History). Use when the user asks for change history, audit trail or "what changed" on any record.
```

**Prompt Command**
```json
{
  "type": "object",
  "properties": {
    "record_id": {
      "type": "string",
      "description": "ONLY the Salesforce Id of the record whose change history should be fetched."
    },
    "object_api_name": {
      "type": "string",
      "description": "API name of the record's object. Examples: 'Account', 'Opportunity', 'Custom_Object__c'."
    },
    "days": {
      "type": "integer",
      "description": "Optional. Lookback window in days (1-365). Defaults to 30."
    }
  },
  "required": ["record_id", "object_api_name"]
}
```

---

### 7.3 — `fetch_user_info`

**Description**
```
Returns the running user's information — Name, Username, Email, Profile, Role, TimeZone, Locale, Language and 'currentdate__c' (today's date). Use as a date anchor for relative-date resolution and to personalise responses. Takes no parameters.
```

**Prompt Command**
```json
{
  "type": "object",
  "properties": {},
  "required": []
}
```

---

### 7.4 — `run_internal_prompt`

**Description**
```
Invokes an internal GPTfy AI Prompt against a specific record and returns the LLM-generated narrative. This is the "Mixed Operation" skill — combines record context (DML) with an internal prompt to generate prose answers (deal overview, stakeholder map, meeting prep, executive summary, etc.). Use whenever the user asks an open-ended question against a specific record that is best answered by a configured GPTfy Prompt Request. The prompt_request_id MUST be a pre-configured GPTfy Prompt Request Id that exists in the org — never invent it.
```

**Prompt Command**
```json
{
  "type": "object",
  "properties": {
    "prompt_request_id": {
      "type": "string",
      "description": "The pre-configured GPTfy Prompt Request Id to invoke. Example: '96a10206d7990a5fabc728ddfd83be0fbd5a9'. Must exist in the org configuration — never make this up."
    },
    "record_id": {
      "type": "string",
      "description": "ONLY the Salesforce Id of the record the prompt should run against (e.g. an Opportunity Id for a Deal Overview prompt)."
    }
  },
  "required": ["prompt_request_id", "record_id"]
}
```

---

### 7.5 — `fetch_picklist_values`

**Description**
```
Returns the valid picklist (or multi-picklist) values for a field on any object. Supports DEPENDENT picklists — when 'controller_value' is supplied, only the values valid for that controller value are returned. Call this skill SILENTLY before any update_*_fields or create_* skill whenever you are unsure whether a picklist value the user gave is valid.
```

**Prompt Command**
```json
{
  "type": "object",
  "properties": {
    "object_api_name": {
      "type": "string",
      "description": "API name of the object the field lives on. Examples: 'Account', 'Opportunity', 'Custom_Object__c'."
    },
    "field_api_name": {
      "type": "string",
      "description": "API name of the picklist or multi-picklist field. Examples: 'Industry', 'StageName', 'Type__c'."
    },
    "controller_value": {
      "type": "string",
      "description": "Required ONLY for dependent picklists. The exact API value of the controlling field that the record will have AFTER the update. The skill returns only the dependent values valid for this controller value."
    }
  },
  "required": ["object_api_name", "field_api_name"]
}
```

---

## Quick Verification Checklist

After creating all 37 `AI_Prompt__c` records:

- [ ] Each prompt's `Name` exactly matches a `when` branch in `GenericAgenticSkillsHandler.executeMethod` (case-sensitive, snake_case)
- [ ] Each prompt has `Type__c = Agentic` and `Status__c = Active`
- [ ] Each prompt has `Agentic_Function_Class__c = GenericAgenticSkillsHandler`
- [ ] Each prompt has its `Description__c` populated (the LLM uses this to choose skills)
- [ ] Each prompt has its `Prompt_Command__c` populated with the JSON schema above (must be valid JSON — copy-paste exactly)
- [ ] All 37 prompts are linked to the parent `AI_Agent__c` record via `AI_Agent_Skill__c` junctions
- [ ] (Optional) `Profiles__c` / `Permission_Sets__c` filled where you want to restrict access
- [ ] The agent's `System_Prompt__c` is populated with the contents of `GenericCRMAssistant_SystemPrompt.txt`

Once these are in place, the agent will dispatch user requests to the correct skill automatically.
