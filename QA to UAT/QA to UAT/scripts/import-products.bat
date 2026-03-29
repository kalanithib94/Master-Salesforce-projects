@echo off
REM Script to import Product2 records into UAT org

echo Importing Product2 records into sgpt-uat org...

REM Check if export file exists
if not exist "data\products-export.csv" (
    echo ERROR: data\products-export.csv not found!
    echo Please run export-products.bat first.
    pause
    exit /b 1
)

REM Create a clean import file without Id column (for new records)
REM Note: You may need to manually edit the CSV to remove Id column or handle duplicates

echo.
echo Importing Product2 records...
sf data import tree --plan data\product-import-plan.json --target-org kalanithi@cloudcompliance.app.sgpt.uat

echo.
echo Import complete!
echo Please verify the records in your UAT org.
pause
