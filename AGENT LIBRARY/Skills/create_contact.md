# Skill: `create_contact`

**Sources:** `Deliverables/force-app/main/default/classes/GenericAgenticSkillsHandler.cls`, `Deliverables/docs/GenericCRMAssistant_SystemPrompt.txt` (v1.3.1), `Deliverables/docs/GPTfy_Agent_Prompt_Commands.md`.

## Apex Code Snippet

```apex
when 'create_contact'               { return handleCreateContact(parameters); }

    /**
     * @description Skill 9 — create_contact. Accepts Contact field API names as flat
     *              top-level parameters (e.g. LastName, FirstName, Email, Phone, AccountId,
     *              MailingCity, …). The reserved key 'account_name' is resolved to AccountId
     *              when supplied and AccountId is not already set. The legacy nested
     *              { "fields": { … } } shape is still accepted for backward compatibility.
     * @jira V2-8418
     */
    private String handleCreateContact(Map<String, Object> p) {
        if (p == null || p.isEmpty()) {
            return errorHtml('Could not create contact', 'Missing required parameters.');
        }
        if (!Schema.sObjectType.Contact.isCreateable()) {
            return errorHtml('Could not create contact', 'Contact is not creatable.');
        }
        Set<String> reservedKeys = new Set<String>{ 'account_name' };
        Map<String, Object> applyFields = new Map<String, Object>();
        Object legacyFields = p.get('fields');
        if (legacyFields instanceof Map<String, Object>) {
            applyFields.putAll((Map<String, Object>) legacyFields);
            reservedKeys.add('fields');
        }
        for (String k : p.keySet()) {
            if (reservedKeys.contains(k)) continue;
            applyFields.put(k, p.get(k));
        }
        if (!applyFields.containsKey('LastName') || String.isBlank(toText(applyFields.get('LastName')))) {
            return errorHtml('Could not create contact', 'LastName is required.');
        }
        String accName = toText(p.get('account_name'));
        if (!applyFields.containsKey('AccountId') && String.isNotBlank(accName)) {
            List<Account> accs = [SELECT Id FROM Account WHERE Name = :accName WITH USER_MODE LIMIT 1];
            if (accs.isEmpty()) return errorHtml('Could not create contact', 'Account "' + accName + '" not found.');
            applyFields.put('AccountId', accs[0].Id);
        }
        try {
            Contact c = new Contact();
            applyFieldsToSObject(c, applyFields, false);
            insert c;
            String body = '<ul><li><b>Name:</b> ' + escapeHtml((String) applyFields.get('LastName')) + '</li></ul>';
            return successHtml('Contact Created', body, c.Id, 'View Contact');
        } catch (Exception ex) {
            return errorHtml('Could not create contact', ex.getMessage());
        }
    }
```

## Agent Behavior & Workflow

SALESFORCE CONTACT CREATION — AGENT BEHAVIOR & WORKFLOW

REQUIRED FIELD:
- Last Name is the only required field to create a contact in Salesforce
- All other fields (email, phone, account, title, etc.) are optional and should only be populated if the user provides them

STEP 1 — PARSE THE REQUEST
- Extract all fields the user has already mentioned in their request
- Never ask for a field the user has already provided

STEP 2 — RESOLVE THE NAME AMBIGUITY
- If both first and last name are clearly provided → skip to Step 3
- If only one name is given and it's unclear whether it's a first or last name, ask exactly one question:
  "Just to confirm — is [Name] the first name or last name? Or does this person go by just one name?"

  Based on the user's reply, act as follows:
  - "That's the first name" → Ask for the last name, then proceed to create
  - "That's the last name" → Use it as Last Name and proceed to create
  - "It's their only name / full name" → Set it as Last Name (Salesforce standard for single names) and proceed to create
  - "First name Jeevan, last name Kumar" → Populate both fields and proceed to create

STEP 3 — DO NOT ASK FOR OPTIONAL FIELDS
- Once Last Name is confirmed, proceed directly — do not prompt for email, phone, account, or any other optional field
- Only include fields the user has already provided

STEP 4 — CONFIRM BEFORE CREATING
- Show a summary of what will be created and ask for confirmation:
  "Here's what I'll create:
   - First Name: [if provided]
   - Last Name: [value]
   - [Any other provided fields]
   Shall I go ahead?"
- If only Last Name is available with no other fields, skip confirmation and create directly

STEP 5 — CREATE THE CONTACT
- Call the Salesforce API with the confirmed fields and create the contact

STEP 6 — CONFIRM SUCCESS
- Respond with: "Contact created: [Full Name] (ID: [Salesforce Record ID])"

EDGE CASES:
- Duplicate contact detected → Warn before creating: "A contact with this name already exists. Do you still want to create a new one?"
- Account name matches multiple records → List the options and ask the user which one to link
- Invalid field format (e.g. bad email) → Flag it: "That email doesn't look valid. Would you like to correct it or skip it?"

GOLDEN RULES:
- Ask as little as possible — use everything the user already gave you
- Never ask for optional fields unless the user explicitly expects them
- The only blocker to creation is a missing or ambiguous Last Name
- Always ask ONE question at a time
- Never create a contact without a confirmed Last Name

## JSON Prompt Command

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
  "required": [
    "LastName"
  ]
}
```
