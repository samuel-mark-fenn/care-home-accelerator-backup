import os

fields = [
    {
        "object": "Account",
        "api_name": "Requires_Ensuite__c",
        "label": "Requires Ensuite",
        "type": "Checkbox",
        "defaultValue": "false"
    },
    {
        "object": "Account",
        "api_name": "Prefers_Garden_View__c",
        "label": "Prefers Garden View",
        "type": "Checkbox",
        "defaultValue": "false"
    },
    {
        "object": "Account",
        "api_name": "Requires_Ground_Floor__c",
        "label": "Requires Ground Floor",
        "type": "Checkbox",
        "defaultValue": "false"
    }
]

def create_field(field_data):
    object_name = field_data["object"]
    api_name = field_data["api_name"]
    label = field_data["label"]
    field_type = field_data["type"]
    
    base_path = f"force-app/main/default/objects/{object_name}/fields"
    os.makedirs(base_path, exist_ok=True)
    file_path = f"{base_path}/{api_name}.field-meta.xml"
    
    xml_content = f"""<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>{api_name}</fullName>
    <label>{label}</label>
    <type>{field_type}</type>
"""

    if field_type == "Checkbox":
        xml_content += f"    <defaultValue>{field_data['defaultValue']}</defaultValue>\n"
    
    xml_content += "</CustomField>"
    
    with open(file_path, "w") as f:
        f.write(xml_content)
    print(f"Created {file_path}")

for field in fields:
    create_field(field)
