#!/usr/bin/env python3
"""
Comprehensive Data Export Script for Care Home Accelerator
Exports all data from custom objects with proper field handling
"""

import subprocess
import json
import os
import sys

ORG_ALIAS = "your-org-alias"
OUTPUT_DIR = "backup/data"

# Ensure output directory exists
os.makedirs(OUTPUT_DIR, exist_ok=True)

# List of custom objects to export
OBJECTS = [
    "Assessment__c",
    "Property__c",
    "Room__c",
    "Room_Occupancy__c",
    "Room_Feature__c",
    "Resident__c",
    "Resident_Assessment__c",
    "Resident_Preference__c",
    "Preference__c",
    "Payment__c",
    "Survey__c",
    "Survey_Response__c",
    "Contract__c",
    "BenefitManagementRecertification__c",
]

def get_object_fields(sobject_name):
    """Get all queryable fields for a given object"""
    try:
        result = subprocess.run(
            ["sf", "sobject", "describe", "--sobject", sobject_name,
             "--target-org", ORG_ALIAS, "--json"],
            capture_output=True,
            text=True,
            check=True
        )
        data = json.loads(result.stdout)
        fields = [f['name'] for f in data['result']['fields']
                 if not f['name'].endswith('__pr') and f.get('type') != 'address']
        return fields
    except Exception as e:
        print(f"  Error getting fields for {sobject_name}: {e}")
        return None

def export_object_data(sobject_name, fields):
    """Export data for a given object"""
    try:
        # Build SOQL query
        field_list = ", ".join(fields)
        query = f"SELECT {field_list} FROM {sobject_name}"

        # Export to JSON
        result = subprocess.run(
            ["sf", "data", "query", "--query", query,
             "--target-org", ORG_ALIAS, "--json"],
            capture_output=True,
            text=True,
            check=True
        )

        data = json.loads(result.stdout)
        records = data.get('result', {}).get('records', [])

        if records:
            # Save to file
            output_file = os.path.join(OUTPUT_DIR, f"{sobject_name}.json")
            with open(output_file, 'w') as f:
                json.dump({
                    'records': records,
                    'totalSize': len(records),
                    'object': sobject_name
                }, f, indent=2)
            print(f"  ✓ Exported {len(records)} records to {output_file}")
            return len(records)
        else:
            print(f"  ⊘ No records found for {sobject_name}")
            return 0

    except Exception as e:
        print(f"  ✗ Error exporting {sobject_name}: {e}")
        return 0

def main():
    print("=" * 60)
    print("Care Home Accelerator - Data Export")
    print("=" * 60)
    print(f"Org: {ORG_ALIAS}")
    print(f"Output: {OUTPUT_DIR}")
    print()

    total_records = 0
    successful_exports = 0

    for sobject in OBJECTS:
        print(f"Processing {sobject}...")
        fields = get_object_fields(sobject)

        if fields:
            count = export_object_data(sobject, fields)
            total_records += count
            if count > 0:
                successful_exports += 1

        print()

    print("=" * 60)
    print(f"Export Complete!")
    print(f"Objects exported: {successful_exports}/{len(OBJECTS)}")
    print(f"Total records: {total_records}")
    print("=" * 60)

if __name__ == "__main__":
    main()
