# CreditLineAgenticHandler - Input Parameters Guide

This document lists all input parameters required for each method in the `CreditLineAgenticHandler` class.

## Method Entry Point

All methods are called through the `executeMethod` function:

```apex
String executeMethod(String methodName, Map<String, Object> parameters)
```

**Parameters:**
- `methodName` (String, required): The name of the method to execute
- `parameters` (Map<String, Object>, required): Map containing method-specific parameters

---

## 1. find_contact_by_name

**Purpose:** Search for contacts by first name or last name.

**Required Parameters:**
- `name` (String) - The first name or last name to search for (minimum 2 characters)

**Example:**
```apex
Map<String, Object> params = new Map<String, Object>{
    'name' => 'Emily'
};
String result = handler.executeMethod('find_contact_by_name', params);
```

**JSON Format:**
```json
{
  "name": "Emily"
}
```

---

## 2. find_contact_details_by_id

**Purpose:** Get detailed contact information using Salesforce Contact ID.

**Required Parameters:**
- `Id` (String) - The Salesforce Contact ID (15 or 18 characters)

**Example:**
```apex
Map<String, Object> params = new Map<String, Object>{
    'Id' => '003J900000G00dSIAR'
};
String result = handler.executeMethod('find_contact_details_by_id', params);
```

**JSON Format:**
```json
{
  "Id": "003J900000G00dSIAR"
}
```

---

## 3. create_case_for_contact

**Purpose:** Create a general-purpose case for a contact.

**Required Parameters:**
- `ContactId` (String) - The Salesforce Contact ID
- `Subject` (String) - Subject line for the case

**Optional Parameters:**
- `Description` (String) - Detailed description of the case
- `Status` (String) - Case status (default: New)
- `Priority` (String) - Case priority: Low, Medium, High (default: Medium)
- `Origin` (String) - Case origin (default: Chat)
- `Type` (String) - Case type
- `Reason` (String) - Case reason

**Example:**
```apex
Map<String, Object> params = new Map<String, Object>{
    'ContactId' => '003J900000G00dSIAR',
    'Subject' => 'General Inquiry',
    'Description' => 'Customer has a question about their account',
    'Priority' => 'Low'
};
String result = handler.executeMethod('create_case_for_contact', params);
```

**JSON Format:**
```json
{
  "ContactId": "003J900000G00dSIAR",
  "Subject": "General Inquiry",
  "Description": "Customer has a question about their account",
  "Priority": "Low"
}
```

---

## 4. create_credit_increase_case

**Purpose:** Create a case for credit line increase requests.

**Required Parameters:**
- `ContactId` (String) - The Salesforce Contact ID

**Optional Parameters:**
- `RequestedAmount` (String) - The new credit limit amount being requested (e.g., "$10,000")
- `Reason` (String) - Reason for requesting the credit line increase

**Example:**
```apex
Map<String, Object> params = new Map<String, Object>{
    'ContactId' => '003J900000G00dSIAR',
    'RequestedAmount' => '$15,000',
    'Reason' => 'Business expansion needs'
};
String result = handler.executeMethod('create_credit_increase_case', params);
```

**JSON Format:**
```json
{
  "ContactId": "003J900000G00dSIAR",
  "RequestedAmount": "$15,000",
  "Reason": "Business expansion needs"
}
```

**Case Created:**
- Subject: `Credit Line Increase Request - {Contact Name}`
- Priority: Medium
- Type: Service Request
- Origin: Chat
- Status: New

---

## 5. create_lost_card_case

**Purpose:** Create an urgent case for lost or stolen credit card reports.

**Required Parameters:**
- `ContactId` (String) - The Salesforce Contact ID

**Optional Parameters:**
- `LastUsedDate` (String) - Date when the card was last used (e.g., "2025-11-27")
- `LastUsedLocation` (String) - Location where the card was last used
- `AdditionalNotes` (String) - Any additional information about the lost/stolen card

**Example:**
```apex
Map<String, Object> params = new Map<String, Object>{
    'ContactId' => '003J900000G00dSIAR',
    'LastUsedDate' => '2025-11-27',
    'LastUsedLocation' => 'Downtown Mall',
    'AdditionalNotes' => 'Card may have been pickpocketed'
};
String result = handler.executeMethod('create_lost_card_case', params);
```

**JSON Format:**
```json
{
  "ContactId": "003J900000G00dSIAR",
  "LastUsedDate": "2025-11-27",
  "LastUsedLocation": "Downtown Mall",
  "AdditionalNotes": "Card may have been pickpocketed"
}
```

**Case Created:**
- Subject: `URGENT: Lost/Stolen Credit Card - {Contact Name}`
- Priority: High
- Type: Problem
- Origin: Chat
- Status: New

---

## 6. create_account_closure_case

**Purpose:** Create a case for account closure requests.

**Required Parameters:**
- `ContactId` (String) - The Salesforce Contact ID

**Optional Parameters:**
- `Reason` (String) - Reason for requesting account closure
- `AdditionalNotes` (String) - Any additional information about the closure request

**Example:**
```apex
Map<String, Object> params = new Map<String, Object>{
    'ContactId' => '003J900000G00dSIAR',
    'Reason' => 'Moving abroad',
    'AdditionalNotes' => 'Please process within 30 days'
};
String result = handler.executeMethod('create_account_closure_case', params);
```

**JSON Format:**
```json
{
  "ContactId": "003J900000G00dSIAR",
  "Reason": "Moving abroad",
  "AdditionalNotes": "Please process within 30 days"
}
```

**Case Created:**
- Subject: `Account Closure Request - {Contact Name}`
- Priority: Medium
- Type: Service Request
- Origin: Chat
- Status: New

---

## Quick Reference Table

| Method Name | Required Parameters | Optional Parameters |
|------------|-------------------|-------------------|
| `find_contact_by_name` | `name` | None |
| `find_contact_details_by_id` | `Id` | None |
| `create_case_for_contact` | `ContactId`, `Subject` | `Description`, `Status`, `Priority`, `Origin`, `Type`, `Reason` |
| `create_credit_increase_case` | `ContactId` | `RequestedAmount`, `Reason` |
| `create_lost_card_case` | `ContactId` | `LastUsedDate`, `LastUsedLocation`, `AdditionalNotes` |
| `create_account_closure_case` | `ContactId` | `Reason`, `AdditionalNotes` |

---

## Notes

1. **ContactId Format:** Must be a valid Salesforce ID (15 or 18 characters, alphanumeric)
2. **Name Search:** Minimum 2 characters required for name searches
3. **Case Creation:** All case creation methods automatically:
   - Validate the ContactId exists
   - Set AccountId if the Contact has an associated Account
   - Include the Contact's full name in the Case Subject
4. **Error Handling:** All methods return JSON with `success: true/false` and appropriate error messages if validation fails

