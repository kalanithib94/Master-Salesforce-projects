# PowerShell script to migrate Product2 records from QA to UAT
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Product2 Migration: QA to UAT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Set location
Set-Location "c:\CC\Project_SFDC\QA to UAT\QA to UAT"

# Create data directory
if (!(Test-Path "data")) {
    New-Item -ItemType Directory -Path "data" | Out-Null
}

# Step 1: Export from QA
Write-Host "[Step 1/3] Exporting Product2 records from sgpt-qa..." -ForegroundColor Yellow
Write-Host ""

$exportQuery = "SELECT Name, ProductCode, Description, IsActive, Family, ExternalId, ExternalDataSourceId, DisplayUrl, QuantityUnitOfMeasure, StockKeepingUnit FROM Product2 WHERE IsActive = true"

sf data export tree --query $exportQuery --target-org kalanithi@cloudcompliance.app.sgpt-qa --output-dir data --plan

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to export Product2 records!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "[Step 2/3] Product2 records exported successfully!" -ForegroundColor Green
Write-Host ""

# Step 2: Import to UAT
Write-Host "[Step 3/3] Importing Product2 records into sgpt-uat..." -ForegroundColor Yellow
Write-Host ""

sf data import tree --plan data\Product2-plan.json --target-org kalanithi@cloudcompliance.app.sgpt.uat

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to import Product2 records!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Migration completed successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Please verify the Product2 records in your UAT org."
Read-Host "Press Enter to exit"
