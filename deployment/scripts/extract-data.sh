#!/bin/bash
#===============================================================================
# Care Home Accelerator - Data Extraction Script
# Extracts all data from the source org in deployment-ready format
#
# Usage: ./extract-data.sh [target_alias]
#        target_alias: Optional SF org alias (defaults to default org)
#
# Output: Creates JSON files in ../data/ directory with proper load order
#===============================================================================

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${SCRIPT_DIR}/../data"
ORG_ALIAS="${1:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}  Care Home Accelerator - Data Extractor${NC}"
echo -e "${BLUE}==========================================${NC}"

# Create data directory structure
mkdir -p "${DATA_DIR}/01-reference-data"
mkdir -p "${DATA_DIR}/02-properties"
mkdir -p "${DATA_DIR}/03-rooms"
mkdir -p "${DATA_DIR}/04-accounts-contacts"
mkdir -p "${DATA_DIR}/05-residents"
mkdir -p "${DATA_DIR}/06-assessments"
mkdir -p "${DATA_DIR}/07-occupancy"
mkdir -p "${DATA_DIR}/08-opportunities"
mkdir -p "${DATA_DIR}/09-surveys"

# Build org flag if alias provided
ORG_FLAG=""
if [ -n "${ORG_ALIAS}" ]; then
    ORG_FLAG="--target-org ${ORG_ALIAS}"
    echo -e "${YELLOW}Using org: ${ORG_ALIAS}${NC}"
else
    echo -e "${YELLOW}Using default org${NC}"
fi

echo ""
echo -e "${GREEN}Starting data extraction...${NC}"
echo ""

#------------------------------------------------------------------------------
# 01 - Reference Data (Preferences, Assessment Types, Products)
#------------------------------------------------------------------------------
echo -e "${BLUE}[1/9] Extracting reference data...${NC}"

# Preferences (care type preferences, dietary preferences, etc.)
sf data query ${ORG_FLAG} \
    --query "SELECT Id, Name, Type__c, Description__c, Active__c, CreatedDate FROM Preference__c ORDER BY Type__c, Name" \
    --result-format json \
    > "${DATA_DIR}/01-reference-data/preferences.json" 2>/dev/null || echo "[]" > "${DATA_DIR}/01-reference-data/preferences.json"

# Assessment Types/Templates
sf data query ${ORG_FLAG} \
    --query "SELECT Id, Name, Description__c, Assessment_Type__c, Active__c, CreatedDate FROM Assessment__c ORDER BY Assessment_Type__c, Name" \
    --result-format json \
    > "${DATA_DIR}/01-reference-data/assessment-types.json" 2>/dev/null || echo "[]" > "${DATA_DIR}/01-reference-data/assessment-types.json"

# Products (Room types, Care packages)
sf data query ${ORG_FLAG} \
    --query "SELECT Id, Name, Description, ProductCode, Family, IsActive FROM Product2 ORDER BY Family, Name" \
    --result-format json \
    > "${DATA_DIR}/01-reference-data/products.json" 2>/dev/null || echo "[]" > "${DATA_DIR}/01-reference-data/products.json"

echo -e "   ${GREEN}✓ Reference data exported${NC}"

#------------------------------------------------------------------------------
# 02 - Properties (Care Homes)
#------------------------------------------------------------------------------
echo -e "${BLUE}[2/9] Extracting properties...${NC}"

sf data query ${ORG_FLAG} \
    --query "SELECT Id, Name, Address__c, City__c, Postcode__c, Region__c, CQC_Rating__c, CQC_Location_ID__c, Care_Types_Offered__c, Total_Beds__c, Status__c, Phone__c, Email__c, Website__c, Manager__c, Facilities__c, Image_URL__c, Description__c, Latitude__c, Longitude__c, CreatedDate FROM Property__c ORDER BY Name" \
    --result-format json \
    > "${DATA_DIR}/02-properties/properties.json" 2>/dev/null || echo "[]" > "${DATA_DIR}/02-properties/properties.json"

echo -e "   ${GREEN}✓ Properties exported${NC}"

#------------------------------------------------------------------------------
# 03 - Rooms
#------------------------------------------------------------------------------
echo -e "${BLUE}[3/9] Extracting rooms...${NC}"

sf data query ${ORG_FLAG} \
    --query "SELECT Id, Name, Property__c, Room_Number__c, Room_Type__c, Floor__c, Status__c, Availability_Status__c, Has_Ensuite__c, Garden_View__c, Ground_Floor__c, Size_Sq_Ft__c, Base_Weekly_Rate__c, Product__c, Image_URL__c, Description__c, Features__c, Last_Refurbished__c, CreatedDate FROM Room__c ORDER BY Property__c, Room_Number__c" \
    --result-format json \
    > "${DATA_DIR}/03-rooms/rooms.json" 2>/dev/null || echo "[]" > "${DATA_DIR}/03-rooms/rooms.json"

