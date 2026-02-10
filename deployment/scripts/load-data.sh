#!/bin/bash
#===============================================================================
# Care Home Accelerator - Data Loading Script
# Loads exported data into target org in correct dependency order
#
# Usage: ./load-data.sh <target_alias> [--dry-run]
#        target_alias: Required SF org alias
#        --dry-run: Optional flag to validate without loading
#
# Prerequisites:
#   - Run extract-data.sh first to generate data files
#   - Metadata must already be deployed to target org
#===============================================================================

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${SCRIPT_DIR}/../data"
ORG_ALIAS="${1:-}"
DRY_RUN="${2:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ID Mapping files for relationship resolution
MAPPING_DIR="${DATA_DIR}/.id-mappings"

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}  Care Home Accelerator - Data Loader${NC}"
echo -e "${BLUE}==========================================${NC}"

# Validate inputs
if [ -z "${ORG_ALIAS}" ]; then
    echo -e "${RED}Error: Target org alias is required${NC}"
    echo "Usage: ./load-data.sh <target_alias> [--dry-run]"
    exit 1
fi

if [ ! -d "${DATA_DIR}" ]; then
    echo -e "${RED}Error: Data directory not found. Run extract-data.sh first.${NC}"
    exit 1
fi

if [ "${DRY_RUN}" == "--dry-run" ]; then
    echo -e "${YELLOW}DRY RUN MODE - No data will be loaded${NC}"
fi

echo -e "${YELLOW}Target org: ${ORG_ALIAS}${NC}"
echo ""

# Create mapping directory
mkdir -p "${MAPPING_DIR}"

#------------------------------------------------------------------------------
# Helper Functions
#------------------------------------------------------------------------------

load_records() {
    local FILE=$1
    local OBJECT=$2
    local DESCRIPTION=$3

    if [ ! -f "${FILE}" ]; then
        echo -e "   ${YELLOW}⚠ File not found: ${FILE}${NC}"
        return 0
    fi

    # Check if file has records
    local RECORD_COUNT=$(cat "${FILE}" | grep -c '"Id"' 2>/dev/null || echo "0")

    if [ "${RECORD_COUNT}" -eq 0 ]; then
        echo -e "   ${YELLOW}⚠ No records in ${DESCRIPTION}${NC}"
        return 0
    fi

    echo -e "   Loading ${RECORD_COUNT} ${DESCRIPTION}..."

    if [ "${DRY_RUN}" == "--dry-run" ]; then
        echo -e "   ${GREEN}✓ Would load ${RECORD_COUNT} records (dry run)${NC}"
        return 0
    fi

    # Use sf data import tree for JSON data
    sf data import tree \
        --target-org "${ORG_ALIAS}" \
        --files "${FILE}" \
        2>&1 || {
            echo -e "   ${YELLOW}⚠ Some records may have failed - check logs${NC}"
        }

    echo -e "   ${GREEN}✓ ${DESCRIPTION} loaded${NC}"
}

upsert_records() {
    local FILE=$1
    local OBJECT=$2
    local EXTERNAL_ID=$3
    local DESCRIPTION=$4

    if [ ! -f "${FILE}" ]; then
        echo -e "   ${YELLOW}⚠ File not found: ${FILE}${NC}"
        return 0
    fi

    local RECORD_COUNT=$(cat "${FILE}" | grep -c '"Id"' 2>/dev/null || echo "0")

    if [ "${RECORD_COUNT}" -eq 0 ]; then
        echo -e "   ${YELLOW}⚠ No records in ${DESCRIPTION}${NC}"
        return 0
    fi

    echo -e "   Upserting ${RECORD_COUNT} ${DESCRIPTION}..."

    if [ "${DRY_RUN}" == "--dry-run" ]; then
        echo -e "   ${GREEN}✓ Would upsert ${RECORD_COUNT} records (dry run)${NC}"
        return 0
    fi

    sf data upsert bulk \
        --target-org "${ORG_ALIAS}" \
        --sobject "${OBJECT}" \
        --file "${FILE}" \
        --external-id "${EXTERNAL_ID}" \
        --wait 10 \
        2>&1 || {
            echo -e "   ${YELLOW}⚠ Some records may have failed - check logs${NC}"
        }

    echo -e "   ${GREEN}✓ ${DESCRIPTION} loaded${NC}"
}

#------------------------------------------------------------------------------
# Phase 1: Reference Data
#------------------------------------------------------------------------------
echo -e "${BLUE}[Phase 1/9] Loading reference data...${NC}"

