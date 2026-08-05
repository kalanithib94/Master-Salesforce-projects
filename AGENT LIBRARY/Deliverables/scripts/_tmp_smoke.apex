Map<String, Object> p = new Map<String, Object>();
p.put('searchTerm', 'Test');
p.put('limitSize', 5);
String result = new AccountAgenticSkillsHandler().executeMethod('fuzzy_search_accounts', p);
System.debug('HANDLER_RESULT=' + (result == null ? 'null' : result.left(800)));
