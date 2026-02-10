# 🏥 Care Home Accelerator - Salesforce Demo Backup

> Complete, production-ready backup of the Care Home Accelerator Salesforce demo org. Deploy to any Salesforce org in ~30-45 minutes.

[![Salesforce API](https://img.shields.io/badge/Salesforce%20API-v64.0-blue.svg)](https://developer.salesforce.com/docs/atlas.en-us.api.meta/api/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 📋 Overview

This repository contains everything needed to recreate the **Care Home Accelerator** demo in any Salesforce org:

- ✅ **14 Custom Objects** - Property, Room, Resident, Assessment management
- ✅ **6 Lightning Web Components** - Interactive dashboards and forms
- ✅ **8 Managed Packages** - Pre-configured with exact versions
- ✅ **842 Data Records** - Complete demo data included
- ✅ **Automated Deployment** - One-command deployment script
- ✅ **Full Documentation** - Step-by-step guides

## 🚀 Quick Start

### 1. Prerequisites

```bash
# Verify Salesforce CLI
sf --version

# Authenticate to target org
sf org login web --alias my-care-home-org
```

### 2. Clone & Deploy

```bash
# Clone this repository
git clone https://github.com/samuel-mark-fenn/care-home-accelerator-backup.git
cd care-home-accelerator-backup

# Run automated deployment
cd backup/deployment
./deploy.sh my-care-home-org
```

### 3. Validate

```bash
# Verify deployment
python3 validate-deployment.py my-care-home-org
```

**That's it!** ⏱️ Total time: 30-45 minutes (mostly package installation)

## 📦 What's Included

### Custom Objects (14)
| Object | Records | Description |
|--------|---------|-------------|
| Property__c | 22 | Care home properties/locations |
| Room__c | 216 | Individual room inventory |
| Room_Occupancy__c | 295 | Occupancy tracking (current & historical) |
| Resident__c | 1 | Resident/patient information |
| Assessment__c | 5 | Medical/care assessments |
| Resident_Assessment__c | 6 | Resident-specific assessments |
| Resident_Preference__c | 17 | Resident preferences |
| Preference__c | 12 | Care preferences catalog |
| Survey__c | 15 | Feedback surveys |
| Survey_Response__c | 3 | Survey responses |
| Payment__c | - | Payment tracking |
| Contract__c | - | Contract management |
| + 2 more | - | Supporting objects |

### Lightning Web Components (6)

- **careDashboard** - Main dashboard for care home staff
- **propertyMap** - Interactive location/property map
- **roomFinder** - Room search with availability
- **residentSurvey** - Resident satisfaction surveys
- **medicalAssessmentForm** - Medical assessment forms
- **enquiryForm** - General enquiry forms

### Managed Packages (8)

1. QLabs_Utilities (qbranch) - v1.193.0.1
2. Postspin DevOps (vbtapp) - v1.6.0.1
3. Time Warp (bmpyrckt) - v1.15.0.1
4. XDO Automation (xdo) - v2.11.0.1
5. Sales Insights (OIQ) - v1.0.0.1
6. Nintex DocGen (Loop) - v20.22.1.1
7. Data Tool (NXDO) - v1.31.0.1
8. b2bmaIntegration (b2bma) - v1.7.0.2

### Standard Objects Data

- 96 Accounts
- 92 Contacts
- 55 Opportunities
- 4 Leads
- 3 Cases

## 📁 Repository Structure

```
care-home-accelerator-backup/
├── backup/
│   ├── README.md                    # Comprehensive deployment guide
│   ├── QUICK-START.md              # Fast deployment instructions
│   ├── BACKUP-SUMMARY.md           # Backup overview
│   ├── MANIFEST.json               # Machine-readable manifest
│   ├── packages/                   # Managed package info & install guide
│   ├── metadata/                   # Complete Salesforce metadata
│   ├── data/                       # All exported data (842 records)
│   └── deployment/                 # Automated deployment scripts
├── force-app/                      # Salesforce DX project structure
└── sfdx-project.json              # SFDX project configuration
```

## 📖 Documentation

- **[Quick Start Guide](backup/QUICK-START.md)** - Deploy in 3 steps
- **[Complete Guide](backup/README.md)** - Full deployment documentation
- **[Backup Summary](backup/BACKUP-SUMMARY.md)** - What's included
- **[Package Guide](backup/packages/package-installation-guide.md)** - Package installation
- **[Contents Inventory](backup/CONTENTS.txt)** - Detailed file listing

## 🔧 Manual Deployment

If you prefer step-by-step control:

### 1. Install Managed Packages (~20-30 min)

```bash
sf package install --package 04tGA000005F6iKYAS --target-org my-org --wait 30 --no-prompt
# ... (see packages/package-installation-guide.md for all 8 packages)
```

### 2. Deploy Metadata (~5-10 min)

```bash
sf project deploy start --source-dir backup/metadata --target-org my-org
```

### 3. Import Data (~10-15 min)

Use Salesforce Data Loader or provided Python scripts in `backup/data/`

See [Complete Guide](backup/README.md) for detailed instructions.

## ✅ Features

### Care Home Management
- Property/location management with interactive map
- Room inventory and availability tracking
- Real-time occupancy management
- Resident information and preferences

### Assessment & Care
- Medical assessment workflows
- Care assessment tracking
- Preference matching for residents
- Survey and feedback collection

### User Experience
- Modern Lightning Web Components
- Interactive dashboards
- Mobile-friendly forms
- Automated workflows

## 🛠️ System Requirements

- Salesforce CLI v2.x or higher
- Python 3.x (for data import scripts)
- Admin access to target Salesforce org
- ~30GB available in target org

## 📊 Statistics

- **Custom Objects**: 14
- **Lightning Components**: 6
- **Apex Classes**: Multiple
- **Flows**: Multiple
- **Total Records**: 842
- **Managed Packages**: 8
- **Total Files**: 2,586
- **Backup Size**: 25MB

## 🔒 Security Note

This backup excludes sensitive org information (access tokens, passwords, etc.). You'll need to configure org-specific settings after deployment.

## 🤝 Contributing

This is a demo backup repository. For issues or improvements:

1. Check the [troubleshooting section](backup/README.md#troubleshooting)
2. Review [deployment documentation](backup/README.md)
3. Open an issue with details

## 📞 Support

For deployment issues:
1. Check [troubleshooting guide](backup/README.md#-troubleshooting)
2. Review [package installation guide](backup/packages/package-installation-guide.md)
3. Verify all prerequisites are met

## 📝 License

This demo backup is provided as-is for demonstration purposes.

## 🎯 Use Cases

Perfect for:
- Demo environments
- Training orgs
- Development sandboxes
- POC/prototype deployments
- Testing and validation

---

**Backup Created**: February 10, 2026
**Source Org**: Care Home Accelerator Demo
**API Version**: 64.0

**Ready to deploy?** Start with the [Quick Start Guide](backup/QUICK-START.md)!
