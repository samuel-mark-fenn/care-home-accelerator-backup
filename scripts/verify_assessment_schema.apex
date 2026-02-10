// Verify Assessment Schema
System.debug('--- Assessment Refactor Verification ---');

// 1. Create Archetype
Assessment__c archetype = new Assessment__c(
    Name = 'Initial Admission Assessment',
    Type__c = 'Initial', // Assuming 'Initial' is a valid picklist value or it was text?
    Description__c = 'Standard initial assessment for new residents.'
);
insert archetype;
System.debug('Created Archetype: ' + archetype.Id);

// 2. Create Resident (Account)
Account resident = new Account(Name = 'Test Resident Household');
insert resident;
System.debug('Created Resident: ' + resident.Id);

// 3. Create Instance
Resident_Assessment__c instance = new Resident_Assessment__c();
// Name is AutoNumber, so no set Name
instance.Assessment__c = archetype.Id; // Link to Archetype
instance.Resident__c = resident.Id;
instance.Assessment_Date__c = Date.today();
instance.Status__c = 'Scheduled';

insert instance;
System.debug('Created Instance: ' + instance.Id);

// Verify fields
Resident_Assessment__c query = [SELECT Id, Assessment__r.Name, Resident__r.Name FROM Resident_Assessment__c WHERE Id = :instance.Id];
System.assertEquals('Initial Admission Assessment', query.Assessment__r.Name);
System.assertEquals('Test Resident Household', query.Resident__r.Name);

System.debug('--- VERIFICATION SUCCESSFUL ---');
