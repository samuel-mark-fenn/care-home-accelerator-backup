// Test Enquiry Form Logic
Map<String, String> formData = new Map<String, String>{
    'firstName' => 'Test',
    'lastName' => 'Enquirer',
    'email' => 'test.enquirer@example.com',
    'phone' => '01234567890',
    'enquiryType' => 'Care',
    'source' => 'Google',
    'message' => 'Testing enquiry form'
};

System.debug('--- Running Test 1: New Enquiry ---');
PublicEnquiryController.submitEnquiry(formData);

// Verify
Contact c = [SELECT Id, AccountId FROM Contact WHERE Email = 'test.enquirer@example.com' LIMIT 1];
System.assert(c != null, 'Contact should be created');
System.assert(c.AccountId != null, 'Account should be linked');

Opportunity opp = [SELECT Id, AccountId, Primary_Contact__c FROM Opportunity WHERE AccountId = :c.AccountId LIMIT 1];
System.assert(opp != null, 'Opportunity should be created');
System.assertEquals(c.AccountId, opp.Primary_Contact__c, 'Primary Contact should link to Account ID');

System.debug('--- Running Test 2: Existing Enquiry ---');
// Submit again
PublicEnquiryController.submitEnquiry(formData);

Integer conCount = [SELECT Count() FROM Contact WHERE Email = 'test.enquirer@example.com'];
System.assertEquals(1, conCount, 'Should not create duplicate contact');

Integer oppCount = [SELECT Count() FROM Opportunity WHERE AccountId = :c.AccountId];
System.assertEquals(2, oppCount, 'Should create second opportunity');

System.debug('--- TESTS PASSED ---');
