@echo off
REM Complete script to migrate Product2 records from QA to UAT

echo ========================================
echo Product2 Migration: QA to UAT
echo ========================================
echo.

REM Create data directory if it doesn't exist
if not exist "data" mkdir data

echo [Step 1/3] Exporting Product2 records from sgpt-qa...
echo.

REM Export Product2 records using data export tree
sf data export tree --query "SELECT Name, ProductCode, Description, IsActive, Family, ExternalId, ExternalDataSourceId, DisplayUrl, QuantityUnitOfMeasure, StockKeepingUnit FROM Product2 WHERE IsActive = true" --target-org kalanithi@cloudcompliance.app.sgpt-qa --output-dir data --plan

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to export Product2 records!
    pause
    exit /b 1
)

echo.
echo [Step 2/3] Product2 records exported successfully!
echo.
echo [Step 3/3] Importing Product2 records into sgpt-uat...
echo.

REM Import Product2 records into UAT org
sf data import tree --plan data\Product2-plan.json --target-org kalanithi@cloudcompliance.app.sgpt.uat

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to import Product2 records!
    pause
    exit /b 1
)

echo.
echo ========================================
echo Migration completed successfully!
echo ========================================
echo.
echo Please verify the Product2 records in your UAT org.
pause
