# Product2 Migration Scripts

This directory contains scripts to migrate Product2 records from QA to UAT org.

## Files

- `soql/product2.soql` - SOQL query to fetch Product2 records (can be run in VS Code)
- `migrate-products.bat` - Complete migration script (export from QA + import to UAT)
- `export-products.bat` - Export Product2 records from QA org only
- `import-products.bat` - Import Product2 records to UAT org only

## Quick Start

### One-Step Migration (Recommended)

Run the complete migration script:
```bash
cd scripts
migrate-products.bat
```

This will:
1. Export all active Product2 records from sgpt-qa org
2. Save them to the `data/` directory
3. Import them into sgpt-uat org

### Manual Step-by-Step Process

If you prefer to run export and import separately:

1. **Export from QA:**
   ```bash
   cd scripts
   export-products.bat
   ```

2. **Review the exported data:**
   - Check `data/products-export.json` for JSON format
   - Check `data/products-export.csv` for CSV format

3. **Import to UAT:**
   ```bash
   import-products.bat
   ```

## Prerequisites

- Salesforce CLI (sf) installed
- Authenticated to both orgs:
  - Source: `kalanithi@cloudcompliance.app.sgpt-qa`
  - Target: `kalanithi@cloudcompliance.app.sgpt.uat`

## Notes

- Only **active** Product2 records are migrated (IsActive = true)
- The scripts exclude the `Id` field to allow Salesforce to generate new IDs in the target org
- If you need to update existing records instead of creating new ones, you'll need to use the external ID or upsert operation

## Troubleshooting

If you encounter errors:

1. Verify org connections:
   ```bash
   sf org list
   ```

2. Test org access:
   ```bash
   sf org display --target-org kalanithi@cloudcompliance.app.sgpt-qa
   sf org display --target-org kalanithi@cloudcompliance.app.sgpt.uat
   ```

3. Check the query in VS Code using the SOQL file

## Custom Fields

If your Product2 object has custom fields, edit the SOQL query in:
- `soql/product2.soql`
- The query strings in the batch files

Add your custom fields to the SELECT clause.
