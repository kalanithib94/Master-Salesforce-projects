// Simple test to check Named Credential
OutlookGraphPing.PingResult result = OutlookGraphPing.ping();

// Print results clearly
System.debug('==========================================');
System.debug('PING TEST RESULTS:');
System.debug('Status: ' + result.status);
System.debug('Status Code: ' + result.statusCode);
System.debug('Message: ' + result.message);
System.debug('==========================================');

if (result.statusCode == 200) {
    System.debug('✓ SUCCESS! Named Credential is configured correctly.');
} else {
    System.debug('✗ ERROR! Check the configuration.');
    System.debug('Response: ' + result.responseBody);
}

