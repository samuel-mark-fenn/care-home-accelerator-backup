#!/bin/bash

# Data Export Script for Care Home Accelerator
# This script exports all data from custom objects in the org

ORG_ALIAS="your-org-alias"
OUTPUT_DIR="backup/data"

echo "Starting data export from Salesforce org..."
echo "Target org: $ORG_ALIAS"
echo "Output directory: $OUTPUT_DIR"
echo ""

# List of custom objects to export
OBJECTS=(
    "Assessment__c"
    "Property__c"
    "Room__c"
    "Room_Occupancy__c"
    "Room_Feature__c"
    "Resident__c"
    "Resident_Assessment__c"
    "Resident_Preference__c"
    "Preference__c"
    "Payment__c"
    "Survey__c"
    "Survey_Response__c"
    "Contract__c"
    "BenefitManagementRecertification__c"
    "Knowledge__kav"
)

# Export data for each object
for OBJECT in "${OBJECTS[@]}"
do
    echo "Exporting $OBJECT..."
    sf data export tree \
        --query "SELECT FIELDS(ALL) FROM $OBJECT LIMIT 2000" \
        --target-org "$ORG_ALIAS" \
        --output-dir "$OUTPUT_DIR" \
        --plan 2>/dev/null || echo "  Warning: Could not export $OBJECT (may be empty or have permission issues)"
done

echo ""
echo "Data export completed!"
echo "Files saved to: $OUTPUT_DIR"
