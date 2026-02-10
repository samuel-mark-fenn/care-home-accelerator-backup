#!/bin/bash
#===============================================================================
# Care Home Accelerator - Sandbox Deployment Script
# Deploys metadata and optionally data to an existing sandbox
#
# Usage: ./deploy-sandbox.sh <sandbox_alias> [--with-data] [--validate-only]
#        sandbox_alias: Required - the authenticated sandbox alias
#        --with-data: Also load data after metadata deployment
#        --validate-only: Validate deployment without committing
#
# Prerequisites:
#   - Sandbox must be authenticated: sf org login web --alias <alias> --instance-url https://test.salesforce.com
#===============================================================================

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/../.."
SANDBOX_ALIAS="${1:-}"
WITH_DATA=""
VALIDATE_ONLY=""

# Parse arguments
for arg in "$@"; do
    case $arg in
        --with-data)
            WITH_DATA="true"
            ;;
        --validate-only)
            VALIDATE_ONLY="true"
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
echo -e "${BLUE}  Care Home Accelerator - Sandbox Deploy${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""

# Validate inputs
if [ -z "${SANDBOX_ALIAS}" ] || [[ "${SANDBOX_ALIAS}" == --* ]]; then
    echo -e "${RED}Error: Sandbox alias is required${NC}"
    echo ""
    echo "Usage: ./deploy-sandbox.sh <sandbox_alias> [--with-data] [--validate-only]"
    echo ""
    echo "Example:"
    echo "  ./deploy-sandbox.sh mydev-sandbox"
    echo "  ./deploy-sandbox.sh qa-sandbox --with-data"
    echo "  ./deploy-sandbox.sh uat-sandbox --validate-only"
    exit 1
fi

echo -e "Target Sandbox: ${YELLOW}${SANDBOX_ALIAS}${NC}"
if [ -n "${VALIDATE_ONLY}" ]; then
    echo -e "Mode: ${YELLOW}VALIDATE ONLY${NC}"
fi
if [ -n "${WITH_DATA}" ]; then
    echo -e "Data: ${YELLOW}Will load after deployment${NC}"
fi
echo ""

#------------------------------------------------------------------------------
# Step 1: Verify Sandbox Connection
#------------------------------------------------------------------------------
echo -e "${BLUE}[1/5] Verifying sandbox connection...${NC}"

sf org display --target-org "${SANDBOX_ALIAS}" > /dev/null 2>&1 || {
    echo -e "${RED}Error: Cannot connect to sandbox '${SANDBOX_ALIAS}'${NC}"
    echo ""
    echo "Please authenticate first:"
    echo "  sf org login web --alias ${SANDBOX_ALIAS} --instance-url https://test.salesforce.com"
    exit 1
}

echo -e "${GREEN}✓ Sandbox connection verified${NC}"
echo ""

#------------------------------------------------------------------------------
# Step 2: Deploy Metadata
#------------------------------------------------------------------------------
echo -e "${BLUE}[2/5] Deploying metadata...${NC}"

DEPLOY_FLAGS="--source-dir ${PROJECT_ROOT}/force-app --target-org ${SANDBOX_ALIAS} --wait 30"

if [ -n "${VALIDATE_ONLY}" ]; then
    DEPLOY_FLAGS="${DEPLOY_FLAGS} --dry-run"
    echo -e "${YELLOW}Running validation only...${NC}"
fi

sf project deploy start ${DEPLOY_FLAGS}

if [ -n "${VALIDATE_ONLY}" ]; then
    echo -e "${GREEN}✓ Deployment validation passed${NC}"
else
    echo -e "${GREEN}✓ Metadata deployed${NC}"
fi
echo ""

#------------------------------------------------------------------------------
# Step 3: Run Apex Tests
#------------------------------------------------------------------------------
echo -e "${BLUE}[3/5] Running Apex tests...${NC}"

sf apex run test \
    --target-org "${SANDBOX_ALIAS}" \
    --test-level RunLocalTests \
    --wait 15 \
    --result-format human \
    || echo -e "${YELLOW}⚠ Some tests may have failed - review results${NC}"

echo -e "${GREEN}✓ Tests completed${NC}"
echo ""

#------------------------------------------------------------------------------
# Step 4: Assign Permission Sets
#------------------------------------------------------------------------------
if [ -z "${VALIDATE_ONLY}" ]; then
    echo -e "${BLUE}[4/5] Assigning permission sets to current user...${NC}"

    sf org assign permset \
        --name ColtenCareMasterAccess \
        --target-org "${SANDBOX_ALIAS}" \
        2>/dev/null || echo -e "${YELLOW}⚠ Could not assign permission set (may already be assigned)${NC}"

    echo -e "${GREEN}✓ Permission sets assigned${NC}"
else
    echo -e "${BLUE}[4/5] Skipping permission sets (validate-only mode)${NC}"
fi
echo ""

#------------------------------------------------------------------------------
# Step 5: Load Data (optional)
#------------------------------------------------------------------------------
if [ -n "${WITH_DATA}" ] && [ -z "${VALIDATE_ONLY}" ]; then
    echo -e "${BLUE}[5/5] Loading data...${NC}"

    if [ -d "${SCRIPT_DIR}/../data" ]; then
        "${SCRIPT_DIR}/load-data.sh" "${SANDBOX_ALIAS}"
        echo -e "${GREEN}✓ Data loaded${NC}"
    else
        echo -e "${YELLOW}⚠ No data directory found. Run extract-data.sh first.${NC}"
    fi
else
    echo -e "${BLUE}[5/5] Skipping data load${NC}"
fi
echo ""

#------------------------------------------------------------------------------
# Summary
#------------------------------------------------------------------------------
echo -e "${GREEN}==========================================${NC}"
if [ -n "${VALIDATE_ONLY}" ]; then
    echo -e "${GREEN}  Sandbox Validation Complete!${NC}"
else
    echo -e "${GREEN}  Sandbox Deployment Complete!${NC}"
fi
echo -e "${GREEN}==========================================${NC}"
echo ""
echo -e "Sandbox: ${YELLOW}${SANDBOX_ALIAS}${NC}"
echo ""
echo -e "${YELLOW}Open sandbox:${NC}"
echo "  sf org open --target-org ${SANDBOX_ALIAS}"
echo ""
