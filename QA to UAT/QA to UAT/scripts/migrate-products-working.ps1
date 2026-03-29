# Working Product2 Migration Script
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Product2 Migration: QA to UAT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$ErrorActionPreference = "Continue"
Set-Location "c:\CC\Project_SFDC\QA to UAT\QA to UAT"

if (!(Test-Path "data")) {
    New-Item -ItemType Directory -Path "data" | Out-Null
}

# Step 1: Export from QA
Write-Host "[Step 1/2] Exporting Product2 records from sgpt-qa..." -ForegroundColor Yellow
Write-Host ""

$query = "SELECT Name, ProductCode, Description, IsActive, Family FROM Product2 WHERE IsActive = true LIMIT 1000"

sf data query --query $query --target-org kalanithi@cloudcompliance.app.sgpt-qa --result-format json | Out-File -FilePath "data\products.json" -Encoding UTF8

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Export failed!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Parse the JSON and count records
$jsonContent = Get-Content "data\products.json" -Raw | ConvertFrom-Json
$recordCount = $jsonContent.result.records.Count

Write-Host "Successfully exported $recordCount records" -ForegroundColor Green
Write-Host ""

if ($recordCount -eq 0) {
    Write-Host "No records to import!" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 0
}

# Step 2: Import to UAT using JSON
Write-Host "[Step 2/2] Importing $recordCount Product2 records to sgpt-uat..." -ForegroundColor Yellow
Write-Host "Processing records..."
Write-Host ""

# Create a simpler JSON array for import (remove attributes and Id)
$recordsToImport = @()
foreach ($record in $jsonContent.result.records) {
    $cleanRecord = @{}
    $record.PSObject.Properties | Where-Object { $_.Name -ne "attributes" -and $_.Name -ne "Id" } | ForEach-Object {
        if ($_.Value) {
            $cleanRecord[$_.Name] = $_.Value
        }
    }
    $recordsToImport += $cleanRecord
}

# Save cleaned records
$recordsToImport | ConvertTo-Json -Depth 10 | Out-File -FilePath "data\products-clean.json" -Encoding UTF8

Write-Host "Cleaned $($recordsToImport.Count) records for import" -ForegroundColor Green
Write-Host ""
Write-Host "Importing via Data Loader Web or Workbench is recommended for large datasets." -ForegroundColor Yellow
Write-Host "Exported clean data to: data\products-clean.json" -ForegroundColor Cyan
Write-Host ""

# Alternative: Try importing in smaller batches
Write-Host "Would you like to try importing now? This works best for small datasets." -ForegroundColor Yellow
Write-Host "For large datasets (>200 records), use Data Loader or Workbench instead." -ForegroundColor Yellow
Write-Host ""

$response = Read-Host "Import now? (y/n)"

if ($response -eq "y" -or $response -eq "Y") {
    Write-Host ""
    Write-Host "Attempting to create records in UAT..." -ForegroundColor Yellow

    # Try creating records one by one (slow but reliable for small sets)
    $success = 0
    $failed = 0

    for ($i = 0; $i -lt [Math]::Min($recordsToImport.Count, 200); $i++) {
        $record = $recordsToImport[$i]
        $recordJson = $record | ConvertTo-Json -Compress

        # Write to temp file
        $recordJson | Out-File -FilePath "data\temp-record.json" -Encoding UTF8 -NoNewline

        # Try to insert
        sf data create record --sobject Product2 --values "@data\temp-record.json" --target-org kalanithi@cloudcompliance.app.sgpt.uat 2>&1 | Out-Null

        if ($LASTEXITCODE -eq 0) {
            $success++
            Write-Progress -Activity "Importing records" -Status "$success records imported" -PercentComplete (($i / [Math]::Min($recordsToImport.Count, 200)) * 100)
        } else {
            $failed++
        }
    }

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Import Summary" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Successfully imported: $success records" -ForegroundColor White
    Write-Host "Failed: $failed records" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "Manual import instructions:" -ForegroundColor Cyan
    Write-Host "1. Use Salesforce Data Loader or Workbench" -ForegroundColor White
    Write-Host "2. Import the file: data\products-clean.json" -ForegroundColor White
    Write-Host "3. Map fields: Name, ProductCode, Description, IsActive, Family" -ForegroundColor White
}

Write-Host ""
Write-Host "Data files created:" -ForegroundColor Cyan
Write-Host "- data\products.json (original export)" -ForegroundColor White
Write-Host "- data\products-clean.json (cleaned for import)" -ForegroundColor White
Write-Host ""
Read-Host "Press Enter to exit"
