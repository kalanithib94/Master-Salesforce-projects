// Reproduce create_contact AccountId failure modes seen in agent chat
ContactAgenticSkillsHandler h = new ContactAgenticSkillsHandler();

System.debug('=== TEST 1: FirstName+LastName + userContextId only ===');
String r1 = h.executeMethod('create_contact', new Map<String, Object>{
  'FirstName' => 'Priya',
  'LastName' => 'KhannaSmoke1',
  'userContextId' => 'conv_3801kv52phh9f299ys583b2r4bz4'
});
System.debug(r1);

System.debug('=== TEST 2: blank AccountId ===');
String r2 = h.executeMethod('create_contact', new Map<String, Object>{
  'FirstName' => 'Priya',
  'LastName' => 'KhannaSmoke2',
  'AccountId' => '',
  'userContextId' => 'conv_test'
});
System.debug(r2);

System.debug('=== TEST 3: invalid AccountId (conversation id) ===');
String r3 = h.executeMethod('create_contact', new Map<String, Object>{
  'FirstName' => 'Priya',
  'LastName' => 'KhannaSmoke3',
  'AccountId' => 'conv_3801kv52phh9f299ys583b2r4bz4'
});
System.debug(r3);

Contact existing = [SELECT Id FROM Contact LIMIT 1];
System.debug('=== TEST 4: AccountId = Contact Id (wrong type) ===');
String r4 = h.executeMethod('create_contact', new Map<String, Object>{
  'FirstName' => 'Priya',
  'LastName' => 'KhannaSmoke4',
  'AccountId' => String.valueOf(existing.Id)
});
System.debug(r4);

System.debug('=== TEST 5: AccountId null ===');
String r5 = h.executeMethod('create_contact', new Map<String, Object>{
  'FirstName' => 'Priya',
  'LastName' => 'KhannaSmoke5',
  'AccountId' => null
});
System.debug(r5);

System.debug('=== TEST 6: injected recordId key (Contact Id) ===');
String r6 = h.executeMethod('create_contact', new Map<String, Object>{
  'FirstName' => 'Priya',
  'LastName' => 'KhannaSmoke6',
  'recordId' => String.valueOf(existing.Id),
  'userContextId' => 'conv_x'
});
System.debug(r6);

System.debug('=== TEST 7: AccountId = "null" string ===');
String r7 = h.executeMethod('create_contact', new Map<String, Object>{
  'FirstName' => 'Priya',
  'LastName' => 'KhannaSmoke7',
  'AccountId' => 'null'
});
System.debug(r7);
