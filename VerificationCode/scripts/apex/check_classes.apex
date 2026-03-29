// Check which Apex classes exist in the org and their last modified date
List<ApexClass> classes = [
    SELECT Name, Status, LastModifiedDate, LengthWithoutComments
    FROM ApexClass
    WHERE Name IN (
        'VerificationCodeService',
        'VerificationCodeGenerator',
        'VerificationCodeValidator',
        'VerificationCodeChecker',
        'VerificationCodeCleanup',
        'VerificationCodeServiceTest',
        'VerificationCodeCheckerTest'
    )
    ORDER BY Name
];
for (ApexClass c : classes) {
    System.debug('Class: ' + c.Name + ' | Status: ' + c.Status + ' | Modified: ' + c.LastModifiedDate + ' | Bytes: ' + c.LengthWithoutComments);
}
System.debug('Total classes found: ' + classes.size());
