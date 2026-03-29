# Simple Product2 Import Script
Write-Host "Automated Product2 Import to UAT" -ForegroundColor Cyan
Write-Host ""

Set-Location "c:\CC\Project_SFDC\QA to UAT\QA to UAT"

# Load records
$records = Get-Content "data\products-clean.json" -Raw | ConvertFrom-Json
$total = $records.Count
Write-Host "Loading $total records..." -ForegroundColor Yellow
Write-Host ""

# Counters
$success = 0
$failed = 0
$skipped = 0

# Import each record
foreach ($record in $records) {
    $name = if ($record.Name) { $record.Name } else { "Unknown" }

    # Build values
    $vals = @()
    if ($record.Name) { $vals += "Name='$($record.Name)'" }
    if ($record.ProductCode) { $vals += "ProductCode='$($record.ProductCode)'" }
    if ($record.IsActive -ne $null) { $vals += "IsActive=$($record.IsActive.ToString().ToLower())" }
    if ($record.Family) { $vals += "Family='$($record.Family)'" }

    $valStr = $vals -join " "

    # Create record
    $output = sf data create record --sobject Product2 --values $valStr --target-org kalanithi@cloudcompliance.app.sgpt.uat 2>&1

    if ($LASTEXITCODE -eq 0) {
        $success++
        Write-Host "OK: $name" -ForegroundColor Green
    } elseif ($output -match "duplicate") {
        $skipped++
        Write-Host "SKIP: $name" -ForegroundColor Yellow
    } else {
        $failed++
        Write-Host "FAIL: $name" -ForegroundColor Red
    }

    # Progress
    if (($success + $failed + $skipped) % 10 -eq 0) {
        $pct = [Math]::Round((($success + $failed + $skipped) / $total) * 100)
        Write-Host "Progress: $pct% (OK:$success SKIP:$skipped FAIL:$failed)" -ForegroundColor Cyan
    }
}

# Summary
Write-Host ""
Write-Host "===== COMPLETE =====" -ForegroundColor Green
Write-Host "Created: $success" -ForegroundColor Green
Write-Host "Skipped: $skipped" -ForegroundColor Yellow
Write-Host "Failed: $failed" -ForegroundColor Red
Write-Host ""
