public with sharing class ResidentSurveyController {
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getInitialData(String opportunityId) {
        Map<String, String> result = new Map<String, String>();
        
        // Get Resident from Opportunity
        Opportunity opp = [SELECT Resident__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
        if (opp.Resident__c != null) {
            result.put('residentId', opp.Resident__c);
        }
        
        // Get latest Survey
        // Assuming we just want the most recently created active survey or similar logic. 
        // For now, just getting the latest one created.
        List<Survey__c> surveys = [SELECT Id, Name FROM Survey__c ORDER BY CreatedDate DESC LIMIT 1];
        if (!surveys.isEmpty()) {
            result.put('surveyId', surveys[0].Id);
            result.put('surveyName', surveys[0].Name);
        }
        
        return result;
    }

    @AuraEnabled
    public static void saveSurveyResponse(Survey_Response__c response) {
        try {
            insert response;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}