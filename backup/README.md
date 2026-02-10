# Care Home Accelerator - Complete Backup & Deployment Guide

## 📦 Backup Contents

This backup contains everything needed to recreate the Care Home Accelerator demo in a new Salesforce org.

### Directory Structure

```
backup/
├── README.md                          # This file
├── org-info.json                      # Original org details
├── packages/                          # Managed package information
│   ├── installed-packages.json        # List of installed packages
│   └── package-installation-guide.md  # Installation instructions
├── metadata/                          # All Salesforce metadata
│   ├── package.xml                    # Metadata manifest
│   ├── objects/                       # Custom objects & fields
│   ├── lwc/                          # Lightning Web Components
│   ├── classes/                      # Apex classes
│   ├── triggers/                     # Apex triggers
│   ├── flows/                        # Flows & Process Builder
│   ├── layouts/                      # Page layouts
│   ├── tabs/                         # Custom tabs
│   ├── applications/                 # Custom apps
│   └── [other metadata types]
├── data/                             # All data exports
│   ├── *.json                        # Custom object data
│   ├── standard/                     # Standard object data
│   │   ├── Account.json
│   │   ├── Contact.json
│   │   └── [other standard objects]
│   ├── export-all-data.py           # Data export script
│   └── export-standard-objects.py   # Standard object export script
└── deployment/                       # Deployment resources
    └── deploy.sh                     # Automated deployment script
```

## 🎯 Quick Start - Deploy to New Org

### Prerequisites

1. **Salesforce CLI** installed (v2.x or higher)

   ```bash
   sf --version
   ```

2. **Create and authenticate to a new org**

   ```bash
   # Create a scratch org
   sf org create scratch --definition-file config/project-scratch-def.json --alias new-care-home

   # OR authenticate to an existing org
   sf org login web --alias new-care-home
   ```

3. **Python 3** (for data import scripts)

### Automated Deployment

The fastest way to deploy everything:

```bash
cd backup/deployment
./deploy.sh new-care-home
```

This script will:

1. ✅ Validate org connection
2. 📦 Install all managed packages (15-30 minutes)
3. 🚀 Deploy all metadata
4. 📊 Import data
5. ✓ Validate deployment

## 📋 Manual Deployment (Step-by-Step)

If you prefer manual control or the automated script fails:

### Step 1: Install Managed Packages

**CRITICAL:** Install packages BEFORE deploying metadata!

See `packages/package-installation-guide.md` for detailed instructions.

Quick install (in order):

```bash
sf package install --package 04tGA000005F6iKYAS --target-org new-care-home --wait 30 --no-prompt  # QLabs
sf package install --package 04t1U000007kPT0QAM --target-org new-care-home --wait 30 --no-prompt  # Postspin
sf package install --package 04tIg0000004fiDIAQ --target-org new-care-home --wait 30 --no-prompt  # Time Warp
sf package install --package 04t4P000002qntuQAA --target-org new-care-home --wait 30 --no-prompt  # XDO
sf package install --package 04t58000000SGw3AAG --target-org new-care-home --wait 30 --no-prompt  # Sales Insights
sf package install --package 04tHu000004V7nzIAC --target-org new-care-home --wait 30 --no-prompt  # Nintex DocGen
sf package install --package 04t8c000000ZxmMAAS --target-org new-care-home --wait 30 --no-prompt  # Data Tool
sf package install --package 04t5G000004F39PQAS --target-org new-care-home --wait 30 --no-prompt  # b2bmaIntegration
```

⏱️ **Wait for all packages to install completely before proceeding!**

### Step 2: Deploy Metadata

Deploy all custom objects, fields, Apex code, and configurations:

```bash
sf project deploy start --source-dir backup/metadata --target-org new-care-home --wait 30
```

If deployment fails due to dependency issues, you may need to deploy in phases:

```bash
# Phase 1: Objects and fields
sf project deploy start --metadata CustomObject --target-org new-care-home

# Phase 2: Apex
sf project deploy start --metadata ApexClass,ApexTrigger --target-org new-care-home

# Phase 3: Lightning components
sf project deploy start --metadata LightningComponentBundle --target-org new-care-home

# Phase 4: Everything else
sf project deploy start --source-dir backup/metadata --target-org new-care-home
```

### Step 3: Import Data

#### Option A: Using Salesforce Data Loader (Recommended for large datasets)

1. Download Salesforce Data Loader
2. Import in this order:
   - Standard Objects: Account → Contact → Lead → Opportunity → Case
   - Custom Objects: Property**c → Room**c → Preference**c → Resident**c → Assessment**c → Resident_Assessment**c → Resident_Preference**c → Room_Occupancy**c → Payment**c → Survey**c → Survey_Response\_\_c

