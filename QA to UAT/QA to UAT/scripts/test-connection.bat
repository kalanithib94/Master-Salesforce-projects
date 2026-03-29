@echo off
echo Testing connection and querying Product2 records...
echo.
sf data query --query "SELECT Id, Name, ProductCode, IsActive FROM Product2 WHERE IsActive = true LIMIT 5" --target-org kalanithi@cloudcompliance.app.sgpt-qa --result-format human
pause
