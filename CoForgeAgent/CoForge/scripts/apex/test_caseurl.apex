// Quick test to verify CaseUrl is in the response
CreditLineAgenticHandler handler = new CreditLineAgenticHandler();

String testContactId = '003J900000G00dSIAR';

Map<String, Object> params = new Map<String, Object>{
    'ContactId' => testContactId,
    'RequestedAmount' => '$10,000',
    'Reason' => 'Test CaseUrl'
};

String result = handler.executeMethod('create_credit_increase_case', params);
System.debug('RESULT: ' + result);

Map<String, Object> response = (Map<String, Object>)JSON.deserializeUntyped(result);
System.debug('CaseNumber: ' + response.get('CaseNumber'));
System.debug('CaseUrl: ' + response.get('CaseUrl'));
System.debug('Has CaseUrl: ' + response.containsKey('CaseUrl'));

