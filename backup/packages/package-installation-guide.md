# Installed Managed Packages

This org has the following managed packages installed. These must be installed **BEFORE** deploying the metadata.

## Installation Order

Install packages in this order to satisfy dependencies:

1. **QLabs_Utilities** (qbranch)
   - Version: 1.193.0.1 (Spring 2025)
   - Package ID: 0337F0000008YQSQA2
   - Version ID: 04tGA000005F6iKYAS

2. **Salesforce - Postspin DevOps** (vbtapp)
   - Version: 1.6.0.1 (Winter '26)
   - Package ID: 0331U0000000LRTQA2
   - Version ID: 04t1U000007kPT0QAM

3. **Time Warp** (bmpyrckt)
   - Version: 1.15.0.1 (Vega)
   - Package ID: 0332w000000UgF3AAK
   - Version ID: 04tIg0000004fiDIAQ

4. **XDO Automation** (xdo)
   - Version: 2.11.0.1 (Demo Boost Tabs Renamed)
   - Package ID: 0334P000000d02xQAA
   - Version ID: 04t4P000002qntuQAA

5. **Sales Insights** (OIQ)
   - Version: 1.0.0.1 (1.0)
   - Package ID: 03358000000Q8xqAAC
   - Version ID: 04t58000000SGw3AAG

6. **Nintex DocGen** (Loop)
   - Version: 20.22.1.1 (20.22.1)
   - Package ID: 03380000000AOBYAA4
   - Version ID: 04tHu000004V7nzIAC

7. **Data Tool** (NXDO)
   - Version: 1.31.0.1 (Remote Site Settings Fix)
   - Package ID: 0338c000000jQfeAAE
   - Version ID: 04t8c000000ZxmMAAS

8. **b2bmaIntegration** (b2bma)
   - Version: 1.7.0.2 (Pardot Internal Integration)
   - Package ID: 033f40000004aGxAAI
   - Version ID: 04t5G000004F39PQAS

## Installation Commands

```bash
# Install packages using Salesforce CLI
sf package install --package 04tGA000005F6iKYAS --target-org <your-org-alias> --wait 30 --no-prompt
sf package install --package 04t1U000007kPT0QAM --target-org <your-org-alias> --wait 30 --no-prompt
sf package install --package 04tIg0000004fiDIAQ --target-org <your-org-alias> --wait 30 --no-prompt
sf package install --package 04t4P000002qntuQAA --target-org <your-org-alias> --wait 30 --no-prompt
sf package install --package 04t58000000SGw3AAG --target-org <your-org-alias> --wait 30 --no-prompt
sf package install --package 04tHu000004V7nzIAC --target-org <your-org-alias> --wait 30 --no-prompt
sf package install --package 04t8c000000ZxmMAAS --target-org <your-org-alias> --wait 30 --no-prompt
sf package install --package 04t5G000004F39PQAS --target-org <your-org-alias> --wait 30 --no-prompt
```

## Alternative: Installation URLs

For manual installation via web browser:

1. QLabs_Utilities: `https://login.salesforce.com/packaging/installPackage.apexp?p0=04tGA000005F6iKYAS`
2. Postspin DevOps: `https://login.salesforce.com/packaging/installPackage.apexp?p0=04t1U000007kPT0QAM`
3. Time Warp: `https://login.salesforce.com/packaging/installPackage.apexp?p0=04tIg0000004fiDIAQ`
4. XDO Automation: `https://login.salesforce.com/packaging/installPackage.apexp?p0=04t4P000002qntuQAA`
5. Sales Insights: `https://login.salesforce.com/packaging/installPackage.apexp?p0=04t58000000SGw3AAG`
6. Nintex DocGen: `https://login.salesforce.com/packaging/installPackage.apexp?p0=04tHu000004V7nzIAC`
7. Data Tool: `https://login.salesforce.com/packaging/installPackage.apexp?p0=04t8c000000ZxmMAAS`
8. b2bmaIntegration: `https://login.salesforce.com/packaging/installPackage.apexp?p0=04t5G000004F39PQAS`

## Notes

- Install these packages in a new org BEFORE deploying any metadata
- Some packages may require specific user permissions or licenses
- Allow sufficient time for package installation (use --wait 30 or longer)
- Verify successful installation before proceeding with metadata deployment
