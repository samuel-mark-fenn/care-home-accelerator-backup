import os

SOURCE_DIR = "force-app/main/default/objects/Assessment__c/fields"
TARGET_DIR = "force-app/main/default/objects/Resident_Assessment__c/fields"

def cleanup_duplicates():
    # List files in Resident_Assessment__c
    if not os.path.exists(TARGET_DIR):
        print("Target dir not found.")
        return

    new_fields = os.listdir(TARGET_DIR)
    
    print(f"Scanning {len(new_fields)} fields in Resident_Assessment__c...")
    
    for filename in new_fields:
        # Check if this file exists in Assessment__c
        old_path = os.path.join(SOURCE_DIR, filename)
        if os.path.exists(old_path):
            os.remove(old_path)
            print(f"Removed duplicate {filename} from Assessment__c")

    # Also remove Assessment_Type__c from Assessment__c as we renamed it to Type__c
    # But retrieve brought it back.
    assess_type = os.path.join(SOURCE_DIR, "Assessment_Type__c.field-meta.xml")
    if os.path.exists(assess_type):
        os.remove(assess_type)
        print("Removed Assessment_Type__c from Assessment__c (replaced by Type__c)")

if __name__ == "__main__":
    cleanup_duplicates()
