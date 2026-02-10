#!/bin/bash
#===============================================================================
# Care Home Accelerator - Scratch Org Deployment Script
# Creates and configures a new scratch org with full metadata and sample data
#
# Usage: ./deploy-scratch-org.sh [org_alias] [--skip-data]
#        org_alias: Optional custom alias (default: care-home-scratch)
#        --skip-data: Skip loading sample data
#
# Prerequisites:
#   - Salesforce CLI (sf) installed
#   - Dev Hub authenticated (sf org login web --set-default-dev-hub)
#===============================================================================

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/../.."
SCRATCH_DEF="${PROJECT_ROOT}/config/project-scratch-def.json"
ORG_ALIAS="${1:-care-home-scratch}"
SKIP_DATA=""

# Parse arguments
for arg in "$@"; do
    case $arg in
        --skip-data)
            SKIP_DATA="true"
            ;;
    esac
done

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}  Care Home Accelerator - Scratch Org${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""
echo -e "Org Alias: ${YELLOW}${ORG_ALIAS}${NC}"
echo ""

#------------------------------------------------------------------------------
# Step 1: Create Scratch Org
#------------------------------------------------------------------------------
echo -e "${BLUE}[1/6] Creating scratch org...${NC}"

sf org create scratch \
    --definition-file "${SCRATCH_DEF}" \
    --alias "${ORG_ALIAS}" \
    --set-default \
    --duration-days 30 \
    --wait 10

echo -e "${GREEN}✓ Scratch org created${NC}"
echo ""

#------------------------------------------------------------------------------
# Step 2: Deploy Metadata
#------------------------------------------------------------------------------
echo -e "${BLUE}[2/6] Deploying metadata...${NC}"

sf project deploy start \
    --source-dir "${PROJECT_ROOT}/force-app" \
    --target-org "${ORG_ALIAS}" \
    --wait 30

echo -e "${GREEN}✓ Metadata deployed${NC}"
echo ""

#------------------------------------------------------------------------------
# Step 3: Assign Permission Sets
#------------------------------------------------------------------------------
echo -e "${BLUE}[3/6] Assigning permission sets...${NC}"

# Assign master access to running user
sf org assign permset \
    --name ColtenCareMasterAccess \
    --target-org "${ORG_ALIAS}" \
    2>/dev/null || echo -e "${YELLOW}⚠ Could not assign ColtenCareMasterAccess${NC}"

echo -e "${GREEN}✓ Permission sets assigned${NC}"
echo ""

#------------------------------------------------------------------------------
# Step 4: Run Apex Tests (validate deployment)
#------------------------------------------------------------------------------
echo -e "${BLUE}[4/6] Running Apex tests...${NC}"

sf apex run test \
    --target-org "${ORG_ALIAS}" \
    --test-level RunLocalTests \
    --wait 10 \
    --result-format human \
    || echo -e "${YELLOW}⚠ Some tests may have failed - review results${NC}"

echo -e "${GREEN}✓ Tests completed${NC}"
echo ""

#------------------------------------------------------------------------------
# Step 5: Load Sample Data (optional)
#------------------------------------------------------------------------------
if [ -z "${SKIP_DATA}" ]; then
    echo -e "${BLUE}[5/6] Loading sample data...${NC}"

    # Check if data exists
    if [ -d "${SCRIPT_DIR}/../data" ]; then
        "${SCRIPT_DIR}/load-data.sh" "${ORG_ALIAS}"
        echo -e "${GREEN}✓ Sample data loaded${NC}"
    else
        echo -e "${YELLOW}⚠ No data directory found. Run extract-data.sh first.${NC}"
    fi
else
    echo -e "${BLUE}[5/6] Skipping data load (--skip-data flag)${NC}"
fi
echo ""

#------------------------------------------------------------------------------
# Step 6: Open Org
#------------------------------------------------------------------------------
echo -e "${BLUE}[6/6] Opening scratch org...${NC}"

sf org open --target-org "${ORG_ALIAS}"

echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}  Scratch Org Deployment Complete!${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo -e "Org Alias: ${YELLOW}${ORG_ALIAS}${NC}"
echo ""
echo -e "${YELLOW}Useful commands:${NC}"
echo "  sf org open --target-org ${ORG_ALIAS}          # Open org"
echo "  sf org display --target-org ${ORG_ALIAS}       # View org details"
echo "  sf org delete scratch --target-org ${ORG_ALIAS} # Delete org"
echo ""
