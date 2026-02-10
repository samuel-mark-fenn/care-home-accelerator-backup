Opportunity testOpp = [SELECT Id FROM Opportunity WHERE Resident__c != null AND Care_Home__c != null LIMIT 1];
Room__c testRoom = [SELECT Id FROM Room__c WHERE Property__c != null LIMIT 1];
Date startDate = Date.today().addDays(7);
Decimal price = 1500.00;

System.debug('--- VERIFICATION START ---');
try {
    System.debug('Target Opp ID: ' + testOpp.Id);
    System.debug('Target Room ID: ' + testRoom.Id);
    
    RoomFinderController.confirmBooking(testOpp.Id, testRoom.Id, price, startDate, startDate.addMonths(1));
    
    Opportunity updatedOpp = [SELECT Preferred_Room__c, Allocated_Room__c, Room_Allocation_Date__c, Room_Ready_Date__c, Actual_Move_In_Date__c, Move_In_Checklist_Complete__c FROM Opportunity WHERE Id = :testOpp.Id];
    
    System.debug('Preferred_Room__c: ' + updatedOpp.Preferred_Room__c);
    System.debug('Allocated_Room__c: ' + updatedOpp.Allocated_Room__c);
    System.debug('Room_Allocation_Date__c: ' + updatedOpp.Room_Allocation_Date__c);
    System.debug('Room_Ready_Date__c: ' + updatedOpp.Room_Ready_Date__c);
    System.debug('Move_In_Checklist_Complete__c: ' + updatedOpp.Move_In_Checklist_Complete__c);
    System.debug('Actual_Move_In_Date__c: ' + updatedOpp.Actual_Move_In_Date__c);

} catch (Exception e) {
    System.debug('Error during verification: ' + e.getMessage());
}
System.debug('--- VERIFICATION END ---');
