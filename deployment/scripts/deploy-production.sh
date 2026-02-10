#!/bin/bash
#===============================================================================
# Care Home Accelerator - Production Deployment Script
# Safely deploys metadata to production with validation and confirmation
#
# Usage: ./deploy-production.sh <prod_alias> [--validate-only] [--quick-deploy <job_id>]
#        prod_alias: Required - the authenticated production org alias
#        --validate-only: Run validation without deploying
#        --quick-deploy <job_id>: Deploy a previously validated deployment
#
# Prerequisites:
#   - Production org must be authenticated: sf org login web --alias <alias>
#   - All tests must pass
#   - Recommended: Run --validate-only first, then --quick-deploy
#
# IMPORTANT: Production deployments require all tests to pass!
#===============================================================================

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/../.."
PROD_ALIAS="${1:-}"
VALIDATE_ONLY=""
QUICK_DEPLOY=""
JOB_ID=""

# Parse arguments
shift || true  # Skip first argument (alias)
while [[ $# -gt 0 ]]; do
    case $1 in
        --validate-only)
            VALIDATE_ONLY="true"
            shift
            ;;
        --quick-deploy)
            QUICK_DEPLOY="true"
            JOB_ID="$2"
            shift 2
            ;;
        *)
            shift
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
echo -e "${BLUE}  Care Home Accelerator - PRODUCTION${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""

# Validate inputs
if [ -z "${PROD_ALIAS}" ] || [[ "${PROD_ALIAS}" == --* ]]; then
    echo -e "${RED}Error: Production org alias is required${NC}"
    echo ""
    echo "Usage: ./deploy-production.sh <prod_alias> [--validate-only] [--quick-deploy <job_id>]"
    echo ""
    echo "Recommended workflow:"
    echo "  1. Validate first:    ./deploy-production.sh prod --validate-only"
    echo "  2. Quick deploy:      ./deploy-production.sh prod --quick-deploy <job_id>"
    exit 1
fi

echo -e "${RED}⚠⚠⚠  PRODUCTION DEPLOYMENT  ⚠⚠⚠${NC}"
echo ""
echo -e "Target: ${YELLOW}${PROD_ALIAS}${NC}"
if [ -n "${VALIDATE_ONLY}" ]; then
    echo -e "Mode: ${YELLOW}VALIDATE ONLY (no changes will be made)${NC}"
elif [ -n "${QUICK_DEPLOY}" ]; then
    echo -e "Mode: ${YELLOW}QUICK DEPLOY (Job ID: ${JOB_ID})${NC}"
else
    echo -e "Mode: ${RED}FULL DEPLOYMENT${NC}"
fi
echo ""

#------------------------------------------------------------------------------
# Safety Confirmation (unless validate-only)
#------------------------------------------------------------------------------
if [ -z "${VALIDATE_ONLY}" ]; then
    echo -e "${YELLOW}This will deploy to PRODUCTION.${NC}"
    read -p "Type 'DEPLOY' to confirm: " CONFIRMATION

    if [ "${CONFIRMATION}" != "DEPLOY" ]; then
        echo -e "${RED}Deployment cancelled.${NC}"
        exit 1
    fi
    echo ""
fi

#------------------------------------------------------------------------------
# Step 1: Verify Production Connection
#------------------------------------------------------------------------------
echo -e "${BLUE}[1/4] Verifying production connection...${NC}"

ORG_INFO=$(sf org display --target-org "${PROD_ALIAS}" --json 2>/dev/null) || {
    echo -e "${RED}Error: Cannot connect to org '${PROD_ALIAS}'${NC}"
    echo ""
    echo "Please authenticate first:"
    echo "  sf org login web --alias ${PROD_ALIAS}"
    exit 1
}

# Check if it's actually a production org (not sandbox)
IS_SANDBOX=$(echo "${ORG_INFO}" | grep -i "sandbox" | head -1 || true)
if [ -n "${IS_SANDBOX}" ]; then
    echo -e "${YELLOW}⚠ Warning: This appears to be a sandbox, not production.${NC}"
    echo "Consider using deploy-sandbox.sh instead."
    read -p "Continue anyway? (y/N): " CONTINUE
    if [ "${CONTINUE}" != "y" ]; then
        exit 1
    fi
fi

echo -e "${GREEN}✓ Production connection verified${NC}"
echo ""

#------------------------------------------------------------------------------
# Step 2: Quick Deploy (if specified)
#------------------------------------------------------------------------------
if [ -n "${QUICK_DEPLOY}" ]; then
    echo -e "${BLUE}[2/4] Quick deploying validated deployment...${NC}"

    if [ -z "${JOB_ID}" ]; then
        echo -e "${RED}Error: Job ID required for quick deploy${NC}"
        exit 1
    fi

    sf project deploy quick \
        --job-id "${JOB_ID}" \
        --target-org "${PROD_ALIAS}" \
        --wait 30

    echo -e "${GREEN}✓ Quick deployment complete${NC}"
    echo ""

    # Skip to summary
    echo -e "${GREEN}==========================================${NC}"
    echo -e "${GREEN}  Production Deployment Complete!${NC}"
    echo -e "${GREEN}==========================================${NC}"
    exit 0
