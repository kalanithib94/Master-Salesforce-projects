# Credit Line Agentic Handler

## Overview

The **Credit Line Agentic Handler** is a Salesforce Apex class that implements the `AIAgenticInterface` to power an AI-driven Credit Line Assistant. This solution enables customers to interact with an AI agent for credit card-related services including account lookups, credit limit inquiries, case creation for service requests, lost card reporting, and account closures.

---

## Table of Contents

1. [Architecture](#architecture)
2. [Supported Methods](#supported-methods)
3. [API Specifications](#api-specifications)
4. [Contact Fields](#contact-fields)
5. [Response Structure](#response-structure)
6. [Error Handling](#error-handling)
7. [Security & Guardrails](#security--guardrails)
8. [Sample Conversations](#sample-conversations)
9. [Deployment Guide](#deployment-guide)

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        AI Agent (GPTfy)                         │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    AIAgenticInterface                           │
│              executeMethod(methodName, parameters)              │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                 CreditLineAgenticHandler                        │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Contact Search        │  Case Creation                   │  │
│  │  • find_contact_by_name│  • create_case_for_contact       │  │
│  │  • find_contact_by_id  │  • create_credit_increase_case   │  │
│  │                        │  • create_lost_card_case         │  │
│  │                        │  • create_account_closure_case   │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Salesforce Database                          │
│                   Contact | Case | Account                      │
└─────────────────────────────────────────────────────────────────┘
```

---

## Supported Methods

| Method | Description | Required Parameters |
|--------|-------------|---------------------|
| `find_contact_by_name` | Search contacts by first or last name | `name` |
| `find_contact_details_by_id` | Get contact details by Salesforce ID | `Id` |
| `create_case_for_contact` | Create a general case | `ContactId`, `Subject` |
| `create_credit_increase_case` | Request credit limit increase | `ContactId` |
| `create_lost_card_case` | Report lost/stolen card (HIGH PRIORITY) | `ContactId` |
| `create_account_closure_case` | Request account closure | `ContactId` |

---

## API Specifications

### 1. find_contact_by_name

**Purpose:** Search for contacts by first name or last name using fuzzy matching.

**API Specification:**
```json
{
  "type": "object",
  "properties": {
    "name": {
      "type": "string",
      "description": "The first name or last name of the contact to search for (minimum 2 characters)"
    }
  },
  "required": ["name"]
}
```

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `success` | Boolean | Whether the operation succeeded |
| `found` | Boolean | Whether any contacts were found |
| `multipleMatches` | Boolean | True if more than one contact found |
| `count` | Integer | Number of contacts found |
| `message` | String | Human-readable result message |
| `contact` | Object | Contact record (single match only) |
| `contacts` | Array | List of contacts (multiple matches) |
| `ContactId` | String | Salesforce Contact ID (single match only) |
| `ContactName` | String | Full name of contact |
| `ContactUrl` | String | Direct URL to Contact record in Salesforce |
| `instruction` | String | Agent behavior instruction |

**Instructions Returned:**
- `INFORM_USER_NO_RECORD_FOUND` - No contacts found
- `ASK_USER_TO_VERIFY_IDENTITY` - Multiple contacts found, verification needed
- `PROCEED_WITH_CONTACT` - Single contact found, ready to proceed

**Example Request:**
```json
{
  "name": "Emily"
}
```

**Example Response (Single Match):**
```json
{
  "success": true,
  "found": true,
  "multipleMatches": false,
  "count": 1,
  "message": "Found contact: Emily Reed",
  "contact": {
    "Id": "003J900000G00dSIAR",
    "FirstName": "Emily",
    "LastName": "Reed",
    "Email": "emily.reed@example.com",
    "Phone": "555-123-4567",
    "Current_Credit_limit__c": 5000,
    "Current_balance__c": 1250,
    "Payment_History__c": "On-time",
    "ContactStatus__c": "Active",
    "Credit_lines__c": 2
  },
  "ContactId": "003J900000G00dSIAR",
  "ContactName": "Emily Reed",
  "ContactUrl": "https://yourorg.my.salesforce.com/003J900000G00dSIAR",
  "instruction": "PROCEED_WITH_CONTACT"
}
```

**Example Response (Multiple Matches):**
```json
{
  "success": true,
  "found": true,
  "multipleMatches": true,
  "count": 3,
  "message": "Found 3 contacts matching: John. Please verify identity.",
  "contacts": [
    {
      "Id": "003J900000G00dSIAR",
      "FirstName": "John",
      "LastName": "Smith",
      "Email": "j***@example.com",
      "Phone": "***-***-4567",
      "ContactUrl": "https://yourorg.my.salesforce.com/003J900000G00dSIAR"
    },
    {
      "Id": "003J900000G00dSIAT",
      "FirstName": "John",
      "LastName": "Doe",
      "Email": "j***@company.com",
      "Phone": "***-***-8901",
      "ContactUrl": "https://yourorg.my.salesforce.com/003J900000G00dSIAT"
    }
  ],
  "ContactId": null,
  "ContactUrl": null,
  "instruction": "ASK_USER_TO_VERIFY_IDENTITY"
}
```

---

### 2. find_contact_details_by_id

**Purpose:** Retrieve detailed contact information using a Salesforce Contact ID.

**API Specification:**
```json
{
  "type": "object",
  "properties": {
    "Id": {
      "type": "string",
      "description": "The Salesforce Contact ID (15 or 18 characters)"
    }
  },
  "required": ["Id"]
}
```

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `success` | Boolean | Whether the operation succeeded |
| `found` | Boolean | Whether the contact was found |
| `count` | Integer | Number of contacts found (0 or 1) |
| `message` | String | Human-readable result message |
| `contact` | Object | Full contact record with all fields |
| `ContactId` | String | Salesforce Contact ID |
| `ContactName` | String | Full name of contact |
| `ContactUrl` | String | Direct URL to Contact record |
| `instruction` | String | Agent behavior instruction |

**Instructions Returned:**
- `INFORM_USER_NO_RECORD_FOUND` - Contact not found
- `DISPLAY_CONTACT_DETAILS` - Contact found, display to user

**Example Request:**
```json
{
  "Id": "003J900000G00dSIAR"
}
```

**Example Response:**
```json
{
  "success": true,
  "found": true,
  "count": 1,
  "message": "Found contact: Emily Reed",
  "contact": {
    "Id": "003J900000G00dSIAR",
    "FirstName": "Emily",
    "LastName": "Reed",
    "Phone": "555-123-4567",
    "MobilePhone": "555-987-6543",
    "Email": "emily.reed@example.com",
    "Annual_Income__c": 85000,
    "Current_Credit_limit__c": 5000,
    "Current_balance__c": 1250,
    "Payment_History__c": "On-time",
    "ContactStatus__c": "Active",
    "Credit_lines__c": 2
  },
  "ContactId": "003J900000G00dSIAR",
  "ContactName": "Emily Reed",
  "ContactUrl": "https://yourorg.my.salesforce.com/003J900000G00dSIAR",
  "instruction": "DISPLAY_CONTACT_DETAILS"
}
```

---

### 3. create_case_for_contact

**Purpose:** Create a general-purpose case for a contact with flexible parameters.

**API Specification:**
```json
{
  "type": "object",
  "properties": {
    "ContactId": {
      "type": "string",
      "description": "The Salesforce ID of the Contact (required)"
    },
    "Subject": {
      "type": "string",
      "description": "Subject line for the case (required)"
    },
    "Description": {
      "type": "string",
      "description": "Detailed description of the case"
    },
    "Status": {
      "type": "string",
      "description": "Case status (default: New)"
    },
    "Priority": {
      "type": "string",
      "description": "Case priority: Low, Medium, High (default: Medium)"
    },
    "Origin": {
      "type": "string",
      "description": "Case origin (default: Chat)"
    },
    "Type": {
      "type": "string",
      "description": "Case type"
    },
    "Reason": {
      "type": "string",
      "description": "Case reason"
    }
  },
  "required": ["ContactId", "Subject"]
}
```

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `success` | Boolean | Whether the case was created |
| `created` | Boolean | Confirmation of case creation |
| `message` | String | Human-readable result message |
| `CaseId` | String | Salesforce Case ID |
| `CaseNumber` | String | Auto-generated Case Number |
| `CaseUrl` | String | Direct URL to Case record |
| `Subject` | String | Case subject |
| `ContactId` | String | Linked Contact ID |
| `ContactName` | String | Contact full name |
| `ContactUrl` | String | Direct URL to Contact record |
| `AccountId` | String | Linked Account ID (if available) |
| `Status` | String | Case status |
| `Priority` | String | Case priority |
| `instruction` | String | Agent behavior instruction |

**Example Request:**
```json
{
  "ContactId": "003J900000G00dSIAR",
  "Subject": "General Inquiry",
  "Description": "Customer has a question about their account",
  "Priority": "Low"
}
```

**Example Response:**
```json
{
  "success": true,
  "created": true,
  "message": "Case created successfully for Emily Reed",
  "CaseId": "500J9000001B77LIAT",
  "CaseNumber": "00001570",
  "CaseUrl": "https://yourorg.my.salesforce.com/500J9000001B77LIAT",
  "Subject": "General Inquiry",
  "ContactId": "003J900000G00dSIAR",
  "ContactName": "Emily Reed",
  "ContactUrl": "https://yourorg.my.salesforce.com/003J900000G00dSIAR",
  "AccountId": null,
  "Status": "New",
  "Priority": "Low",
  "instruction": "DISPLAY_CASE_NUMBER_AND_LINK_TO_USER"
}
```

---

### 4. create_credit_increase_case

**Purpose:** Create a case for credit line increase requests.

**API Specification:**
```json
{
  "type": "object",
  "properties": {
    "ContactId": {
      "type": "string",
      "description": "The Salesforce ID of the Contact requesting credit increase (required)"
    },
    "RequestedAmount": {
      "type": "string",
      "description": "The new credit limit amount being requested (e.g., $10,000)"
    },
    "Reason": {
      "type": "string",
      "description": "Reason for requesting the credit line increase"
    }
  },
  "required": ["ContactId"]
}
```

**Case Details Created:**
- **Subject:** `Credit Line Increase Request - {Contact Name}`
- **Priority:** Medium
- **Type:** Service Request
- **Origin:** Chat
- **Status:** New

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `success` | Boolean | Whether the case was created |
| `created` | Boolean | Confirmation of case creation |
| `message` | String | Human-readable result message |
| `CaseId` | String | Salesforce Case ID |
| `CaseNumber` | String | Auto-generated Case Number |
| `CaseUrl` | String | Direct URL to Case record |
| `Subject` | String | Case subject |
| `ContactId` | String | Linked Contact ID |
| `ContactName` | String | Contact full name |
| `ContactUrl` | String | Direct URL to Contact record |
| `AccountId` | String | Linked Account ID (if available) |
| `CurrentCreditLimit` | Number | Contact's current credit limit |
| `RequestedAmount` | String | Amount requested by customer |
| `Status` | String | Case status |
| `Priority` | String | Case priority |
| `instruction` | String | Agent behavior instruction |

**Example Request:**
```json
{
  "ContactId": "003J900000G00dSIAR",
  "RequestedAmount": "$15,000",
  "Reason": "Business expansion needs"
}
```

**Example Response:**
```json
{
  "success": true,
  "created": true,
  "message": "Credit Line Increase case created for Emily Reed",
  "CaseId": "500J9000001B77LIAT",
  "CaseNumber": "00001571",
  "CaseUrl": "https://yourorg.my.salesforce.com/500J9000001B77LIAT",
  "Subject": "Credit Line Increase Request - Emily Reed",
  "ContactId": "003J900000G00dSIAR",
  "ContactName": "Emily Reed",
  "ContactUrl": "https://yourorg.my.salesforce.com/003J900000G00dSIAR",
  "AccountId": null,
  "CurrentCreditLimit": 5000,
  "RequestedAmount": "$15,000",
  "Status": "New",
  "Priority": "Medium",
  "instruction": "DISPLAY_CASE_NUMBER_AND_LINK_TO_USER"
}
```

---

### 5. create_lost_card_case

**Purpose:** Create an urgent case for lost or stolen credit card reports.

**API Specification:**
```json
{
  "type": "object",
  "properties": {
    "ContactId": {
      "type": "string",
      "description": "The Salesforce ID of the Contact reporting lost/stolen card (required)"
    },
    "LastUsedDate": {
      "type": "string",
      "description": "Date when the card was last used (e.g., 2025-11-27)"
    },
    "LastUsedLocation": {
      "type": "string",
      "description": "Location where the card was last used"
    },
    "AdditionalNotes": {
      "type": "string",
      "description": "Any additional information about the lost/stolen card"
    }
  },
  "required": ["ContactId"]
}
```

**Case Details Created:**
- **Subject:** `URGENT: Lost/Stolen Credit Card - {Contact Name}`
- **Priority:** High ⚠️
- **Type:** Problem
- **Origin:** Chat
- **Status:** New

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `success` | Boolean | Whether the case was created |
| `created` | Boolean | Confirmation of case creation |
| `message` | String | Human-readable result message (includes urgency) |
| `CaseId` | String | Salesforce Case ID |
| `CaseNumber` | String | Auto-generated Case Number |
| `CaseUrl` | String | Direct URL to Case record |
| `Subject` | String | Case subject (includes URGENT prefix) |
| `ContactId` | String | Linked Contact ID |
| `ContactName` | String | Contact full name |
| `ContactUrl` | String | Direct URL to Contact record |
| `AccountId` | String | Linked Account ID (if available) |
| `Status` | String | Case status |
| `Priority` | String | Case priority (always High) |
| `instruction` | String | Agent behavior instruction |

**Example Request:**
```json
{
  "ContactId": "003J900000G00dSIAR",
  "LastUsedDate": "2025-11-27",
  "LastUsedLocation": "Downtown Mall",
  "AdditionalNotes": "Card may have been pickpocketed"
}
```

**Example Response:**
```json
{
  "success": true,
  "created": true,
  "message": "URGENT: Lost Card case created for Emily Reed. Card will be blocked immediately.",
  "CaseId": "500J9000001B77LIAT",
  "CaseNumber": "00001572",
  "CaseUrl": "https://yourorg.my.salesforce.com/500J9000001B77LIAT",
  "Subject": "URGENT: Lost/Stolen Credit Card - Emily Reed",
  "ContactId": "003J900000G00dSIAR",
  "ContactName": "Emily Reed",
  "ContactUrl": "https://yourorg.my.salesforce.com/003J900000G00dSIAR",
  "AccountId": null,
  "Status": "New",
  "Priority": "High",
  "instruction": "DISPLAY_CASE_NUMBER_AND_LINK_TO_USER_URGENT"
}
```

---

### 6. create_account_closure_case

**Purpose:** Create a case for account closure requests.

**API Specification:**
```json
{
  "type": "object",
  "properties": {
    "ContactId": {
      "type": "string",
      "description": "The Salesforce ID of the Contact requesting account closure (required)"
    },
    "Reason": {
      "type": "string",
      "description": "Reason for requesting account closure"
    },
    "AdditionalNotes": {
      "type": "string",
      "description": "Any additional information about the closure request"
    }
  },
  "required": ["ContactId"]
}
```

**Case Details Created:**
- **Subject:** `Account Closure Request - {Contact Name}`
- **Priority:** Medium
- **Type:** Service Request
- **Origin:** Chat
- **Status:** New

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `success` | Boolean | Whether the case was created |
| `created` | Boolean | Confirmation of case creation |
| `message` | String | Human-readable result message |
| `CaseId` | String | Salesforce Case ID |
| `CaseNumber` | String | Auto-generated Case Number |
| `CaseUrl` | String | Direct URL to Case record |
| `Subject` | String | Case subject |
| `ContactId` | String | Linked Contact ID |
| `ContactName` | String | Contact full name |
| `ContactUrl` | String | Direct URL to Contact record |
| `AccountId` | String | Linked Account ID (if available) |
| `CurrentBalance` | Number | Contact's current outstanding balance |
| `Status` | String | Case status |
| `Priority` | String | Case priority |
| `instruction` | String | Agent behavior instruction |

**Example Request:**
```json
{
  "ContactId": "003J900000G00dSIAR",
  "Reason": "Moving abroad",
  "AdditionalNotes": "Please process within 30 days"
}
```

**Example Response:**
```json
{
  "success": true,
  "created": true,
  "message": "Account Closure case created for Emily Reed",
  "CaseId": "500J9000001B77LIAT",
  "CaseNumber": "00001573",
  "CaseUrl": "https://yourorg.my.salesforce.com/500J9000001B77LIAT",
  "Subject": "Account Closure Request - Emily Reed",
  "ContactId": "003J900000G00dSIAR",
  "ContactName": "Emily Reed",
  "ContactUrl": "https://yourorg.my.salesforce.com/003J900000G00dSIAR",
  "AccountId": null,
  "CurrentBalance": 1250,
  "Status": "New",
  "Priority": "Medium",
  "instruction": "DISPLAY_CASE_NUMBER_AND_LINK_TO_USER"
}
```

---

## Contact Fields

The handler queries the following Contact fields:

### Standard Fields

| Field | Type | Description |
|-------|------|-------------|
| `Id` | ID | Salesforce Contact ID |
| `FirstName` | String | Contact's first name |
| `LastName` | String | Contact's last name |
| `Phone` | String | Primary phone number |
| `MobilePhone` | String | Mobile phone number |
| `HomePhone` | String | Home phone number |
| `Fax` | String | Fax number |
| `Email` | String | Email address |

### Custom Fields

| Field | Type | Description |
|-------|------|-------------|
| `Annual_Income__c` | Currency | Customer's annual income |
| `Current_Credit_limit__c` | Currency | Current credit limit |
| `Current_balance__c` | Currency | Outstanding balance |
| `Payment_History__c` | Picklist | Payment history status |
| `ContactStatus__c` | Picklist | Account status (Active/Inactive) |
| `Credit_lines__c` | Number | Number of credit lines |

---

## Response Structure

### Success Response

All successful responses follow this structure:

```json
{
  "success": true,
  "found": true,           // For search methods
  "created": true,         // For case creation methods
  "message": "Human-readable message",
  "instruction": "AGENT_INSTRUCTION_CODE",
  // ... additional fields specific to method
}
```

### Error Response

All error responses follow this structure:

```json
{
  "success": false,
  "error": true,
  "errorCode": "ERROR_CODE",
  "message": "Human-readable error message"
}
```

### Error Codes

| Error Code | Description |
|------------|-------------|
| `PERMISSION_DENIED` | User lacks required object permissions |
| `MISSING_PARAMETER` | Required parameter not provided |
| `INVALID_INPUT` | Parameter value is invalid |
| `INVALID_ID_FORMAT` | Salesforce ID format is incorrect |
| `CONTACT_NOT_FOUND` | No contact found with provided ID |
| `CASE_CREATION_FAILED` | Case insert operation failed |
| `METHOD_NOT_FOUND` | Requested method doesn't exist |
| `EXCEPTION` | Unexpected error occurred |

---

## Security & Guardrails

### Permission Checks

The handler validates CRUD permissions before every operation:

```apex
private Boolean hasObjectPerm(String sObjectName, String permType) {
    Schema.DescribeSObjectResult describeResult = 
        Schema.getGlobalDescribe().get(sObjectName).getDescribe();
    if (permType == 'read')   return describeResult.isAccessible();
    if (permType == 'create') return describeResult.isCreateable();
    // ...
}
```

### Input Validation

1. **Salesforce ID Validation:**
   - Must be 15 or 18 characters
   - Must match alphanumeric pattern
   
2. **Input Sanitization:**
   - Removes harmful characters
   - Escapes single quotes (SOQL injection prevention)
   - Trims whitespace

```apex
private String sanitizeInput(String input) {
    if (String.isBlank(input)) return '';
    String sanitized = input.trim();
    sanitized = String.escapeSingleQuotes(sanitized);
    sanitized = sanitized.replaceAll('[^a-zA-Z0-9\\s\\-\'\\$\\,\\.]', '');
    return sanitized;
}
```

### Privacy Protection

When multiple contacts are found, sensitive information is masked:

- **Email:** `j***@example.com`
- **Phone:** `***-***-4567`

### Search Limits

- Minimum search length: 2 characters
- Maximum results: 50 contacts

---

## Sample Conversations

### Conversation 1: Check Credit Information

```
User: Hi, I'd like to check my credit information

Agent: [Calls find_contact_by_name with user's name]

Agent: Hello Emily! I found your account. Here's your credit information:
       
       • Current Credit Limit: $5,000
       • Current Balance: $1,250
       • Available Credit: $3,750
       • Payment History: On-time
       • Account Status: Active
       
       Is there anything specific you'd like help with today?
```

### Conversation 2: Credit Limit Increase

```
User: I'd like to request a credit limit increase to $15,000

Agent: [Calls create_credit_increase_case]

Agent: I've submitted your credit line increase request.
       
       📋 Case Number: 00001571
       📝 Request: Increase from $5,000 to $15,000
       
       Our team will review your request and contact you within 2-3 business days.
       
       [View Case](https://yourorg.my.salesforce.com/500J9000001B77LIAT)
```

### Conversation 3: Lost Card Report

```
User: I lost my credit card yesterday at the mall!

Agent: [Calls create_lost_card_case with LastUsedLocation]

Agent: ⚠️ URGENT: I've immediately created a case to block your card.
       
       📋 Case Number: 00001572
       🔒 Priority: HIGH
       
       Your card will be blocked immediately to prevent unauthorized use.
       A replacement card will be issued within 5-7 business days.
       
       [View Case](https://yourorg.my.salesforce.com/500J9000001B77LIAT)
       
       Is there anything else I can help you with?
```

### Conversation 4: Account Closure

```
User: I want to close my account because I'm moving abroad

Agent: [Calls create_account_closure_case with Reason]

Agent: I've submitted your account closure request.
       
       📋 Case Number: 00001573
       💰 Current Balance: $1,250
       
       ⚠️ Note: Please ensure your outstanding balance of $1,250 is 
       paid before the account can be closed.
       
       Our team will contact you within 5 business days to complete 
       the closure process.
       
       [View Case](https://yourorg.my.salesforce.com/500J9000001B77LIAT)
```

---

## Deployment Guide

### Prerequisites

1. Salesforce org with API access
2. GPTfy package installed (`ccai` namespace)
3. Custom fields on Contact object:
   - `Annual_Income__c`
   - `Current_Credit_limit__c`
   - `Current_balance__c`
   - `Payment_History__c`
   - `ContactStatus__c`
   - `Credit_lines__c`

### Deployment Steps

1. **Deploy the Apex Class:**
   ```bash
   sfdx force:source:deploy -p force-app/main/default/classes/CreditLineAgenticHandler.cls
   ```

2. **Verify Permissions:**
   - Ensure the running user has Read access to Contact
   - Ensure the running user has Create access to Case

3. **Configure GPTfy Agent:**
   - Set Handler Class: `CreditLineAgenticHandler`
   - Configure API Specifications for each method

4. **Test with Anonymous Apex:**
   ```apex
   CreditLineAgenticHandler handler = new CreditLineAgenticHandler();
   
   // Test contact search
   String result = handler.executeMethod('find_contact_by_name', 
       new Map<String, Object>{'name' => 'Emily'});
   System.debug(result);
   
   // Test case creation
   String caseResult = handler.executeMethod('create_credit_increase_case', 
       new Map<String, Object>{'ContactId' => '003XXXXXXXXXXXX'});
   System.debug(caseResult);
   ```

---

## URL Generation

All responses include dynamic URLs that work across any Salesforce org:

```apex
private String buildRecordUrl(Id recordId) {
    if (recordId == null) return null;
    return URL.getOrgDomainUrl().toExternalForm() + '/' + recordId;
}
```

**Examples:**
- Production: `https://acme.my.salesforce.com/500XXXX`
- Sandbox: `https://acme--dev.sandbox.my.salesforce.com/500XXXX`
- Scratch Org: `https://speed-dream-1234.scratch.my.salesforce.com/500XXXX`

---

## Debug Logging

The handler includes comprehensive debug logging (controlled by `DEBUG_ENABLED` flag):

```apex
private static final Boolean DEBUG_ENABLED = true;

private void log(String method, String message) {
    if (DEBUG_ENABLED) {
        System.debug('>>> [' + method + '] ' + message);
    }
}
```

**Log Sections:**
- `START` / `END` - Method boundaries
- `INPUT PARAMETERS` - All incoming parameters
- `OUTPUT RESPONSE` - Final response data
- `CREATED CASE DETAILS` - Case creation confirmation

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-11-28 | Initial implementation with 6 methods |
| 1.1 | 2025-11-28 | Added CaseUrl and ContactUrl to all responses |
| 1.2 | 2025-11-28 | Added comprehensive debug logging |

---

## Author

**GPTfy**  
Salesforce AI Platform

---

## License

Proprietary - GPTfy.ai
