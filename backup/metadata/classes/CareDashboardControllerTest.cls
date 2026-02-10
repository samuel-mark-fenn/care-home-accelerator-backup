@IsTest
private class CareDashboardControllerTest {
    @TestSetup
    static void setup() {
        // Create Property
        Property__c prop = new Property__c(Name = 'Test Home');
        insert prop;
        
        // Create Rooms
        List<Room__c> rooms = new List<Room__c>{
            new Room__c(Name = 'Room 1', Property__c = prop.Id, Availability_Status__c = 'Available'),
            new Room__c(Name = 'Room 2', Property__c = prop.Id, Availability_Status__c = 'Occupied'),
            new Room__c(Name = 'Room 3', Property__c = prop.Id, Availability_Status__c = 'Occupied')
        };
        insert rooms;
        
        // Create Opportunities
        List<Opportunity> opps = new List<Opportunity>{
            new Opportunity(Name = 'Opp 1', StageName = 'Prospecting', CloseDate = Date.today().addDays(30)),
            new Opportunity(Name = 'Opp 2', StageName = 'Prospecting', CloseDate = Date.today().addDays(30)),
            new Opportunity(Name = 'Opp 3', StageName = 'Qualification', CloseDate = Date.today().addDays(30))
        };
        insert opps;
    }
    
    @IsTest
    static void testGetDashboardData() {
        Test.startTest();
        CareDashboardController.DashboardData data = CareDashboardController.getDashboardData();
        Test.stopTest();
        
        System.assertNotEquals(null, data, 'Data should not be null');
        System.assertEquals(3, data.totalRooms);
        System.assertEquals(2, data.occupiedRooms);
        System.assertEquals(66.7, data.occupancyRate);
        System.assert(data.pipeline.size() > 0, 'Pipeline data should be present');
    }
}