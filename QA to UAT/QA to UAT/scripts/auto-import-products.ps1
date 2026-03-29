# Automated Product2 Import Script - Batch Processing
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Automated Product2 Import to UAT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$ErrorActionPreference = "Continue"
Set-Location "c:\CC\Project_SFDC\QA to UAT\QA to UAT"

# Check if clean JSON exists
if (!(Test-Path "data\products-clean.json")) {
    Write-Host "ERROR: data\products-clean.json not found!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Load the records
Write-Host "Loading records from data\products-clean.json..." -ForegroundColor Yellow
$records = Get-Content "data\products-clean.json" -Raw | ConvertFrom-Json
$totalRecords = $records.Count

Write-Host "Found $totalRecords records to import" -ForegroundColor Green
Write-Host ""

# Import statistics
$success = 0
$failed = 0
$skipped = 0
$batchSize = 10
$batchNumber = 1

Write-Host "Starting import in batches of $batchSize..." -ForegroundColor Yellow
Write-Host ""

# Process in batches
for ($i = 0; $i -lt $totalRecords; $i += $batchSize) {
    $batchEnd = [Math]::Min($i + $batchSize, $totalRecords)
    $currentBatch = $records[$i..($batchEnd - 1)]

    Write-Host "Processing batch $batchNumber (records $($i + 1) to $batchEnd)..." -ForegroundColor Cyan

    foreach ($record in $currentBatch) {
        # Build the record values string
        $values = @()

        if ($record.Name) { $values += "Name=`"$($record.Name -replace '"', '\"')`"" }
        if ($record.ProductCode) { $values += "ProductCode=`"$($record.ProductCode -replace '"', '\"')`"" }
        if ($record.Description) { $values += "Description=`"$($record.Description -replace '"', '\"')`"" }
        if ($record.IsActive -ne $null) { $values += "IsActive=$($record.IsActive.ToString().ToLower())" }
        if ($record.Family) { $values += "Family=`"$($record.Family -replace '"', '\"')`"" }

        $valuesString = $values -join " "

        # Try to create the record
        try {
            $result = sf data create record --sobject Product2 --values $valuesString --target-org kalanithi@cloudcompliance.app.sgpt.uat --json 2>&1

            if ($LASTEXITCODE -eq 0) {
                $success++
                Write-Host "  ✓ Created: $($record.Name)" -ForegroundColor Green
            } else {
                # Check if it's a duplicate error
                if ($result -match "duplicate" -or $result -match "DUPLICATE") {
                    $skipped++
                    Write-Host "  ⊘ Skipped (duplicate): $($record.Name)" -ForegroundColor Yellow
                } else {
                    $failed++
                    Write-Host "  ✗ Failed: $($record.Name)" -ForegroundColor Red
                }
            }
        } catch {
            $failed++
            Write-Host "  ✗ Error: $($record.Name) - $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Write-Host ""
    $batchNumber++

    # Progress update
    $percentComplete = [Math]::Round(($batchEnd / $totalRecords) * 100, 1)
    Write-Host "Progress: $percentComplete% - Created: $success, Skipped: $skipped, Failed: $failed" -ForegroundColor White
    Write-Host ""
}

# Final summary
Write-Host "========================================" -ForegroundColor Green
Write-Host "Import Completed!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Total records processed: $totalRecords" -ForegroundColor White
Write-Host "  Successfully created: $success" -ForegroundColor Green
Write-Host "  Skipped (duplicates): $skipped" -ForegroundColor Yellow
Write-Host "  Failed: $failed" -ForegroundColor Red
Write-Host ""

if ($success -gt 0) {
    Write-Host "✅ Successfully imported $success Product2 records to UAT!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Login to your UAT org: https://sgpt-uat-dev-ed.develop.my.salesforce.com" -ForegroundColor White
    Write-Host "2. Navigate to: App Launcher > Products" -ForegroundColor White
    Write-Host "3. Verify the imported records" -ForegroundColor White
} else {
    Write-Host "⚠️ No records were imported successfully." -ForegroundColor Yellow
    Write-Host "Check the error messages above for details." -ForegroundColor Yellow
}

Write-Host ""
Read-Host "Press Enter to exit"
