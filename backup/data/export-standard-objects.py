#!/usr/bin/env python3
"""
Export Standard Object Data
Exports Account, Contact, and other standard objects
"""

import subprocess
import json
import os

ORG_ALIAS = "your-org-alias"
OUTPUT_DIR = "backup/data/standard"

os.makedirs(OUTPUT_DIR, exist_ok=True)

# Standard objects to export with relevant fields
STANDARD_OBJECTS = {
    "Account": [
        "Id", "Name", "Type", "Industry", "Phone", "Website",
        "BillingStreet", "BillingCity", "BillingState", "BillingPostalCode",
        "BillingCountry", "Description", "OwnerId"
    ],
    "Contact": [
        "Id", "FirstName", "LastName", "Email", "Phone", "MobilePhone",
        "AccountId", "Title", "Department", "Birthdate", "OwnerId"
    ],
    "Lead": [
        "Id", "FirstName", "LastName", "Company", "Email", "Phone",
        "Status", "LeadSource", "Industry", "OwnerId"
    ],
    "Opportunity": [
        "Id", "Name", "AccountId", "StageName", "Amount", "CloseDate",
        "Probability", "Type", "LeadSource", "OwnerId"
    ],
    "Case": [
        "Id", "CaseNumber", "Subject", "Status", "Priority", "Origin",
        "AccountId", "ContactId", "Description", "OwnerId"
    ],
}

def export_object(sobject_name, fields):
    """Export data for a standard object"""
    try:
        field_list = ", ".join(fields)
        query = f"SELECT {field_list} FROM {sobject_name} LIMIT 2000"

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
            output_file = os.path.join(OUTPUT_DIR, f"{sobject_name}.json")
            with open(output_file, 'w') as f:
                json.dump({
                    'records': records,
                    'totalSize': len(records),
                    'object': sobject_name
                }, f, indent=2)
            print(f"  ✓ Exported {len(records)} {sobject_name} records")
            return len(records)
        else:
            print(f"  ⊘ No {sobject_name} records found")
            return 0

    except Exception as e:
        print(f"  ✗ Error exporting {sobject_name}: {e}")
        return 0

def main():
    print("Exporting Standard Object Data...")
    print()

    total = 0
    for sobject, fields in STANDARD_OBJECTS.items():
        print(f"Exporting {sobject}...")
        count = export_object(sobject, fields)
        total += count
        print()

    print(f"Total standard object records exported: {total}")

if __name__ == "__main__":
    main()
