import json
import subprocess
import random
from datetime import datetime, timedelta

def run_command(command):
    print(f"Running: {command}")
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    
    output = result.stdout
    if not output:
        print(f"No STDOUT. STDERR: {result.stderr}")
        return None
    
    start_index = output.find('{')
    if start_index == -1:
        print(f"No opening brace found in output: {output}")
        return None
    
    json_str = output[start_index:]
    end_index = json_str.rfind('}') + 1
    json_str = json_str[:end_index]
    
    try:
        data = json.loads(json_str)
        if data.get('status') != 0:
            print(f"Command execution status non-zero: {data}")
        return data
    except json.JSONDecodeError as e:
        print(f"JSONDecodeError: {e}")
        return None

def get_properties():
    prop_data = run_command('sf data query -q "SELECT Id, Name FROM Property__c" --json')
    if not prop_data: return []
    return prop_data['result']['records']

def get_rooms():
    room_data = run_command('sf data query -q "SELECT Id, Name, Property__c FROM Room__c" --json')
    if not room_data: return []
    return room_data['result']['records']

def main():
    # Setup data
    rt_resident = '012KZ000000lBWxYAM' # RecType: Resident on Account
    
    properties = get_properties()
    rooms = get_rooms()
    
    if not properties or not rooms:
        print("Required base data missing (Properties or Rooms).")
        return

    first_names = ["James", "Mary", "Robert", "Patricia", "John", "Jennifer", "Michael", "Linda", "Elizabeth", "William"]
    last_names = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez"]
    
    print("Generating Dummy Data...")
    
    resident_ids = []
    
    # 1. Create Resident Accounts (Person Accounts)
    for i in range(5):
        fn = random.choice(first_names)
        ln = random.choice(last_names)
        cmd = f"sf data create record -s Account -v \"FirstName='{fn}' LastName='{ln}' RecordTypeId='{rt_resident}'\" --json"
        res = run_command(cmd)
        if res and res.get('status') == 0:
            acc_id = res['result']['id']
            resident_ids.append(acc_id)
            print(f"Created Resident Account: {fn} {ln} ({acc_id})")

    if not resident_ids:
        print("Failed to create any Resident Accounts.")
        return

    # Create a template Assessment
    ass_template_res = run_command('sf data create record -s Assessment__c -v "Name=\'Initial Admission Assessment\' Type__c=\'Initial\'" --json')
    ass_template_id = ass_template_res['result']['id'] if ass_template_res and 'result' in ass_template_res else None
    
    # 2. For each resident, create an Opportunity (Enquiry), Resident_Assessment__c, and Contract
    for rid in resident_ids:
        prop = random.choice(properties)
        room = random.choice([r for r in rooms if r['Property__c'] == prop['Id']])
        
        # Opportunity (Enquiry)
        opp_name = f"Enquiry for {rid}"
        opp_cmd = f"sf data create record -s Opportunity -v \"Name='{opp_name}' Resident__c='{rid}' StageName='Prospecting' CloseDate='2026-12-31'\" --json"
        opp_res = run_command(opp_cmd)
        
        if opp_res and opp_res.get('status') == 0:
            opp_id = opp_res['result']['id']
            print(f"Created Opportunity: {opp_id}")
            
            # Resident_Assessment__c (Corrected object name)
            ass_val = f"Assessment__c='{ass_template_id}' " if ass_template_id else ""
            ass_cmd = f"sf data create record -s Resident_Assessment__c -v \"{ass_val}Opportunity__c='{opp_id}' Resident__c='{rid}' Status__c='Scheduled'\" --json"
            run_command(ass_cmd)
            
            # Contract (Standard Object)
            cont_cmd = f"sf data create record -s Contract -v \"AccountId='{rid}' StartDate='2026-01-08' ContractTerm=12 Status='Draft'\" --json"
            run_command(cont_cmd)
            
            # Room_Occupancy__c (Custom Object)
            occ_cmd = f"sf data create record -s Room_Occupancy__c -v \"Resident__c='{rid}' Room__c='{room['Id']}' Start_Date__c='2026-01-08' Status__c='Reserved'\" --json"
            run_command(occ_cmd)

    print("Dummy data generation finished.")

if __name__ == "__main__":
    main()