load_records "${DATA_DIR}/01-reference-data/preferences.json" "Preference__c" "Preferences"
load_records "${DATA_DIR}/01-reference-data/assessment-types.json" "Assessment__c" "Assessment Types"
load_records "${DATA_DIR}/01-reference-data/products.json" "Product2" "Products"

echo -e "${GREEN}Phase 1 complete${NC}"
echo ""

#------------------------------------------------------------------------------
# Phase 2: Properties
#------------------------------------------------------------------------------
echo -e "${BLUE}[Phase 2/9] Loading properties...${NC}"

load_records "${DATA_DIR}/02-properties/properties.json" "Property__c" "Properties"

echo -e "${GREEN}Phase 2 complete${NC}"
echo ""

#------------------------------------------------------------------------------
# Phase 3: Rooms
#------------------------------------------------------------------------------
echo -e "${BLUE}[Phase 3/9] Loading rooms...${NC}"

load_records "${DATA_DIR}/03-rooms/rooms.json" "Room__c" "Rooms"

echo -e "${GREEN}Phase 3 complete${NC}"
echo ""

#------------------------------------------------------------------------------
# Phase 4: Accounts & Contacts
#------------------------------------------------------------------------------
echo -e "${BLUE}[Phase 4/9] Loading accounts & contacts...${NC}"

load_records "${DATA_DIR}/04-accounts-contacts/accounts.json" "Account" "Accounts"
load_records "${DATA_DIR}/04-accounts-contacts/contacts.json" "Contact" "Contacts"

echo -e "${GREEN}Phase 4 complete${NC}"
echo ""

#------------------------------------------------------------------------------
# Phase 5: Residents
#------------------------------------------------------------------------------
echo -e "${BLUE}[Phase 5/9] Loading residents...${NC}"

load_records "${DATA_DIR}/05-residents/residents.json" "Resident__c" "Residents"
load_records "${DATA_DIR}/05-residents/resident-preferences.json" "Resident_Preference__c" "Resident Preferences"

echo -e "${GREEN}Phase 5 complete${NC}"
echo ""

#------------------------------------------------------------------------------
# Phase 6: Assessments
#------------------------------------------------------------------------------
echo -e "${BLUE}[Phase 6/9] Loading assessments...${NC}"

load_records "${DATA_DIR}/06-assessments/resident-assessments.json" "Resident_Assessment__c" "Resident Assessments"

echo -e "${GREEN}Phase 6 complete${NC}"
echo ""

#------------------------------------------------------------------------------
# Phase 7: Room Occupancy
#------------------------------------------------------------------------------
echo -e "${BLUE}[Phase 7/9] Loading room occupancy...${NC}"

load_records "${DATA_DIR}/07-occupancy/room-occupancy.json" "Room_Occupancy__c" "Room Occupancy Records"

echo -e "${GREEN}Phase 7 complete${NC}"
echo ""

#------------------------------------------------------------------------------
# Phase 8: Opportunities & Enquiries
#------------------------------------------------------------------------------
echo -e "${BLUE}[Phase 8/9] Loading opportunities & enquiries...${NC}"

load_records "${DATA_DIR}/08-opportunities/enquiries.json" "Enquiry__c" "Enquiries"
load_records "${DATA_DIR}/08-opportunities/opportunities.json" "Opportunity" "Opportunities"

echo -e "${GREEN}Phase 8 complete${NC}"
echo ""

#------------------------------------------------------------------------------
# Phase 9: Surveys & Contracts
#------------------------------------------------------------------------------
echo -e "${BLUE}[Phase 9/9] Loading surveys & contracts...${NC}"

load_records "${DATA_DIR}/09-surveys/surveys.json" "Survey__c" "Surveys"
load_records "${DATA_DIR}/09-surveys/survey-responses.json" "Survey_Response__c" "Survey Responses"
load_records "${DATA_DIR}/09-surveys/contracts.json" "Contract__c" "Contracts"

echo -e "${GREEN}Phase 9 complete${NC}"
echo ""

#------------------------------------------------------------------------------
# Summary
#------------------------------------------------------------------------------
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}  Data Loading Complete!${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""

if [ "${DRY_RUN}" == "--dry-run" ]; then
    echo -e "${YELLOW}This was a dry run. No data was actually loaded.${NC}"
    echo "Run without --dry-run flag to load data."
else
    echo -e "${GREEN}All data has been loaded to: ${ORG_ALIAS}${NC}"
    echo ""
    echo -e "${YELLOW}Post-load steps:${NC}"
    echo "  1. Verify record counts in target org"
    echo "  2. Check for any failed records in Salesforce Setup > Bulk Data Load Jobs"
    echo "  3. Validate lookup relationships are correctly mapped"
    echo "  4. Run validation tests"
fi
echo ""
