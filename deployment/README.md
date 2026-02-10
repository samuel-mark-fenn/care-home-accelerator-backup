# Care Home Accelerator - Deployment Guide

Complete deployment package for the Care Home Accelerator Salesforce application.

## Directory Structure

```
deployment/
├── manifest/
│   └── package.xml           # Full metadata manifest
├── data/                     # Exported data (after running extract-data.sh)
│   ├── 01-reference-data/    # Preferences, Products, Assessment Types
│   ├── 02-properties/        # Care Homes (Property__c)
│   ├── 03-rooms/             # Rooms (Room__c)
│   ├── 04-accounts-contacts/ # Accounts & Contacts
│   ├── 05-residents/         # Residents & Preferences
│   ├── 06-assessments/       # Resident Assessments
│   ├── 07-occupancy/         # Room Occupancy records
│   ├── 08-opportunities/     # Opportunities & Enquiries
│   ├── 09-surveys/           # Surveys, Responses, Contracts
│   └── LOAD_ORDER.md         # Data load sequence
├── scripts/
│   ├── extract-data.sh       # Export data from source org
│   ├── load-data.sh          # Import data to target org
│   ├── deploy-scratch-org.sh # Create & deploy to scratch org
│   ├── deploy-sandbox.sh     # Deploy to sandbox
│   └── deploy-production.sh  # Deploy to production
└── README.md                 # This file
```

---

## Prerequisites

### Required Tools
- **Salesforce CLI (sf)** v2.x or later
- **Node.js** 18+ (for LWC development)
- **Git** (for version control)

### Authentication

```bash
# Authenticate to Dev Hub (for scratch orgs)
sf org login web --set-default-dev-hub --alias devhub

# Authenticate to Sandbox
sf org login web --alias my-sandbox --instance-url https://test.salesforce.com

# Authenticate to Production
sf org login web --alias my-prod
```

---

## Quick Start

### Option 1: Scratch Org (Development/Testing)

```bash
cd deployment/scripts

# Create scratch org with metadata and sample data
./deploy-scratch-org.sh care-home-dev

# Or without sample data
./deploy-scratch-org.sh care-home-dev --skip-data
```

### Option 2: Sandbox

```bash
# Deploy metadata only
./deploy-sandbox.sh my-sandbox

# Deploy metadata + data
./deploy-sandbox.sh my-sandbox --with-data

# Validate without deploying
./deploy-sandbox.sh my-sandbox --validate-only
```

### Option 3: Production

```bash
# Step 1: Validate (recommended)
./deploy-production.sh my-prod --validate-only

# Step 2: Quick deploy validated package
./deploy-production.sh my-prod --quick-deploy <job_id>
```

---

## Detailed Deployment Steps

### Step 1: Export Data from Source Org

Before deploying to a new org, export data from your source org:

```bash
cd deployment/scripts

# Export from default org
./extract-data.sh

# Export from specific org
./extract-data.sh source-org-alias
```

This creates JSON files in `deployment/data/` organized by load order.

### Step 2: Deploy Metadata

The metadata is in `force-app/` directory. Deploy using:

```bash
# Using SFDX directly
sf project deploy start --source-dir ../force-app --target-org target-alias

# Or use the deployment scripts
./deploy-sandbox.sh target-alias
```

### Step 3: Load Data

After metadata is deployed, load data:

```bash
# Dry run (validate without loading)
./load-data.sh target-alias --dry-run

# Actual load
./load-data.sh target-alias
```

### Step 4: Post-Deployment Configuration

1. **Assign Permission Sets**
   ```bash
   sf org assign permset --name ColtenCareMasterAccess --target-org target-alias
   ```

2. **Set Default Record Types** (if needed)
   - Navigate to Setup > Record Types
   - Assign default record types to profiles

3. **Configure Lightning Pages**
   - Activate custom record pages (Property, Enquiry, Account)
   - Deploy flexipages if not auto-activated

---

## Metadata Components

