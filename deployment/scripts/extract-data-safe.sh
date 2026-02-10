#!/bin/bash
#===============================================================================
# Care Home Accelerator - Safe Data Extraction Script
# Extracts all data using dynamic field discovery
#
# Usage: ./extract-data-safe.sh [target_alias]
#===============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${SCRIPT_DIR}/../data"
ORG_ALIAS="${1:-your-org-alias}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}  Care Home Accelerator - Data Extractor${NC}"
echo -e "${BLUE}==========================================${NC}"
echo -e "${YELLOW}Using org: ${ORG_ALIAS}${NC}"
echo ""

# Create directories
mkdir -p "${DATA_DIR}/01-reference-data"
mkdir -p "${DATA_DIR}/02-properties"
mkdir -p "${DATA_DIR}/03-rooms"
mkdir -p "${DATA_DIR}/04-accounts-contacts"
mkdir -p "${DATA_DIR}/05-residents"
mkdir -p "${DATA_DIR}/06-assessments"
mkdir -p "${DATA_DIR}/07-occupancy"
mkdir -p "${DATA_DIR}/08-opportunities"
mkdir -p "${DATA_DIR}/09-surveys"

ORG_FLAG="--target-org ${ORG_ALIAS}"

echo -e "${GREEN}Extracting data...${NC}"
echo ""

#------------------------------------------------------------------------------
# 01 - Reference Data
#------------------------------------------------------------------------------
echo -e "${BLUE}[1/9] Reference data...${NC}"

# Products
sf data query ${ORG_FLAG} \
    --query "SELECT Id, Name, Description, ProductCode, Family, IsActive FROM Product2" \
    --result-format json > "${DATA_DIR}/01-reference-data/products.json" 2>/dev/null || echo '{"records":[]}' > "${DATA_DIR}/01-reference-data/products.json"

# Preferences
sf data query ${ORG_FLAG} \
    --query "SELECT FIELDS(ALL) FROM Preference__c LIMIT 200" \
    --result-format json > "${DATA_DIR}/01-reference-data/preferences.json" 2>/dev/null || echo '{"records":[]}' > "${DATA_DIR}/01-reference-data/preferences.json"

# Assessment Types
sf data query ${ORG_FLAG} \
    --query "SELECT FIELDS(ALL) FROM Assessment__c LIMIT 200" \
    --result-format json > "${DATA_DIR}/01-reference-data/assessment-types.json" 2>/dev/null || echo '{"records":[]}' > "${DATA_DIR}/01-reference-data/assessment-types.json"

echo -e "   ${GREEN}✓ Done${NC}"

#------------------------------------------------------------------------------
# 02 - Properties
#------------------------------------------------------------------------------
echo -e "${BLUE}[2/9] Properties...${NC}"

sf data query ${ORG_FLAG} \
    --query "SELECT FIELDS(ALL) FROM Property__c LIMIT 200" \
    --result-format json > "${DATA_DIR}/02-properties/properties.json" 2>/dev/null || echo '{"records":[]}' > "${DATA_DIR}/02-properties/properties.json"

echo -e "   ${GREEN}✓ Done${NC}"

#------------------------------------------------------------------------------
# 03 - Rooms
#------------------------------------------------------------------------------
echo -e "${BLUE}[3/9] Rooms...${NC}"

sf data query ${ORG_FLAG} \
    --query "SELECT FIELDS(ALL) FROM Room__c LIMIT 2000" \
    --result-format json > "${DATA_DIR}/03-rooms/rooms.json" 2>/dev/null || echo '{"records":[]}' > "${DATA_DIR}/03-rooms/rooms.json"

echo -e "   ${GREEN}✓ Done${NC}"

#------------------------------------------------------------------------------
# 04 - Accounts & Contacts
#------------------------------------------------------------------------------
echo -e "${BLUE}[4/9] Accounts & Contacts...${NC}"

# Custom fields on Account
sf data query ${ORG_FLAG} \
    --query "SELECT FIELDS(STANDARD), NHS_Number__c, Date_of_Birth__c, Gender__c, Marital_Status__c, Ethnicity__c, Religion__c, Preferred_Language__c, Dietary_Requirements__c, Allergies__c, Mobility_Status__c, Cognitive_Status__c FROM Account LIMIT 2000" \
    --result-format json > "${DATA_DIR}/04-accounts-contacts/accounts.json" 2>/dev/null || echo '{"records":[]}' > "${DATA_DIR}/04-accounts-contacts/accounts.json"

# Contacts
sf data query ${ORG_FLAG} \
    --query "SELECT FIELDS(STANDARD) FROM Contact LIMIT 2000" \
    --result-format json > "${DATA_DIR}/04-accounts-contacts/contacts.json" 2>/dev/null || echo '{"records":[]}' > "${DATA_DIR}/04-accounts-contacts/contacts.json"

echo -e "   ${GREEN}✓ Done${NC}"

