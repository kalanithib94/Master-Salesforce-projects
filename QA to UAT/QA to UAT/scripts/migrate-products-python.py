#!/usr/bin/env python3
"""
Product2 Migration Script - Batch Import
Migrates Product2 records from QA to UAT org in batches
"""
import subprocess
import json
import csv
import sys
from pathlib import Path

# Configuration
BATCH_SIZE = 200  # Salesforce limit for composite API
SOURCE_ORG = "kalanithi@cloudcompliance.app.sgpt-qa"
TARGET_ORG = "kalanithi@cloudcompliance.app.sgpt.uat"
DATA_DIR = Path("c:/CC/Project_SFDC/QA to UAT/QA to UAT/data")
CSV_FILE = DATA_DIR / "products-export.csv"

def run_command(cmd):
    """Run a shell command and return the result"""
    print(f"Running: {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result

def export_products():
    """Export Product2 records from QA org"""
    print("\n" + "="*60)
    print("STEP 1: Exporting Product2 records from QA")
    print("="*60 + "\n")

    query = ("SELECT Name, ProductCode, Description, IsActive, Family, "
             "ExternalId, ExternalDataSourceId, DisplayUrl, "
             "QuantityUnitOfMeasure, StockKeepingUnit "
             "FROM Product2 WHERE IsActive = true")

    cmd = [
        "sf", "data", "query",
        "--query", query,
        "--target-org", SOURCE_ORG,
        "--result-format", "csv"
    ]

    result = run_command(cmd)

    if result.returncode == 0:
        # Write to file
        DATA_DIR.mkdir(parents=True, exist_ok=True)
        with open(CSV_FILE, 'w', encoding='utf-8') as f:
            f.write(result.stdout)

        # Count records
        with open(CSV_FILE, 'r', encoding='utf-8') as f:
            record_count = sum(1 for line in f) - 1  # Subtract header

        print(f"✅ Successfully exported {record_count} records")
        return record_count
    else:
        print(f"❌ Export failed: {result.stderr}")
        return 0

def split_csv_into_batches():
    """Split the CSV file into batches"""
    print("\n" + "="*60)
    print(f"STEP 2: Splitting data into batches of {BATCH_SIZE}")
    print("="*60 + "\n")

    batches = []
    batch_dir = DATA_DIR / "batches"
    batch_dir.mkdir(parents=True, exist_ok=True)

    with open(CSV_FILE, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        headers = reader.fieldnames

        batch_num = 0
        batch = []

        for row in reader:
            batch.append(row)

            if len(batch) >= BATCH_SIZE:
                batch_file = batch_dir / f"batch_{batch_num:04d}.csv"
                write_batch(batch_file, headers, batch)
                batches.append(batch_file)
                print(f"Created batch {batch_num}: {len(batch)} records")
                batch_num += 1
                batch = []

        # Write remaining records
        if batch:
            batch_file = batch_dir / f"batch_{batch_num:04d}.csv"
            write_batch(batch_file, headers, batch)
            batches.append(batch_file)
            print(f"Created batch {batch_num}: {len(batch)} records")

    print(f"\n✅ Created {len(batches)} batch files")
    return batches

def write_batch(filename, headers, rows):
    """Write a batch of records to a CSV file"""
    with open(filename, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=headers)
        writer.writeheader()
        writer.writerows(rows)

def import_batch(batch_file, batch_num, total_batches):
    """Import a single batch of records"""
    print(f"\nImporting batch {batch_num + 1}/{total_batches}...")

    cmd = [
        "sf", "data", "upsert", "bulk",
        "--sobject", "Product2",
        "--file", str(batch_file),
        "--external-id", "Name",
        "--target-org", TARGET_ORG,
        "--wait", "5"
    ]

    result = run_command(cmd)

    if result.returncode == 0:
        print(f"✅ Batch {batch_num + 1} imported successfully")
        return True
    else:
        print(f"❌ Batch {batch_num + 1} failed: {result.stderr}")
        return False

def import_products(batches):
    """Import Product2 records to UAT org in batches"""
    print("\n" + "="*60)
    print("STEP 3: Importing batches to UAT")
    print("="*60 + "\n")

    successful = 0
    failed = 0

    for i, batch_file in enumerate(batches):
        if import_batch(batch_file, i, len(batches)):
            successful += 1
        else:
            failed += 1
            # Continue with other batches even if one fails

    return successful, failed

def main():
    """Main migration function"""
    print("\n" + "="*60)
    print("Product2 Migration: QA to UAT (Python)")
    print("="*60)

    # Step 1: Export
    record_count = export_products()
    if record_count == 0:
        print("\n❌ Migration aborted - no records exported")
        return 1

    # Step 2: Split into batches
    batches = split_csv_into_batches()

    # Step 3: Import batches
    successful, failed = import_products(batches)

    # Summary
    print("\n" + "="*60)
    print("MIGRATION SUMMARY")
    print("="*60)
    print(f"Total records exported: {record_count}")
    print(f"Batches created: {len(batches)}")
    print(f"Batches imported successfully: {successful}")
    print(f"Batches failed: {failed}")

    if failed == 0:
        print("\n✅ Migration completed successfully!")
        print("\nNext steps:")
        print("1. Log into your sgpt-uat org")
        print("2. Navigate to Products tab")
        print("3. Verify the imported records")
        return 0
    else:
        print(f"\n⚠️ Migration completed with {failed} failed batches")
        print("Check the error messages above for details")
        return 1

if __name__ == "__main__":
    sys.exit(main())
