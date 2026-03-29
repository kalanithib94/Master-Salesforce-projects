// List all field names on Verification_Code__c so we know what actually exists
Schema.DescribeSObjectResult d = Schema.SObjectType.Verification_Code__c;
Map<String, Schema.SObjectField> fields = d.fields.getMap();
List<String> names = new List<String>(fields.keySet());
names.sort();
for (String f : names) {
    System.debug('Field: ' + f);
}
System.debug('Total fields: ' + names.size());
