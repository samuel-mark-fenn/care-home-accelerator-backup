import json
import subprocess
import random

def run_command(command):
    print(f"Running: {command}")
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    output = result.stdout
    start_index = output.find('{')
    if start_index == -1: return None
    json_str = output[start_index:]
    end_index = json_str.rfind('}') + 1
    try:
        data = json.loads(json_str[:end_index])
        return data
    except: return None

def main():
    # 1. Get Property
    prop_res = run_command('sf data query -q "SELECT Id FROM Property__c LIMIT 1" --json')
    if not prop_res or not prop_res['result']['records']:
        print("No Property found.")
        return
    prop_id = prop_res['result']['records'][0]['Id']

    # 2. Get Room
    room_res = run_command(f'sf data query -q "SELECT Id FROM Room__c WHERE Property__c = \'{prop_id}\' LIMIT 1" --json')
    if not room_res or not room_res['result']['records']:
        print("No Room found.")
        return
    room_id = room_res['result']['records'][0]['Id']

    # 3. Create Resident Account
    acc_res = run_command('sf data create record -s Account -v "FirstName=Dummy LastName=Resident RecordTypeId=012KZ000000lBWxYAM" --json')
    if not acc_res or 'result' not in acc_res:
        print(f"Failed to create Account: {acc_res}")
        return
    acc_id = acc_res['result']['id']
    print(f"Created Account: {acc_id}")

    # 4. Create Resident Record
    res_res = run_command(f'sf data create record -s Resident__c -v "Account__c=\'{acc_id}\' Current_Care_Home__c=\'{prop_id}\' Current_Room__c=\'{room_id}\' Resident_Status__c=Permanent" --json')
    if not res_res or 'result' not in res_res:
        print(f"Failed to create Resident__c: {res_res}")
    else:
        print(f"Created Resident__c: {res_res['result']['id']}")

    # 5. Create Enquiry
    enq_res = run_command(f'sf data create record -s Enquiry__c -v "Prospective_Resident__c=\'{acc_id}\' Preferred_Location__c=\'{prop_id}\' Enquiry_Source__c=Website Status__c=New" --json')
    if not enq_res or 'result' not in enq_res:
        print(f"Failed to create Enquiry__c: {enq_res}")
    else:
        print(f"Created Enquiry__c: {enq_res['result']['id']}")

if __name__ == "__main__":
    main()
