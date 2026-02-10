public with sharing class AssessmentController {
    
    @AuraEnabled(cacheable=true)
    public static List<Account> getResidents() {
        // Assuming 'Resident' is a likely RecordType or just all Accounts for now.
        // In a real scenario, we might filter by RecordType or a 'Type' field.
        return [SELECT Id, Name FROM Account ORDER BY Name ASC LIMIT 100];
    }

    @AuraEnabled(cacheable=true)
    public static List<Assessment__c> getAssessmentTypes() {
        return [SELECT Id, Name, Description__c FROM Assessment__c ORDER BY Name ASC];
    }

    @AuraEnabled
    public static void submitAssessment(Resident_Assessment__c assessment) {
        try {
            // Ensure Assessor is set to current user if not provided
            if (assessment.Assessor__c == null) {
                assessment.Assessor__c = UserInfo.getUserId();
            }
            // Ensure Date is set to today if not provided
            if (assessment.Assessment_Date__c == null) {
                assessment.Assessment_Date__c = Date.today();
            }
            
            insert assessment;
        } catch (Exception e) {
            throw new AuraHandledException('Error submitting assessment: ' + e.getMessage());
        }
    }
}