#------------------------------------------------------------------------------
# 05 - Residents
#------------------------------------------------------------------------------
echo -e "${BLUE}[5/9] Residents...${NC}"

sf data query ${ORG_FLAG} \
    --query "SELECT FIELDS(ALL) FROM Resident__c LIMIT 2000" \
    --result-format json > "${DATA_DIR}/05-residents/residents.json" 2>/dev/null || echo '{"records":[]}' > "${DATA_DIR}/05-residents/residents.json"

sf data query ${ORG_FLAG} \
    --query "SELECT FIELDS(ALL) FROM Resident_Preference__c LIMIT 2000" \
    --result-format json > "${DATA_DIR}/05-residents/resident-preferences.json" 2>/dev/null || echo '{"records":[]}' > "${DATA_DIR}/05-residents/resident-preferences.json"

echo -e "   ${GREEN}✓ Done${NC}"

#------------------------------------------------------------------------------
# 06 - Assessments
#------------------------------------------------------------------------------
echo -e "${BLUE}[6/9] Assessments...${NC}"

sf data query ${ORG_FLAG} \
    --query "SELECT FIELDS(ALL) FROM Resident_Assessment__c LIMIT 2000" \
    --result-format json > "${DATA_DIR}/06-assessments/resident-assessments.json" 2>/dev/null || echo '{"records":[]}' > "${DATA_DIR}/06-assessments/resident-assessments.json"

echo -e "   ${GREEN}✓ Done${NC}"

#------------------------------------------------------------------------------
# 07 - Room Occupancy
#------------------------------------------------------------------------------
echo -e "${BLUE}[7/9] Room Occupancy...${NC}"

sf data query ${ORG_FLAG} \
    --query "SELECT FIELDS(ALL) FROM Room_Occupancy__c LIMIT 2000" \
    --result-format json > "${DATA_DIR}/07-occupancy/room-occupancy.json" 2>/dev/null || echo '{"records":[]}' > "${DATA_DIR}/07-occupancy/room-occupancy.json"

echo -e "   ${GREEN}✓ Done${NC}"

#------------------------------------------------------------------------------
# 08 - Opportunities & Enquiries
#------------------------------------------------------------------------------
echo -e "${BLUE}[8/9] Opportunities & Enquiries...${NC}"

sf data query ${ORG_FLAG} \
    --query "SELECT FIELDS(ALL) FROM Enquiry__c LIMIT 2000" \
    --result-format json > "${DATA_DIR}/08-opportunities/enquiries.json" 2>/dev/null || echo '{"records":[]}' > "${DATA_DIR}/08-opportunities/enquiries.json"

# Opportunity with standard + custom fields
sf data query ${ORG_FLAG} \
    --query "SELECT FIELDS(STANDARD), Care_Home__c, Care_Type__c, Admission_Type__c, Funding_Source__c, Expected_Move_In_Date__c, Actual_Move_In_Date__c, Weekly_Rate__c FROM Opportunity LIMIT 2000" \
    --result-format json > "${DATA_DIR}/08-opportunities/opportunities.json" 2>/dev/null || echo '{"records":[]}' > "${DATA_DIR}/08-opportunities/opportunities.json"

echo -e "   ${GREEN}✓ Done${NC}"

#------------------------------------------------------------------------------
# 09 - Surveys & Contracts
#------------------------------------------------------------------------------
echo -e "${BLUE}[9/9] Surveys & Contracts...${NC}"

sf data query ${ORG_FLAG} \
    --query "SELECT FIELDS(ALL) FROM Survey__c LIMIT 2000" \
    --result-format json > "${DATA_DIR}/09-surveys/surveys.json" 2>/dev/null || echo '{"records":[]}' > "${DATA_DIR}/09-surveys/surveys.json"

sf data query ${ORG_FLAG} \
    --query "SELECT FIELDS(ALL) FROM Survey_Response__c LIMIT 2000" \
    --result-format json > "${DATA_DIR}/09-surveys/survey-responses.json" 2>/dev/null || echo '{"records":[]}' > "${DATA_DIR}/09-surveys/survey-responses.json"

sf data query ${ORG_FLAG} \
    --query "SELECT FIELDS(ALL) FROM Contract__c LIMIT 2000" \
    --result-format json > "${DATA_DIR}/09-surveys/contracts.json" 2>/dev/null || echo '{"records":[]}' > "${DATA_DIR}/09-surveys/contracts.json"

echo -e "   ${GREEN}✓ Done${NC}"

#------------------------------------------------------------------------------
# Summary
#------------------------------------------------------------------------------
echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}  Data Extraction Complete!${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo "Record counts:"
for file in $(find "${DATA_DIR}" -name "*.json" -type f | sort); do
    COUNT=$(grep -o '"Id"' "$file" 2>/dev/null | wc -l | tr -d ' ')
    BASENAME=$(basename "$file")
    printf "  %-35s %s records\n" "$BASENAME" "$COUNT"
done
echo ""
