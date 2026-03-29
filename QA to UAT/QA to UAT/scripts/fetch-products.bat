@echo off
cd /d "c:\CC\Project_SFDC\QA to UAT\QA to UAT"
if not exist "data" mkdir data
echo Fetching Product2 records from QA org...
sf data query --query "SELECT Id, Name, ProductCode, Description, IsActive, Family FROM Product2 WHERE IsActive = true" --target-org kalanithi@cloudcompliance.app.sgpt-qa --result-format json > data\products-qa.json
echo Done! Check data\products-qa.json