#### Option B: Using CLI for smaller datasets

```bash
# Use the provided data export scripts in reverse (create import scripts)
# or use sf data import tree commands
```

### Step 4: Post-Deployment Configuration

1. **Assign Permission Sets**

   ```bash
   sf org assign permset --name [PermissionSetName] --target-org new-care-home
   ```

2. **Configure Org Settings**
   - Review and update Remote Site Settings
   - Configure Named Credentials if needed
   - Set up any org-specific configurations

3. **Verify Deployment**

   ```bash
   # Open the org
   sf org open --target-org new-care-home

   # Check custom objects
   sf sobject list --sobject-type custom --target-org new-care-home
   ```

## 📊 Data Summary

### Custom Objects Data

- **Property\_\_c**: 22 records
- **Room\_\_c**: 216 records
- **Room_Occupancy\_\_c**: 295 records
- **Resident\_\_c**: 1 record
- **Resident_Assessment\_\_c**: 6 records
- **Resident_Preference\_\_c**: 17 records
- **Preference\_\_c**: 12 records
- **Assessment\_\_c**: 5 records
- **Survey\_\_c**: 15 records
- **Survey_Response\_\_c**: 3 records

**Total Custom Object Records**: 592

### Standard Objects Data

- **Account**: 96 records
- **Contact**: 92 records
- **Lead**: 4 records
- **Opportunity**: 55 records
- **Case**: 3 records

**Total Standard Object Records**: 250

**GRAND TOTAL**: 842 records

## 🎁 Managed Packages Included

1. **QLabs_Utilities** (qbranch) - v1.193.0.1
2. **Salesforce - Postspin DevOps** (vbtapp) - v1.6.0.1
3. **Time Warp** (bmpyrckt) - v1.15.0.1
4. **XDO Automation** (xdo) - v2.11.0.1
5. **Sales Insights** (OIQ) - v1.0.0.1
6. **Nintex DocGen** (Loop) - v20.22.1.1
7. **Data Tool** (NXDO) - v1.31.0.1
8. **b2bmaIntegration** (b2bma) - v1.7.0.2

## 🔧 Troubleshooting

### Package Installation Issues

- **Timeout errors**: Increase wait time to 60 minutes: `--wait 60`
- **License errors**: Ensure target org has appropriate licenses
- **Dependency errors**: Verify packages are installed in order

### Metadata Deployment Issues

- **API version mismatch**: Update package.xml version to match target org
- **Field dependency errors**: Deploy objects first, then fields
- **Validation rule conflicts**: Temporarily disable validation rules

### Data Import Issues

- **Lookup relationship errors**: Import parent objects before children
- **Duplicate detection**: Disable duplicate rules temporarily
- **Record type errors**: Ensure record types are created before importing

## 📝 Custom Objects Schema

### Core Objects

- **Property\_\_c**: Care home properties/locations
- **Room\_\_c**: Individual rooms in properties
- **Room_Occupancy\_\_c**: Current and historical occupancy
- **Resident\_\_c**: Resident/patient information
- **Assessment\_\_c**: Medical/care assessments
- **Preference\_\_c**: Room/care preferences
- **Payment\_\_c**: Payment tracking
- **Survey\_\_c**: Surveys for feedback
- **Survey_Response\_\_c**: Survey responses

### Lightning Web Components

- `careDashboard` - Main care home dashboard
- `propertyMap` - Interactive property map
- `roomFinder` - Room search and availability
- `residentSurvey` - Resident satisfaction surveys
- `medicalAssessmentForm` - Medical assessment forms
- `enquiryForm` - General enquiry forms

## 🔄 Creating a Fresh Backup

To create a new backup from an org:

```bash
# Export packages
sf package installed list --target-org your-org --json > packages/installed-packages.json

# Export metadata
sf project retrieve start --manifest backup/metadata/package.xml --target-org your-org

# Export data
python3 data/export-all-data.py
python3 data/export-standard-objects.py
```

## 📞 Support

For issues or questions:

1. Check troubleshooting section above
2. Review Salesforce CLI documentation
3. Verify all prerequisites are met
4. Check package installation status in target org

## ✅ Deployment Checklist

- [ ] Salesforce CLI installed and up to date
- [ ] Target org created and authenticated
- [ ] Admin access to target org verified
- [ ] All 8 managed packages installed successfully
- [ ] Metadata deployed without errors
- [ ] Standard object data imported
- [ ] Custom object data imported
- [ ] Permission sets assigned to users
- [ ] Org settings configured
- [ ] Lightning Web Components accessible
- [ ] All functionality tested

---

**Backup Created**: February 10, 2026
**Source Org**: samuel.mark.fenn@gmail.com.carehomedemo
**API Version**: 64.0
