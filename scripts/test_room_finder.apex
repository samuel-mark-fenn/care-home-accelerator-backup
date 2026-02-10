// Test Room Finder Controller
System.debug('--- Testing RoomFinderController ---');

// 1. Setup Data
Product2 rate = new Product2(Name = 'Standard Room Rate', IsActive = true);
insert rate;

Property__c prop = new Property__c(Name = 'Seaview House', Image_URL__c = 'http://example.com/photo.jpg');
insert prop;

Room__c room = new Room__c(
    Name = '101',
    Property__c = prop.Id,
    Product__c = rate.Id,
    Availability_Status__c = 'Available',
    Base_Weekly_Rate__c = 1500,
    Ensuite__c = true,
    Ground_Floor__c = true,
    Garden_View__c = true
);
insert room;

Account resident = new Account(
    Name = 'Mrs. Smith',
    Requires_Ensuite__c = true,
    Requires_Ground_Floor__c = true
);
insert resident;

Opportunity opp = new Opportunity(
    Name = 'Smith Enquiry',
    StageName = 'Prospecting',
    CloseDate = Date.today().addDays(30),
    AccountId = resident.Id
);
insert opp;

System.debug('Data Setup Complete. Room: ' + room.Id + ', Opp: ' + opp.Id);

// 2. Test findRooms
List<RoomFinderController.RoomWrapper> results = RoomFinderController.findRooms(resident.Id, Date.today());
System.debug('Found ' + results.size() + ' rooms.');

if (!results.isEmpty()) {
    RoomFinderController.RoomWrapper match = results[0];
    System.debug('Match: ' + match.room.Name + ' | Score: ' + match.matchScore);
    System.assertEquals(true, match.room.Ensuite__c);
    
    // 3. Test confirmBooking
    Decimal finalPrice = 1450.00;
    RoomFinderController.confirmBooking(opp.Id, match.room.Id, finalPrice);
    
    // Validate
    Opportunity updatedOpp = [SELECT Amount FROM Opportunity WHERE Id = :opp.Id];
    System.assertEquals(finalPrice, updatedOpp.Amount);
    System.debug('Opp Amount Updated: ' + updatedOpp.Amount);
    
    List<Quote> quotes = [SELECT Id, Status FROM Quote WHERE OpportunityId = :opp.Id];
    System.assertEquals(1, quotes.size());
    System.debug('Quote Created: ' + quotes[0].Id);
    
    List<Contract> contracts = [SELECT Id, Status FROM Contract WHERE AccountId = :resident.Id];
    System.assertEquals(1, contracts.size());
    System.debug('Contract Created: ' + contracts[0].Id);
    
    System.debug('--- VERIFICATION SUCCESSFUL ---');
} else {
    System.debug('--- VERIFICATION FAILED: No rooms found ---');
}
