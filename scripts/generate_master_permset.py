import os
import xml.etree.ElementTree as ET

def generate_permission_set():
    objects_dir = 'force-app/main/default/objects'
    output_file = 'force-app/main/default/permissionsets/ColtenCareMasterAccess.permissionset-meta.xml'
    
    field_permissions = []
    object_permissions = []
    
    # Custom objects to include
    custom_objects = [
        'Assessment__c', 'Campaign', 'Contract__c', 'Enquiry__c', 
        'Opportunity', 'Product2', 'Property__c', 'Resident_Assessment__c', 
        'Resident__c', 'Room_Occupancy__c', 'Room__c', 'Survey__c', 
        'Survey_Response__c', 'Account', 'Contact'
    ]
    
    for obj_name in sorted(custom_objects):
        obj_path = os.path.join(objects_dir, obj_name)
        if not os.path.exists(obj_path):
            continue
            
        # Object permissions
        is_custom = obj_name.endswith('__c')
        object_permissions.append(f"""    <objectPermissions>
        <allowCreate>true</allowCreate>
        <allowDelete>true</allowDelete>
        <allowEdit>true</allowEdit>
        <allowRead>true</allowRead>
        <modifyAllRecords>true</modifyAllRecords>
        <object>{obj_name}</object>
        <viewAllRecords>true</viewAllRecords>
    </objectPermissions>""")

        # Field permissions
        fields_dir = os.path.join(obj_path, 'fields')
        if os.path.exists(fields_dir):
            for field_file in sorted(os.listdir(fields_dir)):
                if not field_file.endswith('.field-meta.xml'):
                    continue
                
                field_name = field_file.replace('.field-meta.xml', '')
                full_field_name = f"{obj_name}.{field_name}"
                
                # Read field meta to check for formula or master-detail
                field_path = os.path.join(fields_dir, field_file)
                with open(field_path, 'r') as f:
                    content = f.read()
                
                is_editable = True
                is_formula = '<formula>' in content
                is_master_detail = '<type>MasterDetail</type>' in content
                
                # Formula fields and Master-Detail fields cannot have field permissions set this way usually,
                # or at least they cause errors if we try to set them as editable or even included.
                if is_formula or is_master_detail:
                    continue
                
                field_permissions.append(f"""    <fieldPermissions>
        <editable>true</editable>
        <field>{full_field_name}</field>
        <readable>true</readable>
    </fieldPermissions>""")

    # Combine into final XML
    xml_content = f"""<?xml version="1.0" encoding="UTF-8"?>
<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Colten Care Master Access</label>
    <description>Master access to all custom fields and objects created for the project.</description>
    <hasActivationRequired>false</hasActivationRequired>
{"".join(field_permissions)}
{"".join(object_permissions)}
</PermissionSet>"""

    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    with open(output_file, 'w') as f:
        f.write(xml_content)
    print(f"Generated {output_file}")

if __name__ == "__main__":
    generate_permission_set()
