Map<String, Schema.SObjectField> fields = Schema.SObjectType.Room__c.fields.getMap();
System.debug('--- Fields for Room__c ---');
for (String f : fields.keySet()) {
    System.debug(f);
}
