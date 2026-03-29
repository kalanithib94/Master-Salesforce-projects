// Recent debug logs - shows what ran recently including flow errors
List<ApexLog> logs = [
    SELECT Id, LogLength, LastModifiedDate, Operation, Status
    FROM ApexLog
    ORDER BY LastModifiedDate DESC
    LIMIT 10
];
for (ApexLog l : logs) {
    System.debug('Log | Op: ' + l.Operation + ' | Status: ' + l.Status + ' | Bytes: ' + l.LogLength + ' | Date: ' + l.LastModifiedDate);
}
