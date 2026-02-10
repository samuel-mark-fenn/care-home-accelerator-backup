public without sharing class PublicEnquiryController {
  @AuraEnabled(cacheable=true)
  public static List<Property__c> getProperties() {
    return [SELECT Id, Name FROM Property__c ORDER BY Name ASC];
  }

  @AuraEnabled
  public static void submitEnquiry(Map<String, Object> formData) {
    try {
      String firstName = (String) formData.get('firstName');
      String lastName = (String) formData.get('lastName');
      String email = (String) formData.get('email');
      String phone = (String) formData.get('phone');
      String enquiryType = (String) formData.get('enquiryType');
      String source = (String) formData.get('source');
      String message = (String) formData.get('message');

      // New fields
      String admissionType = (String) formData.get('admissionType');
      String residentName = (String) formData.get('residentName');
      String respiteStartDateStr = (String) formData.get('respiteStartDate');
      String respiteEndDateStr = (String) formData.get('respiteEndDate');
      String interests = (String) formData.get('interests');
      String needs = (String) formData.get('needs');
      String careHomeId = (String) formData.get('careHomeId');

      // 1. Create Enquirer Person Account (ALWAYS CREATE NEW - Demonstration Mode)
      // Note: We are intentionally not checking for duplicates to demonstrate duplicate management features.
      Id personAccountRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('PersonAccount')
        .getRecordTypeId();

      Account enquirer = new Account();
      enquirer.RecordTypeId = personAccountRtId;
      enquirer.FirstName = firstName;
      enquirer.LastName = lastName;
      enquirer.PersonEmail = email;
      enquirer.Phone = phone;
      insert enquirer;

      // 2. Handle Resident Account (if applicable)
      Account resident;
      if (String.isNotBlank(residentName)) {
        resident = new Account();
        resident.RecordTypeId = personAccountRtId;
        
        List<String> nameParts = residentName.trim().split('\\s+');
        if (nameParts.size() == 1) {
            resident.LastName = nameParts[0];
        } else {
            resident.LastName = nameParts.remove(nameParts.size()-1);
            resident.FirstName = String.join(nameParts, ' ');
        }
        resident.Previous_Respite_Stays__c = 3;
        insert resident;
      }

      // 3. Create Opportunity
      Id rtId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
        .get('Care_Home_Enquiry')
        .getRecordTypeId();

      Opportunity opp = new Opportunity();
      opp.RecordTypeId = rtId;
      opp.Name =
        (residentName != null ? residentName : firstName + ' ' + lastName) +
        ' - Care Enquiry';
      opp.AccountId = enquirer.Id; // Linked to Enquirer Account
      opp.Primary_Contact__c = enquirer.Id; // Fix: Primary_Contact__c looks up to Account (Person Account), not Contact
      opp.StageName = '1. Initial Inquiry';
      opp.CloseDate = Date.today().addDays(30);
      opp.Description = message;
      opp.LeadSource = source;
      opp.Type = 'New Customer';

      // Map new fields
      opp.Admission_Type__c = admissionType;
      if (String.isNotBlank(careHomeId)) {
        opp.Care_Home__c = careHomeId;
      }

      // Calculate Enquiry Level
      if (String.isNotBlank(respiteStartDateStr)) {
        Date startDate = Date.valueOf(respiteStartDateStr);
        Integer daysToAdmission = Date.today().daysBetween(startDate);
        
        if (daysToAdmission <= 14) {
          opp.Enquiry_Level__c = 'Level 1: Expected admission within one to two weeks.';
        } else if (daysToAdmission <= 42) {
          opp.Enquiry_Level__c = 'Level 2: Expected admission within the next six weeks.';
        } else {
          opp.Enquiry_Level__c = 'Level 3: Likely to be admitted at a later, undefined date.';
        }
      } else {
        opp.Enquiry_Level__c = 'Level 4: No Expected date set';
      }

      if (String.isNotBlank(respiteStartDateStr)) {
        opp.Respite_Start_Date__c = Date.valueOf(respiteStartDateStr);
        opp.Requested_Intake_Date__c = Date.valueOf(respiteStartDateStr);
      }
      if (String.isNotBlank(respiteEndDateStr)) {
        opp.Respite_End_Date__c = Date.valueOf(respiteEndDateStr);
        opp.Requested_Discharge_Date__c = Date.valueOf(respiteEndDateStr);
      }
      if (resident != null) {
        opp.Resident__c = resident.Id; // Linked to Resident Account
      }

      opp.Description =
        'Type: ' +
        enquiryType +
        '\n\n' +
        (opp.Description != null ? opp.Description : '');
      insert opp;

      // 4. Handle Resident Preferences
      if (resident != null) {
        processPreferences(resident.Id, interests, 'Interest');
        processPreferences(resident.Id, needs, 'Need');
      }
    } catch (Exception e) {
      throw new AuraHandledException(
        'Error submitting enquiry: ' + e.getMessage()
      );
    }
  }

  private static void processPreferences(
    Id residentId,
    String prefList,
    String type
  ) {
    if (String.isBlank(prefList))
      return;

    List<String> prefs = prefList.split(',');
    List<Resident_Preference__c> resPrefsToInsert = new List<Resident_Preference__c>();

    for (String pName : prefs) {
      String cleanName = pName.trim();
      if (String.isBlank(cleanName))
        continue;

      Id prefId = findOrCreatePreference(cleanName);
      resPrefsToInsert.add(
        new Resident_Preference__c(
          Resident__c = residentId,
          Preference__c = prefId,
          Type__c = type
        )
      );
    }

    if (!resPrefsToInsert.isEmpty()) {
      insert resPrefsToInsert;
    }
  }

  private static Id findOrCreatePreference(String name) {
    List<Preference__c> existing = [
      SELECT Id
      FROM Preference__c
      WHERE Name = :name
      LIMIT 1
    ];
    if (!existing.isEmpty()) {
      return existing[0].Id;
    }
    Preference__c p = new Preference__c(Name = name);
    insert p;
    return p.Id;
  }
}
