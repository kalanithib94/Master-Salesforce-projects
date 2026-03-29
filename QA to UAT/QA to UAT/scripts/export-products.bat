@echo off
REM Script to export Product2 records from QA org

echo Exporting Product2 records from sgpt-qa org...

REM Create data directory if it doesn't exist
if not exist "data" mkdir data

REM Export Product2 records to JSON
sf data query --query "SELECT Id, Name, ProductCode, Description, IsActive, Family, ExternalId, ExternalDataSourceId, DisplayUrl, QuantityUnitOfMeasure, StockKeepingUnit FROM Product2 WHERE IsActive = true" --target-org kalanithi@cloudcompliance.app.sgpt-qa --result-format json > data\products-export.json

echo Product2 records exported to data\products-export.json
echo.
echo Converting to CSV format for better readability...

REM Also export to CSV format
sf data query --query "SELECT Id, Name, ProductCode, Description, IsActive, Family, ExternalId, ExternalDataSourceId, DisplayUrl, QuantityUnitOfMeasure, StockKeepingUnit FROM Product2 WHERE IsActive = true" --target-org kalanithi@cloudcompliance.app.sgpt-qa --result-format csv > data\products-export.csv

echo Product2 records also exported to data\products-export.csv
echo Export complete!
pause