echo -e "   ${GREEN}✓ Rooms exported${NC}"

#------------------------------------------------------------------------------
# 04 - Accounts & Contacts (Family members, Local Authorities, etc.)
#------------------------------------------------------------------------------
echo -e "${BLUE}[4/9] Extracting accounts & contacts...${NC}"

# Accounts (including custom care-related fields)
sf data query ${ORG_FLAG} \
    --query "SELECT Id, Name, RecordTypeId, Type, Phone, Website, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Description, NHS_Number__c, Date_of_Birth__c, Gender__c, Marital_Status__c, Ethnicity__c, Religion__c, Preferred_Language__c, Dietary_Requirements__c, Allergies__c, Mobility_Status__c, Cognitive_Status__c, Life_Story__c, Emergency_Contact_Name__c, Emergency_Contact_Phone__c, Emergency_Contact_Relationship__c, GP_Name__c, GP_Practice__c, GP_Phone__c, Primary_Diagnosis__c, Secondary_Diagnoses__c, Current_Medications__c, Next_of_Kin__c, Power_of_Attorney__c, DNACPR_Status__c, CreatedDate FROM Account ORDER BY Name" \
    --result-format json \
    > "${DATA_DIR}/04-accounts-contacts/accounts.json" 2>/dev/null || echo "[]" > "${DATA_DIR}/04-accounts-contacts/accounts.json"

# Contacts
sf data query ${ORG_FLAG} \
    --query "SELECT Id, FirstName, LastName, AccountId, Email, Phone, MobilePhone, MailingStreet, MailingCity, MailingState, MailingPostalCode, MailingCountry, Title, Department, Relationship__c, Is_Emergency_Contact__c, Has_Power_of_Attorney__c, Preferred_Contact_Method__c, CreatedDate FROM Contact ORDER BY LastName, FirstName" \
    --result-format json \
    > "${DATA_DIR}/04-accounts-contacts/contacts.json" 2>/dev/null || echo "[]" > "${DATA_DIR}/04-accounts-contacts/contacts.json"

echo -e "   ${GREEN}✓ Accounts & Contacts exported${NC}"

#------------------------------------------------------------------------------
# 05 - Residents
#------------------------------------------------------------------------------
echo -e "${BLUE}[5/9] Extracting residents...${NC}"

sf data query ${ORG_FLAG} \
    --query "SELECT Id, Name, Account__c, Property__c, Room__c, Status__c, Admission_Date__c, Discharge_Date__c, Care_Type__c, Funding_Type__c, Weekly_Fee__c, Photo_URL__c, Notes__c, CreatedDate FROM Resident__c ORDER BY Property__c, Name" \
    --result-format json \
    > "${DATA_DIR}/05-residents/residents.json" 2>/dev/null || echo "[]" > "${DATA_DIR}/05-residents/residents.json"

# Resident Preferences
sf data query ${ORG_FLAG} \
    --query "SELECT Id, Name, Resident__c, Preference__c, Notes__c, CreatedDate FROM Resident_Preference__c ORDER BY Resident__c" \
    --result-format json \
    > "${DATA_DIR}/05-residents/resident-preferences.json" 2>/dev/null || echo "[]" > "${DATA_DIR}/05-residents/resident-preferences.json"

echo -e "   ${GREEN}✓ Residents exported${NC}"

#------------------------------------------------------------------------------
# 06 - Assessments
#------------------------------------------------------------------------------
echo -e "${BLUE}[6/9] Extracting assessments...${NC}"

sf data query ${ORG_FLAG} \
    --query "SELECT Id, Name, Resident__c, Assessment_Type__c, Assessor__c, Assessment_Date__c, Status__c, Score__c, Notes__c, Next_Review_Date__c, CreatedDate FROM Resident_Assessment__c ORDER BY Assessment_Date__c DESC" \
    --result-format json \
    > "${DATA_DIR}/06-assessments/resident-assessments.json" 2>/dev/null || echo "[]" > "${DATA_DIR}/06-assessments/resident-assessments.json"

echo -e "   ${GREEN}✓ Assessments exported${NC}"

#------------------------------------------------------------------------------
# 07 - Room Occupancy
#------------------------------------------------------------------------------
echo -e "${BLUE}[7/9] Extracting room occupancy...${NC}"

sf data query ${ORG_FLAG} \
    --query "SELECT Id, Name, Room__c, Resident__c, Expected_Start_Date__c, Expected_End_Date__c, Actual_Start_Date__c, Actual_End_Date__c, Status__c, Notes__c, CreatedDate FROM Room_Occupancy__c ORDER BY Expected_Start_Date__c DESC" \
    --result-format json \
    > "${DATA_DIR}/07-occupancy/room-occupancy.json" 2>/dev/null || echo "[]" > "${DATA_DIR}/07-occupancy/room-occupancy.json"

echo -e "   ${GREEN}✓ Room Occupancy exported${NC}"

