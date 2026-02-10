# Data Load Order

Load data in this exact order to satisfy lookup/master-detail relationships:

## Phase 1: Reference Data (No Dependencies)
1. `01-reference-data/preferences.json` - Preference__c
2. `01-reference-data/assessment-types.json` - Assessment__c
3. `01-reference-data/products.json` - Product2

## Phase 2: Properties (No Dependencies)
4. `02-properties/properties.json` - Property__c

## Phase 3: Rooms (Depends on Properties)
5. `03-rooms/rooms.json` - Room__c (→ Property__c)

## Phase 4: Accounts & Contacts
6. `04-accounts-contacts/accounts.json` - Account
7. `04-accounts-contacts/contacts.json` - Contact (→ Account)

## Phase 5: Residents (Depends on Accounts, Properties, Rooms)
8. `05-residents/residents.json` - Resident__c (→ Account, Property__c, Room__c)
9. `05-residents/resident-preferences.json` - Resident_Preference__c (→ Resident__c, Preference__c)

## Phase 6: Assessments (Depends on Residents)
10. `06-assessments/resident-assessments.json` - Resident_Assessment__c (→ Resident__c)

## Phase 7: Room Occupancy (Depends on Rooms, Residents)
11. `07-occupancy/room-occupancy.json` - Room_Occupancy__c (→ Room__c, Resident__c)

## Phase 8: Opportunities (Depends on Multiple Objects)
12. `08-opportunities/enquiries.json` - Enquiry__c (→ Property__c)
13. `08-opportunities/opportunities.json` - Opportunity (→ Account, Property__c, Room__c, Resident__c)

## Phase 9: Surveys & Contracts
14. `09-surveys/surveys.json` - Survey__c
15. `09-surveys/survey-responses.json` - Survey_Response__c (→ Survey__c, Resident__c)
16. `09-surveys/contracts.json` - Contract__c (→ Account, Resident__c, Property__c)

---

**Important Notes:**
- External IDs should be used for data loading to enable relationship mapping
- Use `sf data import tree` or SFDX Data Loader for bulk imports
- For production deployments, use incremental loads with proper validation
