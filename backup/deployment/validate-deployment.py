#!/usr/bin/env python3
"""
Deployment Validation Script
Validates that a deployment matches the backup
"""

import subprocess
import json
import sys

def get_installed_packages(org_alias):
    """Get installed packages from an org"""
    try:
        result = subprocess.run(
            ["sf", "package", "installed", "list", "--target-org", org_alias, "--json"],
            capture_output=True,
            text=True,
            check=True
        )
        data = json.loads(result.stdout)
        return {pkg['SubscriberPackageName']: pkg['SubscriberPackageVersionNumber']
                for pkg in data.get('result', [])}
    except Exception as e:
        print(f"Error getting packages: {e}")
        return {}

def get_custom_objects(org_alias):
    """Get custom objects from an org"""
    try:
        result = subprocess.run(
            ["sf", "sobject", "list", "--sobject-type", "custom",
             "--target-org", org_alias, "--json"],
            capture_output=True,
            text=True,
            check=True
        )
        data = json.loads(result.stdout)
        return set(data.get('result', []))
    except Exception as e:
        print(f"Error getting custom objects: {e}")
        return set()

def count_records(org_alias, sobject):
    """Count records in an object"""
    try:
        result = subprocess.run(
            ["sf", "data", "query", "--query", f"SELECT COUNT() FROM {sobject}",
             "--target-org", org_alias, "--json"],
            capture_output=True,
            text=True,
            check=True
        )
        data = json.loads(result.stdout)
        return data.get('result', {}).get('totalSize', 0)
    except Exception:
        return 0

def validate_deployment(target_org):
    """Validate a deployment against expected configuration"""

    print("=" * 70)
    print("Care Home Accelerator - Deployment Validation")
    print("=" * 70)
    print(f"Target Org: {target_org}\n")

    # Expected configuration from backup
    EXPECTED_PACKAGES = {
        "QLabs_Utilities": "1.193.0.1",
        "Salesforce - Postspin DevOps": "1.6.0.1",
        "Time Warp": "1.15.0.1",
        "XDO Automation": "2.11.0.1",
        "Sales Insights": "1.0.0.1",
        "Nintex DocGen": "20.22.1.1",
        "Data Tool": "1.31.0.1",
        "b2bmaIntegration": "1.7.0.2"
    }

    EXPECTED_OBJECTS = {
        'Assessment__c', 'Property__c', 'Room__c', 'Room_Occupancy__c',
        'Resident__c', 'Resident_Assessment__c', 'Resident_Preference__c',
        'Preference__c', 'Payment__c', 'Survey__c', 'Survey_Response__c',
        'Contract__c', 'BenefitManagementRecertification__c', 'Room_Feature__c'
    }

    EXPECTED_DATA_COUNTS = {
        'Property__c': 22,
        'Room__c': 216,
        'Room_Occupancy__c': 295,
        'Resident__c': 1,
        'Resident_Assessment__c': 6,
        'Resident_Preference__c': 17,
        'Preference__c': 12,
        'Assessment__c': 5,
        'Survey__c': 15,
        'Survey_Response__c': 3
    }

    # Validate packages
    print("📦 Validating Managed Packages...")
    print("-" * 70)
    installed_packages = get_installed_packages(target_org)

    all_packages_ok = True
    for pkg_name, expected_version in EXPECTED_PACKAGES.items():
        if pkg_name in installed_packages:
            actual_version = installed_packages[pkg_name]
            if actual_version == expected_version:
                print(f"  ✓ {pkg_name}: {actual_version}")
            else:
                print(f"  ⚠ {pkg_name}: {actual_version} (expected {expected_version})")
                all_packages_ok = False
        else:
            print(f"  ✗ {pkg_name}: NOT INSTALLED")
            all_packages_ok = False

    if all_packages_ok:
        print("\n✅ All packages validated successfully\n")
    else:
        print("\n⚠️  Some packages missing or wrong version\n")

    # Validate custom objects
    print("🏗️  Validating Custom Objects...")
    print("-" * 70)
    deployed_objects = get_custom_objects(target_org)

    missing_objects = EXPECTED_OBJECTS - deployed_objects
    extra_objects = deployed_objects - EXPECTED_OBJECTS

    for obj in sorted(EXPECTED_OBJECTS):
        if obj in deployed_objects:
            print(f"  ✓ {obj}")
        else:
            print(f"  ✗ {obj} - MISSING")

    if not missing_objects:
        print("\n✅ All custom objects deployed successfully\n")
    else:
        print(f"\n⚠️  Missing objects: {', '.join(missing_objects)}\n")

    # Validate data
    print("📊 Validating Data Counts...")
    print("-" * 70)
    total_expected = sum(EXPECTED_DATA_COUNTS.values())
    total_actual = 0

    for obj, expected_count in EXPECTED_DATA_COUNTS.items():
        if obj in deployed_objects:
            actual_count = count_records(target_org, obj)
            total_actual += actual_count

            if actual_count >= expected_count * 0.9:  # Allow 10% variance
                print(f"  ✓ {obj}: {actual_count} records (expected ~{expected_count})")
            else:
                print(f"  ⚠ {obj}: {actual_count} records (expected ~{expected_count})")
        else:
            print(f"  ✗ {obj}: Object not found")

    print(f"\nTotal records: {total_actual} (expected ~{total_expected})")

    if total_actual >= total_expected * 0.8:
        print("✅ Data import looks good\n")
    else:
        print("⚠️  Data import may be incomplete\n")

    # Summary
    print("=" * 70)
    print("VALIDATION SUMMARY")
    print("=" * 70)

    issues = []
    if not all_packages_ok:
        issues.append("- Some managed packages missing or wrong version")
    if missing_objects:
        issues.append("- Some custom objects not deployed")
    if total_actual < total_expected * 0.8:
        issues.append("- Data import appears incomplete")

    if not issues:
        print("✅ All validation checks passed!")
        print("   Deployment appears successful.")
        return 0
    else:
        print("⚠️  Issues found:")
        for issue in issues:
            print(f"   {issue}")
        return 1

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 validate-deployment.py <target-org-alias>")
        sys.exit(1)

    sys.exit(validate_deployment(sys.argv[1]))
