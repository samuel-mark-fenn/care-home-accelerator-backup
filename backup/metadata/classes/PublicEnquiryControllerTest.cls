@IsTest
public class PublicEnquiryControllerTest {
  @IsTest
  static void testSubmitEnquiry() {
    Property__c prop = new Property__c(Name = 'Test Home');
    insert prop;

    Map<String, Object> formData = new Map<String, Object>{
      'firstName' => 'John',
      'lastName' => 'Doe',
      'email' => 'john.doe@example.com',
      'phone' => '1234567890',
      'enquiryType' => 'Looking for care for a loved one',
      'source' => 'Google',
      'message' => 'Need help for my dad',
      'admissionType' => 'First Respite',
      'residentName' => 'Robert Doe',
      'respiteStartDate' => String.valueOf(Date.today().addDays(7)),
      'respiteEndDate' => String.valueOf(Date.today().addDays(14)),
      'interests' => 'Gardening, Reading',
      'needs' => 'Mobility help',
      'careHomeId' => prop.Id
    };

    Test.startTest();
    PublicEnquiryController.submitEnquiry(formData);
    Test.stopTest();

    // Verify Enquirer Contact
    Contact c = [
      SELECT Id, FirstName, LastName, AccountId
      FROM Contact
      WHERE Email = 'john.doe@example.com'
      LIMIT 1
    ];
    Assert.areEqual('John', c.FirstName);

    // Verify Resident Account
    Account resAcc = [
      SELECT Id, Name
      FROM Account
      WHERE Name = 'Robert Doe'
      LIMIT 1
    ];
    Assert.areEqual('Robert Doe', resAcc.Name);

    // Verify Opportunity
    Opportunity opp = [
      SELECT Id, Name, Admission_Type__c, Respite_Start_Date__c, Resident__c, Care_Home__c, Enquiry_Level__c, RecordType.DeveloperName
      FROM Opportunity
      WHERE Resident__c = :resAcc.Id
      LIMIT 1
    ];
    Assert.areEqual('Robert Doe - Care Enquiry', opp.Name);
    Assert.areEqual('First Respite', opp.Admission_Type__c);
    Assert.areEqual('Care_Home_Enquiry', opp.RecordType.DeveloperName);
    Assert.areEqual(Date.today().addDays(7), opp.Respite_Start_Date__c);
    Assert.areEqual(prop.Id, opp.Care_Home__c);
    Assert.areEqual('Level 1: Expected admission within one to two weeks.', opp.Enquiry_Level__c);

    // Verify Preferences
    List<Preference__c> prefs = [SELECT Id, Name FROM Preference__c];
    Assert.isTrue(
      prefs.size() >= 3,
      'Should have created at least 3 preferences'
    );

    List<Resident_Preference__c> resPrefs = [
      SELECT Id, Type__c
      FROM Resident_Preference__c
      WHERE Resident__c = :resAcc.Id
    ];
    Assert.areEqual(3, resPrefs.size());
  }

  @IsTest
  static void testGetProperties() {
    Property__c p1 = new Property__c(Name = 'B Home');
    Property__c p2 = new Property__c(Name = 'A Home');
    insert new List<Property__c>{p1, p2};

    Test.startTest();
    List<Property__c> results = PublicEnquiryController.getProperties();
    Test.stopTest();

    Assert.areEqual(2, results.size());
    Assert.areEqual('A Home', results[0].Name);
    Assert.areEqual('B Home', results[1].Name);
  }
}