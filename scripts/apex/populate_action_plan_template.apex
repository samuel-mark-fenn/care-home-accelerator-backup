String versionId = '0PTKZ000000pSTv4AM';

// Cleanup existing items for this version
delete [SELECT Id FROM ActionPlanTemplateItem WHERE ActionPlanTemplateVersionId = :versionId];

// Define Items
List<Map<String, String>> items = new List<Map<String, String>>{
    new Map<String, String>{'Name' => 'Complete Initial Inquiry Form', 'Type' => 'Task', 'Offset' => '0', 'Priority' => 'High', 'Desc' => 'Populate the inquiry form after the initial contact.'},
    new Map<String, String>{'Name' => 'Send Welcome Brochure', 'Type' => 'Task', 'Offset' => '0', 'Priority' => 'Normal', 'Desc' => 'Email the welcome brochure to the inquirer immediately.'},
    new Map<String, String>{'Name' => 'Initial Follow-up Call', 'Type' => 'Task', 'Offset' => '2', 'Priority' => 'Normal', 'Desc' => 'Check if the inquirer received the brochure and answer questions.'},
    new Map<String, String>{'Name' => 'Book Show Round', 'Type' => 'Task', 'Offset' => '3', 'Priority' => 'Normal', 'Desc' => 'Coordinate with Home Manager and Clinical Lead to schedule visit.'},
    new Map<String, String>{'Name' => 'Prepare for Show Round', 'Type' => 'Task', 'Offset' => '4', 'Priority' => 'Normal', 'Desc' => 'Tidy common areas and prepare refreshments (tea/coffee).'},
    new Map<String, String>{'Name' => 'Show Round', 'Type' => 'Event', 'Offset' => '5', 'Priority' => '', 'Desc' => 'Conduct the show round with the inquirer and family.'},
    new Map<String, String>{'Name' => 'Post-Show Round Follow-up', 'Type' => 'Task', 'Offset' => '6', 'Priority' => 'Normal', 'Desc' => 'Follow up to gauge interest and address concerns after the visit.'},
    new Map<String, String>{'Name' => 'Room Allocation & Rate Assignment', 'Type' => 'Task', 'Offset' => '7', 'Priority' => 'Normal', 'Desc' => 'Check availability and assign the correct rate.'},
    new Map<String, String>{'Name' => 'Collect Signed Documentation', 'Type' => 'Task', 'Offset' => '10', 'Priority' => 'High', 'Desc' => 'Collect required wet signatures and upload documents.'}
};

List<ActionPlanTemplateItem> templateItems = new List<ActionPlanTemplateItem>();
for (Integer i = 0; i < items.size(); i++) {
    Map<String, String> itemData = items[i];
    templateItems.add(new ActionPlanTemplateItem(
        ActionPlanTemplateVersionId = versionId,
        Name = itemData.get('Name'),
        ItemEntityType = itemData.get('Type'),
        IsActive = true,
        IsRequired = true,
        DisplayOrder = i + 1
    ));
}
insert templateItems;

List<ActionPlanTemplateItemValue> itemValues = new List<ActionPlanTemplateItemValue>();
for (Integer i = 0; i < templateItems.size(); i++) {
    ActionPlanTemplateItem item = templateItems[i];
    Map<String, String> data = items[i];
    String prefix = item.ItemEntityType + '.';

    // Subject
    itemValues.add(new ActionPlanTemplateItemValue(
        ActionPlanTemplateItemId = item.Id,
        ItemEntityFieldName = prefix + 'Subject',
        ValueLiteral = data.get('Name'),
        IsActive = true
    ));

    // Description
    itemValues.add(new ActionPlanTemplateItemValue(
        ActionPlanTemplateItemId = item.Id,
        ItemEntityFieldName = prefix + 'Description',
        ValueLiteral = data.get('Desc'),
        IsActive = true
    ));

    // ActivityDate (Offset)
    itemValues.add(new ActionPlanTemplateItemValue(
        ActionPlanTemplateItemId = item.Id,
        ItemEntityFieldName = prefix + 'ActivityDate',
        ValueLiteral = data.get('Offset'),
        IsActive = true
    ));

    // Assignment - MANDATORY for Action Plans
    itemValues.add(new ActionPlanTemplateItemValue(
        ActionPlanTemplateItemId = item.Id,
        ItemEntityFieldName = prefix + 'OwnerId',
        ValueLiteral = 'PlanCreator', // Common literal for Action Plan Creator
        IsActive = true
    ));

    // Priority (for Tasks only)
    if (item.ItemEntityType == 'Task') {
        itemValues.add(new ActionPlanTemplateItemValue(
            ActionPlanTemplateItemId = item.Id,
            ItemEntityFieldName = 'Task.Priority',
            ValueLiteral = data.get('Priority'),
            IsActive = true
        ));
    }

    // Duration (for Event)
    if (item.ItemEntityType == 'Event') {
        itemValues.add(new ActionPlanTemplateItemValue(
            ActionPlanTemplateItemId = item.Id,
            ItemEntityFieldName = 'Event.DurationInMinutes',
            ValueLiteral = '60',
            IsActive = true
        ));
    }
}
insert itemValues;
System.debug('Created ' + templateItems.size() + ' items and ' + itemValues.size() + ' values.');
