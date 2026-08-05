Account a = [SELECT Id FROM Account LIMIT 1];
GenericAgenticSkillsHandler h = new GenericAgenticSkillsHandler();
String r = h.executeMethod('fetch_session_context', new Map<String, Object>{
    'userContextId' => 'test_conv_123',
    'record_id' => a.Id
});
System.debug('RESULT=' + r);
