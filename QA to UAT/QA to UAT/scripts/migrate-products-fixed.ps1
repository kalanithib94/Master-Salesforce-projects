# Fixed Product2 Migration Script with proper encoding
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Product2 Migration: QA to UAT (Fixed)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Set-Location "c:\CC\Project_SFDC\QA to UAT\QA to UAT"

if (!(Test-Path "data")) {
    New-Item -ItemType Directory -Path "data" | Out-Null
}

# Step 1: Export with proper encoding
Write-Host "[Step 1/3] Exporting Product2 records from sgpt-qa..." -ForegroundColor Yellow
Write-Host ""

$query = "SELECT Name, ProductCode, Description, IsActive, Family, ExternalId, ExternalDataSourceId, DisplayUrl, QuantityUnitOfMeasure, StockKeepingUnit FROM Product2 WHERE IsActive = true LIMIT 10000"

# Export to temp file
$tempFile = "data\products-temp.csv"
$outputFile = "data\products-final.csv"

sf data query --query $query --target-org kalanithi@cloudcompliance.app.sgpt-qa --result-format csv > $tempFile

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to export!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Convert encoding to proper UTF-8 without BOM
Write-Host "[Step 2/3] Converting file encoding..." -ForegroundColor Yellow
$content = Get-Content $tempFile -Raw -Encoding Unicode
[System.IO.File]::WriteAllLines((Resolve-Path $outputFile), $content, (New-Object System.Text.UTF8Encoding $false))

$recordCount = (Get-Content $outputFile | Measure-Object -Line).Lines - 1
Write-Host "Converted $recordCount records to proper UTF-8 format" -ForegroundColor Green
Write-Host ""

# Step 3: Import using bulk create
Write-Host "[Step 3/3] Importing to sgpt-uat..." -ForegroundColor Yellow
Write-Host "This may take a few minutes..." -ForegroundColor Yellow
Write-Host ""

sf data create bulk --sobject Product2 --file $outputFile --target-org kalanithi@cloudcompliance.app.sgpt.uat --wait 10

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Migration completed successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host "- Records migrated: $recordCount" -ForegroundColor White
    Write-Host "- Source: sgpt-qa" -ForegroundColor White
    Write-Host "- Target: sgpt-uat" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "ERROR: Import failed!" -ForegroundColor Red
    Write-Host "Check the error messages above." -ForegroundColor Red
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Log into your sgpt-uat org" -ForegroundColor White
Write-Host "2. Navigate to Products tab" -ForegroundColor White
Write-Host "3. Verify the imported records" -ForegroundColor White
Write-Host ""
Read-Host "Press Enter to exit"
