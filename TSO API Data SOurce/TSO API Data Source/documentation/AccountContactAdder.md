# AccountContactAdder Documentation

## Overview
This documentation describes the `AccountContactAdder` Apex utility class and related assets.

## What Was Added
- **Apex Class**: `AccountContactAdder` (force-app/main/default/classes/AccountContactAdder.cls)  
  Bulk-safe method `addContactIfNone` that inserts one contact per account only if no contacts exist.
- **Test Class**: `AccountContactAdderTest` (force-app/main/default/classes/AccountContactAdderTest.cls)  
  Covers single-account and bulk scenarios, ensuring no duplicates are created.
- **Metadata Files**: Corresponding `*.cls-meta.xml` files with API version 64.0.

## Usage
Call from Apex or execute anonymously:
```apex
List<Id> acctIds = new List<Id>{ '001xxxxxxxxxxxx' };
AccountContactAdder.addContactIfNone(acctIds, 'First', 'Last');
```

## Best Practices Applied
- Bulkification: processes lists of accounts in a single transaction.
- SOQL in loops avoided: uses subquery and aggregate queries.
- Test coverage: unit tests for edge cases and bulk scenarios.
- With sharing enforced for security compliance.

## Next Steps
- Deploy to target org via Salesforce CLI:
  ```bash
  sfdx force:source:push
  ```
- Run tests:
  ```bash
  sfdx force:apex:test:run --classnames AccountContactAdderTest --resultformat human
  ```
