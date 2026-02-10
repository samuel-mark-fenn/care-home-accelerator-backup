import os

fields = [
    {"api_name": "Property_Code__c", "label": "Property Code", "type": "Text", "length": 20, "unique": True},
    {"api_name": "Region__c", "label": "Region", "type": "Picklist", "values": ["Dorset", "Hampshire", "West Sussex", "Wiltshire"]},
    {"api_name": "Address__c", "label": "Address", "type": "TextArea"},
    {"api_name": "City__c", "label": "City", "type": "Text", "length": 100},
    {"api_name": "Postcode__c", "label": "Postcode", "type": "Text", "length": 10},
    {"api_name": "Phone__c", "label": "Phone", "type": "Phone"},
    {"api_name": "Email__c", "label": "Email", "type": "Email"},
    {"api_name": "Website__c", "label": "Website", "type": "Url"},
    {"api_name": "Total_Beds__c", "label": "Total Beds", "type": "Number", "precision": 3, "scale": 0},
    {"api_name": "CQC_Rating__c", "label": "CQC Rating", "type": "Picklist", "values": ["Outstanding", "Good", "Requires Improvement", "Inadequate", "Not Rated"]},
    {"api_name": "CQC_Registration_Number__c", "label": "CQC Registration Number", "type": "Text", "length": 50},
    {"api_name": "Last_CQC_Inspection_Date__c", "label": "Last CQC Inspection Date", "type": "Date"},
    {"api_name": "Status__c", "label": "Status", "type": "Picklist", "values": ["Active", "Temporarily Closed", "Under Refurbishment", "Closed"]},
    {"api_name": "Care_Types_Offered__c", "label": "Care Types Offered", "type": "MultiselectPicklist", "values": ["Residential", "Nursing", "Dementia", "Respite", "End of Life", "Assisted"], "visibleLines": 4},
    {"api_name": "Facilities__c", "label": "Facilities", "type": "MultiselectPicklist", "values": ["Garden", "Café", "Salon", "Minibus"], "visibleLines": 4},
]

def generate_field_xml(field):
    api_name = field["api_name"]
    label = field["label"]
    field_type = field["type"]
    
    xml = f"""<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>{api_name}</fullName>
    <label>{label}</label>
    <type>{field_type}</type>
    <required>false</required>
    <trackHistory>false</trackHistory>
    <trackTrending>false</trackTrending>
"""
    
    if field_type == "Text":
        xml += f"    <length>{field['length']}</length>\n"
        if field.get("unique"):
            xml += "    <unique>true</unique>\n"
        else:
            xml += "    <unique>false</unique>\n"
        xml += "    <externalId>false</externalId>\n"
    
    if field_type == "Number":
        xml += f"    <precision>{field['precision']}</precision>\n"
        xml += f"    <scale>{field['scale']}</scale>\n"
        xml += "    <externalId>false</externalId>\n"

    if field_type in ["Picklist", "MultiselectPicklist"]:
        xml += "    <valueSet>\n"
        xml += "        <restricted>true</restricted>\n"
        xml += "        <valueSetDefinition>\n"
        xml += "            <sorted>false</sorted>\n"
        for val in field["values"]:
            xml += "            <value>\n"
            xml += f"                <fullName>{val}</fullName>\n"
            xml += "                <default>false</default>\n"
            xml += f"                <label>{val}</label>\n"
            xml += "            </value>\n"
        xml += "        </valueSetDefinition>\n"
        xml += "    </valueSet>\n"
        if field_type == "MultiselectPicklist":
            xml += f"    <visibleLines>{field['visibleLines']}</visibleLines>\n"

    xml += "</CustomField>"
    return xml

base_dir = "force-app/main/default/objects/Property__c/fields"
os.makedirs(base_dir, exist_ok=True)

for field in fields:
    file_path = os.path.join(base_dir, f"{field['api_name']}.field-meta.xml")
    with open(file_path, "w") as f:
        f.write(generate_field_xml(field))
    print(f"Generated {file_path}")
