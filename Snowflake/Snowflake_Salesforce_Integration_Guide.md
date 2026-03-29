# ❄ Snowflake ↔ Salesforce Integration Guide

> **Internal Technical Documentation** | March 2026 | Confidential

---

## Table of Contents

- [Section 1 — Connecting Snowflake with Salesforce via External Data Source](#section-1)
  - [1.1 Pre-Requisites](#11-pre-requisites)
  - [1.2 Snowflake Setup — Security Integration & OAuth](#12-snowflake-setup--security-integration--oauth)
  - [1.3 Snowflake Setup — Database, Tables & Sample Data](#13-snowflake-setup--database-tables--sample-data)
  - [1.4 Salesforce Setup — Auth Provider](#14-salesforce-setup--auth-provider)
  - [1.5 Salesforce Setup — Named Credential (Legacy)](#15-salesforce-setup--named-credential-legacy)
  - [1.6 Salesforce Setup — External Data Source](#16-salesforce-setup--external-data-source)
  - [1.7 Sync External Objects](#17-sync-external-objects)
  - [1.8 Configure External Objects in Salesforce](#18-configure-external-objects-in-salesforce)
  - [1.9 Architecture Overview](#19-architecture-overview)
- [Section 2 — Connecting Snowflake with Salesforce via GPTfy API Data Source](#section-2)

---

<a name="section-1"></a>
## Section 1 — Connecting Snowflake with Salesforce via External Data Source

This section provides a complete, step-by-step walkthrough for establishing a live bi-directional connection between a **Snowflake** database and a **Salesforce** org using Salesforce's native **External Data Source** (Salesforce Connect — SQL type).

Once configured, Snowflake tables appear as **External Objects** inside Salesforce, enabling real-time data access without ETL pipelines or data duplication.

---

### 1.1 Pre-Requisites

| Requirement | Details |
|---|---|
| **Snowflake Account** | Admin-level access with the ability to create security integrations |
| **Salesforce Org with Connect** | Active Salesforce Connect licence (External Data Sources — SQL type) |
| **GPTfy Installed** | GPTfy package installed in the Salesforce org (required for prompt usage on external objects) |
| **Network Connectivity** | Salesforce IP ranges must be allowlisted in Snowflake's network policy |

---

### 1.2 Snowflake Setup — Security Integration & OAuth

Salesforce uses **OAuth 2.0** to authenticate against Snowflake's REST API. You must create a **Security Integration** in Snowflake that registers Salesforce as a trusted OAuth client and specifies the callback URL.

Run the following commands in your Snowflake worksheet. Replace `MY_SNOWSQL_CLIENT_DEVORG` with a meaningful name and substitute your Salesforce domain in the `OAUTH_REDIRECT_URI`.

```sql
-- Step 1: Create the OAuth Security Integration
Create OR replace SECURITY INTEGRATION MY_SNOWSQL_CLIENT_DEVORG
TYPE = OAUTH
ENABLED = TRUE
OAUTH_CLIENT = CUSTOM
OAUTH_CLIENT_TYPE = 'CONFIDENTIAL'
OAUTH_REDIRECT_URI = 'https://<your-sf-domain>.my.salesforce.com/services/authcallback/Snowflake'
OAUTH_ISSUE_REFRESH_TOKENS = TRUE
OAUTH_REFRESH_TOKEN_VALIDITY = 7776000
;

-- Step 2: Describe the integration to get Consumer Key & Endpoint URLs
DESC SECURITY INTEGRATION MY_SNOWSQL_CLIENT_DEVORG;

-- Step 3: Retrieve the Consumer Secret
select SYSTEM$SHOW_OAUTH_CLIENT_SECRETS( 'MY_SNOWSQL_CLIENT_DEVORG' );
```

**Step-by-step instructions:**

1. **Replace the name** — Change `MY_SNOWSQL_CLIENT_DEVORG` in all three commands to a unique integration name for your environment (e.g. `MY_SNOWSQL_DEV`, `MY_SNOWSQL_UAT`).

2. **Set redirect URI** — Replace the placeholder domain in `OAUTH_REDIRECT_URI` with your actual Salesforce My Domain URL. The suffix `/services/authcallback/Snowflake` must match the **URL Suffix** of the Auth Provider you will create in Salesforce.

3. **Run lines 1–9** — Select lines 1–9 and click **Run**. The integration will be created in Snowflake.

4. **Run DESC command** — Select and run the `DESC SECURITY INTEGRATION` command. From the output copy:
   - `OAUTH_AUTHORIZATION_ENDPOINT`
   - `OAUTH_TOKEN_ENDPOINT`
   - `OAUTH_CLIENT_ID`

5. **Run SHOW_SECRETS** — Select and run the `SYSTEM$SHOW_OAUTH_CLIENT_SECRETS` command. Copy the `OAUTH_CLIENT_SECRET` value from the JSON output.

6. **Update callback** — After saving the Salesforce Auth Provider (Section 1.4), Salesforce generates a callback URL. If it differs from the `OAUTH_REDIRECT_URI` above, update the security integration with the correct URL and re-run steps 3–5.

> **ℹ Note:** When giving access to orgs other than dev/qa/uat, always create a new security integration with a unique name rather than reusing existing ones.

---

### 1.3 Snowflake Setup — Database, Tables & Sample Data

Create the database, schema, and tables that will be surfaced as External Objects in Salesforce. The `EXTERNALID` column on the Department table allows Salesforce record linkage.

```sql
-- 1. Create database and schema
CREATE DATABASE TESTDB;
CREATE SCHEMA TESTDB.MYSCHEMA;

-- 2. Department table (includes ExternalId for SF record linking)
CREATE OR REPLACE TABLE TESTDB.MYSCHEMA.DEPARTMENT (
    DID            NUMBER(38,0)   NOT NULL,
    DEPARTMENTNAME VARCHAR(25)    NOT NULL,
    LOCATION       VARCHAR(25),
    CREATEDDATE    DATE           DEFAULT CURRENT_DATE(),
    EXTERNALID     VARCHAR(255),
    UNIQUE (DID)
);

-- 3. Employee table (FK to Department)
CREATE OR REPLACE TABLE TESTDB.MYSCHEMA.EMPLOYEE (
    EID            NUMBER         NOT NULL UNIQUE,
    EMPLOYEENAME   VARCHAR(25)    NOT NULL,
    EMAIL          VARCHAR(25)    DEFAULT NULL,
    JOBTITLE       VARCHAR(25)    DEFAULT NULL,
    DEPARTMENT_ID  NUMBER         NOT NULL UNIQUE,
    CREATEDDATE    DATE           DEFAULT CURRENT_DATE()
);

ALTER TABLE TESTDB.MYSCHEMA.EMPLOYEE
ADD FOREIGN KEY (DEPARTMENT_ID) REFERENCES TESTDB.MYSCHEMA.DEPARTMENT(DID);

-- 4. Seed data — Department
INSERT INTO TESTDB.MYSCHEMA.DEPARTMENT (DID, DEPARTMENTNAME, LOCATION) VALUES
    (101, 'Sales',            'Floor 1'),
    (102, 'Marketing',        'Floor 3'),
    (103, 'Engineering',      'Floor 7'),
    (104, 'Customer Service', 'Floor 2'),
    (105, 'Finance',          'Floor 4');

INSERT INTO TESTDB.MYSCHEMA.DEPARTMENT (DID, DEPARTMENTNAME, LOCATION, EXTERNALID)
    VALUES (106, 'Finance', 'Floor 5', '0018d00000eE0CFAA0');

-- 5. Seed data — Employee
INSERT INTO TESTDB.MYSCHEMA.EMPLOYEE (EID, EMPLOYEENAME, EMAIL, JOBTITLE, DEPARTMENT_ID) VALUES
    (201, 'TestName1', 'testName1@test.com', 'Software Engineer',   103),
    (202, 'TestName2', 'testName2@test.com', 'Marketing Manager',   102),
    (203, 'TestName3', 'testName3@test.com', 'Finance',             105),
    (204, 'TestName4', 'testName4@test.com', 'Customer Service',    104),
    (205, 'TestName5', 'testName5@test.com', 'Software Engineer',   103),
    (206, 'TestName6', 'testName6@test.com', 'Marketing Manager',   102),
    (207, 'TestName7', 'testName7@test.com', 'Salesman',            101);

-- 6. Verify
SELECT * FROM TESTDB.MYSCHEMA.DEPARTMENT;
SELECT * FROM TESTDB.MYSCHEMA.EMPLOYEE;

-- Join query
SELECT t1.EID, t1.EMPLOYEENAME, t2.DEPARTMENTNAME
FROM   TESTDB.MYSCHEMA.EMPLOYEE t1
INNER JOIN TESTDB.MYSCHEMA.DEPARTMENT t2 ON t1.DEPARTMENT_ID = t2.DID
LIMIT 100;

-- Lookup by Salesforce External ID
SELECT * FROM TESTDB.MYSCHEMA.DEPARTMENT WHERE EXTERNALID = '0018d00000eE0CFAA0';
```

> **ℹ Note:** The `EXTERNALID` column on the Department table stores the Salesforce record ID. This enables cross-system lookups between Salesforce records and Snowflake rows.

---

### 1.4 Salesforce Setup — Auth Provider

The Auth Provider stores the OAuth 2.0 credentials retrieved from Snowflake and handles the token exchange between Salesforce and Snowflake.

**Navigation:** `Setup → Identity → Auth. Providers → New`

| Field | Value |
|---|---|
| **Provider Type** | Open ID Connect |
| **Name** | Snowflake |
| **URL Suffix** | Snowflake *(auto-filled)* |
| **Consumer Key** | Value from `DESC SECURITY INTEGRATION` → `OAUTH_CLIENT_ID` |
| **Consumer Secret** | Value from `SYSTEM$SHOW_OAUTH_CLIENT_SECRETS` |
| **Authorize Endpoint URL** | `https://<account>.snowflakecomputing.com/oauth/authorize` |
| **Token Endpoint URL** | `https://<account>.snowflakecomputing.com/oauth/token-request` |
| **Use PKCE Extension** | ✅ Checked |
| **Send access token in header** | ✅ Checked |
| **Include Consumer Secret in SOAP API Responses** | ✅ Checked |

**Screenshot — Auth Provider configuration:**

![Auth Provider](assets/c__Users_Kala_AppData_Roaming_Cursor_User_workspaceStorage_8db96b5896cf80549641b385b6149186_images_image-6ae83b32-501d-4810-8950-2396c20492cf.png)

*Figure 1.4 — Salesforce Auth Provider configured for Snowflake (OpenID Connect)*

> **⚠ Important:** After saving, Salesforce generates a **Callback URL** shown at the bottom of the Auth Provider page. Copy this URL and update your Snowflake Security Integration's `OAUTH_REDIRECT_URI` to match, then re-run the `DESC` and `SHOW_SECRETS` commands to refresh the credentials.

---

### 1.5 Salesforce Setup — Named Credential (Legacy)

The Named Credential stores the Snowflake REST API endpoint URL and references the Auth Provider for OAuth token management. Use the **Legacy** type.

**Navigation:** `Setup → Security → Named Credentials → New Legacy`

| Field | Value |
|---|---|
| **Label** | Snowflake |
| **Name** | Snowflake |
| **URL** | `https://<account-identifier>.snowflakecomputing.com/api/v2/statements` |
| **Identity Type** | Named Principal |
| **Authentication Protocol** | OAuth 2.0 |
| **Authentication Provider** | Snowflake *(Auth Provider created above)* |
| **Generate Authorization Header** | ✅ Checked |
| **Allow Merge Fields in HTTP Header** | ✅ Checked |

Replace `<account-identifier>` with your Snowflake account locator (e.g. `vj79561.europe-west4.gcp`). The full URL looks like:

```
https://vj79561.europe-west4.gcp.snowflakecomputing.com/api/v2/statements
```

**Screenshot — Named Credential configuration:**

![Named Credential](assets/c__Users_Kala_AppData_Roaming_Cursor_User_workspaceStorage_8db96b5896cf80549641b385b6149186_images_image-51bbccd7-c10a-4dba-9824-4490b21c67f2.png)

*Figure 1.5 — Named Credential 'Snowflake' using OAuth 2.0 — Authentication Status: Authenticated*

---

### 1.6 Salesforce Setup — External Data Source

The External Data Source is the Salesforce Connect configuration that maps Snowflake as a SQL-based external system.

**Navigation:** `Setup → Integrations → External Data Sources → New`

| Field | Value |
|---|---|
| **External Data Source (Label)** | testSnowflake |
| **Name** | testSnowflake |
| **Type** | SQL |
| **Provider** | Snowflake |
| **Named Credential** | Snowflake *(created in Step 1.5)* |
| **Connection Timeout (Seconds)** | 120 |
| **Writable External Objects** | ✅ Checked — allows DML operations from Salesforce |
| **Server Driven Pagination** | ✅ Checked — improves performance with large datasets |

**Screenshot — External Data Source configuration:**

![External Data Source](assets/c__Users_Kala_AppData_Roaming_Cursor_User_workspaceStorage_8db96b5896cf80549641b385b6149186_images_image-0f691fbb-b7b9-4f01-a87c-8021567e1f24.png)

*Figure 1.6 — External Data Source 'testSnowflake' — SQL Type with Snowflake Provider*

---

### 1.7 Sync External Objects

After saving the External Data Source, synchronise it with Snowflake to discover and import the table metadata as External Objects.

**Step 1 — Click 'Validate and Sync'**
From the External Data Source detail page, click **Validate and Sync**.

**Step 2 — Enter connection parameters**
In the sync dialog provide:
- **Database** = `TESTDB`
- **Schema** = `MYSCHEMA`

**Step 3 — Select objects**
From the list of discovered tables, select **DEPARTMENT** and **EMPLOYEE**.

> ⚠ **Do NOT check 'Sync in Background'** — this must run synchronously to confirm success immediately.

**Step 4 — Verify deployment**
After sync completes, go to `Setup → External Objects`. If the objects are listed as *Not Deployed*, click **Edit** on each and check the **Deployed** checkbox, then save.

**Step 5 — Create tabs**
Create Salesforce App tabs for both External Objects via `Setup → User Interface → Tabs → New` so users can navigate to them.

**Step 6 — Add related list**
Open a Department External Object record. If the Employee related list is missing, add it via `Setup → External Objects → Department → Page Layouts`.

> **ℹ Note:** If the sync fails with an authentication error, ensure the Named Credential authentication status is **Authenticated**. You may need to click **Authenticate** on the Named Credential to trigger the OAuth flow.

---

### 1.8 Configure External Objects in Salesforce

| Feature | Details |
|---|---|
| **Record pages** | Use Lightning App Builder to add External Object related lists to standard object pages (e.g. add `EMPLOYEE__x` to the Account page layout) |
| **GPTfy prompts** | Create a GPTfy prompt on the Department External Object. Add Employee as a **related object** in the prompt field mapping to enable AI summaries using live Snowflake data |
| **Run the prompt** | Navigate to a Department record → Add the GPTfy Console component to the page → Run the configured prompt to verify end-to-end data flow |
| **SOQL queries** | External Objects support SOQL (with limitations). Example: `SELECT Id, DepartmentName__c FROM Department__x LIMIT 10` |
| **DML operations** | Because **Writable External Objects** is enabled, Salesforce users can insert, update, and delete Snowflake rows directly from Salesforce UI or Apex (subject to Snowflake permissions) |

---

### 1.9 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         SNOWFLAKE                                   │
│                                                                     │
│  ┌──────────────────────────┐    ┌──────────────────────────────┐  │
│  │  Security Integration    │    │  TESTDB.MYSCHEMA             │  │
│  │  (OAuth 2.0 — Custom)    │    │  ├── DEPARTMENT table        │  │
│  │  MY_SNOWSQL_CLIENT_*     │    │  └── EMPLOYEE table          │  │
│  └────────────┬─────────────┘    └──────────────────────────────┘  │
└───────────────│─────────────────────────────────────────────────────┘
                │ OAuth Tokens
                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         SALESFORCE                                  │
│                                                                     │
│  ┌──────────────────┐    ┌──────────────────┐                      │
│  │  Auth Provider   │───▶│  Named Credential│                      │
│  │  (OpenID Connect)│    │  (Legacy — OAuth)│                      │
│  └──────────────────┘    └────────┬─────────┘                      │
│                                   │                                 │
│                          ┌────────▼─────────┐                      │
│                          │ External Data    │                      │
│                          │ Source (SQL /    │                      │
│                          │ Snowflake)       │                      │
│                          └────────┬─────────┘                      │
│                                   │ Sync                            │
│                    ┌──────────────┴───────────────┐                │
│                    │                              │                 │
│           ┌────────▼────────┐           ┌────────▼────────┐        │
│           │ DEPARTMENT__x   │           │  EMPLOYEE__x    │        │
│           │ (External Obj)  │◀──────────│  (External Obj) │        │
│           └─────────────────┘  Related  └─────────────────┘        │
│                                  List                               │
└─────────────────────────────────────────────────────────────────────┘
```

| Layer | Component | Purpose |
|---|---|---|
| Snowflake | Security Integration (OAuth) | Issues access/refresh tokens to Salesforce |
| Snowflake | TESTDB.MYSCHEMA tables | Source data: DEPARTMENT, EMPLOYEE |
| Salesforce | Auth Provider (OpenID Connect) | Manages OAuth token lifecycle |
| Salesforce | Named Credential | Stores endpoint URL + auth reference |
| Salesforce | External Data Source (SQL/Snowflake) | Salesforce Connect adapter |
| Salesforce | External Objects (DEPARTMENT__x, EMPLOYEE__x) | Virtual SF objects backed by Snowflake |

---

<a name="section-2"></a>
## Section 2 — Connecting Snowflake with Salesforce via GPTfy API Data Source

GPTfy's **API Data Source** is an alternative integration pattern that bypasses Salesforce Connect entirely. Instead of syncing external objects, GPTfy calls Snowflake's REST API directly at **prompt runtime** via an Apex connector class. This gives you full control over the SQL query, the data shaping, and when the callout fires.

**High-level flow:**

```
Salesforce Prompt (GPTfy)
        │
        ▼
  API Data Source  ──▶  Named Credential (SnowflakeDS)
        │                        │
        │                 Auth Provider (SnowflakeDS)
        │                        │
        ▼                        ▼
  Connector Class          Snowflake REST API
  (SampleDataSourceClass2) /api/v2/statements
        │
        ▼
  Parsed result injected into prompt context
```

> **ℹ Note:** The Snowflake database, schema, and tables (`TESTDB.MYSCHEMA.DEPARTMENT` / `EMPLOYEE`) are **identical** to Section 1. No additional Snowflake-side setup is needed beyond what was done in Section 1.2 and 1.3.

---

### 2.1 Pre-Requisites

| Requirement | Details |
|---|---|
| **Section 1 Snowflake setup complete** | Security Integration, TESTDB, MYSCHEMA, DEPARTMENT & EMPLOYEE tables must already exist |
| **GPTfy installed** | GPTfy package deployed in the Salesforce org |
| **Apex deploy access** | Developer Console or VS Code with SFDX to deploy the connector Apex class |
| **Salesforce Connect licence NOT required** | The API Data Source uses standard HTTP callouts — no Salesforce Connect licence needed |

---

### 2.2 Salesforce Setup — Auth Provider (SnowflakeDS)

The Auth Provider for the API Data Source follows the **exact same steps** as Section 1.4, but with a different name to keep it separate from the External Data Source credential.

**Navigation:** `Setup → Identity → Auth. Providers → New`

| Field | Value |
|---|---|
| **Provider Type** | Open ID Connect |
| **Name** | SnowflakeDS |
| **URL Suffix** | SnowflakeDS *(auto-filled)* |
| **Consumer Key** | From `DESC SECURITY INTEGRATION` → `OAUTH_CLIENT_ID` |
| **Consumer Secret** | From `SYSTEM$SHOW_OAUTH_CLIENT_SECRETS` |
| **Authorize Endpoint URL** | `https://st81340.ap-southeast-1.snowflakecomputing.com/oauth/authorize` |
| **Token Endpoint URL** | `https://st81340.ap-southeast-1.snowflakecomputing.com/oauth/token-request` |
| **Use PKCE Extension** | ✅ Checked |
| **Send access token in header** | ✅ Checked |
| **Include Consumer Secret in SOAP API Responses** | ✅ Checked |

**Screenshot — Auth Provider (SnowflakeDS):**

![Auth Provider SnowflakeDS](assets/c__Users_Kala_AppData_Roaming_Cursor_User_workspaceStorage_8db96b5896cf80549641b385b6149186_images_image-790491e4-f0ee-4f4f-8f46-12550a6f0468.png)

*Figure 2.2 — Auth Provider 'SnowflakeDS' — OpenID Connect — Authorized against ap-southeast-1 Snowflake account*

> **⚠ Important:** The Snowflake Security Integration's `OAUTH_REDIRECT_URI` must use `/services/authcallback/SnowflakeDS` (matching the URL Suffix above). Update the Snowflake integration and re-run `DESC` + `SHOW_SECRETS` if needed.

---

### 2.3 Salesforce Setup — Named Credential (SnowflakeDS)

**Navigation:** `Setup → Security → Named Credentials → New Legacy`

| Field | Value |
|---|---|
| **Label** | SnowflakeDS |
| **Name** | SnowflakeDS |
| **URL** | `https://st81340.ap-southeast-1.snowflakecomputing.com/api/v2/statements` |
| **Identity Type** | Named Principal |
| **Authentication Protocol** | OAuth 2.0 |
| **Authentication Provider** | SnowflakeDS *(created above)* |
| **Authentication Status** | Authenticated |
| **Start Authentication Flow on Save** | ✅ Checked |
| **Generate Authorization Header** | ✅ Checked |
| **Allow Merge Fields in HTTP Header** | ☐ Unchecked |
| **Allow Merge Fields in HTTP Body** | ☐ Unchecked |

**Screenshot — Named Credential (SnowflakeDS):**

![Named Credential SnowflakeDS](assets/c__Users_Kala_AppData_Roaming_Cursor_User_workspaceStorage_8db96b5896cf80549641b385b6149186_images_image-668b5c31-e7ec-46b1-9e52-11a2799b26e6.png)

*Figure 2.3 — Named Credential 'SnowflakeDS' — OAuth 2.0 — Authentication Status: Authenticated*

> **ℹ Note:** The Named Credential name `SnowflakeDS` is used directly inside the Apex connector class via `'callout:' + dataSource.Named_Credential__c`. Make sure the names match exactly.

---

### 2.4 Apex Connector Class — SampleDataSourceClass2

This global Apex class implements GPTfy's `ccai.AIDataSourceInterface` (from the `ccai` managed package namespace). At prompt runtime, GPTfy calls `getExternalData()`, which fires a callout to Snowflake's SQL REST API and returns the raw result set to be injected into the prompt context.

**Deploy this class via Developer Console or VS Code SFDX before creating the API Data Source.**

```apex
global class SampleDataSourceClass2 implements ccai.AIDataSourceInterface {

    global String getExternalData(ccai__AI_Data_Source__c dataSource, String extractedData) {

      /*  Map<String, Object> maps = (Map<String, Object>)JSON.deserializeUntyped(extractedData);
          maps.put('Industry', 'Agriculture');
          return JSON.serialize(maps); */

        Map<String, Object> maps = (Map<String, Object>)JSON.deserializeUntyped(extractedData);
        System.debug('extractedData : ' + maps.get('Id'));

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:' + dataSource.ccai__Named_Credential__c);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setTimeout(60000);

        String sql = 'SELECT t1.EID,t1.EmployeeName, t1.Email,t2.did, t2.departmentname ' +
                     'FROM TESTDB.myschema.Employee as t1 ' +
                     'INNER JOIN TESTDB.myschema.Department t2 ON t1.department_id = t2.did ' +
                     'WHERE t2.ExternalId = \'' + maps.get('Id') + '\'';

        Map<String, Object> body = new Map<String, Object>{
            'statement' => sql,
            'timeout'   => 60,
            'warehouse' => 'COMPUTE_WH',
            'database'  => 'TESTDB',
            'schema'    => 'MYSCHEMA',
            'role'      => 'SYSADMIN'
        };
        req.setBody(JSON.serialize(body));

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            // Parse response: res.getBody() contains JSON with 'resultSet' for data
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            Object o = (Object) response.get('data');
            System.debug('Query Result: ' + o);
            return o.toString();
        } else {
            System.debug('Error: ' + res.getStatusCode() + ' - ' + res.getBody());
            return 'Error: ' + res.getStatusCode() + ' - ' + res.getBody();
        }
    }
}
```

**Key points about the class:**

| Aspect | Detail |
|---|---|
| **Interface** | `ccai.AIDataSourceInterface` — GPTfy managed package (`ccai` namespace) connector contract |
| **`extractedData`** | JSON string of the current Salesforce record (e.g. Account). GPTfy passes this automatically |
| **`dataSource.ccai__Named_Credential__c`** | Namespaced field on `ccai__AI_Data_Source__c` — resolves to `SnowflakeDS` at runtime |
| **SQL query** | Joins `EMPLOYEE` and `DEPARTMENT`, filtered by `ExternalId` = current record's Salesforce ID |
| **Snowflake REST endpoint** | `POST /api/v2/statements` — submits SQL and returns results as JSON |
| **Return value** | Raw `data` array from Snowflake response, injected into the GPTfy prompt as context |

---

### 2.5 GPTfy Setup — Create API Data Source

**Navigation:** `GPTfy → API Data Source → New`

You will see the GPTfy API Data Source catalogue (Snowflake API, Bloomberg, DnB, GovWin, etc.). Select **Snowflake API** or create a **Test API Data Source** for custom connector classes.

**Screenshot — API Data Source catalogue:**

![API Data Source List](assets/c__Users_Kala_AppData_Roaming_Cursor_User_workspaceStorage_8db96b5896cf80549641b385b6149186_images_image-82ed5521-8078-47c6-b2da-b4aff1f0d948.png)

*Figure 2.5 — GPTfy API Data Source catalogue — Snowflake API and Test API Data Source visible*

Click **Edit** on your chosen data source (or create a new one) and fill in the **Data Source Details** tab:

| Field | Value |
|---|---|
| **Data Source Name** | Test API Data Source |
| **Named Credential** | SnowflakeDS |
| **Source** | Azure *(or appropriate source type)* |
| **Connector Class** | `SampleDataSourceClass2` |
| **EndPoint URL** | *(leave blank — endpoint is resolved via the Named Credential)* |

Click **Save**, then click **Activate**.

**Screenshot — Edit API Data Source:**

![Edit API Data Source](assets/c__Users_Kala_AppData_Roaming_Cursor_User_workspaceStorage_8db96b5896cf80549641b385b6149186_images_image-91e25996-5efc-48c9-ba8d-922141a4dd01.png)

*Figure 2.5b — Edit Test API Data Source — Named Credential: SnowflakeDS, Connector Class: SampleDataSourceClass2*

> **⚠ Important:** The data source must be in **Active** status (green tick in the catalogue) before it can be used in a prompt mapping.

---

### 2.6 GPTfy Setup — Create Prompt with API Data Source Mapping

Once the API Data Source is active, link it to a prompt via **Data Context Mapping**.

**Navigation:** `GPTfy → Prompt Catalog → [Your Prompt] → Data Context Mapping → New`

| Field | Value |
|---|---|
| **Mapping Name** | Account Prompt Test ss 1 *(or any descriptive name)* |
| **Target Object** | Account (Account) |
| **Target Object Label** | Account |
| **Description** | *(optional)* |
| **Select API Data Connection** | Test API Data Source *(the active data source from Step 2.5)* |
| **Select Apex Security Layer** | *(optional — leave blank or select if you have security layer configured)* |

Click **Save**.

**Screenshot — Data Context Mapping:**

![Data Context Mapping](assets/c__Users_Kala_AppData_Roaming_Cursor_User_workspaceStorage_8db96b5896cf80549641b385b6149186_images_image-095cfd52-ae4d-4d32-85f9-9c79e956736b.png)

*Figure 2.6 — Data Context Mapping linking the prompt to 'Test API Data Source' on the Account object*

**How it works at runtime:**

1. User opens an **Account** record in Salesforce and runs the GPTfy prompt
2. GPTfy serialises the Account record fields into JSON (`extractedData`) and calls `SampleDataSourceClass2.getExternalData()`
3. The Apex class extracts the Account's `Id`, builds the Snowflake SQL query filtering `DEPARTMENT.ExternalId = <AccountId>`
4. The callout fires to Snowflake via the `SnowflakeDS` Named Credential
5. Snowflake returns the matching `EMPLOYEE` + `DEPARTMENT` rows as JSON
6. GPTfy injects the result into the prompt context for the LLM to process

---

### 2.7 Architecture Overview — GPTfy API Data Source Flow

```
┌──────────────────────────────────────────────────────────────────────────┐
│                           SNOWFLAKE                                      │
│                                                                          │
│  ┌──────────────────────────┐    ┌───────────────────────────────────┐  │
│  │  Security Integration    │    │  TESTDB.MYSCHEMA                  │  │
│  │  (OAuth 2.0 — Custom)    │    │  ├── DEPARTMENT (ExternalId col)  │  │
│  │  MY_SNOWSQL_CLIENT_*     │    │  └── EMPLOYEE                     │  │
│  └────────────┬─────────────┘    └───────────────────────────────────┘  │
└───────────────│──────────────────────────────────────────────────────────┘
                │ OAuth + REST POST /api/v2/statements
                ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                          SALESFORCE                                      │
│                                                                          │
│  ┌──────────────────┐    ┌──────────────────┐                           │
│  │  Auth Provider   │───▶│  Named Credential│                           │
│  │  (SnowflakeDS)   │    │  (SnowflakeDS)   │                           │
│  └──────────────────┘    └────────┬─────────┘                           │
│                                   │                                      │
│  ┌─────────────────────────────── │ ──────────────────────────┐         │
│  │  GPTfy                         │                           │         │
│  │                       ┌────────▼──────────────┐           │         │
│  │  Prompt Catalog ─────▶│  API Data Source       │           │         │
│  │                       │  (Test API Data Source)│           │         │
│  │                       └────────┬──────────────-┘           │         │
│  │                                │                           │         │
│  │                       ┌────────▼──────────────┐           │         │
│  │                       │  SampleDataSourceClass2│           │         │
│  │                       │  (AIDataSourceInterface│           │         │
│  │                       │  implementation)       │           │         │
│  │                       └────────┬───────────────┘           │         │
│  │                                │                           │         │
│  │                       ┌────────▼──────────────┐           │         │
│  │  Data Context Mapping │  Result injected into │           │         │
│  │  (Account object)     │  prompt context (LLM) │           │         │
│  │                       └───────────────────────┘           │         │
│  └───────────────────────────────────────────────────────────┘         │
└──────────────────────────────────────────────────────────────────────────┘
```

| Layer | Component | Purpose |
|---|---|---|
| Snowflake | Security Integration | Issues OAuth tokens for the SnowflakeDS callout |
| Snowflake | TESTDB.MYSCHEMA tables | Source data queried at prompt runtime |
| Salesforce | Auth Provider (SnowflakeDS) | OAuth lifecycle for the API callout credential |
| Salesforce | Named Credential (SnowflakeDS) | Stores endpoint + auth, referenced as `callout:SnowflakeDS` |
| Salesforce | SampleDataSourceClass2 | Apex class that builds SQL, fires callout, returns data |
| GPTfy | API Data Source | Registers the connector class + named credential |
| GPTfy | Data Context Mapping | Links the data source to a specific prompt + target object |
| GPTfy | Prompt | Consumes the Snowflake data as enriched context for the LLM |

---

### 2.8 Comparison — External Data Source vs GPTfy API Data Source

| Aspect | External Data Source (Section 1) | GPTfy API Data Source (Section 2) |
|---|---|---|
| **Salesforce Connect licence** | Required | Not required |
| **Data access pattern** | Always-on virtual objects (SOQL) | On-demand callout at prompt runtime |
| **External Objects** | Yes — visible in SF UI as records | No — data only appears in prompt output |
| **DML from Salesforce** | ✅ Yes (writable external objects) | ❌ No (read-only callout) |
| **SQL control** | Automatic (SF generates queries) | Full control via Apex class |
| **Setup complexity** | Moderate | Low (once Auth Provider & Named Credential exist) |
| **Best for** | Browsing / reporting on Snowflake data in SF | AI prompt enrichment with Snowflake context |
