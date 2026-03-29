# PowerShell script to migrate large number of Product2 records using CSV and Bulk API
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Product2 Bulk Migration: QA to UAT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Set location
Set-Location "c:\CC\Project_SFDC\QA to UAT\QA to UAT"

# Create data directory
if (!(Test-Path "data")) {
    New-Item -ItemType Directory -Path "data" | Out-Null
}

# Step 1: Export from QA to CSV
Write-Host "[Step 1/3] Exporting Product2 records from sgpt-qa to CSV..." -ForegroundColor Yellow
Write-Host ""

$exportQuery = "SELECT Name, ProductCode, Description, IsActive, Family, ExternalId, ExternalDataSourceId, DisplayUrl, QuantityUnitOfMeasure, StockKeepingUnit FROM Product2 WHERE IsActive = true"

sf data query --query $exportQuery --target-org kalanithi@cloudcompliance.app.sgpt-qa --result-format csv > data\products-export.csv

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to export Product2 records!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "[Step 2/3] Product2 records exported successfully!" -ForegroundColor Green
$recordCount = (Get-Content data\products-export.csv | Measure-Object -Line).Lines - 1
Write-Host "Total records exported: $recordCount" -ForegroundColor Green
Write-Host ""

# Step 2: Import to UAT using Bulk API
Write-Host "[Step 3/3] Importing Product2 records into sgpt-uat using Bulk API..." -ForegroundColor Yellow
Write-Host "This may take a few minutes for $recordCount records..." -ForegroundColor Yellow
Write-Host ""

sf data upsert bulk --sobject Product2 --file data\products-export.csv --external-id Name --target-org kalanithi@cloudcompliance.app.sgpt.uat --wait 10

if ($LASTEXITCODE -ne 0) {
    Write-Host "" -ForegroundColor Red
    Write-Host "ERROR: Bulk upsert failed!" -ForegroundColor Red
    Write-Host "Trying alternative method with bulk insert..." -ForegroundColor Yellow
    Write-Host ""

    # Try bulk insert as fallback
    sf data import bulk --sobject Product2 --file data\products-export.csv --target-org kalanithi@cloudcompliance.app.sgpt.uat --wait 10

    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Failed to import Product2 records!" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Migration completed successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "- Exported: $recordCount records from sgpt-qa" -ForegroundColor White
Write-Host "- Imported: Check UAT org for verification" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Log into your sgpt-uat org" -ForegroundColor White
Write-Host "2. Navigate to Products tab" -ForegroundColor White
Write-Host "3. Verify the imported records" -ForegroundColor White
Write-Host ""
Read-Host "Press Enter to exit"
