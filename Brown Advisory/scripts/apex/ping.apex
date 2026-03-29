OutlookGraphPing.PingResult result = OutlookGraphPing.ping();
System.debug('Status: ' + result.status);
System.debug('Message: ' + result.message);
System.debug('Response: ' + result.responseBody);

