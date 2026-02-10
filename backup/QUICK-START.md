# 🚀 Quick Start Guide

Deploy Care Home Accelerator to a new org in 3 steps!

## Prerequisites Check ✅

```bash
# 1. Verify Salesforce CLI is installed
sf --version

# 2. Create or authenticate to target org
sf org login web --alias my-new-org

# 3. Verify connection
sf org display --target-org my-new-org
```

## One-Command Deployment 🎯

```bash
cd backup/deployment
./deploy.sh my-new-org
```

⏱️ **Estimated time**: 30-45 minutes (mostly package installation)

## What Gets Deployed

### 📦 Managed Packages (8)

- QLabs_Utilities
- Postspin DevOps
- Time Warp
- XDO Automation
- Sales Insights
- Nintex DocGen
- Data Tool
- b2bmaIntegration

### 🏗️ Custom Metadata

- 14 Custom Objects
- Lightning Web Components (6)
- Apex Classes & Triggers
- Flows & Process Automation
- Page Layouts
- Custom Tabs & Apps
- Validation Rules
- Permission Sets

### 📊 Data

- **842 total records**
- 592 custom object records
- 250 standard object records

## Validation ✓

After deployment, validate everything worked:

```bash
cd backup/deployment
python3 validate-deployment.py my-new-org
```

## Troubleshooting 🔧

### Package Installation Taking Forever?

- Normal! Packages can take 20-30 minutes
- Check status: `sf package installed list --target-org my-new-org`

### Deployment Failed?

1. Check if packages are fully installed
2. Try deploying metadata in phases (see main README)
3. Check deployment logs for specific errors

### Need Help?

See detailed instructions in `backup/README.md`

## Post-Deployment ⚙️

1. **Open the org**

   ```bash
   sf org open --target-org my-new-org
   ```

2. **Assign permission sets** to users

3. **Test key functionality**
   - Property and Room records visible
   - Care Dashboard loads
   - Forms and surveys work

## Alternative: Manual Deployment

If automated script fails, follow manual steps in `README.md`:

1. Install packages manually (30 min)
2. Deploy metadata (5-10 min)
3. Import data (10-15 min)
4. Configure settings (5 min)

---

**Total Deployment Time**: 30-60 minutes (mostly waiting for packages)
