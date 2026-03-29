// Check org namespace
System.debug('Org namespace: [' + UserInfo.getOrganizationName() + ']');
Organization org = [SELECT Id, Name, NamespacePrefix FROM Organization LIMIT 1];
System.debug('Org NamespacePrefix: [' + org.NamespacePrefix + ']');

// Describe the object and list ALL field API names (as stored)
Schema.DescribeSObjectResult d = Schema.SObjectType.Verification_Code__c;
System.debug('Object label: ' + d.getLabel() + ' | API: ' + d.getName());
Map<String, Schema.SObjectField> fields = d.fields.getMap();
for (String f : fields.keySet()) {
    Schema.DescribeFieldResult fr = fields.get(f).getDescribe();
    System.debug('  field: ' + f + ' → label: ' + fr.getLabel() + ' | name: ' + fr.getName());
}
