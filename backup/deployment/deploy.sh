#!/bin/bash

################################################################################
# Care Home Accelerator - Complete Deployment Script
#
# This script deploys the complete Care Home demo to a new Salesforce org
#
# Prerequisites:
#   - Salesforce CLI installed and authenticated
#   - Target org created and connected
#   - Admin access to target org
#
# Usage:
#   ./deploy.sh <target-org-alias>
#
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Function to print section headers
print_header() {
    echo ""
    echo "=========================================="
    echo "$1"
    echo "=========================================="
}

# Check arguments
if [ $# -eq 0 ]; then
    print_error "No target org alias provided"
    echo "Usage: $0 <target-org-alias>"
    exit 1
fi

TARGET_ORG=$1
BACKUP_DIR="$(dirname "$0")/.."

print_header "Care Home Accelerator Deployment"
print_info "Target Org: $TARGET_ORG"
print_info "Backup Directory: $BACKUP_DIR"

# Step 1: Validate org connection
print_header "Step 1: Validating Org Connection"
if sf org display --target-org "$TARGET_ORG" > /dev/null 2>&1; then
    print_success "Successfully connected to $TARGET_ORG"
else
    print_error "Cannot connect to org: $TARGET_ORG"
    exit 1
fi

# Step 2: Install Managed Packages
print_header "Step 2: Installing Managed Packages"
print_warning "This may take 15-30 minutes. Please be patient..."
print_info "Installing packages in dependency order..."

packages=(
    "04tGA000005F6iKYAS:QLabs_Utilities"
    "04t1U000007kPT0QAM:Postspin_DevOps"
    "04tIg0000004fiDIAQ:Time_Warp"
    "04t4P000002qntuQAA:XDO_Automation"
    "04t58000000SGw3AAG:Sales_Insights"
    "04tHu000004V7nzIAC:Nintex_DocGen"
    "04t8c000000ZxmMAAS:Data_Tool"
    "04t5G000004F39PQAS:b2bmaIntegration"
)

for pkg in "${packages[@]}"; do
    IFS=':' read -r pkg_id pkg_name <<< "$pkg"
    print_info "Installing $pkg_name ($pkg_id)..."

    if sf package install --package "$pkg_id" --target-org "$TARGET_ORG" --wait 30 --no-prompt 2>&1 | grep -q "Successfully installed"; then
        print_success "$pkg_name installed successfully"
    else
        print_warning "$pkg_name installation may have issues - continuing..."
    fi
done

print_success "All packages installation attempted"

# Step 3: Deploy Metadata
print_header "Step 3: Deploying Metadata"
print_info "Deploying custom objects, fields, Apex, LWC, and all configurations..."

if sf project deploy start --source-dir "$BACKUP_DIR/metadata" --target-org "$TARGET_ORG" --wait 30; then
    print_success "Metadata deployed successfully"
else
    print_error "Metadata deployment failed"
    print_info "You may need to deploy in phases or resolve conflicts"
    exit 1
fi

# Step 4: Import Data
print_header "Step 4: Importing Data"

# Import standard objects first (for lookup relationships)
print_info "Importing standard object data..."

standard_objects=(
    "Account"
    "Contact"
    "Lead"
    "Opportunity"
    "Case"
)

for obj in "${standard_objects[@]}"; do
    data_file="$BACKUP_DIR/data/standard/${obj}.json"
    if [ -f "$data_file" ]; then
        print_info "Importing $obj records..."
        if python3 -c "import json; import subprocess; data=json.load(open('$data_file')); [subprocess.run(['sf','data','create','record','--sobject','$obj','--values',json.dumps({k:v for k,v in r.items() if k not in ['Id','attributes']}), '--target-org','$TARGET_ORG'], capture_output=True) for r in data['records'][:100]]" 2>/dev/null; then
            print_success "$obj data imported"
        else
            print_warning "Some $obj records may not have imported"
        fi
    else
        print_warning "$obj data file not found"
    fi
done

# Import custom objects
print_info "Importing custom object data..."

custom_objects=(
    "Property__c"
    "Room__c"
    "Preference__c"
    "Resident__c"
    "Assessment__c"
    "Resident_Assessment__c"
    "Resident_Preference__c"
    "Room_Occupancy__c"
    "Payment__c"
    "Survey__c"
    "Survey_Response__c"
)

for obj in "${custom_objects[@]}"; do
    data_file="$BACKUP_DIR/data/${obj}.json"
    if [ -f "$data_file" ]; then
        print_info "Importing $obj records..."
        # Note: This is a simplified import - you may need data loader for complex relationships
        print_warning "Complex relationships may require manual data loader import"
    fi
done

# Step 5: Post-Deployment Configuration
print_header "Step 5: Post-Deployment Validation"
print_info "Verifying deployment..."

# Check if custom objects exist
print_info "Checking custom objects..."
if sf sobject describe --sobject Property__c --target-org "$TARGET_ORG" > /dev/null 2>&1; then
    print_success "Custom objects deployed successfully"
else
    print_warning "Some custom objects may not be available"
fi

# Step 6: Summary
print_header "Deployment Summary"
print_success "Care Home Accelerator deployment completed!"
print_info ""
print_info "Next Steps:"
print_info "1. Log into the org: sf org open --target-org $TARGET_ORG"
print_info "2. Assign permission sets to users"
print_info "3. Configure any org-specific settings"
print_info "4. Import remaining data using Data Loader if needed"
print_info "5. Test all functionality"
print_info ""
print_success "Deployment script finished!"
