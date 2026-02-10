import os
import shutil

SOURCE_DIR = "force-app/main/default/objects/Assessment__c/fields"
TARGET_DIR = "force-app/main/default/objects/Resident_Assessment__c/fields"

# Fields to move from Assessment__c to Resident_Assessment__c
FIELDS_TO_MOVE = [
    "Assessment_Date__c.field-meta.xml",
    "Assessor__c.field-meta.xml",
    "Resident__c.field-meta.xml",
    "Status__c.field-meta.xml",
    "Overall_Outcome__c.field-meta.xml",
    "Care_Level_Recommendation__c.field-meta.xml",
    "Risk_Level__c.field-meta.xml",
    "Accommodation_Recommendations__c.field-meta.xml",
    "Mobility_Assessment__c.field-meta.xml",
    "Nutrition_Assessment__c.field-meta.xml",
    "Personal_Care_Assessment__c.field-meta.xml",
    "Medical_Needs_Assessment__c.field-meta.xml",
    "Mental_Health_Assessment__c.field-meta.xml",
    "Social_Needs_Assessment__c.field-meta.xml",
    "Falls_Risk__c.field-meta.xml",
    "Choking_Risk__c.field-meta.xml",
    "Nutrition_Risk__c.field-meta.xml",
    "Absconding_Risk__c.field-meta.xml",
    "Pressure_Sore_Risk__c.field-meta.xml",
    "Follow_Up_Required__c.field-meta.xml",
    "Follow_Up_Notes__c.field-meta.xml",
    "Location__c.field-meta.xml",
    "Opportunity__c.field-meta.xml" # Moving Opportunity link to instance too
]

def move_fields():
    print("Moving fields...")
    for filename in FIELDS_TO_MOVE:
        src = os.path.join(SOURCE_DIR, filename)
        dst = os.path.join(TARGET_DIR, filename)
        
        if os.path.exists(src):
            shutil.move(src, dst)
            print(f"Moved {filename}")
        else:
            print(f"Warning: {filename} not found in source.")

def create_lookup_to_assessment():
    print("Creating lookup to Assessment__c on component...")
    content = """<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Assessment_Type__c</fullName>
    <description>The archetype of assessment being performed.</description>
    <label>Assessment Type</label>
    <referenceTo>Assessment__c</referenceTo>
    <relationshipLabel>Resident Assessments</relationshipLabel>
    <relationshipName>Resident_Assessments</relationshipName>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>Lookup</type>
</CustomField>
"""
    with open(os.path.join(TARGET_DIR, "Assessment_Type__c.field-meta.xml"), "w") as f:
        f.write(content)

def update_assessment_archetype():
    print("Updating Assessment__c archetype fields...")
    
    # 1. Rename Assessment_Type__c to Type__c (if it exists)
    old_type = os.path.join(SOURCE_DIR, "Assessment_Type__c.field-meta.xml")
    new_type = os.path.join(SOURCE_DIR, "Type__c.field-meta.xml")
    
    if os.path.exists(old_type):
        with open(old_type, "r") as f:
            data = f.read()
        
        data = data.replace("<fullName>Assessment_Type__c</fullName>", "<fullName>Type__c</fullName>")
        data = data.replace("<label>Assessment Type</label>", "<label>Type</label>") # Optional label change
        
        with open(new_type, "w") as f:
            f.write(data)
        
        os.remove(old_type)
        print("Renamed Assessment_Type__c to Type__c")
    
    # 2. Add Description__c
    desc_path = os.path.join(SOURCE_DIR, "Description__c.field-meta.xml")
    desc_content = """<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Description__c</fullName>
    <description>Description of this assessment type.</description>
    <label>Description</label>
    <length>32768</length>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
    <type>LongTextArea</type>
    <visibleLines>5</visibleLines>
</CustomField>
"""
    with open(desc_path, "w") as f:
        f.write(desc_content)
    print("Created Description__c on Assessment__c")

if __name__ == "__main__":
    if not os.path.exists(TARGET_DIR):
        os.makedirs(TARGET_DIR)
    
    move_fields()
    create_lookup_to_assessment()
    update_assessment_archetype()
