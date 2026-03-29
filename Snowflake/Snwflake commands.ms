CREATE DATABASE TESTDB

Create SCHEMA MYSCHEMA

create or replace TABLE TESTDB.MYSCHEMA.DEPARTMENT (
	DID NUMBER(38,0) NOT NULL,
	DEPARTMENTNAME VARCHAR(25) NOT NULL,
	LOCATION VARCHAR(25),
	CREATEDDATE DATE DEFAULT CURRENT_DATE(),
    EXTERNALID VARCHAR(255),
	unique (DID)
);

CREATE OR REPLACE TABLE TESTDB.myschema.Employee (EID Number NOT NULL unique,
  EmployeeName VARChar(25) NOT NULL,
  Email Varchar(25) DEFAULT NULL,
  jobtitle VARCHAR(25) DEFAULT NULL,
  department_id Number NOT NULL unique,
  CreatedDate Date default current_date()
)

alter table TESTDB.myschema.Employee
ADD FOREIGN KEY(department_id) 
REFERENCES  TESTDB.myschema.Department(DID) 


INSERT INTO TESTDB.myschema.Department (DID,DepartmentName,location) values (101,'Sales','Floor 1');
INSERT INTO TESTDB.myschema.Department (DID,DepartmentName,location) values (102,'Marketing','Floor 3');
INSERT INTO TESTDB.myschema.Department (DID,DepartmentName,location) values (103,'Engineering','Floor 7');
INSERT INTO TESTDB.myschema.Department (DID,DepartmentName,location) values (104,'Customer Service','Floor 2');
INSERT INTO TESTDB.myschema.Department (DID,DepartmentName,location) values (105,'Finance','Floor 4');
INSERT INTO TESTDB.myschema.Department (DID,DepartmentName,location,externalid) values (106,'Finance','Floor 5','0018d00000eE0CFAA0');


Select * from TESTDB.myschema.Department

SELECT * FROM Department Where ExternalId='0018d00000eE0CFAA0'

upsert into 


INSERT INTO TESTDB.myschema.Employee (EID,EmployeeName,Email,jobtitle,department_id) values (201,'TestName1','testName1@test.com','Software Engineer',103);
INSERT INTO TESTDB.myschema.Employee (EID,EmployeeName,Email,jobtitle,department_id) values (202,'TestName2','testName2@test.com','Marketing Manager',102);
INSERT INTO TESTDB.myschema.Employee (EID,EmployeeName,Email,jobtitle,department_id) values (203,'TestName3','testName3@test.com','Finance',105);
INSERT INTO TESTDB.myschema.Employee (EID,EmployeeName,Email,jobtitle,department_id) values (204,'TestName4','testName4@test.com','Customer Service',104);
INSERT INTO TESTDB.myschema.Employee (EID, EMPLOYEENAME, EMAIL, JOBTITLE, DEPARTMENT_ID) VALUES (205, 'TestName5', 'testName5@test.com', 'Software Engineer', 103);
INSERT INTO TESTDB.myschema.Employee (EID, EMPLOYEENAME, EMAIL, JOBTITLE, DEPARTMENT_ID) VALUES (206, 'TestName6', 'testName6@test.com', 'Marketing Manager', 102);
INSERT INTO TESTDB.myschema.Employee (EID, EMPLOYEENAME, EMAIL, JOBTITLE, DEPARTMENT_ID) VALUES (207, 'TestName7', 'testName7@test.com', 'Salesman', 101);
INSERT INTO TESTDB.myschema.Employee (EID, EMPLOYEENAME, EMAIL, JOBTITLE, DEPARTMENT_ID)VALUES (215, 'TestName15', 'testName15@test.com', 'Finance', 105);
INSERT INTO TESTDB.myschema.Employee (EID, EMPLOYEENAME, EMAIL, JOBTITLE, DEPARTMENT_ID)VALUES (215, 'TestName1225', 'testName15@test.com', 'Finance', 106);
INSERT INTO TESTDB.myschema.Employee (EID, EMPLOYEENAME, EMAIL, JOBTITLE, DEPARTMENT_ID)VALUES (215, 'TestName1235', 'testName15@test.com', 'Finance', 106);

Select * from TESTDB.myschema.Employee



SELECT t1.id, t1.name, t2.details FROM Employee t1 INNER JOIN Department t2 ON t1.department_id = t2.did LIMIT 100



Create OR replace SECURITY INTEGRATION MY_SNOWSQL_CLIENT
TYPE = OAUTH
ENABLED = TRUE
OAUTH_CLIENT = CUSTOM
OAUTH_CLIENT_TYPE = 'CONFIDENTIAL'
OAUTH_REDIRECT_URI = 'https://sgpt-dev-dev-ed.develop.my.salesforce.com/services/authcallback/SnowflakeDS'
OAUTH_ISSUE_REFRESH_TOKENS = TRUE
OAUTH_REFRESH_TOKEN_VALIDITY = 7776000
;

DESC SECURITY INTEGRATION MY_SNOWSQL_CLIENT;

select SYSTEM$SHOW_OAUTH_CLIENT_SECRETS( 'MY_SNOWSQL_CLIENT' );






Create OR replace SECURITY INTEGRATION MY_SNOWSQL_CLIENT_DEVORG
TYPE = OAUTH
ENABLED = TRUE
OAUTH_CLIENT = CUSTOM
OAUTH_CLIENT_TYPE = 'CONFIDENTIAL'
OAUTH_REDIRECT_URI = 'https://sgpt-dev-dev-ed.develop.my.salesforce.com/services/authcallback/Snowflake'
OAUTH_ISSUE_REFRESH_TOKENS = TRUE
OAUTH_REFRESH_TOKEN_VALIDITY = 7776000
;

DESC SECURITY INTEGRATION MY_SNOWSQL_CLIENT_DEVORG;

select SYSTEM$SHOW_OAUTH_CLIENT_SECRETS( 'MY_SNOWSQL_CLIENT_DEVORG' );
