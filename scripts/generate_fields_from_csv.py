import csv
import os
import xml.etree.ElementTree as ET
from xml.dom import minidom

CSV_FILE = 'colten_care_fields_master_list.csv'
BASE_PATH = 'force-app/main/default/objects'

def create_directory(path):
    if not os.path.exists(path):
        os.makedirs(path)

def get_xml_header():
    return '<?xml version="1.0" encoding="UTF-8"?>\n'

def format_xml(elem):
    rough_string = ET.tostring(elem, 'utf-8')
    reparsed = minidom.parseString(rough_string)
    # Remove empty lines caused by pretty print on text nodes
    return reparsed.toprettyxml(indent="    ")

def create_object_metadata(object_name, label=None, plural_label=None):
    # Always create/overwrite to ensure correct settings
    object_dir = os.path.join(BASE_PATH, object_name)
    create_directory(object_dir)
    
    meta_file_path = os.path.join(object_dir, f'{object_name}.object-meta.xml')
    if os.path.exists(meta_file_path):
        return

    root = ET.Element('CustomObject', xmlns="http://soap.sforce.com/2006/04/metadata")
    
    ET.SubElement(root, 'deploymentStatus').text = 'Deployed'
    
    # Calculate Label
    calculated_label = label
    if not calculated_label:
        calculated_label = object_name.replace('__c', '').replace('_', ' ')
    
    ET.SubElement(root, 'label').text = calculated_label
        
    if plural_label:
        ET.SubElement(root, 'pluralLabel').text = plural_label
    else:
        # Simple pluralization
        if calculated_label.endswith('s'):
             ET.SubElement(root, 'pluralLabel').text = calculated_label
        else:
             ET.SubElement(root, 'pluralLabel').text = calculated_label + 's'
        
    ET.SubElement(root, 'sharingModel').text = 'ReadWrite'
    
    # Add essential flags
    ET.SubElement(root, 'enableHistory').text = 'true'
    ET.SubElement(root, 'enableActivities').text = 'true'
    ET.SubElement(root, 'enableReports').text = 'true'
    ET.SubElement(root, 'enableSearch').text = 'true'
    ET.SubElement(root, 'enableSharing').text = 'true'
    ET.SubElement(root, 'enableStreamingApi').text = 'true'
    
    name_field = ET.SubElement(root, 'nameField')
    ET.SubElement(name_field, 'label').text = calculated_label + ' Name'
    ET.SubElement(name_field, 'type').text = 'Text'

    with open(meta_file_path, 'w') as f:
        f.write(format_xml(root))
    print(f"Created/Updated object metadata: {meta_file_path}")

