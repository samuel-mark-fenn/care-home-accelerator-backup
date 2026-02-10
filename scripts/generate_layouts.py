
import csv
import os
import xml.etree.ElementTree as ET
from xml.dom import minidom
from collections import defaultdict

CSV_FILE = 'colten_care_fields_master_list.csv'
LAYOUTS_DIR = 'force-app/main/default/layouts'
OBJECTS_TO_SKIP = ['Event', 'Account']

def create_directory(path):
    if not os.path.exists(path):
        os.makedirs(path)

def format_xml(elem):
    rough_string = ET.tostring(elem, 'utf-8')
    reparsed = minidom.parseString(rough_string)
    return reparsed.toprettyxml(indent="    ")

def get_layout_name(object_name):
    # Standard objects: Account-Account Layout
    # Custom objects: Room__c-Room Layout
    clean_name = object_name.replace('__c', '').replace('_', ' ')
    return f"{object_name}-{clean_name} Layout"

def generate_layout(object_name, fields):
    layout_name = get_layout_name(object_name)
    file_path = os.path.join(LAYOUTS_DIR, f"{layout_name}.layout-meta.xml")
    
    root = ET.Element('Layout', xmlns="http://soap.sforce.com/2006/04/metadata")
    
    # --- Layout Sections ---
    
    # 1. Information Section (The main fields)
    section = ET.SubElement(root, 'layoutSections')
    ET.SubElement(section, 'customLabel').text = 'false'
    ET.SubElement(section, 'detailHeading').text = 'false'
    ET.SubElement(section, 'editHeading').text = 'true'
    ET.SubElement(section, 'label').text = 'Information'
    ET.SubElement(section, 'style').text = 'TwoColumnsTopToBottom'
    
    # Prepare columns
    left_col = ET.SubElement(section, 'layoutColumns')
    right_col = ET.SubElement(section, 'layoutColumns')
    
    # Ensure Name field is present (Required by SF)
    has_name = any(f['Field API Name'].strip() == 'Name' for f in fields)
    if not has_name and object_name != 'Task' and object_name != 'Event':
         item = ET.Element('layoutItems')
         ET.SubElement(item, 'behavior').text = 'Required'
         ET.SubElement(item, 'field').text = 'Name'
         left_col.append(item)

    # Standard Object required fields
    REQUIRED_APPENDS = {
        'Contact': ['AccountId'],
        'Opportunity': ['AccountId', 'StageName', 'CloseDate', 'Probability'],
        'Case': ['ContactId', 'AccountId', 'Status', 'Priority', 'Origin'],
        'Lead': ['Status', 'Company']
    }
    
    extra_reqs = REQUIRED_APPENDS.get(object_name, [])
    for req in extra_reqs:
        # Check if already in fields (CSV might include them)
        if any(f['Field API Name'].strip() == req for f in fields):
            continue
        
        item = ET.Element('layoutItems')
        ET.SubElement(item, 'behavior').text = 'Required'
        ET.SubElement(item, 'field').text = req
        # Append to right col for balance, or left?
        left_col.append(item)

    for i, field in enumerate(fields):
        api_name = field['Field API Name'].strip()
        if api_name == 'Name': continue # Already added if present, or handled above
        
        # Create LayoutItem
        item = ET.Element('layoutItems')
        ET.SubElement(item, 'behavior').text = 'Edit' # Default to Edit
        ET.SubElement(item, 'field').text = api_name
        
        # Distribute
        # If we added Name to left, maybe we should balance?
        # Simple alternation is fine.
        if i % 2 == 0:
            right_col.append(item) # Start filling right if Name took left 1st slot? 
            # Or just keep alternating.
        else:
            left_col.append(item)
            
    # 2. System Information
    sys_section = ET.SubElement(root, 'layoutSections')
    ET.SubElement(sys_section, 'customLabel').text = 'false'
    ET.SubElement(sys_section, 'detailHeading').text = 'false'
    ET.SubElement(sys_section, 'editHeading').text = 'true'
    ET.SubElement(sys_section, 'label').text = 'System Information'
    ET.SubElement(sys_section, 'style').text = 'TwoColumnsTopToBottom'
    
    sys_left = ET.SubElement(sys_section, 'layoutColumns')
    sys_right = ET.SubElement(sys_section, 'layoutColumns')
    
    # Created By
    cb_item = ET.SubElement(sys_left, 'layoutItems')
    ET.SubElement(cb_item, 'behavior').text = 'Readonly'
    ET.SubElement(cb_item, 'field').text = 'CreatedById'

    # Last Modified By
    lmb_item = ET.SubElement(sys_right, 'layoutItems')
    ET.SubElement(lmb_item, 'behavior').text = 'Readonly'
    ET.SubElement(lmb_item, 'field').text = 'LastModifiedById'

    # 3. Custom Links (Required for valid layout)
    link_section = ET.SubElement(root, 'layoutSections')
    ET.SubElement(link_section, 'customLabel').text = 'true'
    ET.SubElement(link_section, 'detailHeading').text = 'false'
    ET.SubElement(link_section, 'editHeading').text = 'false'
    ET.SubElement(link_section, 'label').text = 'Custom Links'
    ET.SubElement(link_section, 'style').text = 'CustomLinks'
    ET.SubElement(link_section, 'layoutColumns')
    ET.SubElement(link_section, 'layoutColumns')
    ET.SubElement(link_section, 'layoutColumns')

    # Defaults
    ET.SubElement(root, 'showEmailCheckbox').text = 'false'
    ET.SubElement(root, 'showHighlightsPanel').text = 'false'
    ET.SubElement(root, 'showInteractionLogPanel').text = 'false'
    ET.SubElement(root, 'showRunAssignmentRulesCheckbox').text = 'false'
    ET.SubElement(root, 'showSubmitAndAttachButton').text = 'false'
    
    # Write file
    content = format_xml(root)
    # Fix XML declaration usually added by minidom to include 'standalone' or just standard header?
    # SF usually likes: <?xml version="1.0" encoding="UTF-8"?>
    # minidom adds: <?xml version="1.0" ?> or similar.
    # Let's just write strictly.
    
    with open(file_path, 'w') as f:
        f.write(content)
    
    print(f"Generated layout: {file_path}")

def main():
    create_directory(LAYOUTS_DIR)
    
    # Read CSV and group fields
    fields_by_object = defaultdict(list)
    
    with open(CSV_FILE, 'r', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        for row in reader:
            obj = row['Object'].strip()
            if obj in OBJECTS_TO_SKIP:
                continue
            fields_by_object[obj].append(row)
            
    # Generate layouts
    for obj, fields in fields_by_object.items():
        if not obj: continue
        generate_layout(obj, fields)

if __name__ == "__main__":
    main()
