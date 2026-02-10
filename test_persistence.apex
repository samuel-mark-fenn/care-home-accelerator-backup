Opportunity testOpp = [SELECT Id FROM Opportunity WHERE Resident__c != null AND Care_Home__c != null LIMIT 1];
Room__c testRoom = [SELECT Id FROM Room__c WHERE Property__c != null LIMIT 1];
Date d = Date.today();

testOpp.Allocated_Room__c = testRoom.Id;
testOpp.Room_Allocation_Date__c = d;
testOpp.Room_Ready_Date__c = d;
update testOpp;

Opportunity updatedOpp = [SELECT Allocated_Room__c, Room_Allocation_Date__c, Room_Ready_Date__c FROM Opportunity WHERE Id = :testOpp.Id];
System.debug('--- SIMPLE PERSISTENCE TEST ---');
System.debug('Allocated_Room__c: ' + updatedOpp.Allocated_Room__c);
System.debug('Room_Allocation_Date__c: ' + updatedOpp.Room_Allocation_Date__c);
System.debug('Room_Ready_Date__c: ' + updatedOpp.Room_Ready_Date__c);
System.debug('--- END TEST ---');