### Custom Objects
| Object | API Name | Description |
|--------|----------|-------------|
| Property | `Property__c` | Care homes/facilities |
| Room | `Room__c` | Individual rooms |
| Resident | `Resident__c` | Care home residents |
| Enquiry | `Enquiry__c` | Public enquiries |
| Assessment | `Assessment__c` | Assessment templates |
| Resident Assessment | `Resident_Assessment__c` | Resident assessments |
| Contract | `Contract__c` | Care contracts |
| Room Occupancy | `Room_Occupancy__c` | Room booking/occupancy |
| Survey | `Survey__c` | Survey definitions |
| Survey Response | `Survey_Response__c` | Survey responses |
| Preference | `Preference__c` | Preference definitions |
| Resident Preference | `Resident_Preference__c` | Resident preferences |

### Standard Object Extensions
- **Account**: Extended with care-specific fields (NHS, medical info, etc.)
- **Opportunity**: Care Home Enquiry record type with admission tracking
- **Contact**: Relationship tracking fields

### Apex Classes
| Class | Description |
|-------|-------------|
| `AssessmentController` | Handles resident assessments |
| `RoomFinderController` | Room matching algorithm |
| `CareDashboardController` | Dashboard data aggregation |
| `PropertyMapController` | Property mapping |
| `PublicEnquiryController` | Public enquiry form |
| `ResidentSurveyController` | Survey management |

### Lightning Web Components
| Component | Description |
|-----------|-------------|
| `roomFinder` | Room availability/matching UI |
| `enquiryForm` | Public enquiry form |
| `medicalAssessmentForm` | Medical assessment capture |
| `careDashboard` | Care dashboard visualization |
| `propertyMap` | Property location map |
| `residentSurvey` | Survey administration |

### Permission Sets
| Permission Set | Description |
|----------------|-------------|
| `ColtenCareMasterAccess` | Full platform access |
| `EnquiryAccess` | Limited public enquiry access |

---

## Data Dependencies

Load data in this order to satisfy relationships:

```
1. Preference__c (no dependencies)
2. Assessment__c (no dependencies)
3. Product2 (no dependencies)
4. Property__c (no dependencies)
5. Room__c (→ Property__c, Product2)
6. Account (no dependencies)
7. Contact (→ Account)
8. Resident__c (→ Account, Property__c, Room__c)
9. Resident_Preference__c (→ Resident__c, Preference__c)
10. Resident_Assessment__c (→ Resident__c, Assessment__c)
11. Room_Occupancy__c (→ Room__c, Resident__c)
12. Enquiry__c (→ Property__c)
13. Opportunity (→ Account, Property__c, Room__c, Resident__c)
14. Survey__c (no dependencies)
15. Survey_Response__c (→ Survey__c, Resident__c)
16. Contract__c (→ Account, Resident__c, Property__c)
```

---

## Troubleshooting

### Common Issues

**"Cannot resolve lookup relationship"**
- Ensure parent records exist before loading child records
- Follow the data load order in `LOAD_ORDER.md`

**"Permission set not found"**
- Deploy metadata first before assigning permission sets
- Check permission set API name matches exactly

**"Test failures in production"**
- Run tests locally first: `sf apex run test --target-org alias`
- Review test coverage requirements (75% minimum)

**"Validation errors on deploy"**
- Check for missing dependent metadata
- Ensure API version compatibility (currently 64.0)

### Getting Help

```bash
# Check deployment status
sf project deploy report --target-org alias

# View org info
sf org display --target-org alias

# Open Setup
sf org open --target-org alias --path /lightning/setup/SetupOneHome/home
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | Current | Initial deployment package |

---

## Architecture Notes

### API Version
All components use Salesforce API version **64.0**.

### Namespace
This is an **unmanaged package** with no namespace prefix.

### Test Coverage
Test classes provided for all Apex controllers. Run full test suite before production deployment.

### Security Model
- Master permission set provides full CRUD access
- Guest access through EnquiryAccess permission set
- Object-level security enforced through permission sets