def create_field_metadata(row):
    # Clean keys
    row = {k.strip(): v for k, v in row.items() if k}
    
    object_name = row['Object']
    api_name = row['Field API Name'].strip()
    label = row['Field Label'].strip()
    field_type = row['Field Type'].strip()

    # --- Robust Fix for Shifted Columns ---
    # Fix Relationship fields shifted right
    ref_to = row.get('Reference To', '').strip()
    if field_type in ('Lookup', 'Master-Detail') and not ref_to:
        # Columns to check in order: Relationship Name, Relationship Label, Delete Constraint, Master Detail
        candidates = ['Relationship Name', 'Relationship Label', 'Delete Constraint', 'Master Detail']
        found_idx = -1
        
        # Valid object names usually start with uppercase, contain letters, no spaces (unless standard?), end with __c or are standard
        # Simple heuristic: Ends with __c or is in a known list of standard objects
        known_standard = {'Account', 'Contact', 'Opportunity', 'User', 'Product2', 'Pricebook2', 'Case', 'Solution', 'Campaign', 'Lead', 'Event', 'Task'}
        
        for i, col in enumerate(candidates):
            val = row.get(col)
            if not val: continue
            val = val.strip()
            # Check if looks like object
            is_obj = (val in known_standard) or (val.endswith('__c'))
            if is_obj:
                found_idx = i
                break
        
        if found_idx != -1:
            # Shift Found!
            # If found at 0 (Relationship Name), shift is 1.
            # If found at 1 (Relationship Label), shift is 2.
            # We need to map:
            # Ref To <- found_col
            # Rel Name <- found_col + 1
            # Rel Label <- found_col + 2
            # Del Const <- found_col + 3
            
            # Since dict is not ordered by index access easily, using keys
            keys = ['Reference To', 'Relationship Name', 'Relationship Label', 'Delete Constraint', 'Master Detail']
            # We want to pull values from (0 + shift + 1) -> (1 + shift) because 'Reference To' is conceptually index -1 in candidate list?
            # No.
            # Ref To is keys[0].
            # candidates[0] is keys[1].
            # If found at candidates[0], then value for keys[0] is at keys[1]. Shift 1.
            # If found at candidates[1], then value for keys[0] is at keys[2]. Shift 2.
            
            shift = found_idx + 1 
            # Apply shift
            # We need to read from right to left to avoid overwriting? Or just copy to temp
            vals = {}
            for k_idx in range(len(keys)):
                src_key_idx = k_idx + shift
                if src_key_idx < len(keys):
                    src_key = keys[src_key_idx]
                    vals[keys[k_idx]] = row.get(src_key)
                else:
                     # If we run off end, check Track History/Feed? 
                     # For now, just None/Empty is fine as we mostly care about RefTo/Names
                     vals[keys[k_idx]] = ''
            
            # Update row
            for k, v in vals.items():
                row[k] = v

    # Fix Description shifted to Picklist Values (Lookup/Text shift right)
    if field_type not in ('Picklist', 'Multi-Select Picklist'):
        desc = row.get('Description')
        pick_val = row.get('Picklist Values (pipe separated)')
        if (not desc) and pick_val:
            row['Description'] = pick_val
            # row['Picklist Values (pipe separated)'] = '' # Optional to clear, but harmless
            
    # Fix Picklist Values shifted to Help Text (Picklist shift left)
    if field_type in ('Picklist', 'Multi-Select Picklist'):
        pick_val = row.get('Picklist Values (pipe separated)')
        help_text = row.get('Help Text')
        if (not pick_val or pick_val.strip() == '') and help_text and '|' in help_text:
            row['Picklist Values (pipe separated)'] = help_text
            row['Help Text'] = ''
            

    # -----------------------------------------

    # Debug print for specific failing field
    if api_name == 'Allocated_Room__c':
        print(f"DEBUG ROW: {row}")
    
    # Helper to get value or default if empty
    def get_val(key, default):
        val = row.get(key)
        if val is None or val.strip() == '':
            return default
        return val

    # Create object dir if not exists (and simple metadata)
    if object_name.endswith('__c'):
        create_object_metadata(object_name)

    fields_dir = os.path.join(BASE_PATH, object_name, 'fields')
    create_directory(fields_dir)
    
    root = ET.Element('CustomField', xmlns="http://soap.sforce.com/2006/04/metadata")
    ET.SubElement(root, 'fullName').text = api_name
    ET.SubElement(root, 'label').text = label
    ET.SubElement(root, 'type').text = map_field_type(field_type)
    
    if row.get('Description'):
        ET.SubElement(root, 'description').text = row['Description']
    
    if row.get('Help Text'):
        ET.SubElement(root, 'inlineHelpText').text = row['Help Text']
        
    if row.get('Required') == 'TRUE':
        ET.SubElement(root, 'required').text = 'true'
    else:
        ET.SubElement(root, 'required').text = 'false'
        
    # Map Resident/Resident__c reference to Account
    if field_type in ('Lookup', 'Master-Detail'):
        ref = row.get('Reference To', '').strip()
        if ref in ('Resident', 'Resident__c'):
            row['Reference To'] = 'Account'

    if field_type == 'Text':
        ET.SubElement(root, 'length').text = get_val('Length', '255')
        ET.SubElement(root, 'unique').text = 'true' if row.get('Unique') == 'TRUE' else 'false'
        ET.SubElement(root, 'externalId').text = 'true' if row.get('External ID') == 'TRUE' else 'false'

    elif field_type == 'Long Text Area':
        ET.SubElement(root, 'length').text = get_val('Length', '32768')
        ET.SubElement(root, 'visibleLines').text = '3'
        
    elif field_type == 'Text Area':
         pass # No length needed usually, or default

    elif field_type == 'Number':
        ET.SubElement(root, 'precision').text = get_val('Precision', '18')
        ET.SubElement(root, 'scale').text = get_val('Scale', '0')
        
    elif field_type == 'Currency':
        ET.SubElement(root, 'precision').text = get_val('Precision', '18')
        ET.SubElement(root, 'scale').text = get_val('Scale', '2')
        
    elif field_type == 'Checkbox':
        ET.SubElement(root, 'defaultValue').text = row.get('Default Value', 'false').lower()
        
    elif field_type in ('Picklist', 'Multi-Select Picklist'):
        value_set = ET.SubElement(root, 'valueSet')
        
        # Fields on Event object that have 'Event' as Default Value but missing from list
        event_fields_with_hack = [
            'Event_Category__c',
            'Visit_Outcome__c',
            'Tour_Provided__c',
            'Meal_Provided__c',
            'Activity_Attended__c'
        ]

        # Restricted check
        is_restricted = 'true'
        if api_name in event_fields_with_hack:
            is_restricted = 'false'
        ET.SubElement(value_set, 'restricted').text = is_restricted

        definition = ET.SubElement(value_set, 'valueSetDefinition')
        ET.SubElement(definition, 'sorted').text = 'false'
        
        values = row.get('Picklist Values (pipe separated)', '').split('|')
        
        # Ensure default value is in list
        default_val = row.get('Default Value')
        if default_val and default_val.strip() and default_val not in values:
             values.insert(0, default_val)

        # Event_Category__c hack for 'Event' value
        if api_name in event_fields_with_hack:
             # Rename Event to General Event to avoid collision
             if 'General Event' not in values:
                 values.insert(0, 'General Event')
             if 'Event' in values:
                 values.remove('Event') # Remove pure Event from list if parsed

        for val in values:
            val = val.strip()
            if not val: continue
            value_elem = ET.SubElement(definition, 'value')
            ET.SubElement(value_elem, 'fullName').text = val
            # Handle Default
            is_default = 'false'
            if default_val and val == default_val:
                is_default = 'true'
            ET.SubElement(value_elem, 'default').text = is_default
            ET.SubElement(value_elem, 'label').text = val

        if field_type == 'Multi-Select Picklist':
             ET.SubElement(root, 'visibleLines').text = '4'

    elif field_type == 'Lookup':
        ET.SubElement(root, 'referenceTo').text = row['Reference To']
        ET.SubElement(root, 'relationshipLabel').text = row.get('Relationship Label', '')
        ET.SubElement(root, 'relationshipName').text = row.get('Relationship Name', '')
        
        del_constraint = row.get('Delete Constraint')
        if not del_constraint or del_constraint.strip() == '':
             del_constraint = 'SetNull'
        ET.SubElement(root, 'deleteConstraint').text = del_constraint
        
    elif field_type == 'Master-Detail':
        ET.SubElement(root, 'referenceTo').text = row['Reference To']
        ET.SubElement(root, 'relationshipLabel').text = row.get('Relationship Label', '')
        ET.SubElement(root, 'relationshipName').text = row.get('Relationship Name', '')
        ET.SubElement(root, 'writeRequiresMasterRead').text = 'false'
        
        # Update Object Sharing Model to ControlledByParent
        update_sharing_model(object_name)


    # Common boolean flags
    if row.get('Track History') == 'TRUE':
        ET.SubElement(root, 'trackHistory').text = 'true'
    else:
        ET.SubElement(root, 'trackHistory').text = 'false'
        
    if row.get('Track Feed') == 'TRUE':
        ET.SubElement(root, 'trackTrending').text = 'true' # Map to trackTrending or trackFeedHistory depending on object
    else:
         ET.SubElement(root, 'trackTrending').text = 'false'

    file_path = os.path.join(fields_dir, f'{api_name}.field-meta.xml')
    with open(file_path, 'w') as f:
        f.write(format_xml(root))
    print(f"Created field: {file_path}")