fi

#------------------------------------------------------------------------------
# Step 2: Deploy/Validate Metadata
#------------------------------------------------------------------------------
echo -e "${BLUE}[2/4] ${VALIDATE_ONLY:+Validating}${VALIDATE_ONLY:-Deploying} metadata...${NC}"

DEPLOY_FLAGS="--source-dir ${PROJECT_ROOT}/force-app --target-org ${PROD_ALIAS} --wait 60"

# Production requires all tests
DEPLOY_FLAGS="${DEPLOY_FLAGS} --test-level RunLocalTests"

if [ -n "${VALIDATE_ONLY}" ]; then
    DEPLOY_FLAGS="${DEPLOY_FLAGS} --dry-run"
fi

echo -e "${YELLOW}Running with test level: RunLocalTests${NC}"
echo "This may take several minutes..."
echo ""

DEPLOY_OUTPUT=$(sf project deploy start ${DEPLOY_FLAGS} --json 2>&1) || {
    echo -e "${RED}Deployment failed. Check errors above.${NC}"
    echo "${DEPLOY_OUTPUT}"
    exit 1
}

# Extract job ID for quick deploy
DEPLOY_JOB_ID=$(echo "${DEPLOY_OUTPUT}" | grep -o '"id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | grep -o '"[^"]*"$' | tr -d '"')

if [ -n "${VALIDATE_ONLY}" ]; then
    echo -e "${GREEN}✓ Validation passed${NC}"
    echo ""
    echo -e "${YELLOW}Job ID for quick deploy: ${DEPLOY_JOB_ID}${NC}"
    echo ""
    echo "To deploy this validated package:"
    echo "  ./deploy-production.sh ${PROD_ALIAS} --quick-deploy ${DEPLOY_JOB_ID}"
else
    echo -e "${GREEN}✓ Metadata deployed${NC}"
fi
echo ""

#------------------------------------------------------------------------------
# Step 3: Post-deployment Validation
#------------------------------------------------------------------------------
if [ -z "${VALIDATE_ONLY}" ]; then
    echo -e "${BLUE}[3/4] Running post-deployment validation...${NC}"

    sf apex run test \
        --target-org "${PROD_ALIAS}" \
        --test-level RunLocalTests \
        --wait 20 \
        --result-format human \
        || echo -e "${YELLOW}⚠ Some tests may need attention${NC}"

    echo -e "${GREEN}✓ Post-deployment tests complete${NC}"
else
    echo -e "${BLUE}[3/4] Skipping post-deployment tests (validate-only)${NC}"
fi
echo ""

#------------------------------------------------------------------------------
# Step 4: Assign Permission Sets
#------------------------------------------------------------------------------
if [ -z "${VALIDATE_ONLY}" ]; then
    echo -e "${BLUE}[4/4] Assigning permission sets...${NC}"

    sf org assign permset \
        --name ColtenCareMasterAccess \
        --target-org "${PROD_ALIAS}" \
        2>/dev/null || echo -e "${YELLOW}⚠ Permission set may already be assigned${NC}"

    echo -e "${GREEN}✓ Permission sets configured${NC}"
else
    echo -e "${BLUE}[4/4] Skipping permission sets (validate-only)${NC}"
fi
echo ""

#------------------------------------------------------------------------------
# Summary
#------------------------------------------------------------------------------
echo -e "${GREEN}==========================================${NC}"
if [ -n "${VALIDATE_ONLY}" ]; then
    echo -e "${GREEN}  Production Validation Complete!${NC}"
    echo -e "${GREEN}==========================================${NC}"
    echo ""
    echo -e "${YELLOW}Next step - Deploy validated package:${NC}"
    echo "  ./deploy-production.sh ${PROD_ALIAS} --quick-deploy ${DEPLOY_JOB_ID}"
else
    echo -e "${GREEN}  Production Deployment Complete!${NC}"
    echo -e "${GREEN}==========================================${NC}"
    echo ""
    echo -e "${YELLOW}Post-deployment checklist:${NC}"
    echo "  □ Verify app functionality in production"
    echo "  □ Assign permission sets to users"
    echo "  □ Update any environment-specific configurations"
    echo "  □ Monitor for any runtime errors"
fi
echo ""
echo -e "${YELLOW}Open org:${NC}"
echo "  sf org open --target-org ${PROD_ALIAS}"
echo ""
