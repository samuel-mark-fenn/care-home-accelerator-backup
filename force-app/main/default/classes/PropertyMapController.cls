public with sharing class PropertyMapController {
    
    @AuraEnabled(cacheable=true)
    public static List<PropertyWrapper> getProperties() {
        List<Property__c> properties = [
            SELECT Id, Name, Postcode__c, Care_Types_Offered__c, 
                   Manager__r.Name, 
                   Total_Available_Rooms__c
            FROM Property__c
            WHERE Postcode__c != null
        ];

        List<PropertyWrapper> wrappers = new List<PropertyWrapper>();
        for (Property__c prop : properties) {
            wrappers.add(new PropertyWrapper(prop));
        }
        return wrappers;
    }

    public class PropertyWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String postcode;
        @AuraEnabled public String careTypes;
        @AuraEnabled public String managerName;
        @AuraEnabled public Integer availableRooms;

        public PropertyWrapper(Property__c prop) {
            this.id = prop.Id;
            this.name = prop.Name;
            this.postcode = prop.Postcode__c;
            this.careTypes = prop.Care_Types_Offered__c;
            this.managerName = prop.Manager__r != null ? prop.Manager__r.Name : 'N/A';
            this.availableRooms = prop.Total_Available_Rooms__c != null ? (Integer)prop.Total_Available_Rooms__c : 0;
        }
    }
}