def map_field_type(val):
    val = val.strip()
    mapping = {
        'Text': 'Text',
        'Checkbox': 'Checkbox',
        'Picklist': 'Picklist',
        'Multi-Select Picklist': 'MultiselectPicklist',
        'Date': 'Date',
        'DateTime': 'DateTime',
        'Currency': 'Currency',
        'Number': 'Number',
        'Percent': 'Percent',
        'Email': 'Email',
        'Phone': 'Phone',
        'URL': 'Url',
        'Long Text Area': 'LongTextArea',
        'Text Area': 'TextArea',
        'Lookup': 'Lookup',
        'Master-Detail': 'MasterDetail'
    }
    return mapping.get(val, 'Text')

def update_sharing_model(object_name):
    object_dir = os.path.join(BASE_PATH, object_name)
    meta_file_path = os.path.join(object_dir, f'{object_name}.object-meta.xml')
    
    if not os.path.exists(meta_file_path):
        return

    try:
        tree = ET.parse(meta_file_path)
        root = tree.getroot()
        
        ns = {'mvn': 'http://soap.sforce.com/2006/04/metadata'}
        ET.register_namespace('', ns['mvn'])
        
        updated = False
        for child in root:
            if child.tag.endswith('sharingModel'):
                if child.text != 'ControlledByParent':
                    child.text = 'ControlledByParent'
                    updated = True
                break
        
        if updated:
            with open(meta_file_path, 'w') as f:
                f.write(format_xml(root))
            print(f"Updated sharingModel for {object_name} to ControlledByParent")
            
    except Exception as e:
        print(f"Error updating sharing model for {object_name}: {e}")


def main():
    if not os.path.exists(CSV_FILE):
        print(f"Error: {CSV_FILE} not found.")
        return

    with open(CSV_FILE, 'r', encoding='utf-8-sig') as f:
        reader = csv.DictReader(f)
        for row in reader:
            # Skip empty lines
            if not row['Object'] or not row['Field API Name']:
                continue
            try:
                create_field_metadata(row)
            except Exception as e:
                print(f"Error creating field {row.get('Field API Name')}: {e}")

if __name__ == '__main__':
    main()
