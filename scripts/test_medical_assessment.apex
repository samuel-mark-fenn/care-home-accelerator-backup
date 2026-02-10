// Test AssessmentController
System.debug('--- Testing AssessmentController ---');

// 1. Get Residents
List<Account> residents = AssessmentController.getResidents();
System.debug('Found ' + residents.size() + ' residents.');

// 2. Get Types
List<Assessment__c> types = AssessmentController.getAssessmentTypes();
System.debug('Found ' + types.size() + ' assessment types.');

if (!residents.isEmpty() && !types.isEmpty()) {
    // 3. Submit Assessment
    Resident_Assessment__c newAss = new Resident_Assessment__c();
    newAss.Resident__c = residents[0].Id;
    newAss.Assessment__c = types[0].Id;
    newAss.Status__c = 'Scheduled';
    newAss.Medical_Needs_Assessment__c = 'Test Medical Needs';
    
    AssessmentController.submitAssessment(newAss);
    System.debug('Assessment submitted successfully: ' + newAss.Id);
} else {
    System.debug('Skipping submission - missing data required.');
}
