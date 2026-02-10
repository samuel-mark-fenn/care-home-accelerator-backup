import csv

CSV_FILE = 'colten_care_fields_master_list.csv'

with open(CSV_FILE, 'r', encoding='utf-8-sig') as f:
    reader = csv.DictReader(f)
    print(f"HEADERS: {reader.fieldnames}")
    for row in reader:
        if row['Field API Name'] == 'Event_Category__c':
            print(f"ROW: {row}")
            print(f"Default Value: '{row.get('Default Value')}'")
            print(f"Picklist Values: '{row.get('Picklist Values (pipe separated)')}'")
            break
