try {
    List<Room__c> rooms = [SELECT Id, Name, Status__c, Base_Weekly_Rate__c FROM Room__c LIMIT 1];
    System.debug('Rooms found: ' + rooms.size());
    if (!rooms.isEmpty()) {
        System.debug('Room 0 Status: ' + rooms[0].Status__c);
    }
} catch (Exception e) {
    System.debug('Error: ' + e.getMessage());
}
