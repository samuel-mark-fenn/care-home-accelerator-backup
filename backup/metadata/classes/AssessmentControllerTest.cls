@isTest
public class AssessmentControllerTest {
    
    @testSetup
    static void setup() {
        Account resident = new Account(Name = 'Test Resident');
        insert resident;
        
        Assessment__c assessmentType = new Assessment__c(Name = 'Clinical Assessment');
        insert assessmentType;
    }
    
    @isTest
    static void testSubmitAssessment() {
        Account resident = [SELECT Id FROM Account LIMIT 1];
        Assessment__c assessmentType = [SELECT Id FROM Assessment__c LIMIT 1];
        
        Resident_Assessment__c ra = new Resident_Assessment__c();
        ra.Resident__c = resident.Id;
        ra.Assessment__c = assessmentType.Id;
        ra.Assessment_Date__c = Date.today();
        ra.Status__c = 'Completed';
        ra.Risk_Level__c = 'Low';
        ra.Overall_Outcome__c = 'Suitable - No Concerns';
        ra.Medical_Needs_Assessment__c = 'Test medical needs';
        ra.Mobility_Assessment__c = 'Test mobility';
        ra.Nutrition_Assessment__c = 'Test nutrition';
        ra.Mental_Health_Assessment__c = 'Test mental health';
        ra.Personal_Care_Assessment__c = 'Test personal care';
        ra.Social_Needs_Assessment__c = 'Test social needs';
        ra.Follow_Up_Required__c = true;
        ra.Follow_Up_Notes__c = 'Test follow up notes';
        
        Test.startTest();
        AssessmentController.submitAssessment(ra);
        Test.stopTest();
        
        Resident_Assessment__c insertedRa = [SELECT Id, Resident__c, Assessment__c, Medical_Needs_Assessment__c, Assessor__c FROM Resident_Assessment__c LIMIT 1];
        System.assertEquals(resident.Id, insertedRa.Resident__c);
        System.assertEquals(assessmentType.Id, insertedRa.Assessment__c);
        System.assertEquals('Test medical needs', insertedRa.Medical_Needs_Assessment__c);
        System.assertEquals(UserInfo.getUserId(), insertedRa.Assessor__c, 'Assessor should be set to current user if not provided');
    }

    @isTest
    static void testGetResidents() {
        Test.startTest();
        List<Account> residents = AssessmentController.getResidents();
        Test.stopTest();
        System.assert(!residents.isEmpty());
    }

    @isTest
    static void testGetAssessmentTypes() {
        Test.startTest();
        List<Assessment__c> types = AssessmentController.getAssessmentTypes();
        Test.stopTest();
        System.assert(!types.isEmpty());
    }
}