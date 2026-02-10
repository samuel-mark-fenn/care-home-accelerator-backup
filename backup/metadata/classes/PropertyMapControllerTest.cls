@IsTest
public class PropertyMapControllerTest {
    
    @TestSetup
    static void setup() {
        Property__c prop = new Property__c(
            Name = 'Test Property',
            Postcode__c = 'BH1 1AA',
            Care_Types_Offered__c = 'Residential;Nursing'
        );
        insert prop;

        Room__c room1 = new Room__c(
            Name = 'Room 1',
            Property__c = prop.Id,
            Availability_Status__c = 'Available'
        );
        Room__c room2 = new Room__c(
            Name = 'Room 2',
            Property__c = prop.Id,
            Availability_Status__c = 'Occupied'
        );
        insert new List<Room__c>{ room1, room2 };
    }

    @IsTest
    static void testGetProperties() {
        Test.startTest();
        List<PropertyMapController.PropertyWrapper> results = PropertyMapController.getProperties();
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'Should return one property');
        Assert.areEqual('Test Property', results[0].name);
        Assert.areEqual('BH1 1AA', results[0].postcode);
        Assert.isNotNull(results[0].availableRooms, 'Available rooms should be populated');
    }
}