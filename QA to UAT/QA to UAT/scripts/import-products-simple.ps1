# Simple import script for Product2 records
# Uses the already exported CSV file

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Product2 Import to UAT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Set-Location "c:\CC\Project_SFDC\QA to UAT\QA to UAT"

# Check if CSV exists
if (!(Test-Path "data\products-export.csv")) {
    Write-Host "ERROR: data\products-export.csv not found!" -ForegroundColor Red
    Write-Host "Please run the export script first." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$recordCount = (Get-Content data\products-export.csv | Measure-Object -Line).Lines - 1
Write-Host "Found $recordCount Product2 records to import" -ForegroundColor White
Write-Host ""

# Option 1: Try standard bulk insert (creates new records)
Write-Host "Attempting bulk insert (creates new records)..." -ForegroundColor Yellow
Write-Host ""

sf data create bulk --sobject Product2 --file data\products-export.csv --target-org kalanithi@cloudcompliance.app.sgpt.uat --wait 10

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Import completed successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "Bulk insert had issues. Check the output above." -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "Please verify the records in your UAT org." -ForegroundColor Cyan
Read-Host "Press Enter to exit"