#------------------------------------------------------------------------------
# 08 - Opportunities (Care Home Enquiries)
#------------------------------------------------------------------------------
echo -e "${BLUE}[8/9] Extracting opportunities...${NC}"

sf data query ${ORG_FLAG} \
    --query "SELECT Id, Name, AccountId, RecordTypeId, StageName, CloseDate, Amount, Probability, LeadSource, Type, Description, Care_Home__c, Care_Type__c, Admission_Type__c, Funding_Source__c, Expected_Move_In_Date__c, Actual_Move_In_Date__c, Allocated_Room__c, Preferred_Room__c, Resident__c, Primary_Contact__c, Local_Authority__c, Weekly_Rate__c, Expected_Duration_Weeks__c, Financial_Assessment_Required__c, Financial_Assessment_Status__c, Financial_Assessment_Completed_Date__c, Assessment_Scheduled_Date__c, Assessment_Completed_Date__c, Assessment_Outcome__c, Visit_Scheduled_Date__c, Visit_Completed_Date__c, Visit_Outcome__c, Contract_Sent_Date__c, Contract_Signed_Date__c, Deposit_Amount__c, Deposit_Paid__c, Room_Allocation_Date__c, Room_Ready_Date__c, Move_In_Checklist_Complete__c, Terms_of_Residence_Signed__c, Direct_Debit_Setup__c, CreatedDate FROM Opportunity ORDER BY CloseDate DESC" \
    --result-format json \
    > "${DATA_DIR}/08-opportunities/opportunities.json" 2>/dev/null || echo "[]" > "${DATA_DIR}/08-opportunities/opportunities.json"

# Enquiries (custom object)
sf data query ${ORG_FLAG} \
    --query "SELECT Id, Name, First_Name__c, Last_Name__c, Email__c, Phone__c, Property__c, Care_Type__c, Enquiry_Type__c, Source__c, Status__c, Notes__c, Preferred_Move_In_Date__c, Budget__c, CreatedDate FROM Enquiry__c ORDER BY CreatedDate DESC" \
    --result-format json \
    > "${DATA_DIR}/08-opportunities/enquiries.json" 2>/dev/null || echo "[]" > "${DATA_DIR}/08-opportunities/enquiries.json"

echo -e "   ${GREEN}✓ Opportunities & Enquiries exported${NC}"

#------------------------------------------------------------------------------
# 09 - Surveys
#------------------------------------------------------------------------------
echo -e "${BLUE}[9/9] Extracting surveys...${NC}"

sf data query ${ORG_FLAG} \
    --query "SELECT Id, Name, Type__c, Description__c, Active__c, CreatedDate FROM Survey__c ORDER BY Name" \
    --result-format json \
    > "${DATA_DIR}/09-surveys/surveys.json" 2>/dev/null || echo "[]" > "${DATA_DIR}/09-surveys/surveys.json"

sf data query ${ORG_FLAG} \
    --query "SELECT Id, Name, Survey__c, Resident__c, Respondent__c, Response_Date__c, Overall_Rating__c, Comments__c, CreatedDate FROM Survey_Response__c ORDER BY Response_Date__c DESC" \
    --result-format json \
    > "${DATA_DIR}/09-surveys/survey-responses.json" 2>/dev/null || echo "[]" > "${DATA_DIR}/09-surveys/survey-responses.json"

# Contracts
sf data query ${ORG_FLAG} \
    --query "SELECT Id, Name, Account__c, Resident__c, Property__c, Status__c, Start_Date__c, End_Date__c, Weekly_Fee__c, Terms__c, CreatedDate FROM Contract__c ORDER BY Start_Date__c DESC" \
    --result-format json \
    > "${DATA_DIR}/09-surveys/contracts.json" 2>/dev/null || echo "[]" > "${DATA_DIR}/09-surveys/contracts.json"

echo -e "   ${GREEN}✓ Surveys & Contracts exported${NC}"

#------------------------------------------------------------------------------
# Generate Load Order Manifest
#------------------------------------------------------------------------------
echo ""
echo -e "${BLUE}Generating load order manifest...${NC}"

cat > "${DATA_DIR}/LOAD_ORDER.md" << 'EOF'
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
EOF

echo -e "${GREEN}✓ Load order manifest created${NC}"

#------------------------------------------------------------------------------
# Summary
#------------------------------------------------------------------------------
echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}  Data Extraction Complete!${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo -e "Data files saved to: ${BLUE}${DATA_DIR}${NC}"
echo ""
echo "Exported Objects:"
find "${DATA_DIR}" -name "*.json" -type f | while read file; do
    COUNT=$(cat "$file" | grep -c '"Id"' 2>/dev/null || echo "0")
    BASENAME=$(basename "$file")
    printf "  %-35s %s records\n" "$BASENAME" "$COUNT"
done
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Review LOAD_ORDER.md for import sequence"
echo "  2. Use ./load-data.sh to import to target org"
echo ""
