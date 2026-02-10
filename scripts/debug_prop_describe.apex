Map<String, Schema.SObjectField> fields = Schema.SObjectType.Property__c.fields.getMap();
System.debug('--- Fields for Property__c ---');
for (String f : fields.keySet()) {
    System.debug(f);
}
