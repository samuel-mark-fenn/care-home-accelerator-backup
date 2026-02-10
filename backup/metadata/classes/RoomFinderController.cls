public with sharing class RoomFinderController {

    @AuraEnabled(cacheable=true)
    public static List<RoomWrapper> findRooms(Id opportunityId, Id residentId, Date startDate) {
        if (startDate == null) startDate = Date.today();

        // 1. Get Opportunity Property and Resident Preferences
        Opportunity opp = [SELECT Care_Home__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
        Id propertyId = opp.Care_Home__c;

        Account resident = [SELECT Id, Requires_Ensuite__c, Prefers_Garden_View__c, Requires_Ground_Floor__c 
                                FROM Account WHERE Id = :residentId LIMIT 1];

        // 2. Query Active Rooms for the specific Property
        List<Room__c> allRooms = [
            SELECT Id, Name, Room_Type__c, Status__c, 
                   Ensuite__c, Garden_View__c, Ground_Floor__c,
                   Base_Weekly_Rate__c, Product__c, Image_URL__c,
                   Property__r.Name, Property__r.Image_URL__c, Property__r.Facilities__c
            FROM Room__c
            WHERE Availability_Status__c = 'Available'
            AND Property__c = :propertyId
        ];

        // 3. Filter by Preferences & Availability
        List<RoomWrapper> availableRooms = new List<RoomWrapper>();
        
        Set<Id> roomIds = new Map<Id, Room__c>(allRooms).keySet();
        
        // Find Occupancies checking for conflicts
        // Conflict = StartDate < ReqEnd AND EndDate > ReqStart
        // Here ReqStart = startDate, ReqEnd is indefinite/future.
        // So we look for any occupancy where EndDate > startDate (or null which means ongoing)
        List<Room_Occupancy__c> occupancies = [
            SELECT Room__c FROM Room_Occupancy__c 
            WHERE Room__c IN :roomIds 
            AND (Expected_End_Date__c > :startDate OR Expected_End_Date__c = null)
            AND (Actual_End_Date__c > :startDate OR Actual_End_Date__c = null)
        ];
        Set<Id> occupiedRoomIds = new Set<Id>();
        for (Room_Occupancy__c occ : occupancies) {
            occupiedRoomIds.add(occ.Room__c);
        }

        for (Room__c room : allRooms) {
            // Check Availability
            if (occupiedRoomIds.contains(room.Id)) continue;

            // Check Preferences (Strict match for 'Requires', loose for 'Prefers'?)
            // Let's do strict for 'Requires'
            if (resident.Requires_Ensuite__c && !room.Ensuite__c) continue;
            if (resident.Requires_Ground_Floor__c && !room.Ground_Floor__c) continue;

            // Build Wrapper
            RoomWrapper wrapper = new RoomWrapper();
            wrapper.room = room;
            wrapper.features = getFeaturesString(room);
            wrapper.isGardenView = room.Garden_View__c;
            wrapper.matchScore = (room.Garden_View__c == resident.Prefers_Garden_View__c ? 1 : 0); // Simple score
            
            // Image Fallback Logic
            if (String.isNotBlank(room.Image_URL__c)) {
                wrapper.displayImageUrl = room.Image_URL__c;
            } else if (String.isNotBlank(room.Property__r.Image_URL__c)) {
                wrapper.displayImageUrl = room.Property__r.Image_URL__c;
            }
            
            availableRooms.add(wrapper);
        }

        return availableRooms;
    }

    private static String getFeaturesString(Room__c room) {
        List<String> features = new List<String>();
        if (room.Ensuite__c) features.add('Ensuite');
        if (room.Garden_View__c) features.add('Garden View');
        if (room.Ground_Floor__c) features.add('Ground Floor');
        return String.join(features, ', ');
    }

    @AuraEnabled
    public static void confirmBooking(Id opportunityId, Id roomId, Decimal finalPrice, Date startDate, Date endDate) {
        try {
            // 1. Update Opportunity
            Opportunity opp = [SELECT Id, Amount, AccountId, Care_Home__c, 
                                     Respite_Start_Date__c, Respite_End_Date__c,
                                     Expected_Move_In_Date__c, Pricebook2Id,
                                     Resident__c, Resident__r.Name
                               FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
            opp.Amount = finalPrice;
            opp.Respite_Start_Date__c = startDate;
            opp.Respite_End_Date__c = endDate;
            
            // Ensure Pricebook is set to Standard if not set
            if (opp.Pricebook2Id == null) {
                Id stdPricebookId = Test.isRunningTest() ? Test.getStandardPricebookId() : [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id;
                opp.Pricebook2Id = stdPricebookId;
            }
            update opp;

            // Get Room Name for sensible naming
            Room__c selectedRoom = [SELECT Name FROM Room__c WHERE Id = :roomId LIMIT 1];

            // 2. Create Room Occupancy
            Room_Occupancy__c occupancy = new Room_Occupancy__c(
                Status__c = 'Reserved',
                Room__c = roomId,
                Opportunity__c = opportunityId,
                Resident__c = opp.Resident__c,
                Start_Date__c = startDate != null ? startDate : (opp.Respite_Start_Date__c != null ? opp.Respite_Start_Date__c : (opp.Expected_Move_In_Date__c != null ? opp.Expected_Move_In_Date__c : Date.today())),
                Expected_End_Date__c = endDate,
                Weekly_Rate__c = finalPrice
            );
            insert occupancy;

            // 3. Handle Product and Opportunity Line Item
            // a. Find or Create Product2 "Room Rate"
            List<Product2> products = [SELECT Id FROM Product2 WHERE Name = 'Room Rate' LIMIT 1];
            Product2 roomRateProd;
            if (products.isEmpty()) {
                roomRateProd = new Product2(Name = 'Room Rate', IsActive = true, Description = 'Night rate for the property');
                insert roomRateProd;
            } else {
                roomRateProd = products[0];
            }

            // b. Find or Create PricebookEntry for Standard Pricebook
            Id pbId = opp.Pricebook2Id;
            List<PricebookEntry> pbes = [SELECT Id FROM PricebookEntry WHERE Product2Id = :roomRateProd.Id AND Pricebook2Id = :pbId AND IsActive = true LIMIT 1];
            PricebookEntry pbe;
            if (pbes.isEmpty()) {
                pbe = new PricebookEntry(
                    Pricebook2Id = pbId,
                    Product2Id = roomRateProd.Id,
                    UnitPrice = finalPrice / 7,
                    IsActive = true
                );
                insert pbe;
            } else {
                pbe = pbes[0];
            }

            // c. Calculate Nights
            Integer nights = 1; // Default
            if (startDate != null && endDate != null) {
                nights = startDate.daysBetween(endDate);
                if (nights <= 0) nights = 1;
            } else if (opp.Respite_Start_Date__c != null && opp.Respite_End_Date__c != null) {
                nights = opp.Respite_Start_Date__c.daysBetween(opp.Respite_End_Date__c);
                if (nights <= 0) nights = 1;
            }

            // d. Create OpportunityLineItem
            OpportunityLineItem oli = new OpportunityLineItem(
                OpportunityId = opportunityId,
                PricebookEntryId = pbe.Id,
                Quantity = nights,
                UnitPrice = finalPrice / 7
            );
            insert oli;

            // 4. Create Quote
            Quote q = new Quote(
                OpportunityId = opp.Id,
                Name = 'Room Booking Quote for ' + roomId,
                Status = 'Draft',
                Pricebook2Id = pbId
            );
            insert q;

            // 5. Create Contract
            Contract c = new Contract(
                AccountId = opp.AccountId,
                StartDate = Date.today(),
                ContractTerm = 12,
                Status = 'Draft'
            );
            insert c;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error confirming booking: ' + e.getMessage());
        }
    }

    public class RoomWrapper {
        @AuraEnabled public Room__c room;
        @AuraEnabled public String features;
        @AuraEnabled public Boolean isGardenView;
        @AuraEnabled public Integer matchScore;
        @AuraEnabled public String displayImageUrl;
    }
}